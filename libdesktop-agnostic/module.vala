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

[CCode (cheader_filename = "libdesktop-agnostic/desktop-agnostic.h")]
namespace DesktopAgnostic
{
  public errordomain ModuleError
  {
    NO_GMODULE
  }
  private void
  debug_msg (string message)
  {
    if (Environment.get_variable ("DESKTOP_AGNOSTIC_MODULE_DEBUG") != null)
    {
      debug (message);
    }
  }
  private static Datalist<Module> modules;
  /**
   * Based on the PluginRegistrar class in
   * <http://live.gnome.org/Vala/TypeModules>.
   */
  public class ModuleLoader : Object
  {
    private static string[] paths;

    private static delegate Type RegisterModuleFunction ();

    private static ModuleLoader? module_loader = null;

    static construct
    {
      paths = new string[]
      {
        Environment.get_variable ("DESKTOP_AGNOSTIC_MODULE_DIR"),
        Path.build_filename (Build.LIBDIR, "desktop-agnostic", "modules"),
        Path.build_filename (Environment.get_home_dir (), ".local", "lib",
                             "desktop-agnostic")
      };
      modules = Datalist<Module> ();
    }

    private static delegate Type GuessModuleFunction (ModuleLoader loader, 
                                                      string library_prefix);
    private Module? module_guesser;

    private ModuleLoader ()
    {
      assert (Module.supported ());
      this.module_guesser = null;
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

      debug_msg ("Loading plugin with path: '%s'".printf (path));
      module = Module.open (path, ModuleFlags.BIND_LAZY);
      if (module == null)
      {
        critical ("Could not load the module '%s': %s",
                  path, Module.error ());
        return Type.INVALID;
      }
      else
      {
        void* function = null;

        module.symbol ("register_plugin", out function);
        if (function == null)
        {
          critical ("Could not find entry function for '%s'.", path);
          return Type.INVALID;
        }
        else
        {
          RegisterModuleFunction register_plugin;

          register_plugin = (RegisterModuleFunction) function;
          modules.set_data (name, (owned)module);

          return register_plugin ();
        }
      }
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
        debug_msg ("Plugin type: %s".printf (module_type.name ()));
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
    public bool
    is_guess_module_loaded ()
    {
      return this.module_guesser != null;
    }
    private Module?
    try_load_guess_module (string prefix)
    {
      string library = "libda-module-guesser";
      string path;

      path = Module.build_path (prefix, library);
      return Module.open (path, ModuleFlags.BIND_LAZY);
    }
    public Type
    guess_module (string library_prefix)
    {
      void* function;
      unowned GuessModuleFunction guess_module_fn;

      if (this.module_guesser == null)
      {
        // load the module guesser
        foreach (unowned string prefix in this.paths)
        {
          if (prefix == null || !FileUtils.test (prefix, FileTest.IS_DIR))
          {
            continue;
          }

          this.module_guesser = this.try_load_guess_module (prefix);

          if (this.module_guesser != null)
          {
            break;
          }
        }
        if (this.module_guesser == null)
        {
          // try the current directory, as a last resort
          this.module_guesser = this.try_load_guess_module (Environment.get_current_dir ());
        }
      }
      assert (this.module_guesser != null);

      this.module_guesser.symbol ("guess_module", out function);
      guess_module_fn = (GuessModuleFunction)function;
      return guess_module_fn (this, library_prefix);
    }
  }
  private static KeyFile module_config = null;
  public Type
  get_module_type (string prefix, string key) throws GLib.Error
  {
    unowned ModuleLoader? loader = null;
    string cfg_file = "desktop-agnostic.ini";

    if (!Module.supported ())
    {
      throw new ModuleError.NO_GMODULE ("libdesktop-agnostic requires GModule support.");
    }

    loader = ModuleLoader.get_default ();

    if (module_config == null && !loader.is_guess_module_loaded ())
    {
      bool loaded_config = false;
      string system_path;
      string user_path;

      module_config = new KeyFile ();
      // load the system file first
      system_path = Path.build_filename (Build.SYSCONFDIR, "xdg",
                                         "libdesktop-agnostic", cfg_file);
      try
      {
        if (FileUtils.test (system_path, FileTest.EXISTS))
        {
          debug_msg ("Loading module config from the system: '%s'".printf (system_path));
          loaded_config = module_config.load_from_file (system_path,
                                                        KeyFileFlags.NONE);
        }
      }
      catch (KeyFileError error)
      {
        warning ("KeyFile error: %s", error.message);
      }
      user_path = Path.build_filename (Environment.get_user_config_dir (),
                                       cfg_file);
      try
      {
        if (FileUtils.test (user_path, FileTest.EXISTS))
        {
          debug_msg ("Loading module config from the user directory: '%s'".printf (user_path));
          loaded_config |= module_config.load_from_file (user_path,
                                                         KeyFileFlags.NONE);
        }
      }
      catch (KeyFileError error)
      {
        warning ("KeyFile error: %s", error.message);
      }
    }

    if (module_config.has_group ("DEFAULT"))
    {
      string library = "libda-%s-%s".printf (prefix,
                                             module_config.get_string ("DEFAULT", key));
      return loader.load (library);
    }
    else
    {
      debug_msg ("No module config files found, falling back to guessing.");
      string library_prefix = "libda-%s-".printf (prefix);
      return loader.guess_module (library_prefix);
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
