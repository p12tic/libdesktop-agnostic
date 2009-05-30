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

namespace DesktopAgnostic.DesktopEntry
{
  private const string GROUP = "Desktop Entry";
  public class GLibImplementation : Backend, Object
  {
    private KeyFile _keyfile = null;
    private bool loaded = false;

    public KeyFile keyfile
    {
      get
      {
        return this._keyfile;
      }
      set
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

    public string data
    {
      set
      {
        if (this.loaded)
        {
          warning ("The desktop entry has already been initialized.");
        }
        else
        {
          this._keyfile.load_from_data (value, value.len (),
                                        KeyFileFlags.KEEP_TRANSLATIONS);
          this.loaded = true;
        }
      }
    }

    private VFS.File.Backend _file = null;
    public string? filename
    {
      owned get
      {
        if (this._file == null)
        {
          return null;
        }
        else
        {
          return this._file.path;
        }
      }
      set
      {
        if (this.loaded)
        {
          warning ("The desktop entry has already been initialized.");
        }
        else
        {
          this._file = VFS.File.new_for_path (value);
          this._keyfile.load_from_file (value, KeyFileFlags.KEEP_TRANSLATIONS);
          this.loaded = true;
        }
      }
    }

    public string? uri
    {
      get
      {
        if (this._file == null)
        {
          return null;
        }
        else
        {
          return this._file.uri;
        }
      }
      set
      {
        if (this.loaded)
        {
          warning ("The desktop entry has already been initialized.");
        }
        else
        {
          string data;
          size_t data_len;

          this._file = VFS.File.new_for_uri (value);
          this._file.load_contents (out data, out data_len);
          this._keyfile.load_from_data (data, data_len,
                                        KeyFileFlags.KEEP_TRANSLATIONS);
          this.loaded = true;
        }
      }
    }

    public DesktopEntry.Type entry_type
    {
      get
      {
        string type = this.get_string ("Type");
        switch (type)
        {
          case "Application":
            return DesktopEntry.Type.APPLICATION;
          case "Link":
            return DesktopEntry.Type.LINK;
          case "Directory":
            return DesktopEntry.Type.DIRECTORY;
          default:
            return DesktopEntry.Type.UNKNOWN;
        }
      }
      set
      {
        this.set_string ("Type", type_to_string (value));
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

    public string icon
    {
      owned get
      {
        return this.get_string ("Icon");
      }
      set
      {
        this.set_string ("Icon", value);
      }
    }

    construct
    {
      this._keyfile = new KeyFile ();
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
        assert_not_reached ();
      }
    }

    public void
    set_boolean (string key, bool value)
    {
      this._keyfile.set_boolean (GROUP, key, value);
    }

    public string
    get_string (string key)
    {
      try
      {
        return this._keyfile.get_string (GROUP, key);
      }
      catch (KeyFileError err)
      {
        assert_not_reached ();
      }
    }

    public void
    set_string (string key, string value)
    {
      this._keyfile.set_string (GROUP, key, value);
    }

    public string
    get_localestring (string key, string locale)
    {
      try
      {
        return this._keyfile.get_locale_string (GROUP, key, locale);
      }
      catch (KeyFileError err)
      {
        assert_not_reached ();
      }
    }

    public void
    set_localestring (string key, string locale, string value)
    {
      this._keyfile.set_locale_string (GROUP, key, locale, value);
    }

    public string[]
    get_string_list (string key)
    {
      try
      {
        return this._keyfile.get_string_list (GROUP, key);
      }
      catch (KeyFileError err)
      {
        assert_not_reached ();
      }
    }

    public void
    set_string_list (string key, string[] value)
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
        case DesktopEntry.Type.APPLICATION:
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
        case DesktopEntry.Type.LINK:
          if (this._keyfile.has_key (GROUP, "URL"))
          {
            string uri = this._keyfile.get_string (GROUP, "URL");
            VFS.File.Backend file = VFS.File.new_for_uri (uri);
            return file.exists;
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
        throw new DesktopEntry.Error.NOT_LAUNCHABLE ("Could not parse Exec key.");
      }

      Process.spawn_async_with_pipes (working_dir, argv, null, flags, null, out pid);
      return pid;
    }

    /**
     * Based on EggDesktopFile's egg_desktop_file_launch().
     * @return the PID of the last process launched.
     */
    public Pid
    launch (LaunchFlags flags, SList<string>? documents) throws GLib.Error
    {
      switch (this.entry_type)
      {
        case DesktopEntry.Type.APPLICATION:
          SpawnFlags sflags = SpawnFlags.SEARCH_PATH;
          string working_dir;
          Pid pid;

          if ((flags & LaunchFlags.DO_NOT_REAP_CHILD) != 0)
          {
            sflags |= SpawnFlags.DO_NOT_REAP_CHILD;
          }
          if ((flags & LaunchFlags.USE_CWD) != 0)
          {
            working_dir = Environment.get_current_dir ();
          }
          else
          {
            working_dir = Environment.get_home_dir ();
          }

          if ((flags & LaunchFlags.ONLY_ONE) == 0 && documents != null)
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
        case DesktopEntry.Type.LINK:
          if (documents != null)
          {
            throw new DesktopEntry.Error.NOT_LAUNCHABLE ("Cannot pass documents to a 'Link' desktop entry.");
          }
          string uri = this._keyfile.get_string (GROUP, "URL");
          VFS.File.Backend file = VFS.File.new_for_uri (uri);
          file.launch ();
          return (Pid)0;
        default:
          throw new DesktopEntry.Error.NOT_LAUNCHABLE ("The desktop entry is unlaunchable.");
      }
    }

    public void
    save (VFS.File.Backend? new_file) throws GLib.Error
    {
      VFS.File.Backend? file = null;
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
        throw new DesktopEntry.Error.INVALID_FILE ("No filename specified.");
      }
      file.replace_contents (this._keyfile.to_data ());
    }
  }
}

[ModuleInit]
public Type
register_plugin ()
{
  return typeof (DesktopAgnostic.DesktopEntry.GLibImplementation);
}

// vim: set ts=2 sts=2 sw=2 et ai cindent :
