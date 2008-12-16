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
    INVALID_TYPE,
    INVALID_LIST_TYPE,
    TYPE_NAME_EXISTS,
    TYPE_GTYPE_EXISTS
  }
  public abstract class SchemaType
  {
    public abstract string name { get; }
    public abstract Type schema_type { get; }
    public abstract string serialize (Value val);
    public abstract Value deserialize (string serialized);
    public abstract Value parse_default_value (KeyFile schema, string group);
    public abstract ValueArray parse_default_list_value (KeyFile schema,
                                                         string group);
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
    public
    SchemaOption (ref KeyFile schema, string group, string key) throws KeyFileError
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
      // switch-case breaks gcc because typeof (ValueArray) is not a constant in C
      if (this._type == typeof (bool))
      {
        this._default_value.set_boolean (schema.get_boolean (group, key));
      }
      else if (this._type == typeof (int))
      {
        this._default_value.set_int (schema.get_integer (group, key));
      }
      else if (this._type == typeof (float))
      {
        this._default_value.set_float ((float)schema.get_double (group, key));
      }
      else if (this._type == typeof (string))
      {
        this._default_value.take_string (schema.get_string (group, key));
      }
      else if (this._type == typeof (Color))
      {
        Color color = new Color.from_string (schema.get_string (group, key));
        this._default_value.take_object ((Object)color);
      }
      else if (this._type == typeof (ValueArray))
      {
        ValueArray array = null;
        if (this._list_type == typeof (bool))
        {
          bool[] list = schema.get_boolean_list (group, key);
          array = new ValueArray (list.length);
          foreach (bool item in list)
          {
            Value val = Value (typeof (bool));
            val.set_boolean (item);
            array.append (val);
          }
        }
        else if (this._list_type == typeof (int))
        {
          int[] list = schema.get_integer_list (group, key);
          array = new ValueArray (list.length);
          foreach (int item in list)
          {
            Value val = Value (typeof (int));
            val.set_int (item);
            array.append (val);
          }
        }
        else if (this._list_type == typeof (float))
        {
          double[] list = schema.get_double_list (group, key);
          array = new ValueArray (list.length);
          foreach (double item in list)
          {
            Value val = Value (typeof (float));
            val.set_float ((float)item);
            array.append (val);
          }
        }
        else if (this._list_type == typeof (string))
        {
          string[] list = schema.get_string_list (group, key);
          array = new ValueArray (list.length);
          foreach (weak string item in list)
          {
            Value val = Value (typeof (string));
            val.take_string (item);
            array.append (val);
          }
        }
        else if (this._list_type == typeof (Color))
        {
          string[] list = schema.get_string_list (group, key);
          array = new ValueArray (list.length);
          foreach (weak string item in list)
          {
            Value val = Value (typeof (Color));
            Color color = new Color.from_string (item);
            val.take_object ((Object)color);
            array.append (val);
          }
        }
        else
        {
          throw new SchemaError.INVALID_LIST_TYPE ("Invalid option list type.");
        }
        this._default_value.set_boxed (array);
      }
      else
      {
        throw new SchemaError.INVALID_TYPE ("Invalid option type.");
      }
    }
  }
  [Compact]
  public class Schema
  {
    private string filename;
    private Datalist<SchemaOption> options;
    private KeyFile data;
    private HashTable<string,List<string>> keys;
    private static HashTable<Type,SchemaType> type_registry;
    private static HashTable<string,SchemaType> name_registry;
    static construct
    {
      type_registry = new HashTable<Type,SchemaType> (int_hash, int_equal);
      name_registry = new HashTable<string,SchemaType> (str_hash, str_equal);
    }
    public Schema (string filename) throws Error
    {
      this.filename = filename;
      this.options = Datalist<SchemaOption> ();
      this.keys = new HashTable<string,List<string>> (str_hash, str_equal);
      this.data = new KeyFile ();
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
          // TODO
        }
        else
        {
          throw new SchemaError.PARSE ("Invalid section in schema ('%s'): %s",
                                       this.filename, group);
        }
      }
    }
    public List<weak string>?
    get_groups ()
    {
      return this.keys.get_keys ();
    }
    public weak List<weak string>?
    get_keys (string group)
    {
      return this.keys.lookup (group);
    }
    public bool
    exists (string group, string key)
    {
      weak List<weak string> group_keys = this.keys.lookup (group);
      return group_keys != null &&
             group_keys.find_custom (key, (CompareFunc)strcmp) != null;
    }
    public SchemaOption
    get_option (string group, string key)
    {
      string full_key = group + "/" + key;
      return this.options.get_data (full_key);
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
