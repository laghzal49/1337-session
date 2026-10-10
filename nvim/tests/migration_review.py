"""Verify backup-preserving environment migration using disposable real venvs."""
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('migrate_venv', ROOT / 'nvim/scripts/migrate_venv.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class MigrationReview(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory(prefix='venv migration % ')
        self.addCleanup(self.folder.cleanup)
        self.root = Path(self.folder.name)
        self.source = self.root / 'project' / '.venv'
        subprocess.run([sys.executable, '-m', 'venv', '--without-pip', str(self.source)], check=True)
        (self.source / 'keep.txt').write_text('original data')
        self.target = self.root / 'local' / 'venvs' / 'project-hash'

    def test_real_venv_and_original_backup(self):
        state = module.migrate(self.source, self.target)
        self.assertTrue(self.source.is_symlink())
        self.assertEqual((Path(state['backup']) / 'keep.txt').read_text(), 'original data')
        self.assertEqual((self.target / 'keep.txt').read_text(), 'original data')
        result = subprocess.run([str(self.source / 'bin/python'), '-c', 'import sys;print(sys.prefix)'],
                                check=True, capture_output=True, text=True)
        self.assertEqual(Path(result.stdout.strip()), self.source)

    def test_existing_destination_untouched(self):
        self.target.mkdir(parents=True)
        (self.target / 'existing').write_text('keep')
        with self.assertRaises(ValueError):
            module.migrate(self.source, self.target)
        self.assertFalse(self.source.is_symlink())
        self.assertEqual((self.target / 'existing').read_text(), 'keep')

    def test_publication_failure_rolls_back_source(self):
        with patch.object(Path, 'symlink_to', side_effect=OSError('publication failed')):
            with self.assertRaises(OSError):
                module.migrate(self.source, self.target)
        self.assertFalse(self.source.is_symlink())
        self.assertEqual((self.source / 'keep.txt').read_text(), 'original data')
        self.assertTrue((self.target / 'keep.txt').exists())
        self.assertFalse(self.source.with_name('.venv.migration.lock').exists())

    def test_symlink_source_refused(self):
        original = self.source.with_name('original')
        self.source.rename(original)
        self.source.symlink_to(original)
        with self.assertRaises(ValueError):
            module.migrate(self.source, self.target)
        self.assertEqual(os.readlink(self.source), str(original))

    def test_concurrent_migration_refused(self):
        lock = self.source.with_name('.venv.migration.lock')
        lock.write_text('busy')
        with self.assertRaises(FileExistsError):
            module.migrate(self.source, self.target)
        self.assertEqual((self.source / 'keep.txt').read_text(), 'original data')
        self.assertEqual(lock.read_text(), 'busy')


if __name__ == '__main__':
    unittest.main()
