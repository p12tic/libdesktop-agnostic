/*
 * Desktop Agnostic Library: File implementation (with GIO).
 *
 * Copyright (C) 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 * Author : Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 */

namespace DesktopAgnostic.VFS
{
  public class FileGIO : File
  {
    private GLib.File _file;
    public override void* implementation
    {
      get
      {
        return (void*)this._file;
      }
    }
    private string _uri;
    protected override string? impl_path
    {
      owned get
      {
        return this._file.get_path ();
      }
    }
    protected override string impl_uri
    {
      owned get
      {
        if (this._uri == null)
        {
          this._uri = this._file.get_uri ();
        }
        return this._uri;
      }
    }
    public override FileType file_type
    {
      get
      {
        FileType ft = FileType.UNKNOWN;
        if (this.exists ())
        {
          // File.query_file_type requires GIO 2.18...
          FileInfo info;
          GLib.FileType gft;

          try
          {
            info = this._file.query_info (FileAttribute.STANDARD_TYPE,
                                          FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                          null);
            gft = (GLib.FileType)info.get_attribute_uint32 (FileAttribute.STANDARD_TYPE);
            switch (gft)
            {
              case GLib.FileType.REGULAR:
                ft = FileType.REGULAR;
                break;
              case GLib.FileType.DIRECTORY:
              case GLib.FileType.MOUNTABLE:
                ft = FileType.DIRECTORY;
                break;
              case GLib.FileType.SYMBOLIC_LINK:
              case GLib.FileType.SHORTCUT:
                ft = FileType.SYMBOLIC_LINK;
                break;
              case GLib.FileType.SPECIAL:
                ft = FileType.SPECIAL;
                break;
              case GLib.FileType.UNKNOWN:
                ft = FileType.UNKNOWN;
                break;
            }
          }
          catch (Error err)
          {
            warning ("An error occurred while querying the file type: %s",
                     err.message);
            ft = FileType.UNKNOWN;
          }
        }
        return ft;
      }
    }
    public override AccessFlags access_flags
    {
      get
      {
        AccessFlags flags = AccessFlags.NONE;
        if (this.exists ())
        {
          FileInfo info;

          try
          {
            string attrs;

            attrs = "%s,%s,%s".printf (FileAttribute.ACCESS_CAN_READ,
                                       FileAttribute.ACCESS_CAN_WRITE,
                                       FileAttribute.ACCESS_CAN_EXECUTE);
            info = this._file.query_info (attrs, FileQueryInfoFlags.NONE,
                                          null);
            if (info.get_attribute_boolean (FileAttribute.ACCESS_CAN_READ))
            {
              flags |= AccessFlags.READ;
            }
            if (info.get_attribute_boolean (FileAttribute.ACCESS_CAN_WRITE))
            {
              flags |= AccessFlags.WRITE;
            }
            if (info.get_attribute_boolean (FileAttribute.ACCESS_CAN_EXECUTE))
            {
              flags |= AccessFlags.EXECUTE;
            }
          }
          catch (Error err)
          {
            warning ("An error occurred while querying the access flags: %s",
                     err.message);
          }
        }

        return flags;
      }
    }
    public override File? parent
    {
      owned get
      {
        GLib.File? file;

        file = this._file.get_parent ();
        if (file == null)
        {
          return null;
        }
        else
        {
          File result;

          result = new FileGIO ();
          result.init (file.get_uri ());
          return result;
        }
      }
    }
    protected override void
    init (string uri)
    {
      this._file = GLib.File.new_for_uri (uri);
    }
    public override bool exists ()
    {
      return this._file.query_exists (null);
    }
    public override FileMonitor monitor ()
    {
      return new FileMonitorGIO (this);
    }
    public override bool
    load_contents (out string contents, out size_t length) throws Error
    {
      uint8[] bytes;
      bool ret = this._file.load_contents (null, out bytes, null);
      contents = (string)bytes;
      length = bytes.length;
      g_free(bytes);
      return ret;
    }
    public override bool
    replace_contents (string contents) throws Error
    {
      return this._file.replace_contents (contents.data, null,
                                          false, 0, null, null);
    }
    public override bool
    launch () throws Error
    {
      AppInfo app_info;
      List<GLib.File> files = new List<GLib.File> ();

      app_info = this._file.query_default_handler (null);
      files.append (this._file);
      return app_info.launch (files, null);
    }
    public override SList<File>
    enumerate_children () throws Error
    {
      SList<File> children;
      FileEnumerator enumerator;
      FileInfo info;

      children = new SList<File> ();
      enumerator = this._file.enumerate_children (FileAttribute.STANDARD_NAME,
                                                  FileQueryInfoFlags.NONE,
                                                  null);
      while ((info = enumerator.next_file (null)) != null)
      {
        GLib.File gchild;
        File child;

        gchild = this._file.get_child (info.get_name ());
        child = file_new_for_uri (gchild.get_uri ());
        children.append ((owned)child);
      }
      return children;
    }
    public override bool
    copy (File destination, bool overwrite) throws Error
    {
      FileCopyFlags flags = 0;

      if (overwrite)
      {
        flags = FileCopyFlags.OVERWRITE;
      }
      return this._file.copy ((GLib.File)destination.implementation,
                              flags, null, null);
    }
    public override bool
    remove () throws Error
    {
      if (!this.exists ())
      {
        throw new FileError.FILE_NOT_FOUND ("The file '%s' does not exist.",
                                            this.uri);
      }
      return this._file.delete (null);
    }

    public override bool is_native ()
    {
      return this._file.is_native ();
    }

    public override string get_mime_type () throws Error
    {
      var fi = this._file.query_info (FileAttribute.STANDARD_CONTENT_TYPE,
                                      0, null);
      return fi.get_content_type ();
    }

    public override string[] get_icon_names () throws Error
    {
      var fi = this._file.query_info (FileAttribute.STANDARD_ICON,
                                      0, null);
      GLib.Icon icon = fi.get_icon ();
      if (icon != null)
      {
        if (icon is ThemedIcon)
        {
          // wow! Vala sucks!
          Value v = Value (typeof (string[]));
          icon.get_property ("names", ref v);
          string[] names = (string[]) v;

          // this should be fixed in vala 0.12
          //names = (icon as ThemedIcon).get_names ();

          return names;
        }

        if (icon is FileIcon)
        {
          string path = (icon as FileIcon).get_file ().get_path ();
          string[] result = { path };

          return result;
        }
      }

      // hmm... what now?
      string[] unknown = {};
      return unknown;
    }

    public override string?
    get_thumbnail_path ()
    {
      try
      {
        var fi = this._file.query_info (FileAttribute.THUMBNAIL_PATH,
                                        0, null);
        if (fi.has_attribute (FileAttribute.THUMBNAIL_PATH))
        {
          return fi.get_attribute_byte_string (FileAttribute.THUMBNAIL_PATH);
        }
      }
      catch (GLib.Error err)
      {
        warning ("%s", err.message);
      }
      return null;
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
