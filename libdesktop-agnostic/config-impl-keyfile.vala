/*
 * A GKeyFile-based implementation of the Config interface.
 *
 * Copyright (C) 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
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
  public class GKeyFile : Backend
  {
    private KeyFile _data;
    private VFS.File _keyfile;
    private VFS.FileMonitor _keyfile_monitor;
    private ulong _monitor_changed_id;
    private string _checksum;
    private bool _autosave;
    private HashTable<string,List<NotifyDelegate>> _notifiers;
    public override string name
    {
      owned get
      {
        return "GKeyFile";
      }
    }

    construct
    {
      this._autosave = true;
      this._monitor_changed_id = 0;
      if (this.schema != null)
      {
        this._data = new KeyFile ();
        this._notifiers = new HashTable<string,List<NotifyDelegate>> (str_hash,
                                                                      str_equal);
      }
    }

    /**
     * Saves the current state of the configuration to the filesystem,
     * suppressing the "changed" signal from the file monitor.
     */
    private void
    save_config () throws GLib.Error
    {
      string data;
      size_t length;

      data = this._data.to_data (out length);
      this._checksum = Checksum.compute_for_string (ChecksumType.SHA256,
                                                    data, length);
      if (this._monitor_changed_id != 0)
      {
        // block changed signal
        SignalHandler.block (this._keyfile_monitor, this._monitor_changed_id);
      }
      // save config file
      this._keyfile.replace_contents (data);
      if (this._monitor_changed_id != 0)
      {
        // unblock changed signal
        SignalHandler.unblock (this._keyfile_monitor, this._monitor_changed_id);
      }
    }

    /**
     * Saves the current configuration state to the filesystem (if autosave is
     * on) and emits the notify signal.
     */
    private void
    update_config (string group, string key) throws GLib.Error
    {
      if (this._autosave)
      {
        this.save_config ();
      }
      this.notify (group, key);
    }

    private void
    get_data_from_file (VFS.File file, out string contents, out size_t length,
                        out string checksum) throws GLib.Error
    {
      file.load_contents (out contents, out length);
      checksum = Checksum.compute_for_string (ChecksumType.SHA256,
                                              contents, length);
    }

    private void
    load_data (VFS.File file) throws GLib.Error
    {
      string data;
      size_t length;

      this.get_data_from_file (file, out data, out length, out this._checksum);
      this._data.load_from_data (data, (ulong)length, KeyFileFlags.NONE);
    }

    private void
    set_value_from_keyfile (KeyFile keyfile, string group, string key) throws GLib.Error
    {
      SchemaOption option = this.schema.get_option (group, key);
      Type type = option.option_type;
      if (type == typeof (bool))
      {
        this.set_bool (group, key, keyfile.get_boolean (group, key));
      }
      else if (type == typeof (int))
      {
        this.set_int (group, key, keyfile.get_integer (group, key));
      }
      else if (type == typeof (float))
      {
        this.set_float (group, key, (float)keyfile.get_double (group, key));
      }
      else if (type == typeof (string))
      {
        this.set_string (group, key, keyfile.get_string (group, key));
      }
      else if (type == typeof (ValueArray))
      {
        ValueArray arr;

        arr = this.generate_valuearray_from_keyfile (keyfile, group, key);

        this.set_list (group, key, arr);
      }
      else
      {
        SchemaType? st = Schema.find_type (type);
        if (st == null)
        {
          throw new Error.INVALID_TYPE ("'%s' is an invalid config type.",
                                        type.name ());
        }

        Value val;

        val = st.deserialize (keyfile.get_string (group, key));
        this.set_value (group, key, val);
      }
    }

    private ValueArray
    generate_valuearray_from_keyfile (KeyFile keyfile, string group,
                                      string key) throws GLib.Error
    {
      SchemaOption option = this.schema.get_option (group, key);
      Type list_type = option.list_type;
      ValueArray arr;

      if (list_type == typeof (bool))
      {
        bool[] list_data;
        Value val;

        list_data = keyfile.get_boolean_list (group, key);
        arr = new ValueArray (list_data.length);
        foreach (bool item in list_data)
        {
          val = item;
          arr.append (val);
        }
      }
      else if (list_type == typeof (int))
      {
        int[] list_data;
        Value val;

        list_data = keyfile.get_integer_list (group, key);
        arr = new ValueArray (list_data.length);
        foreach (int item in list_data)
        {
          val = item;
          arr.append (val);
        }
      }
      else if (list_type == typeof (float))
      {
        double[] list_data;
        Value val;

        list_data = (double[])keyfile.get_double_list (group, key);
        arr = new ValueArray (list_data.length);
        foreach (double item in list_data)
        {
          val = (float)item;
          arr.append (val);
        }
      }
      else if (list_type == typeof (string))
      {
        string[] list_data;
        Value val;

        list_data = keyfile.get_string_list (group, key);
        arr = new ValueArray (list_data.length);
        foreach (string item in list_data)
        {
          val = item;
          arr.append (val);
        }
      }
      else
      {
        SchemaType? st = Schema.find_type (list_type);
        if (st == null)
        {
          throw new Error.INVALID_TYPE ("'%s' is an invalid config type.",
                                        list_type.name ());
        }

        string[] list_data;

        list_data = keyfile.get_string_list (group, key);
        arr = new ValueArray (list_data.length);
        foreach (string item in list_data)
        {
          arr.append (st.deserialize (item));
        }
      }

      return arr;
    }

    private void
    on_keyfile_changed (VFS.FileMonitor monitor, VFS.File file, VFS.File other,
                        VFS.FileMonitorEvent event)
    {
      switch (event)
      {
        case VFS.FileMonitorEvent.CREATED:
          // just set the data
          this.load_data (file);
          break;
        case VFS.FileMonitorEvent.CHANGED:
          // check to see if the contents have changed
          string data;
          size_t length;
          string checksum;

          this.get_data_from_file (file, out data, out length, out checksum);
          if (this._checksum != checksum)
          {
            // iterate through the config keys and determine which ones have changed
            Schema schema = this.schema;
            KeyFile new_data = new KeyFile ();

            new_data.load_from_data (data, length, KeyFileFlags.NONE);

            foreach (unowned string group in schema.get_groups ())
            {
              foreach (unowned string key in schema.get_keys (group))
              {
                if (this._data.get_value (group, key) != new_data.get_value (group, key))
                {
                  this.set_value_from_keyfile (new_data, group, key);
                }
              }
            }
          }
          break;
        case VFS.FileMonitorEvent.DELETED:
          // reset & save to disk
          this.reset ();
          break;
        default:
          // do nothing
          break;
      }
    }

    private void
    ensure_directory (string path)
    {
      if (!FileUtils.test (path, FileTest.EXISTS))
      {
        int d_errno = DirUtils.create_with_parents (path, 0755);
        if (d_errno != 0)
        {
          critical ("Config file error: %s", strerror (d_errno));
        }
      }
    }

    /**
     * Determines the path to the config file and creates/loads it.
     */
    public override void
    constructed ()
    {
      string base_path;
      string path;
      Schema schema = this.schema;

      base_path = Path.build_filename (Environment.get_user_config_dir (),
                                       "desktop-agnostic");
      this.ensure_directory (base_path);
      if (this.instance_id == null)
      {
        path = Path.build_filename (base_path,
                                    "%s.ini".printf (schema.app_name));
      }
      else
      {
        path = Path.build_filename (base_path, "instances",
                                    "%s-%s.ini".printf (schema.app_name,
                                                        this.instance_id));
        this.ensure_directory (Path.get_basename (path));
      }
      this._keyfile = VFS.file_new_for_path (path);
      try
      {
        if (this._keyfile.exists ())
        {
          this.load_data (this._keyfile);
        }
        else
        {
          this.reset ();
          this.save_config ();
        }
      }
      catch (GLib.Error err)
      {
        critical ("Config error: %s", err.message);
      }
      this._keyfile_monitor = this._keyfile.monitor ();
      this._monitor_changed_id = Signal.connect (this._keyfile_monitor,
                                                 "changed",
                                                 (Callback)this.on_keyfile_changed,
                                                 this);
    }

    ~GKeyFile ()
    {
      this._keyfile_monitor.cancel ();
      SignalHandler.disconnect (this._keyfile_monitor,
                                this._monitor_changed_id);
    }

    public override void
    reset () throws GLib.Error
    {
      Schema? schema = this.schema;
      if (schema == null)
      {
        throw new Error.NO_SCHEMA ("The schema was not loaded.");
      }

      this._autosave = false;
      foreach (string group in schema.get_groups ())
      {
        foreach (string key in schema.get_keys (group))
        {
          SchemaOption option = schema.get_option (group, key);
          this.set_value (group, key, option.default_value);
        }
      }
      this._autosave = true;
      this.save_config ();
    }

    public override void
    notify_add (string group, string key, NotifyFunc callback) throws GLib.Error
    {
      string full_key = "%s/%s".printf (group, key);
      unowned List<NotifyDelegate>? funcs = this._notifiers.lookup (full_key);
      NotifyDelegate data = new NotifyDelegate (callback);
      if (funcs == null)
      {
        List<NotifyDelegate> new_funcs = new List<NotifyDelegate> ();
        new_funcs.append ((owned)data);
        this._notifiers.insert (full_key, (owned)new_funcs);
      }
      else
      {
        funcs.append ((owned)data);
      }
    }

    public override void
    notify (string group, string key) throws GLib.Error
    {
      string full_key = "%s/%s".printf (group, key);
      Value value = this.get_value (group, key);
      unowned List<NotifyDelegate> funcs = this._notifiers.lookup (full_key);
      foreach (unowned NotifyDelegate data in funcs)
      {
        if (data != null && data.callback != null)
        {
          data.execute (group, key, value);
        }
      }
    }

    public override void
    notify_remove (string group, string key, NotifyFunc callback) throws GLib.Error
    {
      string full_key = "%s/%s".printf (group, key);
      unowned List<NotifyDelegate>? funcs = this._notifiers.lookup (full_key);
      if (funcs != null)
      {
        NotifyDelegate data;
        unowned List<NotifyDelegate>? node;

        data = new NotifyDelegate (callback);
        node = funcs.find_custom (data, (CompareFunc)NotifyDelegate.compare);
        if (node != null)
        {
          funcs.delete_link (node);
        }
      }
    }

    /**
     * Removes the config file from the file system. Implies reset(), but does
     * not save to disk.
     */
    public override void
    remove () throws GLib.Error
    {
      this._keyfile.remove ();
      this.reset ();
    }

    public override Value
    get_value (string group, string key) throws GLib.Error
    {
      Schema schema = this.schema;
      SchemaOption option = schema.get_option (group, key);
      Type option_type;
      Value result;

      if (option == null)
      {
        throw new Error.KEY_NOT_FOUND ("Could not find group and/or key in schema.");
      }

      option_type = option.option_type;

      if (option_type == typeof (bool))
      {
        result = this.get_bool (group, key);
      }
      else if (option_type == typeof (float))
      {
        result = this.get_float (group, key);
      }
      else if (option_type == typeof (int))
      {
        result = this.get_int (group, key);
      }
      else if (option_type == typeof (string))
      {
        result = this.get_string (group, key);
      }
      else if (option_type == typeof (ValueArray))
      {
        result = this.get_list (group, key);
      }
      else
      {
        SchemaType st = this.schema.find_type (option_type);
        if (st == null)
        {
          throw new Error.INVALID_TYPE ("'%s' is an invalid config type.",
                                        option_type.name ());
        }
        else
        {
          result = st.deserialize (this.get_string (group, key));
        }
      }
      return result;
    }

    public override bool
    get_bool (string group, string key) throws GLib.Error
    {
      try
      {
        return this._data.get_boolean (group, key);
      }
      catch (KeyFileError err)
      {
        if (err is KeyFileError.GROUP_NOT_FOUND ||
            err is KeyFileError.KEY_NOT_FOUND)
        {
          throw new Error.KEY_NOT_FOUND (err.message);
        }
        else
        {
          throw err;
        }
      }
    }

    public override void
    set_bool (string group, string key, bool value) throws GLib.Error
    {
      this._data.set_boolean (group, key, value);
      this.update_config (group, key);
    }

    public override float
    get_float (string group, string key) throws Error
    {
      try
      {
        return (float)this._data.get_double (group, key);
      }
      catch (KeyFileError err)
      {
        if (err is KeyFileError.GROUP_NOT_FOUND ||
            err is KeyFileError.KEY_NOT_FOUND)
        {
          throw new Error.KEY_NOT_FOUND (err.message);
        }
        else
        {
          throw err;
        }
      }
    }

    public override void
    set_float (string group, string key, float value) throws GLib.Error
    {
      this._data.set_double (group, key, value);
      this.update_config (group, key);
    }

    public override int
    get_int (string group, string key) throws GLib.Error
    {
      try
      {
        return this._data.get_integer (group, key);
      }
      catch (KeyFileError err)
      {
        if (err is KeyFileError.GROUP_NOT_FOUND ||
            err is KeyFileError.KEY_NOT_FOUND)
        {
          throw new Error.KEY_NOT_FOUND (err.message);
        }
        else
        {
          throw err;
        }
      }
    }

    public override void
    set_int (string group, string key, int value) throws GLib.Error
    {
      this._data.set_integer (group, key, value);
      this.update_config (group, key);
    }

    public override string
    get_string (string group, string key) throws GLib.Error
    {
      try
      {
        return this._data.get_string (group, key);
      }
      catch (KeyFileError err)
      {
        if (err is KeyFileError.GROUP_NOT_FOUND ||
            err is KeyFileError.KEY_NOT_FOUND)
        {
          throw new Error.KEY_NOT_FOUND (err.message);
        }
        else
        {
          throw err;
        }
      }
    }

    public override void
    set_string (string group, string key, string value) throws GLib.Error
    {
      this._data.set_string (group, key, value);
      this.update_config (group, key);
    }

    public override ValueArray
    get_list (string group, string key) throws GLib.Error
    {
      try
      {
        return this.generate_valuearray_from_keyfile (this._data, group, key);
      }
      catch (KeyFileError err)
      {
        if (err is KeyFileError.GROUP_NOT_FOUND ||
            err is KeyFileError.KEY_NOT_FOUND)
        {
          throw new Error.KEY_NOT_FOUND (err.message);
        }
        else
        {
          throw err;
        }
      }
    }

    public override void
    set_list (string group, string key, ValueArray value) throws GLib.Error
    {
      SchemaOption option = this.schema.get_option (group, key);
      Type list_type = option.list_type;

      if (list_type == typeof (bool))
      {
        bool[value.n_values] list = new bool[value.n_values];
        for (uint i = 0; i < value.n_values; i++)
        {
          unowned Value val = value.get_nth (i);

          list[i] = (bool)val;
        }

        this._data.set_boolean_list (group, key, list);
      }
      else if (list_type == typeof (int))
      {
        int[value.n_values] list = new int[value.n_values];
        for (uint i = 0; i < value.n_values; i++)
        {
          unowned Value val = value.get_nth (i);

          list[i] = (int)val;
        }

        this._data.set_integer_list (group, key, list);
      }
      else if (list_type == typeof (float))
      {
        double[value.n_values] list = new double[value.n_values];
        for (uint i = 0; i < value.n_values; i++)
        {
          unowned Value val = value.get_nth (i);

          list[i] = (float)val;
        }

        this._data.set_double_list (group, key, list);
      }
      else if (list_type == typeof (string))
      {
        string[value.n_values] list = new string[value.n_values];
        for (uint i = 0; i < value.n_values; i++)
        {
          unowned Value val = value.get_nth (i);

          list[i] = (string)val;
        }

        this._data.set_string_list (group, key, list);
      }
      else
      {
        SchemaType? st = Schema.find_type (list_type);
        if (st == null)
        {
          throw new Error.INVALID_TYPE ("'%s' is an invalid config type.",
                                        list_type.name ());
        }

        string[value.n_values] list = new string[value.n_values];
        for (uint i = 0; i < value.n_values; i++)
        {
          list[i] = st.serialize (value.get_nth (i));
        }

        this._data.set_string_list (group, key, list);
      }
      this.update_config (group, key);
    }
  }
}
[ModuleInit]
public Type
register_plugin ()
{
  return typeof (DesktopAgnostic.Config.GKeyFile);
}

// vim: set et ts=2 sts=2 sw=2 ai :
