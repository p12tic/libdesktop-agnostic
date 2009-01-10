/* 
 * Vala binding for POSIX glob() (with GNU extensions).
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

namespace POSIX
{
  [CCode (cname = "glob_t", cheader_filename = "glob.h", destroy_function = "globfree")]
  public struct glob_t
  {
    // properties
    [CCode (cname = "gl_pathc")]
    public size_t path_count;
    [CCode (cname = "gl_pathv")]
    public string[]? paths;
    [CCode (cname = "gl_offs")]
    public size_t offset;
    // flags
    [CCode (cname = "GLOB_ERR")]
    public static const int ERR;
    [CCode (cname = "GLOB_MARK")]
    public static const int MARK;
    [CCode (cname = "GLOB_NOSORT")]
    public static const int NOSORT;
    [CCode (cname = "GLOB_DOOFFS")]
    public static const int DOOFFS;
    [CCode (cname = "GLOB_NOCHECK")]
    public static const int NOCHECK;
    [CCode (cname = "GLOB_APPEND")]
    public static const int APPEND;
    [CCode (cname = "GLOB_NOESCAPE")]
    public static const int NOESCAPE;
    // GNU-specific flags
    [CCode (cname = "GLOB_PERIOD")]
    public static const int PERIOD;
    [CCode (cname = "GLOB_MAGCHAR")]
    public static const int MAGCHAR;
    [CCode (cname = "GLOB_ALTDIRFUNC")]
    public static const int ALTDIRFUNC;
    [CCode (cname = "GLOB_BRACE")]
    public static const int BRACE;
    [CCode (cname = "GLOB_NOMAGIC")]
    public static const int NOMAGIC;
    [CCode (cname = "GLOB_TILDE")]
    public static const int TILDE;
    [CCode (cname = "GLOB_ONLYDIR")]
    public static const int ONLYDIR;
    [CCode (cname = "GLOB_TILDE_CHECK")]
    public static const int TILDE_CHECK;
    // error codes
    [CCode (cname = "GLOB_NOSPACE")]
    public static const int ERR_NOSPACE;
    [CCode (cname = "GLOB_ABORTED")]
    public static const int ERR_ABORTED;
    [CCode (cname = "GLOB_NOMATCH")]
    public static const int ERR_NOMATCH;
  }
  //public delegate int GlobErrFunc (string path, int errno);
  [CCode (cname = "glob")]
  public static int glob (string pattern, int flags, void* err_func,
                          out glob_t g);
}

// vim: set et ts=2 sts=2 sw=2 ai :
