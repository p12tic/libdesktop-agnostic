/*
 * Interface for the configuration implementations.
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

using DesktopAgnostic;

namespace DesktopAgnostic.Config
{
  /**
   * Errors which occur when setting/retrieving configuration options.
   */
  public errordomain Error
  {
    NO_SCHEMA,
    INVALID_TYPE,
    KEY_NOT_FOUND,
    NOTIFY
  }
  /**
   * The placeholder used for the default group. In some backends, this
   * indicates that the key associated with it is considered to be on the
   * "top level" of the schema.
   */
  public const string GROUP_DEFAULT = "DEFAULT";
  /**
   * The callback prototype used for notifications when configuration values
   * change.
   */
  public delegate void NotifyFunc (string group, string key, Value value);
  /**
   * The abstract base class that defines what a configuration backend should
   * look like.
   */
  public abstract class Backend : Object
  {
    public abstract string name { owned get; }

    private static HashTable<string,Value?> _backend_metadata_keys;
    public static unowned HashTable<string,Value?>
    get_backend_metadata_keys ()
    {
      if (_backend_metadata_keys == null)
      {
        _backend_metadata_keys =
          new HashTable<string,Value?> (str_hash, str_equal);
      }
      return _backend_metadata_keys;
    }

    private Schema? _schema = null;
    public Schema? schema
    {
      get
      {
        return this._schema;
      }
      construct
      {
        this._schema = value;
      }
    }
    private string? _instance_id;
    public string? instance_id
    {
      get
      {
        return this._instance_id;
      }
      construct
      {
        this._instance_id = value;
      }
    }
    /**
     * Resets the configuration to the default values.
     * @throws Error if something wrong happened during the reset
     */
    public abstract void reset () throws GLib.Error;
    /**
     * Removes all of the configuration.
     * @throws Error if the config removal could not be completed.
     */
    public abstract void remove () throws GLib.Error;
    /**
     * Adds a notification callback to the specified key.
     * @param group the group the key is associated with
     * @param key the config key to associate the callback with
     */
    public abstract void notify_add (string group, string key, NotifyFunc callback) throws GLib.Error;
    /**
     * Manually executes all of the notification callbacks associated with the
     * specified key.
     * @param group the group the key is associated with
     * @param key the config key that is associated with the callback(s)
     */
    public abstract new void notify (string group, string key) throws GLib.Error;
    /**
     * Removes the specified notification callback for the specified key.
     * @param group the group the key is associated with
     * @param key the config key that is associated with the callback
     * @param callback the callback to remove
     * @throws Error if the callback is not associated with the key, among
     * other things
     */
    public abstract void notify_remove (string group, string key, NotifyFunc callback) throws GLib.Error;
    public abstract Value get_value (string group, string key) throws GLib.Error;
    /**
     * Sets the configuration option to the specified value.
     * @param group the group the key is associated with
     * @param key the config key that is associated with the value
     * @param value the new value of the configuration option
     * @throws Error if the group/key does not exist, the value type is not
     * supported, or something bad happened while trying to set the value
     */
    public virtual void
    set_value (string group, string key, Value value) throws GLib.Error
    {
      SchemaOption option = this._schema.get_option (group, key);
      Type option_type;

      if (option == null)
      {
        throw new Error.KEY_NOT_FOUND ("Could not find group and/or key in schema.");
      }

      option_type = option.option_type;

      if (option_type == typeof (bool))
      {
        this.set_bool (group, key, (bool)value);
      }
      else if (option_type == typeof (float))
      {
        this.set_float (group, key, (float)value);
      }
      else if (option_type == typeof (int))
      {
        this.set_int (group, key, (int)value);
      }
      else if (option_type == typeof (string))
      {
        this.set_string (group, key, (string)value);
      }
      else if (option_type == typeof (ValueArray))
      {
        this.set_list (group, key, (ValueArray)value);
      }
      else
      {
        SchemaType st = this.schema.find_type (option_type);
        if (st == null)
        {
          throw new Error.INVALID_TYPE ("Invalid config value type.");
        }
        else
        {
          this.set_string (group, key, st.serialize (value));
        }
      }
    }
    public abstract bool get_bool (string group, string key) throws GLib.Error;
    public abstract void set_bool (string group, string key, bool value) throws GLib.Error;
    public abstract float get_float (string group, string key) throws GLib.Error;
    public abstract void set_float (string group, string key, float value) throws GLib.Error;
    public abstract int get_int (string group, string key) throws GLib.Error;
    public abstract void set_int (string group, string key, int value) throws GLib.Error;
    public abstract string get_string (string group, string key) throws GLib.Error;
    public abstract void set_string (string group, string key, string value) throws GLib.Error;
    public abstract ValueArray get_list (string group, string key) throws GLib.Error;
    public abstract void set_list (string group, string key, ValueArray value) throws GLib.Error;
  }

  private static Type? module_type = null;

  /**
   * Retrieve the default config backend type.
   * @return Config.Backend-based type on succes, Type.INVALID on failure
   */
  public Type
  get_type () throws GLib.Error
  {
    if (module_type == null)
    {
      module_type = get_module_type ("cfg", "config");
    }
    return module_type;
  }

  /**
   * Convenience method for instantiating a configuration backend.
   * @return a Config.Backend object on success, %NULL on failure
   */
  public Backend?
  @new (Schema schema) throws GLib.Error
  {
    Type type = get_type ();
    if (type == Type.INVALID)
    {
      return null;
    }
    else
    {
      return (Config.Backend)Object.new (type,
                                         "schema", schema);
    }
  }

  /**
   * Convenience method for instantiating a configuration backend with an
   * instance ID.
   * @return a Config.Backend object on success, %NULL on failure
   */
  public Backend?
  @new_for_instance (string instance_id,
                     Schema schema) throws GLib.Error
  {
    Type type = get_type ();
    if (type == Type.INVALID)
    {
      return null;
    }
    else
    {
      return (Config.Backend)Object.new (type,
                                         "schema", schema,
                                         "instance_id", instance_id);
    }
  }

}

// vim: set et ts=2 sts=2 sw=2 ai :
