#!/usr/bin/env python
# Copyright(c) 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
#(at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software

import glib
import time
import desktopagnostic.config


class TestCase:

    def __init__(self):
        SCHEMA_FILE = '../test-config.schema-ini'
        self.ml = glib.MainLoop()
        self.notify_counter = 0
        self.client = desktopagnostic.config.Client(SCHEMA_FILE)
        self.client.reset(False)

    def check_values(self, expected, actual, value):
        ERROR_MSG = 'Fail! Expected value: %s, actual: %s'
        assert expected == actual, ERROR_MSG % (str(expected), str(actual))
        assert actual == value

    def test_defaults(self):
        group, key = ('numeric', 'boolean')
        self.check_values(True,
                          self.client.get_bool(group, key),
                          self.client.get_value(group, key))

        group, key = ('numeric', 'integer')
        self.check_values(3,
                          self.client.get_int(group, key),
                          self.client.get_value(group, key))

        group, key = ('numeric', 'float')
        self.check_values(round(3.14, 3),
                          round(self.client.get_float(group, key), 3),
                          round(self.client.get_value(group, key), 3))

        group, key = ('misc', 'string')
        self.check_values('Foo bar',
                          self.client.get_string(group, key),
                          self.client.get_value(group, key))

        group, key = ('list', 'boolean')
        self.check_values([True, False],
                          self.client.get_list(group, key),
                          self.client.get_value(group, key))

        group, key = ('list', 'integer')
        self.check_values([1, 2, 3],
                          self.client.get_list(group, key),
                          self.client.get_value(group, key))

        group, key = ('list', 'float')
        actual = [round(x, 3) for x in self.client.get_list(group, key)]
        values = [round(x, 3) for x in self.client.get_value(group, key)]
        self.check_values([round(x, 3) for x in [1.618, 2.718, 3.141]],
                          actual, values)

        group, key = ('list', 'string')
        self.check_values(['foo', 'bar'],
                          self.client.get_list(group, key),
                          self.client.get_value(group, key))

    def test_set(self):
        expected = False
        self.client.set_bool('numeric', 'boolean', expected)
        assert expected == self.client.get_value('numeric', 'boolean')
        assert expected == self.client.get_bool('numeric', 'boolean')

        expected = 10
        self.client.set_int('numeric', 'integer', expected)
        assert expected == self.client.get_value('numeric', 'integer')
        assert expected == self.client.get_int('numeric', 'integer')

        expected = round(2.718, 3)
        self.client.set_float('numeric', 'float', expected)
        assert expected == round(self.client.get_value('numeric', 'float'), 3)
        assert expected == round(self.client.get_float('numeric', 'float'), 3)

        expected = 'Quux baz'
        self.client.set_string('misc', 'string', expected)
        assert expected == self.client.get_value('misc', 'string')
        assert expected == self.client.get_string('misc', 'string')

        expected = [False, True, False]
        self.client.set_list('list', 'boolean', expected)
        assert expected == self.client.get_value('list', 'boolean')
        assert expected == self.client.get_list('list', 'boolean')

        expected = [10, 20, 30]
        self.client.set_list('list', 'integer', expected)
        assert expected == self.client.get_value('list', 'integer')
        assert expected == self.client.get_list('list', 'integer')

        expected = [round(x, 3) for x in [10.5, 20.6, 30.7]]
        self.client.set_list('list', 'float', expected)
        list1 = [round(x, 3) for x in self.client.get_value('list', 'float')]
        list2 = [round(x, 3) for x in self.client.get_list('list', 'float')]
        assert expected == list1
        assert expected == list2

        expected = ['Quux', 'Baz', 'Foo']
        self.client.set_list('list', 'string', expected)
        assert expected == self.client.get_value('list', 'string')
        assert expected == self.client.get_list('list', 'string')

    def string_changed(self, group, key, value):
        self.notify_counter += 1

    def string_changed2(self, group, key, value):
        if 'quux' in value:
            self.notify_counter += 3

    def check_notify(self, ctx, string, expected_counter):
        self.client.set_string('misc', 'string', string)
        # wait for the notification
        time.sleep(0.25)
        while ctx.pending():
            ctx.iteration()
        assert self.notify_counter == expected_counter

    def test_notify(self):
        ctx = self.ml.get_context()

        self.client.notify_add('misc', 'string', self.string_changed)
        self.client.notify_add('misc', 'string', self.string_changed2)

        self.check_notify(ctx, 'Bar foo', 1)

        self.check_notify(ctx, 'Foo quux', 5)

        self.client.notify_remove('misc', 'string', self.string_changed)
        self.check_notify(ctx, 'Bar quux', 8)

        self.client.notify_remove('misc', 'string', self.string_changed2)
        self.check_notify(ctx, 'Baz foo', 8)

if __name__ == '__main__':
    t = TestCase()
    t.test_defaults()
    t.test_set()
    t.test_notify()
