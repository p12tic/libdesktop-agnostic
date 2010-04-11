============
Installation
============

The following document details how to install libdesktop-agnostic.

-------------
Debian/Ubuntu
-------------

For Ubuntu users, there is a `PPA`_ with semi-regular releases:

.. _PPA: https://launchpad.net/~malept/+archive/experimental

If you wish to build from source, the preferred method is to use the Debian
packaging method:

1. Install the build-time prerequisites. They are listed in ``debian/control``,
   under the ``Build-Depends`` entry.
2. Run ``debuild binary``.
3. Install the built packages with ``sudo dpkg -i``. The packages should be in
   the parent directory of the source directory.

------
Gentoo
------

For Gentoo users, an SCM version is available at the desktop-effects overlay.
You can add it by installing `layman`_ and running the following commands
(with administrative privileges)::

    layman -a desktop-effects
    echo ** x11-libs/libdesktop-agnostic >> /etc/portage/package.keywords
    emerge libdesktop-agnostic

There are several USE flags for libdesktop-agnostic. Please consult the
``metadata.xml`` file in the directly where the
``libdesktop-agnostic-9999.ebuild`` is located for flag descriptions.

.. _layman: http://layman.sf.net/

-------------
Prerequisites
-------------

Build-only
~~~~~~~~~~

* Python 2.4 or later (requires the development files, for the Python
  bindings)
* GObject Introspection 0.6.3 or later (requires the development files, to
  properly detect the correct version)
* Vala 0.7.10 or later

Build/Runtime (*required*)
~~~~~~~~~~~~~~~~~~~~~~~~~~

* GLib 2.12 or later
* GTK 2.12 or later

For the Python bindings:

* PyGObject 2.12 or later
* PyGTK 2.12 or later

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
* ``keyfile`` (uses GLib's GKeyFile, which is a .ini-like format)
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
