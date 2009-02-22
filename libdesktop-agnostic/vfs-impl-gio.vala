/* 
 * Desktop Agnostic Library: VFS implementation (with GIO).
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
  public class GIOImplementation : Object, Implementation
  {
    public string name
    {
      get
      {
        return "GIO";
      }
    }
    public Type file_type
    {
      get
      {
        return typeof (File.GIOBackend);
      }
    }
    public Type file_monitor_type
    {
      get
      {
        return typeof (File.GIOMonitor);
      }
    }
    public Type trash_type
    {
      get
      {
        return typeof (Trash.GIOImplementation);
      }
    }
    public Type volume_type
    {
      get
      {
        return typeof (Volume.GIOBackend);
      }
    }
    public void init ()
    {
    }
    public SList<File.Backend>
    files_from_uri_list (string uri_list) throws GLib.Error
    {
      SList<File.Backend> files = new SList<File.Backend> ();
      string[] uris = Uri.list_extract_uris (uri_list);
      foreach (weak string uri in uris)
      {
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
        vmonitor = new Volume.GIOMonitor ();
      }
      return vmonitor;
    }
    public void shutdown ()
    {
    }
  }
}
[ModuleInit]
public Type
register_plugin ()
{
  return typeof (DesktopAgnostic.VFS.GIOImplementation);
}

// vim: set et ts=2 sts=2 sw=2 ai :
