/* 
 * Desktop Agnostic Library: Configuration Schema Abstract Type.
 *
 * Copyright (C) 2008, 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 * Author : Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 */

namespace DesktopAgnostic.Config
{
  /**
   * The definition of a custom schema type. That is, a schema type which is
   * neither one of the primitive types (boolean, integer, float, string) nor
   * a list.
   */
  public abstract class SchemaType
  {
    /**
     * The name of the schema type, used in the "type" and "list type" schema
     * options for for configuration keys.
     */
    public abstract string name { get; }
    /**
     * The GType associated with the schema type.
     */
    public abstract Type schema_type { get; }
    /**
     * Converts a value into a string, to store in the configuration backend.
     * @param val the value to convert to a string
     * @return the string-serialized version of the value
     * @throws SchemaError if the schema type and the value type are different,
     * or if the serialization fails
     */
    public abstract string serialize (Value val) throws SchemaError;
    /**
     * Converts a serialized string into the corresponding value dictated by the
     * schema type.
     * @param serialized the string to convert into the value
     * @return a container containing the converted value
     * @throws SchemaError if the deserialization fails
     */
    public abstract Value deserialize (string serialized) throws SchemaError;
    /**
     * Converts the default value specified by the schema into the corresponding
     * deserialized value.
     * @param schema the schema from which the default value will be parsed
     * @param group the configuration option's full group/key
     * @return the parsed default value
     * @throws SchemaError if the default value is not found, or could not be
     * parsed correctly.
     */
    public abstract Value parse_default_value (KeyFile schema,
                                               string group) throws SchemaError;
    /**
     * Converts the default list value specified by the schema into the
     * corresponding deserialized value array.
     * @param schema the schema from which the default value will be parsed
     * @param group the configuration option's full group/key
     * @return the parsed default value(s)
     * @throws SchemaError if the default value is not found, or could not be
     * parsed correctly.
     */
    public abstract ValueArray parse_default_list_value (KeyFile schema,
                                                         string group) throws SchemaError;
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
