/*
 * GType key functions for GHashTable.
 *
 * Copyright (C) 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
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

#include <glib-object.h>

/**
 * desktop_agnostic_config_gtype_equal:
 * @v1: a pointer to a #GType key.
 * @v2: a pointer to a #GType key to compare with @v1.
 *
 * Compares the two #GType values being pointed to and returns 
 * %TRUE if they are equal.
 * It can be passed to g_hash_table_new() as the @key_equal_func
 * parameter, when using pointers to GType values as keys in a #GHashTable.
 *
 * Originally based on %g_int64_equal.
 * 
 * Returns: %TRUE if the two keys match.
 */
static gboolean
desktop_agnostic_config_gtype_equal (gconstpointer v1,
                                     gconstpointer v2)
{
  /* this is the way that it would work if Vala didn't do GINT_TO_POINTER.
  return *((const GType*) v1) == *((const GType*) v2); */
  return GPOINTER_TO_UINT (v1) == GPOINTER_TO_UINT (v2);
}

/**
 * desktop_agnostic_config_gtype_hash:
 * @v: a pointer to a #GType key
 *
 * Converts a pointer to a #GType to a hash value.
 * It can be passed to g_hash_table_new() as the @hash_func parameter, 
 * when using pointers to GType values as keys in a #GHashTable.
 *
 * Originally based on %g_int64_hash.
 *
 * Returns: a hash value corresponding to the key.
 */
static guint
desktop_agnostic_config_gtype_hash (gconstpointer v)
{
  /* this is the way that it would work if Vala didn't do GINT_TO_POINTER.
  return (guint) *(const GType*) v; */
  return (guint) GPOINTER_TO_UINT (v);
}
