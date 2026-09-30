"""Measure guarded 12k-line Markdown movement/redraw and verify small-file editing.

Run with installed plugins and writable XDG cache/state. Updates markdown_results.json.
"""
import atexit
import os
from pathlib import Path
import select
import shutil
import subprocess
import time

import msgpack

root = Path(__file__).resolve().parents[2]
env = dict(os.environ, XDG_CONFIG_HOME=str(root), TERM="xterm-256color")
exe = os.environ.get("NVIM_BIN") or shutil.which("nvim")
if not exe:
    raise SystemExit("Neovim is required; set NVIM_BIN.")
process = subprocess.Popen([exe, "--embed"], cwd=root, env=env,
                           stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                           stderr=subprocess.DEVNULL)
atexit.register(lambda: process.terminate() if process.poll() is None else None)
unpacker = msgpack.Unpacker(raw=False)
pending = {}
serial = 0


def pump(seconds=0.2):
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        ready, _, _ = select.select([process.stdout], [], [], max(0, end - time.monotonic()))
        if not ready:
            break
        data = os.read(process.stdout.fileno(), 65536)
        if not data:
            break
        unpacker.feed(data)
        for message in unpacker:
            if message[0] == 1:
                pending[message[1]] = message


def call(method, args):
    global serial
    serial += 1
    request = serial
    process.stdin.write(msgpack.packb([0, request, method, args], use_bin_type=True))
    process.stdin.flush()
    deadline = time.monotonic() + 15
    while request not in pending and time.monotonic() < deadline:
        pump(0.005)
    result = pending.pop(request, None)
    assert result is not None, "RPC timeout: " + method
    assert result[2] is None, result[2]
    return result[3]


def lua(code, *args):
    return call("nvim_exec_lua", [code, list(args)])


call("nvim_ui_attach", [140,42,{"rgb":True,"ext_linegrid":True}])
pump(1)
import json
lua("vim.cmd.enew(); vim.bo.modifiable=true")
print(lua('''local lines={}; for i=1,1500 do vim.list_extend(lines, {"## Heading "..i, "A paragraph with **bold** and `inline` text, [link](https://example.com).", "- List one", "- List two", "", "```python", "def fn(x): return x + 1", "```"}) end; vim.api.nvim_buf_set_lines(0,0,-1,false,lines); vim.bo.filetype='markdown'; return #lines'''))
pump(1)
samples=lua("local times={}; for j=1,7 do local t=vim.uv.hrtime(); for i=1,100 do vim.cmd('normal! j'); vim.cmd.redraw(); end; times[j]=(vim.uv.hrtime()-t)/1e6 end; return times")
print('after_guard_ms', samples, flush=True)
path=root/'nvim/tests/markdown_results.json'
data=json.loads(path.read_text())
data['after_guard_ms']=samples
data['after_guard_conditions']='Same 12000-line fixture with configured 5000-line/512KiB automatic rendering/highlighting/context guard; seven 100-move+redraw samples. Separate fresh process.'
path.write_text(json.dumps(data,indent=2)+'\n')
lua("vim.cmd.enew(); vim.api.nvim_buf_set_lines(0,0,-1,false,{'# Small document','','Paragraph **bold** and `code`.','','```python','def fn(x): return x','```'}); vim.bo.filetype='markdown'")
pump(.5)
assert lua("return not require('config.markdown').large(0) and vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil")
lua("vim.api.nvim_buf_set_text(0,2,0,2,0,{'Edited '})")
pump(.3)
assert lua("return vim.api.nvim_buf_get_lines(0,2,3,false)[1]:sub(1,7) == 'Edited '")
print('Small Markdown keeps highlighting and accepts edits PASS')
process.terminate()
