# Requires msgpack and installed Neovim plugins. Runs isolated unsaved test buffers.
import os, subprocess, time, select, msgpack
from pathlib import Path
import shutil, atexit
root=Path(__file__).resolve().parents[2]
capture_dir=Path(os.environ.get('NVIM_CAPTURE_DIR','/tmp/1337-popup-preview'))
capture_dir.mkdir(parents=True,exist_ok=True)
exe=os.environ.get('NVIM_BIN') or shutil.which('nvim')
if not exe: raise SystemExit('Neovim is required; set NVIM_BIN if it is not on PATH.')
env=os.environ.copy()
env.update(NVIM_APPNAME='nvim',XDG_CONFIG_HOME=str(root),TERM='xterm-256color',NVIM_BLACK_DOCS_AUTO_UPDATE='0')
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
 while i not in pending and time.time()<until:pump(.005)
 result=pending.pop(i,None)
 if not result:raise RuntimeError('timeout: '+method)
 if result[2]:raise RuntimeError(str(result[2]))
 return result[3]

call('nvim_ui_attach',[140,42,{'rgb':True,'ext_linegrid':True}]);pump(1)
import sys;sys.path.insert(0,str(root/'nvim/tests'))
from PIL import Image, ImageDraw, ImageFont
font_path=os.environ.get('NVIM_PREVIEW_FONT') or subprocess.check_output(['fc-match','-f','%{file}','JetBrainsMono Nerd Font Mono'],text=True)
font=ImageFont.truetype(font_path,16)
bold_path=subprocess.check_output(['fc-match','-f','%{file}','JetBrainsMono Nerd Font Mono:style=Bold'],text=True)
bold_font=ImageFont.truetype(bold_path,16)
def save_grid(grid,attrs,fg,bg,output):
 im=Image.new('RGB',(len(grid[0])*10,len(grid)*22)); d=ImageDraw.Draw(im)
 for y,row in enumerate(grid):
  for x,(char,hl) in enumerate(row):
   a=attrs.get(hl,{}); f,b=a.get('foreground',fg),a.get('background',bg)
   if a.get('reverse'): f,b=b,f
   d.rectangle((x*10,y*22,x*10+9,y*22+21),fill=f'#{b:06x}')
 for y,row in enumerate(grid):
  for x,(char,hl) in enumerate(row):
   a=attrs.get(hl,{});f=a.get('background',bg) if a.get('reverse') else a.get('foreground',fg)
   d.text((x*10,y*22+2),char,font=bold_font if a.get('bold') else font,fill=f'#{f:06x}',stroke_width=0)
 im.save(output)


def lua(code): return call('nvim_exec_lua',[code,[]])
def keys(k,wait=.2): call('nvim_input',[k]);pump(wait)
def shot(name):
 pump(.2)
 save_grid(grid,attrs,default_fg,default_bg,capture_dir/('popup-'+name+'.png'))
 print(name,flush=True)
lua("dofile('nvim/tests/documentation_fixture.lua'); require('config.notifications').dismiss()")
keys('K');shot('hover-140')
keys('K');shot('hover-focused-140');keys('q')
lua("require('blink.cmp').add_source_provider('popup_review',{name='LSP',module='popup_review.source'}); require('blink.cmp.config').sources.default={'popup_review'}")

lua("""
package.preload['popup_review.source']=function()
 local s={}; function s.new() return setmetatable({},{__index=s}) end
 function s:get_completions(_,cb) cb({items={
 {label='analyze',kind=3,documentation={kind='markdown',value=documentation_review.markdown}},
 {label='analyze_values',kind=3,labelDetails={description='project.analytics'},documentation={kind='markdown',value=documentation_review.markdown}},
 {label='analysis_limit',kind=6},
 },is_incomplete_forward=false,is_incomplete_backward=false}) end
 return s
end
vim.bo.filetype='lua'; vim.api.nvim_buf_set_lines(0,0,-1,false,{'-- Task queue: aggregate completed jobs','','local result = ana','','-- TODO validate limits before running','local function total_completed(jobs)','  local count = 0','  for _, job in ipairs(jobs) do','    if job.status == "complete" then','      count = count + 1','    end','  end','  return count','end'})
vim.api.nvim_win_set_cursor(0,{3,18})
""")
for width,height in [(140,42),(80,24),(40,20)]:
 call('nvim_ui_try_resize',[width,height]);pump(.1)
 keys('A');lua("require('blink.cmp').show()");pump(.3);keys('<C-n>',.4)
 lua("require('blink.cmp').show_documentation()");shot('completion-'+str(width))
 keys('<Esc>')
 keys(':colo',.5);shot('command-'+str(width));keys('<Esc>')
 lua("vim.ui.input({prompt='Rename symbol',default='analysis_limit'},function(v) _G.popup_input_value=v end)")
 shot('input-'+str(width));keys('<Esc>')
 lua("require('config.notifications').dismiss(); vim.notify('Type checker found an incompatible return value. Open diagnostics to inspect the source.',vim.log.levels.WARN,{title='Python'})")
 shot('notice-'+str(width))
 lua("require('config.notifications').history()")
 shot('history-'+str(width));keys('<Esc>')
 lua("vim.schedule(function() require('config.lsp_actions').select({'Extract function','Rename symbol'}, {prompt='Code actions'}, function() end) end)")
 shot('actions-'+str(width));keys('<Esc>')
call('nvim_ui_try_resize',[140,42]);pump(.1)
lua("require('config.debug_panels').inspect('watches')")
shot('debug-watch-140');keys('<Esc>')
lua("require('config.pick').open('files')");shot('picker-140');keys('<Esc>')
lua("vim.diagnostic.set(vim.api.nvim_create_namespace('popup-review'),0,{{lnum=2,col=0,message='Expected an integer return value, received a string instead.',source='type checker',code='invalid-return-type',severity=1}});require('config.popups').diagnostic()")
shot('diagnostic-140')
errors=lua("return {errmsg=vim.v.errmsg,notices=vim.tbl_filter(function(n) return n.level=='ERROR' end,require('mini.notify').get_all())}")
assert not errors['errmsg'] and not errors['notices'],errors
print('POPUP CAPTURE PASS: no runtime errors',flush=True)
lua("vim.fn.delete(documentation_review.dir,'rf')")
p.terminate()
