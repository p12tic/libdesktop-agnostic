/*
 * An in-memory implemenation of the Config interface.
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

namespace DesktopAgnostic.Config
{
  public class Memory : Backend
  {
    private Datalist<Value?> values;
    private Datalist<unowned SList<NotifyDelegate>> _notifiers;
    public override string name
    {
      owned get
      {
        return "Memory";
      }
    }

    construct
    {
      if (this.schema != null)
      {
        try
        {
          this.reset ();
        }
        catch (GLib.Error err)
        {
          critical ("Error: %s", err.message);
        }
        this._notifiers = Datalist<SList<NotifyDelegate>> ();
      }
    }

    public override void
    reset () throws Error
    {
      Schema? schema = this.schema;
      if (schema == null)
      {
        throw new Error.NO_SCHEMA ("The schema was not loaded.");
      }

      this.values = Datalist<Value?> ();
      foreach (string group in schema.get_groups ())
      {
        foreach (string key in schema.get_keys (group))
        {
          string full_key = "%s/%s".printf (group, key);
          SchemaOption option = schema.get_option (group, key);
          this.values.set_data (full_key, option.default_value);
        }
      }
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
    remove () throws GLib.Error
    {
      this.reset ();
    }

    public override Value
    get_value (string group, string key) throws GLib.Error
    {
      string full_key = "%s/%s".printf (group, key);
      Value? result = this.values.get_data (full_key);
      if (result == null)
      {
        throw new Error.KEY_NOT_FOUND ("Could not find the key specified: %s.",
                                       full_key);
      }
      else
      {
        return result;
      }
    }

    public override void
    set_value (string group, string key, Value value) throws GLib.Error
    {
      string full_key = "%s/%s".printf (group, key);
      unowned Value val = value;
      this.values.set_data (full_key, val);
      this.notify (group, key);
    }

    public override bool
    get_bool (string group, string key) throws GLib.Error
    {
      return this.get_value (group, key).get_boolean ();
    }

    public override void
    set_bool (string group, string key, bool value) throws GLib.Error
    {
      string full_key = "%s/%s".printf (group, key);
      Value val = this.get_value (group, key);
      val.set_boolean (value);
      this.values.set_data (full_key, val);
      this.notify (group, key);
    }

    public override float
    get_float (string group, string key) throws Error
    {
      return this.get_value (group, key).get_float ();
    }

    public override void
    set_float (string group, string key, float value) throws GLib.Error
    {
      string full_key = "%s/%s".printf (group, key);
      Value val = this.get_value (group, key);
      val.set_float (value);
      this.values.set_data (full_key, val);
      this.notify (group, key);
    }

    public override int
    get_int (string group, string key) throws GLib.Error
    {
      return this.get_value (group, key).get_int ();
    }

    public override void
    set_int (string group, string key, int value) throws GLib.Error
    {
      string full_key = "%s/%s".printf (group, key);
      Value val = this.get_value (group, key);
      val.set_int (value);
      this.values.set_data (full_key, val);
      this.notify (group, key);
    }

    public override string
    get_string (string group, string key) throws GLib.Error
    {
      return this.get_value (group, key).get_string ();
    }

    public override void
    set_string (string group, string key, string value) throws GLib.Error
    {
      string full_key = "%s/%s".printf (group, key);
      Value val = this.get_value (group, key);
      val.set_string (value);
      this.values.set_data (full_key, val);
      this.notify (group, key);
    }

    public override ValueArray
    get_list (string group, string key) throws GLib.Error
    {
      Value val = this.get_value (group, key);
      return ((ValueArray)val).copy ();
    }

    public override void
    set_list (string group, string key, ValueArray value) throws GLib.Error
    {
      string full_key = "%s/%s".printf (group, key);
      Value val = this.get_value (group, key);
      val.set_boxed (value);
      this.values.set_data (full_key, val);
      this.notify (group, key);
    }
  }
}
[ModuleInit]
public Type
register_plugin ()
{
  return typeof (DesktopAgnostic.Config.Memory);
}

// vim: set et ts=2 sts=2 sw=2 ai :
