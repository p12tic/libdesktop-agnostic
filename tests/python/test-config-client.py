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
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.

import glib
import time
import unittest
from desktopagnostic import config

'''
Map format: type name => (group, key, default, set value)
'''
type_key_map = {
    'bool': ('numeric', 'boolean', True, False),
    'int': ('numeric', 'integer', 3, 10),
    'float': ('numeric', 'float', 3.14, 2.718),
    'string': ('misc', 'string', 'Foo bar', 'Quux baz')
    }

'''
Map format: type name => (default, set value)
'''
list_value_map = {
    'bool': ([True, False], [False, True, False]),
    'int': ([1, 2, 3], [10, 20, 30]),
    'float': ([1.618, 2.718, 3.141], [10.5, 20.6, 30.7]),
    'string': (['foo', 'bar'], ['Quux', 'Baz', 'Foo'])
    }

def create_type_tests(type_name, group, key, default, set_val):
    list_default, list_set_val = list_value_map[type_name]
    def test_default(self):
        self.check_values(group, key, default, type_name)
    def test_default_list(self):
        self.check_values('list', key, list_default, 'list')
    def test_set(self):
        self.check_set_values(group, key, set_val, type_name, False)
    def test_set_list(self):
        self.check_set_values('list', key, list_set_val, 'list', False)
    def test_set_value(self):
        self.check_set_values(group, key, set_val, type_name, True)
    def test_set_list_value(self):
        self.check_set_values('list', key, list_set_val, 'list', True)
    return {
        'test_default_%s' % type_name: test_default,
        'test_default_list_%s' % type_name: test_default_list,
        'test_set_%s' % type_name: test_set,
        'test_set_list_%s' % type_name: test_set_list,
        'test_set_value_%s' % type_name: test_set_value,
        'test_set_list_value_%s' % type_name: test_set_list_value}


class TestConfigClient(unittest.TestCase):

    def setUp(self):
        self.ml = glib.MainLoop()
        self.notify_counter = 0
        self.client = config.Client('../test-config.schema-ini')
        self.client.reset(False)

    def check_values(self, group, key, expected, type_name):
        get_func = getattr(self.client, 'get_%s' % type_name)
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
        self.assertEqual(expected, actual,
                         ERROR_MSG % (str(expected), str(actual)))
        self.assertEqual(actual, actual_value)

    def check_set_values(self, group, key, expected, type_name, set_value):
        if set_value:
            set_func = self.client.set_value
        else:
            set_func = getattr(self.client, 'set_%s' % type_name)
        set_func(group, key, expected)
        self.check_values(group, key, expected, type_name)

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
        self.assertEqual(self.notify_counter, expected_counter)

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

# add the type-specific tests to the testcase
for type_name, data in type_key_map.iteritems():
    methods = create_type_tests(type_name, *data)
    for name, method in methods.iteritems():
        setattr(TestConfigClient, name, method)

if __name__ == '__main__':
    unittest.main()
