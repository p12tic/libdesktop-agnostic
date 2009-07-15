/*
 * Tests the Color class, plus its interaction with the Config interface.
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

using DesktopAgnostic;

void print_color (Color? clr, string name)
{
  if (clr == null)
  {
    message ("color '%s' is NULL", name);
  }
  else
  {
    message ("color '%s' = %s", name, clr.to_string ());
  }
}

void print_cfg_color (Config.Backend cfg, string name)
{
  Value val;

  val = cfg.get_value (Config.GROUP_DEFAULT, name);
  print_color (val as Color, name);
}

int main (string[] args)
{
  try
  {
    try
    {
      Color green = new Color.from_string ("green");
      assert (green.alpha == 0);
      message ("green = %s", green.to_string ());
    }
    catch (ColorParseError err)
    {
      critical ("Color parse error: %s", err.message);
    }
    Config.Schema schema = new Config.Schema ("test-color.schema-ini");
    Config.Backend cfg = Config.new (schema);
    print_cfg_color (cfg, "color");
    print_cfg_color (cfg, "none");
    Value val = cfg.get_value (Config.GROUP_DEFAULT, "color_list");
    unowned ValueArray array = (ValueArray)val;
    for (uint i = 0; i < array.n_values; i++)
    {
      unowned Value v = array.get_nth (i);
      print_color (v as Color, "color_list[%u]".printf (i));
    }
  }
  catch (Error err)
  {
    critical ("Error: %s", err.message);
    return 1;
  }
  return 0;
}

// vim: set et ts=2 sts=2 sw=2 ai :
