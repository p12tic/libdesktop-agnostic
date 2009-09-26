/*
 * Desktop Agnostic Library: Configuration Schema Abstract Type.
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

namespace DesktopAgnostic.Config
{
  /**
   * A representation of one configuration option as defined by the schema.
   */
  public class SchemaOption : Object
  {
    /**
     * The type of the configuration option. Can be one of the following types
     * (as represented by GType): boolean, integer, float, string, color, list
     * (AKA ValueArray). If something weird happened, the type is "invalid".
     */
    public Type option_type { get; private set; }
    /**
     * If the configuration option type is a list (AKA ValueArray), the type
     * of values that the list holds. Can be one of the following: boolean,
     * integer, float, string, color. Otherwise, the list type is "invalid".
     */
    public Type list_type { get; private set; }
    /**
     * The default value of the configuration option. Its value type depends on
     * the option type, and potentially the list type.
     */
    public Value default_value { get; private set; }
    /**
     * The description of the configuration option.
     */
    public string description { get; private set; }
    /**
     * A summary of the configuration option. This is an optional piece of
     * metadata.
     */
    public string? summary { get; private set; }
    /**
     * The lower boundary (inclusive) of a configuration option. This is an
     * optional piece of metadata that is applicable for all types except
     * boolean. For numeric types, the standard usage is observed. For strings,
     * the value must be an integer that indicates its minimum length (in
     * characters). For lists, the value must be an integer that indicates the
     * minimum number of elements present.
     */
    public Value? lower_boundary { get; private set; }
    /**
     * The upper boundary (inclusive) of a configuration option. This is an
     * optional piece of metadata that is applicable for all types except
     * boolean. For numeric types, the standard usage is observed. For strings,
     * the value must be an integer that indicates its maximum length (in
     * characters). For lists, the value must be an integer that indicates the
     * maximum number of elements present.
     */
    public Value? upper_boundary { get; private set; }
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
     * Determines whether a configuration option is per instance, or applied
     * towards all instances of the configuration. Defaults to true. Note that
     * this option only applies if the "single_instance" metadata key is false.
     */
    public bool per_instance { get; private set; default = true; }
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
    SchemaOption (ref KeyFile schema, string group, string key) throws GLib.Error
    {
      string full_key = group + "/" + key;
      this.parse_type (schema.get_value (full_key, "type"));
      this.parse_default_value (schema, full_key);
      // TODO handle proper locale for description/summary
      this.description = schema.get_value (full_key, "description");
      if (schema.has_key (full_key, "summary"))
      {
        this.summary = schema.get_value (full_key, "summary");
      }
      // TODO handle optional upper/lower boundaries
      // TODO handle optional blacklist/whitelist
      if (schema.has_key (full_key, "per_instance"))
      {
        this.per_instance = schema.get_boolean (full_key, "per_instance");
      }
    }
    /**
     * Determines which GType (and possibly list GType for list types) is described by a string.
     */
    private void
    parse_type (string serialized)
    {
      if (serialized.has_prefix ("list-"))
      {
        this.option_type = typeof (ValueArray);
        unowned string subtype = serialized.offset (5);
        this.list_type = this.parse_simple_type_from_string (subtype);
      }
      else
      {
        this.option_type = this.parse_simple_type_from_string (serialized);
        this.list_type = Type.INVALID;
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
        default:
          SchemaType st = Schema.find_type_by_name (serialized);
          if (st == null)
          {
            type = Type.INVALID;
          }
          else
          {
            type = st.schema_type;
          }
          break;
      }
      return type;
    }
    private void
    parse_default_value (KeyFile schema, string group) throws GLib.Error
    {
      string key = "default";
      try
      {
        if (this.option_type == typeof (bool))
        {
          this._default_value = schema.get_boolean (group, key);
        }
        else if (this.option_type == typeof (int))
        {
          this._default_value = schema.get_integer (group, key);
        }
        else if (this.option_type == typeof (float))
        {
          this._default_value = (float)schema.get_double (group, key);
        }
        else if (this.option_type == typeof (string))
        {
          this._default_value = schema.get_string (group, key);
        }
        else
        {
          SchemaType st = Schema.find_type (this.option_type);
          if (st != null)
          {
            this._default_value = st.deserialize (schema.get_string (group, key));
          }
          else if (this.option_type == typeof (ValueArray))
          {
            ValueArray array = null;
            if (schema.get_value (group, key) == "")
            {
              // special case for empty arrays
              array = new ValueArray (0);
            }
            else if (this.list_type == typeof (bool))
            {
              bool[] list = schema.get_boolean_list (group, key);
              array = new ValueArray (list.length);
              foreach (bool item in list)
              {
                Value val;
                val = item;
                array.append (val);
              }
            }
            else if (this.list_type == typeof (int))
            {
              int[] list = schema.get_integer_list (group, key);
              array = new ValueArray (list.length);
              foreach (int item in list)
              {
                Value val;
                val = item;
                array.append (val);
              }
            }
            else if (this.list_type == typeof (float))
            {
              double[] list = schema.get_double_list (group, key);
              array = new ValueArray (list.length);
              foreach (double item in list)
              {
                Value val;
                val = (float)item;
                array.append (val);
              }
            }
            else if (this.list_type == typeof (string))
            {
              string[] list = schema.get_string_list (group, key);
              array = new ValueArray (list.length);
              foreach (unowned string item in list)
              {
                Value val;
                val = item;
                array.append (val);
              }
            }
            else
            {
              st = Schema.find_type (this.list_type);
              if (st == null)
              {
                throw new SchemaError.INVALID_LIST_TYPE ("Invalid option list type for %s: %s (given: '%s').",
                                                         group, this.list_type.name (),
                                                         schema.get_value (group, "type"));
              }
              else
              {
                string[] list = schema.get_string_list (group, key);
                array = new ValueArray (list.length);
                foreach (unowned string item in list)
                {
                  array.append (st.deserialize (item));
                }
              }
            }
            this._default_value = array;
          }
          else
          {
            throw new SchemaError.INVALID_TYPE ("Invalid option type for %s: %s (given: '%s').",
                                                group, this.option_type.name (),
                                                schema.get_value (group, "type"));
          }
        }
      }
      catch (KeyFileError err)
      {
        if (err is KeyFileError.INVALID_VALUE)
        {
          throw new KeyFileError.INVALID_VALUE ("%s (key: %s)", err.message, group);
        }
        else
        {
          throw err;
        }
      }
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
