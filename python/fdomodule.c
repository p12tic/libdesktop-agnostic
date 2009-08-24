/*
 * Copyright (c) 2009 Mark Lee <libdesktop-agnostic@lazymalevolence.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
*/

#ifdef HAVE_BUILD_CONFIG_H
#include "build-config.h"
#endif

#include <pygobject.h>

/* the following symbols are declared in fdo.c: */
void pydesktopagnostic_fdo_add_constants (PyObject *module,
                                          const gchar *strip_prefix);
void pydesktopagnostic_fdo_register_classes (PyObject *d);
void pyglib_pid_register_type (PyObject *d);
extern PyMethodDef pydesktopagnostic_fdo_functions[];

DL_EXPORT (void)
initfdo (void)
{
  PyObject *m, *d;

  init_pygobject ();

  m = Py_InitModule ("desktopagnostic.fdo", pydesktopagnostic_fdo_functions);
  d = PyModule_GetDict (m);

  pydesktopagnostic_fdo_register_classes (d);
  pyglib_pid_register_type (d);
  pydesktopagnostic_fdo_add_constants (m, "DESKTOP_AGNOSTIC_FDO_");

  if (PyErr_Occurred ())
  {
    Py_FatalError ("Unable to initialise the desktopagnostic module");
  }
}
