"""Five-run installed MiniPick/Snacks comparison with identical files and UI.

Uses /tmp fixture/cache/state and real picker APIs. Polling resolution is 2ms;
elapsed open/filter times include asynchronous finder and rendering readiness.
No external LSP server or physical keyboard latency is measured.
"""
import argparse, atexit, json, os, pathlib, select, shutil, statistics, subprocess, tempfile, time
import msgpack

parser = argparse.ArgumentParser()
parser.add_argument('--config', type=pathlib.Path, default=pathlib.Path(__file__).resolve().parents[1])
parser.add_argument('--output', type=pathlib.Path, default=pathlib.Path('/tmp/picker-comparison.json'))
parser.add_argument('--references-only', action='store_true', help='300 references, real picker adapters, mock LSP with 20ms delay')
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parents[2]
tmp = tempfile.TemporaryDirectory(prefix='picker-bench-')
atexit.register(tmp.cleanup)
fixture = pathlib.Path(tmp.name) / 'fixture'
fixture.mkdir()
for i in range(1000):
    (fixture / ('module_%04d.py' % i)).write_text('def benchmark_%04d():\n    return "needle_%04d"\n' % (i, i))
os.symlink(args.config.resolve(), pathlib.Path(tmp.name) / 'nvim')
env = dict(os.environ, XDG_CONFIG_HOME=tmp.name, XDG_CACHE_HOME=tmp.name+'/cache',
           XDG_STATE_HOME=tmp.name+'/state', TERM='xterm-256color')
exe = os.environ.get('NVIM_BIN') or shutil.which('nvim')
proc = subprocess.Popen([exe, '--embed', '--cmd', 'let g:station_1337 = v:false'],
                        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, env=env, cwd=root)
atexit.register(lambda: proc.terminate() if proc.poll() is None else None)
unpacker = msgpack.Unpacker(raw=False)
seq = 0
pending = {}

def rpc(method, params):
    global seq
    seq += 1
    proc.stdin.write(msgpack.packb([0, seq, method, params], use_bin_type=True)); proc.stdin.flush()
    deadline = time.monotonic()+20
    while seq not in pending and time.monotonic() < deadline:
        ready, _, _ = select.select([proc.stdout], [], [], .1)
        if ready:
            data = os.read(proc.stdout.fileno(), 65536)
            if not data: raise RuntimeError('Neovim exited')
            unpacker.feed(data)
            for msg in unpacker:
                if msg[0] == 1: pending[msg[1]] = msg
    reply = pending.pop(seq, None)
    if not reply: raise RuntimeError('RPC timeout: '+method)
    if reply[2]: raise RuntimeError(str(reply[2]))
    return reply[3]

def lua(code, values=None): return rpc('nvim_exec_lua', [code, values or []])
def wait(code, limit=5):
    deadline = time.monotonic()+limit
    while time.monotonic()<deadline:
        value = lua(code)
        if value: return value
        time.sleep(.002)
    raise RuntimeError('Readiness timeout: '+code)

rpc('nvim_ui_attach', [140, 42, {'rgb': True, 'ext_linegrid': True}])
time.sleep(.3)
lua("require('lazy').load({plugins={'mini.pick','mini.extra'}}); _G.pb_dir=...; "
    "local old={}; for i=0,19 do old[i+1]=pb_dir..string.format('/module_%04d.py',i); "
    "vim.fn.histadd(':','edit '..old[i+1]) end; vim.v.oldfiles=old; "
    "for i=0,4 do local b=vim.fn.bufadd(pb_dir..string.format('/module_%04d.py',i)); vim.bo[b].buflisted=true end", [str(fixture)])
result = {'scope': __doc__, 'cwd': str(root), 'config': str(args.config.resolve()),
          'files': 1000, 'ui': [140,42], 'runs': 5, 'metrics': {}, 'checks': {}, 'errors': []}
if args.references_only:
    lua("""
      vim.cmd('enew!'); vim.bo.filetype='picker_bench'; vim.api.nvim_buf_set_lines(0,0,-1,false,{'benchmark_symbol'})
      _G.pb_source_buf=vim.api.nvim_get_current_buf(); _G.pb_locations={}
      for i=0,299 do
        local uri=vim.uri_from_fname(pb_dir..string.format('/module_%04d.py',i))
        local range={start={line=0,character=0},['end']={line=0,character=3}}
        pb_locations[i+1]=i%2==0 and {uri=uri,range=range} or
          {targetUri=uri,targetRange=range,targetSelectionRange=range,originSelectionRange=range}
      end
      local closed=false; local serial=0
      _G.pb_client=vim.lsp.start({name='picker-bench',root_dir=pb_dir,
        cmd=function(dispatch)
          return {
            request=function(method,_,cb)
              serial=serial+1
              local response=method=='initialize' and {capabilities={referencesProvider=true,textDocumentSync=1}}
                or method=='textDocument/references' and pb_locations or nil
              vim.defer_fn(function() if not closed then cb(nil,response) end end,method=='initialize' and 0 or 20)
              return true,serial
            end,
            notify=function() return true end,
            is_closing=function() return closed end,
            terminate=function() closed=true; dispatch.on_exit(0,0) end,
          }
        end,
      },{bufnr=pb_source_buf})
      assert(vim.wait(2000,function() local c=vim.lsp.get_client_by_id(pb_client); return c and c.initialized end))
    """)
    result['scope']='300 references (150 Location + 150 LocationLink), actual MiniPick config adapter and Snacks LSP source; 20ms mock response delay included; five warm runs'
    result['references']=300
    result['provider_delay_ms']=20

def close(kind):
    if kind == 'mini':
        rpc('nvim_input', ['<Esc>'])
        wait("return not require('mini.pick').is_picker_active()")
    else: lua('if pb_picker then pb_picker:close(); pb_picker=nil end')

def ready(kind, minimum=1):
    if kind == 'mini':
        return wait("local p=require('mini.pick'); local items=p.get_picker_items(); "
                    "if p.is_picker_active() and items and #items>="+str(minimum)+" then return (vim.uv.hrtime()-pb_start)/1e6 end")
    return wait("if pb_picker and not pb_picker.finder:running() and not pb_picker.matcher:running() "
                "and pb_picker:count()>="+str(minimum)+" then return (vim.uv.hrtime()-pb_start)/1e6 end")

sources = ('references',) if args.references_only else ('files', 'grep', 'buffers', 'oldfiles', 'command_history', 'filter_1000', 'filter_20000')
for source in sources:
    result['metrics'][source] = {}
    for kind in ('mini', 'snacks'):
        samples = []
        try:
            for run in range(6):
                if source=='references':
                    lua('vim.api.nvim_set_current_buf(pb_source_buf); vim.api.nvim_win_set_cursor(0,{1,0})')
                n = 20000 if source == 'filter_20000' else 1000
                if source.startswith('filter'):
                    lua("pb_items={}; for i=1,... do pb_items[i]=string.format('module_%05d.py',i) end", [n])
                if kind == 'mini':
                    opening = ("require('mini.pick').start({source={items=pb_items,cwd=pb_dir}})" if source.startswith('filter')
                               else "require('config.pick').open(...,{cwd=pb_dir})")
                    lua("local source=...; pb_start=vim.uv.hrtime(); vim.schedule(function() " +
                        opening.replace('...', 'source') + " end)", [source])
                    if source == 'grep':
                        wait("return require('mini.pick').is_picker_active()")
                        lua("pb_start=vim.uv.hrtime(); require('mini.pick').set_picker_query(vim.split('needle_', ''))")
                        opened = ready(kind, 1000)
                    else:
                        opened = ready(kind, 300 if source=='references' else n if source.startswith('filter') or source == 'files' else 1)
                    if source.startswith('filter'):
                        lua("pb_start=vim.uv.hrtime(); require('mini.pick').set_picker_query(vim.split('module_00001', ''))")
                        opened = wait("local p=require('mini.pick'); local m=p.get_picker_matches(); "
                                      "if m and m.all and #m.all==1 then return (vim.uv.hrtime()-pb_start)/1e6 end")
                else:
                    src = {'oldfiles':'recent', 'command_history':'command_history','references':'lsp_references'}.get(source, source)
                    lua("local source=...; pb_start=vim.uv.hrtime(); "
                        "if source:find('filter_',1,true) then local items={}; for _,s in ipairs(pb_items) do "
                        "items[#items+1]={text=s,file=s} end; pb_picker=Snacks.picker({items=items,cwd=pb_dir}) "
                        "else pb_picker=Snacks.picker[source]({cwd=pb_dir,search=source=='grep' and 'needle_' or nil}) end", [src])
                    opened = ready(kind, 300 if source=='references' else n if source.startswith('filter') or source in ('files','grep') else 1)
                    if source.startswith('filter'):
                        lua("pb_start=vim.uv.hrtime(); pb_picker.input:set('module_00001'); pb_picker:find({refresh=false})")
                        opened = wait("if pb_picker and not pb_picker.matcher:running() and pb_picker.list:count()==1 "
                                      "then return (vim.uv.hrtime()-pb_start)/1e6 end")
                if run: samples.append(opened)
                close(kind)
            result['metrics'][source][kind] = {'runs_ms':samples, 'median_ms':statistics.median(samples)}
        except Exception as exc:
            result['errors'].append({'source':source,'picker':kind,'error':str(exc)})
            try: close(kind)
            except Exception: pass
for width,height in (() if args.references_only else ((80,24),(140,42))):
    rpc('nvim_ui_try_resize',[width,height])
    for kind in ('mini','snacks'):
        key=kind+'_'+str(width)
        try:
            if kind=='mini':
                lua("pb_start=vim.uv.hrtime(); vim.schedule(function() require('config.pick').open('files',{cwd=pb_dir}) end)")
                ready(kind,1000)
                rpc('nvim_input',['<C-x><C-n><C-x><Tab>']); time.sleep(.05)
                checked=lua("local p=require('mini.pick'); local s=p.get_picker_state(); local w=s.windows.main; "
                            "return {root=p.get_picker_opts().source.cwd,selected=#p.get_picker_matches().marked,"
                            "preview=s.buffers.preview~=nil and vim.api.nvim_win_get_buf(w)==s.buffers.preview,"
                            "width=vim.api.nvim_win_get_width(w),height=vim.api.nvim_win_get_height(w)}")
            else:
                lua("pb_start=vim.uv.hrtime(); pb_picker=Snacks.picker.files({cwd=pb_dir})")
                ready(kind,1000)
                checked=lua("pb_picker.list:select(pb_picker.list.items[1]); pb_picker.list:select(pb_picker.list.items[2]); "
                            "pb_picker:show_preview(); local p=pb_picker; return {root=p:cwd(),selected=#p:selected(),"
                            "preview=p.preview.win:valid(),width=p.list.win:size().width,height=p.list.win:size().height}")
            checked['fits']=checked['width']<=width and checked['height']<=height
            result['checks'][key]=checked
            close(kind)
        except Exception as exc:
            result['errors'].append({'check':key,'error':str(exc)})
            try: close(kind)
            except Exception: pass
result['messages'] = lua("return vim.api.nvim_exec2('messages',{output=true}).output")
args.output.write_text(json.dumps(result, indent=2)+'\n')
print(json.dumps(result, indent=2))
proc.terminate(); proc.wait(timeout=5)
