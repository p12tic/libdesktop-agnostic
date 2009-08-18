============
Known Issues
============

Build System
------------

The following compile warnings are known (line numbers may not be accurate):

* This error (and other, similar ones) are due to a limitation in Vala [1]_::

    desktop-entry-impl-glib.vala: In function ‘desktop_agnostic_desktop_entry_glib_implementation_real_set_string_list’:
    desktop-entry-impl-glib.vala: warning: passing argument 4 of ‘g_key_file_set_string_list’ from incompatible pointer type

* These errors are also due to a limitation in Vala. Patches for Vala have
  been submitted [2]_ [3]_::

    config-bridge.vala: In function ‘desktop_agnostic_config_bridge_bind’:
    config-bridge.vala:164: warning: pointer targets in passing argument 2 of ‘g_object_class_list_properties’ differ in signedness
    desktop-entry-impl-glib.c:306: warning: pointer targets in passing argument 4 of ‘g_key_file_get_string_list’ differ in signedness

.. [1] See `GNOME Bug #582092`_.
.. [2] See `GNOME Bug #529866`_ (fixed in Vala 0.7.6).
.. [3] See `GNOME Bug #592108`_ (fixed in Vala 0.7.6).

.. _GNOME Bug #582092: http://bugzilla.gnome.org/show_bug.cgi?id=582092
.. _GNOME Bug #529866: http://bugzilla.gnome.org/show_bug.cgi?id=529866
.. _GNOME Bug #592108: http://bugzilla.gnome.org/show_bug.cgi?id=592108

* This kind of error is usually due to a limitation in Vala API generation::

    libdesktop-agnostic/vfs-file-impl-thunar-vfs.vala:107.15-110.9: warning: unreachable catch clause detected

Runtime
-------

* ``lda-schema-to-gconf`` does not function properly on 64-bit systems if
  built with optimization flags higher than ``-O0``.

See also: confirmed/in progress bugs at the `bug tracker`_.

.. _bug tracker: https://bugs.launchpad.net/libdesktop-agnostic
