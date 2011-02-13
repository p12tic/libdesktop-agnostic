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
  private class BindingNotifier : Object
  {
    public unowned Backend config;

    public BindingNotifier (Backend cfg)
    {
      this.config = cfg;
    }

    public void
    on_simple_value_changed (string group, string key, Value value)
    {
      unowned BindingListWrapper? bindings_list;
      string full_key;
      unowned Bridge bridge = Bridge.get_default ();

      full_key = "%s/%s/%s".printf (this.config.instance_id, group, key);
      bindings_list = bridge.get_all_bindings ().get_data (full_key) as BindingListWrapper;
      return_if_fail (bindings_list != null);
      foreach (unowned Binding binding in bindings_list.binding_list)
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

    public void
    on_list_changed (string group, string key, Value value)
    {
      unowned BindingListWrapper? bindings_list;
      string full_key;
      unowned Bridge bridge = Bridge.get_default ();

      full_key = "%s/%s/%s".printf (this.config.instance_id, group, key);
      bindings_list = bridge.get_all_bindings ().get_data (full_key) as BindingListWrapper;
      return_if_fail (bindings_list != null);
      foreach (unowned Binding binding in bindings_list.binding_list)
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

    public void
    on_serialized_object_changed (string group, string key, Value value)
    {
      unowned BindingListWrapper? bindings_list;
      string full_key;
      unowned Bridge bridge = Bridge.get_default ();

      full_key = "%s/%s/%s".printf (this.config.instance_id, group, key);
      bindings_list = bridge.get_all_bindings ().get_data (full_key) as BindingListWrapper;
      return_if_fail (bindings_list != null);
      foreach (unowned Binding binding in bindings_list.binding_list)
      {
        ParamSpec spec;
        SchemaType? st;

        spec = bridge.get_property_spec (binding.obj, binding.property_name);
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
  }

  private class BindingListWrapper : Object
  {
    public List<Binding> binding_list = null;
  }

  private class Binding : Object
  {
    public unowned Backend cfg;
    public string group;
    public string key;
    public unowned Object obj;
    public string property_name;
    public ulong notify_id;
    public bool read_only;

    ~Binding ()
    {
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
    private Datalist<BindingListWrapper> bindings;
    private static Bridge bridge = null;

    private Bridge ()
    {
      this.bindings = Datalist<BindingListWrapper> ();
    }

    public unowned Datalist<Object>
    get_all_bindings ()
    {
      return this.bindings;
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

    public static unowned ParamSpec?
    get_property_spec (Object obj, string property_name)
    {
      unowned ObjectClass obj_cls = (ObjectClass)(obj.get_type ().class_peek ());
      return obj_cls.find_property (property_name);
    }

    private static delegate void NotifyFuncHandler (Config.Backend config,
                                                    string group, string key,
                                                    NotifyFunc func) throws GLib.Error;

    private void
    handle_notify_func (Config.Backend config, string group, string key,
                        Object obj, string property_name,
                        NotifyFuncHandler func) throws GLib.Error
    {
      unowned ParamSpec? spec;

      spec = get_property_spec (obj, property_name);
      if (spec != null)
      {
        this.handle_notify_func_with_param_spec (config, group, key, spec,
                                                 func);
      }
    }

    private void
    handle_notify_func_with_param_spec (Config.Backend config, string group,
                                        string key, ParamSpec spec,
                                        NotifyFuncHandler func) throws GLib.Error
    {
      unowned BindingNotifier? notifier;
      notifier = config.get_data ("lda-binding-notifier");
      if (notifier == null)
      {
        BindingNotifier new_notifier = new BindingNotifier (config);
        notifier = new_notifier;
        config.set_data ("lda-binding-notifier", notifier);
      }

      if (spec.value_type == typeof (bool) ||
          spec.value_type == typeof (float) ||
          spec.value_type == typeof (double) ||
          spec.value_type == typeof (int) ||
          spec.value_type == typeof (long) ||
          spec is ParamSpecEnum ||
          spec.value_type == typeof (string))
      {
        func (config, group, key, notifier.on_simple_value_changed);
      }
      else if (spec.value_type == typeof (ValueArray))
      {
        func (config, group, key, notifier.on_list_changed);
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
          func (config, group, key, notifier.on_serialized_object_changed);
        }
      }
    }

    private static void
    cleanup_bindings (BindingListWrapper obj)
    {
      unowned Bridge bridge = Bridge.get_default ();
      foreach (Binding b in obj.binding_list)
      {
        bridge.remove (b.cfg, b.group, b.key, b.obj, b.property_name);
      }

      obj.unref ();
    }

    /**
     * Binds a specific object's property with a specific configuration key.
     */
    public void
    bind (Backend config, string group, string key, Object obj,
          string property_name, bool read_only) throws GLib.Error
    {
      Binding binding;
      unowned ParamSpec? spec;

      binding = new Binding ();
      binding.cfg = config;
      binding.group = group;
      binding.key = key;
      binding.obj = obj;

      spec = get_property_spec (obj, property_name);
      if (spec != null)
      {
        string binding_key;
        unowned BindingListWrapper? bindings_list;

        binding.property_name = spec.name;

        binding_key = "%s/%s/%s".printf (config.instance_id, group, key);

        // FIXME: check duplicates
        void *obj_bindings = obj.get_data ("lda-bindings");
        if (obj_bindings == null)
        {
          BindingListWrapper new_bindings_list = new BindingListWrapper ();
          new_bindings_list.binding_list.append (binding);

          obj.set_data_full ("lda-bindings", new_bindings_list.@ref (),
                             (DestroyNotify) this.cleanup_bindings);
        }
        else
        {
          unowned BindingListWrapper object_bindings =
            (BindingListWrapper) obj_bindings;
          object_bindings.binding_list.append (binding);
        }

        obj.set_property (spec.name, config.get_value (group, key));
        if (!read_only)
        {
          binding.notify_id = Signal.connect (obj, "notify::%s".printf (spec.name),
                                              (Callback)this.on_property_changed,
                                              binding);
        }
        binding.read_only = read_only;

        bindings_list = this.bindings.get_data (binding_key);
        if (bindings_list == null)
        {
          BindingListWrapper new_bindings_list = new BindingListWrapper ();
          new_bindings_list.binding_list.append (binding);

          this.bindings.set_data_full (binding_key, (owned)new_bindings_list,
                                       (DestroyNotify)Object.unref);
          this.handle_notify_func_with_param_spec (config, group, key, spec,
                                                   config.notify_add);
        }
        else
        {
          bindings_list.binding_list.append (binding);
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
            string property_name) throws GLib.Error
    {
      unowned BindingListWrapper? bindings_list;
      SList<uint> bindings_to_remove;
      uint pos = -1;
      string binding_key;

      unowned BindingListWrapper? obj_bindings = obj.get_data ("lda-bindings");
      binding_key = "%s/%s/%s".printf (config.instance_id, group, key);
      bindings_list = this.bindings.get_data (binding_key);
      bindings_to_remove = new SList<uint> ();

      if (bindings_list == null)
      {
        // FIXME: throw error / warn_if_reached() ?
        return;
      }

      foreach (unowned Binding binding in bindings_list.binding_list)
      {
        pos++;
        if (binding.obj == obj)
        {
          bindings_to_remove.prepend (pos);

          // remove from the per-object list
          if (obj_bindings != null)
          {
            unowned List<Binding> node;
            
            node = obj_bindings.binding_list.find (binding);
            if (node != null)
            {
              node.data = null;
              obj_bindings.binding_list.delete_link (node);
            }
          }
        }
      }
      foreach (uint binding_pos in bindings_to_remove)
      {
        unowned List<Binding> node;

        node = bindings_list.binding_list.nth (binding_pos);
        node.data = null;
        bindings_list.binding_list.delete_link (node);
      }
      if (bindings_list.binding_list.length () == 0)
      {
        this.handle_notify_func (config, group, key, obj, property_name,
                                 config.notify_remove);
        this.bindings.remove_data (binding_key);
      }
    }

    /**
     * Removes all of the bindings related to a specific object.
     */
    public void
    remove_all_for_object (Backend? config, Object obj) throws GLib.Error
    {
      void *data = obj.steal_data ("lda-bindings");
      if (data != null)
      {
        unowned BindingListWrapper obj_bindings = (BindingListWrapper) data;

        foreach (Binding b in obj_bindings.binding_list)
        {
          this.remove (b.cfg, b.group, b.key, obj, b.property_name);
        }

        // now it's safe to unref the ListWrapper
        obj_bindings.unref ();
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
