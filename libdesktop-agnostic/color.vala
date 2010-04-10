/*
 * Extension to Gdk.Color which has support for an alpha channel.
 *
 * Copyright (C) 2008, 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
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

using Gdk;

[CCode (cheader_filename = "libdesktop-agnostic/desktop-agnostic.h")]
namespace DesktopAgnostic
{
  public errordomain ColorParseError
  {
    INVALID_INPUT,
    INVALID_ALPHA
  }
  /**
   * Note: cannot use ushort in properties as Value cannot be mapped to it.
   */
  public class Color : Object
  {
    const string HTML_STRING = "#%02hx%02hx%02hx%02hx";
    const ushort HTML_SCALE = 256;
    private Gdk.Color _color;
    public Gdk.Color color
    {
      get
      {
        return this._color;
      }
      set
      {
        this._color = value;
      }
    }
    private ushort
    ushortify (uint value) throws ColorParseError
    {
      if (value < 0 || value > ushort.MAX)
      {
        throw new ColorParseError.INVALID_INPUT ("RGB values must be between 0 and %hu.",
                                                 ushort.MAX);
      }
      return (ushort)value;
    }
    public uint red
    {
      get
      {
        return this._color.red;
      }
      set
      {
        this._color.red = this.ushortify (value);
      }
    }
    public uint green
    {
      get
      {
        return this._color.green;
      }
      set
      {
        this._color.green = this.ushortify (value);
      }
    }
    public uint blue
    {
      get
      {
        return this._color.blue;
      }
      set
      {
        this._color.blue = this.ushortify (value);
      }
    }
    private ushort _alpha = ushort.MAX;
    public uint alpha
    {
      get
      {
        return this._alpha;
      }
      set
      {
        this._alpha = this.ushortify (value);
      }
    }
    public Color (Gdk.Color color, ushort alpha)
    {
      this._color = color;
      this._alpha = alpha;
    }
    public Color.from_values (ushort red, ushort green, ushort blue, ushort alpha)
    {
      this._color = Gdk.Color ();
      this._color.red = red;
      this._color.green = green;
      this._color.blue = blue;
      this._alpha = alpha;
    }
    /**
     * Parses color from string.
     * @see Gdk.Color.parse
     */
    public Color.from_string (string spec) throws ColorParseError
    {
      this._color = Gdk.Color ();
      this._alpha = ushort.MAX; // MIN = transparent, MAX = opaque
      string color_data;
      if (spec.get_char () == '#')
      {
        size_t cd_len = 0;
        unowned string color_hex = spec.offset (1);
        // adapted from pango_color_parse (), licensed under the LGPL2.1+.
        cd_len = (size_t)color_hex.size ();
        if (cd_len % 4 != 0 || cd_len < 4 || cd_len > 16)
        {
          throw new ColorParseError.INVALID_INPUT ("Invalid input size.");
        }
        size_t hex_len = cd_len / 4;
        size_t offset = hex_len * 3;
        string rgb_hex = color_hex.substring (0, (long)offset);
        unowned string alpha_hex = color_hex.offset ((long)offset);
        if (alpha_hex.scanf ("%" + hex_len.to_string () + "hx", ref this._alpha) == 0)
        {
          throw new ColorParseError.INVALID_ALPHA ("Could not parse alpha section of input: %s",
                                                   alpha_hex);
        }
        ushort bits = (ushort)cd_len;
        this._alpha <<= 16 - bits;
        while (bits < 16)
        {
          this._alpha |= (this._alpha >> bits);
          bits *= 2;
        }
        color_data = "#" + rgb_hex;
      }
      else
      {
        // assume color name + no alpha
        color_data = spec;
      }
      if (!Gdk.Color.parse (color_data, out this._color))
      {
        throw new ColorParseError.INVALID_INPUT ("Could not parse color string: %s",
                                                 spec);
      }
    }
    public string
    to_html_color ()
    {
      return HTML_STRING.printf (this.red / HTML_SCALE,
                                 this.green / HTML_SCALE,
                                 this.blue / HTML_SCALE,
                                 this._alpha / HTML_SCALE);
    }
    /**
     * Behaves the same as Gdk.Color.to_string (), except that it adds
     * alpha data.
     * @see Gdk.Color.to_string
     */
    public string
    to_string ()
    {
      string gdk_str = this._color.to_string ();
      return "%s%04x".printf (gdk_str, this._alpha);
    }
    /**
     * Returns the color values as doubles, where 0.0 < value <= 1.0.
     */
    public void
    get_cairo_color (out double red = null, out double green = null,
                     out double blue = null, out double alpha = null)
    {
      if (&red != null)
      {
        red = gdk_value_to_cairo ((ushort)this.red);
      }
      if (&green != null)
      {
        green = gdk_value_to_cairo ((ushort)this.green);
      }
      if (&blue != null)
      {
        blue = gdk_value_to_cairo ((ushort)this.blue);
      }
      if (&alpha != null)
      {
        alpha = gdk_value_to_cairo (this._alpha);
      }
    }
    /**
     * Sets the color with values as doubles, where 0.0 < value <= 1.0.
     */
    public void
    set_cairo_color (double red, double green, double blue, double alpha)
    {
      if (red > 0.0f && red <= 1.0f)
      {
        this.red = cairo_value_to_gdk (red);
      }
      if (green > 0.0f && green <= 1.0f)
      {
        this.green = cairo_value_to_gdk (green);
      }
      if (blue > 0.0f && blue <= 1.0f)
      {
        this.blue = cairo_value_to_gdk (blue);
      }
      if (alpha > 0.0f && alpha <= 1.0f)
      {
        this._alpha = cairo_value_to_gdk (alpha);
      }
    }
    /**
     * Converts a single RGBA value for cairo to its GDK/Pango equivalent.
     */
    public static ushort
    cairo_value_to_gdk (double value)
    {
      return (ushort)(Math.lround (value * 65536) - 1);
    }
    /**
     * Converts a single RGBA value for GDK/Pango to its cairo equivalent.
     */
    public static double
    gdk_value_to_cairo (ushort value)
    {
      return (value + 1) / 65536.0;
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
