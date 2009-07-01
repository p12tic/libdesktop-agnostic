/*
 * Desktop Agnostic Library: File monitor implementation (with Thunar VFS).
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

namespace DesktopAgnostic.VFS.File
{
  public class ThunarVFSMonitor : Object, Monitor
  {
    private unowned ThunarVfs.MonitorHandle handle;
    private Backend file;
    private bool _cancelled;
    public bool cancelled
    {
      get
      {
        return this._cancelled;
      }
    }
    public ThunarVFSMonitor (ThunarVFSBackend file)
    {
      this.file = file;
      unowned ThunarVfs.Monitor mon = ThunarVfs.Monitor.get_default ();
      if (file.file_type == FileType.DIRECTORY)
      {
        this.handle = mon.add_directory ((ThunarVfs.Path)file.implementation,
                                         this.monitor_callback);
      }
      else
      {
        this.handle = mon.add_file ((ThunarVfs.Path)file.implementation,
                                    this.monitor_callback);
      }
      this._cancelled = false;
    }
    private void monitor_callback (ThunarVfs.Monitor monitor, ThunarVfs.MonitorHandle handle, ThunarVfs.MonitorEvent event, ThunarVfs.Path handle_path, ThunarVfs.Path event_path)
    {
      try
      {
        Backend event_file = File.new_for_uri (event_path.dup_uri ());
        MonitorEvent da_event = MonitorEvent.UNKNOWN;
        switch (event)
        {
          case ThunarVfs.MonitorEvent.CHANGED:
            da_event = MonitorEvent.CHANGED;
            break;
          case ThunarVfs.MonitorEvent.CREATED:
            da_event = MonitorEvent.CREATED;
            break;
          case ThunarVfs.MonitorEvent.DELETED:
            da_event = MonitorEvent.DELETED;
            break;
        }
        this.changed (this.file, event_file, da_event);
      }
      catch (Error err)
      {
        critical ("Error: %s", err.message);
      }
    }
    public void emit (Backend? other, MonitorEvent event)
    {
      ThunarVfs.MonitorEvent tvfs_event;
      ThunarVfs.Path path;
      unowned ThunarVfs.Monitor mon = ThunarVfs.Monitor.get_default ();
      switch (event)
      {
        case MonitorEvent.CHANGED:
          tvfs_event = ThunarVfs.MonitorEvent.CHANGED;
          break;
        case MonitorEvent.CREATED:
          tvfs_event = ThunarVfs.MonitorEvent.CREATED;
          break;
        case MonitorEvent.DELETED:
          tvfs_event = ThunarVfs.MonitorEvent.DELETED;
          break;
        default:
          return;
      }
      if (other == null)
      {
        path = (ThunarVfs.Path)this.file.implementation;
      }
      else
      {
        path = (ThunarVfs.Path)other.implementation;
      }
      mon.feed (tvfs_event, path);
    }
    public bool cancel ()
    {
      ThunarVfs.Monitor.get_default ().remove (this.handle);
      this._cancelled = true;
      return true;
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
