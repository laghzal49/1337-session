"""Bounded embedded-UI typing benchmark with real parsing/buffer completion.

NVIM_BIN=/path/to/nvim python3 nvim/tests/typing_bench.py --output /tmp/typing.json
Measures input-to-buffer-update plus explicit redraw roundtrip, including RPC
transport. No physical terminal/display latency or LSP/server claims. Installed
plugins/parsers and warm caches are retained. No tools are installed or updated.
"""
import argparse
import atexit
import json
import math
import os
from pathlib import Path
import select
import shutil
import statistics
import subprocess
import tempfile
import time

import msgpack

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
exe = os.environ.get('NVIM_BIN') or shutil.which('nvim')
if not exe:
    parser.error('install Neovim or set NVIM_BIN')
temp = tempfile.TemporaryDirectory(prefix='nvim-typing-')
atexit.register(temp.cleanup)
env = dict(os.environ, XDG_CONFIG_HOME=str(root), XDG_STATE_HOME=temp.name,
           TERM='xterm-256color', NVIM_BLACK_DOCS_AUTO_UPDATE='0')
proc = subprocess.Popen([exe, '--embed', '--cmd', 'let g:station_1337 = v:false'],
                        cwd=root, env=env, stdin=subprocess.PIPE,
                        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
atexit.register(lambda: proc.terminate() if proc.poll() is None else None)
unpacker = msgpack.Unpacker(raw=False)
responses = {}
serial = 0


def pump(seconds):
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        readable, _, _ = select.select([proc.stdout], [], [], max(0, end - time.monotonic()))
        if not readable:
            break
        data = os.read(proc.stdout.fileno(), 65536)
        if not data:
            raise RuntimeError('Neovim exited during typing benchmark')
        unpacker.feed(data)
        for message in unpacker:
            if message[0] == 1:
                responses[message[1]] = message
        if responses:
            break


def call(method, params):
    global serial
    serial += 1
    request = serial
    proc.stdin.write(msgpack.packb([0, request, method, params], use_bin_type=True))
    proc.stdin.flush()
    deadline = time.monotonic() + 10
    while request not in responses and time.monotonic() < deadline:
        pump(.01)
    response = responses.pop(request, None)
    if not response or response[2]:
        raise RuntimeError(str(response))
    return response[3]


def lua(code, values=None):
    return call('nvim_exec_lua', [code, values or []])


call('nvim_ui_attach', [120, 38, {'rgb': True, 'ext_linegrid': True}])
pump(.5)
lua("require('lazy').load({plugins={'nvim-lspconfig'}}); "
    "for _,name in ipairs({'clangd','ty','ruff','lua_ls','jsonls'}) do vim.lsp.enable(name,false) end")
results = {'scope': __doc__.strip(), 'nvim': subprocess.check_output([exe, '--version'], text=True).splitlines()[0],
           'ui': [120, 38], 'lsp': 'disabled to isolate editing/UI/buffer completion', 'fixtures': {}}
results['initial_last_error'] = lua('return vim.v.errmsg')
fixtures = {
    'lua': ('lua', ['local bench_symbol_%04d = %d' % (i, i) for i in range(2000)], '-- '),
    'c': ('c', ['int bench_symbol_%04d = %d;' % (i, i) for i in range(2000)], '// '),
    'markdown': ('md', ['# Typing benchmark', ''] + ['- bench_symbol_%04d: notes' % i for i in range(2000)], ''),
    'large_lua': ('lua', ['local bench_symbol_%05d = %d' % (i, i) for i in range(22000)], '-- '),
}
for name, (extension, lines, prefix) in fixtures.items():
    path = Path(temp.name) / (name + '.' + extension)
    path.write_text('\n'.join(lines + [prefix]) + '\n')
    call('nvim_command', ['edit! ' + str(path)])
    pump(.4)
    lua('vim.api.nvim_win_set_cursor(0,{vim.api.nvim_buf_line_count(0),0})')
    call('nvim_input', ['A'])
    pump(.15)
    state = lua("return {lines=vim.api.nvim_buf_line_count(0),guard=vim.b.performance_guard==true,"
                "parser=vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()]~=nil,"
                "completion=require('blink.cmp.config').enabled(),lsp_clients=#vim.lsp.get_clients({bufnr=0})}")
    assert state['lsp_clients'] == 0, 'unexpected LSP client in isolated benchmark'
    if name == 'large_lua':
        assert state['guard'] and not state['parser'] and not state['completion'], 'large-file safeguards failed'
    samples = []
    expected = prefix
    for character in 'bench_symbol_interactive_typing':
        started = time.perf_counter()
        call('nvim_input', [character])
        expected += character
        deadline = time.monotonic() + 5
        while lua('return vim.api.nvim_buf_get_lines(0,-2,-1,false)[1]') != expected:
            if time.monotonic() > deadline:
                raise RuntimeError('buffer update timed out: ' + name)
            pump(.001)
        lua('vim.cmd.redraw()')
        samples.append((time.perf_counter() - started) * 1000)
        pump(.02)  # A bounded 50 Hz input cadence; excluded from the sample.
    call('nvim_input', ['<Esc>'])
    pump(.1)
    ordered = sorted(samples)
    state.update(samples_ms=samples, keys=len(samples), first_key_ms=samples[0],
                 median_ms=statistics.median(samples), p95_ms=ordered[math.ceil(len(samples)*.95)-1],
                 max_ms=max(samples))
    results['fixtures'][name] = state
results['errors'] = lua('return vim.v.errors')
results['last_error'] = lua('return vim.v.errmsg')
rendered = json.dumps(results, indent=2)
if args.output:
    args.output.write_text(rendered + '\n')
print(rendered)
proc.terminate()
proc.wait(timeout=5)
