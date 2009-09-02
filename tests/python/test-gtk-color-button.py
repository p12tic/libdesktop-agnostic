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

import gtk

import desktopagnostic
from desktopagnostic.gtk import ColorButton


class TestColorButton(gtk.Window):
    def __init__(self):
        super(TestColorButton, self).__init__()
        self.connect('delete-event', gtk.main_quit)
        color = desktopagnostic.Color.from_string('green')
        color.props.alpha = 2**15 - 1
        button = ColorButton.with_color(color)
        button.connect('color-set', self.on_color_set)
        self.add(button)
        self.show_all()

    def on_color_set(self, button):
        print str(button.props.da_color)
        gtk.main_quit();

if __name__ == '__main__':
    tcb = TestColorButton()
    gtk.main()

# vim:ts=4:sts=4:sw=4:et:ai:cindent:
