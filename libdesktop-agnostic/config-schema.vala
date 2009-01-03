/* 
 * Desktop Agnostic Library: Configuration Schema.
 *
 * Copyright (C) 2008 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
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
   * The definition of a custom schema type. That is, a schema type which is
   * neither one of the primitive types (boolean, integer, float, string) nor
   * a list.
   */
  public abstract class SchemaType
  {
    /**
     * The name of the schema type, used in the "type" and "list type" schema
     * options for for configuration keys.
     */
    public abstract string name { get; }
    /**
     * The GType associated with the schema type.
     */
    public abstract Type schema_type { get; }
    /**
     * Converts a value into a string, to store in the configuration backend.
     * @param val the value to convert to a string
     * @return the string-serialized version of the value
     * @throws SchemaError if the schema type and the value type are different,
     * or if the serialization fails
     */
    public abstract string serialize (Value val) throws SchemaError;
    /**
     * Converts a serialized string into the corresponding value dictated by the
     * schema type.
     * @param serialized the string to convert into the value
     * @return a container containing the converted value
     * @throws SchemaError if the deserialization fails
     */
    public abstract Value deserialize (string serialized) throws SchemaError;
    /**
     * Converts the default value specified by the schema into the corresponding
     * deserialized value.
     * @param schema the schema from which the default value will be parsed
     * @param group the configuration option's full group/key
     * @return the parsed default value
     * @throws SchemaError if the default value is not found, or could not be
     * parsed correctly.
     */
    public abstract Value parse_default_value (KeyFile schema,
                                               string group) throws SchemaError;
    /**
     * Converts the default list value specified by the schema into the
     * corresponding deserialized value array.
     * @param schema the schema from which the default value will be parsed
     * @param group the configuration option's full group/key
     * @return the parsed default value(s)
     * @throws SchemaError if the default value is not found, or could not be
     * parsed correctly.
     */
    public abstract ValueArray parse_default_list_value (KeyFile schema,
                                                         string group) throws SchemaError;
  }
  /**
   * A representation of one configuration option as defined by the schema.
   */
  public class SchemaOption
  {
    private Type _type;
    /**
     * The type of the configuration option. Can be one of the following types
     * (as represented by GType): boolean, integer, float, string, color, list
     * (AKA ValueArray). If something weird happened, the type is "invalid".
     */
    public Type option_type
    {
      get
      {
        return this._type;
      }
    }
    private Type _list_type;
    /**
     * If the configuration option type is a list (AKA ValueArray), the type
     * of values that the list holds. Can be one of the following: boolean,
     * integer, float, string, color. Otherwise, the list type is "invalid".
     */
    public Type list_type
    {
      get
      {
        return this._list_type;
      }
    }
    private Value _default_value;
    /**
     * The default value of the configuration option. Its value type depends on
     * the option type, and potentially the list type.
     */
    public Value default_value
    {
      get
      {
        return this._default_value;
      }
    }
    private string _description;
    /**
     * The description of the configuration option.
     */
    public string description
    {
      get
      {
        return this._description;
      }
    }
    private string? _summary;
    /**
     * A summary of the configuration option. This is an optional piece of
     * metadata.
     */
    public string? summary
    {
      get
      {
        return this._summary;
      }
    }
    private Value? _lower_boundary;
    /**
     * The lower boundary (inclusive) of a configuration option. This is an
     * optional piece of metadata that is applicable for all types except
     * boolean. For numeric types, the standard usage is observed. For strings,
     * the value must be an integer that indicates its minimum length (in
     * characters). For lists, the value must be an integer that indicates the
     * minimum number of elements present.
     */
    public Value? lower_boundary
    {
      get
      {
        return this._lower_boundary;
      }
    }
    private Value? _upper_boundary;
    /**
     * The upper boundary (inclusive) of a configuration option. This is an
     * optional piece of metadata that is applicable for all types except
     * boolean. For numeric types, the standard usage is observed. For strings,
     * the value must be an integer that indicates its maximum length (in
     * characters). For lists, the value must be an integer that indicates the
     * maximum number of elements present.
     */
    public Value? upper_boundary
    {
      get
      {
        return this._upper_boundary;
      }
    }
    private ValueArray? _whitelist;
    /**
     * A list of values that the configuration option may only be set to. This
     * is an optional piece of metadata that is applicable for all types except
     * boolean. For simple types, the standard usage is observed. For lists,
     * this is a list of values that can only appear as elements in the list.
     * Note that if a blacklist is also present, then the whitelist takes
     * precedence.
     */
    public ValueArray? whitelist
    {
      get
      {
        return this._whitelist;
      }
    }
    private ValueArray? _blacklist;
    /**
     * A list of values that the configuration option may not be set to. This is
     * an optional piece of metadata that is applicable for all types except
     * boolean. For simple types, the standard usage is observed. For lists,
     * this is a list of values that cannot appear as elements in the list. Note
     * that if a whitelist is also present, then the whitelist takes precedence.
     */
    public ValueArray? blacklist
    {
      get
      {
        return this._blacklist;
      }
    }
    /**
     * Parses a schema option from the specification in the schema configuration
     * file.
     * @param schema the schema configuration file
     * @param group the group associated with the configuration option
     * @param key the name of the configuration option
     * @throws Error if any required field for the option is not present, or if
     * any value could not be parsed correctly
     */
    public
    SchemaOption (ref KeyFile schema, string group, string key) throws Error
    {
      string full_key = group + "/" + key;
      this.parse_type (schema.get_value (full_key, "type"));
      this.parse_default_value (schema, full_key);
      // TODO handle proper locale for description/summary
      this._description = schema.get_value (full_key, "description");
      if (schema.has_key (full_key, "summary"))
      {
        this._summary = schema.get_value (full_key, "summary");
      }
      // TODO handle optional upper/lower boundaries
      // TODO handle optional blacklist/whitelist
    }
    /**
     * Determines which GType (and possibly list GType for list types) is described by a string.
     */
    private void
    parse_type (string serialized)
    {
      if (serialized.has_prefix ("list-"))
      {
        this._type = typeof (ValueArray);
        weak string subtype = serialized.offset (5);
        this._list_type = this.parse_simple_type_from_string (subtype);
      }
      else
      {
        this._type = this.parse_simple_type_from_string (serialized);
        this._list_type = Type.INVALID;
      }
    }
    /**
     * Converts a string into a simple type (i.e., not a list).
     */
    private Type
    parse_simple_type_from_string (string serialized)
    {
      Type type;
      switch (serialized)
      {
        case "boolean":
          type = typeof (bool);
          break;
        case "integer":
          type = typeof (int);
          break;
        case "float":
          type = typeof (float);
          break;
        case "string":
          type = typeof (string);
          break;
        case "color":
          type = typeof (Color);
          break;
        default:
          type = Type.INVALID;
          break;
      }
      return type;
    }
    private void
    parse_default_value (KeyFile schema, string group) throws Error
    {
      string key = "default";
      this._default_value = Value (this._type);
      switch (this._type)
      {
        case typeof (bool):
          this._default_value.set_boolean (schema.get_boolean (group, key));
          break;
        case typeof (int):
          this._default_value.set_int (schema.get_integer (group, key));
          break;
        case typeof (float):
          this._default_value.set_float ((float)schema.get_double (group, key));
          break;
        case typeof (string):
          this._default_value.take_string (schema.get_string (group, key));
          break;
        default:
          SchemaType st = Schema.find_type (this._type);
          if (st != null)
          {
            this._default_value = st.deserialize (schema.get_string (group, key));
          }
          else if (this._type == typeof (ValueArray))
          {
            ValueArray array = null;
            switch (this.list_type)
            {
              case typeof (bool):
                bool[] list = schema.get_boolean_list (group, key);
                array = new ValueArray (list.length);
                foreach (bool item in list)
                {
                  Value val = Value (typeof (bool));
                  val.set_boolean (item);
                  array.append (val);
                }
                break;
              case typeof (int):
                int[] list = schema.get_integer_list (group, key);
                array = new ValueArray (list.length);
                foreach (int item in list)
                {
                  Value val = Value (typeof (int));
                  val.set_int (item);
                  array.append (val);
                }
                break;
              case typeof (float):
                double[] list = schema.get_double_list (group, key);
                array = new ValueArray (list.length);
                foreach (double item in list)
                {
                  Value val = Value (typeof (float));
                  val.set_float ((float)item);
                  array.append (val);
                }
                break;
              case typeof (string):
                string[] list = schema.get_string_list (group, key);
                array = new ValueArray (list.length);
                foreach (weak string item in list)
                {
                  Value val = Value (typeof (string));
                  val.take_string (item);
                  array.append (val);
                }
                break;
              default:
                st = Schema.find_type (this._list_type);
                if (st == null)
                {
                  throw new SchemaError.INVALID_LIST_TYPE ("Invalid option list type.");
                }
                else
                {
                  string[] list = schema.get_string_list (group, key);
                  array = new ValueArray (list.length);
                  foreach (weak string item in list)
                  {
                    array.append (st.deserialize (item));
                  }
                }
                break;
            }
            this._default_value.set_boxed (array);
          }
          else
          {
            throw new SchemaError.INVALID_TYPE ("Invalid option type.");
          }
          break;
      }
    }
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
    private static HashTable<Type,SchemaType> type_registry;
    private static HashTable<string,SchemaType> name_registry;
    private static HashTable<string,Value?> common_metadata_keys;
    private List<string> valid_metadata_keys;
    private Datalist<Value?> metadata_options;
    static construct
    {
      type_registry = new HashTable<Type,SchemaType> (int_hash, int_equal);
      name_registry = new HashTable<string,SchemaType> (str_hash, str_equal);
      common_metadata_keys = new HashTable<string,Value?> (str_hash, str_equal);
      Value val = Value (typeof (bool));
      val.set_boolean (true);
      common_metadata_keys.insert ("single_instance", val);
    }
    public Schema (Backend backend, string filename) throws Error
    {
      string basename = null;
      weak HashTable<string,Value?> backend_metadata_keys;
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
      this.valid_metadata_keys = new List<string> ();
      this.metadata_options = Datalist<Value?> ();
      foreach (weak string key in common_metadata_keys.get_keys ())
      {
        this.valid_metadata_keys.append (key);
        this.metadata_options.set_data (key, common_metadata_keys.lookup (key));
      }
      backend_metadata_keys = backend.get_backend_metadata_keys ();
      foreach (weak string key in backend_metadata_keys.get_keys ())
      {
        string option = backend.name + "." + key;
        this.valid_metadata_keys.append (option);
        this.metadata_options.set_data (option,
                                        backend_metadata_keys.lookup (key));
      }
      this.parse ();
    }
    private void
    parse () throws Error
    {
      this.data.load_from_file (this.filename, KeyFileFlags.KEEP_TRANSLATIONS);
      foreach (weak string group in this.data.get_groups ())
      {
        if (group.contains ("/"))
        {
          // split option group & key, add to groups/keys lists
          weak string last_slash = group.rchr (group.length, '/');
          long offset = group.pointer_to_offset (last_slash);
          string option_group = group.substring (0, offset);
          weak string option_key = group.offset (offset + 1);
          weak List<string> list = this.keys.lookup (option_group);
          if (!this.exists (option_group, option_key))
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
          foreach (weak string key in this.data.get_keys (group))
          {
            if (this.valid_metadata_keys.find (key) == null)
            {
              throw new SchemaError.INVALID_METADATA_OPTION ("The option '%s' is not a registered metadata option.", key);
            }
            else
            {
              Value cur_val, new_val;
              cur_val = this.metadata_options.get_data (key);
              new_val = Value (cur_val.type ());
              switch (cur_val.type ())
              {
                case typeof (bool):
                  new_val.set_boolean (this.data.get_boolean (group, key));
                  break;
                case typeof (int):
                  new_val.set_int (this.data.get_integer (group, key));
                  break;
                case typeof (float):
                  new_val.set_float ((float)this.data.get_double (group, key));
                  break;
                case typeof (string):
                  new_val.set_string (this.data.get_string (group, key));
                  break;
                default:
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
    public List<weak string>?
    get_groups ()
    {
      return this.keys.get_keys ();
    }
    /**
     * Retrieves the configuration keys for a specified group in the schema.
     * @param group the group name to search for keys associated with it
     * @return a list of zero or more keys
     */
    public weak List<weak string>?
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
      weak List<weak string> group_keys = this.keys.lookup (group);
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
    public static weak SchemaType?
    find_type (Type type)
    {
      return type_registry.lookup (type);
    }
    public static weak SchemaType?
    find_type_by_name (string name)
    {
      return name_registry.lookup (name);
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
