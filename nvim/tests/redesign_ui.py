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




call('nvim_ui_attach',[140,42,{'rgb':True,'ext_linegrid':True}]);pump(1)
import sys;sys.path.insert(0,str(root/'nvim/tests'))
from PIL import Image, ImageDraw, ImageFont
font_path=os.environ.get('NVIM_PREVIEW_FONT') or subprocess.check_output(['fc-match','-f','%{file}','JetBrainsMono Nerd Font Mono'],text=True)
font=ImageFont.truetype(font_path,16)
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
   d.text((x*10,y*22+2),char,font=font,fill=f'#{f:06x}',stroke_width=0)
 im.save(output)

save_grid(grid,attrs,default_fg,default_bg,root/'nvim/assets/redesign-dashboard.png')
call('nvim_command',['edit nvim/lua/config/debugging.lua']);pump(.5)
call('nvim_command',['vsplit nvim/lua/plugins/debugging.lua']);pump(.3)
save_grid(grid,attrs,default_fg,default_bg,root/'nvim/assets/redesign-editor.png')
call('nvim_command',['only']);pump(.1)
for width,height in [(140,42),(80,24)]:
 call('nvim_ui_try_resize',[width,height]);pump(.2)
 call('nvim_exec_lua',["require('config.pick').open('files')",[]]);pump(.7)
 state=call('nvim_exec_lua',["local p=Snacks.picker.get()[1]; return {count=#p:items(), width=vim.api.nvim_win_get_width(p.list.win.win)}",[]])
 assert state['count']>0 and state['width']<=width,state
 for win in call('nvim_list_wins',[]):
  config=call('nvim_win_get_config',[win])
  if config.get('relative'):
   row,col=call('nvim_win_get_position',[win]);w=call('nvim_win_get_width',[win]);h=call('nvim_win_get_height',[win])
   assert row>=0 and col>=0 and row+h<=height and col+w<=width,(row,col,w,h,width,height)
 if width==140: save_grid(grid,attrs,default_fg,default_bg,root/'nvim/assets/redesign-picker.png')
 call('nvim_input',['<Esc>']);pump(.3)
 assert call('nvim_exec_lua',["return #Snacks.picker.get()",[]])==0
assert call('nvim_exec_lua',["return require('config.workspace_info').get().branch",[]])=='codex/nvim-performance-ui'
messages=call('nvim_exec_lua',["return vim.api.nvim_exec2('messages',{output=true}).output",[]])
assert 'Error executing' not in messages and 'Failed to load' not in messages,messages
print('REDESIGN UI: dashboard, split editor, async branch, responsive preview picker and Escape PASS')
req('nvim_command',['qa!']);p.wait(timeout=10)
