/*
 * Desktop Agnostic Library: File monitor interface (similar to GFileMonitor).
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
  /**
   * The file monitor events that will be propagated to the signal handlers.
   */
  public enum MonitorEvent
  {
    UNKNOWN = 0,
    CHANGED,
    CREATED,
    DELETED,
    ATTRIBUTE_CHANGED
  }
  /**
   * The base class for file/directory monitoring.
   */
  public interface Monitor : Object
  {
    /**
     * Emits a file monitor event for the file backend associated with
     * the monitor.
     * @param other if the associated URI is a directory, the child file that
     * triggered the event. Otherwise, it should be NULL.
     * @param event the event type to emit.
     */
    public abstract void emit (Backend? other, MonitorEvent event);
    /**
     * Prevent the monitor from monitoring any events from the URI associated
     * with it.
     * @return whether the monitor was successfully cancelled.
     */
    public abstract bool cancel ();
    /**
     * Whether the monitor has been cancelled via cancel().
     */
    public abstract bool cancelled { get; }
    /**
     * The signal emitted when something changes
     * @param file the file backend associated with the monitor.
     * @param other if the URI associated with the monitor is a directory, the
     * child file that triggered the event. Otherwise, it should be NULL.
     * @param event the event type to send
     */
    public signal void changed (Backend file, Backend? other, MonitorEvent event);
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
