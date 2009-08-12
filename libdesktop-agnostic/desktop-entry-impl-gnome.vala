/*
 * Desktop Agnostic Library: Desktop Entry implementation using GNOME.
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

using DesktopAgnostic.VFS;
using Gnome;

namespace DesktopAgnostic.FDO
{
  public class DesktopEntryGNOME : DesktopEntry, Object
  {
    private DesktopItem item = null;

    private VFS.File _file = null;
    public VFS.File? file
    {
      get
      {
        return this._file;
      }
      set
      {
        if (this.item == null)
        {
          if (value == null)
          {
            this.item = new DesktopItem ();
          }
          else
          {
            string? path;

            this._file = value;
            path = value.path;
            if (path == null)
            {
              this.item = new DesktopItem.from_uri (value.uri, 0);
            }
            else
            {
              this.item = new DesktopItem.from_file (path, 0);
            }
          }
        }
        else
        {
          warning ("The desktop entry has already been initialized.");
        }
      }
    }

    private unowned KeyFile? _keyfile = null;
    public KeyFile keyfile
    {
      get
      {
        return this._keyfile;
      }
      set
      {
        if (this.item == null)
        {
          string data;
          size_t length;

          this._keyfile = value;
          data = value.to_data (out length);
          this.item =
            new DesktopItem.from_string ("", data, (ssize_t)length, 0);
        }
        else
        {
          warning ("The desktop entry has already been initialized.");
        }
      }
    }

    public string data
    {
      set
      {
        if (this.item == null)
        {
          this.item =
            new DesktopItem.from_string ("", value, value.len (), 0);
        }
        else
        {
          warning ("The desktop entry has already been initialized.");
        }
      }
    }

    public DesktopEntryType entry_type
    {
      get
      {
        DesktopEntryType result;
        switch (this.item.get_entry_type ())
        {
          case DesktopItemType.APPLICATION:
            result = DesktopEntryType.APPLICATION;
            break;
          case DesktopItemType.LINK:
            result = DesktopEntryType.LINK;
            break;
          case DesktopItemType.DIRECTORY:
            result = DesktopEntryType.DIRECTORY;
            break;
          default:
            result = DesktopEntryType.UNKNOWN;
            break;
        }

        return result;
      }
      set
      {
        switch (value)
        {
          case DesktopEntryType.UNKNOWN:
            this.item.set_entry_type (DesktopItemType.OTHER);
            break;
          case DesktopEntryType.APPLICATION:
            this.item.set_entry_type (DesktopItemType.APPLICATION);
            break;
          case DesktopEntryType.LINK:
            this.item.set_entry_type (DesktopItemType.LINK);
            break;
          case DesktopEntryType.DIRECTORY:
            this.item.set_entry_type (DesktopItemType.DIRECTORY);
            break;
        }
      }
    }

    public string name
    {
      owned get
      {
        return this.item.get_string (DESKTOP_ITEM_NAME);
      }
      set
      {
        this.item.set_string (DESKTOP_ITEM_NAME, value);
      }
    }

    public string icon
    {
      owned get
      {
        return this.item.get_icon (Gtk.IconTheme.get_default ());
      }
      set
      {
        this.item.set_string (DESKTOP_ITEM_ICON, value);
      }
    }

    public bool
    get_boolean (string key)
    {
      return this.item.get_boolean (key);
    }

    public void
    set_boolean (string key, bool value)
    {
      this.item.set_boolean (key, value);
    }

    public string
    get_string (string key)
    {
      return this.item.get_string (key);
    }

    public void
    set_string (string key, string value)
    {
      this.item.set_string (key, value);
    }

    public string
    get_localestring (string key, string locale)
    {
      return this.item.get_localestring_lang (key, locale);
    }

    public void
    set_localestring (string key, string locale, string value)
    {
      this.item.set_localestring_lang (key, locale, value);
    }

    public string[]
    get_string_list (string key)
    {
      return (string[])this.item.get_strings (key);
    }

    public void
    set_string_list (string key, string[] value)
    {
      this.item.set_strings (key, value);
    }

    public bool
    exists ()
    {
      return this.item.exists ();
    }

    public Pid
    launch (DesktopEntryLaunchFlags flags, SList<string>? documents) throws GLib.Error
    {
      List<string> file_list = new List<string> ();
      DesktopItemLaunchFlags lflags = 0;

      foreach (unowned string document in documents)
      {
        file_list.append (document);
      }
      if ((flags & DesktopEntryLaunchFlags.ONLY_ONE) != 0)
      {
        lflags |= DesktopItemLaunchFlags.ONLY_ONE;
      }
      if ((flags & DesktopEntryLaunchFlags.USE_CWD) != 0)
      {
        lflags |= DesktopItemLaunchFlags.USE_CURRENT_DIR;
      }
      if ((flags & DesktopEntryLaunchFlags.DO_NOT_REAP_CHILD) != 0)
      {
        lflags |= DesktopItemLaunchFlags.DO_NOT_REAP_CHILD;
      }
      return (Pid)this.item.launch (file_list, lflags);
    }

    public void
    save (VFS.File? new_file) throws GLib.Error
    {
      string? uri = null;
      if (new_file != null)
      {
        uri = new_file.uri;
      }
      else if (this._file != null)
      {
        uri = this._file.uri;
      }
      else
      {
        throw new DesktopEntryError.INVALID_FILE ("No filename specified.");
      }
      this.item.save (uri, false);
    }
  }
}

[ModuleInit]
public Type
register_plugin ()
{
  return typeof (DesktopAgnostic.FDO.DesktopEntryGNOME);
}

// vim: set et ts=2 sts=2 sw=2 ai cindent :
