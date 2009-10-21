/*
 * Convenience class for GtkColorButton.
 *
 * Copyright (C) 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
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

namespace DesktopAgnostic.GTK
{
  public class ColorButton : Gtk.ColorButton
  {
    private static Color ZERO = new Color.from_values (0, 0, 0, ushort.MAX);
    private ulong da_color_signal;

    public Color da_color { get; set; default = ZERO; }

    public ColorButton.with_color (Color color)
    {
      this.color = color.color;
      this.alpha = color.alpha;
      this.on_color_set ();
    }

    private override void
    constructed ()
    {
      this.use_alpha = true;
      this.da_color_signal = Signal.connect (this, "notify::da-color",
                                             (Callback)this.on_da_color_changed,
                                             null);
      this.color_set.connect (this.on_color_set);
    }

    private void
    on_da_color_changed (ParamSpec pspec)
    {
      if (this._da_color == null)
      {
        this.color = ZERO.color;
        this.alpha = ZERO.alpha;
      }
      else
      {
        this.color = this.da_color.color;
        this.alpha = this.da_color.alpha;
      }
    }

    /**
     * Emits the non-internal signal callbacks for the da-color property.
     */
    private void
    da_color_notify ()
    {
      // don't run on_da_color_changed
      SignalHandler.block (this, this.da_color_signal);
      this.notify_property ("da-color");
      SignalHandler.unblock (this, this.da_color_signal);
    }

    /**
     * Updates the da-color property when the color is updated via the UI.
     */
    private void
    on_color_set ()
    {
      if (this._da_color == null)
      {
        this._da_color = new Color (this.color, (ushort)this.alpha);
      }
      else
      {
        this._da_color.color = this.color;
        this._da_color.alpha = this.alpha;
      }
      this.da_color_notify ();
    }

    public new void
    set_color (Gdk.Color color)
    {
      if (this._da_color == null)
      {
        this._da_color = new Color (color, ushort.MAX);
      }
      else
      {
        this._da_color.alpha = alpha;
      }
    }

    public new void
    set_alpha (uint16 alpha)
    {
      if (this._da_color == null)
      {
        this._da_color = new Color (ZERO.color, alpha);
      }
      else
      {
        this._da_color.alpha = alpha;
      }
      this.da_color_notify ();
      base.set_alpha (alpha);
    }
  }
}

// vim: set ts=2 sts=2 sw=2 ai cindent :
