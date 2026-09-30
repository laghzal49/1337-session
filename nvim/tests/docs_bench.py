"""Matched 5-run startup and attached-UI hover/scroll before/after benchmark.
Both configurations use identical cwd, /tmp cache/state and installed plugins.
Hover uses the real symbol_help adapter and an async fake LSP with 60ms delay.
Completion uses real Blink windows with a custom 60ms delayed resolver. Scroll
samples measure 100 native scroll/redraw operations in one Lua batch. First-use
samples are separate; startup is host-sensitive and may be bimodal under load.
"""
import argparse, atexit, json, os, pathlib, re, select, shutil, statistics, subprocess, tempfile, time
import msgpack
parser=argparse.ArgumentParser()
parser.add_argument('--before',type=pathlib.Path,default=pathlib.Path('/tmp/1337-docs-baseline'))
parser.add_argument('--after',type=pathlib.Path,default=pathlib.Path(__file__).resolve().parents[1])
parser.add_argument('--output',type=pathlib.Path,default=pathlib.Path('/tmp/documentation-benchmark.json'))
args=parser.parse_args(); root=pathlib.Path(__file__).resolve().parents[2]
tmp=tempfile.TemporaryDirectory(prefix='docs-bench-'); atexit.register(tmp.cleanup)
env=dict(os.environ,XDG_CONFIG_HOME=tmp.name,XDG_CACHE_HOME=tmp.name+'/cache',XDG_STATE_HOME=tmp.name+'/state',TERM='xterm-256color')
exe=os.environ.get('NVIM_BIN') or shutil.which('nvim'); link=pathlib.Path(tmp.name)/'nvim'
result={'scope':__doc__,'cwd':str(root),'runs':5,'configs':{}}
for label,config in [('before',args.before),('after',args.after)]:
    if link.is_symlink(): link.unlink()
    link.symlink_to(config.resolve(),target_is_directory=True)
    record={'config':str(config.resolve()),'startup_ms':[],'hover':{},'errors':[]}; result['configs'][label]=record
    for i in range(6):
        log=pathlib.Path(tmp.name)/'startup.log'
        run=subprocess.run([exe,'--headless','--cmd','let g:station_1337 = v:false','--startuptime',str(log),'+qa!'],cwd=root,env=env,capture_output=True,text=True,timeout=30)
        data=log.read_text(); log.unlink()
        times=[float(m[1]) for line in data.splitlines() if (m:=re.match(r'^(\d+\.\d+).*NVIM STARTED',line))]
        if run.returncode or re.search(r'Error in |Failed to load |E\d+:',run.stderr): record['errors'].append(run.stderr)
        if not times: raise RuntimeError('no startup marker')
        if i: record['startup_ms'].append(times[-1])
        else: record['startup_first_ms']=times[-1]
    record['startup_median_ms']=statistics.median(record['startup_ms'])
    p=subprocess.Popen([exe,'--embed','--cmd','let g:station_1337 = v:false'],cwd=root,env=env,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL)
    u=msgpack.Unpacker(raw=False); pending={}; seq=0
    def rpc(method,params):
        global seq
        seq+=1; p.stdin.write(msgpack.packb([0,seq,method,params],use_bin_type=True)); p.stdin.flush()
        deadline=time.monotonic()+20
        while seq not in pending and time.monotonic()<deadline:
            ready,_,_=select.select([p.stdout],[],[],.1)
            if ready:
                data=os.read(p.stdout.fileno(),65536)
                if not data: raise RuntimeError('Neovim exited')
                u.feed(data)
                for msg in u:
                    if msg[0]==1: pending[msg[1]]=msg
        reply=pending.pop(seq,None)
        if not reply or reply[2]: raise RuntimeError(str(reply))
        return reply[3]
    def lua(code): return rpc('nvim_exec_lua',[code,[]])
    rpc('nvim_ui_attach',[140,42,{'rgb':True,'ext_linegrid':True}]); time.sleep(.3)
    lua("dofile('nvim/tests/documentation_fixture.lua'); documentation_review.signature=false")
    for width,height in [(80,24),(140,42)]:
        rpc('nvim_ui_try_resize',[width,height]); times=[]; scroll=[]; bounds=[]; first=None
        for iteration in range(6):
            lua("for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.api.nvim_win_get_config(w).relative~='' then vim.api.nvim_win_close(w,true) end end; "
                "vim.api.nvim_set_current_buf(documentation_review.buf); pb_start=vim.uv.hrtime(); require('config.symbol_help').show(nil,false)")
            deadline=time.monotonic()+5; state=None
            while time.monotonic()<deadline:
                state=lua("for _,w in ipairs(vim.api.nvim_list_wins()) do local c=vim.api.nvim_win_get_config(w); "
                          "if c.relative~='' and vim.bo[vim.api.nvim_win_get_buf(w)].filetype=='markdown' then "
                          "_G.pb_doc_win=w; return {ms=(vim.uv.hrtime()-pb_start)/1e6,width=c.width,height=c.height} end end")
                if state: break
                time.sleep(.002)
            if not state: record['errors'].append('hover timeout at '+str(width)); break
            if iteration: times.append(state['ms']); bounds.append([state['width'],state['height']])
            else: first=state['ms']
            elapsed=lua("local t=vim.uv.hrtime(); vim.api.nvim_win_call(pb_doc_win,function() for i=1,100 do "
                        "vim.cmd.normal({args={i%2==0 and '5\\5' or '5\\25'},bang=true}); vim.cmd.redraw() end end); return (vim.uv.hrtime()-t)/1e6")
            if iteration: scroll.append(elapsed)
        record['hover'][str(width)]={'first_ms':first,'runs_ms':times,'median_ms':statistics.median(times) if times else None,
                                     'scroll100_ms':scroll,'scroll100_median_ms':statistics.median(scroll) if scroll else None,'bounds':bounds}
    lua("""
      require('blink.cmp')
      package.preload['docs_bench_source']=function()
        local s={}; function s.new() return setmetatable({},{__index=s}) end
        function s:get_completions(_,cb)
          cb({items={{label='summary',kind=3}},is_incomplete_forward=false,is_incomplete_backward=false})
        end
        function s:resolve(item,cb)
          vim.defer_fn(function() item.documentation={kind='markdown',value=documentation_review.markdown}; cb(item) end,60)
        end
        return s
      end
      require('blink.cmp').add_source_provider('docs_bench',{name='Bench',module='docs_bench_source'})
      local c=require('blink.cmp.config'); c.sources.default={'docs_bench'}
      c.completion.documentation.auto_show=false; c.signature.enabled=false
    """)
    record['completion']={}
    for width,height in [(80,24),(140,42)]:
        rpc('nvim_ui_try_resize',[width,height]); samples=[]; first=None; bounds=[]
        for iteration in range(6):
            rpc('nvim_input',['<Esc>']); time.sleep(.01)
            lua("require('blink.cmp').hide(); vim.api.nvim_set_current_buf(documentation_review.buf); "
                "vim.api.nvim_buf_set_lines(0,0,-1,false,{'sum'}); vim.api.nvim_win_set_cursor(0,{1,0})")
            rpc('nvim_input',['A']); time.sleep(.01)
            lua("require('blink.cmp').show()")
            deadline=time.monotonic()+3
            while time.monotonic()<deadline:
                if lua("local c=require('blink.cmp'); return c.is_menu_visible() and #c.get_items()>0"): break
                time.sleep(.002)
            lua("local c=require('blink.cmp'); if not c.get_selected_item() then c.select_next() end")
            deadline=time.monotonic()+3
            while time.monotonic()<deadline:
                if lua("return require('blink.cmp').get_selected_item()~=nil"): break
                time.sleep(.002)
            lua("pb_start=vim.uv.hrtime(); require('blink.cmp').show_documentation()")
            state=None; deadline=time.monotonic()+5
            while time.monotonic()<deadline:
                state=lua("for _,w in ipairs(vim.api.nvim_list_wins()) do local b=vim.api.nvim_win_get_buf(w); "
                          "if vim.bo[b].filetype=='blink-cmp-documentation' and vim.api.nvim_buf_line_count(b)>3 then "
                          "local c=vim.api.nvim_win_get_config(w); return {ms=(vim.uv.hrtime()-pb_start)/1e6,width=c.width,height=c.height} end end")
                if state: break
                time.sleep(.002)
            if not state: record['errors'].append('completion docs timeout at '+str(width)); break
            if iteration: samples.append(state['ms']); bounds.append([state['width'],state['height']])
            else: first=state['ms']
            lua("require('blink.cmp').hide_documentation(); require('blink.cmp').hide()")
        record['completion'][str(width)]={'first_ms':first,'runs_ms':samples,
                                         'median_ms':statistics.median(samples) if samples else None,'bounds':bounds}
    rpc('nvim_input',['<Esc>'])
    record['messages']=lua("return vim.api.nvim_exec2('messages',{output=true}).output")
    p.terminate(); p.wait(timeout=5)
args.output.write_text(json.dumps(result,indent=2)+'\n'); print(json.dumps(result,indent=2))
