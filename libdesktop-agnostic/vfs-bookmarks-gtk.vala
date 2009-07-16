/*
 * Desktop Agnostic Library: VFS GTK+ Bookmarks Parser.
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
 *
 * Based on the code from the Awn Places applet, author Rodney Cryderman
 * <rcryderman@gmail.com>.
 */

using DesktopAgnostic.VFS;

namespace DesktopAgnostic.VFS
{
  /**
   * A representation of a simple bookmark.
   */
  public class Bookmark : Object
  {
    public File.Backend file { get; set; }
    public string? alias { get; set; }
  }
  /**
   * Parses .gtk-bookmarks files.
   */
  public class GtkBookmarks : Object
  {
    private File.Backend _file;
    private File.Monitor _monitor;
    public File.Backend? file
    {
      construct
      {
        if (value == null)
        {
          string fname;

          fname = Path.build_filename (Environment.get_home_dir (),
                                       ".gtk-bookmarks");
          this._file = VFS.File.new_for_path (fname);
        }
        else
        {
          this._file = value;
        }
      }
    }
    private SList<Bookmark>? _bookmarks;
    public unowned SList<Bookmark>? bookmarks
    {
      get
      {
        return this._bookmarks;
      }
    }
    /**
     * Creates a new parser object.
     * @param file the object representing the gtk bookmark file. if %NULL,
     * defaults to "~/.gtk-bookmarks" (defaults to %NULL)
     * @param monitor if %TRUE, monitors the file for changes, and notifies of
     * changes via the "changed" signal (defaults to %TRUE)
     */
    public GtkBookmarks (File.Backend? file = null, bool monitor = true)
    {
      this.file = file;
      if (this._file.exists)
      {
        this.parse ();
      }
      if (monitor)
      {
        this._monitor = this._file.monitor ();
        this._monitor.changed.connect (this.on_file_changed);
      }
    }
    private void
    parse ()
    {
      this._bookmarks = new SList<Bookmark> ();

      try
      {
        string contents;
        size_t length;
        string[] lines;

        this._file.load_contents (out contents, out length);
        lines = contents.split ("\n");
        foreach (unowned string line in lines)
        {
          string[] tokens;

          if (line == "")
          {
            continue;
          }

          tokens = line.split (" ", 2);
          if (tokens != null && tokens[0] != null)
          {
            Bookmark bookmark = new Bookmark ();
            tokens[0].strip ();
            bookmark.file = VFS.File.new_for_uri (tokens[0]);
            if (tokens[1] == null)
            {
              bookmark.alias = null;
            }
            else
            {
              tokens[1].strip ();
              bookmark.alias = tokens[1];
            }
            this._bookmarks.append ((owned)bookmark);
          }
        }
      }
      catch (Error err)
      {
        critical ("Could not load/parse GTK bookmarks file: %s", err.message);
        this._bookmarks = null;
      }
    }
    private void
    on_file_changed (File.Monitor monitor, File.Backend file,
                     File.Backend? other, File.MonitorEvent event)
    {
      switch (event)
      {
        case File.MonitorEvent.CREATED:
        case File.MonitorEvent.CHANGED:
          this.parse ();
          this.changed ();
          break;
        case File.MonitorEvent.DELETED:
          this._bookmarks = null;
          this.changed ();
          break;
        default: // UNKNOWN, ATTRIBUTE_CHANGED
          // do nothing
          break;
      }
    }

    /**
     * Emitted when a monitor has been created for the bookmarks file, and its
     * contents have changed.
     */
    public signal void changed ();
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
