# -*- coding: utf-8 -*-
'''A waf tool for building Sphinx documentation.

.. moduleauthor:: Mark Lee <waf@lazymalevolence.com>
'''

import Constants
import Node
import os
import pproc
import stat
import Task
import TaskGen
import Utils


class sphinx_task(Task.Task):
    '''The task that builds Sphinx documentation.'''

    def update_build_dir(self, node):
        '''Adapted from Waf 1.5.15 (wafadmin/Node.py).'''

        path = node.abspath(self.env)

        lst = Utils.listdir(path)
        try:
            node.__class__.bld.cache_dir_contents[node.id].update(lst)
        except KeyError:
            node.__class__.bld.cache_dir_contents[node.id] = set(lst)
        node.__class__.bld.cache_scanned_folders[node.id] = True

        for k in lst:
            npath = path + os.sep + k
            st = os.stat(npath)
            if stat.S_ISREG(st[stat.ST_MODE]):
                try:
                    ick = node.find_or_declare(k)
                    if ick.id not in node.__class__.bld \
                                         .node_sigs[self.env.variant()]:
                        node.__class__.bld \
                            .node_sigs[self.env.variant()][ick.id] = \
                                Constants.SIG_NIL
                except AttributeError:
                    print 'WTF @ %s' % k
            elif stat.S_ISDIR(st[stat.ST_MODE]):
                child = node.find_dir(k)
                if not child:
                    child = node.ensure_dir_node_from_path(k)
                self.update_build_dir(child)

    def run(self):
        doc_dir = self.inputs[0].parent
        rule = '"${SPHINX}" -b html "%s" "%s"' % (doc_dir.srcpath(),
                                                  doc_dir.bldpath(self.env))
        cmd = Utils.subst_vars(rule, self.env)
        proc = pproc.Popen(cmd, shell=True, stdin=pproc.PIPE)
        proc.communicate()
        self.update_build_dir(self.generator.path)
        return proc.returncode

    def install(self):
        base_builddir = self.inputs[0].parent.bldpath(self.env)
        exclude = Node.exclude_regs + '\n**/.buildinfo\n**/_static'

        def generate_glob(pattern, use_exclude=False):
            excl = []
            if use_exclude:
                excl = exclude
            glob = self.generator.path.ant_glob(pattern, dir=False, src=False,
                                                excl=excl)
            return ' '.join([os.path.join('build', base_builddir, x)
                             for x in glob.split()])
        glob_base = generate_glob('*', True)
        glob_static = generate_glob('_static/*')
        self.generator.bld.install_files('${HTMLDIR}', glob_base)
        self.generator.bld.install_files('${HTMLDIR}/_static', glob_static)


@TaskGen.extension('.rst')
def rst_handler(task, node):
    # do nothing!
    pass


@TaskGen.feature('sphinx')
def process_sphinx(self):
    conf_file = getattr(self, 'sphinx_config', 'conf.py')

    node = self.path.find_resource(conf_file)
    if not node:
        raise ValueError('sphinx configuration file not found')

    # the task instance
    task = self.create_task('sphinx')
    source = self.source
    self.source = ['%s.rst' % s for s in source]
    self.target = ['objects.inv', 'search.html', 'searchindex.js'] + \
                  ['%s.html' % s for s in source]
    task.set_inputs([node] + [self.path.find_resource(f)
                              for f in self.source])
    task.set_outputs([self.path.find_or_declare(f) for f in self.target])


def detect(conf):
    conf.find_program('sphinx-build', mandatory=True, var='SPHINX')
