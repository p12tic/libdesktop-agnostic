#!/usr/bin/env python
#
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
from desktopagnostic import config


class TestCase:

    def __init__(self):
        self.ml = glib.MainLoop()
        self.notify_counter = 0
        self.client = config.Client('../test-config.schema-ini')
        self.client.reset(False)

    def check_values(self, group, key, expected, get_func):
        actual = get_func(group, key)
        actual_value = self.client.get_value(group, key)
        if isinstance(expected, float):
            expected = round(expected, 3)
            actual = round(actual, 3)
            actual_value = round(actual_value, 3)
        elif isinstance(expected, list) and isinstance(expected[0], float):
            expected = [round(x, 3) for x in expected]
            actual = [round(x, 3) for x in actual]
            actual_value = [round(x, 3) for x in actual_value]
        ERROR_MSG = 'Fail! Expected value: %s, actual: %s'
        assert expected == actual, ERROR_MSG % (str(expected), str(actual))
        assert actual == actual_value

    def check_values_list(self, group, key, expected):
        self.check_values(group, key, expected, self.client.get_list)

    def test_defaults(self):
        self.check_values('numeric', 'boolean', True, self.client.get_bool)
        self.check_values('numeric', 'integer', 3, self.client.get_int)
        self.check_values('numeric', 'float', 3.14, self.client.get_float)
        self.check_values('misc', 'string', 'Foo bar', self.client.get_string)
        self.check_values_list('list', 'boolean', [True, False])
        self.check_values_list('list', 'integer', [1, 2, 3])
        self.check_values_list('list', 'float', [1.618, 2.718, 3.141])
        self.check_values_list('list', 'string', ['foo', 'bar'])

    def check_set_values(self, group, key, expected, type_name, set_value):
        get_func = getattr(self.client, 'get_%s' % type_name)
        if set_value:
            set_func = self.client.set_value
        else:
            set_func = getattr(self.client, 'set_%s' % type_name)
        set_func(group, key, expected)
        self.check_values(group, key, expected, get_func)

    def check_set_all_types(self, set_value):
        self.check_set_values('numeric', 'boolean', False, 'bool', set_value)
        self.check_set_values('numeric', 'integer', 10, 'int', set_value)
        self.check_set_values('numeric', 'float', 2.718, 'float', set_value)
        self.check_set_values('misc', 'string', 'Quux baz', 'string', set_value)
        expected_lists = [
            ([False, True, False], 'boolean'),
            ([10, 20, 30], 'integer'),
            ([10.5, 20.6, 30.7], 'float'),
            (['Quux', 'Baz', 'Foo'], 'string')]
        for expected, key in expected_lists:
            self.check_set_values('list', key, expected, 'list', set_value)

    def test_set(self):
        self.check_set_all_types(False)
        self.client.reset(False)
        self.test_defaults()
        self.check_set_all_types(True)

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
