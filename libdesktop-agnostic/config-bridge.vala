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
  private class Binding : Object
  {
    public unowned Backend cfg;
    public string group;
    public string key;
    public unowned Object obj;
    public string property_name;
    public ulong notify_id;
    public NotifyFunc cfg_notify_func;
    public bool read_only;

    ~Binding ()
    {
      this.cfg.notify_remove (this.group, this.key, this.cfg_notify_func);
      if (!this.read_only && SignalHandler.is_connected (obj, this.notify_id))
      {
        SignalHandler.disconnect (obj, this.notify_id);
      }
      this.obj = null;
    }
  }

  /**
   * Provides a convenient way for a GObject's properties and associated
   * configuration keys to be in sync for the duration of the object's life.
   */
  public class Bridge : Object
  {
    private Datalist<List<Binding>> bindings;
    private HashTable<unowned Object,List<string>> bindings_by_obj;
    private static Bridge bridge = null;

    private Bridge ()
    {
      this.bindings = Datalist<List<Binding>> ();
      this.bindings_by_obj =
        new HashTable<unowned Object,List<string>> (direct_hash, direct_equal);
    }

    /**
     * Retrieves the singleton that manages all of the bindings.
     */
    public static unowned Bridge
    get_default ()
    {
      if (bridge == null)
      {
        bridge = new Bridge ();
      }
      return bridge;
    }

    static unowned ParamSpec?
    get_property_spec (Object obj, string property_name)
    {
      unowned ObjectClass obj_cls = (ObjectClass)(obj.get_type ().class_peek ());
      return obj_cls.find_property (property_name);
    }

    /**
     * Binds a specific object's property with a specific configuration key.
     */
    public void
    bind (Backend config, string group, string key, Object obj,
          string property_name, bool read_only) throws GLib.Error
    {
      Binding binding;
      string binding_key, full_key;
      unowned ParamSpec spec;
      unowned List<Binding>? bindings_list;

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
          binding.cfg_notify_func = this.on_simple_value_changed;
        }
        else if (spec.value_type == typeof (ValueArray))
        {
          obj.set (property_name, config.get_list (group, key));
          binding.cfg_notify_func = this.on_list_changed;
        }
        else
        {
          SchemaType st = Schema.find_type (spec.value_type);
          if (st == null)
          {
            throw new Error.INVALID_TYPE ("Invalid property type to bind: %s.",
                                          spec.value_type.name ());
          }
          else
          {
            obj.set_property (binding.property_name, config.get_value (group, key));
            binding.cfg_notify_func = this.on_serialized_object_changed;
          }
        }
        config.notify_add (group, key, binding.cfg_notify_func);
        if (!read_only)
        {
          binding.notify_id = Signal.connect (obj, "notify::%s".printf (spec.name),
                                              (Callback)this.on_property_changed,
                                              binding);
        }
        binding.read_only = read_only;
        binding_key = "%s/%s".printf (group, key);

        bindings_list = this.bindings.get_data (binding_key);
        if (bindings_list == null)
        {
          List<Binding> new_bindings_list;

          new_bindings_list = new List<Binding> ();
          new_bindings_list.append ((owned)binding);
          this.bindings.set_data (binding_key, (owned)new_bindings_list);
          /* Using the following call will cause bizarre segfaults:
          this.bindings.set_data_full (binding_key, (owned)new_bindings_list,
                                       (DestroyNotify)g_list_free);
          */
        }
        else
        {
          bindings_list.append ((owned)binding);
        }

        full_key = "%s:%s".printf (binding_key, property_name);
        unowned List<string>? key_list = this.bindings_by_obj.lookup (obj);
        if (key_list == null)
        {
          List<string> new_key_list = new List<string> ();
          new_key_list.append (full_key);
          this.bindings_by_obj.insert (obj, (owned)new_key_list);
        }
        else if (key_list.find_custom (full_key, (CompareFunc)strcmp) == null)
        {
          key_list.append (full_key);
        }
      }
      else
      {
        unowned ParamSpec[] properties;
        string props_str;
        properties = ((ObjectClass)(obj.get_type ().class_peek ())).list_properties ();
        props_str = "";
        foreach (unowned ParamSpec property in properties)
        {
          if (props_str != "")
          {
            props_str += ", ";
          }
          props_str += property.name;
        }
        warning ("Invalid property name for the object (%s). Valid properties (%d): %s",
                 property_name, properties.length, props_str);
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
      unowned List<Binding> bindings_list;
      SList<uint> bindings_to_remove;
      uint pos = -1;
      string binding_key;

      binding_key = "%s/%s".printf (group, key);
      bindings_list = this.bindings.get_data (binding_key);
      bindings_to_remove = new SList<uint> ();
      foreach (unowned Binding binding in bindings_list)
      {
        pos++;
        if (binding.obj == obj)
        {
          bindings_to_remove.prepend (pos);
        }
      }
      foreach (uint binding_pos in bindings_to_remove)
      {
        unowned List<Binding> node;

        node = bindings_list.nth (binding_pos);
        node.data = null;
        bindings_list.delete_link (node);
      }
      if (bindings_list.length () == 0)
      {
        this.bindings.remove_data (binding_key);
      }
      else
      {
        List<Binding> new_list;

        new_list = bindings_list.copy ();
        this.bindings.set_data (binding_key, (owned)new_list);
        /* Using the following call will cause bizarre segfaults:
        this.bindings.set_data_full (binding_key, (owned)new_list,
                                     (DestroyNotify)g_list_free);
        */
      }
    }

    /**
     * Removes all of the bindings related to a specific object.
     */
    public void
    remove_all_for_object (Backend config, Object obj) throws Error
    {
      unowned List<string> key_list = this.bindings_by_obj.lookup (obj);
      foreach (unowned string full_key in key_list)
      {
        unowned string property_name = full_key.rchr (-1, ':');
        long property_offset = full_key.pointer_to_offset (property_name);
        property_name = property_name.offset (1);
        unowned string last_slash = full_key.rchr (property_offset, '/');
        long last_slash_offset = full_key.pointer_to_offset (last_slash) + 1;
        string key = full_key.substring (last_slash_offset, property_offset - last_slash_offset);
        string group = full_key.substring (0, last_slash_offset - 1);
        this.remove (config, group, key, obj, property_name);
      }
      this.bindings_by_obj.remove (obj);
    }

    private void
    on_simple_value_changed (string group, string key, Value value)
    {
      unowned List<Binding> bindings_list;
      string full_key;

      full_key = "%s/%s".printf (group, key);
      bindings_list = this.bindings.get_data (full_key);
      foreach (unowned Binding binding in bindings_list)
      {
        if (!binding.read_only)
        {
          SignalHandler.block (binding.obj, binding.notify_id);
        }
        binding.obj.set_property (binding.property_name, value);
        if (!binding.read_only)
        {
          SignalHandler.unblock (binding.obj, binding.notify_id);
        }
      }
    }

    private void
    on_list_changed (string group, string key, Value value)
    {
      unowned List<Binding> bindings_list;
      string full_key;

      full_key = "%s/%s".printf (group, key);
      bindings_list = this.bindings.get_data (full_key);
      foreach (unowned Binding binding in bindings_list)
      {
        if (!binding.read_only)
        {
          SignalHandler.block (binding.obj, binding.notify_id);
        }
        binding.obj.set (binding.property_name, value.get_boxed ());
        if (!binding.read_only)
        {
          SignalHandler.unblock (binding.obj, binding.notify_id);
        }
      }
    }

    private void
    on_serialized_object_changed (string group, string key, Value value)
    {
      unowned List<Binding> bindings_list;
      string full_key;

      full_key = "%s/%s".printf (group, key);
      bindings_list = this.bindings.get_data (full_key);
      foreach (unowned Binding binding in bindings_list)
      {
        ParamSpec spec;
        SchemaType? st;

        spec = this.get_property_spec (binding.obj, binding.property_name);
        st = Schema.find_type (spec.value_type);
        if (st != null)
        {
          if (!binding.read_only)
          {
            SignalHandler.block (binding.obj, binding.notify_id);
          }
          binding.obj.set_property (binding.property_name, value);
          if (!binding.read_only)
          {
            SignalHandler.unblock (binding.obj, binding.notify_id);
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
      catch (GLib.Error err)
      {
        critical ("Configuration error: %s", err.message);
      }
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
