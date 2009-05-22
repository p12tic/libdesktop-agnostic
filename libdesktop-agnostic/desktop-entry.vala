/*
 * Desktop Agnostic Library: Desktop Entry interface.
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
  /**
   * Flags used when launching an application from a desktop entry.
   */
  public enum LaunchFlags
  {
    // use documents to fill argv instead of launching one app per document
    ONLY_ONE = 1 << 0,
    // use current working directory instead of home directory
    USE_CWD = 1 << 1,
    // don't automatically reap child process
    DO_NOT_REAP_CHILD = 1 << 2
  }
  /**
   * The kind of desktop entry.
   * @see http://standards.freedesktop.org/desktop-entry-spec/latest/ar01s05.html
   */
  public enum Type
  {
    UNKNOWN = 0,
    APPLICATION,
    LINK,
    DIRECTORY
  }
  /**
   * Generic, DesktopEntry-related errors.
   */
  public errordomain Error
  {
    INVALID_FILE,
    NOT_LAUNCHABLE
  }
  /**
   * Converts a DesktopEntry.Type to its string counterpart.
   */
  public static string type_to_string (DesktopEntry.Type entry_type)
  {
    switch (entry_type)
    {
      case DesktopEntry.Type.APPLICATION:
        return "Application";
      case DesktopEntry.Type.LINK:
        return "Link";
      case DesktopEntry.Type.DIRECTORY:
        return "Directory";
      default:
        return "Unknown";
    }
  }
  public interface Backend : Object
  {
    // construction
    /**
     * The filename of the desktop entry. Cannot be constructed in conjunction
     * with any of uri, keyfile, or data.
     * Note: these are really construct-only, but construct-only properties
     * don't work with GModules.
     */
    public abstract string? filename { owned get; set; }
    /**
     * The URI of the desktop entry. Cannot be constructed with any of filename,
     * keyfile, or data.
     * Note: these are really construct-only, but construct-only properties
     * don't work with GModules.
     */
    public abstract string? uri { owned get; set; }
    public abstract KeyFile keyfile { get; set; }
    /**
     * The raw data that is formatted according to the desktop entry
     * specification. Cannot be constructed in conjunction with any of filename,
     * uri, or keyfile.
     * Note: these are really construct-only, but construct-only properties
     * don't work with GModules.
     */
    public abstract string data { set; }
    // manipulation
    /**
     * The type of desktop entry, corresponding to the "Type" key.
     */
    public abstract DesktopEntry.Type entry_type { get; set; }
    public abstract string name { get; set; }
    public abstract string icon { get; set; }
    public abstract bool get_boolean (string key);
    public abstract void set_boolean (string key, bool value);
    public abstract string get_string (string key);
    public abstract void set_string (string key, string value);
    public abstract string get_localestring (string key, string locale);
    public abstract void set_localestring (string key, string locale, string value);
    public abstract string[] get_string_list (string key);
    public abstract void set_string_list (string key, string[] value);
    //public abstract string[] get_localestring_list (string key, string locale);
    //public abstract void set_localestring_list (string key, string locale, string[] value);
    // miscellaneous
    /**
     * Whether the path specified in the "Exec" key exists. if the entry type is
     * "Application", also checks to see if it's launchable.
     */
    public abstract bool exists ();
    public abstract Pid launch (LaunchFlags flags, SList<string>? documents) throws GLib.Error;
    public abstract void save (VFS.File.Backend? new_file) throws GLib.Error;
  }

  public GLib.Type?
  get_type () throws GLib.Error
  {
    GLib.Type type = get_module_type ("de", "desktop-entry");
    if (type == GLib.Type.INVALID)
    {
      return null;
    }
    else
    {
      return type;
    }
  }

  /**
   * Convenience method for creating a new desktop entry from scratch.
   */
  public Backend?
  @new () throws GLib.Error
  {
    return (Backend)Object.new (get_type ());
  }

  /**
   * Convenience method for loading a desktop entry via a local filename.
   */
  public Backend?
  new_for_filename (string filename) throws GLib.Error
  {
    return (Backend)Object.new (get_type (),
                                "filename", filename);
  }

  /**
   * Convenience method for loading a desktop entry via a URI.
   */
  public Backend?
  new_for_uri (string uri) throws GLib.Error
  {
    return (Backend)Object.new (get_type (),
                                "uri", uri);
  }

  /**
   * Convenience method for loading a desktop entry from a KeyFile object.
   */
  public Backend?
  new_for_keyfile (KeyFile keyfile) throws GLib.Error
  {
    return (Backend)Object.new (get_type (),
                                "keyfile", keyfile);
  }

  /**
   * Convenience method for loading a desktop entry from a string of data.
   */
  public Backend?
  new_for_data (string data) throws GLib.Error
  {
    return (Backend)Object.new (get_type (),
                                "data", data);
  }
}

// vim: set ts=2 sts=2 sw=2 et ai cindent :
