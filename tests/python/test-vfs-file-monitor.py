#!/usr/bin/env python
#
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
import os.path
import gobject
from desktopagnostic import vfs


class TestFileMonitor:

    def __init__(self, path):
        self.vfile = vfs.File.for_path(path)
        self.monitor = self.vfile.monitor()
        self.monitor.connect('changed', self.on_change)
        if self.vfile.props.file_type == vfs.FILE_TYPE_DIRECTORY:
            gobject.timeout_add_seconds(2, self.do_emit)

    def on_change(self, monitor, vfile, other, event):
        print '%s: %s' % (event.value_nick, vfile.props.uri)
        if other is not None:
            print ' * other: %s' % other.props.uri

    def do_emit(self):
        path = os.path.join(self.vfile.props.path, 'test-vfs-file.txt')
        other = vfs.File.for_path(path)
        self.monitor.changed(other, vfs.FILE_MONITOR_EVENT_CREATED)


def main(args):
    if len(args) < 2:
        sys.stderr.write('Usage: %s [FILE | DIRECTORY FILE] \n' % args[0])
        return 1
    vfs.init()
    try:
        ml = gobject.MainLoop()
        test = TestFileMonitor(args[1])
        ml.run()
        test.monitor.cancel()
        assert test.monitor.props.cancelled
    finally:
        vfs.shutdown()
    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv))
