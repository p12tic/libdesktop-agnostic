============
Installation
============

The following document details how to install libdesktop-agnostic.

-------------
Prerequisites
-------------

Build-only
~~~~~~~~~~

* Python 2.4 or later

Build/Runtime (*required*)
~~~~~~~~~~~~~~~~~~~~~~~~~~

* Vala 0.7.4 or later
* GLib 2.12 or later
* GTK 2.12 or later

One of the following VFS libraries:

* GIO 2.16 or later (recommended)
* GNOME VFS 2.6 or later
* Thunar VFS (also requires the D-Bus bindings for GLib [``dbus-glib``])

Build/Runtime (*optional*)
~~~~~~~~~~~~~~~~~~~~~~~~~~

* GConf (Needs GLib 2.14 or later, for ``GRegex`` support)
* GNOME Desktop

--------------------
Building the Package
--------------------

libdesktop-agnostic uses Waf as its build system. It is bundled with the
package. From the toplevel directory, run ``./waf --help`` to see all of the
options available for the various commands. A regular user will just need to
run the following::

    ./waf configure --config-backends=[cfg] --vfs-backends=[vfs] --desktop-entry-backends=[de]
    ./waf
    ./waf install

The preceding commands check the system for dependencies, build the library and
test programs, and install the library to the default location (``/usr/local``).

The placeholders (specified by the ``[bracketed]`` identifiers) should be
replaced by a comma-separated list of backends. A list of valid backends
follows:

Config
~~~~~~

* ``gconf`` (recommended)
* ``memory`` (useful for testing applications)
* ``null`` (only useful for people developing libdesktop-agnostic)

VFS
~~~

* ``gio`` (recommended)
* ``gnome-vfs``
* ``thunar-vfs``

Desktop Entry
~~~~~~~~~~~~~

* ``glib`` (recommended)
* ``gnome``

---------------
Packaging Notes
---------------

Packagers should package binary modules separately.

A configuration file (``desktop-agnostic.ini``) is installed in
``$SYSCONFDIR/xdg/libdesktop-agnostic``. ``$SYSCONFDIR`` is usually ``/etc``.
The default modules are the first modules listed in the respective backend
flags passed to ``./waf configure``.
