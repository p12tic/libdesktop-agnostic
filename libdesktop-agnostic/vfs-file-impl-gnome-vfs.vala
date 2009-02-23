/* 
 * Desktop Agnostic Library: File implementation (with GNOME VFS).
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

namespace DesktopAgnostic.VFS.File
{
  public class GnomeVFSBackend : Backend
  {
    private GnomeVFS.URI _uri;
    public override void* implementation
    {
      get
      {
        return (void*)this._uri;
      }
    }
    private string _uri_str;
    protected override string impl_uri
    {
      get
      {
        return this._uri_str;
      }
    }
    protected override string? impl_path
    {
      owned get
      {
        return this._uri.get_path ();
      }
    }
    public override bool exists
    {
      get
      {
        return this._uri.exists ();
      }
    }
    public override FileType file_type
    {
      get
      {
        FileType ft;
        if (this.exists)
        {
          GnomeVFS.FileInfo info = new GnomeVFS.FileInfo ();
          GnomeVFS.get_file_info_uri (this._uri, info,
                                      GnomeVFS.FileInfoOptions.DEFAULT);
          switch (info.type)
          {
            case GnomeVFS.FileType.REGULAR:
              ft = FileType.REGULAR;
              break;
            case GnomeVFS.FileType.DIRECTORY:
              ft = FileType.DIRECTORY;
              break;
            case GnomeVFS.FileType.SYMBOLIC_LINK:
              ft = FileType.SYMBOLIC_LINK;
              break;
            case GnomeVFS.FileType.FIFO:
            case GnomeVFS.FileType.SOCKET:
            case GnomeVFS.FileType.CHARACTER_DEVICE:
            case GnomeVFS.FileType.BLOCK_DEVICE:
              ft = FileType.SPECIAL;
              break;
            case GnomeVFS.FileType.UNKNOWN:
            default:
              ft = FileType.UNKNOWN;
              break;
          }
        }
        else
        {
          ft = FileType.UNKNOWN;
        }
        return ft;
      }
    }
    protected override void init (string uri)
    {
      this._uri_str = uri;
      this._uri = new GnomeVFS.URI (uri);
    }
    public override Monitor monitor ()
    {
      return new GnomeVFSMonitor (this);
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
