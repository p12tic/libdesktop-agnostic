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

using DesktopAgnostic.VFS;
using GnomeVFS;

namespace DesktopAgnostic.VFS.Trash
{
  class TrashVolume : Object
  {
    private uint _file_count;
    public uint file_count
    {
      get
      {
        return this._file_count;
      }
    }
    private weak Backend trash;
    private weak MonitorHandle monitor;
    private weak URI _uri;
    public URI uri
    {
      set
      {
        this._uri = value;
        this.reset_file_count ();
        if (this.monitor == null)
        {
          // add monitor
          monitor_add (out this.monitor,
                       this.uri.to_string (URIHideOptions.NONE),
                       MonitorType.DIRECTORY,
                       this.update_file_count);
        }
      }
      get
      {
        return this._uri;
      }
    }

    public TrashVolume (Backend trash, URI uri)
    {
      this._file_count = 0;
      this.trash = trash;
      this.uri = uri;
    }

    private void
    update_file_count (MonitorHandle    monitor,
                       string           monitor_uri,
                       string           info_uri,
                       MonitorEventType event_type)
    {
      if (event_type != MonitorEventType.CREATED &&
          event_type != MonitorEventType.DELETED)
      {
        return;
      }
      uint old_file_count = this._file_count;
      this.reset_file_count ();
      if (old_file_count != this._file_count)
      {
        this.trash.file_count_changed ();
      }
    }

    private void
    reset_file_count ()
    {
      message ("reset_file_count");
      weak DirectoryHandle handle;
      Result res;
      this._file_count = 0;
      // iterate through folder contents
      res = directory_open_from_uri (out handle, this.uri,
                                     FileInfoOptions.NAME_ONLY);
      if (res == Result.OK)
      {
        GnomeVFS.FileInfo file_info;
        file_info = new GnomeVFS.FileInfo ();
        while ((res = directory_read_next (handle, file_info)) == Result.OK)
        {
          if (file_info.name != "." && file_info.name != "..")
          {
            this._file_count++;
          }
        }
      }
    }

    private static bool
    visit_callback (string rel_path,
                    GnomeVFS.FileInfo info,
                    bool recursing_will_loop,
                    void** data,
                    bool recurse)
    {
      weak URI item;
      item = ((URI)(*data)).resolve_relative (rel_path);
      if (info.type == GnomeVFS.FileType.DIRECTORY)
      {
        TrashVolume.do_empty (item);
      }
      unlink_from_uri (item);
      return true;
    }

    private static void
    do_empty (URI dir)
    {
      Result res;
      res = directory_visit_uri (dir,
                                 FileInfoOptions.DEFAULT,
                                 DirectoryVisitOptions.LOOPCHECK,
                                 (DirectoryVisitFunc)TrashVolume.visit_callback,
                                 &dir);
      if (res != Result.OK)
      {
        warning ("Error occurred: %s", result_to_string (res));
      }
    }

    public void
    empty ()
    {
      if (this._uri == null)
      {
        warning ("URI is NULL!");
      }
      TrashVolume.do_empty (this._uri);
    }
  }

  public class GnomeVFSImplementation : Backend, Object
  {
    protected HashTable<GnomeVFS.Volume, TrashVolume> trash_dirs;

    construct
    {
      message ("GNOME VFS Impl.");
      this.trash_dirs = new HashTable<GnomeVFS.Volume, TrashVolume> (direct_hash, direct_equal);
      Idle.add (this.search_for_trash_dirs);
    }

    public uint
    file_count
    {
      get
      {
        uint total = 0;
        List<TrashVolume> values;
        values = this.trash_dirs.get_values ();
        foreach (weak TrashVolume tv in values)
        {
          total += tv.file_count;
        }
        return total;
      }
    }

    public void
    send_to_trash (File.Backend uri)
    {
      URI g_uri, trash_uri;
      Result res;

      g_uri = (URI)uri.implementation;
      res = find_directory (g_uri, FindDirectoryKind.TRASH,
                            out trash_uri,
                            true, false, 0777);
      if (res == Result.OK)
      {
        URI new_uri = trash_uri.append_file_name (g_uri.extract_short_path_name ());
        message ("Moving '%s' to '%s'...", g_uri.to_string (URIHideOptions.NONE), new_uri.to_string (URIHideOptions.NONE));
        res = move_uri (g_uri, new_uri, false);
        if (res != Result.OK)
        {
          warning ("Error occurred: %s", result_to_string (res));
        }
      }
      else
      {
        warning ("Error occurred: %s", result_to_string (res));
      }
    }

    public void
    empty ()
    {
      List<TrashVolume> values;
      values = this.trash_dirs.get_values ();
      foreach (weak TrashVolume tv in values)
      {
        tv.empty ();
      }
    }

    private bool
    search_for_trash_dirs ()
    {
      GnomeVFS.VolumeMonitor volume_monitor;
      weak List<GnomeVFS.Volume> volumes;
      volume_monitor = get_volume_monitor ();
      volumes = volume_monitor.get_mounted_volumes ();
      foreach (weak GnomeVFS.Volume volume in volumes)
      {
        this.check_volume_for_trash_dir (volume_monitor, volume);
      }
      volume_monitor.volume_mounted += this.check_volume_for_trash_dir;
      volume_monitor.volume_unmounted += this.remove_volume;
      this.file_count_changed ();
      return false;
    }

    private void
    check_volume_for_trash_dir (GnomeVFS.VolumeMonitor vm, GnomeVFS.Volume vol)
    {
      if (vol.handles_trash ())
      {
        Result res;
        URI uri;
        URI trash_uri;
        uri = new URI (vol.get_activation_uri ());
        res = find_directory (uri, FindDirectoryKind.TRASH,
                              out trash_uri,
                              false, true, 0777);
        if (res == Result.OK)
        {
          TrashVolume tv;
          tv = new TrashVolume (this, trash_uri);
          this.trash_dirs.insert (vol, (owned)tv);
          message ("Volume added");
        }
      }
    }

    private void
    remove_volume (GnomeVFS.VolumeMonitor vm, GnomeVFS.Volume vol)
    {
      if (this.trash_dirs.lookup (vol) != null)
      {
        this.trash_dirs.remove (vol);
      }
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
