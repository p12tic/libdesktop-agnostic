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

import glib
import time
import desktopagnostic.config

class TestCase:
    def __init__(self):
        self.ml = glib.MainLoop()
        self.notify_counter = 0
        self.client = desktopagnostic.config.Client("../test-config.schema-ini")
        self.client.reset(False)

    def test_defaults(self):
        expected = True
        actual = self.client.get_bool("numeric", "boolean")
        v = self.client.get_value("numeric", "boolean")
        assert expected == actual, "Fail! Expected value: %s, actual: %s" % (str(expected), str(actual))
        assert actual == v

        expected = 3
        actual = self.client.get_int("numeric", "integer")
        v = self.client.get_value("numeric", "integer")
        assert expected == actual, "Fail! Expected value: %s, actual: %s" % (str(expected), str(actual))
        assert actual == v

        expected = round (3.14, 3)
        actual = self.client.get_float("numeric", "float")
        v = self.client.get_value("numeric", "float")
        actual = round(actual, 3)
        v = round(v, 3)
        assert expected == actual, "Fail! Expected value: %s, actual: %s" % (str(expected), str(actual))
        assert actual == v

        expected = "Foo bar"
        actual = self.client.get_string("misc", "string")
        v = self.client.get_value("misc", "string")
        assert expected == actual, "Fail! Expected value: %s, actual: %s" % (str(expected), str(actual))
        assert actual == v

        expected = [True, False]
        actual = self.client.get_list("list", "boolean")
        v = self.client.get_value("list", "boolean")
        assert expected == actual, "Fail! Expected value: %s, actual: %s" % (str(expected), str(actual))
        assert actual == v

        expected = [1,2,3]
        actual = self.client.get_list("list", "integer")
        v = self.client.get_value("list", "integer")
        assert expected == actual, "Fail! Expected value: %s, actual: %s" % (str(expected), str(actual))
        assert actual == v

        expected = [1.618, 2.718, 3.141]
        expected = map (lambda x: round (x, 3), expected)
        actual = self.client.get_list("list", "float")
        actual = map (lambda x: round (x, 3), actual)
        v = self.client.get_value("list", "float")
        v = map (lambda x: round (x, 3), v)
        assert expected == actual, "Fail! Expected value: %s, actual: %s" % (str(expected), str(actual))
        assert actual == v

        expected = ["foo", "bar"]
        actual = self.client.get_list("list", "string")
        v = self.client.get_value("list", "string")
        assert expected == actual, "Fail! Expected value: %s, actual: %s" % (str(expected), str(actual))
        assert actual == v

    def test_set(self):
        expected = False
        self.client.set_bool ("numeric", "boolean", expected)
        assert expected == self.client.get_value ("numeric", "boolean")
        assert expected == self.client.get_bool ("numeric", "boolean")

        expected = 10
        self.client.set_int ("numeric", "integer", expected)
        assert expected == self.client.get_value ("numeric", "integer")
        assert expected == self.client.get_int ("numeric", "integer")

        expected = round (2.718, 3)
        self.client.set_float ("numeric", "float", expected)
        assert expected == round (self.client.get_value ("numeric", "float"), 3)
        assert expected == round (self.client.get_float ("numeric", "float"), 3)

        expected = "Quux baz"
        self.client.set_string ("misc", "string", expected)
        assert expected == self.client.get_value ("misc", "string")
        assert expected == self.client.get_string ("misc", "string")

        expected = [False, True, False]
        self.client.set_list ("list", "boolean", expected)
        assert expected == self.client.get_value ("list", "boolean")
        assert expected == self.client.get_list ("list", "boolean")

        expected = [10, 20, 30]
        self.client.set_list ("list", "integer", expected)
        assert expected == self.client.get_value ("list", "integer")
        assert expected == self.client.get_list ("list", "integer")

        expected = [10.5, 20.6, 30.7]
        expected = map (lambda x: round (x, 3), expected)
        self.client.set_list ("list", "float", expected)
        assert expected == map (lambda x: round (x, 3), self.client.get_value ("list", "float"))
        assert expected == map (lambda x: round (x, 3), self.client.get_list ("list", "float"))

        expected = ["Quux", "Baz", "Foo"]
        self.client.set_list ("list", "string", expected)
        assert expected == self.client.get_value ("list", "string")
        assert expected == self.client.get_list ("list", "string")

    def string_changed(self, group, key, value):
        self.notify_counter = self.notify_counter + 1

    def string_changed2(self, group, key, value):
        if (value.find ("quux") != -1):
            self.notify_counter = self.notify_counter + 3

    def test_notify(self):
        ctx = self.ml.get_context()

        self.client.notify_add ("misc", "string", self.string_changed)
        self.client.notify_add ("misc", "string", self.string_changed2)

        self.client.set_string ("misc", "string", "Bar foo")
        # wait for the notification
        time.sleep(0.25)
        while ctx.pending(): ctx.iteration()
        assert self.notify_counter == 1, "Counter is: %d" % self.notify_counter

        self.client.set_string ("misc", "string", "Foo quux")
        # wait for the notification
        time.sleep(0.25)
        while ctx.pending(): ctx.iteration()
        assert self.notify_counter == 5, "Counter is: %d" % self.notify_counter

        self.client.notify_remove ("misc", "string", self.string_changed)
        self.client.set_string ("misc", "string", "Bar quux")
        # wait for the notification
        time.sleep(0.25)
        while ctx.pending(): ctx.iteration()
        assert self.notify_counter == 8, "Counter is: %d" % self.notify_counter

        self.client.notify_remove ("misc", "string", self.string_changed2)
        self.client.set_string ("misc", "string", "Baz foo")
        # wait for the notification (though it shouldn't come)
        time.sleep(0.25)
        while ctx.pending(): ctx.iteration()
        assert self.notify_counter == 8, "Counter is: %d" % self.notify_counter

if __name__ == "__main__":
    t = TestCase()
    t.test_defaults()
    t.test_set()
    t.test_notify()
