"""Attached-UI WhichKey review using public show/input APIs, no plugin patches.
Run with --config /tmp/1337-before-black-deck to capture the baseline.
"""
import argparse,atexit,json,os,pathlib,select,shutil,statistics,subprocess,tempfile,time
import msgpack
parser=argparse.ArgumentParser()
parser.add_argument('--config',type=pathlib.Path,default=pathlib.Path(__file__).resolve().parents[1])
parser.add_argument('--output',type=pathlib.Path,default=pathlib.Path('/tmp/black-deck-review.json'))
parser.add_argument('--compare-baseline',type=pathlib.Path)
parser.add_argument('--expect-black-deck',action='store_true')
args=parser.parse_args();root=pathlib.Path(__file__).resolve().parents[2]
tmp=tempfile.TemporaryDirectory(prefix='black-deck-review-');atexit.register(tmp.cleanup)
pathlib.Path(tmp.name,'nvim').symlink_to(args.config.resolve(),target_is_directory=True)
env=dict(os.environ,XDG_CONFIG_HOME=tmp.name,XDG_CACHE_HOME=tmp.name+'/cache',XDG_STATE_HOME=tmp.name+'/state',TERM='xterm-256color',NVIM_BLACK_DOCS_AUTO_UPDATE='0')
exe=os.environ.get('NVIM_BIN') or shutil.which('nvim')
p=subprocess.Popen([exe,'--embed','--cmd','let g:station_1337 = v:false'],env=env,cwd=root,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL)
atexit.register(lambda:p.terminate() if p.poll() is None else None)
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
    raise RuntimeError('UI readiness timeout')
def panel():
    return lua("local r={}; for _,w in ipairs(vim.api.nvim_list_wins()) do local b=vim.api.nvim_win_get_buf(w); if vim.bo[b].filetype=='wk' then "
               "r[#r+1]={config=vim.api.nvim_win_get_config(w),lines=vim.api.nvim_buf_get_lines(b,0,-1,false),hl=vim.wo[w].winhighlight} end end; return r")
def memory():
    rss=next((line.split()[1] for line in pathlib.Path('/proc',str(p.pid),'status').read_text().splitlines() if line.startswith('VmRSS:')),None)
    return {'rss_kib':int(rss) if rss else None,'lua_gc_kib':lua("return collectgarbage('count')")}
rpc('nvim_ui_attach',[140,42,{'rgb':True,'ext_linegrid':True}]);time.sleep(.25)
lua("require('lazy').load({plugins={'which-key.nvim'}}); vim.cmd('enew!'); vim.bo.filetype='black_deck_review'")
result={'config':str(args.config.resolve()),'cwd':str(root),'scope':__doc__,'auto_update':False,'memory_before':memory(),'screens':{},'errors':[]}
result['leader_mappings']=lua("local r={}; for _,m in ipairs(vim.api.nvim_get_keymap('n')) do if m.lhs:sub(1,1)==' ' then "
                            "r[#r+1]={lhs=m.lhs,rhs=m.rhs or '',desc=m.desc or '',callback=m.callback~=nil} end end; table.sort(r,function(a,b)return a.lhs<b.lhs end); return r")
if args.compare_baseline:
    before=json.loads(args.compare_baseline.read_text())
    missing=set(m['lhs'] for m in before['leader_mappings'])-set(m['lhs'] for m in result['leader_mappings'])
    assert not missing,('missing existing leader mappings',sorted(missing))
    result['existing_leader_mappings_preserved']=True
for width,height in [(80,24),(100,30),(140,42)]:
    rpc('nvim_ui_try_resize',[width,height]);samples=[];nested=[];screens={}
    for i in range(6):
        lua("bd_start=vim.uv.hrtime(); vim.schedule(function() require('which-key').show({keys=vim.g.mapleader,mode='n',delay=0}) end)")
        elapsed=wait("for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype=='wk' then return (vim.uv.hrtime()-bd_start)/1e6 end end")
        if i:samples.append(elapsed)
        screens['root']=panel()
        assert len([w for w in screens['root'] if len(w['lines'])>1])==1,'Duplicate WhichKey main surfaces'
        if args.expect_black_deck:
            titles=[str(w['config'].get('title','')) for w in screens['root']]
            assert any('BLACKDECK' in title.replace(' ','') for title in titles),titles
        lua("bd_start=vim.uv.hrtime()")
        rpc('nvim_input',['f'])
        elapsed=wait("for _,w in ipairs(vim.api.nvim_list_wins()) do local b=vim.api.nvim_win_get_buf(w); if vim.bo[b].filetype=='wk' then "
                     "local text=table.concat(vim.api.nvim_buf_get_lines(b,0,-1,false),' '); if text:lower():find('files',1,true) then return (vim.uv.hrtime()-bd_start)/1e6 end end end")
        if i:nested.append(elapsed)
        screens['find']=panel()
        assert [w['lines'] for w in screens['find']] != [w['lines'] for w in screens['root']],'Find navigation did not change the deck'
        rpc('nvim_input',['<BS>']);time.sleep(.01);screens['back']=panel()
        assert screens['back'],'Backspace closed the root deck'
        assert [w['lines'] for w in screens['back']] == [w['lines'] for w in screens['root']],'Backspace did not restore root entries/order'
        rpc('nvim_input',['<Esc>']);wait("for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype=='wk' then return false end end; return true")
    for stage,windows in screens.items():
        for w in windows:
            c=w['config'];assert c['width']<=width and c['height']<=height,(stage,c)
            if c['relative']=='editor':
                border=0 if c.get('border') in (None,'none') else 2
                assert c['col']+c['width']+border<=width and c['row']+c['height']+border<=height,(stage,c)
    result['screens'][str(width)]={'root_open_ms':samples,'root_median_ms':statistics.median(samples),
                                  'nested_open_ms':nested,'nested_median_ms':statistics.median(nested),'stages':screens}
result['memory_after']=memory();result['messages']=lua("return vim.api.nvim_exec2('messages',{output=true}).output")
args.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k not in ('leader_mappings','screens')},indent=2))
p.terminate();p.wait(timeout=5)
