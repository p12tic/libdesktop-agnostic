/*
 * Desktop Agnostic Library: Trash implementation with Thunar VFS.
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

using DBus;
using ThunarVfs;

[DBus (name = "org.xfce.Trash")]
public interface Xfce.Trash : DBus.Object
{
  public abstract void DisplayTrash (string display);
  public abstract void EmptyTrash (string display) throws DBus.Error;
  public abstract void MoveToTrash (string[] uris, string display);
  public abstract bool QueryTrash ();
  public signal void TrashChanged (bool full);
}

namespace DesktopAgnostic.VFS
{
  private enum TrashState
  {
    UNKNOWN = -1,
    EMPTY,
    FULL
  }
  public class TrashThunarVFS : Trash, GLib.Object
  {
    protected unowned ThunarVfs.Path trash;
    private Connection dbus;
    private Xfce.Trash xfce_trash;
    private uint _file_count;
    private Job job;

    construct
    {
      Monitor monitor;
      this.trash = ThunarVfs.Path.get_for_trash ();
      this.dbus = Bus.get (BusType.SESSION);
      this.xfce_trash =
        (Xfce.Trash)this.dbus.get_object ("org.xfce.Thunar",
                                          "/org/xfce/FileManager");
      this.xfce_trash.TrashChanged += this.on_trash_changed;
      this._file_count = 0;
      this.update_file_count (TrashState.UNKNOWN);
    }

    private void
    on_trash_changed (bool full)
    {
      this.update_file_count (full ? TrashState.FULL : TrashState.EMPTY);
    }

    private void
    update_file_count (TrashState state)
    {
      if (state == TrashState.EMPTY)
      {
        this._file_count = 0;
        this.file_count_changed ();
      }
      else
      {
        try
        {
          this.job = deep_count (this.trash, DeepCountFlags.NONE);
          this.job.status_ready += this.on_trash_count;
          this.job.finished += this.on_job_finished;
        }
        catch (GLib.Error e)
        {
          warning ("Could not retrieve contents of Trash: %s", e.message);
        }
      }
    }

    private void
    on_job_finished (Job job)
    {
      this.job = null;
    }

    private void
    on_trash_count (Job job,
                    uint64 total_size,
                    uint file_count,
                    uint dir_count,
                    uint unreadable_dir_count)
    {
      // For some reason, the root trash directory is also counted.
      this._file_count = file_count + (dir_count - 1) + unreadable_dir_count;
      this.file_count_changed ();
    }

    public uint
    file_count
    {
      get
      {
        return this._file_count;
      }
    }

    public void
    send_to_trash (File file) throws GLib.Error
    {
      string[] uris = new string[] { file.uri };
      this.xfce_trash.MoveToTrash (uris, "");
    }

    public void empty ()
    {
      try
      {
        this.xfce_trash.EmptyTrash ("");
      }
      catch (DBus.Error err)
      {
        critical ("VFS Trash Error (Thunar VFS): %s", err.message);
      }
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
