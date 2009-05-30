/* 
 * GConf implementation of the configuration interface.
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

using GConf;

namespace DesktopAgnostic.Config
{
  [Compact]
  private class NotifyData
  {
    public NotifyFunc callback;
    public uint func_id;
  }
  public class GConfBackend : Backend
  {
    private string path;
    private Client client;
    private Datalist<unowned SList<unowned NotifyData>> notify_funcs;

    public override string name
    {
      get
      {
        return "GConf";
      }
    }

    static construct
    {
      GLib.Value val;
      val = GLib.Value (typeof (string));
      val.set_string ("/apps");
      unowned HashTable<string,GLib.Value?> backend_metadata_keys = get_backend_metadata_keys ();
      backend_metadata_keys.insert ("base_path", val);
      val = GLib.Value (typeof (string));
      val.set_string ("${base_path}/instances");
      backend_metadata_keys.insert ("base_instance_path", val);
    }

    construct
    {
      string opt_prefix = this.name + ".";
      string base_path;
      this.notify_funcs = Datalist<unowned SList<unowned NotifyData>> ();
      base_path = this.schema.get_metadata_option (opt_prefix + "base_path").get_string ();
      if (this.instance_id == null)
      {
        this.path = base_path + "/" + this.schema.app_name;
      }
      else
      {
        string option = this.schema.get_metadata_option (opt_prefix +
                                                         "base_instance_path").get_string ();
        option = option.replace ("${base_path}", base_path);
        this.path = option + "/" + this.schema.app_name +
                    "/" + this.instance_id;
      }
    }

    private string
    generate_key (string group, string key)
    {
      if (key == null)
      {
        if (group == GROUP_DEFAULT)
        {
          return this.path;
        }
        else
        {
          return this.path + "/" + group;
        }
      }
      else
      {
        if (group == GROUP_DEFAULT)
        {
          return this.path + "/" + key;
        }
        else
        {
          return this.path + "/" + group + "/" + key;
        }
      }
    }

    private void
    parse_group_and_key (string full_key, out string group, out string key)
    {
      unowned string key_to_parse = full_key.offset (this.path.length + 1);
      unowned string last_slash = key_to_parse.rchr (key_to_parse.length, '/');
      long offset = key_to_parse.pointer_to_offset (last_slash);
      group = key_to_parse.substring (0, offset);
      key = key_to_parse.offset (offset + 1);
    }

    private Type
    valuetype_to_type (ValueType vt, bool list_is_type)
    {
      Type type;
      switch (vt)
      {
        case ValueType.BOOL:
          type = typeof (bool);
          break;
        case ValueType.FLOAT:
          type = typeof (float);
          break;
        case ValueType.INT:
          type = typeof (int);
          break;
        case ValueType.STRING:
          type = typeof (string);
          break;
        case ValueType.LIST:
          if (list_is_type)
          {
            type = typeof (ValueArray);
          }
          else
          {
            type = Type.INVALID;
          }
          break;
        default:
          type = Type.INVALID;
          break;
      }
      return type;
    }

    private ValueType
    type_to_valuetype (Type type)
    {
      ValueType vt;
      if (type == typeof (bool))
      {
        vt = ValueType.BOOL;
      }
      else if (type == typeof (float))
      {
        vt = ValueType.FLOAT;
      }
      else if (type == typeof (int))
      {
        vt = ValueType.INT;
      }
      else if (type == typeof (string))
      {
        vt = ValueType.STRING;
      }
      else if (type == typeof (ValueArray))
      {
        vt = ValueType.LIST;
      }
      else if (this.schema.find_type (type) != null)
      {
        vt = ValueType.STRING;
      }
      else
      {
        vt = ValueType.INVALID;
      }
      return vt;
    }

    private GLib.Value
    gconfvalue_to_gvalue (GConf.Value gc_val)
    {
      Type type;
      GLib.Value value;
      type = this.valuetype_to_type (gc_val.type, true);
      value = GLib.Value (type);
      if (type == typeof (bool))
      {
        value.set_boolean (gc_val.get_bool ());
      }
      else if (type == typeof (float))
      {
        value.set_float ((float)gc_val.get_float ());
      }
      else if (type == typeof (int))
      {
        value.set_int (gc_val.get_int ());
      }
      else if (type == typeof (string))
      {
        value.set_string (gc_val.get_string ());
      }
      else if (type == typeof (ValueArray))
      {
        Type list_type;
        list_type = this.valuetype_to_type (gc_val.get_list_type (), false);
        value.set_boxed (this.slist_to_valuearray (gc_val.get_list (), 
                                                   list_type));
      }
      else
      {
        SchemaType st = this.schema.find_type (type);
        if (st == null)
        {
          throw new ConfigError.INVALID_TYPE ("Invalid config value type.");
        }
        else
        {
          value = st.deserialize (gc_val.get_string ());
        }
      }
      return value;
    }

    private ValueType
    get_gconf_list_valuetype (string key) throws GLib.Error
    {
      unowned GConf.Value value;
      value = this.client.get (key);
      return value.get_list_type ();
    }

    private GLib.ValueArray
    slist_to_valuearray (SList<GConf.Value> list, Type type)
    {
      unowned SList l;
      GLib.ValueArray arr = new GLib.ValueArray (list.length ());
      for (l = list; l != null; l = l.next)
      {
        GLib.Value val;
        unowned GConf.Value gc_val;
        val = GLib.Value (type);
        gc_val = (GConf.Value)l.data;
        if (type == typeof (bool))
        {
          val.set_boolean (gc_val.get_bool ());
        }
        else if (type == typeof (float))
        {
          val.set_float ((float)gc_val.get_float ());
        }
        else if (type == typeof (int))
        {
          val.set_int (gc_val.get_int ());
        }
        else if (type == typeof (string))
        {
          val.set_string (gc_val.get_string ());
        }
        else
        {
          SchemaType st = this.schema.find_type (type);
          if (st == null)
          {
            throw new ConfigError.INVALID_TYPE ("Invalid config value type.");
          }
          else
          {
            val = st.deserialize (gc_val.get_string ());
          }
        }
        arr.append (val);
      }
      return arr;
    }

    private SList<GConf.Value>?
    valuearray_to_slist (ValueArray arr)
    {
      if (arr == null || arr.n_values == 0)
      {
        return null;
      }
      else
      {
        uint i;
        unowned GLib.Value v = arr.values[0];
        Type type = v.type ();
        SList<unowned GConf.Value> list = new SList<unowned GConf.Value> ();
        for (i = 0; i < arr.n_values; i++)
        {
          unowned GLib.Value val;
          GConf.Value gc_val;
          unowned GConf.Value gc_val2;
          val = arr.values[i];
          gc_val = new GConf.Value (this.type_to_valuetype (type));
          if (type == typeof (bool))
          {
            gc_val.set_bool (val.get_boolean ());
          }
          else if (type == typeof (float))
          {
            gc_val.set_float (val.get_float ());
          }
          else if (type == typeof (int))
          {
            gc_val.set_int (val.get_int ());
          }
          else if (type == typeof (string))
          {
            gc_val.set_string (val.get_string ());
          }
          else
          {
            throw new ConfigError.INVALID_TYPE ("Invalid config value type.");
          }
          gc_val2 = gc_val;
          list.append (gc_val);
        }
        return list;
      }
    }

    private void
    notify_proxy (Client client, uint cnxn_id, Entry entry)
    {
      string full_key = entry.get_key ();
      NotifyEntry cn_entry = NotifyEntry ();
      this.parse_group_and_key (full_key, out cn_entry.group, out cn_entry.key);
      cn_entry.value = this.gconfvalue_to_gvalue (entry.get_value ());
      unowned SList<unowned NotifyData> notify_func_list =
        this.notify_funcs.get_data (full_key);
      foreach (unowned NotifyData notify_func in notify_func_list)
      {
        notify_func.callback (cn_entry);
      }
    }

    public override void
    remove () throws GLib.Error
    {
      // TODO determine when to remove a directory?
      this.client.remove_dir (this.path);
    }

    public override void
    notify_add (string group, string key, NotifyFunc callback)
    {
      NotifyData notify;
      string full_key;
      uint func_id;
      unowned SList<unowned NotifyData> callbacks;

      notify = new NotifyData ();
      notify.callback = callback;
      full_key = this.generate_key (group, key);
      try
      {
        func_id = this.client.notify_add (full_key, (ClientNotifyFunc)this.notify_proxy);
        if (func_id == 0)
        {
          warning ("Something went wrong when we tried to add a notification callback.");
        }
        notify.func_id = func_id;
      }
      catch (GLib.Error err)
      {
        warning ("Something went wrong when we tried to add a notification callback: %s", err.message);
        notify.func_id = 0;
      }
      callbacks = this.notify_funcs.get_data (full_key);
      callbacks.append ((owned)notify);
      this.notify_funcs.set_data (full_key, callbacks);
    }

    public override void
    notify (string group, string key)
    {
      string full_key = this.generate_key (group, key);
      unowned SList<unowned NotifyData> notifications = this.notify_funcs.get_data (full_key);
      NotifyEntry entry = NotifyEntry ();
      entry.group = group;
      entry.key = key;
      entry.value = this.get_value (group, key);
      foreach (unowned NotifyData notify in notifications)
      {
        notify.callback (entry);
      }
    }

    public override void
    notify_remove (string group, string key, NotifyFunc callback)
    {
      string full_key = this.generate_key (group, key);
      unowned SList<unowned NotifyData> notifications = this.notify_funcs.get_data (full_key);
      foreach (unowned NotifyData notify in notifications)
      {
        if (notify.callback == callback)
        {
          this.client.notify_remove (notify.func_id);
          notifications.remove (notify);
          break;
        }
      }
    }

    public override void
    reset () throws GLib.Error
    {
      Process.spawn_command_line_async ("killall -HUP gconfd-2");
    }
    public override GLib.Value
    get_value (string group, string key) throws GLib.Error
    {
      string full_key;
      full_key = this.generate_key (group, key);
      return this.gconfvalue_to_gvalue (this.client.get (full_key));
    }
    public override bool
    get_bool (string group, string key) throws GLib.Error
    {
      string full_key;
      full_key = this.generate_key (group, key);
      return this.client.get_bool (full_key);
    }
    public override void
    set_bool (string group, string key, bool value) throws GLib.Error
    {
      string full_key;
      full_key = this.generate_key (group, key);
      this.client.set_bool (full_key, value);
    }
    public override float
    get_float (string group, string key) throws GLib.Error
    {
      string full_key;
      full_key = this.generate_key (group, key);
      return (float)this.client.get_float (full_key);
    }
    public override void
    set_float (string group, string key, float value) throws GLib.Error
    {
      string full_key;
      full_key = this.generate_key (group, key);
      this.client.set_float (full_key, value);
    }
    public override int
    get_int (string group, string key) throws GLib.Error
    {
      string full_key;
      full_key = this.generate_key (group, key);
      return this.client.get_int (full_key);
    }
    public override void
    set_int (string group, string key, int value) throws GLib.Error
    {
      string full_key;
      full_key = this.generate_key (group, key);
      this.client.set_int (full_key, value);
    }
    public override string
    get_string (string group, string key) throws GLib.Error
    {
      string full_key;
      full_key = this.generate_key (group, key);
      return this.client.get_string (full_key);
    }
    public override void
    set_string (string group, string key, string value) throws GLib.Error
    {
      string full_key;
      full_key = this.generate_key (group, key);
      this.client.set_string (full_key, value);
    }
    public override GLib.ValueArray
    get_list (string group, string key) throws GLib.Error
    {
      string full_key;
      full_key = this.generate_key (group, key);
      ValueType vt = this.get_gconf_list_valuetype (full_key);
      return this.slist_to_valuearray (this.client.get_list (full_key, vt),
                                       this.valuetype_to_type (vt, false));
    }
    public override void
    set_list (string group, string key, GLib.ValueArray value) throws GLib.Error
    {
      string full_key;
      SList list;
      full_key = this.generate_key (group, key);
      list = this.valuearray_to_slist (value);
      this.client.set_list (full_key,
                            this.get_gconf_list_valuetype (full_key),
                            list);
    }
  }
  [ModuleInit]
  public Type
  register_plugin ()
  {
    return typeof (GConfBackend);
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
