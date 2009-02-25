/* 
 * Desktop Agnostic Library: File interface (similar to GFile).
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

namespace DesktopAgnostic.VFS.File
{
  /**
   * The kinds of files recognized by the File backends.
   */
  public enum FileType
  {
    UNKNOWN = 0,
    REGULAR,
    DIRECTORY,
    SYMBOLIC_LINK,
    SPECIAL
  }
  /**
   * Abstract base class for representations of files.
   */
  public abstract class Backend : Object
  {
    /**
     * The pointer to the implementation used.
     */
    public abstract void* implementation { get; }
    /**
     * Implementation detail. Implementing classes override this to allow the
     * uri property to return the correct value.
     */
    protected abstract string impl_uri { get; }
    /**
     * The URI that the object represents.
     */
    public string uri {
      get
      {
        return this.impl_uri;
      }
      construct
      {
        if (value != null)
        {
          this.init (value);
        }
      }
    }
    /**
     * Implementation detail. Implementing classes override this to allow the
     * path property to return the correct value.
     */
    protected abstract string? impl_path { owned get; }
    /**
     * The path that the object represents.
     */
    public string? path {
      owned get
      {
        return this.impl_path;
      }
      construct
      {
        if (value != null)
        {
          this.init ("file://" + value);
        }
      }
    }
    /**
     * Whether something exists at the URI that the object represents.
     */
    public abstract bool exists { get; }
    /**
     * The kind of file that the object represents.
     */
    public abstract FileType file_type { get; }
    /**
     * Implementation detail. Implementing classes override this to properly
     * associate the URI with the implementation pointer.
     */
    protected abstract void init (string uri);
    /**
     * Adds a monitor to the file.
     * @return the monitor associated with the file
     */
    public abstract Monitor monitor ();
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :