/*
 * VAPI for a configuration notification delegate structure.
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

namespace DesktopAgnostic.Config
{
  [CCode (cheader_filename = "config-notify-delegate.c", free_function = "desktop_agnostic_config_notify_delegate_free")]
  [Compact]
  class NotifyDelegate
  {
    public NotifyFunc callback;
    public NotifyDelegate (NotifyFunc callback);
    public void execute (string group, string key, GLib.Value value);
    public static int compare (void* a, void* b);
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
