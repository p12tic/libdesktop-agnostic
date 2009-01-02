/* 
 * Provides a method to bind configuration entries to a GObject.
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
 * Author : Neil J. Patel <njpatel@gmail.com> (Original C code)
 * Author : Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 */

using GLib;

namespace DesktopAgnostic.Config
{
  [Compact]
  private class Binding
  {
    public Object obj;
    public string property_name;
  }

  public class Bridge : Object
  {
    private Datalist<weak Binding> bindings;
    private static Bridge bridge = null;

    construct
    {
      this.bindings = Datalist<weak Binding> ();
    }

    public static weak Bridge
    get_default ()
    {
      if (bridge == null)
      {
        bridge = new Bridge ();
      }
      return bridge;
    }

    public void
    bind (Backend config, string group, string key, Object obj, string property_name)
    {
      Binding binding;
      string binding_key;
      ParamSpec spec;

      binding = new Binding ();
      binding.obj = obj;
      binding.property_name = property_name;
      spec = ((ObjectClass)(obj.get_type ().class_peek ())).find_property (property_name);
      if (spec != null)
      {
        switch (spec.value_type)
        {
          case typeof (bool):
            obj.set (property_name, config.get_bool (group, key));
            config.notify_add (group, key, this.on_bool_changed);
            break;
          case typeof (float):
          case typeof (double):
            obj.set (property_name, config.get_float (group, key));
            config.notify_add (group, key, this.on_float_changed);
            break;
          case typeof (int):
            obj.set (property_name, config.get_int (group, key));
            config.notify_add (group, key, this.on_int_changed);
            break;
          case typeof (string):
            obj.set (property_name, config.get_string (group, key));
            config.notify_add (group, key, this.on_string_changed);
            break;
          default:
            if (spec.value_type == typeof (ValueArray))
            {
              obj.set (property_name, config.get_list (group, key));
              config.notify_add (group, key, this.on_list_changed);
            }
            else
            {
              warning ("Invalid property type to bind.");
              return;
            }
            break;
        }
        binding_key = group + "/" + key;
        bindings.set_data (binding_key, binding);
      }
      else
      {
        weak ParamSpec[] properties;
        string props_str;
        properties = ((ObjectClass)(obj.get_type ().class_peek ())).list_properties ();
        props_str = "";
        for (int i = 0; i < properties.length; i++)
        {
          if (props_str != "")
          {
            props_str += ", ";
          }
          props_str += properties[i].name;
        }
        warning ("Invalid property name for the object. Valid properties (%d): %s",
                 properties.length, props_str);
      }
    }

    private void
    remove (Backend config, string group, string key, Object obj, string property_name)
    {
      weak Binding binding;
      string binding_key;
      ParamSpec spec;

      binding_key = group + "/" + key;
      binding = bindings.get_data (binding_key);
      if (binding != null && binding.obj == obj)
      {
        binding.obj = null;
        spec = ((ObjectClass)(obj.get_type ().class_peek ())).find_property (property_name);
        switch (spec.value_type)
        {
          case typeof (bool):
            config.notify_remove (group, key, this.on_bool_changed);
            break;
          case typeof (float):
          case typeof (double):
            config.notify_remove (group, key, this.on_float_changed);
            break;
          case typeof (int):
            config.notify_remove (group, key, this.on_int_changed);
            break;
          case typeof (string):
            config.notify_remove (group, key, this.on_string_changed);
            break;
          default:
            if (spec.value_type == typeof (ValueArray))
            {
              config.notify_remove (group, key, this.on_list_changed);
            }
            else
            {
              warning ("Invalid property type to remove a binding from.");
              return;
            }
            break;
        }
      }
    }
    
    private void
    on_bool_changed (NotifyEntry entry)
    {
      weak Binding binding;
      string key;

      key = entry.group + "/" + entry.key;
      binding = (Binding)this.bindings.get_data (key);
      binding.obj.set (binding.property_name, entry.value.get_boolean ());
    }

    private void
    on_float_changed (NotifyEntry entry)
    {
      weak Binding binding;
      string key;

      key = entry.group + "/" + entry.key;
      binding = (Binding)this.bindings.get_data (key);
      binding.obj.set (binding.property_name, entry.value.get_float ());
    }

    private void
    on_int_changed (NotifyEntry entry)
    {
      weak Binding binding;
      string key;

      key = entry.group + "/" + entry.key;
      binding = (Binding)this.bindings.get_data (key);
      binding.obj.set (binding.property_name, entry.value.get_int ());
    }

    private void
    on_string_changed (NotifyEntry entry)
    {
      weak Binding binding;
      string key;

      key = entry.group + "/" + entry.key;
      binding = (Binding)this.bindings.get_data (key);
      binding.obj.set (binding.property_name, entry.value.get_string ());
    }

    private void
    on_list_changed (NotifyEntry entry)
    {
      weak Binding binding;
      string key;

      key = entry.group + "/" + entry.key;
      binding = (Binding)this.bindings.get_data (key);
      binding.obj.set (binding.property_name, entry.value.get_boxed ());
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
