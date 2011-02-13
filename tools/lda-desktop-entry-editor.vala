/*
 * Desktop Agnostic Library: Desktop entry editor.
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
using DesktopAgnostic.UI;

const OptionEntry[] entries = {
  //{ 0, }
};

public static int
main (string[] args)
{
  VFS.File file;
  VFS.File? output = null;
  LauncherEditorDialog editor;

  if (args.length < 2)
  {
    critical ("Usage: %s FILE [OUTPUT FILE]", args[0]);
    return 1;
  }

  try
  {
    VFS.init ();

    Gtk.init (ref args);

    file = VFS.file_new_for_path (args[1]);
    if (args.length > 2)
    {
      output = VFS.file_new_for_path (args[2]);
    }
    editor = new LauncherEditorDialog (file, output);
    editor.show_all ();
    editor.run ();

    VFS.shutdown ();
  }
  catch (Error err)
  {
    critical ("Error: %s", err.message);
    return 1;
  }
  return 0;
}

// vim:et:ai:cindent:ts=2 sts=2 sw=2
