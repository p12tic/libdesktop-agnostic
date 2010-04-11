====
TODO
====

Config
------
Convert get/set methods to use contract programming (requires) when possible
KeyFile: check for added/deleted keys from schema when constructed

Desktop Entry
-------------
* add _for_(path|uri) constructors for convenience purposes?
* add is_valid() method

VFS: File
---------
* content type discovery

VFS: Volume
-----------
* split up network mounts, when possible?
* drive support, when possible?

UI: Icon Chooser Dialog
-----------------------
* if there are no icons but subfolders, there would be a centered (horiz+vert)
  icon + caption "select a subfolder", which, when clicked, shows the parent
  folder + expanded child folders in the folder selection dialog
* if editing and the entry has an icon, show the icon with the proper
  location/category.
* the last icon folder should be remembered (within a single session).
