/* 
 * Desktop Agnostic Library: glob() wrapper.
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

using POSIX;

namespace DesktopAgnostic.VFS
{
  public errordomain GlobError
  {
    NOSPACE,     // ran out of memory
    ABORTED,     // read error
    NOMATCH,     // no found matches
    BAD_PATTERN, // invalid pattern
    BAD_FLAGS,   // invalid flags
    ERRNO        // via errno
  }
  public class Glob : Object
  {
    private glob_t glob;
    public size_t length
    {
      get
      {
        return this.glob.path_count;
      }
    }
    public weak string[]? paths
    {
      get
      {
        return this.glob.paths;
      }
    }
    public size_t offset
    {
      get
      {
        return this.glob.offset;
      }
    }
    private string _pattern;
    public string pattern
    {
      get
      {
        return this._pattern;
      }
      set
      {
        if (value != "")
        {
          this._pattern = value;
        }
        else
        {
          throw new GlobError.BAD_PATTERN ("Invalid pattern.");
        }
      }
    }
    private int _flags = glob_t.MARK | glob_t.BRACE | glob_t.TILDE_CHECK;
    public int flags
    {
      get
      {
        return this._flags;
      }
      set
      {
        if (value >= 0)
        {
          this._flags = value;
        }
        else
        {
          throw new GlobError.BAD_FLAGS ("Invalid flags.");
        }
      }
    }
    public static Glob
    execute (string pattern) throws GlobError
    {
      Glob g = (Glob)Object.new (typeof (Glob), "pattern", pattern);
      g.run_glob (g._pattern, g._flags);
      return g;
    }
    public static Glob
    execute_with_flags (string pattern, int flags) throws GlobError
    {
      Glob g = (Glob)Object.new (typeof (Glob),
                                 "pattern", pattern,
                                 "flags", flags);
      g.run_glob (g._pattern, g._flags);
      return g;
    }
    public void
    append (string pattern) throws GlobError
    {
      this.run_glob (pattern, this._flags | glob_t.APPEND);
    }
    private void
    run_glob (string pattern, int flags) throws GlobError
    {
      int res = POSIX.glob (pattern, flags, (void*)on_glob_error,
                            out this.glob);
      if (res != 0)
      {
        switch (res)
        {
          case glob_t.ERR_NOSPACE:
            throw new GlobError.NOSPACE ("Ran out of memory.");
          case glob_t.ERR_ABORTED:
            throw new GlobError.ABORTED ("Read error.");
          case glob_t.ERR_NOMATCH:
            throw new GlobError.NOMATCH ("No matches found.");
          default:
            critical ("Unknown error code: %d", res);
            break;
        }
      }
    }
    private static int
    on_glob_error (string path, int eerrno)
    {
      switch (eerrno)
      {
        case Posix.EACCES:
        case Posix.EBADF:
        case Posix.EMFILE:
        case Posix.ENFILE:
        case Posix.ENOENT:
        case Posix.ENOMEM:
        case Posix.ENOTDIR:
        case Posix.EFAULT:
        case Posix.EINVAL:
        case Posix.ELOOP:
        case Posix.ENAMETOOLONG:
          throw new GlobError.ERRNO ("Miscellaneous error for '%s' (%d): %s",
                                     path, eerrno,
                                     Posix.strerror (eerrno));
        default:
          critical ("Unknown error code: %d", eerrno);
          break;
      }
      return 1;
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
