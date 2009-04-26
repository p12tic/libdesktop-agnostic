/* 
 * Desktop Agnostic Library: VFS implementation (with GNOME VFS).
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
  public class GnomeVFSImplementation : Object, Implementation
  {
    public string name
    {
      get
      {
        return "GNOME VFS";
      }
    }
    public Type file_type
    {
      get
      {
        return typeof (File.GnomeVFSBackend);
      }
    }
    public Type file_monitor_type
    {
      get
      {
        return typeof (File.GnomeVFSMonitor);
      }
    }
    public Type trash_type
    {
      get
      {
        return typeof (Trash.GnomeVFSImplementation);
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
      GnomeVFS.init ();
    }
    public SList<File.Backend>
    files_from_uri_list (string uri_list) throws GLib.Error
    {
      SList<File.Backend> files = new SList<File.Backend> ();
      weak List<GnomeVFS.URI> uris = GnomeVFS.URI.list_parse (uri_list);
      foreach (weak GnomeVFS.URI uri in uris)
      {
        string uri_str = uri.to_string (GnomeVFS.URIHideOptions.NONE);
        File.Backend file = (File.Backend)Object.new (this.file_type,
                                                      "uri", uri_str);
        files.append ((owned)file);
      }
      return files;
    }
    private Volume.Monitor vmonitor;
    public unowned Volume.Monitor
    volume_monitor_get_default ()
    {
      if (vmonitor == null)
      {
        vmonitor = new Volume.GnomeVFSMonitor ();
      }
      return vmonitor;
    }
    public void shutdown ()
    {
      GnomeVFS.shutdown ();
    }
  }
}
[ModuleInit]
public Type
register_plugin ()
{
  return typeof (DesktopAgnostic.VFS.GnomeVFSImplementation);
}

// vim: set et ts=2 sts=2 sw=2 ai :
