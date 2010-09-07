#! /usr/bin/env python
# encoding: utf-8

import intltool
import Options
import os
import Scripting
import shutil
import sys
import Utils
import tarfile
import Task
import tempfile

API_VERSION = '1.0'

# the following two variables are used by the target "waf dist"
VERSION = '0.3.90'
VNUM = '0.4.0'

CFG_BACKENDS = ','.join(['gconf', 'keyfile'])
VFS_BACKENDS = ','.join(['gio', 'gnome-vfs', 'thunar-vfs'])
FDO_BACKENDS = ','.join(['glib', 'gnome'])
DISTCHECK_FLAGS = '\t'.join(['--config-backends=%s' % CFG_BACKENDS,
                             '--vfs-backends=%s' % VFS_BACKENDS,
                             '--desktop-entry-backends=%s' % FDO_BACKENDS])
GEN_SRC_DIR = 'gen_src'

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
elif os.path.exists('BZR_VERSION'):
    # the BZR_VERSION file should contain only the following:
    # $revno-$branch_name
    VERSION += '-bzr' + open('BZR_VERSION').read()

APPNAME = 'libdesktop-agnostic'

# these variables are mandatory ('/' is converted automatically)
srcdir = '.'
blddir = 'build'

config_backend = None


def set_options(opt):
    [opt.tool_options(x) for x in ['compiler_cc', 'gnu_dirs']]
    opt.sub_options('data docs')
    opt.sub_options('libdesktop-agnostic')
    opt.add_option('--enable-debug', action='store_true',
                   dest='debug', default=False,
                   help='Enables the library to be built with debug symbols.')
    opt.add_option('--enable-extra-warnings', action='store_true',
                   dest='extra_warnings', default=False,
                   help='Shows extra warnings during compilation.')
    opt.add_option('--enable-profiling', action='store_true',
                   dest='profiling', default=False,
                   help='Enables the library to be built so that it is '
                        'instrumented to measure performance.')
    opt.add_option('--disable-gi', action='store_true',
                   dest='no_gi', default=False)


def configure(conf):
    print 'Configuring %s %s' % (APPNAME, VERSION)

    if len(Options.options.config_backends) == 0:
        conf.fatal('At least one configuration backend needs to be built.')
    conf.env['BACKENDS_CFG'] = Options.options.config_backends.split(',')
    if len(Options.options.vfs_backends) == 0:
        conf.fatal('At least one VFS backend needs to be built.')
    conf.env['BACKENDS_VFS'] = Options.options.vfs_backends.split(',')
    if len(Options.options.de_backends) == 0:
        conf.fatal('At least one desktop entry backend needs to be built.')
    conf.env['BACKENDS_DE'] = Options.options.de_backends.split(',')

    conf.env['DEBUG'] = Options.options.debug
    conf.env['EXTRA_WARNINGS'] = Options.options.extra_warnings
    conf.env['PROFILING'] = Options.options.profiling
    conf.env['INTROSPECTION'] = not Options.options.no_gi
    conf.env['VNUM'] = str(VNUM)

    conf.check_tool('gnu_dirs')
    conf.check_tool('compiler_cc intltool misc python vala')

    MIN_VALA_VERSION = (0, 8, 1)

    conf.check_cfg(package='gmodule-2.0', uselib_store='GMODULE',
                   atleast_version='2.6.0', mandatory=True,
                   args='--cflags --libs')
    conf.check_cfg(package='glib-2.0', uselib_store='GLIB',
                   atleast_version='2.10.0', mandatory=True,
                   args='--cflags --libs')
    conf.check_cfg(package='gobject-2.0', uselib_store='GOBJECT',
                   atleast_version='2.12.0', mandatory=True,
                   args='--cflags --libs')
    # Needed for the Color class
    conf.check(lib='m', uselib='MATH')
    conf.check_cfg(package='gdk-2.0', uselib_store='GDK',
                   atleast_version='2.12.0', mandatory=True,
                   args='--cflags --libs')
    conf.check_cfg(package='gtk+-2.0', uselib_store='GTK',
                   atleast_version='2.12.0', mandatory=True,
                   args='--cflags --libs')
    if 'gconf' in conf.env['BACKENDS_CFG']:
        conf.check_cfg(package='glib-2.0', uselib_store='GREGEX',
                       atleast_version='2.14.0', mandatory=True,
                       args='--cflags --libs')
        conf.check_cfg(package='gconf-2.0', uselib_store='GCONF',
                       mandatory=True, args='--cflags --libs')
    if 'gio' in conf.env['BACKENDS_VFS']:
        conf.check_cfg(package='gio-2.0', uselib_store='GIO',
                       atleast_version='2.16.0', mandatory=True,
                       args='--cflags --libs')
    if 'thunar-vfs' in conf.env['BACKENDS_VFS']:
        conf.check_cfg(package='thunar-vfs-1', uselib_store='THUNAR_VFS',
                       mandatory=True, args='--cflags --libs')
        conf.check_cfg(package='dbus-glib-1', uselib_store='DBUS_GLIB',
                       mandatory=True, args='--cflags --libs')
    if 'gnome-vfs' in conf.env['BACKENDS_VFS']:
        conf.check_cfg(package='gnome-vfs-2.0', uselib_store='GNOME_VFS',
                       atleast_version='2.6.0', mandatory=True,
                       args='--cflags --libs')
    if 'gnome' in conf.env['BACKENDS_DE']:
        conf.check_cfg(package='gnome-desktop-2.0',
                       uselib_store='GNOME_DESKTOP', mandatory=True,
                       args='--cflags --libs')
    # make sure we have the proper Vala version
    if conf.env['VALAC_VERSION'] < MIN_VALA_VERSION and \
        not os.path.isdir(os.path.join(conf.curdir, GEN_SRC_DIR)):
        conf.fatal('''\
Your Vala compiler version %s is too old. The project requires
version %d.%d.%d''' % ((str(conf.env['VALAC_VERSION']),) + MIN_VALA_VERSION))

    # check for gobject-introspection
    conf.check_cfg(package='gobject-introspection-1.0',
                   atleast_version='0.6.3', mandatory=True,
                   args='--cflags --libs')
    pkgconfig = 'pkg-config --variable g_ir_compiler ' \
                'gobject-introspection-1.0'
    conf.env['G_IR_COMPILER'] = Utils.cmd_output(pkgconfig, silent=1).strip()

    conf.sub_config('data')
    conf.sub_config('docs')

    # manual Python bindings
    conf.sub_config('python')

    conf.define('API_VERSION', str(API_VERSION))
    conf.define('VERSION', str(VERSION))
    conf.define('GETTEXT_PACKAGE', APPNAME + '-1.0')
    conf.define('PACKAGE', APPNAME)
    conf.define('LIBDIR', conf.env['LIBDIR'])
    conf.define('SYSCONFDIR', conf.env['SYSCONFDIR'])

    if conf.env['DEBUG']:
        conf.env.append_value('VALAFLAGS', '-g')
        conf.env.append_value('CCFLAGS', '-ggdb')
    if conf.env['EXTRA_WARNINGS']:
        conf.env.append_value('CCFLAGS', '-Wall')
        conf.env.append_value('CCFLAGS', '-Wno-return-type')
        conf.env.append_value('CCFLAGS', '-Wno-unused')
    if conf.env['PROFILING']:
        conf.env.append_value('CCFLAGS', '-pg')
        conf.env.append_value('LINKFLAGS', '-pg')

    conf.env.append_value('CCFLAGS', '-D_GNU_SOURCE')
    conf.env.append_value('CCFLAGS', '-DHAVE_BUILD_CONFIG_H')

    conf.write_config_header('build-config.h')


def build(bld):
    # process subfolders from here
    bld.add_subdirs('libdesktop-agnostic tools tests data python docs')

    if bld.env['INTLTOOL']:
        bld.add_subdirs('po')

    cls = Task.TaskBase.classes['valac']
    old = cls.run

    def run(self):
        gen_src_dir = os.path.join(bld.srcnode.abspath(), GEN_SRC_DIR)
        if os.path.isdir(gen_src_dir) == False:
            return old(self)
        else:
            #print "restoring from pre-cache"
            # check if output timestamp is newer than inputs
            d = bld.path.abspath()
            latest_input = 0
            for x in self.inputs:
                timestamp = os.path.getmtime(x.abspath(self.env))
                if timestamp > latest_input:
                    latest_input = timestamp
            # we need two passes to check that we have up-to-date C sources
            try:
                for x in self.outputs:
                    subdir = x.parent.path_to_parent(x.__class__.bld.srcnode)
                    src = os.path.join(d, GEN_SRC_DIR, subdir, x.name)
                    timestamp = os.path.getmtime(src)
                    if timestamp < latest_input:
                        raise Exception("Source file needs to be regenerated!")
            except Exception:
                return old(self)

            for x in self.outputs:
                subdir = x.parent.path_to_parent(x.__class__.bld.srcnode)
                src = os.path.join(d, GEN_SRC_DIR, subdir, x.name)
                shutil.copy2(src, x.abspath(self.env))
            return 0
    cls.run = run


def dist(appname='', version=''):
    # we need to reconfigure to include all backends
    Options.options.config_backends = CFG_BACKENDS
    Options.options.vfs_backends = VFS_BACKENDS
    Options.options.de_backends = FDO_BACKENDS
    Scripting.commands += ['configure', 'build', 'dist2']


def dist2(ctx):
    src_dir = os.path.abspath('.')
    bld_dir = os.path.join(src_dir, getattr(Utils.g_module, Scripting.BLDDIR))
    gen_src_dir = os.path.join(src_dir, GEN_SRC_DIR)
    try:
        shutil.rmtree(gen_src_dir)
    except (OSError, IOError):
        pass

    os.makedirs(gen_src_dir)
    for dir, subdirs, filenames in os.walk(os.path.join(bld_dir, 'default')):
        dir_basename = os.path.basename(dir)
        if dir_basename in ['libdesktop-agnostic', 'tools', 'tests']:
            for filename in filenames:
                root, ext = os.path.splitext(filename)
                if ext in ['.c', '.h', '.gir', '.vapi', '.deps']:
                    src = os.path.join(dir, filename)
                    dst = os.path.join(gen_src_dir, dir_basename)
                    if not os.path.exists(dst):
                        os.makedirs(dst)
                    shutil.copy2(src, os.path.join(dst, filename))

    Scripting.g_gz = 'gz'
    tarball = Scripting.dist()
    # clean up
    shutil.rmtree(gen_src_dir)
    return tarball


def distcheck(ctx):
    # no support for extra configure flags in distcheck, we need to add it
    dist()
    Scripting.commands.pop()  # get rid of dist2, we'll call it ourselves
    Scripting.commands += ['distcheck2']


def distcheck2(ctx):
    appname = getattr(Utils.g_module, Scripting.APPNAME, 'noname')
    version = getattr(Utils.g_module, Scripting.VERSION, '1.0')
    waf = os.path.abspath(sys.argv[0])
    # we need to call dist2(), dist() just appends to Scripting.commands list
    tarball = dist2(ctx)
    tbp = tarfile.open(tarball)  # as in, tarball pointer
    [tbp.extract(filename) for filename in tbp]
    tbp.close()
    path = '%s-%s' % (appname, version)
    instdir = tempfile.mkdtemp('.inst', '%s-%s' % (appname, version))
    conf_flags = DISTCHECK_FLAGS
    popen_params = [waf, 'configure'] + conf_flags.split() + \
                   ['build', 'install', 'uninstall', '--destdir=%s' % instdir]
    ret = Utils.pproc.Popen(popen_params, cwd=path).wait()
    if ret:
        raise Utils.WafError('distcheck failed with code %i' % ret)
    if os.path.exists(instdir):
        raise Utils.WafError('''\
distcheck succeeded, but files were left in %s''' % instdir)
    shutil.rmtree(path)
