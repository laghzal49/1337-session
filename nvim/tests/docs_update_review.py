"""Offline updater conversion, indexing and atomic failure regression tests."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import subprocess
import sys
import fcntl
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('update_docs', Path(__file__).resolve().parents[1]/'scripts/update_docs.py')
docs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(docs)


class UpdaterTests(unittest.TestCase):
    def test_converter(self):
        html = '<h2>Parameters</h2><dl><dt><code>query: str</code></dt><dd>Search text</dd></dl>' \
               '<pre>char **ft_split(char const *s, char c);\n\treturn NULL;</pre>' \
               '<ul><li>First</li><li>Second</li></ul>' \
               '<table><tr><th>Type</th><th>Return</th></tr><tr><td>bool</td><td>Exists</td></tr></table>'
        md = docs.markdown(html, 'c')
        for fragment in ['## Parameters', '`query: str`', 'Search text', '```c\nchar **ft_split(char const *s, char c);',
                         '\treturn NULL;', '- First', '- Second', '| Type | Return |', '| bool | Exists |']:
            self.assertIn(fragment, md)

    def test_index(self):
        entries = [{'name': n, 'path': 'manual#' + str(i)} for i,n in enumerate(['pathlib.Path.exists()', 'other.Path.exists()', 'std::vector::size()'])]
        index = docs.indexed(entries)
        self.assertEqual(index['exact']['pathlib.Path.exists'], 1)
        self.assertIs(index['suffix']['Path.exists'], False)
        self.assertIs(index['suffix']['exists'], False)
        self.assertEqual(index['suffix']['vector::size'], 3)
        self.assertEqual(index['suffix']['size'], 3)

    def test_paths(self):
        for path in ['../escape', '/absolute', 'a/../../escape', 'a\\b', '\x00bad', '']:
            with self.assertRaises(ValueError): docs.safe_path(path)

    def test_publish_and_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            data = Path(directory)
            index = {'entries': [{'name':'Path.exists()', 'path':'library/pathlib#exists','type':'Method'}]}
            pages = {'library/pathlib': '<h1>Path.exists()</h1><p>Whether this path exists.</p>'}
            catalog = {'python': {'slug':'python~3.14','lang':'python'}}
            with patch.object(docs,'download',side_effect=[index,pages]): docs.update('python',catalog,data)
            previous = (data/'manifest.json').read_bytes()
            manifest = json.loads(previous)
            root = data/manifest['docsets']['python']['root']
            self.assertIn('Whether this path exists.', (root/'pages/library/pathlib.md').read_text())
            with patch.object(docs,'download',side_effect=[index,{}]):
                with self.assertRaises(ValueError): docs.update('python',catalog,data)
            self.assertEqual((data/'manifest.json').read_bytes(), previous)
            with patch.object(docs,'download',side_effect=[index,pages]), patch.object(docs,'atomic_json',side_effect=OSError('disk full')):
                with self.assertRaises(OSError): docs.update('python',catalog,data)
            self.assertEqual((data/'manifest.json').read_bytes(), previous)
            self.assertTrue(root.exists())
            original = docs.atomic_json
            def fail_manifest(path, value):
                if path.name == 'manifest.json': raise OSError('manifest disk full')
                return original(path, value)
            with patch.object(docs,'download',side_effect=[index,pages]), patch.object(docs,'atomic_json',side_effect=fail_manifest):
                with self.assertRaises(OSError): docs.update('python',catalog,data)
            self.assertEqual((data/'manifest.json').read_bytes(), previous)
            self.assertTrue(root.exists())

    def test_corrupt_manifest(self):
        with tempfile.TemporaryDirectory() as directory:
            data=Path(directory)
            (data/'manifest.json').write_text('{')
            with self.assertRaises(json.JSONDecodeError): docs.load_manifest(data)

    def test_import(self):
        with tempfile.TemporaryDirectory() as directory:
            directory=Path(directory)
            source=directory/'old'/'lua~5.1'
            (source/'pages-md').mkdir(parents=True)
            (source/'index.json').write_text(json.dumps({'entries':[{'name':'print()','path':'manual#print'}]}))
            (source/'pages-md/manual.md').write_text('# print\nActual manual.\n')
            with patch.object(docs,'download',side_effect=AssertionError('no network')):
                docs.update('lua',docs.CATALOG,directory/'new',directory/'old')
            self.assertTrue((directory/'new'/'manifest.json').exists())

    def test_lock(self):
        with tempfile.TemporaryDirectory() as directory:
            with (Path(directory)/'update.lock').open('a') as lock:
                fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
                result=subprocess.run([sys.executable,docs.__file__,'python','--data',directory],capture_output=True,text=True)
                self.assertEqual(result.returncode,2)
                self.assertIn('already running',result.stderr)

    def test_generation_retention(self):
        with tempfile.TemporaryDirectory() as directory:
            data = Path(directory)
            catalog = {'lua': {'slug': 'lua~5.1', 'lang': 'lua'}}
            index = {'entries': [{'name': 'print()', 'path': 'manual#print'}]}
            pages = {'manual': '<h1>print</h1><p>Actual manual.</p>'}
            roots = []
            for _ in range(4):
                with patch.object(docs, 'download', side_effect=[index, pages]):
                    docs.update('lua', catalog, data)
                roots.append(json.loads((data/'manifest.json').read_text())['docsets']['lua']['root'])
            self.assertEqual({str(p.relative_to(data)) for p in (data/'sets/lua').iterdir()}, set(roots[-2:]))
            manifest = (data/'manifest.json').read_bytes()
            with patch.object(docs, 'download', side_effect=[index, {}]):
                with self.assertRaises(ValueError): docs.update('lua', catalog, data)
            self.assertEqual((data/'manifest.json').read_bytes(), manifest)
            for root in roots[-2:]: self.assertTrue((data/root/'pages/manual.md').exists())
            outside = data/'external'
            outside.mkdir()
            (outside/'keep').write_text('never delete')
            (data/'sets/lua/100-aaaaaaaaaaaa').symlink_to(outside, target_is_directory=True)
            docs.prune_generations(data/'sets/lua', Path(roots[-1]).name, roots[-2])
            self.assertTrue((outside/'keep').exists())


if __name__ == '__main__': unittest.main()
