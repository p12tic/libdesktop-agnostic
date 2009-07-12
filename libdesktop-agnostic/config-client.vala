/*
 * Desktop Agnostic Library: Configuration frontend.
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
   * @GLOBAL: Bind the global only to the property.
   * @INSTANCE: Bind the instance only to the property.
   * @FALLBACK: Bind the global to the property if the instance doesn't exist.
   * @BOTH: Bind the global key to ${property_name}-base, and the instance key
   * to ${property_name}.
   */
  public enum BindMethod
  {
    GLOBAL,
    INSTANCE,
    FALLBACK,
    BOTH
  }
  public class Client : Object
  {
    private Schema _schema;
    private Backend global;
    private Backend? instance;
    // properties
    public string? instance_id
    {
      get
      {
        if (this.instance == null)
        {
          return null;
        }
        else
        {
          return this.instance.instance_id;
        }
      }
      construct
      {
        if (value != null)
        {
          Value single_instance = this._schema.get_metadata_option ("single_instance");
          if ((bool)single_instance)
          {
            critical ("The configuration schema has declared that there can only be a single configuration instance.");
          }
          else
          {
            this.instance = Config.new_for_instance (value, this._schema);
          }
        }
      }
    }
    public string schema_filename
    {
      construct
      {
        try
        {
          // force the config module load before creating the schema
          Config.get_type ();
          this._schema = new Schema (value);
          this.global = Config.new (this._schema);
        }
        catch (GLib.Error err)
        {
          critical ("Config error: %s", err.message);
        }
      }
    }
    // constructors
    public Client (string schema_filename)
    {
      this.schema_filename = schema_filename;
    }
    public Client.for_instance (string schema_filename,
                                string instance_id) throws GLib.Error
    {
      this.schema_filename = schema_filename;
      this.instance_id = instance_id;
    }
    // methods
    public bool
    get_bool (string group, string key) throws GLib.Error
    {
      if (this.instance == null)
      {
        return this.global.get_bool (group, key);
      }
      else
      {
        return this.instance.get_bool (group, key);
      }
    }
    public void
    set_bool (string group, string key, bool value) throws GLib.Error
    {
      if (this.instance == null)
      {
        this.global.set_bool (group, key, value);
      }
      else
      {
        this.instance.set_bool (group, key, value);
      }
    }
    public int
    get_int (string group, string key) throws GLib.Error
    {
      if (this.instance == null)
      {
        return this.global.get_int (group, key);
      }
      else
      {
        return this.instance.get_int (group, key);
      }
    }
    public void
    set_int (string group, string key, int value) throws GLib.Error
    {
      if (this.instance == null)
      {
        this.global.set_int (group, key, value);
      }
      else
      {
        this.instance.set_int (group, key, value);
      }
    }
    public float
    get_float (string group, string key) throws GLib.Error
    {
      if (this.instance == null)
      {
        return this.global.get_float (group, key);
      }
      else
      {
        return this.instance.get_float (group, key);
      }
    }
    public void
    set_float (string group, string key, float value) throws GLib.Error
    {
      if (this.instance == null)
      {
        this.global.set_float (group, key, value);
      }
      else
      {
        this.instance.set_float (group, key, value);
      }
    }
    public string
    get_string (string group, string key) throws GLib.Error
    {
      if (this.instance == null)
      {
        return this.global.get_string (group, key);
      }
      else
      {
        return this.instance.get_string (group, key);
      }
    }
    public void
    set_string (string group, string key, string value) throws GLib.Error
    {
      if (this.instance == null)
      {
        this.global.set_string (group, key, value);
      }
      else
      {
        this.instance.set_string (group, key, value);
      }
    }
    public ValueArray
    get_list (string group, string key) throws GLib.Error
    {
      if (this.instance == null)
      {
        return this.global.get_list (group, key);
      }
      else
      {
        return this.instance.get_list (group, key);
      }
    }
    public void
    set_list (string group, string key, ValueArray value) throws GLib.Error
    {
      if (this.instance == null)
      {
        this.global.set_list (group, key, value);
      }
      else
      {
        this.instance.set_list (group, key, value);
      }
    }
    /**
     * Retrieves the value of the configuration key. If the client has an
     * instance ID and the key cannot be found in the instance config, it
     * falls back to retrieving the value from the global config.
     */
    public Value
    get_value (string group, string key) throws GLib.Error
    {
      Value? temp_val = null;
      Value val;

      try
      {
        if (this.instance != null)
        {
          temp_val = this.instance.get_value (group, key);
        }
      }
      catch (GLib.Error err)
      {
        if (!(err is Config.Error.KEY_NOT_FOUND))
        {
          throw err;
        }
      }

      if (temp_val == null)
      {
        val = this.global.get_value (group, key);
      }
      else
      {
        val = temp_val;
      }

      return val;
    }
    public void
    set_value (string group, string key, Value value) throws GLib.Error
    {
      if (this.instance == null)
      {
        this.global.set_value (group, key, value);
      }
      else
      {
        this.instance.set_value (group, key, value);
      }
    }
    public void
    notify_add (string group, string key, NotifyFunc callback)
    {
      if (this.instance != null)
      {
        this.instance.notify_add (group, key, callback);
      }
      this.global.notify_add (group, key, callback);
    }
    public new void
    notify (string group, string key)
    {
      if (this.instance != null)
      {
        this.instance.notify (group, key);
      }
      this.global.notify (group, key);
    }
    public void
    notify_remove (string group, string key,
                   NotifyFunc callback) throws GLib.Error
    {
      if (this.instance != null)
      {
        this.instance.notify_remove (group, key, callback);
      }
      this.global.notify_remove (group, key, callback);
    }
    public void
    remove_instance ()
    {
      this.instance = null;
    }
    public void
    reset (bool instance_only) throws GLib.Error
    {
      if (this.instance != null)
      {
        this.instance.reset ();
      }
      if (!instance_only)
      {
        this.global.reset ();
      }
    }
    /**
     * @param group The configuration group
     * @param key The configuration key
     * @param obj The object to which to bind the config key.
     * @param property_name The name of the property to bind. Has an additional
     * use if @method is #BindMethod.BOTH.
     * @param read_only if TRUE, setting the object property does not propagate
     * to the config backend(s).
     * @param method The method of binding the config backend(s) to the object.
     * @see BindMethod
     */
    public void
    bind (string group, string key, Object obj, string property_name,
          bool read_only, BindMethod method) throws Error
    {
      unowned Bridge bridge = Bridge.get_default ();

      if (method == BindMethod.GLOBAL ||
          method == BindMethod.BOTH ||
          (method == BindMethod.FALLBACK && this.instance == null))
      {
        bridge.bind (this.global, group, key, obj, property_name, read_only);
      }

      if (this.instance != null &&
          (method == BindMethod.INSTANCE ||
           method == BindMethod.BOTH ||
           method == BindMethod.FALLBACK))
      {
        bridge.bind (this.instance, group, key, obj, property_name, read_only);
      }
    }
    /**
     * Removes the bindings between a config key and a GObject property.
     */
    public void
    unbind (string group, string key, Object obj, string property_name,
            bool read_only, BindMethod method) throws Error
    {
      unowned Bridge bridge = Bridge.get_default ();

      if (method == BindMethod.GLOBAL ||
          method == BindMethod.BOTH ||
          (method == BindMethod.FALLBACK && this.instance == null))
      {
        bridge.remove (this.global, group, key, obj, property_name);
      }

      if (this.instance != null &&
          (method == BindMethod.INSTANCE ||
           method == BindMethod.BOTH ||
           method == BindMethod.FALLBACK))
      {
        bridge.remove (this.instance, group, key, obj, property_name);
      }
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai cindent :
