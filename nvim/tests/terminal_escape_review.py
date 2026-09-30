"""Full-config attached-UI review of command suggestions and spatial panels."""
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


call("nvim_ui_attach", [100,30,{"rgb":True,"ext_linegrid":True}])
pump(1)
lua("vim.cmd.enew(); require('config.terminal').toggle()")
pump(.4)
assert lua("return vim.fn.mode()") == 't'
call('nvim_input', ['<Esc>'])
pump(.5)
assert lua("return vim.fn.mode()") == 't', 'single Esc must reach shell'
call('nvim_input', ['<Esc><Esc>'])
pump(.5)
assert lua("return vim.fn.mode()") == 'n', 'double Esc must leave terminal mode'
call('nvim_input', ['i'])
pump(.3)
assert lua("return vim.fn.mode()") == 't'
call('nvim_input', ['<C-t>'])
pump(.4)
assert lua("return vim.bo.buftype") != 'terminal'
assert lua("return vim.fn.mode()") == 'n'
print('Attached terminal: single Esc passes through; EscEsc leaves mode; C-t returns to code PASS')
lua("for _, t in ipairs(Snacks.terminal.list()) do t:close() end")
process.terminate()
