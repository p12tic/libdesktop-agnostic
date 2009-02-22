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
        return typeof (File.ThunarVFSBackend);
      }
    }
    public Type file_monitor_type
    {
      get
      {
        return typeof (File.ThunarVFSMonitor);
      }
    }
    public Type trash_type
    {
      get
      {
        return typeof (Trash.ThunarVFSImplementation);
      }
    }
    public Type volume_type
    {
      get
      {
        return Type.INVALID;
      }
    }
    public void init ()
    {
      ThunarVfs.init ();
    }
    public SList<File.Backend>
    files_from_uri_list (string uri_list) throws GLib.Error
    {
      SList<File.Backend> files = new SList<File.Backend> ();
      weak List<ThunarVfs.Path> paths = ThunarVfs.PathList.from_string (uri_list);
      foreach (weak ThunarVfs.Path path in paths)
      {
        weak string uri = path.dup_uri ();
        File.Backend file = (File.Backend)Object.new (this.file_type,
                                                      "uri", uri);
        files.append (#file);
      }
      return files;
    }
    private Volume.Monitor vmonitor;
    public unowned Volume.Monitor
    volume_monitor_get_default ()
    {
      if (vmonitor == null)
      {
        vmonitor = new Volume.ThunarVFSMonitor ();
      }
      return vmonitor;
    }
    public void shutdown ()
    {
      ThunarVfs.shutdown ();
    }
  }
}
[ModuleInit]
public Type
register_plugin ()
{
  return typeof (DesktopAgnostic.VFS.ThunarVFSImplementation);
}

// vim: set et ts=2 sts=2 sw=2 ai :
