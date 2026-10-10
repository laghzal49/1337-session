"""Strict, fresh-process regression runner; no tool installation or downloads."""
import argparse
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
DEFAULT = [
    'project_review.lua', 'redesign_review.lua', 'editor_titles_review.lua',
    'dashboard_review.lua', 'statusline_safety_review.lua', 'station_venv_review.lua',
    'plugins_audit.lua', 'performance_review.lua',
    'tasks_workspace_review.lua', 'tasks_lifecycle_review.lua', 'debugging_review.lua',
]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('tests', nargs='*', help='Lua test filenames (defaults to upgrade regressions)')
parser.add_argument('--timeout', type=float, default=90, help='maximum seconds per fresh process')
args = parser.parse_args()
exe = os.environ.get('NVIM_BIN') or shutil.which('nvim')
if not exe:
    parser.error('Neovim is required; set NVIM_BIN')
def run_bounded(command, env):
    # Killing only Neovim leaves debug adapters/task children running after a
    # timeout. Give each test a private process group and clean up all of it.
    with subprocess.Popen(command, cwd=ROOT, env=env, text=True,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          start_new_session=True) as process:
        try:
            output, _ = process.communicate(timeout=args.timeout)
            return subprocess.CompletedProcess(command, process.returncode, output)
        finally:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait()

failed = []
for name in args.tests or DEFAULT:
    path = Path(name)
    if not path.is_absolute():
        path = ROOT / 'nvim' / 'tests' / path
    env = dict(os.environ, NVIM_APPNAME='nvim', XDG_CONFIG_HOME=str(ROOT), NVIM_BLACK_DOCS_AUTO_UPDATE='0',
               NVIM_SMOKE_TEST=str(path), NVIM_SMOKE_RUNNER=str(ROOT / 'nvim/tests/strict.lua'))
    try:
        result = run_bounded([exe, '--headless', '-c', 'lua dofile(vim.env.NVIM_SMOKE_RUNNER)'], env)
        passed = result.returncode == 0 and 'STRICT SMOKE PASS: ' + str(path) in result.stdout
        print(result.stdout.strip(), flush=True)
        if not passed:
            failed.append(name)
            print(f'FAIL {name}: process exit {result.returncode}', flush=True)
    except (subprocess.TimeoutExpired, OSError) as err:
        failed.append(name)
        print(f'FAIL {name}: {err}', flush=True)
if failed:
    print('Failed: ' + ', '.join(failed), file=sys.stderr)
    sys.exit(1)
print(f'SMOKE PASS: {len(args.tests or DEFAULT)} fresh-process tests')
