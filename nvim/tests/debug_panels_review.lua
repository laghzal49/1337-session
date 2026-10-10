require('lazy').load({plugins={'nvim-dap'}})
local panels = require('config.debug_panels')
vim.cmd.enew()
local editor = vim.api.nvim_get_current_win()
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(buf,0,-1,false,{'unsaved editor data'})
for _,size in ipairs({{140,42},{80,24},{40,20},{140,42}}) do
  vim.o.columns,vim.o.lines=size[1],size[2]
  if panels.active then vim.api.nvim_exec_autocmds('VimResized',{}) else panels.open() end
  assert(vim.api.nvim_get_current_win()==editor,'debug layout stole editor focus')
  assert(vim.api.nvim_win_get_width(editor)>=math.floor(size[1]*0.65), 'debug layout crowded out code')
  assert(vim.api.nvim_win_get_height(editor)>=math.floor(size[2]*0.5),'debug layout consumed editor height')
  local count,scopes=0,0
  for _,win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local ft=vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if ft:match('^dapui_') or ft=='dap-repl' then count=count+1 end
    if ft=='dapui_scopes' then scopes=scopes+1 end
  end
  assert(scopes==1,'scopes missing or duplicated')
  assert(count==(size[1]>=120 and 6 or size[1]>=80 and 4 or 1),'unexpected layout profile')
end
panels.toggle()
assert(not panels.active and #vim.api.nvim_tabpage_list_wins(0)==1,'toggle left debug panels behind')
panels.open()
local original_tab=vim.api.nvim_get_current_tabpage()
vim.cmd.tabnew()
local other_tab=vim.api.nvim_get_current_tabpage()
panels.close()
assert(vim.api.nvim_get_current_tabpage()==other_tab and #vim.api.nvim_tabpage_list_wins(original_tab)==1,'session cleanup leaked panels or switched tabs')
vim.cmd.tabclose()
panels.open()
local repurposed=next(panels.owned)
vim.api.nvim_win_set_buf(repurposed,buf)
vim.o.columns=40
vim.api.nvim_exec_autocmds('VimResized',{})
assert(vim.api.nvim_win_is_valid(repurposed) and vim.api.nvim_win_get_buf(repurposed)==buf,'resize closed a repurposed panel')
assert(vim.api.nvim_buf_get_lines(buf,0,-1,false)[1]=='unsaved editor data','debug layout changed editor text')
require('dapui').close()
print('DEBUG PANELS PASS: three layouts, live resize, focus, toggle, repurposed window and unsaved text safety')
