/* 
 * Init function for the library.
 *
 * Copyright (C) 2008, 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
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

using GLib;

namespace DesktopAgnostic
{
  public errordomain ModuleError
  {
    NO_GMODULE,
    NO_CONFIG_FOUND
  }
  public static Datalist<Module> modules;
  /**
   * Based on the PluginRegistrar class in
   * <http://live.gnome.org/Vala/TypeModules>.
   */
  public class ModuleLoader<T> : Object
  {
    public string name { get; construct; }

    private Type _module_type;
    public Type module_type
    {
      get
      {
        return this._module_type;
      }
    }
    private static string[] paths;

    private delegate Type RegisterModuleFunction ();

    static construct
    {
      paths = new string[]
      {
        // FIXME use config.vapi
        Path.build_filename ("@LIBDIR@", "desktop-agnostic"),
        Path.build_filename (Environment.get_home_dir (), ".local", "lib",
                             "desktop-agnostic"),
        Environment.get_variable ("DESKTOP_AGNOSTIC_MODULE_DIR")
      };
      modules = Datalist<Module> ();
    }

    construct
    {
      assert (Module.supported ());
    }

    public ModuleLoader (string name)
    {
      this.name = name;
    }

    public static string[] get_search_paths ()
    {
      return paths;
    }

    public bool
    load_from_path (string path)
    {
      Module module = null;
      void* function;
      RegisterModuleFunction register_plugin;
      debug ("Loading plugin with path: '%s'", path);
      module = Module.open (path, ModuleFlags.BIND_LAZY);
      if (module == null)
      {
        return false;
      }
      module.symbol ("register_plugin", out function);
      register_plugin = (RegisterModuleFunction) function;
      modules.set_data (this.name, #module);

      this._module_type = register_plugin ();
      debug ("Plugin type: %s", this._module_type.name ());

      return true;
    }

    public bool
    load ()
    {
      string path;
      bool found_module = false;

      foreach (weak string prefix in this.paths)
      {
        if (prefix == null || !FileUtils.test (prefix, FileTest.IS_DIR))
        {
          continue;
        }
        path = Module.build_path (Path.build_filename (prefix,
                                                       Path.get_dirname (this.name)),
                                  Path.get_basename (this.name));
        found_module = this.load_from_path (path);
        if (found_module)
        {
          break;
        }
      }
      if (!found_module)
      {
        // try the current directory, as a last resort
        path = Module.build_path (Environment.get_current_dir (),
                                  Path.get_basename (this.name));
        found_module = this.load_from_path (path);
        if (!found_module)
        {
          warning ("Could not locate the plugin '%s'.", this.name);
          return false;
        }
      }

      return true;
    }
  }
  public Config.Backend?
  config_get_default (string schema_file) throws GLib.Error
  {
    KeyFile config;
    ModuleLoader<Config.Backend> loader;
    string cfg_file = "desktop-agnostic.ini";

    if (!Module.supported ())
    {
      throw new ModuleError.NO_GMODULE ("libdesktop-agnostic requires GModule support.");
    }
    config = new KeyFile ();
    if (!config.load_from_file (Path.build_filename (Environment.get_user_config_dir (), cfg_file),
                                KeyFileFlags.NONE))
    {
      if (!config.load_from_data_dirs (cfg_file, null, KeyFileFlags.NONE))
      {
        throw new ModuleError.NO_CONFIG_FOUND ("Could not find any libdesktop-agnostic configuration files.");
      }
    }
    loader = new ModuleLoader<Config.Backend> ("libda-cfg-" +
                                               config.get_string ("DEFAULT", "config"));
    if (loader.load ())
    {
      return (Config.Backend)Object.new (loader.module_type, "schema_filename", schema_file);
    }
    else
    {
      return null;
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
