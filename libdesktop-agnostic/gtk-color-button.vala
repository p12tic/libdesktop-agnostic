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
    public Color da_color { get; set; }
    public ColorButton.with_color (Color color)
    {
      this.color = color.color;
      this.use_alpha = true;
      this.alpha = color.alpha;
      this.color_set.connect (this.on_color_set);
    }

    private void
    on_color_set ()
    {
      if (this.da_color == null)
      {
        this.da_color = new Color (this.color, (ushort)this.alpha);
      }
      else
      {
        this.da_color.color = this.color;
        this.da_color.alpha = this.alpha;
      }
    }

    public new void
    set_alpha (uint16 alpha)
    {
      this.da_color.alpha = alpha;
      base.set_alpha (alpha);
    }
  }
}
