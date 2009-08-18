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

[CCode (cheader_filename = "libdesktop-agnostic/fdo.h")]
namespace DesktopAgnostic.FDO
{
  /**
   * Flags used when launching an application from a desktop entry.
   */
  public enum DesktopEntryLaunchFlags
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
  public enum DesktopEntryType
  {
    UNKNOWN = 0,
    APPLICATION,
    LINK,
    DIRECTORY
  }
  /**
   * Generic, DesktopEntry-related errors.
   */
  public errordomain DesktopEntryError
  {
    INVALID_FILE,
    NOT_LAUNCHABLE
  }
  /**
   * Converts a DesktopEntryType to its string counterpart.
   */
  public static string
  desktop_entry_type_to_string (DesktopEntryType entry_type)
  {
    switch (entry_type)
    {
      case DesktopEntryType.APPLICATION:
        return "Application";
      case DesktopEntryType.LINK:
        return "Link";
      case DesktopEntryType.DIRECTORY:
        return "Directory";
      default:
        return "Unknown";
    }
  }
  public interface DesktopEntry : Object
  {
    // construction
    /**
     * The file object which points to the desktop entry file. Cannot be
     * constructed in conjunction with either keyfile or data.
     * Note: these are really construct-only, but construct-only properties
     * don't work with GModules.
     */
    public abstract VFS.File? file { get; set; }
    /**
     * The URI of the desktop entry. Cannot be constructed with either file
     * or data.
     * Note: these are really construct-only, but construct-only properties
     * don't work with GModules.
     */
    public abstract KeyFile keyfile { get; set; }
    /**
     * The raw data that is formatted according to the desktop entry
     * specification. Cannot be constructed in conjunction with either file or
     * keyfile.
     * Note: these are really construct-only, but construct-only properties
     * don't work with GModules.
     */
    public abstract string data { set; }
    // manipulation
    /**
     * The type of desktop entry, corresponding to the "Type" key.
     */
    public abstract DesktopEntryType entry_type { get; set; }
    public abstract string name { owned get; set; }
    public abstract string icon { owned get; set; }
    public abstract bool get_boolean (string key);
    public abstract void set_boolean (string key, bool value);
    public abstract string? get_string (string key);
    public abstract void set_string (string key, string value);
    public abstract string? get_localestring (string key, string locale);
    public abstract void set_localestring (string key, string locale, string value);
    [CCode (array_length = false, array_null_terminated = true)]
    public abstract string[]? get_string_list (string key);
    public abstract void set_string_list (string key, [CCode (array_length = false, array_null_terminated = true)] string[] value);
    // miscellaneous
    /**
     * Whether the path specified in the "Exec" key exists. if the entry type is
     * "Application", also checks to see if it's launchable.
     */
    public abstract bool exists ();
    public abstract Pid launch (DesktopEntryLaunchFlags flags, SList<string>? documents) throws GLib.Error;
    public abstract void save (VFS.File? new_file) throws GLib.Error;
  }

  private static Type? module_type = null;

  public Type
  get_type () throws GLib.Error
  {
    if (module_type == null)
    {
      module_type = get_module_type ("fdo", "desktop-entry");
    }
    return module_type;
  }

  /**
   * Convenience method for creating a new desktop entry from scratch.
   */
  public DesktopEntry?
  desktop_entry_new () throws GLib.Error
  {
    Type type = get_type ();
    if (type == Type.INVALID)
    {
      return null;
    }
    else
    {
      return (DesktopEntry)Object.new (type);
    }
  }

  /**
   * Convenience method for loading a desktop entry via a VFS.File.
   */
  public DesktopEntry?
  desktop_entry_new_for_file (VFS.File file) throws GLib.Error
  {
    Type type = get_type ();
    if (type == Type.INVALID)
    {
      return null;
    }
    else
    {
      return (DesktopEntry)Object.new (type, "file", file);
    }
  }

  /**
   * Convenience method for loading a desktop entry from a KeyFile object.
   */
  public DesktopEntry?
  desktop_entry_new_for_keyfile (KeyFile keyfile) throws GLib.Error
  {
    Type type = get_type ();
    if (type == Type.INVALID)
    {
      return null;
    }
    else
    {
      return (DesktopEntry)Object.new (type, "keyfile", keyfile);
    }
  }

  /**
   * Convenience method for loading a desktop entry from a string of data.
   */
  public DesktopEntry?
  desktop_entry_new_for_data (string data) throws GLib.Error
  {
    Type type = get_type ();
    if (type == Type.INVALID)
    {
      return null;
    }
    else
    {
      return (DesktopEntry)Object.new (type, "data", data);
    }
  }
}

// vim: set ts=2 sts=2 sw=2 et ai cindent :
