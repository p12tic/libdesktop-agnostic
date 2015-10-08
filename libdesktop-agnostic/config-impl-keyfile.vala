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
    private Datalist<unowned SList<NotifyDelegate>> _notifiers;
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
        this._notifiers = Datalist<SList<NotifyDelegate>> ();
      }
    }

    /**
     * Saves the current state of the configuration to the filesystem,
     * suppressing the "changed" signal from the file monitor.
     */
    private void
    save_config (bool calc_chksum = true) throws GLib.Error
    {
      string data;
      data = this._data.to_data (null);
      if (calc_chksum)
      {
        this._checksum = calculate_checksum_from_data (data);
      }

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

    private string
    calculate_checksum_from_data (string data)
    {
      return Checksum.compute_for_string (ChecksumType.SHA256, data, data.length);
    }

    private void
    calculate_checksum ()
    {
      string data;
      data = this._data.to_data (null);
      this._checksum = calculate_checksum_from_data (data);
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
    load_data (VFS.File file)
    {
      try
      {
        string data;
        size_t length;

        // Load the keyfile and update _data. If the keyfile can't be loaded
        // then regenerate it based on the current configuration.
        if(file.load_contents (out data, out length))
        {
          this.update_from_keyfile(data);
        }
        else
        {
          this.save_config ();
        }
      }
      catch (KeyFileError.PARSE e)
      {
        // Keyfile is invalid. Recover by overwriting the keyfile with the
        // current configuration.
        warning ("File is invalid: %s", e.message);
        this.save_config ();
      }
      catch (GLib.Error e)
      {
        critical ("Failed to load the keyfile: %s Code:%d", e.message, e.code);
      }
    }

    private void
    set_value_from_keyfile (KeyFile keyfile, string group, string key) throws GLib.Error
    {
      SchemaOption option = this.schema.get_option (group, key);
      Type type = option.option_type;
      if (type == typeof (bool))
      {
        bool val;
        try
        {
          val = keyfile.get_boolean (group, key);
        }
        catch (KeyFileError e)
        {
          return;
        }
        this._data.set_boolean (group, key, val);
        this.update_config (group, key);
      }
      else if (type == typeof (int))
      {
        int val;
        try
        {
          val = keyfile.get_integer (group, key);
        }
        catch (KeyFileError e)
        {
          return;
        }
        this._data.set_integer (group, key, val);
        this.update_config (group, key);
      }
      else if (type == typeof (float))
      {
        float val;
        try
        {
          val = (float)keyfile.get_double (group, key);
        }
        catch (KeyFileError e)
        {
          return;
        }
        this._data.set_double (group, key, val);
        this.update_config (group, key);
      }
      else if (type == typeof (string))
      {
        string val;
        try
        {
          val = keyfile.get_string (group, key);
        }
        catch (KeyFileError e)
        {
          return;
        }
        this._data.set_string (group, key, val);
        this.update_config (group, key);
      }
      else if (type == typeof (ValueArray))
      {
        ValueArray arr;
        try
        {
          arr = this.generate_valuearray_from_keyfile (keyfile, group, key);
        }
        catch (KeyFileError e)
        {
          return;
        }
        this.set_list (group, key, arr);
      }
      else // Treat it as a string.
      {
        SchemaType? st = Schema.find_type (type);
        if (st == null)
        {
          throw new Error.INVALID_TYPE ("'%s' is an invalid config type.",
                                        type.name ());
        }

        string val;
        try
        {
          val = keyfile.get_string (group, key);
        }
        catch (KeyFileError e)
        {
          return;
        }
        this._data.set_string (group, key, val);
        this.update_config (group, key);
      }
    }

    private void
    update_from_keyfile (string data) throws GLib.Error
    {
      string checksum = calculate_checksum_from_data (data);

      if (this._checksum != checksum)
      {
        unowned Schema? schema = this.schema;
        if (schema == null)
        {
          throw new Error.NO_SCHEMA ("The schema was not loaded.");
        }

        KeyFile new_data = new KeyFile ();
        new_data.load_from_data (data, data.length, KeyFileFlags.NONE);

        this._autosave = false;
        foreach (unowned string group in schema.get_groups ())
        {
          if(this._data.has_group (group) && new_data.has_group (group))
          {
            foreach (unowned string key in schema.get_keys (group))
            {
              // Only add if there is a new key/value pair.
              if (new_data.has_key (group, key))
              {
                // If it's a ValueArray defer checking if it's updated to set_list().
                if (schema.get_option (group, key).option_type == typeof (ValueArray) ||
                    (this._data.has_key (group, key) &&
                     this._data.get_value (group, key) != new_data.get_value (group, key)))
                {
                  this.set_value_from_keyfile (new_data, group, key);
                }
              }
            }
          }
        }
        this._autosave = true;

        calculate_checksum ();
        if (this._checksum != checksum)
        {
          // Only save if they are still different after the update.
          this.save_config(false);
        }
      }
    }

    private ValueArray
    generate_valuearray_from_keyfile (KeyFile keyfile, string group,
                                      string key) throws KeyFileError, GLib.Error
    {
      SchemaOption? option;
      Type list_type;
      ValueArray arr;

      option = this.schema.get_option (group, key);
      if (option == null)
      {
        throw new Error.KEY_NOT_FOUND ("The key %s/%s is invalid.",
                                       group, key);
      }
      else if (!keyfile.has_key (group, key))
      {
        return new ValueArray (0);
      }
      list_type = option.list_type;
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
    on_keyfile_changed (VFS.File file, VFS.File? other,
                        VFS.FileMonitorEvent event, VFS.FileMonitor monitor)
    {
      switch (event)
      {
        /**
         * The keyfile always gets created on startup if there is none.
         *
         * - If the user modifies the keyfile this will trigger a DELETED ->
         *   CREATED -> CHANGED sequence. In this case the keyfile always exists
         *   so ignore the DELETED/CREATED event and go directly to the CHANGED
         *   event to update the settings if there were any.
         *
         * - If the user deletes the keyfile then only a DELETED event occurs.
         *   Regenerate it based on the default configuration.
         */
        case VFS.FileMonitorEvent.CHANGED:
          this.load_data (file);
          break;
        case VFS.FileMonitorEvent.DELETED:
          if (!this._keyfile.exists ())
          {
            GLib.File impl = (GLib.File)this._keyfile.implementation;
            this.ensure_directory (Path.get_dirname (impl.get_path()));
            try
            {
              this.reset ();
            }
            catch (GLib.Error e)
            {
              critical ("Failed to regenerate the default configuration: %s Code:%d",
                         e.message, e.code);
            }
          }
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

    private bool
    create_file_monitor ()
    {
      this._keyfile_monitor = this._keyfile.monitor ();
      this._monitor_changed_id = Signal.connect_swapped (this._keyfile_monitor,
                                                         "changed",
                                                         (Callback)this.on_keyfile_changed,
                                                         this);
      return false;
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
      }

      try
      {
        this._keyfile = VFS.file_new_for_path (path);
        if (this._keyfile.exists ())
        {
          this.reset_nosave();
          calculate_checksum ();
          this.load_data (this._keyfile);
        }
        else
        {
          this.ensure_directory (Path.get_dirname (path));
          this.reset ();
        }
      }
      catch (GLib.Error e)
      {
        critical ("Configuration error: %s Code:%d", e.message, e.code);
        // Can't really recover from this. If we can't access the keyfile or
        // the settings in the schemas during initialization then we are done.
        // Can't throw from a GLib.Object.constructed.
        //Process.abort();
      }
      // don't immediately create the file monitor, otherwise it will catch
      // the "config file created" signal.
      Idle.add (this.create_file_monitor);
    }

    ~GKeyFile ()
    {
      this._keyfile_monitor.cancel ();
      SignalHandler.disconnect (this._keyfile_monitor,
                                this._monitor_changed_id);
    }

    private void
    reset_nosave () throws GLib.Error
    {
      unowned Schema? schema = this.schema;
      if (schema == null)
      {
        throw new Error.NO_SCHEMA ("The schema was not loaded.");
      }

      this._autosave = false;
      foreach (unowned string group in schema.get_groups ())
      {
        foreach (unowned string key in schema.get_keys (group))
        {
          SchemaOption option = schema.get_option (group, key);
          if (this.instance_id == null || option.per_instance)
          {
            this.set_value (group, key, option.default_value);
          }
        }
      }
      this._autosave = true;
    }

    public override void
    reset () throws GLib.Error
    {
      this.reset_nosave ();
      this.save_config ();
    }

    public override void
    notify_add (string group, string key, NotifyFunc callback) throws GLib.Error
    {
      string full_key = "%s/%s".printf (group, key);
      unowned SList<NotifyDelegate>? funcs = this._notifiers.get_data (full_key);
      NotifyDelegate data = new NotifyDelegate (callback);
      funcs.append ((owned)data);
      this._notifiers.set_data (full_key, funcs);
    }

    public override void
    notify (string group, string key) throws GLib.Error
    {
      string full_key = "%s/%s".printf (group, key);
      Value value = this.get_value (group, key);
      unowned SList<NotifyDelegate> funcs = this._notifiers.get_data (full_key);
      foreach (unowned NotifyDelegate data in funcs)
      {
          // Modified according to config-impl-gconf.vala
          data.execute (group, key, value);
      }
    }

    public override void
    notify_remove (string group, string key, NotifyFunc callback) throws GLib.Error
    {
      string full_key = "%s/%s".printf (group, key);
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

    /**
     * Removes the config file from the file system.
     */
    public override void
    remove () throws GLib.Error
    {
      // Let the FileMonitor code regenerate the file.
      this._keyfile.remove ();
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
        SchemaType st = Schema.find_type (option_type);
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
      if (!this._data.has_group (group) || !this._data.has_key (group, key) ||
          this.get_bool (group, key) != value)
      {
        this._data.set_boolean (group, key, value);
        this.update_config (group, key);
      }
    }

    public override float
    get_float (string group, string key) throws GLib.Error
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
      if (!this._data.has_group (group) || !this._data.has_key (group, key) ||
          this.get_float (group, key) != value)
      {
        this._data.set_double (group, key, value);
        this.update_config (group, key);
      }
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
      if (!this._data.has_group (group) || !this._data.has_key (group, key) ||
          this.get_int (group, key) != value)
      {
        this._data.set_integer (group, key, value);
        this.update_config (group, key);
      }
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
      if (!this._data.has_group (group) || !this._data.has_key (group, key) ||
          this.get_string (group, key) != value)
      {
        this._data.set_string (group, key, value);
        this.update_config (group, key);
      }
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

      if (this._data.has_group (group) && this._data.has_key (group, key))
      {
        ValueArray old_value;

        old_value = this.get_list (group, key);
        if (old_value.n_values == value.n_values)
        {
          bool is_equal = true;
          for (uint i = 0; i < value.n_values; i++)
          {
            // FIXME ridiculously unreliable Value.equals algorithm
            unowned Value old_val;
            unowned Value new_val;

            old_val = old_value.get_nth (i);
            new_val = value.get_nth (i);

            if (old_val.type () != new_val.type () ||
                old_val.strdup_contents () != new_val.strdup_contents ())
            {
              is_equal = false;
              break;
            }
          }
          if (is_equal)
          {
            return;
          }
        }
      }

      if (value.n_values == 0 &&
          (list_type == typeof (bool) || list_type == typeof (int) || list_type == typeof (float)))
      {
        warning ("Discarding empty key: %s", key);
        if (!this._data.has_group (group))
        {
          // Create the group since it could be the only element in the group
          // but discard the key.
          this._data.set_boolean (group, key, true);
          this._data.remove_key (group, key);
        }
        else
        {
          // set_string_list needs NULL the rest of them don't like NULL lists.
          // Keep the last valid value since some values can be mandatory.
          // If the key never existed then discard the key/value pair.
          return;
        }
      }
      else if (list_type == typeof (bool))
      {
        bool[] list = {};
        foreach (unowned Value val in value)
        {
          list += (bool)val;
        }

        this._data.set_boolean_list (group, key, list);
      }
      else if (list_type == typeof (int))
      {
        int[] list = {};
        foreach (unowned Value val in value)
        {
          list += get_int_from_value (val);
        }

        this._data.set_integer_list (group, key, list);
      }
      else if (list_type == typeof (float))
      {
        double[] list = {};
        foreach (unowned Value val in value)
        {
          list += get_float_from_value (val);
        }

        this._data.set_double_list (group, key, list);
      }
      else if (list_type == typeof (string))
      {
        string[] list = {};
        foreach (unowned Value val in value)
        {
          list += (string)val;
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

        string[] list = {};
        foreach (unowned Value val in value)
        {
          list += st.serialize (val);
        }

        this._data.set_string_list (group, key, list);
      }
      this.update_config (group, key);
    }
  }
}
public Type
register_plugin ()
{
  return typeof (DesktopAgnostic.Config.GKeyFile);
}

// vim: set et ts=2 sts=2 sw=2 ai :
