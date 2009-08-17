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
  int retval;

  public TestCase ()
  {
    Config.Schema schema = new Config.Schema ("test-config.schema-ini");
    this.cfg = Config.new ((owned)schema);
    this.notify_counter = 0;
    this.ml = new MainLoop (null, false);
    this.retval = 0;
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
  test_default_empty_list (string suffix) throws AssertionError, Error
  {
    ValueArray expected_array;
    Value expected;
    string key;

    expected_array = new ValueArray (0);
    expected = expected_array;
    key = "list-%s".printf (suffix);
    assert_equals (expected, cfg.get_value ("empty", key));
    assert (array_equals (expected_array,
                          cfg.get_list ("empty", key)));
  }

  void
  test_defaults () throws AssertionError, Error
  {
    Value expected, item_1, item_2, item_3;
    ValueArray expected_array;

    cfg.reset ();

    expected = true;
    assert_equals (expected, cfg.get_value ("numeric", "boolean"));
    assert ((bool)expected == cfg.get_bool ("numeric", "boolean"));

    expected = 3;
    assert_equals (expected, cfg.get_value ("numeric", "integer"));
    assert ((int)expected == cfg.get_int ("numeric", "integer"));

    expected = 3.14f;
    assert_equals (expected, cfg.get_value ("numeric", "float"));
    assert ((float)expected == cfg.get_float ("numeric", "float"));

    expected = "Foo bar";
    assert_equals (expected, cfg.get_value ("misc", "string"));
    assert ((string)expected == cfg.get_string ("misc", "string"));

    expected = "";
    assert_equals (expected, cfg.get_value ("empty", "string"));
    assert ((string)expected == cfg.get_string ("empty", "string"));

    expected_array = new ValueArray (2);
    item_1 = true;
    item_2 = false;
    expected_array.append (item_1);
    expected_array.append (item_2);
    expected = expected_array;
    assert_equals (expected, cfg.get_value ("list", "boolean"));
    assert (array_equals ((ValueArray)expected,
                          cfg.get_list ("list", "boolean")));

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

    expected_array = new ValueArray (2);
    item_1 = "foo";
    item_2 = "bar";
    expected_array.append (item_1);
    expected_array.append (item_2);
    expected = expected_array;
    assert_equals (expected, cfg.get_value ("list", "string"));
    assert (array_equals ((ValueArray)expected,
                          cfg.get_list ("list", "string")));

    this.test_default_empty_list ("boolean");
    this.test_default_empty_list ("integer");
    this.test_default_empty_list ("float");
    this.test_default_empty_list ("string");
  }

  void
  test_set_empty_list (string key) throws AssertionError, Error
  {
    ValueArray old_value;
    ValueArray expected_array;
    Value expected;

    old_value = cfg.get_list ("list", key);
    expected_array = new ValueArray (0);
    expected = expected_array;

    // test setting via set_list ()
    cfg.set_list ("list", key, expected_array);
    assert_equals (expected, cfg.get_value ("list", key));
    assert (array_equals (expected_array,
                          cfg.get_list ("list", key)));

    // reset to old value
    cfg.set_list ("list", key, old_value);
    assert (array_equals (old_value,
                          cfg.get_list ("list", key)));

    // test setting via set_value ()
    cfg.set_value ("list", key, expected);
    assert_equals (expected, cfg.get_value ("list", key));
    assert (array_equals (expected_array,
                          cfg.get_list ("list", key)));
  }

  void
  test_set () throws AssertionError, Error
  {
    Value expected, item_1, item_2, item_3;
    ValueArray expected_array;

    expected = false;
    cfg.set_bool ("numeric", "boolean", (bool)expected);
    assert_equals (expected, cfg.get_value ("numeric", "boolean"));
    assert ((bool)expected == cfg.get_bool ("numeric", "boolean"));

    expected = 10;
    cfg.set_int ("numeric", "integer", (int)expected);
    assert_equals (expected, cfg.get_value ("numeric", "integer"));
    assert ((int)expected == cfg.get_int ("numeric", "integer"));

    expected = 2.718f;
    cfg.set_float ("numeric", "float", (float)expected);
    assert_equals (expected, cfg.get_value ("numeric", "float"));
    assert ((float)expected == cfg.get_float ("numeric", "float"));

    expected = "Quux baz";
    cfg.set_string ("misc", "string", (string)expected);
    assert_equals (expected, cfg.get_value ("misc", "string"));
    assert ((string)expected == cfg.get_string ("misc", "string"));

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

    this.test_set_empty_list ("boolean");
    this.test_set_empty_list ("integer");
    this.test_set_empty_list ("float");
    this.test_set_empty_list ("string");
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
    unowned MainContext ctx = this.ml.get_context ();

    cfg.notify_add ("misc", "string", this.on_string_changed);
    cfg.notify_add ("misc", "string", this.on_string_changed2);
    this.update_notify_value (ctx, "Bar foo", 1);
    this.update_notify_value (ctx, "Foo quux", 5);
    cfg.notify_remove ("misc", "string", this.on_string_changed);
    this.update_notify_value (ctx, "Bar quux", 8);
    cfg.notify_remove ("misc", "string", this.on_string_changed2);
    this.update_notify_value (ctx, "Baz foo", 8);
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
    this.test_invalid_func ((GetCfgFunc)cfg.get_bool);
    this.test_invalid_func ((GetCfgFunc)cfg.get_float);
    this.test_invalid_func ((GetCfgFunc)cfg.get_int);
    this.test_invalid_func ((GetCfgFunc)cfg.get_string);
    this.test_invalid_func ((GetCfgFunc)cfg.get_list);
  }

  bool
  run ()
  {
    try
    {
      this.test_defaults ();
      this.test_set ();
      this.test_invalid ();
      this.test_notify ();
    }
    catch (AssertionError assertion)
    {
      critical ("Assertion Error: %s", assertion.message);
      this.retval = 1;
    }
    catch (Error err)
    {
      critical ("Error: %s", err.message);
      this.retval = 2;
    }
    finally
    {
      this.ml.quit ();
    }
    return false;
  }

  public static int
  main (string[] args)
  {
    TestCase test = new TestCase ();
    Idle.add (test.run);
    test.ml.run ();
    return test.retval;
  }
}

// vim: set et ts=2 sts=2 sw=2 ai cindent :
