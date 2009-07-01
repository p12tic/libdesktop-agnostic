/*
 * Desktop Agnostic Library: Test for the file (monitor) implementations.
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

const string CONTENT = "Desktop Agnostic Library";

int main (string[] args)
{
  try
  {
    VFS.Implementation vfs = VFS.get_default ();
    vfs.init ();
    unowned string path = Environment.get_tmp_dir ();
    VFS.File.Backend tmp = VFS.File.new_for_path (path);
    assert (tmp.exists);
    assert (tmp.file_type == VFS.File.FileType.DIRECTORY);
    message ("URI: %s", tmp.uri);
    message ("Path: %s", tmp.path);
    tmp = null;
    string file_path = Path.build_filename (path, "desktop-agnostic-test");
    VFS.File.Backend file = VFS.File.new_for_path (file_path);
    file.replace_contents (CONTENT);
    string contents;
    size_t length;
    file.load_contents (out contents, out length);
    assert (contents == CONTENT);
    assert (file.launch ());
    file = null;
    vfs.shutdown ();
  }
  catch (Error err)
  {
    critical ("Error: %s", err.message);
  }
  return 0;
}

// vim: set et ts=2 sts=2 sw=2 ai :
