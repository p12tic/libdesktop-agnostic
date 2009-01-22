/*
 * Desktop Agnostic Library: glob() wrapper test.
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

using DesktopAgnostic.VFS;

int main (string[] args)
{
  if (args.length < 2)
  {
    return 0;
  }
  Glob g = null;
  bool first_arg = false;
  foreach (weak string arg in args)
  {
    // don't try to match the program arg
    if (!first_arg)
    {
      first_arg = true;
      continue;
    }
    try
    {
      if (g == null)
      {
        g = Glob.execute (arg);
      }
      else
      {
        g.append (arg);
      }
      foreach (weak string path in g.paths)
      {
        stdout.printf ("%s\n", path);
      }
    }
    catch (GlobError err)
    {
      if (err is GlobError.NOMATCH)
      {
        critical (err.message);
        return 1;
      }
    }
  }
  return 0;
}

// vim: set et ts=2 sts=2 sw=2 ai :
