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

private class Test : Object
{
  public string str { get; set; }
  public int num { get; set; }

  construct
  {
    this.str = "Not expected string";
    this.num = 1;
  }
}

private class TestDestruct : Test
{
  private Config.Backend cfg;
  TestDestruct (Config.Backend cfg)
  {
    this.cfg = cfg;
  }

  ~TestDestruct ()
  {
    unowned Config.Bridge bridge = Config.Bridge.get_default ();
    bridge.remove_all_for_object (this.cfg, this);
  }
}

int main (string[] args)
{
  try
  {
    Config.Schema schema = new Config.Schema ("test-config-bridge.schema-ini");
    Config.Backend cfg = Config.new (schema);
    Config.Bridge bridge = Config.Bridge.get_default ();

    cfg.reset ();

    Test t = new Test ();
    bridge.bind (cfg, "group", "string", t, "str", false);
    bridge.bind (cfg, "group", "number", t, "num", true);
    assert (t.str == "foo");
    assert (t.num == 10);
    t.str = "Some new string";
    t.num = 100;
    assert (cfg.get_string ("group", "string") == t.str);
    assert (cfg.get_int ("group", "number") != t.num);
    bridge.remove_all_for_object (cfg, t);

    cfg.reset ();

    assert (cfg.get_string ("group", "string") == "foo");

    TestDestruct td = new TestDestruct (cfg);
    bridge.bind (cfg, "group", "string", td, "str", false);
    bridge.bind (cfg, "group", "number", td, "num", true);
    assert (td.str == "foo");
    assert (td.num == 10);
    td.str = "Some new string";
    td.num = 100;
    assert (cfg.get_string ("group", "string") == td.str);
    assert (cfg.get_int ("group", "number") != td.num);
    td = null;
  }
  catch (Error err)
  {
    critical ("Error: %s", err.message);
    return 1;
  }
  return 0;
}

// vim: set et ts=2 sts=2 sw=2 ai :
