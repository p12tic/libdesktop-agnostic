/*
 * Registers DesktopAgnostic.Color as a valid configuration type.
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

using DesktopAgnostic;

namespace DesktopAgnostic.Config
{
  public class ColorType : SchemaType
  {
    const string DEFAULT_KEY = "default";
    public override string name
    {
      owned get
      {
        return "color";
      }
    }
    public override Type schema_type
    {
      get
      {
        return typeof (Color);
      }
    }
    public override string
    serialize (Value val) throws SchemaError
    {
      unowned Color color = (Color)val.get_object ();
      return color.to_string ();
    }
    public override Value
    deserialize (string serialized) throws SchemaError
    {
      Value val;
      if (serialized == "")
      {
        val = (Object)null;
        return val;
      }
      try
      {
        Color color = new Color.from_string (serialized);
        val = (owned)color;
        return val;
      }
      catch (ColorParseError err)
      {
        throw new SchemaError.PARSE ("Could not deserialize value: %s",
                                     err.message);
      }
    }
    public override Value
    parse_default_value (KeyFile schema, string group) throws SchemaError
    {
      return this.deserialize (schema.get_string (group, DEFAULT_KEY));
    }
    public override ValueArray
    parse_default_list_value (KeyFile schema, string group) throws SchemaError
    {
      ValueArray array;
      try
      {
        string[] list = schema.get_string_list (group, DEFAULT_KEY);
        array = new ValueArray (list.length);
        foreach (unowned string item in list)
        {
          array.append (this.deserialize (item));
        }
      return array;
      }
      catch (KeyFileError err)
      {
        throw new SchemaError.PARSE ("Could not parse the default list value: %s",
                                     err.message);
      }
    }
  }
}
[ModuleInit]
public Type
register_plugin ()
{
  return typeof (DesktopAgnostic.Config.ColorType);
}

// vim: set et ts=2 sts=2 sw=2 ai :
