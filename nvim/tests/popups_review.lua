-- First invocation must initialize the debugger without a dependency loop.
vim.cmd.enew()
vim.api.nvim_buf_set_lines(0,0,-1,false,{'unsaved popup review'})
local editor, source = vim.api.nvim_get_current_win(),vim.api.nvim_get_current_buf()
require('lazy').load({plugins={'nvim-lspconfig'}})
local diagnostic_ns=vim.api.nvim_create_namespace('popup_diagnostics_review')
vim.diagnostic.set(diagnostic_ns,source,{{lnum=0,col=0,severity=1,source='test server',code='E123',message='Invalid value'}})
local diagnostic_buf,diagnostic_win=require('config.popups').diagnostic()
local diagnostic_text=table.concat(vim.api.nvim_buf_get_lines(diagnostic_buf,0,-1,false),'\n')
local _,code_count=diagnostic_text:gsub('E123','')
assert(code_count==1 and diagnostic_text:find('test server',1,true),'diagnostic code duplicated or source omitted')
assert(vim.wo[diagnostic_win].winhighlight:find('NormalNC:BlackDocs',1,true),'diagnostic inherited the inactive editor background')
vim.api.nvim_win_close(diagnostic_win,true)
vim.diagnostic.reset(diagnostic_ns,source)
require('config.debug_panels').inspect('watches')
assert(vim.wait(2000,function() return vim.bo.filetype=='dapui_watches' end),'watch inspector did not open')
local win=vim.api.nvim_get_current_win()
assert(vim.wait(500,function() return vim.api.nvim_win_get_config(win).footer~=nil end),'debug footer missing')
assert(vim.api.nvim_win_get_config(win).relative=='editor','inspector is not anchored to editor')
vim.api.nvim_win_close(win,true)
assert(vim.api.nvim_get_current_win()==editor and vim.api.nvim_get_current_buf()==source,'inspector lost source window')

-- A history float follows live terminal changes without replacing editor text.
require('config.notifications').notify('A long warning retained for searching',vim.log.levels.WARN)
require('config.notifications').history()
win=vim.api.nvim_get_current_win()
for _,size in ipairs({{40,20},{140,42},{80,24}}) do
  vim.o.columns,vim.o.lines=size[1],size[2]
  vim.api.nvim_exec_autocmds('VimResized',{})
  assert(vim.wait(500,function()
    local config=vim.api.nvim_win_get_config(win)
    return config.width<=size[1]-6 and config.height<=size[2]-6
  end),'history overflow after resize')
end
local saved=vim.api.nvim_win_get_config(win)
local other=vim.api.nvim_create_buf(false,true)
vim.api.nvim_win_set_buf(win,other)
vim.o.columns=40
vim.api.nvim_exec_autocmds('VimResized',{})
vim.wait(60,function() return false end)
assert(vim.api.nvim_win_get_config(win).width==saved.width,'popup styling changed a repurposed window')
vim.api.nvim_win_close(win,true)
assert(vim.api.nvim_buf_get_lines(source,0,-1,false)[1]=='unsaved popup review','popup modified source text')
print('POPUPS PASS: debugger first invocation, history resize, repurposed-window ownership and unsaved text')
