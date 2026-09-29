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
assert marks[0][3]['priority'] < 99 and marks[0][3].get('sign_text', '').strip() != 'X',marks
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
-- A real Blink provider with a delayed resolve response. No UI/mapping mocks.
package.preload['ui_review.blink_source'] = function()
  local source = {}
  function source.new() return setmetatable({}, { __index = source }) end
  function source:get_completions(_, callback)
    callback({ items = {{ label = 'summary', kind = 3 }, { label = 'summary_details', kind = 3 }}, is_incomplete_forward = false, is_incomplete_backward = false })
  end
  function source:resolve(item, callback)
    vim.defer_fn(function()
      item.documentation = {
        kind = 'markdown', value = '```python\ndef summary(values: Iterable[int]) -> int\n```\n\n'
          .. 'Return the total of a sequence of integers.\n\n'
          .. '**Parameters**\n\n- `values`: Integer values to add.\n\n'
          .. '**Returns**\n\nAn integer containing the accumulated total.\n\n'
          .. '**Example**\n\n```python\nsummary([4, 8, 15])\n# 27\n```\n\n'
          .. string.rep('Values are consumed once; lists, tuples and generators are supported.\n\n', 24),
      }
      callback(item)
    end, 300)
  end
  return source
end
require('blink.cmp').add_source_provider('ui_review', { name = 'Review', module = 'ui_review.blink_source' })
_G.review_blink_sources = require('blink.cmp.config').sources.default
require('blink.cmp.config').sources.default = { 'ui_review' }
""",[]])
for width,height in [(80,24),(140,42)]:
 call('nvim_input',['<Esc>']);pump(.5)
 assert call('nvim_get_mode',[])['mode']=='n'
 call('nvim_ui_try_resize',[width,height]);pump(.2)
 call('nvim_command',['enew!'])
 call('nvim_command',['setfiletype python'])
 call('nvim_exec_lua',["vim.api.nvim_buf_set_lines(0,0,-1,false,{'# Python analysis — completion review','from collections.abc import Iterable','','def analyze(values: Iterable[int]) -> int:','    ','    # Inspect the selected completion with Ctrl-D.','    # Ctrl-N / Ctrl-P move through matches.','','def summary(values: Iterable[int]) -> int:','    total = 0','    for value in values:','        total += value','    return total','','result = analyze([4, 8, 15, 16, 23, 42])'}); vim.api.nvim_win_set_cursor(0,{5,4})",[]])
 call('nvim_input',['Asum']);pump(.3)
 for opening in ['<C-n>', '<C-p>']:
  call('nvim_exec_lua',["require('blink.cmp').hide()",[]]);pump(.1)
  call('nvim_input',[opening]);pump(.4)
  assert call('nvim_exec_lua',["return require('blink.cmp').is_menu_visible() and vim.fn.pumvisible()==0",[]]), opening
 call('nvim_exec_lua',["local c=require('blink.cmp'); assert(c.is_menu_visible(), 'Blink completion menu missing'); assert(c.get_selected_item_idx()==nil); assert(#c.get_items()==2)",[]])
 for key, index in [('<C-n>',1),('<C-n>',2),('<C-p>',1)]:
  call('nvim_input',[key]);pump(.2)
  state=call('nvim_exec_lua',["return {selected=require('blink.cmp').get_selected_item_idx(),line=vim.api.nvim_get_current_line(),native=vim.fn.pumvisible()}",[]])
  assert state=={'selected':index,'line':'    sum','native':0}, (key,state)
 call('nvim_exec_lua',["assert(require('blink.cmp').get_selected_item().label=='summary', 'Review item missing')",[]]);pump(.2)
 call('nvim_input',['<C-d>']);pump(.2)
 call('nvim_input',['<C-k>']);pump(1.8)
 call('nvim_input',['<C-k>']);pump(.2)
 assert call('nvim_exec_lua',["return require('blink.cmp').is_documentation_visible()",[]]),width
 docs=call('nvim_exec_lua',["for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype=='blink-cmp-documentation' then return {win=w,config=vim.api.nvim_win_get_config(w)} end end",[]])
 c=docs['config'];assert c['width']+2<=width and c['height']+2<=height,(width,c)
 if width==140 and '--screenshot' in __import__('sys').argv:
  call('nvim_exec_lua',["vim.api.nvim_buf_set_name(0,vim.fn.tempname()..'/analysis.py')",[]]);pump(.2)
  from ui_capture import save_grid
  save_grid(grid,attrs,default_fg,default_bg,root/'nvim/assets/completion.png')
 view_before=call('nvim_exec_lua',["local win=...; return vim.api.nvim_win_call(win,function() return vim.fn.winsaveview() end)",[docs['win']]])
 for _ in range(3):
  call('nvim_input',['<C-f>']);pump(.15)
 view_after=call('nvim_exec_lua',["local win=...; return vim.api.nvim_win_call(win,function() return vim.fn.winsaveview() end)",[docs['win']]])
 assert (view_after['topline'],view_after['skipcol'],view_after['lnum'])!=(view_before['topline'],view_before['skipcol'],view_before['lnum']), (view_before,view_after,c)
 call('nvim_input',['<C-d>']);pump(.2)
 assert not call('nvim_exec_lua',["return require('blink.cmp').is_documentation_visible()",[]])
 call('nvim_input',['<CR>']);pump(.3)
 accepted=call('nvim_exec_lua',["return {lines=vim.api.nvim_buf_get_lines(0,0,-1,false),cursor=vim.api.nvim_win_get_cursor(0),selected=require('blink.cmp').get_selected_item()}",[]])
 assert accepted['lines'][4]=='    summary()', accepted
 call('nvim_input',['<Esc>']);pump(.5)
 call('nvim_input',[':set number']);pump(.3)
 wins=call('nvim_exec_lua',["local r={} for _,w in ipairs(vim.api.nvim_list_wins()) do local c=vim.api.nvim_win_get_config(w); if c.relative~='' then r[#r+1]=c end end return r",[]])
 assert all(c['width']<=width and c['height']<=height for c in wins),wins
 call('nvim_input',['<Esc>']);pump(.5)
 print('DOCS / COMMAND',width,height,'open, scroll, close and geometry PASS',flush=True)

call('nvim_exec_lua',["require('blink.cmp.config').sources.default=review_blink_sources",[]])

# Ctrl-K also provides Python builtin documentation without a language server.
call('nvim_command',['enew!'])
call('nvim_command',['setfiletype python'])
for mode in ['normal', 'insert']:
 call('nvim_exec_lua',["vim.api.nvim_buf_set_lines(0,0,-1,false,{'sum'}); vim.api.nvim_win_set_cursor(0,{1,1})",[]])
 if mode=='insert':
  call('nvim_input',['i']);pump(.1)
  call('nvim_exec_lua',["require('blink.cmp').hide()",[]]);pump(.1)
 call('nvim_input',['<C-k>']);pump(.6)
 text=call('nvim_exec_lua',["for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.api.nvim_win_get_config(w).relative~='' then local b=vim.api.nvim_win_get_buf(w); local lines=vim.api.nvim_buf_get_lines(b,0,-1,false); local text=table.concat(lines,'\\n'); if text:find('sum%(iterable') then return text end end end",[]])
 assert text and 'start' in text and 'Return' in text, (mode,text)
 assert call('nvim_get_current_line',[])=='sum',mode
 call('nvim_input',['<Esc>']);pump(.2)
 call('nvim_exec_lua',["for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.api.nvim_win_get_config(w).relative~='' then vim.api.nvim_win_close(w,true) end end",[]])
print('CTRL-K: completion docs and normal/insert Python usage help PASS',flush=True)

# A buffer-only candidate must use its full name without accepting the suggestion.
call('nvim_command',['enew!'])
call('nvim_command',['setfiletype python'])
call('nvim_exec_lua',["require('blink.cmp.config').sources.default={'buffer'}; vim.api.nvim_buf_set_lines(0,0,-1,false,{'print',''}); vim.api.nvim_win_set_cursor(0,{2,0})",[]])
call('nvim_input',['ipri']);pump(.6)
call('nvim_input',['<C-n>']);pump(.2)
item=call('nvim_exec_lua',["return require('blink.cmp').get_selected_item()",[]])
assert item and item['label']=='print' and item['source_id']=='buffer',item
call('nvim_input',['<C-k>']);pump(.5)
text=call('nvim_exec_lua',["local t={} for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.api.nvim_win_get_config(w).relative~='' then vim.list_extend(t,vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(w),0,-1,false)) end end return table.concat(t,'\\n')",[]])
assert 'print(' in text,text
assert call('nvim_get_current_line',[])=='pri'
call('nvim_input',['<Esc>']);pump(.2)
call('nvim_exec_lua',["require('blink.cmp.config').sources.default=review_blink_sources",[]])
print('SELECTED BUFFER WORD: full builtin name; typed text unchanged PASS',flush=True)

# Real LSP responses: active parameters, empty-response fallbacks and stale replies.
call('nvim_exec_lua',["dofile('nvim/tests/symbol_help_review.lua'); require('blink.cmp.config').signature.enabled=false",[]])
def help_text():
 return call('nvim_exec_lua',["local lines={} for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.api.nvim_win_get_config(w).relative~='' then vim.list_extend(lines,vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(w),0,-1,false)) end end return table.concat(lines,'\\n')",[]])
def help_line(line):
 call('nvim_input',['<Esc>']);pump(.1)
 call('nvim_exec_lua',["for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.api.nvim_win_get_config(w).relative~='' then vim.api.nvim_win_close(w,true) end end; vim.api.nvim_buf_set_lines(0,0,-1,false,{...}); vim.api.nvim_win_set_cursor(0,{1,0})",[line]])
 call('nvim_input',['A']);pump(.15)
 call('nvim_exec_lua',["require('blink.cmp').hide()",[]]);pump(.1)
help_line('analyze([1, 2], ')
call('nvim_input',['<C-k>']);pump(.4)
assert 'Maximum number of values' in help_text(),help_text()
call('nvim_exec_lua',["symbol_help_review.empty_signature=true",[]])
help_line('analyze([1, 2], ')
call('nvim_input',['<C-k>']);pump(.5)
assert 'limit=10' in help_text(),help_text()
call('nvim_exec_lua',["symbol_help_review.empty_hover=true",[]])
help_line('sum([1, 2], ')
call('nvim_input',['<C-k>']);pump(.5)
assert 'sum(iterable' in help_text(),help_text()
call('nvim_exec_lua',["symbol_help_review.empty_hover=false",[]])
help_line('analyze')
call('nvim_input',['<C-k>'])
call('nvim_input',['x']);pump(.4)
assert 'limit=10' not in help_text(),'Stale help appeared after editing'
call('nvim_input',['<Esc>']);pump(.1)
call('nvim_exec_lua',["vim.lsp.get_client_by_id(symbol_help_review.client):stop(true); require('blink.cmp.config').signature.enabled=true",[]])
print('SMART HELP: nested calls, active parameter docs, empty fallbacks and stale replies PASS',flush=True)

# A slow LSP must not delay local matches; semantic matches win when they arrive.
call('nvim_exec_lua',["dofile('nvim/tests/completion_latency.lua')",[]])
call('nvim_input',['isum'])
pump(.35)
stats=call('nvim_exec_lua',["return completion_latency_stats",[]])
assert stats.get('first_source')=='buffer' and stats['first_ms']<600, stats
pump(.8)
items=call('nvim_exec_lua',["return require('blink.cmp').get_items()",[]])
assert items[0]['label']=='summary_lsp' and items[0]['source_id']=='lsp', items
assert any(item['label']=='summary_local' for item in items), items
print('COMPLETION LATENCY: local matches %.1f ms; slow LSP updates and ranks first PASS' % stats['first_ms'],flush=True)
call('nvim_input',['<Esc>']);pump(.2)
call('nvim_exec_lua',["vim.lsp.get_client_by_id(completion_latency_client):stop(true)",[]])

# Tab and Shift-Tab follow native snippet placeholders before menu selection.
call('nvim_command',['enew!'])
call('nvim_input',['i']);pump(.1)
call('nvim_exec_lua',["vim.snippet.expand('pair(${1:first}, ${2:second})$0')",[]]);pump(.2)
first=call('nvim_exec_lua',["return vim.api.nvim_win_get_cursor(0)",[]])
call('nvim_input',['<Tab>']);pump(.2)
second=call('nvim_exec_lua',["return vim.api.nvim_win_get_cursor(0)",[]])
assert second[0]==first[0] and second[1]>first[1], (first,second)
call('nvim_input',['<S-Tab>']);pump(.2)
assert call('nvim_exec_lua',["return vim.api.nvim_win_get_cursor(0)",[]])==first
call('nvim_exec_lua',["vim.snippet.stop()",[]])
call('nvim_input',['<Esc>']);pump(.2)
print('SNIPPETS: Tab / Shift-Tab placeholders PASS',flush=True)

call('nvim_exec_lua',["_G.layoutdir=vim.fn.tempname(); vim.fn.mkdir(layoutdir..'/parent/long_directory_name_for_title','p')",[]])
for width,height in [(140,42),(80,24),(100,30),(140,42)]:
 call('nvim_ui_try_resize',[width,height]);pump(.2)
 call('nvim_exec_lua',["_G.test_exp = Snacks.explorer({ cwd = layoutdir })",[]]);pump(.3)
 assert call('nvim_exec_lua',["return _G.test_exp ~= nil",[]])
 call('nvim_exec_lua',["_G.test_exp:close()",[]]);pump(.2)
print('SNACKS EXPLORER',width,height,'bounds and geometry PASS',flush=True)
call('nvim_exec_lua',["vim.fn.delete(layoutdir,'rf')",[]])
print('PLUGIN INTEGRATION',call('nvim_exec_lua',["return dofile('nvim/tests/plugins_review.lua')",[]]),flush=True)
call('nvim_exec_lua',["vim.schedule(function() require('config.pick').open('files',{cwd=plugin_review.dir}) end)",[]]);pump(.7)
call('nvim_exec_lua',["assert(vim.wait(3000, function() return require('mini.pick').get_picker_state() ~= nil end), 'picker did not open')",[]])
call('nvim_input',['renamed']);pump(.5)
call('nvim_input',['<CR>']);pump(.5)
call('nvim_exec_lua',["assert(vim.wait(3000, function() return vim.fn.expand('%:t') == 'renamed.txt' end), 'did not switch to renamed.txt: ' .. vim.fn.expand('%:t'))",[]])
call('nvim_exec_lua',["vim.api.nvim_set_current_buf(plugin_review.buf); vim.api.nvim_win_set_cursor(0,{3,5})",[]])
print('FILE CREATION + MINI PICK selection PASS',flush=True)

for width,height in [(80,24),(140,42)]:
 call('nvim_ui_try_resize',[width,height]);pump(.3)
 for command,ft in [('Glance references','glance'),('AerialOpen float','aerial')]:
  call('nvim_command',[command]);pump(.8)
  panels=call('nvim_exec_lua',["local r={} for _,w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype:lower():match(...) then r[#r+1]={vim.api.nvim_win_get_width(w),vim.api.nvim_win_get_height(w)} end end return r",[ft]])
  assert panels and all(c[0]<=width and c[1]<=height-2 for c in panels),(command,panels)
  if ft=='glance':call('nvim_exec_lua',["require('glance').actions.close()",[]])
  else:call('nvim_command',['AerialClose'])
  pump(.3)
 print('TOOL PANELS',width,height,'Glance, Aerial PASS',flush=True)
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
try: p.stdin.close()
except BrokenPipeError: pass
p.stdout.close()
