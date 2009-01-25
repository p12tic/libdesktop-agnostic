/*
 * Test program for the Trash VFS backends.
 *
 * Copyright (C) 2008, 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
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

public class TestTrash
{
  static MainLoop mainloop;
  static void on_file_count_changed (VFS.Trash.Backend t)
  {
    message ("Number of files in the trash: %u\n", t.file_count);
    mainloop.quit ();
  }
  static int main (string[] args)
  {
    try
    {
      VFS.Implementation vfs = vfs_get_default ();
      vfs.init ();
      VFS.Trash.Backend t = (VFS.Trash.Backend)Object.new (vfs.trash_type);
      t.file_count_changed += on_file_count_changed;
      mainloop = new MainLoop (null, true);
      mainloop.run ();
      vfs.shutdown ();
    }
    catch (GLib.Error err)
    {
      critical (err.message);
    }
    return 0;
  }
}

// vim: set ft=cs et ts=2 sts=2 sw=2 ai :
