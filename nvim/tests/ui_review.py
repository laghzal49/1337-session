# Requires msgpack and installed Neovim plugins. Runs isolated unsaved test buffers.
import os, subprocess, time, select, msgpack
from pathlib import Path
import shutil, atexit
root=Path(__file__).resolve().parents[2]
exe=os.environ.get('NVIM_BIN') or shutil.which('nvim')
if not exe: raise SystemExit('Neovim is required; set NVIM_BIN if it is not on PATH.')
env=os.environ.copy()
env.update(XDG_CONFIG_HOME=str(root), TERM='xterm-256color')
p=subprocess.Popen([exe,'--embed'],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,env=env,cwd=str(root))
atexit.register(lambda: p.terminate() if p.poll() is None else None)
u=msgpack.Unpacker(raw=False)
seq=0
pending={}
grid=[]; attrs={}; default_fg=0xe7e7ec; default_bg=0

def req(method, params):
 global seq
 seq+=1
 p.stdin.write(msgpack.packb([0,seq,method,params],use_bin_type=True));p.stdin.flush()
 return seq

def handle(msg):
 global grid,default_fg,default_bg
 if msg[0]==1:
  pending[msg[1]]=msg
 elif msg[0]==2 and msg[1]=='redraw':
  for event in msg[2]:
   name, *batches = event
   for a in batches:
    if name=='default_colors_set': default_fg,default_bg=a[:2]
    elif name=='hl_attr_define': attrs[a[0]]=a[1]
    elif name=='grid_resize' and a[0]==1:
     w,h=a[1:3];grid=[[(' ',0) for _ in range(w)] for _ in range(h)]
    elif name=='grid_clear' and a[0]==1:
     for y in range(len(grid)):
      for x in range(len(grid[y])):grid[y][x]=(' ',0)
    elif name=='grid_line' and a[0]==1 and grid:
     _,row,col,cells,*_=a
     hl=0
     for cell in cells:
      if len(cell)>1: hl=cell[1]
      repeat=cell[2] if len(cell)>2 else 1
      for _ in range(repeat):
       if 0<=row<len(grid) and 0<=col<len(grid[row]): grid[row][col]=(cell[0],hl)
       col+=1
    elif name=='grid_scroll' and a[0]==1 and grid:
     _,top,bot,left,right,rows,cols=a
     old=[r[:] for r in grid]
     for y in range(top,bot):
      for x in range(left,right):
       sy=y+rows; sx=x+cols
       grid[y][x]=old[sy][sx] if top<=sy<bot and left<=sx<right else (' ',0)

def pump(seconds=0.4):
 end=time.time()+seconds
 while time.time()<end:
  ready,_,_=select.select([p.stdout],[],[],max(0,end-time.time()))
  if not ready:break
  data=os.read(p.stdout.fileno(),65536)
  if not data:break
  u.feed(data)
  for msg in u:handle(msg)

def call(method,params):
 i=req(method,params)
 until=time.time()+10
 while i not in pending and time.time()<until:pump(.2)
 result=pending.pop(i,None)
 if not result:raise RuntimeError('timeout: '+method)
 if result[2]:raise RuntimeError(str(result[2]))
 return result[3]


call('nvim_ui_attach',[100,30,{'rgb':True,'ext_linegrid':True}]);pump(1)
call('nvim_command',['enew'])
call('nvim_buf_set_lines',[0,0,-1,False,['test diagnostics','second line']])
call('nvim_exec_lua',["require('config.diagnostic_signs').setup(); vim.diagnostic.config({signs=true,virtual_text=false,update_in_insert=true}); _G.review_a=vim.api.nvim_create_namespace('review_a'); _G.review_b=vim.api.nvim_create_namespace('review_b'); vim.diagnostic.config({signs={priority=99,text={[1]='X'}}},review_b); vim.diagnostic.set(review_a,0,{{lnum=0,col=0,message='warning',severity=2}}); vim.diagnostic.set(review_b,0,{{lnum=0,col=0,message='error',severity=1}})",[]]);pump(.2)
def signs():
 return call('nvim_exec_lua',["local ns=vim.api.nvim_get_namespaces().perfect_black_diagnostic_signs; local sign_ns=vim.diagnostic.get_namespace(ns).user_data.sign_ns; return sign_ns and vim.api.nvim_buf_get_extmarks(0,sign_ns,0,-1,{details=true}) or {}",[]])
marks=signs();assert len(marks)==1,marks
assert 'Error' in marks[0][3].get('sign_hl_group',''),marks
assert marks[0][3]['priority'] < 99 and marks[0][3]['sign_text'].strip() != 'X',marks
call('nvim_exec_lua',['vim.diagnostic.reset(review_b,0)',[]]);pump(.2)
marks=signs();assert len(marks)==1 and 'Warn' in marks[0][3].get('sign_hl_group',''),marks
call('nvim_exec_lua',['vim.diagnostic.reset(review_a,0)',[]]);pump(.2);assert signs()==[]
print('DIAGNOSTICS: worst-per-line and namespace removal PASS',flush=True)
call('nvim_exec_lua',["require('config.notifications').dismiss(); for i=1,5 do vim.notify('review-repeat',vim.log.levels.WARN) end; for i=1,4 do vim.notify('review-error-'..i,vim.log.levels.ERROR) end",[]]);pump(.6)
state=call('nvim_exec_lua',["local all=require('mini.notify').get_all(); local records=vim.tbl_filter(function(n) return n.msg:match('^review%-') end,all); local active=vim.tbl_filter(function(n) return not n.ts_remove end, records); return {history=#records,display=require('config.notifications').sort(active)}",[]])
assert state['history']==9 and len(state['display'])==2,state
assert state['display'][1]['data']['count']==5,state
screen='\n'.join(''.join(c for c,h in row) for row in grid)
assert '4 errors' in screen and 'review-error-4' in screen and '×5' in screen,screen
print('NOTIFICATIONS: originals retained, warning ×5, one error summary PASS',flush=True)
call('nvim_exec_lua',["for i=1,6 do vim.notify('review-overflow-'..i,vim.log.levels.INFO) end",[]]);pump(.3)
live=call('nvim_exec_lua',["local active=vim.tbl_filter(function(n) return not n.ts_remove end,require('mini.notify').get_all()); return #require('config.notifications').sort(active)",[]])
assert live==3,live
assert '4 errors' in '\n'.join(''.join(c for c,h in row) for row in grid)
print('OVERFLOW: three displayed entries, error summary protected PASS',flush=True)
call('nvim_exec_lua',["require('config.notifications').history()",[]]);pump(.2)
assert call('nvim_eval',['&filetype'])=='mininotify-history'
call('nvim_command',['close'])
call('nvim_command',['set nomodified'])
for width,height in [(80,24),(100,30),(140,42)]:
 call('nvim_ui_try_resize',[width,height]);pump(.2)
 for source in ['files','grep']:
  call('nvim_exec_lua',["local source=...; vim.schedule(function() require('config.pick').open(source) end)",[source]]);pump(.7)
  call('nvim_input',['notifications' if source=='files' else 'vim.notify']);pump(.7)
  state=call('nvim_exec_lua',["local p=require('mini.pick'); local s=p.get_picker_state(); return {items=#p.get_picker_items(),width=vim.api.nvim_win_get_width(s.windows.main),height=vim.api.nvim_win_get_height(s.windows.main)}",[]])
  assert state['items']>0 and state['width']<=width and state['height']<=height,state
  call('nvim_input',['<C-p>']);pump(.3)
  assert call('nvim_exec_lua',["local s=require('mini.pick').get_picker_state(); return s.buffers.preview~=nil and vim.api.nvim_win_get_buf(s.windows.main)==s.buffers.preview",[]])
  call('nvim_input',['<C-p>']);pump(.2)
  call('nvim_input',['<Esc>']);pump(.3)
  assert call('nvim_exec_lua',["return require('mini.pick').get_picker_state()==nil",[]])
 print('MINI PICK',width,height,'files, live grep, previews, close PASS',flush=True)
# Synthetic large-buffer cost; this excludes external LSP work and NFS latency.
stress=call('nvim_exec_lua',["local t=vim.uv.hrtime(); local lines={}; for i=1,20000 do lines[i]='local value_'..i..' = '..i end; vim.api.nvim_buf_set_lines(0,0,-1,false,lines); local a,b={},{}; for i=1,2000 do a[i]={lnum=i-1,col=0,message='warning',severity=2}; b[i]={lnum=i-1,col=0,message='error',severity=1} end; vim.diagnostic.set(review_a,0,a); vim.diagnostic.set(review_b,0,b); vim.api.nvim_buf_set_text(0,10000,0,10000,0,{'-- edited '}); vim.cmd.redraw(); return {ms=(vim.uv.hrtime()-t)/1e6,lines=vim.api.nvim_buf_line_count(0)}",[]])
assert stress['lines']==20000 and len(signs())==2000,stress
print('LARGE BUFFER: 20k lines, 4k diagnostics, 2k signs',stress,flush=True)
call('nvim_exec_lua',["vim.diagnostic.reset(review_a,0); vim.diagnostic.reset(review_b,0); vim.api.nvim_buf_set_lines(0,0,-1,false,{'test complete'}); vim.bo.modified=false",[]])
# Exercise documentation via the real insert-mode mappings at two viewport sizes.
call('nvim_exec_lua',[r"""
local cmp = require('cmp')
cmp.register_source('ui_review', {
  complete = function(_, _, callback)
    callback({ items = {{ label = 'summary', kind = 3 }}, isIncomplete = false })
  end,
  resolve = function(_, item, callback)
    vim.defer_fn(function()
      item.documentation = {
        kind = 'markdown', value = '```python\ndef summary(values: list[int]) -> int\n```\n\n' .. string.rep('Documentation paragraph with a readable explanation.\n\n', 24),
      }
      callback(item)
    end, 1600)
  end,
})
""",[]])
for width,height in [(80,24),(140,42)]:
 call('nvim_input',['<Esc>']);pump(.5)
 assert call('nvim_get_mode',[])['mode']=='n'
 call('nvim_ui_try_resize',[width,height]);pump(.2)
 call('nvim_command',['enew!'])
 call('nvim_command',['setfiletype python'])
 call('nvim_exec_lua',["vim.api.nvim_buf_set_lines(0,0,-1,false,{'# documentation check','','','',''}); vim.api.nvim_win_set_cursor(0,{5,0}); require('cmp').setup.buffer({sources={{name='ui_review'}}})",[]])
 call('nvim_input',['isum']);pump(.3)
 call('nvim_exec_lua',["require('cmp').complete()",[]]);pump(.4)
 call('nvim_exec_lua',["local c=require('cmp'); if not c.get_selected_entry() then c.select_next_item({behavior=c.SelectBehavior.Select}) end",[]]);pump(.2)
 call('nvim_input',['<C-b>']);pump(1.8)
 assert call('nvim_exec_lua',["return require('cmp').visible_docs()",[]]),width
 docs=call('nvim_exec_lua',["for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype=='cmp_docs' then return {win=w,config=vim.api.nvim_win_get_config(w)} end end",[]])
 c=docs['config'];assert c['width']+2<=width and c['height']+2<=height,(width,c)
 if c['width']>=28: assert 'DOCUMENTATION' in str(c.get('title')),c
 call('nvim_input',['<C-f>']);pump(.3)
 assert call('nvim_exec_lua',["return vim.fn.getwininfo(...)[1].topline",[docs['win']]])>1
 call('nvim_input',['<C-d>']);pump(.2)
 assert not call('nvim_exec_lua',["return require('cmp').visible_docs()",[]])
 call('nvim_input',['<Esc>']);pump(.5)
 call('nvim_input',[':set number']);pump(.3)
 wins=call('nvim_exec_lua',["local r={} for _,w in ipairs(vim.api.nvim_list_wins()) do local c=vim.api.nvim_win_get_config(w); if c.relative~='' then r[#r+1]=c end end return r",[]])
 assert all(c['width']<=width and c['height']<=height for c in wins),wins
 call('nvim_input',['<Esc>']);pump(.5)
 print('DOCS / COMMAND',width,height,'open, scroll, close and geometry PASS',flush=True)

call('nvim_exec_lua',["_G.layoutdir=vim.fn.tempname(); vim.fn.mkdir(layoutdir..'/parent/long_directory_name_for_title','p')",[]])
for width,height in [(140,42),(80,24),(100,30),(140,42)]:
 call('nvim_ui_try_resize',[width,height]);pump(.2)
 call('nvim_exec_lua',["local f=require('mini.files'); if not f.get_explorer_state() then f.open(layoutdir,true,require('config.tool_layout').files()) end; f.set_branch({layoutdir,layoutdir..'/parent',layoutdir..'/parent/long_directory_name_for_title'}); f.refresh(require('config.tool_layout').files())",[]]);pump(.3)
 for repeat in range(3):
  wins=call('nvim_exec_lua',["local s=require('mini.files').get_explorer_state(); local out={}; for _,w in ipairs(s.windows) do require('config.tool_layout').decorate_files({data={win_id=w.win_id}}); local c=vim.api.nvim_win_get_config(w.win_id); out[#out+1]={row=c.row,col=c.col,width=c.width,height=c.height,title=c.title} end return out",[]])
  assert len(wins)==(1 if width<100 else 3),wins
  for w in wins: assert w['col']>=0 and w['row']>=1 and w['col']+w['width']+2<=width and w['row']+w['height']+2<height,w
  for left,right in zip(wins,wins[1:]): assert left['col']+left['width']+2<=right['col'],wins
  if repeat: assert wins==previous,'layout drift'
  previous=wins
 print('BROWSER',width,height,'bounds, columns, no overlap/drift PASS',flush=True)
call('nvim_exec_lua',["require('mini.files').close(); vim.fn.delete(layoutdir,'rf')",[]])
print('PLUGIN INTEGRATION',call('nvim_exec_lua',["return dofile('nvim/tests/plugins_review.lua')",[]]),flush=True)
call('nvim_exec_lua',["vim.schedule(function() require('config.pick').open('files',{cwd=plugin_review.dir}) end)",[]]);pump(.7)
call('nvim_input',['renamed']);pump(.5)
call('nvim_input',['<CR>']);pump(.5)
assert call('nvim_eval',["expand('%:t')"])=='renamed.txt'
call('nvim_exec_lua',["vim.api.nvim_set_current_buf(plugin_review.buf); vim.api.nvim_win_set_cursor(0,{3,5})",[]])
print('MINI FILES rename + MINI PICK selection PASS',flush=True)

for width,height in [(80,24),(140,42)]:
 call('nvim_ui_try_resize',[width,height]);pump(.3)
 call('nvim_exec_lua',["require('mini.files').open(plugin_review.dir,true,require('config.tool_layout').files())",[]]);pump(.3)
 files=call('nvim_exec_lua',["local r={} for _,w in ipairs(vim.api.nvim_list_wins()) do local c=vim.api.nvim_win_get_config(w); if vim.bo[vim.api.nvim_win_get_buf(w)].filetype=='minifiles' then r[#r+1]=c end end return r",[]])
 assert files and all(c['width']<=width-4 and c['height']<=height-2 for c in files),files
 call('nvim_exec_lua',["require('mini.files').close()",[]]);pump(.2)
 for command,ft in [('Glance references','glance'),('AerialOpen float','aerial')]:
  call('nvim_command',[command]);pump(.8)
  panels=call('nvim_exec_lua',["local r={} for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype:lower():match(...) then r[#r+1]={vim.api.nvim_win_get_width(w),vim.api.nvim_win_get_height(w)} end end return r",[ft]])
  assert panels and all(c[0]<=width and c[1]<=height-2 for c in panels),(command,panels)
  if ft=='glance':call('nvim_exec_lua',["require('glance').actions.close()",[]])
  else:call('nvim_command',['AerialClose'])
  pump(.3)
 print('TOOL PANELS',width,height,'Mini Files, Glance, Aerial PASS',flush=True)
call('nvim_exec_lua',["vim.api.nvim_set_current_buf(plugin_review.buf); vim.api.nvim_win_set_cursor(0,{3,5})",[]])
call('nvim_input',[':IncRename renamed']);pump(.6)
call('nvim_input',['<CR>']);pump(.6)
assert 'renamed' in call('nvim_exec_lua',["return vim.api.nvim_buf_get_lines(plugin_review.buf,2,3,false)[1]",[]])
call('nvim_exec_lua',["vim.lsp.stop_client(plugin_review.client,true); vim.api.nvim_buf_delete(plugin_review.buf,{force=true}); vim.fn.delete(plugin_review.dir,'rf')",[]])
print('LSP UI: Glance, Aerial, incremental rename PASS',flush=True)
errors=call('nvim_eval',['v:errors']); assert errors==[],errors
print('V_ERRORS',errors,flush=True)
req('nvim_command',['silent! qa!'])
# Installer shutdown messages may request Enter after Noice detaches on exit.
deadline=time.time()+8
while p.poll() is None and time.time()<deadline:
 pump(.2)
 if p.poll() is None:
  try: req('nvim_input',['<CR>'])
  except BrokenPipeError: break  # Neovim closed stdin between poll and write.
p.wait(timeout=5)
