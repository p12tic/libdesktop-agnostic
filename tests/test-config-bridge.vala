/*
 * Tests the GObject <-> Config bridge
 *
 * Copyright (C) 2008, 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
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

using GLib;
using DesktopAgnostic;

/**
 * Note: array test disabled until the following Vala bug is fixed:
 * http://bugzilla.gnome.org/show_bug.cgi?id=592493
 */
private class Test : Object
{
  public string str { get; set; }
  public int num { get; set; }
  public float dec { get; set; }
  public bool tf { get; set; }
  //public unowned ValueArray arr { get; set; }

  construct
  {
    this.str = "Not expected string";
    this.num = 1;
    this.dec = 2.71f;
    this.tf = false;
    //this.arr = new ValueArray (0);
  }
}

private class TestDestruct : Test
{
  private Config.Backend cfg;
  public static bool instance_exists = false;
  public TestDestruct (Config.Backend cfg)
  {
    this.cfg = cfg;
    instance_exists = true;
  }

  ~TestDestruct ()
  {
    unowned Config.Bridge bridge = Config.Bridge.get_default ();
    bridge.remove_all_for_object (this.cfg, this);
    instance_exists = false;
  }
}

private void
bridge_assertions (Config.Backend cfg, Config.Bridge bridge, Test obj) throws Error
{
  /*ValueArray new_array;
  Value array_item;*/
  cfg.reset ();

  assert (cfg.get_string ("group", "string") == "foo");

  bridge.bind (cfg, "group", "string", obj, "str", false);
  bridge.bind (cfg, "group", "number", obj, "num", true);
  bridge.bind (cfg, "group", "decimal", obj, "dec", false);
  bridge.bind (cfg, "group", "tf", obj, "tf", true);
  //bridge.bind (cfg, "group", "array", obj, "arr", false);
  assert (obj.str == "foo");
  assert (obj.num == 10);
  assert (obj.dec == 3.14f);
  assert (obj.tf == true);
  //assert (obj.arr.n_values == 3);
  obj.str = "Some new string";
  obj.num = 100;
  obj.dec = 1.618f;
  obj.tf = false;
  /*new_array = new ValueArray (2);
  array_item = "z";
  new_array.append (array_item);
  array_item = "y";
  new_array.append (array_item);
  obj.arr = new_array;*/
  assert (cfg.get_string ("group", "string") == obj.str);
  assert (cfg.get_int ("group", "number") != obj.num);
  assert (cfg.get_float ("group", "decimal") == obj.dec);
  assert (cfg.get_bool ("group", "tf") != obj.tf);
  //assert (cfg.get_list ("group", "array").n_values == obj.arr.n_values);
}

int main (string[] args)
{
  try
  {
    Config.Schema schema = new Config.Schema ("test-config-bridge.schema-ini");
    Config.Backend cfg = Config.new (schema);
    unowned Config.Bridge bridge = Config.Bridge.get_default ();
    Test t;
    TestDestruct td;

    t = new Test ();
    bridge_assertions (cfg, bridge, t);
    bridge.remove_all_for_object (cfg, t);
    cfg.reset ();

    td = new TestDestruct (cfg);
    bridge_assertions (cfg, bridge, td);
    td = null;
    assert (!TestDestruct.instance_exists);

    t = new Test ();
    bridge_assertions (cfg, bridge, t);

    td = new TestDestruct (cfg);
    bridge_assertions (cfg, bridge, td);
    td = null;
    assert (!TestDestruct.instance_exists);

    bridge.remove_all_for_object (cfg, t);
  }
  catch (Error err)
  {
    critical ("Error: %s", err.message);
    return 1;
  }
  return 0;
}

// vim: set et ts=2 sts=2 sw=2 ai :
