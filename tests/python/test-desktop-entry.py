#!/usr/bin/env python

# Copyright (c) 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.

import sys
import gtk
from desktopagnostic import fdo
from desktopagnostic import vfs

def main(args):
    vfs.init()
    try:
        if len(args) > 1:
            for arg in args[1:]:
                desktop_file = vfs.File.for_path(arg)
                entry = fdo.DesktopEntry.for_file(desktop_file)
                print 'Entry: %s' % entry.props.name
                print 'Entry exec line: %s', entry.get_string('Exec')
                if entry.exists():
                    pid = entry.launch(0, None)
                    print 'PID: %d' % pid
                else:
                    print 'Entry does not exist!'
        else:
            entry = fdo.DesktopEntry.new()
            entry.props.name = 'hosts file'
            entry.props.entry_type = fdo.DESKTOP_ENTRY_TYPE_LINK
            entry.set_string('URL', 'file:///etc/hosts')
            desktop_file = vfs.File.for_path('/tmp/desktop-agnostic-test.desktop')
            entry.save(desktop_file)
    finally:
        vfs.shutdown()

if __name__ == '__main__':
    gtk.init_check()
    main(sys.argv)
