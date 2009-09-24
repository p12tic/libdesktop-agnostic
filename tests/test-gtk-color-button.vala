/*
 * Tests the GtkColorButton wrapper class.
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

class TestColorButton : Gtk.Window
{
  construct
  {
    Gtk.VBox box;
    Color color;
    Gtk.Label label;
    GTK.ColorButton button;

    this.delete_event.connect (this.on_quit);
    box = new Gtk.VBox (false, 5);
    label = new Gtk.Label ("With default color");
    box.add (label);
    color = new Color.from_string ("green");
    color.alpha = ushort.MAX / 2;
    button = new GTK.ColorButton.with_color (color);
    button.color_set.connect (this.on_color_set);
    box.add (button);
    label = new Gtk.Label ("Without default color");
    box.add (label);
    button = new GTK.ColorButton ();
    button.color_set.connect (this.on_color_set);
    box.add (button);
    this.add (box);
  }

  private bool
  on_quit (Gtk.Widget widget, Gdk.Event event)
  {
    Gtk.main_quit ();
    return true;
  }

  private void
  on_color_set (Gtk.ColorButton button)
  {
    GTK.ColorButton real_button = button as GTK.ColorButton;
    message ("Selected color: %s", real_button.da_color.to_string ());
    assert (real_button.da_color.color.equal (real_button.color));
    assert (real_button.da_color.alpha == real_button.alpha);
    Gtk.main_quit ();
  }

  public static int main (string[] args)
  {
    TestColorButton window;

    Gtk.init (ref args);
    window = new TestColorButton ();
    window.show_all ();
    Gtk.main ();
    return 0;
  }
}

// vim: set ts=2 sts=2 sw=2 ai cindent :
