/*
 * Desktop Agnostic Library: Desktop Entry implementation using GLib.
 *
 * Copyright (C) 2010 Michal Hruby <michal.mhr@gmail.com>
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
 * Author : Michal Hruby <michal.mhr@gmail.com>
 */

using DesktopAgnostic;

namespace DesktopAgnostic.FDO
{
  private const string GROUP = "Desktop Entry";
  public class DesktopEntryGio : DesktopEntry, Object
  {
    private KeyFile _keyfile = new KeyFile ();
    private bool loaded = false;
    private VFS.File _file = null;

    public VFS.File? file
    {
      get
      {
        return this._file;
      }
      set construct
      {
        if (value != null)
        {
          if (this.loaded)
          {
            warning ("The desktop entry has already been initialized.");
          }
          else if (value.exists ())
          {
            string? path;

            this._file = value;
            path = value.path;
            if (path == null)
            {
              string data;
              size_t data_len;

              this._file.load_contents (out data, out data_len);
              this._keyfile.load_from_data (data, data_len,
                                            KeyFileFlags.KEEP_TRANSLATIONS);
            }
            else
            {
              this._keyfile.load_from_file (path, KeyFileFlags.KEEP_TRANSLATIONS);
            }
            this.loaded = true;
          }
        }
      }
    }

    public KeyFile keyfile
    {
      get
      {
        return this._keyfile;
      }
      set construct
      {
        if (value != null)
        {
          if (this.loaded)
          {
            warning ("The desktop entry has already been initialized.");
          }
          else
          {
            string data;
            size_t length;

            data = value.to_data (out length);
            this._keyfile.load_from_data (data, length,
                                          KeyFileFlags.KEEP_TRANSLATIONS);
            this.loaded = true;
          }
        }
      }
    }

    public string data
    {
      set construct
      {
        if (value != null && value != "")
        {
          if (this.loaded)
          {
            warning ("The desktop entry has already been initialized.");
          }
          else
          {
            this._keyfile.load_from_data (value, value.size (),
                                          KeyFileFlags.KEEP_TRANSLATIONS);
            this.loaded = true;
          }
        }
      }
    }

    public DesktopEntryType entry_type
    {
      get
      {
        string type = this.get_string ("Type");
        switch (type)
        {
          case "Application":
            return DesktopEntryType.APPLICATION;
          case "Link":
            return DesktopEntryType.LINK;
          case "Directory":
            return DesktopEntryType.DIRECTORY;
          default:
            return DesktopEntryType.UNKNOWN;
        }
      }
      set
      {
        this.set_string ("Type", desktop_entry_type_to_string (value));
      }
    }

    public string name
    {
      owned get
      {
        return this.get_string ("Name");
      }
      set
      {
        this.set_string ("Name", value);
      }
    }

    public string? icon
    {
      /**
       * If a path is provided then return the given value. Otherwise,
       * strip any extension (.xpm, .svg, .png).
       */
      owned get
      {
        string? icon_name = this.get_string ("Icon");

        if (icon_name != null && Path.get_basename (icon_name) == icon_name)
        {
          icon_name = icon_name.split (".png", 2)[0];
          icon_name = icon_name.split (".svg", 2)[0];
          icon_name = icon_name.split (".xpm", 2)[0];
        }

        return icon_name;
      }
      set
      {
        if (value == null)
        {
          warning ("Cannot set a NULL value for 'Icon'.");
        }
        else
        {
          this.set_string ("Icon", value);
        }
      }
    }

    public bool
    key_exists (string key)
    {
      return this._keyfile.has_group (GROUP) &&
             this._keyfile.has_key (GROUP, key);
    }

    public bool
    get_boolean (string key)
    {
      try
      {
        return this._keyfile.get_boolean (GROUP, key);
      }
      catch (KeyFileError err)
      {
        warning ("Error trying to retrieve '%s': %s", key, err.message);
        return false;
      }
    }

    public void
    set_boolean (string key, bool value)
    {
      this._keyfile.set_boolean (GROUP, key, value);
    }

    public string?
    get_string (string key)
    {
      try
      {
        return this._keyfile.get_string (GROUP, key);
      }
      catch (KeyFileError err)
      {
        warning ("Error trying to retrieve '%s': %s", key, err.message);
        return null;
      }
    }

    public void
    set_string (string key, string value)
    {
      this._keyfile.set_string (GROUP, key, value);
    }

    public string?
    get_localestring (string key, string? locale)
    {
      try
      {
        return this._keyfile.get_locale_string (GROUP, key, locale);
      }
      catch (KeyFileError err)
      {
        warning ("Error trying to retrieve '%s[%s]': %s", key, locale,
                 err.message);
        return null;
      }
    }

    public void
    set_localestring (string key, string locale, string value)
    {
      this._keyfile.set_locale_string (GROUP, key, locale, value);
    }

    [CCode (array_length = false, array_null_terminated = true)]
    public string[]?
    get_string_list (string key)
    {
      try
      {
        return this._keyfile.get_string_list (GROUP, key);
      }
      catch (KeyFileError err)
      {
        warning ("Error trying to retrieve '%s': %s", key, err.message);
        return null;
      }
    }

    public void
    set_string_list (string key, [CCode (array_length = false, array_null_terminated = true)] string[] value)
    {
      this._keyfile.set_string_list (GROUP, key, value);
    }

    /**
     * Based on EggDesktopFile's egg_desktop_file_can_launch().
     */
    public bool
    exists ()
    {
      switch (this.entry_type)
      {
        case DesktopEntryType.APPLICATION:
          if (this._keyfile.has_key (GROUP, "TryExec"))
          {
            if (Environment.find_program_in_path (this.get_string ("TryExec")) != null)
            {
              return true;
            }
          }
          string? exec;
          string[] argv = null;;
          exec = this.get_string ("Exec");
          if (exec == null || !Shell.parse_argv (exec, out argv))
          {
            return false;
          }
          return Environment.find_program_in_path (argv[0]) != null;
        case DesktopEntryType.LINK:
          if (this._keyfile.has_key (GROUP, "URL"))
          {
            string uri = this._keyfile.get_string (GROUP, "URL");
            VFS.File file = VFS.file_new_for_uri (uri);
            return file.exists ();
          }
          else
          {
            return false;
          }
        default:
          return false;
      }
    }

    /**
     * Launch desktop entry.
     * @return always zero.
     */
    public Pid
    launch (DesktopEntryLaunchFlags flags,
            SList<string>? documents) throws GLib.Error
    {
      DesktopAppInfo info;
      if (this._file != null)
      {
        info = new DesktopAppInfo.from_filename (this._file.path);
      }
      else
      {
        info = new DesktopAppInfo.from_keyfile (this._keyfile);
      }

      List<unowned string> uris = new List<unowned string> ();
      foreach (unowned string s in documents)
      {
        uris.append (s);
      }

      //var context = new AppLaunchContext ();
      info.launch_uris (uris, null);

      return (Pid) 0;
    }

    public void
    save (VFS.File? new_file) throws GLib.Error
    {
      VFS.File? file = null;
      if (new_file != null)
      {
        file = new_file;
      }
      else if (this._file != null)
      {
        file = this._file;
      }
      else
      {
        throw new DesktopEntryError.INVALID_FILE ("No filename specified.");
      }
      file.replace_contents (this._keyfile.to_data ());
    }
  }
}

public Type
register_plugin ()
{
  return typeof (DesktopAgnostic.FDO.DesktopEntryGio);
}

// vim: set ts=2 sts=2 sw=2 et ai cindent :
