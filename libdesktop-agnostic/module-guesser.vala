/*
 * Desktop Agnostic Module guesser function.
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

using DesktopAgnostic;
using DesktopAgnostic.VFS;

/**
 * Given a valid library prefix, this function takes the first valid module
 * that is locates via the search paths and glob and loads it.
 */
public Type
guess_module (ModuleLoader loader, string library_prefix)
{
  string[] paths = loader.get_search_paths ();
  string module_glob_suffix = "%s*".printf (library_prefix);
  Type result = Type.INVALID;

  foreach (unowned string path_prefix in paths)
  {
    if (path_prefix == null || !FileUtils.test (path_prefix, FileTest.IS_DIR))
    {
      continue;
    }

    string module_glob = Path.build_filename (path_prefix, module_glob_suffix);
    try
    {
      Glob found_modules;
      unowned string[] modules_paths;

      found_modules = Glob.execute (module_glob);
      modules_paths = found_modules.get_paths ();
      foreach (unowned string module in modules_paths)
      {
        result = loader.load_from_path (path_prefix, module);
        if (result != Type.INVALID)
        {
          break;
        }
      }
    }
    catch (GlobError err)
    {
      if (!(err is GlobError.NOMATCH))
      {
        warning ("Glob-related eror: %s", err.message);
      }
    }
    if (result != Type.INVALID)
    {
      break;
    }
  }

  return result;
}

// vim: set et ts=2 sts=2 sw=2 ai :
