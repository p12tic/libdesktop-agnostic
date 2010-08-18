/*
 * Desktop Agnostic Library: Desktop Entry implementation using GLib.
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

namespace DesktopAgnostic.FDO
{
  private const string GROUP = "Desktop Entry";
  public class DesktopEntryGLib : DesktopEntry, Object
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
     * Ported from EggDesktopFile.
     */
    private string
    get_quoted_word (string word, bool in_single_quotes, bool in_double_quotes)
    {
      string result = "";

      if (!in_single_quotes && !in_double_quotes)
      {
        result += "'";
      }
      else if (!in_single_quotes && in_double_quotes)
      {
        result += "\"'";
      }

      if (word.contains ("'"))
      {
        for (string s = word; s != null && s.len () > 0; s = s.next_char ())
        {
          string chr = s.substring (0, 1);
          if (chr == "'")
          {
            result += "'\\''";
          }
          else
          {
            result += chr;
          }
        }
      }
      else
      {
        result += word;
      }

      if (!in_single_quotes && !in_double_quotes)
      {
        result += "'";
      }
      else if (!in_single_quotes && in_double_quotes)
      {
        result += "'\"";
      }

      return result;
    }

    /**
     * Ported from EggDesktopFile.
     */
    private string
    do_percent_subst (string code, SList<string>? documents, bool in_single_quotes,
                      bool in_double_quotes)
    {
      switch (code)
      {
        case "%":
          return "%";
        case "F":
        case "U":
          string result = "";
          foreach (unowned string doc in documents)
          {
            result += " " + this.get_quoted_word (doc, in_single_quotes,
                                                  in_double_quotes);
          }
          return result;
        case "f":
        case "u":
          if (documents == null)
          {
            return "";
          }
          else
          {
            return " " + this.get_quoted_word (documents.data, in_single_quotes,
                                               in_double_quotes);
          }
        case "i":
          string? icon = this.icon;
          if (icon == null)
          {
            return "";
          }
          else
          {
            return "--icon " + this.get_quoted_word (icon, in_single_quotes,
                                                     in_double_quotes);
          }
        case "c":
          string? name = this.name;
          if (name == null)
          {
            return "";
          }
          else
          {
            return this.get_quoted_word (name, in_single_quotes, in_double_quotes);
          }
        case "k":
          if (this._file == null)
          {
            return "";
          }
          else
          {
            return this._file.uri;
          }
        case "D":
        case "N":
        case "d":
        case "n":
        case "v":
        case "m":
          // deprecated, skip
          return "";
        default:
          warning ("Unrecognized %%-code '%%%s' in Exec.", code);
          return "";
      }
    }

    /**
     * Ported from EggDesktopFile.
     */
    private string?
    parse_exec (SList<string>? documents)
    {
      string exec;
      string command = "";
      bool escape, single_quot, double_quot;

      if (!this._keyfile.has_key (GROUP, "Exec"))
      {
        return null;
      }

      exec = this.get_string ("Exec");

      escape = single_quot = double_quot = false;

      for (string s = exec; s != null && s.len () > 0; s = s.next_char ())
      {
        string chr = s.substring (0, 1);
        if (escape)
        {
          escape = false;
          command += chr;
        }
        else if (chr == "\\")
        {
          if (!single_quot)
          {
            escape = true;
          }
          command += chr;
        }
        else if (chr == "'")
        {
          command += chr;

          if (!single_quot && !double_quot)
          {
            single_quot = true;
          }
          else if (single_quot)
          {
            single_quot = false;
          }
        }
        else if (chr == "\"")
        {
          command += chr;
          if (!single_quot && !double_quot)
          {
            double_quot = true;
          }
          else if (double_quot)
          {
            double_quot = false;
          }
        }
        else if (chr == "%")
        {
          string? pchr = s.substring (1, 1);
          if (pchr == null)
          {
            command += chr;
          }
          else
          {
            command += this.do_percent_subst (pchr, documents, single_quot, double_quot);
            s = s.next_char ();
          }
        }
        else
        {
          command += chr;
        }
      }
      return command;
    }

    private Pid
    do_app_launch (string? working_dir, SpawnFlags flags,
                   SList<string>? documents) throws GLib.Error
    {
      string[] argv;
      Pid pid;

      if (!Shell.parse_argv (this.parse_exec (documents), out argv))
      {
        throw new DesktopEntryError.NOT_LAUNCHABLE ("Could not parse Exec key.");
      }

      Process.spawn_async_with_pipes (working_dir, argv, null, flags, null, out pid);
      return pid;
    }

    /**
     * Based on EggDesktopFile's egg_desktop_file_launch().
     * @return the PID of the last process launched.
     */
    public Pid
    launch (DesktopEntryLaunchFlags flags,
            SList<string>? documents) throws GLib.Error
    {
      switch (this.entry_type)
      {
        case DesktopEntryType.APPLICATION:
          SpawnFlags sflags = SpawnFlags.SEARCH_PATH;
          string working_dir;
          Pid pid;

          if ((flags & DesktopEntryLaunchFlags.DO_NOT_REAP_CHILD) != 0)
          {
            sflags |= SpawnFlags.DO_NOT_REAP_CHILD;
          }
          if ((flags & DesktopEntryLaunchFlags.USE_CWD) != 0)
          {
            working_dir = Environment.get_current_dir ();
          }
          else
          {
            working_dir = Environment.get_home_dir ();
          }

          if ((flags & DesktopEntryLaunchFlags.ONLY_ONE) == 0 &&
              documents != null)
          {
            pid = (Pid)0;
            foreach (unowned string doc in documents)
            {
              SList<string> docs = new SList<string> ();
              docs.append (doc);
              pid = this.do_app_launch (working_dir, sflags, docs);
            }
          }
          else
          {
            pid = this.do_app_launch (working_dir, sflags, documents);
          }
          return pid;
        case DesktopEntryType.LINK:
          if (documents != null)
          {
            throw new DesktopEntryError.NOT_LAUNCHABLE ("Cannot pass documents to a 'Link' desktop entry.");
          }
          string uri = this._keyfile.get_string (GROUP, "URL");
          VFS.File file = VFS.file_new_for_uri (uri);
          file.launch ();
          return (Pid)0;
        default:
          throw new DesktopEntryError.NOT_LAUNCHABLE ("The desktop entry is unlaunchable.");
      }
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
  return typeof (DesktopAgnostic.FDO.DesktopEntryGLib);
}

// vim: set ts=2 sts=2 sw=2 et ai cindent :
