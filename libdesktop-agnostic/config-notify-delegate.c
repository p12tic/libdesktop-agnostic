/*
 * A configuration notification delegate structure.
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

#include <libdesktop-agnostic/config.h>

typedef struct _DesktopAgnosticConfigNotifyDelegate
{
  DesktopAgnosticConfigNotifyFunc callback;
  gpointer target;
} DesktopAgnosticConfigNotifyDelegate;

static DesktopAgnosticConfigNotifyDelegate *
desktop_agnostic_config_notify_delegate_new (DesktopAgnosticConfigNotifyFunc callback,
                                             gpointer target)
{
  DesktopAgnosticConfigNotifyDelegate *self = NULL;

  g_return_val_if_fail (callback != NULL, self);

  self = g_slice_new0 (DesktopAgnosticConfigNotifyDelegate);
  self->callback = callback;
  self->target = target;

  return self;
}

static void
desktop_agnostic_config_notify_delegate_execute (DesktopAgnosticConfigNotifyDelegate *self,
                                                 const gchar *group,
                                                 const gchar *key,
                                                 const GValue *value)
{
  self->callback (group, key, value, self->target);
}

static int
desktop_agnostic_config_notify_delegate_compare (gpointer a, gpointer b)
{
  DesktopAgnosticConfigNotifyDelegate *del_a;
  DesktopAgnosticConfigNotifyDelegate *del_b;

  del_a = (DesktopAgnosticConfigNotifyDelegate*)a;
  del_b = (DesktopAgnosticConfigNotifyDelegate*)b;

  if (del_a->callback == del_b->callback && del_a->target == del_b->target)
  {
    return 0;
  }
  else
  {
    return 1;
  }
}

static void
desktop_agnostic_config_notify_delegate_free (DesktopAgnosticConfigNotifyDelegate *self)
{
  g_slice_free (DesktopAgnosticConfigNotifyDelegate, self);
}

/* vim: set et ts=2 sts=2 sw=2 ai : */
