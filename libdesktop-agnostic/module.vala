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

namespace DesktopAgnostic
{
  public errordomain ModuleError
  {
    NO_GMODULE,
    NO_CONFIG_FOUND
  }
  private static Datalist<Module> modules;
  /**
   * Based on the PluginRegistrar class in
   * <http://live.gnome.org/Vala/TypeModules>.
   */
  public class ModuleLoader : Object
  {
    private static string[] paths;

    private delegate Type RegisterModuleFunction ();

    private static ModuleLoader? module_loader = null;

    static construct
    {
      paths = new string[]
      {
        Path.build_filename (Build.LIBDIR, "desktop-agnostic", "modules"),
        Path.build_filename (Environment.get_home_dir (), ".local", "lib",
                             "desktop-agnostic"),
        Environment.get_variable ("DESKTOP_AGNOSTIC_MODULE_DIR")
      };
      modules = Datalist<Module> ();
    }

    private ModuleLoader ()
    {
      assert (Module.supported ());
    }

    public static unowned ModuleLoader
    get_default ()
    {
      if (module_loader == null)
      {
        module_loader = new ModuleLoader ();
      }

      return module_loader;
    }

    public static string[]
    get_search_paths ()
    {
      return paths;
    }

    public Type
    load_from_path (string name, string path)
    {
      Module module = null;
      void* function;
      RegisterModuleFunction register_plugin;
      debug ("Loading plugin with path: '%s'", path);
      module = Module.open (path, ModuleFlags.BIND_LAZY);
      if (module == null)
      {
        return Type.INVALID;
      }
      module.symbol ("register_plugin", out function);
      register_plugin = (RegisterModuleFunction) function;
      modules.set_data (name, (owned)module);

      return register_plugin ();
    }

    public Type
    load (string name)
    {
      string path;
      Type module_type = Type.INVALID;

      foreach (unowned string prefix in this.paths)
      {
        if (prefix == null || !FileUtils.test (prefix, FileTest.IS_DIR))
        {
          continue;
        }
        path = Module.build_path (Path.build_filename (prefix,
                                                       Path.get_dirname (name)),
                                  Path.get_basename (name));
        module_type = this.load_from_path (name, path);
        debug ("Plugin type: %s", module_type.name ());
        if (module_type != Type.INVALID)
        {
          break;
        }
      }
      if (module_type == Type.INVALID)
      {
        // try the current directory, as a last resort
        path = Module.build_path (Environment.get_current_dir (),
                                  Path.get_basename (name));
        module_type = this.load_from_path (name, path);
        if (module_type == Type.INVALID)
        {
          warning ("Could not locate the plugin '%s'.", name);
        }
      }

      return module_type;
    }
  }
  private static KeyFile module_config = null;
  public Type
  get_module_type (string prefix, string key) throws GLib.Error
  {
    unowned ModuleLoader loader;
    string cfg_file = "desktop-agnostic.ini";

    if (!Module.supported ())
    {
      throw new ModuleError.NO_GMODULE ("libdesktop-agnostic requires GModule support.");
    }
    if (module_config == null)
    {
      bool loaded_config = false;
      string system_path;
      string user_path;

      module_config = new KeyFile ();
      // load the system file first
      system_path = Path.build_filename (Build.SYSCONFDIR, "xdg",
                                         "libdesktop-agnostic", cfg_file);
      loaded_config = module_config.load_from_file (system_path,
                                                    KeyFileFlags.NONE);
      user_path = Path.build_filename (Environment.get_user_config_dir (),
                                       cfg_file);
      loaded_config |= module_config.load_from_file (user_path,
                                                     KeyFileFlags.NONE);
      if (!loaded_config)
      {
        throw new ModuleError.NO_CONFIG_FOUND ("Could not find any libdesktop-agnostic configuration files.");
      }
    }
    string library = "libda-%s-%s".printf (prefix,
                                           module_config.get_string ("DEFAULT", key));
    loader = ModuleLoader.get_default ();
    return loader.load (library);
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
