Configuration Metadata
======================

.. sidebar:: Note

   This document attempts to conform to the `RFC 2119
   <http://tools.ietf.org/html/rfc2119>`_ standards for the terms "MUST" and
   "SHOULD".

Each configuration schema has its own set of metadata, in addition to the
metadata associated with each configuration option. There are three kinds of
schema metadata: Common, backend-specific, and custom metadata. Common metadata
is comprised of pre-defined keys not specific to a backend, and do not have a
common prefix. Backend-specific metadata is comprised of pre-defined keys with
a common prefix: the name property of the backend. Custom metadata follows the
convention of message headers [#]_ and desktop file keys [#]_, in that they MUST
begin with the prefix ``X-``.

Here is the list of common metadata keys:

.. sidebar:: Note

   In the following definitions, ``app_name`` refers to the "basename" of the
   schema file. For example, the ``app_name`` of the file ``foo-bar.schema-ini``
   would be ``foo-bar``. This name SHOULD be filename-friendly on multiple
   platforms.

``single_instance``
  Asserts that there can only be one instance of the configuration (defaults to
  true). If this value is false, then multiple instances of configuration
  options can be governed by the schema.

Here is the list of backend-specific metadata keys:

``GConf.base_path``
  The base path for the configuration options. The configuration options will
  reside in ``${base_path}/${app_name}``. This defaults to ``/apps``.

``GConf.base_instance_path``
  The base path for the configuration data for multiple instances that are
  governed by the schema. Defaults to ``${base_path}/instances``. The
  configuration options will reside in
  ``${base_instance_path}/${app_name}/${instance_id}``. If this key exists when
  ``single_instance`` is true, a warning will be issued. The placeholder
  ``${base_path}`` and will be replaced with the proper variable value.

All of this metadata is stored in the group ``DEFAULT``. Here is an example of
what that section might look like:

.. sourcecode:: ini

   [DEFAULT]
   single_instance = false
   GConf.base_path = /non/standard-prefix

.. [#] `RFC 822, Section 4.7.5 <http://tools.ietf.org/html/rfc822#section-4.7.5>`_
.. [#] `Desktop Entry Specification: Extending the format <http://standards.freedesktop.org/desktop-entry-spec/1.1/ar01s08.html>`_

.. vim: set ft=rst tw=80 lbr :
