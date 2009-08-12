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
  public class GConfBackend : Backend
  {
    private string schema_path;
    private string path;
    private unowned GConf.Client client;
    private uint connection_id;
    private Datalist<unowned SList<NotifyDelegate>> _notifiers;

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

      this.connection_id = 0;
      this._notifiers = Datalist<SList<NotifyDelegate>> ();
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
      // XXX gconf_client_add_dir is a bizarre API call that is needed for
      // notification support. This should probably be looked at in greater
      // detail. One thing's for sure: do not call it recursively.
      try
      {
        this.client.add_dir (this.path, GConf.ClientPreloadType.RECURSIVE);
        this.connection_id = this.client.notify_add (this.path, this.notify_proxy);
      }
      catch (GLib.Error err)
      {
        critical ("Config (GConf) error: %s", err.message);
      }
    }

    ~GConfBackend ()
    {
      try
      {
        this.client.notify_remove (this.connection_id);
        this.client.remove_dir (this.path);
      }
      catch (GLib.Error err)
      {
        critical ("Config (GConf) error: %s", err.message);
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
        string cgroup;
        string ckey;
        SchemaOption option;

        schema_key = entry.get_key ();
        key = "%s/%s".printf (pref_dir, Path.get_basename (schema_key));

        /* Associating a schema is potentially expensive, so let's try
         * to avoid this by doing it only when needed. So we check if
         * the key is already correctly associated.
         */
        pref_entry = this.client.get_entry (key, null, true);

        this.parse_group_and_key (key, out cgroup, out ckey);
        option = this.schema.get_option (cgroup, ckey);
        if (option == null || !option.per_instance)
        {
          continue;
        }

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
            throw new Error.INVALID_TYPE ("Invalid config value type: %s.",
                                          type.name ());
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

    private void
    notify_proxy (GConf.Client client, uint cnxn_id, GConf.Entry entry)
    {
      string full_key = entry.get_key ();
      string group;
      string key;
      Value value;

      this.parse_group_and_key (full_key, out group, out key);
      value = this.gconfvalue_to_gvalue (group, key, entry.get_value ());
      unowned SList<NotifyDelegate> notify_func_list =
        this._notifiers.get_data (full_key);
      foreach (unowned NotifyDelegate notify_func in notify_func_list)
      {
        notify_func.execute (group, key, value);
      }
    }

    public override void
    remove () throws GLib.Error
    {
      // TODO determine when to remove a directory?
      this.client.remove_dir (this.path);
    }

    public override void
    notify_add (string group, string key, NotifyFunc callback) throws GLib.Error
    {
      NotifyDelegate notify;
      string full_key;
      unowned SList<NotifyDelegate>? callbacks;

      notify = new NotifyDelegate (callback);
      full_key = this.generate_key (group, key);
      callbacks = this._notifiers.get_data (full_key);
      callbacks.append ((owned)notify);
      this._notifiers.set_data (full_key, callbacks);
    }

    public override void
    notify (string group, string key) throws GLib.Error
    {
      string full_key = this.generate_key (group, key);
      unowned SList<NotifyDelegate> notifications;
      Value value;

      notifications = this._notifiers.get_data (full_key);
      value = this.get_value (group, key);
      foreach (unowned NotifyDelegate notify in notifications)
      {
        notify.execute (group, key, value);
      }
    }

    public override void
    notify_remove (string group, string key,
                   NotifyFunc callback) throws GLib.Error
    {
      string full_key = this.generate_key (group, key);
      unowned SList<NotifyDelegate> funcs = this._notifiers.get_data (full_key);
      NotifyDelegate ndata = new NotifyDelegate (callback);
      unowned SList<NotifyDelegate>? node;

      node = funcs.find_custom (ndata, (CompareFunc)NotifyDelegate.compare);
      if (node != null)
      {
        node.data = null;
        funcs.delete_link (node);
        this._notifiers.set_data (full_key, funcs);
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
      Type list_type;
      unowned SList list;

      full_key = this.generate_key (group, key);
      list_type = this.schema.get_option (group, key).list_type;
      list = this.client.get (full_key).get_list ();
      return this.slist_to_valuearray (list, list_type);
    }
    public override void
    set_list (string group, string key, GLib.ValueArray value) throws GLib.Error
    {
      string full_key;
      Type type;

      full_key = this.generate_key (group, key);
      type = this.schema.get_option (group, key).list_type;
      if (type == typeof (bool) || type == typeof (float) ||
          type == typeof (int))
      {
        SList<GConf.Value> list;
        GConf.Value val;
        GConf.ValueType gc_type = this.type_to_valuetype (type);

        list = new SList<GConf.Value> ();
        for (uint i = 0; i < value.n_values; i++)
        {
          unowned GLib.Value list_val;
          GConf.Value gc_val;

          list_val = value.get_nth (i);
          gc_val = new GConf.Value (gc_type);
          if (type == typeof (bool))
          {
            gc_val.set_bool (list_val.get_boolean ());
          }
          else if (type == typeof (float))
          {
            gc_val.set_float (list_val.get_float ());
          }
          else if (type == typeof (int))
          {
            gc_val.set_int (list_val.get_int ());
          }
          else
          {
            // should not be reached
            throw new Error.INVALID_TYPE ("Invalid config value type: %s.",
                                          type.name ());
          }
          list.append ((owned)gc_val);
        }
        val = new GConf.Value (GConf.ValueType.LIST);
        val.set_list_type (gc_type);
        val.set_list (list);
        this.client.set (full_key, val);
      }
      else // handle strings via the set_list method.
      {
        SchemaType? st = null;
        SList<string> list;

        if (type != typeof (string))
        {
          st = Schema.find_type (type);
          if (st == null)
          {
            throw new Error.INVALID_TYPE ("Invalid config value type: %s.",
                                          type.name ());
          }
        }

        list = new SList<string> ();

        for (uint i = 0; i < value.n_values; i++)
        {
          unowned GLib.Value list_val;

          list_val = value.get_nth (i);
          if (st == null)
          {
            list.append ((string)list_val);
          }
          else
          {
            list.append (st.serialize (list_val));
          }
        }
        this.client.set_list (full_key, GConf.ValueType.STRING, list);
      }
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
