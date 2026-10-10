-- Station report presentation; health scans and repair actions stay in station.lua.
local M = {}
local ui = require('config.ui')
local items, state, actions = {}, {}, {}
local namespace = vim.api.nvim_create_namespace('BlackStationReport')
local function fit(text, width)
  if vim.fn.strdisplaywidth(text) <= width then return text end
  local length = vim.fn.strchars(text)
  while length > 0 and vim.fn.strdisplaywidth(vim.fn.strcharpart(text,0,length)..'…') > width do length=length-1 end
  return vim.fn.strcharpart(text,0,length)..'…'
end
local function frame()
  local width = math.max(1,math.min(76,vim.o.columns-4))
  local height = math.max(1,math.min(30,vim.o.lines-4))
  return {relative='editor', width=width, height=height,
    row=math.max(0,math.floor((vim.o.lines-height-2)/2)),
    col=math.max(0,math.floor((vim.o.columns-width-2)/2)), border=ui.border,
    title=' '..fit('Station Health · '..(state.current_station or 'unknown'),math.max(1,width-4))..' ',
    title_pos='center', footer=fit(width >= 60 and ' f fix  v venv  t tools  r recheck  q close '
      or width >= 30 and ' f fix  r recheck  q close ' or ' f v t r q ', math.max(1,width-2)),
    footer_pos='center'}
end
local function render()
  local lines, marks = {}, {}
  local function add(line, hl)
    lines[#lines+1]=line
    if hl then marks[#marks+1]={#lines-1,hl} end
  end
  if state.station_changed then
    add('WORKSTATION CHANGED', 'DiagnosticWarn')
    add('  '..(state.prev_station or 'unknown')..' -> '..(state.current_station or 'unknown'), 'BlackMuted')
    add('  Local environments may need re-linking.', 'BlackMuted')
    add('')
  end
  for _, item in ipairs(items) do
    local status = ({error='ERROR',warn='WARN',info='INFO'})[item.status] or 'OK'
    local hl = ({error='DiagnosticError',warn='DiagnosticWarn',info='DiagnosticInfo'})[item.status] or 'DiagnosticOk'
    add('['..status..'] '..item.label,hl)
    add('  '..tostring(item.details or ''),'BlackDocs')
    add('')
  end
  add('ACTIONS', 'BlackDashboardHeading')
  for _, action in ipairs({{'f','Repair safe issues'}, {'v','Rebuild project environment'},
    {'t','Install or restore tools'}, {'r','Recheck station'}, {'q','Close report'}}) do
    add('  '..action[1]..'  '..action[2], 'BlackDocs')
  end
  vim.bo[M.buf].modifiable=true
  vim.api.nvim_buf_set_lines(M.buf,0,-1,false,lines)
  vim.bo[M.buf].modifiable=false
  vim.api.nvim_buf_clear_namespace(M.buf,namespace,0,-1)
  for _, mark in ipairs(marks) do vim.api.nvim_buf_add_highlight(M.buf,namespace,mark[2],mark[1],0,-1) end
end
function M.close()
  local win,buf=M.win,M.buf
  M.win,M.buf=nil,nil
  vim.g.station_health_win=nil
  if win and vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win,true) end
  if buf and vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf,{force=true}) end
end
function M.show(report, context, handlers)
  items,state,actions=report,context,handlers
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    render(); vim.api.nvim_win_set_config(M.win,frame()); vim.api.nvim_set_current_win(M.win); return M.win
  end
  M.buf=vim.api.nvim_create_buf(false,true)
  vim.bo[M.buf].bufhidden='wipe'
  vim.bo[M.buf].buftype='nofile'
  vim.bo[M.buf].filetype='stationhealth'
  render()
  local opts=frame(); opts.style='minimal'
  M.win=vim.api.nvim_open_win(M.buf,true,opts)
  local win=M.win
  vim.g.station_health_win=win
  for name,value in pairs({wrap=true,linebreak=true,breakindent=true,number=false,relativenumber=false,
    signcolumn='no',foldcolumn='0',spell=false,
    winhighlight='Normal:BlackDocs,FloatBorder:BlackDocsBorder,FloatTitle:BlackDocsTitle,FloatFooter:BlackMuted'}) do vim.wo[win][name]=value end
  for _,key in ipairs({'q','<Esc>'}) do vim.keymap.set('n',key,M.close,{buffer=M.buf,nowait=true,silent=true}) end
  for _,key in ipairs({'f','v','t','r'}) do
    vim.keymap.set('n',key,function()
      local action=actions[key]; M.close(); if action then action() end
    end,{buffer=M.buf,nowait=true,silent=true})
  end
  vim.keymap.set('n','j','gj',{buffer=M.buf,silent=true})
  vim.keymap.set('n','k','gk',{buffer=M.buf,silent=true})
  vim.api.nvim_create_autocmd('WinClosed',{pattern=tostring(win),once=true,callback=function()
    if M.win==win then M.win,M.buf=nil,nil; vim.g.station_health_win=nil end
  end})
  return win
end
local group=vim.api.nvim_create_augroup('BlackStationReport',{clear=true})
local function resize()
  if M.win and vim.api.nvim_win_is_valid(M.win) then vim.api.nvim_win_set_config(M.win,frame()) end
end
vim.api.nvim_create_autocmd('VimResized',{group=group,callback=resize})
vim.api.nvim_create_autocmd('User',{group=group,pattern='BlackUIPresetChanged',callback=resize})
return M
