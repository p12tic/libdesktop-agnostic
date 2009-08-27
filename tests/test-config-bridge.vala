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

enum TestEnum
{
  ZERO = 0,
  ONE,
  TWO
}

const string DEFAULT_STR = "Not expected string";

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
  public TestEnum enum_val { get; set; }

  construct
  {
    this.str = DEFAULT_STR;
    this.num = 1;
    this.dec = 2.71f;
    this.tf = false;
    //this.arr = new ValueArray (0);
    this.enum_val = TestEnum.ZERO;
  }
}

private class TestDestruct : Test
{
  private Config.Backend cfg;
  public int foo_counter = 0;
  public int str_counter = 0;
  public int num2 { get; set; }
  public static bool instance_exists = false;
  public TestDestruct (Config.Backend cfg)
  {
    this.num2 = 1;
    this.cfg = cfg;
    instance_exists = true;
    this.notify["str"].connect (this.on_str_notify_pre_bind);
  }

  private void
  on_str_notify_pre_bind (ParamSpec spec)
  {
    string str = this.str;

    assert (str != DEFAULT_STR);
    if (str == "foo")
    {
      this.foo_counter++;
    }
    else
    {
      this.str_counter++;
    }
  }

  public void
  add_post_bind_notify ()
  {
    this.notify["str"].connect (this.on_str_notify_post_bind);
  }

  private void
  on_str_notify_post_bind (ParamSpec spec)
  {
    string str = this.str;

    assert (str != DEFAULT_STR);
    if (str == "foo")
    {
      this.foo_counter--;
    }
    else
    {
      this.str_counter--;
    }
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
  if (obj is TestDestruct)
  {
    (obj as TestDestruct).add_post_bind_notify ();
    bridge.bind (cfg, "group", "number", obj, "num2", true);
  }
  bridge.bind (cfg, "group", "decimal", obj, "dec", false);
  bridge.bind (cfg, "group", "tf", obj, "tf", true);
  //bridge.bind (cfg, "group", "array", obj, "arr", false);
  bridge.bind (cfg, "group", "enum", obj, "enum_val", true);
  assert (obj.str == "foo");
  assert (obj.num == 10);
  if (obj is TestDestruct)
  {
    assert ((obj as TestDestruct).num2 == 10);
  }
  assert (obj.dec == 3.14f);
  assert (obj.tf == true);
  //assert (obj.arr.n_values == 3);
  assert (obj.enum_val == TestEnum.ONE);
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
  obj.enum_val = TestEnum.TWO;
  assert (cfg.get_string ("group", "string") == obj.str);
  assert (cfg.get_int ("group", "number") != obj.num);
  assert (cfg.get_float ("group", "decimal") == obj.dec);
  assert (cfg.get_bool ("group", "tf") != obj.tf);
  //assert (cfg.get_list ("group", "array").n_values == obj.arr.n_values);
  assert (cfg.get_int ("group", "enum") != 2);
  if (obj is TestDestruct)
  {
    unowned TestDestruct td = obj as TestDestruct;
    assert (td.foo_counter == 1);
    assert (td.str_counter == 1);
  }
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
