/*
 * Desktop Agnostic Library: VFS Volume interface.
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

using DesktopAgnostic.VFS;

namespace DesktopAgnostic.VFS.Volume
{
  public errordomain Error
  {
    MOUNT,
    UNMOUNT,
    EJECT
  }
  public interface Backend : Object
  {
    /**
     * The name of the volume.
     */
    public abstract string name { get; }
    /**
     * Usually, the mount point of the volume.
     */
    public abstract File.Backend uri { get; }
    /**
     * Either an icon name usable with gtk.IconTheme, or an absolute path to
     * an image (either of which are associated with the volume).
     */
    public abstract string? icon { owned get; }
    /**
     * Tells whether the volume is mounted.
     */
    public abstract bool is_mounted ();
    public abstract void mount (Volume.Callback callback);
    public abstract bool mount_finish () throws Volume.Error;
    public abstract void unmount (Volume.Callback callback);
    public abstract bool unmount_finish () throws Volume.Error;
    public abstract bool can_eject ();
    public abstract void eject (Volume.Callback callback);
    public abstract bool eject_finish () throws Volume.Error;
  }
  public delegate void Callback (Backend vol);
  public interface Monitor : Object
  {
    public abstract void* implementation { get; }
    public abstract List<Backend> volumes { owned get; }
    public abstract signal void volume_mounted (Backend volume);
    public abstract signal void volume_unmounted (Backend volume);
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
