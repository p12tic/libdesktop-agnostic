/*
 * Desktop Agnostic Library: VFS Volume implementation (GNOME VFS).
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
  private struct VolumeResult
  {
    public bool succeeded;
    public string error;
    public string detailed_error;
  }
  public class VolumeGnomeVFS : Object, Volume
  {
    private GnomeVFS.Drive drive;
    public GnomeVFS.Drive implementation
    {
      construct
      {
        this.drive = value;
      }
    }
    public string name
    {
      get
      {
        return this.drive.get_display_name ();
      }
    }
    private File _uri;
    public File uri
    {
      get
      {
        if (this._uri == null)
        {
          string activation_uri = this.drive.get_activation_uri ();
          this._uri = file_new_for_uri (activation_uri);
        }
        return this._uri;
      }
    }
    public string? icon
    {
      owned get
      {
        return this.drive.get_icon ();
      }
    }
    public bool
    is_mounted ()
    {
      return this.drive.is_mounted ();
    }
    private VolumeResult? result;
    private Volume.Callback _mount_callback;
    private void
    on_drive_mounted (bool succeeded, string error, string detailed_error)
    {
      this.result = VolumeResult ();
      result.succeeded = succeeded;
      result.error = error;
      result.detailed_error = detailed_error;
      this._mount_callback ();
      this._mount_callback = null;
    }
    public void
    mount (Volume.Callback callback)
    {
      if (this._mount_callback == null)
      {
        this._mount_callback = callback;
        this.drive.mount ((GnomeVFS.VolumeOpCallback)this.on_drive_mounted);
      }
    }
    public bool
    mount_finish () throws VolumeError
    {
      bool result = this.result.succeeded;
      if (!result)
      {
        string msg = "%s (%s)".printf (this.result.error,
                                       this.result.detailed_error);
        this.result = null;
        throw new VolumeError.MOUNT (msg);
      }
      this.result = null;
      return result;
    }
    private Volume.Callback _unmount_callback;
    private void
    on_drive_unmounted (bool succeeded, string error, string detailed_error)
    {
      this.result = VolumeResult ();
      result.succeeded = succeeded;
      result.error = error;
      result.detailed_error = detailed_error;
      this._unmount_callback ();
      this._unmount_callback = null;
    }
    public void
    unmount (Volume.Callback callback)
    {
      if (this._unmount_callback == null)
      {
        this._unmount_callback = callback;
        this.drive.unmount ((GnomeVFS.VolumeOpCallback)this.on_drive_unmounted);
      }
    }
    public bool
    unmount_finish () throws VolumeError
    {
      bool result = this.result.succeeded;
      if (!result)
      {
        string msg = "%s (%s)".printf (this.result.error,
                                       this.result.detailed_error);
        this.result = null;
        throw new VolumeError.UNMOUNT (msg);
      }
      this.result = null;
      return result;
    }
    public bool
    can_eject ()
    {
      return true;
    }
    private Volume.Callback _eject_callback;
    private void
    on_drive_ejected (bool succeeded, string error, string detailed_error)
    {
      this.result = VolumeResult ();
      result.succeeded = succeeded;
      result.error = error;
      result.detailed_error = detailed_error;
      this._eject_callback ();
      this._eject_callback = null;
    }
    public void
    eject (Volume.Callback callback)
    {
      if (this._eject_callback == null)
      {
        this._eject_callback = callback;
        this.drive.eject ((GnomeVFS.VolumeOpCallback)this.on_drive_ejected);
      }
    }
    public bool
    eject_finish () throws VolumeError
    {
      bool result = this.result.succeeded;
      if (!result)
      {
        string msg = "%s (%s)".printf (this.result.error,
                                       this.result.detailed_error);
        this.result = null;
        throw new VolumeError.EJECT (msg);
      }
      this.result = null;
      return result;
    }
  }
  public class VolumeMonitorGnomeVFS : Object, VolumeMonitor
  {
    private GnomeVFS.VolumeMonitor monitor;
    private HashTable<GnomeVFS.Drive,VFS.Volume> _volumes;
    construct
    {
      this.monitor = GnomeVFS.get_volume_monitor ();
      this._volumes = new HashTable<GnomeVFS.Drive,VFS.Volume> (direct_hash,
                                                                direct_equal);
      unowned List<GnomeVFS.Drive> drives =
        this.monitor.get_connected_drives ();
      foreach (unowned GnomeVFS.Drive drive in drives)
      {
        VFS.Volume vol = this.create_volume (drive);
        this._volumes.insert (drive, vol);
      }
      this.monitor.drive_connected += this.on_drive_connected;
      this.monitor.drive_disconnected += this.on_drive_disconnected;
      this.monitor.volume_mounted += this.on_volume_mounted;
      this.monitor.volume_unmounted += this.on_volume_unmounted;
    }
    private VFS.Volume
    create_volume (GnomeVFS.Drive drive)
    {
        return (VFS.Volume)Object.new (typeof (VolumeGnomeVFS),
                                       "implementation", drive);
    }
    private VFS.Volume
    check_volume (GnomeVFS.Drive drive)
    {
      VFS.Volume? vol = this._volumes.lookup (drive);
      if (vol == null)
      {
        vol = this.create_volume (drive);
        this._volumes.insert (drive, vol);
      }
      return vol;
    }
    private void on_drive_connected (GnomeVFS.VolumeMonitor vmonitor,
                                    GnomeVFS.Drive drive)
    {
      this.check_volume (drive);
    }
    private void
    on_drive_disconnected (GnomeVFS.VolumeMonitor vmonitor,
                           GnomeVFS.Drive drive)
    {
      VFS.Volume? vol = this._volumes.lookup (drive);
      if (vol != null)
      {
        this._volumes.remove (drive);
      }
    }
    private VFS.Volume
    get_volume (GnomeVFS.Volume gvol)
    {
      return this.check_volume (gvol.get_drive ());
    }
    private void
    on_volume_mounted (GnomeVFS.VolumeMonitor vmonitor,
                       GnomeVFS.Volume gvol)
    {
      this.volume_mounted (this.get_volume (gvol));
    }
    private void
    on_volume_unmounted (GnomeVFS.VolumeMonitor vmonitor,
                         GnomeVFS.Volume gvol)
    {
      this.volume_unmounted (this.get_volume (gvol));
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
