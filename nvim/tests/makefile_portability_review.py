"""Offline Makefile checks using fake tools and an isolated checkout."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[2] / 'Makefile'

class PortableMakeTests(unittest.TestCase):
    def test_commands_work_outside_checkout_and_keep_xdg_destination(self):
        with tempfile.TemporaryDirectory(prefix='session-make-') as directory:
            base=Path(directory)
            checkout=base/'checkout'; checkout.mkdir()
            shutil.copy2(SOURCE,checkout/'Makefile')
            fake=base/'fake nvim'
            fake.write_text('#!/usr/bin/env python3\nimport json,os,sys\nprint(json.dumps({"cwd":os.getcwd(),"xdg":os.environ["XDG_CONFIG_HOME"],"args":sys.argv[1:]}))\n')
            fake.chmod(0o755)
            install=checkout/'install.sh'
            install.write_text('#!/bin/sh\nexec "'+str(fake)+'" "$@"\n')
            destination=base/'user-config'
            env=dict(os.environ,XDG_CONFIG_HOME=str(destination))
            def run(*args):
                result=subprocess.run(['make','--no-print-directory','-f',str(checkout/'Makefile'),*args],
                    cwd=base,env=env,text=True,capture_output=True,check=True)
                return result.stdout.strip()
            self.assertIn('make setup',run())
            for target in ('setup','cluster','install'):
                output=json.loads(run(target))
                self.assertEqual(output['cwd'],str(checkout))
                self.assertEqual(output['xdg'],str(destination))
            output=json.loads(run('config'))
            self.assertEqual(output['args'],['--config-only'])
            self.assertEqual(output['xdg'],str(destination))
            output=json.loads(run('run','NVIM='+str(fake),'NVIM_ARGS=example.py'))
            self.assertEqual(output['cwd'],str(checkout))
            self.assertEqual(output['xdg'],str(checkout))
            self.assertEqual(output['args'],['example.py'])
            output=json.loads(run('config','XDG_CONFIG_HOME='+str(base/'explicit-config')))
            self.assertEqual(output['xdg'],str(base/'explicit-config'))

if __name__=='__main__':unittest.main(verbosity=2)
