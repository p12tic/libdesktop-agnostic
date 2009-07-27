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

using DesktopAgnostic.Config;

namespace DesktopAgnostic.Config
{
  private const string BACKEND_NAME = "GConf";
  [Compact]
  private class NotifyData
  {
    public NotifyFunc callback;
    public uint func_id;
  }
  public class GConfBackend : Backend
  {
    private string schema_path;
    private string path;
    private unowned GConf.Client client;
    private Datalist<unowned SList<NotifyData>> notify_funcs;

    public override string name
    {
      owned get
      {
        return BACKEND_NAME;
      }
    }

    construct
    {
      this.client = GConf.Client.get_default ();
    }

    public override void
    constructed ()
    {
      string opt_prefix = this.name + ".";
      string base_path;
      Schema schema = this.schema;

      this.notify_funcs = Datalist<SList<NotifyData>> ();
      base_path = schema.get_metadata_option (opt_prefix +
                                              "base_path").get_string ();
      this.schema_path = "/schemas%s/%s".printf (base_path, schema.app_name);
      if (this.instance_id == null)
      {
        this.path = "%s/%s".printf (base_path, schema.app_name);
      }
      else
      {
        string option = schema.get_metadata_option (opt_prefix +
                                                    "base_instance_path").get_string ();
        this.path = "%s/%s/%s".printf (option.replace ("${base_path}", base_path),
                                       schema.app_name, this.instance_id);
        // associate instance with schema
        try
        {
          this.associate_schemas_in_dir (this.schema_path, this.path);
        }
        catch (GLib.Error err)
        {
          critical ("Error associating instance with schema: %s", err.message);
        }
      }
    }

    /**
     * Ported from #panel_applet_associate_schemas_in_dir ().
     */
    private void
    associate_schemas_in_dir (string schema_dir,
                              string pref_dir) throws GLib.Error
    {
      unowned SList<GConf.Entry> entries;
      unowned SList<string> subdirs;

      entries = this.client.all_entries (schema_dir);

      foreach (GConf.Entry entry in entries)
      {
        string schema_key;
        string key;
        GConf.Entry? pref_entry;
        string pref_schema_key;

        schema_key = entry.get_key ();
        key = "%s/%s".printf (pref_dir, Path.get_basename (schema_key));

        this.client.add_dir (pref_dir, GConf.ClientPreloadType.NONE);

        /* Associating a schema is potentially expensive, so let's try
         * to avoid this by doing it only when needed. So we check if
         * the key is already correctly associated.
         */
        pref_entry = this.client.get_entry (key, null, true);

        if (pref_entry == null)
        {
          pref_schema_key = null;
        }
        else
        {
          pref_schema_key = pref_entry.get_schema_name ();
        }
        if (schema_key != pref_schema_key)
        {
          this.client.engine.associate_schema (key, schema_key);

          if (pref_entry == null ||
              pref_entry.get_value () == null ||
              pref_entry.get_is_default ())
          {
            /* unset the key: gconf_client_get_entry()
             * brought an invalid entry in the client
             * cache, and we want to fix this
             */
            this.client.unset (key);
          }
        }
      }

      subdirs = this.client.all_dirs (schema_dir);

      foreach (unowned string dir in subdirs)
      {
        string base_key;
        string schema_subdir;
        string pref_subdir;

        base_key = Path.get_basename (dir);
        schema_subdir = "%s/%s".printf (schema_dir, base_key);
        pref_subdir = "%s/%s".printf (pref_dir, base_key);

        this.associate_schemas_in_dir (schema_subdir, pref_subdir);
      }
    }

    private string
    generate_key (string group, string? key)
    {
      string full_key;
      if (key == null)
      {
        if (group == GROUP_DEFAULT)
        {
          full_key = this.path;
        }
        else
        {
          full_key = "%s/%s".printf (this.path, group);
        }
      }
      else
      {
        if (group == GROUP_DEFAULT)
        {
          full_key = "%s/%s".printf (this.path, key);
        }
        else
        {
          full_key = "%s/%s/%s".printf (this.path, group, key);
        }
      }

      return full_key;
    }

    private void
    parse_group_and_key (string full_key, out string group, out string key)
    {
      unowned string key_to_parse = full_key.offset (this.path.length + 1);
      unowned string? last_slash = key_to_parse.rchr (key_to_parse.length, '/');
      if (last_slash == null)
      {
        group = GROUP_DEFAULT;
        key = key_to_parse;
      }
      else
      {
        long offset = key_to_parse.pointer_to_offset (last_slash);
        group = key_to_parse.substring (0, offset);
        key = key_to_parse.offset (offset + 1);
      }
    }

    private Type
    valuetype_to_type (GConf.ValueType vt, bool list_is_type)
    {
      Type type;
      switch (vt)
      {
        case GConf.ValueType.BOOL:
          type = typeof (bool);
          break;
        case GConf.ValueType.FLOAT:
          type = typeof (float);
          break;
        case GConf.ValueType.INT:
          type = typeof (int);
          break;
        case GConf.ValueType.STRING:
          type = typeof (string);
          break;
        case GConf.ValueType.LIST:
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

    private GConf.ValueType
    type_to_valuetype (Type type)
    {
      GConf.ValueType vt;
      if (type == typeof (bool))
      {
        vt = GConf.ValueType.BOOL;
      }
      else if (type == typeof (float))
      {
        vt = GConf.ValueType.FLOAT;
      }
      else if (type == typeof (int))
      {
        vt = GConf.ValueType.INT;
      }
      else if (type == typeof (string))
      {
        vt = GConf.ValueType.STRING;
      }
      else if (type == typeof (ValueArray))
      {
        vt = GConf.ValueType.LIST;
      }
      else if (this.schema.find_type (type) != null)
      {
        vt = GConf.ValueType.STRING;
      }
      else
      {
        vt = GConf.ValueType.INVALID;
      }
      return vt;
    }

    private GLib.Value
    gconfvalue_to_gvalue (string group, string key,
                          GConf.Value gc_val) throws Error
    {
      SchemaOption schema_option;
      Type type;
      GLib.Value value;

      schema_option = this.schema.get_option (group, key);
      type = schema_option.option_type;
      if (type == typeof (bool))
      {
        value = gc_val.get_bool ();
      }
      else if (type == typeof (float))
      {
        value = (float)gc_val.get_float ();
      }
      else if (type == typeof (int))
      {
        value = gc_val.get_int ();
      }
      else if (type == typeof (string))
      {
        value = gc_val.get_string ();
      }
      else if (type == typeof (ValueArray))
      {
        Type list_type;
        ValueArray array;

        value = Value (type);
        list_type = schema_option.list_type;
        array = this.slist_to_valuearray (gc_val.get_list (), list_type);
        value.set_boxed ((owned)array);
      }
      else
      {
        SchemaType st = this.schema.find_type (type);
        if (st == null)
        {
          throw new Error.INVALID_TYPE ("Invalid config value type.");
        }
        else
        {
          value = st.deserialize (gc_val.get_string ());
        }
      }
      return value;
    }

    private GConf.ValueType
    get_gconf_list_valuetype (string key) throws GLib.Error
    {
      unowned GConf.Value value;
      value = this.client.get (key);
      return value.get_list_type ();
    }

    private GLib.ValueArray
    slist_to_valuearray (SList<unowned GConf.Value> list, Type type) throws Error
    {
      GLib.ValueArray arr = new GLib.ValueArray (list.length ());
      foreach (unowned GConf.Value gc_val in list)
      {
        GLib.Value val;

        if (type == typeof (bool))
        {
          val = gc_val.get_bool ();
        }
        else if (type == typeof (float))
        {
          val = (float)gc_val.get_float ();
        }
        else if (type == typeof (int))
        {
          val = gc_val.get_int ();
        }
        else if (type == typeof (string))
        {
          val = gc_val.get_string ();
        }
        else
        {
          SchemaType st = this.schema.find_type (type);
          if (st == null)
          {
            throw new Error.INVALID_TYPE ("Invalid config value type.");
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
            throw new Error.INVALID_TYPE ("Invalid config value type.");
          }
          gc_val2 = gc_val;
          list.append (gc_val);
        }
        return list;
      }
    }

    private void
    notify_proxy (GConf.Client client, uint cnxn_id, GConf.Entry entry)
    {
      string full_key = entry.get_key ();
      string group;
      string key;
      Value value;

      this.parse_group_and_key (full_key, out group, out key);
      value = this.gconfvalue_to_gvalue (group, key, entry.get_value ());
      unowned SList<NotifyData> notify_func_list =
        this.notify_funcs.get_data (full_key);
      foreach (unowned NotifyData notify_func in notify_func_list)
      {
        notify_func.callback (group, key, value);
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
      unowned SList<NotifyData>? callbacks;

      notify = new NotifyData ();
      notify.callback = callback;
      full_key = this.generate_key (group, key);
      try
      {
        func_id = this.client.notify_add (full_key, this.notify_proxy);
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
    notify (string group, string key) throws GLib.Error
    {
      string full_key = this.generate_key (group, key);
      unowned SList<NotifyData> notifications;
      Value value;

      notifications = this.notify_funcs.get_data (full_key);
      value = this.get_value (group, key);
      foreach (unowned NotifyData notify in notifications)
      {
        notify.callback (group, key, value);
      }
    }

    public override void
    notify_remove (string group, string key,
                   NotifyFunc callback) throws GLib.Error
    {
      string full_key = this.generate_key (group, key);
      unowned SList<NotifyData> notifications = this.notify_funcs.get_data (full_key);
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
      unowned GConf.Value? gc_val;
      GLib.Value val;

      full_key = this.generate_key (group, key);
      gc_val = this.client.get_entry (full_key, null, true).get_value ();
      if (gc_val == null)
      {
        throw new Error.KEY_NOT_FOUND ("Could not find the key specified: %s.",
                                       full_key);
      }
      else
      {
        val = this.gconfvalue_to_gvalue (group, key, gc_val);
      }
      return val;
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
      GConf.ValueType vt;
      unowned SList list;

      full_key = this.generate_key (group, key);
      vt = this.get_gconf_list_valuetype (full_key);
      list = this.client.get (full_key).get_list ();
      return this.slist_to_valuearray (list,
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
}

[ModuleInit]
public Type
register_plugin ()
{
  GLib.Value val;
  unowned HashTable<string,GLib.Value?> backend_metadata_keys;

  val = "/apps";
  backend_metadata_keys = Backend.get_backend_metadata_keys ();
  backend_metadata_keys.insert ("%s.base_path".printf (BACKEND_NAME), val);
  val = "${base_path}/instances";
  backend_metadata_keys.insert ("%s.base_instance_path".printf (BACKEND_NAME),
                                val);
  return typeof (GConfBackend);
}

// vim: set et ts=2 sts=2 sw=2 ai :
