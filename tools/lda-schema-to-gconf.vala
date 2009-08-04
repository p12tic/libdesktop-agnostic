/*
 * Desktop Agnostic Library: Desktop Agnostic to GConf schema converter.
 *
 * Copyright (C) 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author : Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 */

using DesktopAgnostic.Config;

string schema_type_to_string (Type type)
{
  if (type == typeof (bool))
  {
    return "bool";
  }
  else if (type == typeof (int))
  {
    return "int";
  }
  else if (type == typeof (float))
  {
    return "float";
  }
  else if (type == typeof (string))
  {
    return "string";
  }
  else if (type == typeof (ValueArray))
  {
    return "list";
  }
  else
  {
    return "string";
  }
}

void value_array_to_string (Value src_value, out Value dest_value)
{
  unowned ValueArray arr = (ValueArray)src_value;
  StringBuilder res = new StringBuilder ("[");

  for (uint i = 0; i < arr.n_values; i++)
  {
    unowned Value val = arr.get_nth (i);
    assert (Value.type_transformable (val.type (), typeof (string)));
    Value val_str = Value (typeof (string));
    val.transform (ref val_str);
    if (i != 0)
    {
      res.append (",");
    }
    res.append ((string)val_str);
  }

  res.append ("]");

  dest_value = res.str;
}

int main (string[] args)
{
  if (args.length < 2)
  {
    return 1;
  }
  // register the ValueArray->string transform
  Value.register_transform_func (typeof (ValueArray), typeof (string),
                                 value_array_to_string);
  try
  {
    DesktopAgnostic.ModuleLoader.get_default ().load ("libda-cfg-gconf");
    Schema schema = new Schema (args[1]);
    StringBuilder gconf;

    gconf = new StringBuilder ("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
    gconf.append ("<gconfschemafile>\n  <schemalist>\n");

    foreach (unowned string group in schema.get_groups ())
    {
      string base_path;
      string app_name;
      string path_prefix;

      base_path = schema.get_metadata_option ("GConf.base_path").get_string ();
      app_name = schema.app_name;

      if (group == GROUP_DEFAULT)
      {
        path_prefix = "%s/%s".printf (base_path, app_name);
      }
      else
      {
        path_prefix = "%s/%s/%s".printf (base_path, app_name, group);
      }
      foreach (unowned string key in schema.get_keys (group))
      {
        SchemaOption option = schema.get_option (group, key);
        Type type = option.option_type;
        Value default_value = Value (typeof (string));
        string? summary;

        gconf.append ("    <schema>\n");
        gconf.append (Markup.printf_escaped ("      <key>/schemas%s/%s</key>\n",
                                             path_prefix, key));
        gconf.append (Markup.printf_escaped ("      <applyto>%s/%s</applyto>\n",
                                             path_prefix, key));
        gconf.append (Markup.printf_escaped ("      <owner>%s</owner>\n",
                                             app_name));
        gconf.append (Markup.printf_escaped ("      <type>%s</type>\n",
                                             schema_type_to_string (type)));
        if (type == typeof (ValueArray))
        {
          Type list_type = option.list_type;

          gconf.append (Markup.printf_escaped ("      <list_type>%s</list_type>\n",
                                               schema_type_to_string (list_type)));
        }
        option.default_value.transform (ref default_value);
        if (null == (string)default_value)
        {
          default_value = "";
        }
        gconf.append (Markup.printf_escaped ("      <default>%s</default>\n",
                                             (string)default_value));
        gconf.append ("      <locale name=\"C\">\n");
        summary = option.summary;
        if (summary != null && summary != "")
        {
          gconf.append (Markup.printf_escaped ("        <short>%s</short>\n",
                                               summary));
        }
        gconf.append (Markup.printf_escaped ("        <long>%s</long>\n",
                                             option.description));
        gconf.append ("      </locale>\n");
        // TODO locale-specific summaries/descriptions
        gconf.append ("    </schema>\n");
      }
    }

    gconf.append ("  </schemalist>\n</gconfschemafile>\n");
    if (args.length < 3)
    {
      stdout.printf (gconf.str);
    }
    else
    {
      FileUtils.set_contents (args[2], gconf.str, gconf.len);
    }
  }
  catch (GLib.Error err)
  {
    critical ("Error: %s", err.message);
    return 1;
  }

  return 0;
}

// vim: set et ts=2 sts=2 sw=2 ai :
