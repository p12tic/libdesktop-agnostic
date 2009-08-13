/*
 * Desktop Agnostic Library: Test for the config backend implementations.
 *
 * Copyright (C) 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author : Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 */

using DesktopAgnostic;

errordomain AssertionError
{
  NOT_EQUAL,
  INVALID_TYPE,
  NOT_REACHED
}

class TestCase
{
  Config.Backend cfg;
  uint notify_counter;
  MainLoop ml;

  public TestCase ()
  {
    Config.Schema schema = new Config.Schema ("test-config.schema-ini");
    this.cfg = Config.new ((owned)schema);
    this.notify_counter = 0;
    this.ml = new MainLoop (null, false);
  }

  void
  on_string_changed (string group, string key, Value value)
  {
    this.notify_counter++;
  }

  void
  on_string_changed2 (string group, string key, Value value)
  {
    if (((string)value).contains ("quux"))
    {
      this.notify_counter += 3;
    }
  }

  bool
  array_equals (ValueArray expected, ValueArray actual) throws AssertionError
  {
    bool equal = true;

    if (expected.n_values == actual.n_values)
    {
      for (uint i = 0; i < actual.n_values; i++)
      {
        assert_equals (expected.get_nth (i), actual.get_nth (i));
      }
    }
    else
    {
      equal = false;
    }

    return equal;
  }

  void
  assert_equals (Value expected, Value actual) throws AssertionError
  {
    bool equal = true;
    if (actual.holds (typeof (bool)))
    {
      equal = (expected.get_boolean () == actual.get_boolean ());
    }
    else if (actual.holds (typeof (int)))
    {
      equal = (expected.get_int () == actual.get_int ());
    }
    else if (actual.holds (typeof (float)))
    {
      equal = (expected.get_float () == actual.get_float ());
    }
    else if (actual.holds (typeof (string)))
    {
      equal = (expected.get_string () == actual.get_string ());
    }
    else if (actual.holds (typeof (ValueArray)))
    {
      equal = array_equals ((ValueArray)expected, (ValueArray)actual);
    }
    else
    {
      throw new AssertionError.INVALID_TYPE ("Invalid value type (%s).",
                                             actual.type ().name ());
    }
    if (!equal)
    {
      throw new AssertionError.NOT_EQUAL ("%s != %s",
                                          expected.strdup_contents (),
                                          actual.strdup_contents ());
    }
  }

  void
  test_defaults () throws AssertionError, Error
  {
    Value expected, item_1, item_2, item_3;
    ValueArray expected_array;

    cfg.reset ();

    message ("====  Defaults tests  ====");

    expected = true;
    assert_equals (expected, cfg.get_value ("numeric", "boolean"));
    assert ((bool)expected == cfg.get_bool ("numeric", "boolean"));
    message (" Boolean:              OK");

    expected = 3;
    assert_equals (expected, cfg.get_value ("numeric", "integer"));
    assert ((int)expected == cfg.get_int ("numeric", "integer"));
    message (" Integer:              OK");

    expected = 3.14f;
    assert_equals (expected, cfg.get_value ("numeric", "float"));
    assert ((float)expected == cfg.get_float ("numeric", "float"));
    message (" Float:                OK");

    expected = "Foo bar";
    assert_equals (expected, cfg.get_value ("misc", "string"));
    assert ((string)expected == cfg.get_string ("misc", "string"));
    message (" String:               OK");

    expected_array = new ValueArray (2);
    item_1 = true;
    item_2 = false;
    expected_array.append (item_1);
    expected_array.append (item_2);
    expected = expected_array;
    assert_equals (expected, cfg.get_value ("list", "boolean"));
    assert (array_equals ((ValueArray)expected,
                          cfg.get_list ("list", "boolean")));
    message (" List of booleans:     OK");

    expected_array = new ValueArray (3);
    item_1 = 1;
    item_2 = 2;
    item_3 = 3;
    expected_array.append (item_1);
    expected_array.append (item_2);
    expected_array.append (item_3);
    expected = expected_array;
    assert_equals (expected, cfg.get_value ("list", "integer"));
    assert (array_equals ((ValueArray)expected,
                          cfg.get_list ("list", "integer")));
    message (" List of integers:     OK");

    expected_array = new ValueArray (3);
    item_1 = 1.618f;
    item_2 = 2.718f;
    item_3 = 3.141f;
    expected_array.append (item_1);
    expected_array.append (item_2);
    expected_array.append (item_3);
    expected = expected_array;
    assert_equals (expected, cfg.get_value ("list", "float"));
    assert (array_equals ((ValueArray)expected,
                          cfg.get_list ("list", "float")));
    message (" List of floats:       OK");

    expected_array = new ValueArray (2);
    item_1 = "foo";
    item_2 = "bar";
    expected_array.append (item_1);
    expected_array.append (item_2);
    expected = expected_array;
    assert_equals (expected, cfg.get_value ("list", "string"));
    assert (array_equals ((ValueArray)expected,
                          cfg.get_list ("list", "string")));
    message (" List of strings:      OK");
  }

  void
  test_set () throws AssertionError, Error
  {
    Value expected, item_1, item_2, item_3;
    ValueArray expected_array;

    message ("==== Set & Get tests  ====");

    expected = false;
    cfg.set_bool ("numeric", "boolean", (bool)expected);
    assert_equals (expected, cfg.get_value ("numeric", "boolean"));
    assert ((bool)expected == cfg.get_bool ("numeric", "boolean"));
    message (" Boolean:              OK");

    expected = 10;
    cfg.set_int ("numeric", "integer", (int)expected);
    assert_equals (expected, cfg.get_value ("numeric", "integer"));
    assert ((int)expected == cfg.get_int ("numeric", "integer"));
    message (" Integer:              OK");

    expected = 2.718f;
    cfg.set_float ("numeric", "float", (float)expected);
    assert_equals (expected, cfg.get_value ("numeric", "float"));
    assert ((float)expected == cfg.get_float ("numeric", "float"));
    message (" Float:                OK");

    expected = "Quux baz";
    cfg.set_string ("misc", "string", (string)expected);
    assert_equals (expected, cfg.get_value ("misc", "string"));
    assert ((string)expected == cfg.get_string ("misc", "string"));
    message (" String:               OK");

    expected_array = new ValueArray (3);
    item_1 = false;
    item_2 = true;
    item_3 = false;
    expected_array.append (item_1);
    expected_array.append (item_2);
    expected_array.append (item_3);
    expected = expected_array;
    cfg.set_list ("list", "boolean", (ValueArray)expected);
    assert_equals (expected, cfg.get_value ("list", "boolean"));
    assert (array_equals ((ValueArray)expected,
                          cfg.get_list ("list", "boolean")));
    message (" List of booleans:     OK");

    expected_array = new ValueArray (3);
    item_1 = 10;
    item_2 = 20;
    item_3 = 30;
    expected_array.append (item_1);
    expected_array.append (item_2);
    expected_array.append (item_3);
    expected = expected_array;
    cfg.set_list ("list", "integer", (ValueArray)expected);
    assert_equals (expected, cfg.get_value ("list", "integer"));
    assert (array_equals ((ValueArray)expected,
                          cfg.get_list ("list", "integer")));
    message (" List of integers:     OK");

    expected_array = new ValueArray (3);
    item_1 = 10.5f;
    item_2 = 20.6f;
    item_3 = 30.7f;
    expected_array.append (item_1);
    expected_array.append (item_2);
    expected_array.append (item_3);
    expected = expected_array;
    cfg.set_list ("list", "float", (ValueArray)expected);
    assert_equals (expected, cfg.get_value ("list", "float"));
    assert (array_equals ((ValueArray)expected,
                          cfg.get_list ("list", "float")));
    message (" List of floats:       OK");

    expected_array = new ValueArray (3);
    item_1 = "Quux";
    item_2 = "Baz";
    item_3 = "Foo";
    expected_array.append (item_1);
    expected_array.append (item_2);
    expected_array.append (item_3);
    expected = expected_array;
    cfg.set_list ("list", "string", (ValueArray)expected);
    assert_equals (expected, cfg.get_value ("list", "string"));
    assert (array_equals ((ValueArray)expected,
                          cfg.get_list ("list", "string")));
    message (" List of strings:      OK");
  }

  void
  update_notify_value (MainContext ctx, string value,
                       uint counter_expected) throws AssertionError, Error
  {
    cfg.set_string ("misc", "string", value);
    Thread.usleep (250000);
    while (ctx.pending ())
    {
      ctx.iteration (false);
    }
    assert (this.notify_counter == counter_expected);
  }

  void
  test_notify () throws AssertionError, Error
  {
    message ("====   Notify tests   ====");
    unowned MainContext ctx = this.ml.get_context ();

    cfg.notify_add ("misc", "string", this.on_string_changed);
    cfg.notify_add ("misc", "string", this.on_string_changed2);

    this.update_notify_value (ctx, "Bar foo", 1);
    message (" Notify test 1:        OK");

    this.update_notify_value (ctx, "Foo quux", 5);
    message (" Notify test 2:        OK");

    cfg.notify_remove ("misc", "string", this.on_string_changed);
    this.update_notify_value (ctx, "Bar quux", 8);
    message (" Notify test 3:        OK");

    cfg.notify_remove ("misc", "string", this.on_string_changed2);
    this.update_notify_value (ctx, "Baz foo", 8);
    message (" Notify test 4:        OK");
  }

  private static delegate void GetCfgFunc (Config.Backend cfg, string group, string key) throws Error;

  void
  test_invalid_func (GetCfgFunc func) throws AssertionError, Error
  {
    try
    {
      func (cfg, "foo", "bar");
      throw new AssertionError.NOT_REACHED ("Key should have been nonexistent.");
    }
    catch (Error err)
    {
      if (!(err is Config.Error.KEY_NOT_FOUND))
      {
        throw err;
      }
    }
  }

  void
  test_invalid () throws AssertionError, Error
  {
    message ("==== Invalid key test ====");

    this.test_invalid_func ((GetCfgFunc)cfg.get_bool);
    message (" Boolean:              OK");

    this.test_invalid_func ((GetCfgFunc)cfg.get_float);
    message (" Float:                OK");

    this.test_invalid_func ((GetCfgFunc)cfg.get_int);
    message (" Integer:              OK");

    this.test_invalid_func ((GetCfgFunc)cfg.get_string);
    message (" String:               OK");

    this.test_invalid_func ((GetCfgFunc)cfg.get_list);
    message (" List:                 OK");
  }

  public static int
  main (string[] args)
  {
    TestCase test = new TestCase ();
    try
    {
      test.test_defaults ();
      test.test_set ();
      test.test_invalid ();
      test.test_notify ();
      print ("All tests finished successfully.\n");
    }
    catch (AssertionError assertion)
    {
      critical ("Assertion Error: %s", assertion.message);
      return 1;
    }
    catch (Error err)
    {
      critical ("Error: %s", err.message);
      return 2;
    }
    return 0;
  }
}

// vim: set et ts=2 sts=2 sw=2 ai cindent :
