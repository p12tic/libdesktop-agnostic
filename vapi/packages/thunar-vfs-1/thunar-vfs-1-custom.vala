/* thunar-vfs-1-custom.vala
 *
 * Copyright (C) 2008  Mark Lee
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 *      Mark Lee <vala@lazymalevolence.com>
 */

namespace ThunarVfs {
	public class Job {
		public virtual signal bool infos_ready (GLib.List<ThunarVfs.Info> info_list);
		public virtual signal void status_ready (uint64 total_size, uint file_count, uint directory_count, uint unreadable_directory_count);
	}
	[Compact]
	public class Path {
		public void unref ();
	}
}

// vim: set noet :

