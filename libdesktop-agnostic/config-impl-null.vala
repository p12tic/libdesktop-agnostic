/* 
 * A NULL implemenation of the Config interface. Used only for testing.
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
 * Author : Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 */

using GLib;

namespace DesktopAgnostic.Config
{
  public class Null : Backend
  {
    public override string name
    {
      get
      {
        return "null";
      }
    }

    public override void
    reset () throws Error
    {
    }

    public override void
    notify_add (string group, string key, NotifyFunc callback)
    {
    }

    public override void
    notify (string group, string key)
    {
    }

    public override void
    notify_remove (string group, string key, NotifyFunc callback) throws Error
    {
    }

    public override void
    remove () throws Error
    {
    }

    public override Value
    get_value (string group, string key) throws Error
    {
      Value value;
      value = Value (Type.INVALID);
      return value;
    }

    public override bool
    get_bool (string group, string key) throws Error
    {
      return false;
    }

    public override void
    set_bool (string group, string key, bool value) throws Error
    {
    }

    public override float
    get_float (string group, string key) throws Error
    {
      return (float)0.0;
    }

    public override void
    set_float (string group, string key, float value) throws Error
    {
    }

    public override int
    get_int (string group, string key) throws Error
    {
      return 0;
    }

    public override void
    set_int (string group, string key, int value) throws Error
    {
    }

    public override string
    get_string (string group, string key) throws Error
    {
      return "";
    }

    public override void
    set_string (string group, string key, string value) throws Error
    {
    }

    public override ValueArray
    get_list (string group, string key) throws Error
    {
      return new ValueArray (0);
    }

    public override void
    set_list (string group, string key, ValueArray value) throws Error
    {
    }
  }
}
[ModuleInit]
public Type
register_plugin (TypeModule module)
{
  return typeof (DesktopAgnostic.Config.Null);
}

// vim: set et ts=2 sts=2 sw=2 ai :
