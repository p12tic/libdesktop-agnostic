/*
 * Tests the GtkColorButton wrapper class with GtkBuilder.
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
  Gtk.main_quit ();
}

public static int main (string[] args)
{
  Gtk.Builder builder;
  unowned Gtk.Window window;
  unowned GTK.ColorButton button;

  Gtk.init (ref args);
  builder = new Gtk.Builder ();
  try
  {
    builder.add_from_file ("test-gtk-color-button-gtkbuilder.ui");
    window = builder.get_object ("window1") as Gtk.Window;
    window.delete_event.connect (on_quit);
    button = window.get_child () as GTK.ColorButton;
    button.color_set.connect (on_color_set);
    window.show_all ();
    Gtk.main ();
    return 0;
  }
  catch (Error err)
  {
    critical ("Error: %s", err.message);
    return 1;
  }
}

// vim: set ts=2 sts=2 sw=2 ai cindent :
