/*
 * Desktop Agnostic Library: Test for the file monitor implementations.
 *
 * Copyright (C) 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author : Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 */

using DesktopAgnostic;

class TestFileMonitor
{
  private static VFS.File file;
  private static VFS.FileMonitor monitor;
  private static void on_change (VFS.FileMonitor monitor,
                                 VFS.File file,
                                 VFS.File? other,
                                 VFS.FileMonitorEvent event)
  {
    string evt_str = "?";
    switch (event)
    {
      case VFS.FileMonitorEvent.CHANGED:
        evt_str = "Changed";
        break;
      case VFS.FileMonitorEvent.CREATED:
        evt_str = "Created";
        break;
      case VFS.FileMonitorEvent.DELETED:
        evt_str = "Deleted";
        break;
      case VFS.FileMonitorEvent.ATTRIBUTE_CHANGED:
        evt_str = "Attribute Changed";
        break;
      case VFS.FileMonitorEvent.UNKNOWN:
        evt_str = "Unknown";
        break;
    }
    message ("%s: %s", evt_str, file.uri);
    if (other != null)
    {
      message (" * other: %s", other.uri);
    }
  }

  private static bool do_emit ()
  {
    try
    {
      string filename = Path.build_filename (file.path, "test-vfs-file.txt");
      VFS.File other = VFS.file_new_for_path (filename);
      monitor.emit (other, VFS.FileMonitorEvent.CREATED);
    }
    catch (Error err)
    {
      critical ("Error: %s", err.message);
    }
    return false;
  }

  public static int
  main (string[] args)
  {
    if (args.length < 2)
    {
      stderr.printf ("Usage: %s [FILE | DIRECTORY FILE] \n", args[0]);
      return 1;
    }
    try
    {
      VFS.init ();
      unowned string path = args[1];
      file = VFS.file_new_for_path (path);
      monitor = file.monitor ();
      monitor.changed += on_change;
      MainLoop mainloop = new MainLoop (null, false);
      if (args.length == 3 && file.file_type == VFS.FileType.DIRECTORY)
      {
        Timeout.add_seconds (2, do_emit);
      }
      mainloop.run ();
      monitor.cancel ();
      assert (monitor.cancelled);
      VFS.shutdown ();
    }
    catch (Error err)
    {
      critical ("VFS Error: %s", err.message);
      return 1;
    }
    return 0;
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
