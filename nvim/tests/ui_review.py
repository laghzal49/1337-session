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
call('nvim_exec_lua',["require('config.diagnostic_signs').setup(); vim.diagnostic.config({signs=true,virtual_text=false,update_in_insert=true}); _G.review_a=vim.api.nvim_create_namespace('review_a'); _G.review_b=vim.api.nvim_create_namespace('review_b'); vim.diagnostic.set(review_a,0,{{lnum=0,col=0,message='warning',severity=2}}); vim.diagnostic.set(review_b,0,{{lnum=0,col=0,message='error',severity=1}})",[]]);pump(.2)
def signs():
 return call('nvim_exec_lua',["local ns=vim.api.nvim_get_namespaces().perfect_black_diagnostic_signs; local sign_ns=vim.diagnostic.get_namespace(ns).user_data.sign_ns; return sign_ns and vim.api.nvim_buf_get_extmarks(0,sign_ns,0,-1,{details=true}) or {}",[]])
marks=signs();assert len(marks)==1,marks
assert 'Error' in marks[0][3].get('sign_hl_group',''),marks
call('nvim_exec_lua',['vim.diagnostic.reset(review_b,0)',[]]);pump(.2)
marks=signs();assert len(marks)==1 and 'Warn' in marks[0][3].get('sign_hl_group',''),marks
call('nvim_exec_lua',['vim.diagnostic.reset(review_a,0)',[]]);pump(.2);assert signs()==[]
print('DIAGNOSTICS: worst-per-line and namespace removal PASS',flush=True)
call('nvim_exec_lua',["require('config.notifications').dismiss(); for i=1,5 do Snacks.notifier.notify('review-repeat','warn') end; for i=1,4 do Snacks.notifier.notify('review-error-'..i,'error') end",[]]);pump(.6)
state=call('nvim_exec_lua',["local found={history=0,repeat_live=0,error_live=0}; for _,v in ipairs(Snacks.notifier.get_history()) do if v.msg:match('^review%-') then found.history=found.history+1; if v.win and v.win:win_valid() then if v.level=='warn' then found.repeat_live=found.repeat_live+1; found.title=v.title else found.error_live=found.error_live+1 end end end end; return found",[]])
assert state=={'history':9,'repeat_live':1,'error_live':0,'title':'Notification ×5'},state
screen='\n'.join(''.join(c for c,h in row) for row in grid)
assert '4 errors' in screen,screen
print('NOTIFICATIONS: 9 records, warning ×5, one error summary PASS',flush=True)
call('nvim_exec_lua',["for i=1,6 do Snacks.notifier.notify('review-overflow-'..i,'info') end",[]]);pump(.3)
live=call('nvim_exec_lua',["local n=0; for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype=='snacks_notif' then n=n+1 end end; return n",[]])
assert live==3,live
assert '4 errors' in '\n'.join(''.join(c for c,h in row) for row in grid)
print('OVERFLOW: three live toasts, error summary protected PASS',flush=True)
call('nvim_exec_lua',["require('config.notifications').history()",[]]);pump(.2)
assert call('nvim_eval',['&filetype'])=='snacks_notif_history'
call('nvim_command',['close'])
call('nvim_command',['set nomodified'])
for width,height in [(80,24),(100,30),(140,42)]:
 call('nvim_ui_try_resize',[width,height]);pump(.2)
 for source in ['files','grep']:
  expr="Snacks.picker.files()" if source=='files' else "Snacks.picker.grep({search='neo-tree'})"
  call('nvim_exec_lua',['_G.review_picker='+expr,[]]);pump(.7)
  def dims():
   return call('nvim_exec_lua',["local p=review_picker; local wins={}; for _,w in ipairs({p.input.win,p.list.win,p.preview.win}) do if w:win_valid() then wins[#wins+1]={width=vim.api.nvim_win_get_width(w.win),height=vim.api.nvim_win_get_height(w.win)} end end; return {hidden=p.layout:is_hidden('preview'),wins=wins}",[]])
  before=dims()
  call('nvim_exec_lua',["review_picker:toggle('preview')",[]]);pump(.3)
  after=dims();assert before['hidden']!=after['hidden'],(width,source,before,after)
  for d in before['wins']+after['wins']: assert 0<d['width']<=width and 0<d['height']<=height,d
  call('nvim_exec_lua',['review_picker:close()',[]]);pump(.2)
 print('PICKERS',width,height,'preview toggle and geometry PASS',flush=True)
# A completed query shrinks the same picker, and clearing it grows it again.
call('nvim_exec_lua',['_G.review_picker=Snacks.picker.files()',[]]);pump(.7)
def picker_height():
 return call('nvim_exec_lua',['return vim.api.nvim_win_get_height(review_picker.layout.root.win)',[]])
full=picker_height()
call('nvim_exec_lua',["review_picker.input:set('notifications.lua')",[]]);pump(.7)
small=picker_height()
assert small<full,(full,small)
call('nvim_exec_lua',["review_picker:toggle('preview')",[]]);pump(.3)
assert not call('nvim_exec_lua',["return review_picker.layout:is_hidden('preview')",[]])
call('nvim_exec_lua',["review_picker.input:set('')",[]]);pump(.7)
assert picker_height()>small
assert not call('nvim_exec_lua',["return review_picker.layout:is_hidden('preview')",[]])
call('nvim_exec_lua',['review_picker:close()',[]]);pump(.2)
print('ADAPTIVE: shrinks with results, grows when cleared, preserves preview PASS',flush=True)
# Synthetic large-buffer cost; this excludes external LSP work and NFS latency.
stress=call('nvim_exec_lua',["local t=vim.uv.hrtime(); local lines={}; for i=1,20000 do lines[i]='local value_'..i..' = '..i end; vim.api.nvim_buf_set_lines(0,0,-1,false,lines); local a,b={},{}; for i=1,2000 do a[i]={lnum=i-1,col=0,message='warning',severity=2}; b[i]={lnum=i-1,col=0,message='error',severity=1} end; vim.diagnostic.set(review_a,0,a); vim.diagnostic.set(review_b,0,b); vim.api.nvim_buf_set_text(0,10000,0,10000,0,{'-- edited '}); vim.cmd.redraw(); return {ms=(vim.uv.hrtime()-t)/1e6,lines=vim.api.nvim_buf_line_count(0)}",[]])
assert stress['lines']==20000 and len(signs())==2000,stress
print('LARGE BUFFER: 20k lines, 4k diagnostics, 2k signs',stress,flush=True)
call('nvim_exec_lua',["vim.diagnostic.reset(review_a,0); vim.diagnostic.reset(review_b,0); vim.api.nvim_buf_set_lines(0,0,-1,false,{'test complete'}); vim.bo.modified=false",[]])
# Exercise the exact Neo-tree event that fires after opening a file.
for width,expected in [(80,False),(140,True)]:
 call('nvim_ui_try_resize',[width,30]);pump(.2)
 call('nvim_command',['Neotree show']);pump(.5)
 call('nvim_exec_lua',["require('neo-tree.events').fire_event('file_opened','nvim/init.lua')",[]]);pump(.2)
 visible=call('nvim_exec_lua',["for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype=='neo-tree' then return true end end; return false",[]])
 assert visible==expected,(width,visible)
 call('nvim_command',['Neotree close'])
print('TREE: narrow closes, wide remains PASS',flush=True)
# Exercise documentation via the real insert-mode mappings at two viewport sizes.
call('nvim_exec_lua',[r"""
local cmp = require('cmp')
cmp.register_source('ui_review', {
  complete = function(_, _, callback)
    callback({ items = {{ label = 'summary', kind = 3, documentation = {
      kind = 'markdown', value = '```python\ndef summary(values: list[int]) -> int\n```\n\n' .. string.rep('Documentation paragraph with a readable explanation.\n\n', 24),
    } }}, isIncomplete = false })
  end,
})
""",[]])
for width,height in [(80,24),(140,42)]:
 call('nvim_ui_try_resize',[width,height]);pump(.2)
 call('nvim_command',['enew!'])
 call('nvim_command',['setfiletype python'])
 call('nvim_exec_lua',["vim.api.nvim_buf_set_lines(0,0,-1,false,{'# documentation check','','','',''}); vim.api.nvim_win_set_cursor(0,{5,0}); require('cmp').setup.buffer({sources={{name='ui_review'}}})",[]])
 call('nvim_input',['isum']);pump(.3)
 call('nvim_exec_lua',["require('cmp').complete()",[]]);pump(.4)
 call('nvim_exec_lua',["local c=require('cmp'); if not c.get_selected_entry() then c.select_next_item({behavior=c.SelectBehavior.Select}) end",[]]);pump(.2)
 call('nvim_input',['<C-b>']);pump(.5)
 assert call('nvim_exec_lua',["return require('cmp').visible_docs()",[]]),width
 docs=call('nvim_exec_lua',["for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype=='cmp_docs' then return {win=w,config=vim.api.nvim_win_get_config(w)} end end",[]])
 c=docs['config'];assert c['width']+2<=width and c['height']+2<=height,(width,c)
 if c['width']>=28: assert 'DOCUMENTATION' in str(c.get('title')),c
 call('nvim_input',['<C-f>']);pump(.3)
 assert call('nvim_exec_lua',["return vim.fn.getwininfo(...)[1].topline",[docs['win']]])>1
 call('nvim_input',['<C-d>']);pump(.2)
 assert not call('nvim_exec_lua',["return require('cmp').visible_docs()",[]])
 call('nvim_input',['<Esc>']);pump(.2)
 call('nvim_input',[':set number']);pump(.3)
 wins=call('nvim_exec_lua',["local r={} for _,w in ipairs(vim.api.nvim_list_wins()) do local c=vim.api.nvim_win_get_config(w); if c.relative~='' then r[#r+1]=c end end return r",[]])
 assert all(c['width']<=width and c['height']<=height for c in wins),wins
 call('nvim_input',['<Esc>']);pump(.2)
 print('DOCS / COMMAND',width,height,'open, scroll, close and geometry PASS',flush=True)

print('V_ERRORS',call('nvim_eval',['v:errors']),flush=True)
req('nvim_command',['qa!'])
pump(.3)
p.wait(timeout=5)
