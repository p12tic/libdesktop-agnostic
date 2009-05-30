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
  private static VFS.Implementation vfs;
  private static VFS.File.Backend file;
  private static VFS.File.Monitor monitor;
  private static void on_change (VFS.File.Monitor monitor,
                                 VFS.File.Backend file,
                                 VFS.File.Backend? other,
                                 VFS.File.MonitorEvent event)
  {
    string evt_str = "?";
    switch (event)
    {
      case VFS.File.MonitorEvent.CHANGED:
        evt_str = "Changed";
        break;
      case VFS.File.MonitorEvent.CREATED:
        evt_str = "Created";
        break;
      case VFS.File.MonitorEvent.DELETED:
        evt_str = "Deleted";
        break;
      case VFS.File.MonitorEvent.ATTRIBUTE_CHANGED:
        evt_str = "Attribute Changed";
        break;
      case VFS.File.MonitorEvent.UNKNOWN:
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
    string filename = Path.build_filename (file.path, "test-vfs-file.txt");
    VFS.File.Backend other = (VFS.File.Backend)Object.new (vfs.file_type,
                                                           "path", filename);
    monitor.emit (other, VFS.File.MonitorEvent.CREATED);
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
    vfs = VFS.get_default ();
    vfs.init ();
    weak string path = args[1];
    file = (VFS.File.Backend)Object.new (vfs.file_type, "path", path);
    monitor = file.monitor ();
    monitor.changed += on_change;
    MainLoop mainloop = new MainLoop (null, false);
    if (args.length == 3 && file.file_type == VFS.File.FileType.DIRECTORY)
    {
      Timeout.add_seconds (2, do_emit);
    }
    mainloop.run ();
    monitor.cancel ();
    assert (monitor.cancelled);
    vfs.shutdown ();
    return 0;
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
