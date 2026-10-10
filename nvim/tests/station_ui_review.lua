-- Exercise the real health entry point without scanning or changing the host.
local station, report = require('config.station'), require('config.station_ui')
local check, state = station.check, station.state
local details = 'Complete environment path: /goinfre/review/project/.venv/bin/python; '..string.rep('long detail ',15)
local items = {
  {status='ok', label='Neovim', details='Ready'},
  {status='warn', label='Python environment', details=details},
  {status='error', label='Compiler', details='Missing tool (test fixture)'},
}
station.check = function(callback) callback(items) end
station.state = {current_station='review-workstation',prev_station='previous',station_changed=true}
station.health()
local win, buf = report.win, report.buf
assert(vim.g.station_health_win == win and vim.bo[buf].filetype == 'stationhealth')
assert(vim.wo[win].wrap and vim.wo[win].linebreak, 'health details must wrap')
assert(table.concat(vim.api.nvim_buf_get_lines(buf,0,-1,false),'\n'):find(details,1,true), 'details truncated in report data')
for _,size in ipairs({{140,42},{80,24},{40,20},{24,12}}) do
  vim.o.columns,vim.o.lines=size[1],size[2]
  vim.api.nvim_exec_autocmds('VimResized',{})
  local frame=vim.api.nvim_win_get_config(win)
  local row,col=unpack(vim.api.nvim_win_get_position(win))
  assert(row>=0 and col>=0 and row+frame.height+2<=size[2] and col+frame.width+2<=size[1], 'station frame overflows terminal')
  assert(vim.fn.strdisplaywidth(frame.footer[1][1])<=frame.width, 'station footer overflows border')
end
local windows=#vim.api.nvim_list_wins()
station.health()
assert(report.win==win and #vim.api.nvim_list_wins()==windows, 'recheck duplicated report window')
local access=require('config.accessibility')
access.set(true)
assert(vim.api.nvim_win_get_config(win).border[1]=='┌', 'open report did not update accessible border')
access.set(false)
report.close()
assert(not vim.api.nvim_win_is_valid(win) and not vim.api.nvim_buf_is_valid(buf) and not vim.g.station_health_win, 'report leaked window or buffer')
for _,key in ipairs({'f','v','t','r'}) do
  local calls=0
  report.show(items,station.state,{[key]=function()
    assert(report.win==nil and not vim.g.station_health_win, 'action ran before report closed')
    calls=calls+1
  end})
  vim.fn.maparg(key,'n',false,true).callback()
  assert(calls==1,'wrong report action')
end
station.check,station.state=check,state
print('STATION UI PASS: real entry point, resize through 24 columns, full details, window reuse, accessibility, actions and cleanup')
