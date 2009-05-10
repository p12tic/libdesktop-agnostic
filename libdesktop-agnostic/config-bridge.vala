/* 
 * Provides a method to bind configuration entries to a GObject.
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
 * Author : Neil J. Patel <njpatel@gmail.com> (Original C code)
 * Author : Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 */

namespace DesktopAgnostic.Config
{
  /**
   * Note: trying to get this working as a struct seems to be more trouble than
   * it's worth.
   */
  [Compact]
  private class Binding
  {
    public Backend cfg;
    public string group;
    public string key;
    public Object obj;
    public string property_name;
    public ulong notify_id;
    public bool read_only;
  }

  /**
   * Provides a convenient way for a GObject's properties and associated
   * configuration keys to be in sync for the duration of the object's life.
   */
  public class Bridge : Object
  {
    private Datalist<List<Binding>> bindings;
    private HashTable<Object,List<string>> bindings_by_obj;
    private static Bridge bridge = null;

    private Bridge ()
    {
      this.bindings = Datalist<List<Binding>> ();
      this.bindings_by_obj =
        new HashTable<Object,List<string>> (direct_hash, direct_equal);
    }

    /**
     * Retrieves the singleton that manages all of the bindings.
     */
    public static weak Bridge
    get_default ()
    {
      if (bridge == null)
      {
        bridge = new Bridge ();
      }
      return bridge;
    }

    private weak ParamSpec?
    get_property_spec (Object obj, string property_name)
    {
      weak ObjectClass obj_cls = (ObjectClass)(obj.get_type ().class_peek ());
      return obj_cls.find_property (property_name);
    }

    /**
     * Binds a specific object's property with a specific configuration key.
     */
    public void
    bind (Backend config, string group, string key, Object obj,
          string property_name, bool read_only) throws Error
    {
      Binding binding;
      string binding_key, full_key;
      weak ParamSpec spec;

      binding = new Binding ();
      binding.cfg = config;
      binding.group = group;
      binding.key = key;
      binding.obj = obj;
      binding.property_name = property_name;
      spec = this.get_property_spec (obj, property_name);
      if (spec != null)
      {
        if (spec.value_type == typeof (bool) ||
            spec.value_type == typeof (float) ||
            spec.value_type == typeof (double) ||
            spec.value_type == typeof (int) ||
            spec.value_type == typeof (string))
        {
          obj.set_property (property_name, config.get_value (group, key));
          config.notify_add (group, key, this.on_simple_value_changed);
        }
        else if (spec.value_type == typeof (ValueArray))
        {
          obj.set (property_name, config.get_list (group, key));
          config.notify_add (group, key, this.on_list_changed);
        }
        else
        {
          SchemaType st = Schema.find_type (spec.value_type);
          if (st == null)
          {
            throw new ConfigError.INVALID_TYPE ("Invalid property type to bind.");
          }
          else
          {
            Value val = st.deserialize (config.get_string (group, key));
            obj.set_property (binding.property_name, val);
            config.notify_add (group, key, this.on_serialized_object_changed);
          }
        }
        if (!read_only)
        {
          binding.notify_id = Signal.connect (obj, "notify::" + spec.name,
                                              (Callback)this.on_property_changed,
                                              binding);
        }
        binding.read_only = read_only;
        binding_key = group + "/" + key;
        weak List<Binding> bindings_list = this.bindings.get_data (binding_key);
        bindings_list.append ((owned)binding);
        full_key = binding_key + ":" + property_name;
        weak List<string> key_list = this.bindings_by_obj.lookup (obj);
        if (key_list.find_custom (full_key, (CompareFunc)strcmp) == null)
        {
          key_list.append (full_key);
        }
      }
      else
      {
        weak ParamSpec[] properties;
        string props_str;
        properties = ((ObjectClass)(obj.get_type ().class_peek ())).list_properties ();
        props_str = "";
        foreach (weak ParamSpec property in properties)
        {
          if (props_str != "")
          {
            props_str += ", ";
          }
          props_str += property.name;
        }
        warning ("Invalid property name for the object. Valid properties (%d): %s",
                 properties.length, props_str);
      }
    }

    /**
     * Removes a binding between a specific configuration key and a specific
     * object's property.
     */
    public void
    remove (Backend config, string group, string key, Object obj,
            string property_name) throws Error
    {
      weak List<Binding> bindings_list;
      string binding_key;
      weak ParamSpec spec;

      binding_key = group + "/" + key;
      bindings_list = this.bindings.get_data (binding_key);
      foreach (weak Binding binding in bindings_list)
      {
        if (binding.obj == obj)
        {
          binding.obj = null;
          spec = this.get_property_spec (obj, property_name);
          if (spec.value_type == typeof (bool) ||
              spec.value_type == typeof (float) ||
              spec.value_type == typeof (double) ||
              spec.value_type == typeof (int) ||
              spec.value_type == typeof (string))
          {
            config.notify_remove (group, key, this.on_simple_value_changed);
          }
          else if (spec.value_type == typeof (ValueArray))
          {
            config.notify_remove (group, key, this.on_list_changed);

          }
          else
          {
            SchemaType st = Schema.find_type (spec.value_type);
            if (st == null)
            {
              throw new ConfigError.INVALID_TYPE ("Invalid property type to remove a binding from.");
            }
            else
            {
              config.notify_remove (group, key, this.on_serialized_object_changed);
            }
          }
          if (!binding.read_only)
          {
            SignalHandler.disconnect (obj, binding.notify_id);
          }
          bindings_list.remove (binding);
        }
      }
    }

    /**
     * Removes all of the bindings related to a specific object.
     */
    public void
    remove_all_for_object (Backend config, Object obj) throws Error
    {
      weak List<string> key_list = this.bindings_by_obj.lookup (obj);
      foreach (weak string full_key in key_list)
      {
        weak string property_name = full_key.rchr (-1, ':');
        long property_offset = full_key.pointer_to_offset (property_name);
        property_name = property_name.offset (1);
        weak string last_slash = full_key.rchr (property_offset, '/');
        long last_slash_offset = full_key.pointer_to_offset (last_slash) + 1;
        string key = full_key.substring (last_slash_offset, property_offset - last_slash_offset);
        string group = full_key.substring (0, last_slash_offset - 1);
        this.remove (config, group, key, obj, property_name);
      }
      this.bindings_by_obj.remove (obj);
    }

    private void
    on_simple_value_changed (NotifyEntry entry)
    {
      weak List<Binding> bindings_list;
      string key;

      key = entry.group + "/" + entry.key;
      bindings_list = this.bindings.get_data (key);
      foreach (weak Binding binding in bindings_list)
      {
        if (!binding.read_only)
        {
          SignalHandler.block (binding.obj, binding.notify_id);
        }
        binding.obj.set_property (binding.property_name, entry.value);
        if (!binding.read_only)
        {
          SignalHandler.unblock (binding.obj, binding.notify_id);
        }
      }
    }

    private void
    on_list_changed (NotifyEntry entry)
    {
      weak List<Binding> bindings_list;
      string key;

      key = entry.group + "/" + entry.key;
      bindings_list = this.bindings.get_data (key);
      foreach (weak Binding binding in bindings_list)
      {
        if (!binding.read_only)
        {
          SignalHandler.block (binding.obj, binding.notify_id);
        }
        binding.obj.set (binding.property_name, entry.value.get_boxed ());
        if (!binding.read_only)
        {
          SignalHandler.unblock (binding.obj, binding.notify_id);
        }
      }
    }

    private void
    on_serialized_object_changed (NotifyEntry entry)
    {
      weak List<Binding> bindings_list;
      string key;

      key = entry.group + "/" + entry.key;
      bindings_list = this.bindings.get_data (key);
      foreach (weak Binding binding in bindings_list)
      {
        ParamSpec spec = this.get_property_spec (binding.obj,
                                                 binding.property_name);
        SchemaType? st = Schema.find_type (spec.value_type);
        if (st != null)
        {
          try
          {
            Value val = st.deserialize (entry.value.get_string ());
            if (!binding.read_only)
            {
              SignalHandler.block (binding.obj, binding.notify_id);
            }
            binding.obj.set_property (binding.property_name, val);
            if (!binding.read_only)
            {
              SignalHandler.unblock (binding.obj, binding.notify_id);
            }
          }
          catch (SchemaError err)
          {
            critical (err.message);
          }
        }
      }
    }

    private static void
    on_property_changed (Object obj, ParamSpec spec, Binding binding)
    {
      try
      {
        Value val = Value (spec.value_type);
        obj.get_property (spec.name, ref val);
        binding.cfg.set_value (binding.group, binding.key, val);
      }
      catch (Error err)
      {
        critical (err.message);
      }
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
