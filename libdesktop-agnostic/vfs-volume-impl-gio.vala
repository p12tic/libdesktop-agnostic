/*
 * Desktop Agnostic Library: VFS Volume implementation (GIO).
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
  public class VolumeGIO : Object, Volume
  {
    private GLib.Volume vol;
    public GLib.Volume implementation
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
          GLib.Mount? mount = this.vol.get_mount ();
          if (mount != null)
          {
            GLib.File file = mount.get_root ();
            this._uri = file_new_for_uri (file.get_uri ());
          }
        }
        return this._uri;
      }
    }
    private string? _icon;
    public string? icon
    {
      owned get
      {
        if (this._icon == null)
        {
          GLib.Icon icon = this.vol.get_icon ();
          if (icon is GLib.ThemedIcon)
          {
            unowned string[] icon_names = (string[])(((GLib.ThemedIcon)icon).get_names ());
            if (icon_names.length > 0)
            {
              this._icon = icon_names[0];
            }
            else
            {
              // set fallback
              this._icon = "drive-harddisk";
            }
          }
          else if (icon is GLib.FileIcon)
          {
            string path = ((GLib.FileIcon)icon).get_file ().get_path ();
            this._icon = path;
          }
          else
          {
            // set fallback
            warning ("Unknown icon type: %s", icon.get_type ().name ());
            this._icon = "drive-harddisk";
          }
        }
        return this._icon;
      }
    }
    public bool
    is_mounted ()
    {
      return this.vol.get_mount () != null;
    }
    private Volume.Callback _mount_callback;
    private AsyncResult async_result;
    private void on_mount (Object? obj, AsyncResult res)
    {
      this.async_result = res;
      this._mount_callback ();
      this._mount_callback = null;
    }
    public void
    mount (Volume.Callback callback)
    {
      if (this._mount_callback == null)
      {
        this._mount_callback = callback;
        this.vol.mount (MountMountFlags.NONE, null, null, this.on_mount);
      }
    }
    public bool mount_finish () throws VolumeError
    {
      bool result = false;
      try
      {
        result = this.vol.mount_finish (this.async_result);
      }
      catch (GLib.Error err)
      {
        throw new VolumeError.MOUNT (err.message);
      }
      this.async_result = null;
      return result;
    }
    private Volume.Callback _unmount_callback;
    private void on_unmount (Object? obj, AsyncResult res)
    {
      this.async_result = res;
      this._unmount_callback ();
      this._unmount_callback = null;
    }
    public void
    unmount (Volume.Callback callback)
    {
      if (this._unmount_callback == null)
      {
        unowned Mount? mount;
        this._unmount_callback = callback;
        mount = this.vol.get_mount ();
        if (mount != null)
        {
          mount.unmount (MountUnmountFlags.NONE, null, this.on_unmount);
        }
      }
    }
    public bool unmount_finish () throws VolumeError
    {
      bool result = false;
      try
      {
        result = this.vol.get_mount ().unmount_finish (this.async_result);
      }
      catch (GLib.Error err)
      {
        throw new VolumeError.UNMOUNT (err.message);
      }
      this.async_result = null;
      return result;
    }
    public bool
    can_eject ()
    {
      return this.vol.can_eject ();
    }
    private Volume.Callback _eject_callback;
    private void
    on_eject (Object? obj, AsyncResult res)
    {
      this.async_result = res;
      this._eject_callback ();
      this._eject_callback = null;
    }
    public void
    eject (Volume.Callback callback)
    {
      if (this._eject_callback == null)
      {
        this._eject_callback = callback;
        this.vol.eject (MountUnmountFlags.NONE, null, this.on_eject);
      }
    }
    public bool eject_finish () throws VolumeError
    {
      bool result = false;
      try
      {
        result = this.vol.eject_finish (this.async_result);
      }
      catch (GLib.Error err)
      {
        throw new VolumeError.EJECT (err.message);
      }
      this.async_result = null;
      return result;
    }
  }
  public class VolumeMonitorGIO : Object, VolumeMonitor
  {
    private GLib.VolumeMonitor monitor;
    private HashTable<GLib.Volume,VFS.Volume> _volumes;
    construct
    {
      this.monitor = GLib.VolumeMonitor.get ();
      this._volumes = new HashTable<GLib.Volume,VFS.Volume> (direct_hash,
                                                             direct_equal);
      List<GLib.Volume> vols = this.monitor.get_volumes ();
      foreach (unowned GLib.Volume gvol in vols)
      {
        VFS.Volume vol = this.create_volume (gvol);
        this._volumes.insert (gvol, vol);
      }
      this.monitor.mount_added += this.on_mount_added;
      this.monitor.mount_removed += this.on_mount_removed;
      this.monitor.volume_added += this.on_volume_added;
      this.monitor.volume_removed += this.on_volume_removed;
    }
    private VFS.Volume
    create_volume (GLib.Volume vol)
    {
        return (VFS.Volume)Object.new (typeof (VolumeGIO),
                                       "implementation", vol);
    }
    private VFS.Volume
    check_volume (GLib.Volume gvol)
    {
      VFS.Volume? vol = this._volumes.lookup (gvol);
      if (vol == null)
      {
        vol = this.create_volume (gvol);
        this._volumes.insert (gvol, vol);
      }
      return vol;
    }
    private VFS.Volume?
    get_volume_from_mount (Mount mount)
    {
      GLib.Volume? gvol = mount.get_volume ();
      if (gvol == null)
      {
        return null;
      }
      else
      {
        return this.check_volume (gvol);
      }
    }
    private void
    on_mount_added (GLib.VolumeMonitor vmonitor, Mount mount)
    {
      VFS.Volume? volume = this.get_volume_from_mount (mount);
      if (volume != null)
      {
        this.volume_mounted (volume);
      }
    }
    private void
    on_mount_removed (GLib.VolumeMonitor vmonitor, Mount mount)
    {
      VFS.Volume? volume = this.get_volume_from_mount (mount);
      if (volume != null)
      {
        this.volume_unmounted (volume);
      }
    }
    private void
    on_volume_added (GLib.VolumeMonitor vmonitor, GLib.Volume gvol)
    {
      this.check_volume (gvol);
    }
    private void
    on_volume_removed (GLib.VolumeMonitor vmonitor, GLib.Volume gvol)
    {
      VFS.Volume? vol = this._volumes.lookup (gvol);
      if (vol != null)
      {
        this._volumes.remove (gvol);
        this.volume_unmounted (vol);
      }
    }
    public void* implementation
    {
      get
      {
        return (void*)this.monitor;
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
