/*
 * Desktop Agnostic Library: VFS implementation (with Thunar VFS).
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

namespace DesktopAgnostic.VFS
{
  public class ThunarVFSImplementation : Object, Implementation
  {
    public string name
    {
      get
      {
        return "Thunar VFS";
      }
    }
    public Type file_type
    {
      get
      {
        return typeof (FileThunarVFS);
      }
    }
    public Type file_monitor_type
    {
      get
      {
        return typeof (FileMonitorThunarVFS);
      }
    }
    public Type trash_type
    {
      get
      {
        return typeof (TrashThunarVFS);
      }
    }
    public Type volume_type
    {
      get
      {
        return typeof (VolumeThunarVFS);
      }
    }
    public void init ()
    {
      ThunarVfs.init ();
    }
    public SList<File>
    files_from_uri_list (string uri_list) throws GLib.Error
    {
      SList<File> files = new SList<File> ();
      unowned List<ThunarVfs.Path> paths = ThunarVfs.PathList.from_string (uri_list);
      foreach (unowned ThunarVfs.Path path in paths)
      {
        unowned string uri = path.dup_uri ();
        File file = file_new_for_uri (uri);
        files.append ((owned)file);
      }
      return files;
    }
    private VolumeMonitor vmonitor;
    public unowned VolumeMonitor
    volume_monitor_get_default ()
    {
      if (vmonitor == null)
      {
        vmonitor = new VolumeMonitorThunarVFS ();
      }
      return vmonitor;
    }
    public void shutdown ()
    {
      ThunarVfs.shutdown ();
    }
  }
}
public Type
register_plugin ()
{
  return typeof (DesktopAgnostic.VFS.ThunarVFSImplementation);
}

// vim: set et ts=2 sts=2 sw=2 ai :
