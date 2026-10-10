"""Exercise installer failure propagation without installing or downloading anything."""
import os
from pathlib import Path
import shutil
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
EXE = os.environ.get('NVIM_BIN') or shutil.which('nvim')
assert EXE, 'Set NVIM_BIN to Neovim 0.11 or newer'
with tempfile.TemporaryDirectory(prefix='nvim-installer-review-') as folder:
    fixture = Path(folder)
    init = fixture / 'init.lua'
    script = ROOT / 'scripts/nvim-bootstrap.lua'

    def check(name, setup, mode, passed):
        init.write_text(setup)
        env = dict(os.environ, NVIM_BOOTSTRAP_MODE=mode, NVIM_BOOTSTRAP_SCRIPT=str(script))
        result = subprocess.run([EXE, '--headless', '-u', str(init), '-c',
                                 'lua dofile(vim.env.NVIM_BOOTSTRAP_SCRIPT)'], env=env,
                                text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=10)
        sentinel = 'BOOTSTRAP PASS: ' + mode
        assert (result.returncode == 0) == passed, (name, result.returncode, result.stdout)
        assert (sentinel in result.stdout) == passed, (name, result.stdout)
        print('INSTALLER CHECK PASS:', name)

    plugin = "package.preload['lazy']=function() return {restore=function() end} end\n"
    good_config = "package.preload['lazy.core.config']=function() return {plugins={fixture={dir=" + repr(folder) + ",_={tasks={}}}}} end\n"
    check('completed plugin restore', plugin + good_config, 'plugins', True)
    bad_task = "package.preload['lazy.core.config']=function() return {plugins={fixture={dir=" + repr(folder) + ",_={tasks={{has_errors=function() return true end,output=function() return 'fetch failed' end}}}}}} end\n"
    check('failed Lazy task rejects success', plugin + bad_task, 'plugins', False)
    check('startup Lua error rejects exit-zero behavior', "error('startup fixture error')", 'plugins', False)
    parser = "package.preload['nvim-treesitter']=function() return {install=function() return {wait=function() end} end} end\n"
    check('missing parser rejects installer success', parser + "vim.treesitter.language.add=function() return false end", 'parsers', False)
    check('loadable parsers confirmed', parser + "vim.treesitter.language.add=function() return true end", 'parsers', True)
    check('unknown installer phase rejected', '', 'unexpected', False)
    # An intentional failed assertion must also make the regression runner fail.
    failure = fixture / 'failure.lua'
    failure.write_text("assert(false, 'intentional assertion fixture')")
    env = dict(os.environ, NVIM_SMOKE_TEST=str(failure), NVIM_SMOKE_RUNNER=str(ROOT/'nvim/tests/strict.lua'))
    result = subprocess.run([EXE, '--headless', '-u', 'NONE', '-c', 'lua dofile(vim.env.NVIM_SMOKE_RUNNER)'],
                            env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=10)
    assert result.returncode != 0 and 'STRICT SMOKE PASS:' not in result.stdout, result.stdout
    print('STRICT RUNNER CHECK PASS: failed assertion exits nonzero')

    failure.write_text("vim.schedule(function() error('intentional async fixture') end)")
    result = subprocess.run([EXE, '--headless', '-u', 'NONE', '-c', 'lua dofile(vim.env.NVIM_SMOKE_RUNNER)'],
                            env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=10)
    assert result.returncode != 0 and 'STRICT SMOKE PASS:' not in result.stdout, result.stdout
    print('STRICT RUNNER CHECK PASS: scheduled callback errors exit nonzero')

    # Execute the installer's real phase helper against a fake executable. An
    # inherited custom app name must not restore another Neovim configuration.
    fake_bin = fixture / 'bin'
    fake_bin.mkdir()
    fake_nvim = fake_bin / 'nvim'
    fake_nvim.write_text('#!/usr/bin/env bash\n[ "$NVIM_APPNAME" = nvim ] || exit 3\n'
                         '[ "$XDG_CONFIG_HOME" = "$HOME/.config" ] || exit 4\n'
                         'echo "BOOTSTRAP PASS: $NVIM_BOOTSTRAP_MODE"\n')
    fake_nvim.chmod(0o755)
    installer = (ROOT/'install.sh').read_text()
    helper = installer[installer.index('  run_nvim_phase() {'):installer.index('  if run_nvim_phase plugins; then')]
    setup = 'TMP=' + shlex.quote(folder) + '; REPO_DIR=' + shlex.quote(str(ROOT)) + '; have() { return 1; };\n'
    result = subprocess.run(['bash', '-c', setup + helper + '\nrun_nvim_phase plugins'],
                            env=dict(os.environ, NVIM_APPNAME='unrelated-config', PATH=str(fake_bin)+os.pathsep+os.environ['PATH']),
                            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=10)
    assert result.returncode == 0, result.stdout
    print('INSTALLER CHECK PASS: inherited app name cannot redirect plugin restore')
