/* 
 * Desktop Agnostic Library: Test for the desktop entry implementations.
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
using DesktopAgnostic.VFS.Bookmarks;

void
print_bookmarks (GtkParser parser)
{
  if (parser.bookmarks == null)
  {
    message ("No bookmarks.");
  }
  else
  {
    message ("Bookmarks:");
    foreach (unowned Bookmark b in parser.bookmarks)
    {
      message ("* %s (%s)", b.file.uri, b.alias);
    }
  }
}

int
main (string[] args)
{
  VFS.Implementation vfs;
  GtkParser parser;

  vfs = VFS.get_default ();
  vfs.init ();

  if (args.length < 2)
  {
    parser = new GtkParser ();
  }
  else
  {
    VFS.File.Backend file = VFS.File.new_for_path (args[1]);
    parser = new GtkParser (file);
  }
  print_bookmarks (parser);
  parser.changed.connect (print_bookmarks);
  MainLoop ml = new MainLoop (null, false);
  ml.run ();
  parser = null;
  vfs.shutdown ();
  return 0;
}

// vim: set et ts=2 sts=2 sw=2 ai cindent :
