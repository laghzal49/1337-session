"""Matched startup/idle memory benchmark for BLACKDECK and SmartDocs.
Five warm runs, existing installed plugin data, same repo cwd, /tmp cache/state.
NVIM_BLACK_DOCS_AUTO_UPDATE=0 prevents benchmark-triggered network requests.
"""
import argparse,atexit,json,os,pathlib,re,select,shutil,statistics,subprocess,tempfile,time
import msgpack
parser=argparse.ArgumentParser()
parser.add_argument('--config',type=pathlib.Path,default=pathlib.Path(__file__).resolve().parents[1])
parser.add_argument('--output',type=pathlib.Path,default=pathlib.Path('/tmp/black-system-after.json'))
parser.add_argument('--startup-only',action='store_true')
parser.add_argument('--runtime-only',action='store_true')
parser.add_argument('--data',type=pathlib.Path,help='actual offline store for page timings')
args=parser.parse_args();root=pathlib.Path(__file__).resolve().parents[2]
tmp=tempfile.TemporaryDirectory(prefix='black-system-bench-');atexit.register(tmp.cleanup)
pathlib.Path(tmp.name,'nvim').symlink_to(args.config.resolve(),target_is_directory=True)
env=dict(os.environ,XDG_CONFIG_HOME=tmp.name,XDG_CACHE_HOME=tmp.name+'/cache',XDG_STATE_HOME=tmp.name+'/state',TERM='xterm-256color',NVIM_BLACK_DOCS_AUTO_UPDATE='0')
exe=os.environ.get('NVIM_BIN') or shutil.which('nvim')
result={'scope':__doc__,'cwd':str(root),'config':str(args.config.resolve()),'auto_update':False,'runs':5,'startup_ms':[],'metrics':{},'errors':[]}
for i in range(0 if args.runtime_only else 6):
    log=pathlib.Path(tmp.name,'startup.log')
    run=subprocess.run([exe,'--headless','--cmd','let g:station_1337 = v:false','--startuptime',str(log),'+qa!'],env=env,cwd=root,capture_output=True,text=True,timeout=30)
    matches=[float(m[1]) for line in log.read_text().splitlines() if (m:=re.match(r'^(\d+\.\d+).*NVIM STARTED',line))];log.unlink()
    if run.returncode or re.search(r'Error in |Failed to load |E\d+:',run.stderr):result['errors'].append(run.stderr)
    if not matches:raise RuntimeError('No startup marker')
    if i:result['startup_ms'].append(matches[-1])
    else:result['startup_first_ms']=matches[-1]
if result['startup_ms']:result['startup_median_ms']=statistics.median(result['startup_ms'])
p=subprocess.Popen([exe,'--embed','--cmd','let g:station_1337 = v:false'],env=env,cwd=root,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL)
atexit.register(lambda:(p.terminate(),p.wait(timeout=5)) if p.poll() is None else None)
u=msgpack.Unpacker(raw=False);pending={};seq=0
def rpc(method,params):
    global seq
    seq+=1;p.stdin.write(msgpack.packb([0,seq,method,params],use_bin_type=True));p.stdin.flush();deadline=time.monotonic()+15
    while seq not in pending and time.monotonic()<deadline:
        ready,_,_=select.select([p.stdout],[],[],.1)
        if ready:
            data=os.read(p.stdout.fileno(),65536)
            if not data:raise RuntimeError('Neovim exited')
            u.feed(data)
            for msg in u:
                if msg[0]==1:pending[msg[1]]=msg
    reply=pending.pop(seq,None)
    if not reply or reply[2]:raise RuntimeError(str(reply))
    return reply[3]
def lua(code,values=None):return rpc('nvim_exec_lua',[code,values or []])
def wait(code):
    deadline=time.monotonic()+5
    while time.monotonic()<deadline:
        value=lua(code)
        if value:return value
        time.sleep(.002)
    raise RuntimeError('readiness timeout')
def memory():
    rss=next((line.split()[1] for line in pathlib.Path('/proc',str(p.pid),'status').read_text().splitlines() if line.startswith('VmRSS:')),None)
    result={'rss_kib':int(rss) if rss else None,'lua_gc_kib':lua("return collectgarbage('count')")}
    result['live_lua_gc_kib']=lua("collectgarbage('collect');return collectgarbage('count')")
    return result
rpc('nvim_ui_attach',[140,42,{'rgb':True,'ext_linegrid':True}]);time.sleep(.25)
result['idle_memory']=memory()
result['modules_at_idle']=lua("return {smart_docs=package.loaded['config.smart_docs']~=nil,docs_store=package.loaded['config.docs_store']~=nil,deep_docs=package.loaded['config.deep_docs']~=nil,devdocs=package.loaded.devdocs~=nil,telescope=package.loaded.telescope~=nil}")
if not args.startup_only:
    entries=[{'name':'fixture_%05d'%i,'path':'fixture','type':'Function'} for i in range(20000)]
    fixture=pathlib.Path(tmp.name,'fixture');legacy=fixture/'legacy'/'python~3.14';custom=fixture/'custom';generation=custom/'sets'/'python'/'fixture'
    for directory in (legacy/'pages-md',generation/'pages'):directory.mkdir(parents=True)
    page='# fixture_00001\n\n```python\ndef fixture_00001():\n    return 1\n```\n\nA local offline reference.\n'
    (legacy/'index.json').write_text(json.dumps({'entries':entries}))
    (legacy/'pages-md'/'fixture.md').write_text(page)
    (generation/'pages'/'fixture.md').write_text(page)
    (generation/'index.json').write_text(json.dumps({'entries':entries,'exact':{e['name']:i+1 for i,e in enumerate(entries)},'suffix':{}}))
    (custom/'manifest.json').write_text(json.dumps({'schema':1,'docsets':{'python':{'slug':'python~3.14','lang':'python','root':'sets/python/fixture','entries':20000,'pages':1,'bytes':len(page),'updated_at':0}}}))
    modern=lua("return vim.fn.filereadable(vim.fn.stdpath('config')..'/lua/config/smart_docs.lua')==1")
    result['backend']='custom' if modern else 'devdocs'
    lua("vim.lsp.enable('ty',false); vim.lsp.enable('pyright',false); vim.cmd('enew!'); vim.bo.filetype='python'; "
        "vim.api.nvim_buf_set_lines(0,0,-1,false,{'fixture_00001'}); vim.api.nvim_win_set_cursor(0,{1,0}); _G.bs_source=vim.api.nvim_get_current_buf()")
    if modern:
        lua("require('config.docs_store').setup({data_dir=...})",[str(custom)])
    else:
        lua("require('config.deep_docs').setup({data_dir=...,manual_dirs={},notes_dirs={}})",[str(fixture/'legacy')])
    lua(r"""
      _G.bs_requests=0; local closed=false;local serial=0
      _G.bs_client=vim.lsp.start({name='black-system-bench',root_dir=vim.fn.getcwd(),
        cmd=function(dispatch)
          return {request=function(method,_,cb)
            serial=serial+1
            if method=='textDocument/hover' then bs_requests=bs_requests+1 end
            local response=method=='initialize' and {capabilities={hoverProvider=true,textDocumentSync=1}}
              or method=='textDocument/hover' and {contents={kind='markdown',value='# Mock semantic hover\n\n```python\ndef mock_symbol(): pass\n```\n\nInjected 20ms response.'}} or nil
            vim.defer_fn(function() if not closed then cb(nil,response) end end,method=='initialize' and 0 or 20)
            return true,serial
          end,notify=function() return true end,is_closing=function() return closed end,
            terminate=function() closed=true;dispatch.on_exit(0,0) end}
        end},{bufnr=bs_source})
      assert(vim.wait(2000,function() local c=vim.lsp.get_client_by_id(bs_client);return c and c.initialized end))
    """)
    def reset(word):
        rpc('nvim_input',['<Esc>'])
        lua("local word=...; for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.api.nvim_win_get_config(w).relative~='' then vim.api.nvim_win_close(w,true) end end; "
            "vim.api.nvim_set_current_buf(bs_source);vim.api.nvim_buf_set_lines(bs_source,0,-1,false,{word});vim.api.nvim_win_set_cursor(0,{1,0})",[word])
    def ready_doc():
        return wait("for _,w in ipairs(vim.api.nvim_list_wins()) do local b=vim.api.nvim_win_get_buf(w); if vim.api.nvim_win_get_config(w).relative~='' and vim.bo[b].filetype=='markdown' then "
                    "return {ms=(vim.uv.hrtime()-bs_start)/1e6,lines=vim.api.nvim_buf_line_count(b),offline=vim.b[b].devdocs~=nil or vim.b[b].black_docs~=nil,requests=bs_requests} end end")
    for name,key,word in [('K_offline_with_LSP','K','fixture_00001'),('K_offline_miss_hover','K','missing_fixture_qualified')]:
        samples=[];states=[]
        for i in range(6):
            reset(word);lua('bs_requests=0;bs_start=vim.uv.hrtime()');rpc('nvim_input',[key]);state=ready_doc()
            if i:samples.append(state['ms']);states.append(state)
            else:result['metrics'][name+'_first_ms']=state['ms']
        result['metrics'][name]={'runs_ms':samples,'median_ms':statistics.median(samples),'states':states}
    lua('vim.lsp.get_client_by_id(bs_client):stop(true)');time.sleep(.02)
    for name,key in [('gK_no_LSP','gK')]+([('K_no_LSP','K')] if modern else []):
        samples=[];states=[]
        for i in range(6):
            reset('fixture_00001');lua('bs_requests=0;bs_start=vim.uv.hrtime()');rpc('nvim_input',[key]);state=ready_doc()
            if i:samples.append(state['ms']);states.append(state)
            else:result['metrics'][name+'_first_ms']=state['ms']
        result['metrics'][name]={'runs_ms':samples,'median_ms':statistics.median(samples),'states':states}
    if not modern:result['metrics']['K_no_LSP']={'outcome':'baseline K has no generic offline lookup; benchmark omitted rather than treating a notice as a page'}
    samples=[]
    for i in range(6):
        reset('fixture_00001')
        lua("local command=...;bs_start=vim.uv.hrtime();vim.schedule(function() vim.cmd(command..' python fixture_00001') end)",['DocsBrowse' if modern else 'Devdocs'])
        state=wait("local m=require('mini.pick').get_picker_matches();if m and m.all and #m.all==1 then return (vim.uv.hrtime()-bs_start)/1e6 end")
        if i:samples.append(state)
        else:result['metrics']['fuzzy_20000_first_ms']=state
        rpc('nvim_input',['<Esc>']);wait("return not require('mini.pick').is_picker_active()")
    result['metrics']['fuzzy_20000']={'runs_ms':samples,'median_ms':statistics.median(samples)}
    result['memory_after_fixture']=memory()
    if args.data:
        data=args.data.resolve();result['actual_data']=str(data)
        if modern:lua("require('config.docs_store').setup({data_dir=...})",[str(data)])
        else:lua("require('config.deep_docs').setup({data_dir=...,manual_dirs={},notes_dirs={}})",[str(data)])
        module='config.docs_store' if modern else 'devdocs.data'
        result['actual_indices_preloaded']=lua("local s=require(...); local names=s.installed(); for _,name in ipairs(names)do assert(s.load_index(name),'invalid actual index: '..name)end; "
                                               "for _,case in ipairs({{'python','pathlib.Path.exists'},{'lua','string.format'},{'c','malloc'}})do assert(s.find_entry(case[1],case[2]),'missing actual entry: '..case[2])end;return names",[module])
        result['memory_after_actual_indices']=memory()
        for docset,word in [('python','pathlib.Path.exists'),('lua','string.format'),('c','malloc')]:
            samples=[];states=[]
            for i in range(6):
                reset(word)
                lua("local word,docset=...;bs_requests=0;bs_start=vim.uv.hrtime();require('config.deep_docs').lookup(word,docset)",[word,docset])
                try:state=ready_doc()
                except RuntimeError:
                    diagnostic=lua("local docset,word=...;local r={};for _,w in ipairs(vim.api.nvim_list_wins())do r[#r+1]={win=w,ft=vim.bo[vim.api.nvim_win_get_buf(w)].filetype,relative=vim.api.nvim_win_get_config(w).relative}end;return {root=require('config.docs_store').root(),found=require('config.docs_store').find_entry(docset,word)~=nil,windows=r,clients=#vim.lsp.get_clients({bufnr=bs_source}),capture=require('config.docs_resolver').capture()}",[docset,word]) if modern else {}
                    result['errors'].append({'scenario':docset+'_page','error':'readiness timeout','diagnostic':diagnostic})
                    break
                if i:samples.append(state['ms']);states.append(state)
                else:result['metrics'][docset+'_page_first_ms']=state['ms']
            result['metrics'][docset+'_page']={'runs_ms':samples,'median_ms':statistics.median(samples) if samples else None,'states':states}
        files=[f for f in data.rglob('*') if f.is_file()]
        result['docs_disk']={'files':len(files),'logical_bytes':sum(f.stat().st_size for f in files),
                             'allocated_bytes':sum(f.stat().st_blocks*512 for f in files)}
        result['memory_after_actual_docs']=memory()
result['messages']=lua("return vim.api.nvim_exec2('messages',{output=true}).output")
args.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
p.terminate();p.wait(timeout=5)
