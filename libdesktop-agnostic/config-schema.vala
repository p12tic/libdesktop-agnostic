/* 
 * Desktop Agnostic Library: Configuration Schema.
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

using DesktopAgnostic.VFS;

namespace DesktopAgnostic.Config
{
  /**
   * Configuration schema error types.
   */
  public errordomain SchemaError
  {
    PARSE,
    INVALID_METADATA_OPTION,
    INVALID_METADATA_TYPE,
    INVALID_TYPE,
    INVALID_LIST_TYPE,
    TYPE_NAME_EXISTS,
    TYPE_GTYPE_EXISTS
  }
  /**
   * A representation of a configuration schema, comprised of one or more
   * configuration options.
   */
  public class Schema : Object
  {
    private string filename;
    private string _app_name;
    public string app_name
    {
      get
      {
        return this._app_name;
      }
      construct
      {
        this._app_name = value;
      }
    }
    private Datalist<SchemaOption> options;
    private KeyFile data;
    private HashTable<string,List<string>> keys;
    private static HashTable<Type,SchemaType> type_registry = 
      new HashTable<Type,SchemaType> ((HashFunc)type_hash,
                                      (EqualFunc)type_equal);
    private static HashTable<string,SchemaType> name_registry =
      new HashTable<string,SchemaType> (str_hash, str_equal);
    private static HashTable<string,Value?> common_metadata_keys =
      new HashTable<string,Value?> (str_hash, str_equal);
    private List<string> valid_metadata_keys;
    private Datalist<Value?> metadata_options;
    static construct
    {
      // Load the type modules
      List<string> type_modules = new List<string> ();
      string[] paths = ModuleLoader.get_search_paths ();
      SList<string> search_paths = new SList<string> ();
      foreach (unowned string path in paths)
      {
        if (path != null)
        {
          search_paths.append (path);
        }
      }
      search_paths.append (Environment.get_current_dir ());
      foreach (unowned string path in search_paths)
      {
        if (!FileUtils.test (path, FileTest.IS_DIR))
        {
          continue;
        }
        Glob found_modules;
        string module = Path.build_filename (path, "libda-cfg-type-*");
        try
        {
          found_modules = Glob.execute (module);
        }
        catch (GlobError err)
        {
          if (err is GlobError.NOMATCH)
          {
            continue;
          }
          else
          {
            throw err;
          }
        }
        foreach (unowned string fm in found_modules.paths)
        {
          if (type_modules.find (fm) == null)
          {
            ModuleLoader loader = new ModuleLoader (Path.get_basename (fm));
            if (loader.load_from_path (fm))
            {
              try
              {
                Type type = loader.module_type;
                Object obj = Object.new (type);
                register_type ((SchemaType)((owned)obj));
                type_modules.append (fm);
              }
              catch (SchemaError err)
              {
                warning ("Schema error: %s", err.message);
              }
            }
            else
            {
              warning ("Could not load the config type module: %s", fm);
            }
          }
        }
      }
      // initialize the common metadata keys hashtable
      Value val = Value (typeof (bool));
      val.set_boolean (true);
      common_metadata_keys.insert ("single_instance", val);
    }
    /**
     * Creates a new Schema object.
     * @param backend the configuration backend associated with the schema
     * @param filename the name of the schema file to parse
     */
    public Schema (Backend backend, string filename) throws Error
    {
      string basename = null;
      unowned HashTable<string,Value?> backend_metadata_keys;
      if (!filename.has_suffix (".schema-ini"))
      {
        throw new SchemaError.PARSE ("Schema files MUST have the extension '.schema-ini'.");
      }
      this.filename = filename;
      basename = Path.get_basename (filename);
      this.app_name = basename.substring (0, basename.length - 11);
      this.options = Datalist<SchemaOption> ();
      this.keys = new HashTable<string,List<string>> (str_hash, str_equal);
      this.data = new KeyFile ();
      // populate the common metadata keys table
      this.valid_metadata_keys = new List<string> ();
      this.metadata_options = Datalist<Value?> ();
      foreach (unowned string key in common_metadata_keys.get_keys ())
      {
        this.valid_metadata_keys.append (key);
        this.metadata_options.set_data (key, common_metadata_keys.lookup (key));
      }
      // populate the backend-specific metadata keys table
      backend_metadata_keys = backend.get_backend_metadata_keys ();
      foreach (unowned string key in backend_metadata_keys.get_keys ())
      {
        string option = backend.name + "." + key;
        this.valid_metadata_keys.append (option);
        this.metadata_options.set_data (option,
                                        backend_metadata_keys.lookup (key));
      }
      this.parse ();
    }
    private void
    parse () throws GLib.Error
    {
      this.data.load_from_file (this.filename, KeyFileFlags.KEEP_TRANSLATIONS);
      foreach (unowned string group in this.data.get_groups ())
      {
        if (group.contains ("/"))
        {
          // split option group & key, add to groups/keys lists
          unowned string last_slash = group.rchr (group.length, '/');
          long offset = group.pointer_to_offset (last_slash);
          string option_group = group.substring (0, offset);
          unowned string option_key = group.offset (offset + 1);
          unowned List<string>? list = this.keys.lookup (option_group);
          if (list == null)
          {
            List<string> key_list = new List<string> ();
            key_list.append (option_key);
            this.keys.insert (option_group, (owned)key_list);
          }
          else if (!this.exists (option_group, option_key))
          {
            list.append (option_key);
          }
          else
          {
            throw new SchemaError.PARSE ("Duplicate key found in '%s': %s",
                                         option_group, option_key);
          }
          // create a new schema option and add to options list
          SchemaOption option = new SchemaOption (ref this.data, option_group,
                                                  option_key);
          this.options.set_data (group, option);
        }
        else if (group == DesktopAgnostic.Config.GROUP_DEFAULT)
        {
          // parse the schema metadata
          foreach (unowned string key in this.data.get_keys (group))
          {
            if (this.valid_metadata_keys.find (key) == null)
            {
              throw new SchemaError.INVALID_METADATA_OPTION ("The option '%s' is not a registered metadata option.", key);
            }
            else
            {
              Value cur_val, new_val;
              Type cur_val_type;

              cur_val = this.metadata_options.get_data (key);
              cur_val_type = cur_val.type ();
              new_val = Value (cur_val_type);
              if (cur_val_type == typeof (bool))
              {
                new_val.set_boolean (this.data.get_boolean (group, key));
              }
              else if (cur_val_type == typeof (int))
              {
                new_val.set_int (this.data.get_integer (group, key));
              }
              else if (cur_val_type == typeof (float))
              {
                new_val.set_float ((float)this.data.get_double (group, key));
              }
              else if (cur_val_type == typeof (string))
              {
                new_val.set_string (this.data.get_string (group, key));
              }
              else
              {
                throw new SchemaError.INVALID_METADATA_TYPE ("The metadata option type can only be a simple type.");
              }
              this.metadata_options.set_data (key, new_val);
            }
          }
        }
        else
        {
          throw new SchemaError.PARSE ("Invalid section in schema ('%s'): %s",
                                       this.filename, group);
        }
      }
    }
    /**
     * Retrieves the configuration groups in the schema.
     * @return a list of zero or more groups
     */
    public List<unowned string>?
    get_groups ()
    {
      return this.keys.get_keys ();
    }
    /**
     * Retrieves the configuration keys for a specified group in the schema.
     * @param group the group name to search for keys associated with it
     * @return a list of zero or more keys
     */
    public unowned List<unowned string>?
    get_keys (string group)
    {
      return this.keys.lookup (group);
    }
    /**
     * Determines if a specified group/key exists in the schema.
     * @param group the group that the key is associated with
     * @param key the configuration key to determine if it exists
     * @return whether the group/key exists
     */
    public bool
    exists (string group, string key)
    {
      unowned List<unowned string> group_keys = this.keys.lookup (group);
      return group_keys != null &&
             group_keys.find_custom (key, (CompareFunc)strcmp) != null;
    }
    /**
     * Retrieves the metadata associated with a specific group/key.
     * @param group the group that the key is associated with
     * @param key the configuration key to retrieve metadata from
     * @return an object which contains the option metadata
     */
    public SchemaOption
    get_option (string group, string key)
    {
      string full_key = group + "/" + key;
      return this.options.get_data (full_key);
    }
    /**
     * Retrieves the value of the specified metadata option.
     * @throws SchemaError if the option named specified is not registered
     */
    public Value?
    get_metadata_option (string name) throws SchemaError
    {
      if (this.valid_metadata_keys.find (name) == null)
      {
        throw new SchemaError.INVALID_METADATA_OPTION ("The option '%s' is not a registered metadata option.", name);
      }
      else
      {
        return this.metadata_options.get_data (name);
      }
    }
    private static uint
    type_hash (void* key)
    {
      return (uint)key;
    }
    private static bool
    type_equal (void* a, void* b)
    {
      return (Type)a == (Type)b;
    }
    /**
     * Registers a configuration schema type with the class. This is usually
     * not called manually - the class loads all of the configuration schema
     * type modules that it can find when the class is first instantiated.
     */
    public static void
    register_type (SchemaType st) throws SchemaError
    {
      if (type_registry.lookup (st.schema_type) != null)
      {
        throw new SchemaError.TYPE_GTYPE_EXISTS ("The GType associated with the SchemaType is already registered.");
      }
      else if (name_registry.lookup (st.name) != null)
      {
        throw new SchemaError.TYPE_NAME_EXISTS ("The name associated with the SchemaType is already registered.");
      }
      else
      {
        type_registry.insert (st.schema_type, st);
        name_registry.insert (st.name, st);
      }
    }
    /**
     * Looks for a registered SchemaType by its GType.
     */
    public static unowned SchemaType?
    find_type (Type type)
    {
      return type_registry.lookup (type);
    }
    /**
     * Looks for a registered SchemaType by its declared name.
     */
    public static unowned SchemaType?
    find_type_by_name (string name)
    {
      return name_registry.lookup (name);
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
