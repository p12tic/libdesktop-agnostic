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
    protected abstract string impl_uri { owned get; }
    /**
     * The URI that the object represents.
     */
    public string uri {
      owned get
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

    /**
     * Loads the contents of the file to a string.
     * @return %TRUE on success, %FALSE on failure.
     */
    public abstract bool load_contents (out string contents,
                                        out size_t length) throws Error;

    /**
     * Saves a string to the specified file, replacing any content that may
     * have been in it.
     * @return %TRUE on success, %FALSE on failure.
     */
    public abstract bool replace_contents (string contents) throws Error;

    /**
     * Launches the specified file with the default MIME application.
     * @return %TRUE on successful launch, %FALSE on failure.
     */
    public abstract bool launch () throws Error;
  }

  public Backend?
  new_for_path (string path) throws Error
  {
    unowned Implementation? vfs = get_default ();
    if (vfs == null)
    {
      return null;
    }
    else
    {
      return (Backend)Object.new (vfs.file_type, "path", path);
    }
  }

  public Backend?
  new_for_uri (string uri) throws Error
  {
    unowned Implementation? vfs = get_default ();
    if (vfs == null)
    {
      return null;
    }
    else
    {
      return (Backend)Object.new (vfs.file_type, "uri", uri);
    }
  }
}

// vim: set et ts=2 sts=2 sw=2 ai :
