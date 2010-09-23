/*
 * Desktop Agnostic Library: VFS Volume implementation (Thunar VFS).
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

namespace DesktopAgnostic.VFS
{
  public class VolumeThunarVFS : Object, Volume
  {
    private ThunarVfs.Volume vol;
    public ThunarVfs.Volume implementation
    {
      construct
      {
        this.vol = value;
      }
    }
    public string name
    {
      get
      {
        return this.vol.get_name ();
      }
    }
    private File _uri;
    public File uri
    {
      get
      {
        if (this._uri == null)
        {
          ThunarVfs.Path path = this.vol.get_mount_point ();
          this._uri = file_new_for_uri (path.dup_uri ());
        }
        return this._uri;
      }
    }
    public string? icon
    {
      owned get
      {
        return this.vol.lookup_icon_name (Gtk.IconTheme.get_default ());
      }
    }
    public VolumeThunarVFS.for_implementation (ThunarVfs.Volume impl)
    {
      GLib.Object (implementation: impl);
    }
    public bool
    is_mounted ()
    {
      return this.vol.is_mounted ();
    }
    private Volume.Callback _mount_callback;
    public bool
    do_mount ()
    {
      this._mount_callback ();
      this._mount_callback = null;
      return false;
    }
    public void
    mount (Volume.Callback callback)
    {
      if (this._mount_callback == null)
      {
        this._mount_callback = callback;
        Idle.add (this.do_mount);
      }
    }
    public bool
    mount_finish () throws VolumeError
    {
      bool result = false;
      try
      {
        result = this.vol.mount (null);
      }
      catch (Error err)
      {
        throw new VolumeError.MOUNT (err.message);
      }
      return result;
    }
    private Volume.Callback _unmount_callback;
    public bool
    do_unmount ()
    {
      this._unmount_callback ();
      this._unmount_callback = null;
      return false;
    }
    public void
    unmount (Volume.Callback callback)
    {
      if (this._unmount_callback == null)
      {
        this._unmount_callback = callback;
        Idle.add (this.do_unmount);
      }
    }
    public bool
    unmount_finish () throws VolumeError
    {
      bool result = false;
      try
      {
        result = this.vol.unmount (null);
      }
      catch (Error err)
      {
        throw new VolumeError.UNMOUNT (err.message);
      }
      return result;
    }
    public bool
    can_eject ()
    {
      return this.vol.is_ejectable ();
    }
    private Volume.Callback _eject_callback;
    public bool
    do_eject ()
    {
      this._eject_callback ();
      this._eject_callback = null;
      return false;
    }
    public void
    eject (Volume.Callback callback)
    {
      if (this._eject_callback == null)
      {
        this._eject_callback = callback;
        Idle.add (this.do_eject);
      }
    }
    public bool
    eject_finish () throws VolumeError
    {
      bool result = false;
      try
      {
        result = this.vol.eject (null);
      }
      catch (Error err)
      {
        throw new VolumeError.EJECT (err.message);
      }
      return result;
    }
  }
  public class VolumeMonitorThunarVFS : Object, VolumeMonitor
  {
    private ThunarVfs.VolumeManager manager;
    private HashTable<ThunarVfs.Volume,VFS.Volume> _volumes;
    construct
    {
      this.manager = ThunarVfs.VolumeManager.get_default ();
      this._volumes = new HashTable<ThunarVfs.Volume,VFS.Volume> (direct_hash,
                                                                  direct_equal);
      unowned List<ThunarVfs.Volume> vols = this.manager.get_volumes ();
      foreach (unowned ThunarVfs.Volume tvol in vols)
      {
        this._volumes.insert (tvol, this.create_volume (tvol));
      }
      this.manager.volume_mounted += this.on_mount_added;
      this.manager.volume_unmounted += this.on_mount_removed;
      this.manager.volumes_added += this.on_volumes_added;
      this.manager.volumes_removed += this.on_volumes_removed;
    }
    private VFS.Volume
    create_volume (ThunarVfs.Volume vol)
    {
      return new VolumeThunarVFS.for_implementation (vol);
    }
    private VFS.Volume
    check_volume (ThunarVfs.Volume tvol)
    {
      VFS.Volume? vol = this._volumes.lookup (tvol);
      if (vol == null)
      {
        vol = this.create_volume (tvol);
        this._volumes.insert (tvol, vol);
      }
      return vol;
    }
    private void
    on_mount_added (ThunarVfs.VolumeManager manager, ThunarVfs.Volume vol)
    {
      this.volume_mounted (this.check_volume (vol));
    }
    private void
    on_mount_removed (ThunarVfs.VolumeManager manager, ThunarVfs.Volume vol)
    {
      this.volume_unmounted (this.check_volume (vol));
    }
    private void
    on_volumes_added (ThunarVfs.VolumeManager manager, void* ptr)
    {
      unowned List<ThunarVfs.Volume> vols = (List<ThunarVfs.Volume>)ptr;
      foreach (unowned ThunarVfs.Volume tvol in vols)
      {
        this.check_volume (tvol);
      }
    }
    private void
    on_volumes_removed (ThunarVfs.VolumeManager manager, void* ptr)
    {
      unowned List<ThunarVfs.Volume> vols = (List<ThunarVfs.Volume>)ptr;
      foreach (unowned ThunarVfs.Volume tvol in vols)
      {
        VFS.Volume? vol = this._volumes.lookup (tvol);
        if (vol != null)
        {
          this._volumes.remove (tvol);
        }
      }
    }
    public void* implementation
    {
      get
      {
        return (void*)this.manager;
      }
    }
    public List<VFS.Volume> volumes
    {
      owned get
      {
        return this._volumes.get_values ();
      }
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
