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

int main (string[] args)
{
  Config.Backend cfg = config_get_default ("test-config-bridge.schema-ini");
  Config.Bridge bridge = Config.Bridge.get_default ();
  Test t = new Test ();
  bridge.bind (cfg, "group", "string", t, "str");
  bridge.bind (cfg, "group", "number", t, "num");
  message ("Backend: '%s'; String: '%s'; Integer: %d", cfg.name, t.str, t.num);
  return 0;
}

// vim: set et ts=2 sts=2 sw=2 ai :
