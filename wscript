#! /usr/bin/env python
# encoding: utf-8

import os
import Params, intltool, gnome

# the following two variables are used by the target "waf dist"
VERSION = '0.0.1'
if os.path.exists('.bzr'):
    try:
        from bzrlib.branch import Branch
        branch = Branch.open_containing('.')[0]
        revno = branch.revno()
        parent_url = branch.get_parent()
        if parent_url is None:
            # use the nick instead
            branch_name = branch.nick
        else:
            if parent_url[-1] == '/':
                parent_url = parent_url[:-1]
            branch_name = os.path.basename(parent_url)
        VERSION += '-bzr%d-%s' % (revno, branch_name)
    except ImportError:
        pass

APPNAME = 'libdesktop-agnostic'

# these variables are mandatory ('/' are converted automatically)
srcdir = '.'
blddir = 'build'

config_backend = None

def set_options(opt):
    [opt.tool_options(x) for x in ['compiler_cc', 'gnome']]
    opt.sub_options('libdesktop-agnostic')

def configure(conf):
    print 'Configuring %s %s' % (APPNAME, VERSION)

    if len(Params.g_options.config_backends) == 0:
        conf.fatal('At least one configuration backend needs to be built.')
    conf.env['BACKENDS_CFG'] = Params.g_options.config_backends.split(',')

    conf.check_tool('compiler_cc misc gnome vala')
    conf.check_tool('intltool')

    conf.check_pkg('gmodule-2.0', destvar='GMODULE', vnum='2.6.0', mandatory=True)
    conf.check_pkg('gobject-2.0', destvar='GOBJECT', mandatory=True)
    # Needed for the Color class
    conf.check_pkg('gdk-2.0', destvar='GDK', mandatory=True)
    conf.check_pkg('vala-1.0', destvar='VALA', vnum='0.3.5', mandatory=True)
    if 'gconf' in conf.env['BACKENDS_CFG']:
        conf.check_pkg('gconf-2.0', destvar='GCONF', mandatory=True)

    conf.define('VERSION', str(VERSION))
    conf.define('GETTEXT_PACKAGE', APPNAME + '-1.0')
    conf.define('PACKAGE', APPNAME)

    conf.env.append_value('CCFLAGS', '-DHAVE_CONFIG_H')

    conf.write_config_header('config.h')

def build(bld):
    # process subfolders from here
    bld.add_subdirs('libdesktop-agnostic data')

    env = bld.env()

#    if env['INTLTOOL']:
#        bld.add_subdirs('po')

def shutdown():
    # Postinstall tasks:
    gnome.postinstall_icons() # Updating the icon cache
