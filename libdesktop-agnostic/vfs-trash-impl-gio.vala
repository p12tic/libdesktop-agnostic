/*
 * Desktop Agnostic Library: Trash implementation with GIO.
 *
 * Copyright (C) 2008, 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
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
  public class TrashGIO : Trash, Object
  {
    private File trash;
    private FileMonitor monitor;
    private uint _file_count;

    construct
    {
      this.trash = file_new_for_uri ("trash://");
      if (this.trash == null)
      {
        critical ("trash is NULL!!!!");
      }
      this.monitor = this.trash.monitor ();
      this.monitor.changed.connect(this.on_trash_changed);
      this._file_count = 0;
      this.update_file_count ();
    }

    public uint file_count
    {
      get
      {
        return this._file_count;
      }
    }

    private void
    on_trash_changed (FileMonitor monitor,
                      File file,
                      File? other_file,
                      FileMonitorEvent event_type)
    {
      this.update_file_count ();
    }

    private void
    update_file_count ()
    {
      GLib.File dir = (GLib.File)this.trash.implementation;
      dir.query_info_async (FileAttribute.TRASH_ITEM_COUNT,
                            FileQueryInfoFlags.NONE,
                            Priority.DEFAULT,
                            null,
                            this.on_trash_count);
    }

    private void
    on_trash_count (Object? obj, AsyncResult res)
    {
      GLib.File dir = (GLib.File)obj;
      FileInfo file_info;

      try
      {
        file_info = dir.query_info_async.end (res);
        this._file_count = file_info.get_attribute_uint32 (FileAttribute.TRASH_ITEM_COUNT);
        this.file_count_changed ();
      }
      catch (Error err)
      {
        warning ("Could not update file count: %s", err.message);
      }
    }

    private void
    do_empty (GLib.File dir)
    {
      FileEnumerator files = null;
      FileInfo info;

      try
      {
        string attrs = FileAttribute.STANDARD_NAME + "," +
                       FileAttribute.STANDARD_TYPE;
        files = dir.enumerate_children (attrs,
                                        FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                        null);
      }
      catch (Error e)
      {
        warning ("Trash error: %s", e.message);
      }
      if (files == null)
      {
        return;
      }
      while ((info = files.next_file (null)) != null)
      {
        GLib.File child;
        child = dir.get_child (info.get_name ());
        if (info.get_file_type () == GLib.FileType.DIRECTORY)
        {
          this.do_empty (child);
        }
        try
        {
          child.delete (null);
        }
        catch (Error e)
        {
          warning ("Trash error: %s", e.message);
        }
      }
    }

    public void
    send_to_trash (File uri) throws GLib.Error
    {
      GLib.File file = (GLib.File)uri.implementation;
      file.trash (null);
    }

    public void
    empty ()
    {
      this.do_empty ((GLib.File)this.trash.implementation);
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
