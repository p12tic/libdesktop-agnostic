/*
 * Desktop Agnostic Library: Trash interface.
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

namespace DesktopAgnostic.VFS
{
  public interface Trash : Object
  {
    public abstract uint file_count { get; }
    public signal void file_count_changed ();
    public abstract void send_to_trash (File file) throws GLib.Error;
    public abstract void empty ();
  }

  private static Trash? trash = null;

  public unowned Trash
  trash_get_default () throws GLib.Error
  {
    if (trash == null)
    {
      unowned VFS.Implementation vfs = VFS.get_default ();
      trash = (Trash)Object.new (vfs.trash_type);
    }

    return trash;
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
