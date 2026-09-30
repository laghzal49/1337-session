"""Embedded UI batch benchmark; installed plugins/cache, no physical latency claims.

python3 nvim/tests/spatial_bench.py --config nvim --output /tmp/spatial.json
Lua hrtime measures each batch, including queued callbacks and explicit redraw,
excluding RPC transport. Scheduled callbacks are drained once at each batch end.
Panel numbers measure synchronous open/close work; asynchronous completion is not timed.
Synthetic unsaved buffers exclude LSP/server, disk and real Git work.
"""
import argparse
import atexit
import json
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
parser.add_argument('--config', type=Path, default=Path(__file__).resolve().parents[1])
parser.add_argument('--output', type=Path)
parser.add_argument('--runs', type=int, default=7)
parser.add_argument('--isolate-panels', action='store_true',
                    help='alternate spatial modules enabled/disabled in one process for warm panel costs')
args = parser.parse_args()
if not 1 <= args.runs <= 30:
    parser.error('--runs must be between 1 and 30')
config = args.config.resolve()
exe = os.environ.get('NVIM_BIN') or shutil.which('nvim')
if not exe:
    parser.error('set NVIM_BIN or install Neovim')
temp = tempfile.TemporaryDirectory(prefix='nvim-spatial-')
atexit.register(temp.cleanup)
env = dict(os.environ, TERM='xterm-256color', XDG_CONFIG_HOME=temp.name)
# Preserve installed plugin/data/cache locations while selecting any config snapshot.
os.symlink(config, Path(temp.name) / 'nvim', target_is_directory=True)
proc = subprocess.Popen(
    [exe, '--embed', '--cmd', 'let g:station_1337 = v:false'],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
    env=env, cwd=Path(__file__).resolve().parents[2],
)
atexit.register(lambda: proc.terminate() if proc.poll() is None else None)
unpacker = msgpack.Unpacker(raw=False)
seq = 0
responses = {}


def pump(seconds):
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        ready, _, _ = select.select([proc.stdout], [], [], max(0, end-time.monotonic()))
        if not ready:
            break
        data = os.read(proc.stdout.fileno(), 65536)
        if not data:
            raise RuntimeError('Neovim exited during benchmark')
        unpacker.feed(data)
        for msg in unpacker:
            if msg[0] == 1:
                responses[msg[1]] = msg
        if responses:
            break


def call(method, params):
    global seq
    seq += 1
    request = seq
    proc.stdin.write(msgpack.packb([0, request, method, params], use_bin_type=True))
    proc.stdin.flush()
    end = time.monotonic() + 30
    while request not in responses and time.monotonic() < end:
        pump(min(.1, max(0, end-time.monotonic())))
    msg = responses.pop(request, None)
    if not msg:
        raise RuntimeError('RPC timeout: ' + method)
    if msg[2]:
        raise RuntimeError(str(msg[2]))
    return msg[3]


def lua(code, params=None):
    return call('nvim_exec_lua', [code, params or []])


def sample(code, iterations):
    # Reset/setup belongs outside each timed batch. Warmup uses identical operation.
    wrapper = '''local n=...; local t=vim.uv.hrtime()
for i=1,n do %s end
local drained=false; vim.schedule(function() drained=true end)
assert(vim.wait(1000,function() return drained end,1), 'scheduled callback drain timed out')
vim.cmd.redraw()
return (vim.uv.hrtime()-t)/1e6''' % code
    lua(wrapper, [iterations])
    runs = [lua(wrapper, [iterations]) for _ in range(args.runs)]
    return {'iterations': iterations, 'runs_ms': runs, 'median_ms': statistics.median(runs),
            'median_per_operation_us': statistics.median(runs)*1000/iterations}


call('nvim_ui_attach', [140, 42, {'rgb': True, 'ext_linegrid': True}])
pump(1)
lua("vim.cmd('enew!'); vim.bo.buftype=''; vim.bo.bufhidden='hide'; "
    "vim.api.nvim_buf_set_name(0,'spatial-bench.lua'); "
    "local lines={}; for i=1,20000 do lines[i]='local value_'..i..' = '..i end; "
    "vim.api.nvim_buf_set_lines(0,0,-1,false,lines); vim.bo.filetype='spatial_bench'; "
    "vim.api.nvim_win_set_cursor(0,{10000,0}); _G.spatial_bench_buf=vim.api.nvim_get_current_buf()")
pump(.4)
result = {'scope': 'embedded UI Lua batches with queued callback drain and explicit redraw; synthetic unsaved 20k-line buffer; '
                   'no physical input/LSP/Git/disk latency claim; panels synchronous work only',
          'config': str(config), 'nvim': subprocess.check_output([exe, '--version'], text=True).splitlines()[0],
          'ui': [140, 42], 'lines': 20000, 'metrics': {}}
result['fixture'] = 'normal unsaved buffer, spatial_bench filetype (no parser or LSP), installed UI plugins'
metrics = result['metrics']
metrics['editing'] = sample("vim.api.nvim_buf_set_text(0,9999,0,9999,1,{i%2==0 and 'x' or 'l'})", 200)
metrics['hjkl'] = sample("vim.cmd.normal({args={'jhlk'},bang=true})", 1000)
metrics['scrolling'] = sample("vim.cmd.normal({args={i%2==0 and '10\\5' or '10\\25'},bang=true})", 100)
metrics['jump_list'] = sample("vim.cmd.normal({args={i%2==0 and '15000G' or '5000G'},bang=true})", 100)
metrics['mapped_jump_history'] = sample("vim.api.nvim_feedkeys(i%2==0 and '\\15' or '\\9','mx',false)", 100)
if lua("return package.loaded['config.cursor_ui'] ~= nil"):
    metrics['beacon_burst'] = sample("require('config.cursor_ui').flash()", 200)
    lua("require('config.cursor_ui').clear()")
lua("vim.cmd('vsplit'); _G.spatial_bench_wins=vim.api.nvim_list_wins()")
metrics['split_focus'] = sample("vim.api.nvim_set_current_win(spatial_bench_wins[(i%2)+1]); "
                                "local done=false; vim.schedule(function() done=true end); "
                                "assert(vim.wait(1000,function() return done end,1))", 200)
lua("vim.cmd('only!')")
metrics['cached_statusline_redraw'] = sample("vim.cmd('redrawstatus')", 200)
panels = [
    ('terminal', "require('config.terminal').toggle()",
     "for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].buftype=='terminal' then vim.api.nvim_win_close(w,true) end end"),
    ('aerial', "vim.cmd('AerialOpen right')", "vim.cmd('AerialClose')"),
    ('trouble', "vim.cmd('Trouble diagnostics open')", "vim.cmd('Trouble diagnostics close')"),
]
lua("local ns=vim.api.nvim_create_namespace('spatial_bench'); vim.diagnostic.set(ns,spatial_bench_buf,{{lnum=5,col=0,message='benchmark warning',severity=2}})")
if args.isolate_panels:
    result['scope'] = ('same-process alternating warm panel samples, spatial modules enabled/disabled; '
                       'queued callbacks plus redraw timed, delayed timers/server work excluded')
    result['metrics'] = {}
    configure = '''local enabled=...;
for _,name in ipairs({'cursor_ui','focus_ui','symbol_context'}) do
 local m=require('config.'..name); if enabled then m.setup() else m.cleanup() end
end
local done=false; vim.schedule(function() done=true end)
assert(vim.wait(1000,function() return done end,1))
vim.cmd.redraw()'''
    def timed_panel(code):
        return lua('''local t=vim.uv.hrtime(); local ok,err=pcall(function()
''' + code + '''
end)
local done=false; vim.schedule(function() done=true end)
assert(vim.wait(1000,function() return done end,1))
vim.cmd.redraw()
return {ms=(vim.uv.hrtime()-t)/1e6,ok=ok,error=not ok and tostring(err) or nil}''')

    for name, opening, closing in panels:
        # Load/warm the same plugins before either measured condition.
        lua(configure, [True])
        timed_panel(opening)
        pump(.25)
        timed_panel(closing)
        pump(.15)
        conditions = {state: {'open_ms': [], 'close_ms': [], 'errors': []}
                      for state in ('enabled', 'disabled')}
        for iteration in range(args.runs):
            order = ('enabled', 'disabled') if iteration % 2 == 0 else ('disabled', 'enabled')
            for state in order:
                lua(configure, [state == 'enabled'])
                pump(.05)
                opened = timed_panel(opening)
                pump(.25)
                closed = timed_panel(closing)
                pump(.15)
                lua('vim.api.nvim_set_current_buf(spatial_bench_buf)')
                conditions[state]['open_ms'].append(opened['ms'])
                conditions[state]['close_ms'].append(closed['ms'])
                for measured in (opened, closed):
                    if not measured['ok']:
                        conditions[state]['errors'].append(measured.get('error'))
        for condition in conditions.values():
            condition['open_median_ms'] = statistics.median(condition['open_ms'])
            condition['close_median_ms'] = statistics.median(condition['close_ms'])
        result['metrics'][name] = conditions
    lua(configure, [True])
    result['messages'] = lua("return vim.api.nvim_exec2('messages',{output=true}).output")
    rendered = json.dumps(result, indent=2)
    if args.output:
        args.output.write_text(rendered + '\n')
    print(rendered)
    proc.terminate()
    proc.wait(timeout=5)
    raise SystemExit(0)
for name, opening, closing in panels:
    runs = []
    close_runs = []
    errors = []
    for _ in range(args.runs):
        state = lua("local t=vim.uv.hrtime(); local ok,err=pcall(function() " + opening +
                    " end); vim.cmd.redraw(); return {ms=(vim.uv.hrtime()-t)/1e6,ok=ok,error=not ok and tostring(err) or nil}")
        pump(.25)
        closed = lua("local t=vim.uv.hrtime(); local ok,err=pcall(function() " + closing +
                     " end); vim.cmd.redraw(); local ms=(vim.uv.hrtime()-t)/1e6; "
                     "vim.api.nvim_set_current_buf(spatial_bench_buf); "
                     "return {ms=ms,ok=ok,error=not ok and tostring(err) or nil}")
        pump(.15)
        runs.append(state['ms'])
        close_runs.append(closed['ms'])
        if not state['ok']:
            errors.append(state.get('error'))
        if not closed['ok']:
            errors.append(closed.get('error'))
    metrics[name + '_open'] = {'first_ms': runs[0], 'runs_ms': runs,
                              'warm_median_ms': statistics.median(runs[1:] or runs), 'errors': errors}
    metrics[name + '_close'] = {'runs_ms': close_runs, 'median_ms': statistics.median(close_runs)}
result['messages'] = lua("return vim.api.nvim_exec2('messages',{output=true}).output")
rendered = json.dumps(result, indent=2)
if args.output:
    args.output.write_text(rendered + '\n')
print(rendered)
proc.terminate()
proc.wait(timeout=5)
