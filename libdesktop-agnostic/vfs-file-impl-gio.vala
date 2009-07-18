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
        FileType ft;
        if (this.exists ())
        {
          switch (this._file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null))
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
        else
        {
          ft = FileType.UNKNOWN;
        }
        return ft;
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
      return this._file.load_contents (null, out contents, out length, null);
    }
    public override bool
    replace_contents (string contents) throws Error
    {
      return this._file.replace_contents (contents, contents.len (), null,
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
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
