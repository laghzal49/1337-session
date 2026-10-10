"""Verify strict timeouts stop a test's subprocesses, using disposable sleep fixtures."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='strict-runner-review-') as folder:
    fixture = Path(folder)
    test = fixture / 'timeout.lua'
    pidfile = fixture / 'child.pid'
    test.write_text('vim.system({"sh", "-c", \'echo $$ > "$1"; exec sleep 20\', "fixture", '
                    + json.dumps(str(pidfile)) + '}); while true do vim.wait(100) end')
    child = None
    try:
        started = time.monotonic()
        result = subprocess.run([sys.executable, str(ROOT/'nvim/tests/smoke.py'), '--timeout', '1', str(test)],
                                env=os.environ, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=5)
        assert result.returncode != 0 and 'timed out' in result.stdout, result.stdout
        assert time.monotonic() - started < 5, 'timeout cleanup exceeded its bound'
        assert pidfile.exists(), 'child fixture never started'
        child = int(pidfile.read_text())
        status = Path(f'/proc/{child}/stat')
        assert not status.exists() or status.read_text().split(') ', 1)[1].startswith('Z'), 'test child survived timeout'
        print('RUNNER REVIEW PASS: failed test timeout is bounded and child process stopped')
    finally:
        if child:
            try:
                os.kill(child, signal.SIGKILL)
            except ProcessLookupError:
                pass
