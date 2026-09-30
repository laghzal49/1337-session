-- SmartDocs identity and content policy; explicit requests only.
local store = require('config.docs_store')
local resolver = require('config.docs_resolver')
local docs = require('config.documentation')
local deep = require('config.deep_docs')
local dir = vim.fn.tempname()
vim.fn.mkdir(dir .. '/sets/python/test/pages', 'p')
local entries = {{name='pathlib.Path.exists()',path='exists'},{name='sum()',path='sum'}}
vim.fn.writefile({vim.json.encode({entries=entries,exact={['pathlib.Path.exists']=1,sum=2},suffix={['Path.exists']=1}})},dir..'/sets/python/test/index.json')
vim.fn.writefile({'# exists','LOCAL OFFLINE PATH REFERENCE'},dir..'/sets/python/test/pages/exists.md')
vim.fn.writefile({'# sum','LOCAL OFFLINE BUILTIN REFERENCE'},dir..'/sets/python/test/pages/sum.md')
vim.fn.writefile({vim.json.encode({schema=1,docsets={python={slug='python',lang='python',root='sets/python/test',entries=2,pages=2,bytes=100,updated_at=1}}})},dir..'/manifest.json')
deep.setup({data_dir=dir})
local real_clients = vim.lsp.get_clients
local calls, responses = 0, {}
local client = {id=989,name='mock-python',offset_encoding='utf-16',supports_method=function(_,method) return method=='textDocument/hover' end,
 request=function(_,method,params,callback) calls=calls+1; responses[#responses+1]=callback; return true,calls end,
 cancel_request=function() end}
vim.lsp.get_clients=function() return {} end
local code=vim.api.nvim_get_current_buf()
local function source(lines,row,needle)
 docs.close(); vim.api.nvim_set_current_buf(code); vim.bo[code].filetype='python'
 vim.api.nvim_buf_set_lines(code,0,-1,false,lines)
 local col=assert(lines[row]:find(needle,1,true))-1
 vim.api.nvim_win_set_cursor(0,{row,col})
end
local function resolve()
 local result; resolver.resolve(function(saved) result=saved end); assert(result); return result
end
source({'from pathlib import Path','Path.exists()'},2,'exists')
assert(resolve().candidates[1]=='pathlib.Path.exists','imported class method unresolved')
source({'from pathlib import Path as P','p = P(".")','p.exists()'},3,'exists')
assert(resolve().candidates[1]=='pathlib.Path.exists','constructor receiver alias unresolved')
source({'import pathlib as pl','p: pl.Path','p.exists()'},3,'exists')
assert(resolve().candidates[1]=='pathlib.Path.exists','annotated receiver unresolved')
source({'from pathlib import Path','def work(p: Path):','    p.exists()'},3,'exists')
assert(resolve().candidates[1]=='pathlib.Path.exists','typed parameter unresolved')
source({'def sum(values):','    return 42','sum([])'},3,'sum')
local local_result=resolve(); assert(local_result.project_local and local_result.allow_literal==false and #local_result.candidates==0,'project builtin shadow stole external identity')
source({'from pathlib import Path','def work(Path):','    Path.exists()'},3,'exists')
assert(resolve().project_local,'parameter shadow stole imported identity')
-- Existing hover is consumed once on an offline miss, without another request.
source({'def sum(values):','    return 42','sum([])'},3,'sum')
vim.lsp.get_clients=function() return {client} end
require('config.smart_docs').show(); assert(calls==1)
responses[1](nil,{contents={kind='markdown',value='PROJECT SUM FUNCTION'}})
local function floating_text()
 local result={}
 for _,win in ipairs(vim.api.nvim_list_wins()) do
  if vim.api.nvim_win_get_config(win).relative~='' then
   vim.list_extend(result,vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win),0,-1,false))
  end
 end
 return table.concat(result,'\n')
end
assert(floating_text():find('PROJECT SUM FUNCTION',1,true),'project hover missing')
assert(not floating_text():find('LOCAL OFFLINE BUILTIN',1,true),'project shadow displayed external reference')
assert(calls==1,'offline miss issued repeated hover')
-- An exact imported identity wins over supplied project hover content.
source({'from pathlib import Path','Path.exists()'},2,'exists')
require('config.smart_docs').show(); responses[2](nil,{contents={kind='markdown',value='UNSELECTED HOVER'}})
assert(floating_text():find('LOCAL OFFLINE PATH REFERENCE',1,true))
assert(not floating_text():find('UNSELECTED HOVER',1,true))
-- A stale async response cannot replace the current surface.
source({'unknown()','other()'},1,'unknown'); require('config.smart_docs').show()
vim.api.nvim_win_set_cursor(0,{2,0}); responses[3](nil,{contents={kind='markdown',value='STALE RESPONSE'}})
assert(not floating_text():find('STALE RESPONSE',1,true))
-- No LSP still supports an exact reference without a request.
vim.lsp.get_clients=function() return {} end
source({'from pathlib import Path','Path.exists()'},2,'exists'); require('config.smart_docs').show()
assert(floating_text():find('LOCAL OFFLINE PATH REFERENCE',1,true)); assert(calls==3)
resolver.cleanup(); docs.close(); vim.lsp.get_clients=real_clients
store.setup({}); vim.fn.delete(dir,'rf')
print('SMART DOCS: imported class/alias/typed receiver, local shadows, cached hover fallback, exact preference, stale and no-LSP PASS')
