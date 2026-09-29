"""Capture the real Neovim UI grid; requires msgpack and ImageMagick.
Run from the repo root: python3 nvim/tests/capture_makefile.py
"""
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



call('nvim_ui_attach', [120, 36, {'rgb': True, 'ext_linegrid': True}])
pump(1)
call('nvim_exec_lua', ["local plugins=require('lazy.core.config').plugins; for _, name in ipairs({'nvim-dap','nvim-dap-ui','nvim-dap-python','nvim-dap-virtual-text','nvim-nio'}) do assert(not plugins[name], name) end; assert(vim.fn.exists(':MakeDebug')==0); assert(vim.fn.maparg('<leader>dc','n')==''); assert(vim.fn.maparg('<F5>','n')=='')", []])
call('nvim_exec_lua', ["local m=require('config.makefile'); local old=Snacks.terminal; local commands={}; Snacks.terminal=function(cmd) commands[#commands+1]=cmd end; m.run(); m.run('test; echo unsafe'); Snacks.terminal=old; assert(#commands[1]==5 and commands[1][4]=='-f'); assert(commands[2][6]=='--' and commands[2][7]=='test; echo unsafe')", []])
call('nvim_command', ['edit Makefile'])
pump(.4)
for width, height in [(80, 24), (120, 36)]:
 call('nvim_ui_try_resize', [width, height])
 call('nvim_exec_lua', ["vim.schedule(function() require('config.makefile').pick() end)", []])
 pump(.5)
 state = call('nvim_exec_lua', ["local p=require('mini.pick'); local s=p.get_picker_state(); assert(s, 'Make picker did not open'); return {items=#p.get_picker_items(),width=vim.api.nvim_win_get_width(s.windows.main),height=vim.api.nvim_win_get_height(s.windows.main)}", []])
 assert state['items'] == 6 and state['width'] <= width and state['height'] <= height, state
 screen = '\n'.join(''.join(c for c, h in row) for row in grid)
 assert 'Run Makefile Target' in screen and 'standalone' in screen, screen
 if width == 80:
  call('nvim_input', ['<Esc>'])
  pump(.2)

from ui_capture import save_grid
output = root / 'nvim/assets/makefile.png'
save_grid(grid, attrs, default_fg, default_bg, output)
print('PASS: DAP absent; Make picker at 80×24 and 120×36; screenshot:', output)
call('nvim_input', ['<Esc>'])
pump(.2)
req('nvim_command', ['qa!'])
p.wait(timeout=5)
