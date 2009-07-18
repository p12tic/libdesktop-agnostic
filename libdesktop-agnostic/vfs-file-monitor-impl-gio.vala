/*
 * Desktop Agnostic Library: File monitor implementation (with GIO).
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
  public class FileMonitorGIO : Object, FileMonitor
  {
    private GLib.FileMonitor monitor;
    public bool cancelled
    {
      get
      {
        return this.monitor.is_cancelled ();
      }
    }
    private File file;
    public FileMonitorGIO (FileGIO file)
    {
      this.file = file;
      GLib.File impl = (GLib.File)file.implementation;
      if (file.file_type == FileType.DIRECTORY)
      {
        this.monitor = impl.monitor_directory (FileMonitorFlags.NONE, null);
      }
      else
      {
        this.monitor = impl.monitor_file (FileMonitorFlags.NONE, null);
      }
      this.monitor.changed += this.monitor_callback;
    }
    private void monitor_callback (GLib.FileMonitor monitor, GLib.File file,
                                   GLib.File? other,
                                   GLib.FileMonitorEvent event_type)
    {
      File other_file = null;
      if (other != null)
      {
        other_file = file_new_for_uri (other.get_uri ());
      }
      FileMonitorEvent da_event;
      switch (event_type)
      {
        case GLib.FileMonitorEvent.CHANGED:
          da_event = FileMonitorEvent.CHANGED;
          break;
        case GLib.FileMonitorEvent.CREATED:
          da_event = FileMonitorEvent.CREATED;
          break;
        case GLib.FileMonitorEvent.DELETED:
          da_event = FileMonitorEvent.DELETED;
          break;
        case GLib.FileMonitorEvent.ATTRIBUTE_CHANGED:
          da_event = FileMonitorEvent.ATTRIBUTE_CHANGED;
          break;
        default:
          da_event = FileMonitorEvent.UNKNOWN;
          break;
      }
      this.changed (this.file, other_file, da_event);
    }
    public void emit (File? other, FileMonitorEvent event)
    {
      GLib.FileMonitorEvent gio_event;
      GLib.File other_file = null;
      switch (event)
      {
        case FileMonitorEvent.CHANGED:
          gio_event = GLib.FileMonitorEvent.CHANGED;
          break;
        case FileMonitorEvent.CREATED:
          gio_event = GLib.FileMonitorEvent.CREATED;
          break;
        case FileMonitorEvent.DELETED:
          gio_event = GLib.FileMonitorEvent.DELETED;
          break;
        case FileMonitorEvent.ATTRIBUTE_CHANGED:
          gio_event = GLib.FileMonitorEvent.ATTRIBUTE_CHANGED;
          break;
        default:
          return;
      }
      if (other != null)
      {
        other_file = (GLib.File)other.implementation;
      }
      this.monitor.emit_event ((GLib.File)this.file.implementation,
                               other_file, gio_event);
    }
    public bool cancel ()
    {
      return this.monitor.cancel ();
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :

