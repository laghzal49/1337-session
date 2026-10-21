"""Kill an editor after swap preservation, then recover its unsaved text."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

root = Path(__file__).resolve().parents[2]
exe = os.environ.get('NVIM_BIN', 'nvim')
with tempfile.TemporaryDirectory(prefix='nvim recovery ') as directory:
    temp = Path(directory)
    env = dict(os.environ, XDG_STATE_HOME=str(temp / 'state'),
               XDG_DATA_HOME=str(temp / 'data'), XDG_CACHE_HOME=str(temp / 'cache'))
    init = temp / 'init.lua'
    init.write_text('vim.opt.rtp:prepend(' + json.dumps(str(root / 'nvim')) + ')\n'
                    "require('config.options')\n")
    target = temp / 'work.py'
    target.write_text('original saved text\n')
    marker = temp / 'ready'
    script = ("vim.api.nvim_buf_set_lines(0, 0, -1, false, {'unsaved recovery fixture'}); "
              "vim.cmd.preserve(); assert(vim.fn.swapname('') ~= ''); "
              "vim.fn.writefile({vim.fn.swapname('')}, " + json.dumps(str(marker)) + ')')
    child = subprocess.Popen([exe, '--headless', '-u', str(init), str(target), '-c', 'lua ' + script],
                             env=env, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    try:
        deadline = time.monotonic() + 5
        while not marker.exists() and time.monotonic() < deadline and child.poll() is None:
            time.sleep(0.02)
        assert marker.exists(), 'editor did not preserve swap'
        swap = Path(marker.read_text().strip())
        assert swap.is_file() and swap.is_relative_to(temp / 'state'), swap
    finally:
        child.kill()
        child.communicate(timeout=5)
    assert target.read_text() == 'original saved text\n', 'test accidentally saved the file'
    result = subprocess.run([exe, '--headless', '-u', str(init), '-r', str(target), '-c',
        "lua if vim.api.nvim_get_current_line() ~= 'unsaved recovery fixture' then vim.cmd('cquit 1') end",
        '-c', 'qa!'], env=env, capture_output=True, text=True, timeout=10)
    assert result.returncode == 0, result.stderr
print('RECOVERY PASS: unsaved text recovered after forcibly terminating Neovim')
