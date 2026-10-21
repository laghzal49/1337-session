"""Offline portability regression tests: no package installs, downloads or Neovim required."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class PortableInstallTests(unittest.TestCase):
    def setUp(self):
        self.sandbox = tempfile.TemporaryDirectory(prefix="1337-portable-")
        self.addCleanup(self.sandbox.cleanup)
        self.base = Path(self.sandbox.name)
        self.home = self.base / "home space"
        self.home.mkdir()
        self.config = self.base / "config with spaces"
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.config))

    def run_cmd(self, *args, expected=0):
        process = subprocess.run(args, cwd=ROOT, env=self.env,
                                 text=True, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, timeout=15)
        self.assertEqual(process.returncode, expected, process.stdout)
        return process.stdout

    def test_shell_syntax(self):
        for command in (
            ("bash", "-n", str(ROOT / "install.sh")),
            ("bash", "-n", str(ROOT / "scripts/install-macos.sh")),
            ("sh", "-n", str(ROOT / "scripts/link-config.sh")),
        ):
            self.run_cmd(*command)

    def test_config_only_is_safe_and_idempotent(self):
        old = self.config / "nvim"
        old.mkdir(parents=True)
        (old / "init.lua").write_text("an existing config\n")
        self.run_cmd("bash", str(ROOT / "install.sh"), "--config-only")
        self.assertTrue(old.is_symlink())
        self.assertEqual(old.resolve(), (ROOT / "nvim").resolve())
        backups = list(self.config.glob("nvim.bak.*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / "init.lua").read_text(), "an existing config\n")
        self.run_cmd("bash", str(ROOT / "install.sh"), "--config-only")
        self.assertEqual(len(list(self.config.glob("nvim.bak.*"))), 1)

    def test_foreign_and_dangling_symlinks_are_preserved(self):
        old = self.config / "nvim"
        self.config.mkdir()
        old.symlink_to(self.base / "missing target")
        self.run_cmd("bash", str(ROOT / "install.sh"), "--config-only")
        self.assertEqual(old.resolve(), (ROOT / "nvim").resolve())
        backups = list(self.config.glob("nvim.bak.*"))
        self.assertEqual(len(backups), 1)
        self.assertTrue(backups[0].is_symlink())
        self.assertEqual(os.readlink(backups[0]), str(self.base / "missing target"))

    def test_invalid_config_path_rejected(self):
        process = subprocess.run(("sh", str(ROOT / "scripts/link-config.sh"), "relative"),
                                 env=self.env, cwd=ROOT, capture_output=True,
                                 text=True, timeout=10)
        self.assertNotEqual(process.returncode, 0)
        self.assertFalse((self.config / "nvim").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
