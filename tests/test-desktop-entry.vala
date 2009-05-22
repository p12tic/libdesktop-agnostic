using DesktopAgnostic;
using DesktopAgnostic.DesktopEntry;

int main (string[] args)
{
  try
  {
    VFS.Implementation vfs = vfs_get_default ();
    vfs.init ();
    if (args.length > 1)
    {
      bool hit_first_arg = false;
      foreach (unowned string arg in args)
      {
        if (!hit_first_arg)
        {
          hit_first_arg = true;
          continue;
        }

        Backend entry = new_for_filename (arg);
        message ("Entry: %s", entry.name);
        if (entry.exists ())
        {
          entry.launch (0, null);
        }
        else
        {
          critical ("Entry does not exist.");
        }
      }
    }
    else
    {
      Backend entry;
      VFS.File.Backend file;

      entry = DesktopEntry.new ();
      entry.name = "hosts file";
      entry.entry_type = DesktopEntry.Type.LINK;
      entry.set_string ("URL", "file:///etc/hosts");
      file = (VFS.File.Backend)Object.new (vfs.file_type,
                                           "path", "/tmp/desktop-agnostic-test.desktop");
      entry.save (file);
      entry = null;
    }
    vfs.shutdown ();
  }
  catch (GLib.Error err)
  {
    critical ("Error: %s", err.message);
  }
  return 0;
}

// vim: set ts=2 sts=2 sw=2 ai cindent :
