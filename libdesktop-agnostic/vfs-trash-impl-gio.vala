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

using DesktopAgnostic.VFS;

namespace DesktopAgnostic.VFS.Trash
{
  public class GIOImplementation : Backend, Object
  {
    private File.Backend trash;
    private File.Monitor monitor;
    private uint _file_count;

    construct
    {
      this.trash = File.new_for_uri ("trash://");
      if (this.trash == null)
      {
        critical ("trash is NULL!!!!");
      }
      this.monitor = this.trash.monitor ();
      this.monitor.changed += this.on_trash_changed;
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
    on_trash_changed (File.Monitor monitor, 
                      File.Backend file,
                      File.Backend? other_file,
                      File.MonitorEvent event_type)
    {
      this.update_file_count ();
    }

    private void
    update_file_count ()
    {
      GLib.File dir = (GLib.File)this.trash.implementation;
      dir.query_info_async (FILE_ATTRIBUTE_TRASH_ITEM_COUNT,
                            FileQueryInfoFlags.NONE,
                            Priority.DEFAULT,
                            null,
                            this.on_trash_count);
    }

    private void
    on_trash_count (Object obj, AsyncResult res)
    {
      GLib.File dir = (GLib.File)obj;
      FileInfo file_info;

      try
      {
        file_info = dir.query_info_finish (res);
        this._file_count = file_info.get_attribute_uint32 (FILE_ATTRIBUTE_TRASH_ITEM_COUNT);
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
        string attrs = FILE_ATTRIBUTE_STANDARD_NAME + "," +
                       FILE_ATTRIBUTE_STANDARD_TYPE;
        GLib.File trash_dir = (GLib.File)this.trash.implementation;
        files = trash_dir.enumerate_children (attrs,
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
        if (info.get_file_type () == FileType.DIRECTORY)
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
    send_to_trash (File.Backend uri) throws GLib.Error
    {
      GLib.File file = (GLib.File)uri.implementation;
      file.trash (null);
    }

    public void
    empty ()
    {
      this.do_empty ((GLib.File)trash.implementation);
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
