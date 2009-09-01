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
import tempfile
from desktopagnostic import vfs
import gtk

CONTENT = 'Desktop Agnostic Library'

def main():
    gtk.init_check()
    vfs.init()
    test_launch = 'launch' in sys.argv
    try:
        path = tempfile.gettempdir()
        tmp = vfs.File.for_path(path)
        assert tmp.exists()
        assert tmp.props.file_type == vfs.FILE_TYPE_DIRECTORY
        assert (tmp.props.access_flags & vfs.ACCESS_FLAGS_READ) != 0
        assert tmp.is_readable()
        assert (tmp.props.access_flags & vfs.ACCESS_FLAGS_WRITE) != 0
        assert tmp.is_writable()
        print 'URI: %s' % tmp.props.uri
        print 'Path: %s' % tmp.props.path
        file_path = os.path.join(path, '%s-lda-test' % tempfile.gettempprefix())
        tmp_file = vfs.File.for_path(file_path);
        tmp_file.replace_contents(CONTENT)
        assert tmp_file.load_contents() == CONTENT
        if test_launch:
          assert tmp_file.launch()
        file_copy_path = '%s-copy' % file_path
        file_copy = vfs.File.for_path (file_copy_path)
        assert tmp_file.copy (file_copy, True)
        assert CONTENT == file_copy.load_contents()
        if not test_launch:
          assert file_copy.remove()
          assert not file_copy.exists()
          assert tmp_file.remove()
          assert not tmp_file.exists()
    finally:
        vfs.shutdown()

if __name__ == '__main__':
    main()
