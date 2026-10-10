-- Full config: nvim --headless '+lua dofile("nvim/tests/signature_ui_review.lua")' +qa!
local formatter, help, docs = require('config.signature_help'),require('config.symbol_help'),require('config.documentation')
local unicode = {signatures={{label='f(😀: str, limit: int)',parameters={{label={2,4}},{label={11,16},documentation='Maximum count'}}}},activeParameter=1}
local lines,hl = formatter.format(unicode,'python')
assert(lines[2]:sub(hl[2]+1,hl[4]) == 'limit','UTF16 parameter offsets produced wrong byte range')
unicode.activeParameter=0
local _,emoji = formatter.format(unicode,'python')
assert(lines[2]:sub(emoji[2]+1,emoji[4]) == '😀','non-BMP label range broken')
assert(formatter.format({signatures={{label='f()'}},activeSignature=99},'python'),'invalid active overload did not default safely')
assert(not formatter.format({signatures={{}}},'python'),'malformed signature was rendered')
assert(formatter.format({signatures={{label='f()',parameters='invalid'}}},'python'),'malformed parameter list raised an error')
assert(formatter.format({signatures={{label='f()',parameters='malformed'}}},'python'),'malformed parameter collection crashed formatter')
vim.cmd.enew()
vim.bo.filetype='python'
vim.api.nvim_buf_set_lines(0,0,-1,false,{'analyze(values, '})
vim.api.nvim_win_set_cursor(0,{1,15})
local origin, buf = vim.api.nvim_get_current_win(),vim.api.nvim_get_current_buf()
local old_clients, old_notify, old_timeout = vim.lsp.get_clients,vim.notify,help.timeout_ms
local notices,cancelled,callbacks = {},{},{}
help.timeout_ms=50
vim.notify=function(message) notices[#notices+1]=message end
local result={activeSignature=1,activeParameter=0,signatures={
  {label='analyze(text: str) -> str',parameters={{label='text',documentation='Input text'}}},
  {label='analyze(values: list[int], limit: int) -> int',activeParameter=1,
   documentation='Analyze values.',parameters={{label='values'},{label='limit',documentation='Maximum values to inspect'}}},
}}
local client={offset_encoding='utf-16',request=function(_,method,params,callback)
  callbacks[#callbacks+1]=callback
  vim.defer_fn(function() callback(nil,result) end,5)
  return true,#callbacks
end,cancel_request=function(_,id) cancelled[#cancelled+1]=id end}
vim.lsp.get_clients=function() return {client} end
help.show(nil,true,true)
local function float()
 for _,win in ipairs(vim.api.nvim_list_wins()) do
  if vim.api.nvim_win_get_config(win).relative ~= '' then return win,vim.api.nvim_win_get_buf(win) end
 end
end
assert(vim.wait(500,function() return float() ~= nil end),'signature window never opened')
local win,floatbuf=float()
local content=vim.api.nvim_buf_get_lines(floatbuf,0,-1,false)
assert(content[2]:find('list[int]',1,true),'active overload not shown first')
assert(table.concat(content,'\n'):find('Parameter 2/2 · limit',1,true),'per-signature activeParameter ignored')
assert(content[6] == 'Maximum values to inspect','parameter docs not prioritized before general docs')
local marks=vim.api.nvim_buf_get_extmarks(floatbuf,vim.api.nvim_create_namespace('symbol_help_parameter'),0,-1,{details=true})
assert(#marks==1,'active parameter highlight missing')
local mark=marks[1]
assert(content[mark[2]+1]:sub(mark[3]+1,mark[4].end_col)=='limit','real float highlighted wrong parameter')
vim.api.nvim_set_current_win(win)
local next_signature=vim.fn.maparg(']s','n',false,true).callback
assert(type(next_signature)=='function','overload navigation mapping missing')
next_signature()
win,floatbuf=float()
assert(vim.api.nvim_get_current_win()==win,'overload switch lost docs focus')
assert(table.concat(vim.api.nvim_buf_get_lines(floatbuf,0,-1,false),'\n'):find('Input text',1,true),'overload switch failed')
-- A focused overload menu must not act on a replaced source buffer.
local switched=vim.api.nvim_create_buf(true,false)
vim.api.nvim_win_set_buf(origin,switched)
local stale_cycle=vim.fn.maparg(']s','n',false,true).callback
stale_cycle()
assert(not float(),'overload menu survived a replaced source buffer')
vim.api.nvim_win_set_buf(origin,buf)
vim.api.nvim_buf_delete(switched,{force=true})
docs.close();vim.api.nvim_set_current_win(origin)
-- Silent and empty clients must complete within a bounded deadline.
local silent={offset_encoding='utf-16',request=function()return true,99 end,cancel_request=client.cancel_request}
local empty={offset_encoding='utf-16',request=function(_,_,_,callback)callback(nil,nil);return true,100 end}
vim.lsp.get_clients=function()return{silent,empty}end
notices={}
help.show(nil,true,true)
assert(vim.wait(500,function()return #notices>0 end),'silent client prevented bounded completion')
assert(cancelled[#cancelled]==99,'timed-out request was not cancelled')
assert(not float(),'empty signatures opened a hover fallback')
-- New request cancels superseded transport work; same-buffer split changes are stale.
vim.lsp.get_clients=function()return{silent}end
help.show(nil,true,true);help.cancel()
assert(cancelled[#cancelled]==99,'explicit cancellation did not reach client')
vim.lsp.get_clients=function()return{client}end
help.show(nil,true,true)
vim.cmd.vsplit()
assert(vim.api.nvim_get_current_win()~=origin and vim.api.nvim_get_current_buf()==buf)
vim.wait(100)
assert(not float(),'response opened in a different window showing the same buffer')
vim.lsp.get_clients,vim.notify,help.timeout_ms=old_clients,old_notify,old_timeout
help.cancel();docs.close()
print('SIGNATURE UI PASS: UTF16 ranges, parameter priority, overload cycling/focus, timeout/cancellation, exact-window staleness')
