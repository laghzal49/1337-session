-- Custom offline store/resolver integration; no plugin, network, or Telescope.
local store = require('config.docs_store')
local resolver = require('config.docs_resolver')
local deep = require('config.deep_docs')
local docs = require('config.documentation')
local dir = vim.fn.tempname()
local sets = {
  cpp = {{name='literal',path='literal'},{name='std::vector::size',path='member'},{name='std::vector',path='type'},{name='oversize',path='oversize'},{name='long',path='long'}},
  c = {{name='printf()',path='printf'}},
  lua = {{name='string.format()',path='manual#pdf-string.format'},{name='string.gsub()',path='gsub'}},
  python = {{name='pathlib.Path.exists()',path='manual#pathlib.Path.exists'},{name='zipfile.Path.exists()',path='zipfile#zipfile.Path.exists'},{name='pathlib.Path()',path='path'},{name='sum()',path='sum'}},
}
local manifest = {schema=1,docsets={}}
local indexes = {}
for name, entries in pairs(sets) do
  local root='sets/'..name..'/fixture'
  vim.fn.mkdir(dir..'/'..root..'/pages','p')
  local index={entries=entries,exact={},suffix={}}
  for position,entry in ipairs(entries) do
    local key=store.normalize(entry.name)
    index.exact[key]=index.exact[key] or position
    local tail=key
    while tail do
      if index.suffix[tail] and index.suffix[tail]~=position then index.suffix[tail]=false
      elseif index.suffix[tail]~=false then index.suffix[tail]=position end
      tail=tail:match('^[^.]+%.(.+)') or tail:match('^[^:]+::(.+)')
    end
  end
  -- Real DevDocs indexes contain ambiguous exact names as well as suffixes.
  index.exact.ambiguous_duplicate = false
  indexes[name]=index
  vim.fn.writefile({vim.json.encode(index)},dir..'/'..root..'/index.json')
  manifest.docsets[name]={slug=name,lang=name,root=root,entries=#entries,pages=#entries,bytes=100,updated_at=1}
end
local function write_manifest()
  local staging=dir..'/manifest.tmp'
  vim.fn.writefile({vim.json.encode(manifest)},staging)
  assert(vim.uv.fs_rename(staging,dir..'/manifest.json'))
end
write_manifest()
local function write(name,path,lines)
  local root=dir..'/'..manifest.docsets[name].root..'/pages/'..path..'.md'
  vim.fn.mkdir(vim.fn.fnamemodify(root,':h'),'p'); vim.fn.writefile(lines,root)
end
write('cpp','literal',{'# literal','Offline literal reference.'})
write('cpp','member',{'# member','Offline member reference.'})
write('cpp','type',{'# type','Offline type reference.'})
write('c','printf',{'# printf','Formatted output.'})
write('lua','gsub',{'# string.gsub','Pattern replacement.'})
write('python','path',{'# pathlib.Path','Filesystem path.'})
write('python','sum',{'# sum','Builtin sum reference.'})
write('python','zipfile',{'**`Path.exists()`**','Zipfile reference.'})
write('python','manual',{'# Python manual','Introductory Path.exists mention.','**`Path.exists_extra()`**','Wrong section.','**`Path.exists(*, follow_symlinks=True)`**','Correct exists reference.','```python','p.exists()','```','**`Path.is_file()`**','Unrelated next method.'})
write('lua','manual',{'# Lua manual','Introductory string.format mention.','### `string.formatter()`','Wrong heading.','### `string.format (formatstring, ...)`','Correct format reference.','```lua','string.format("%s", "x")','```','### `string.gmatch (...)`','Unrelated next function.'})
write('cpp','oversize',{string.rep('x',1024*1024+1)})
local long={'# Long reference','```python'}
for _=1,230 do long[#long+1]='pass' end
long[#long+1]='```'; write('cpp','long',long)
deep.setup({data_dir=dir,timeout_ms=80})
package.preload['devdocs']=function() error('Removed plugin must not load') end
package.preload['telescope.pickers']=function() error('Telescope must not load') end
assert(store.find_entry('c','printf').name=='printf()')
assert(not store.find_entry('c','ambiguous_duplicate'), 'ambiguous exact entry was guessed')
assert(store.find_entry('lua','string.gsub').name=='string.gsub()')
assert(store.find_entry('cpp','vector').name=='std::vector')
assert(not store.find_entry('python','Path.exists'),'ambiguous qualified suffix was guessed')
assert(store.find_entry('python','pathlib.Path.exists').path=='manual#pathlib.Path.exists')
assert(not store.page_lines('cpp','../escape'))
assert(not store.page_lines('cpp','/etc/passwd'))
assert(not store.page_lines('cpp','literal/../../escape'))
assert(not store.load_index('missing'))
local first=store.load_index('cpp'); assert(first==store.load_index('cpp'),'cached generation index was rebuilt')
-- An invalid publication must never revive the previously cached manifest.
vim.fn.writefile({'{broken'},dir..'/manifest.json'); assert(not store.manifest())
write_manifest(); assert(store.manifest())
local invalid={entries={{name='bad',path='../escape'}},exact={bad=1},suffix={}}
vim.fn.writefile({vim.json.encode(invalid)},dir..'/'..manifest.docsets.c.root..'/index.json')
store.invalidate(); assert(not store.load_index('c'),'traversing index path accepted')
vim.fn.writefile({vim.json.encode(indexes.c)},dir..'/'..manifest.docsets.c.root..'/index.json'); store.invalidate()
vim.cmd('enew!')
local source=vim.api.nvim_get_current_buf(); vim.bo.filetype='deep_docs_review'
vim.api.nvim_buf_set_lines(0,0,-1,false,{'é object','second line'}); vim.api.nvim_win_set_cursor(0,{1,4})
local function opened()
  for _,win in ipairs(vim.api.nvim_list_wins()) do
    local buf=vim.api.nvim_win_get_buf(win)
    if vim.b[buf].black_docs then return {win=win,buf=buf,metadata=vim.b[buf].black_docs,text=table.concat(vim.api.nvim_buf_get_lines(buf,0,-1,false),'\n')} end
  end
end
local function close() docs.close(); vim.api.nvim_set_current_buf(source) end
deep.lookup('literal','cpp'); assert(opened().metadata.name=='literal')
deep.lookup('std::vector','cpp'); assert(opened().metadata.name=='std::vector' and opened().text:find('Offline type',1,true))
-- Back navigation restores the real previous page without closing the code window.
docs.focus(); vim.fn.maparg('<C-o>','n',false,true).callback()
assert(opened().metadata.name=='literal','reference history did not restore prior page'); close()
deep.lookup('pathlib.Path.exists','python')
local selected=opened(); assert(selected.metadata.section and selected.text:find('Correct exists',1,true))
assert(not selected.text:find('Wrong section',1,true) and not selected.text:find('Unrelated next',1,true),selected.text)
assert(selected.metadata.source=='https://devdocs.io/python/manual#pathlib.Path.exists'); close()
deep.lookup('string.format','lua'); assert(opened().metadata.section and opened().text:find('Correct format',1,true) and not opened().text:find('Wrong heading',1,true)); close()
resolver.cancel(); assert(not deep.show('cpp',store.find_entry('cpp','oversize'),resolver.capture()),'oversize page rendered')
deep.lookup('long','cpp'); local text=opened().text; assert(text:find('Showing the beginning',1,true))
local fences=0; for _ in text:gmatch('```') do fences=fences+1 end; assert(fences==2,'cap left an unclosed fence'); close()
local queue,canceled,clients={},0,{}
local function server(name,encoding)
  local serial,closed=0,false
  local id=vim.lsp.start({name=name,cmd=function(dispatchers)
    return {request=function(method,params,cb)
      serial=serial+1
      if method=='initialize' then vim.schedule(function() cb(nil,{capabilities={hoverProvider=true,positionEncoding=encoding}}) end)
      elseif method=='textDocument/hover' or method=='textDocument/symbolInfo' then queue[#queue+1]={method=method,params=params,callback=cb,name=name}
      else vim.schedule(function() cb(nil,nil) end) end
      return true,serial
    end,notify=function(method) if method=='$/cancelRequest' then canceled=canceled+1 end; return true end,
      is_closing=function() return closed end,terminate=function() closed=true; dispatchers.on_exit(0,0) end}
  end},{bufnr=source})
  clients[#clients+1]=id; assert(vim.wait(500,function() local c=vim.lsp.get_client_by_id(id); return c and c.initialized end))
end
server('clangd','utf-16'); server('docs-generic','utf-8')
local function replies(kind)
  local requests=queue; queue={}
  for _,request in ipairs(requests) do
    local result
    if kind=='python' and request.method=='textDocument/hover' then result={contents={kind='markdown',value='```python\nbound method Path.exists() -> bool\n```'}}
    elseif kind=='member' and request.method=='textDocument/symbolInfo' then result={{name='size',containerName='std::vector<int>'}}
    elseif request.method=='textDocument/hover' then result={contents={kind='markdown',value='Type: `std::vector<int>`'}} end
    vim.schedule(function() request.callback(nil,result) end)
  end
end
deep.lookup('literal','cpp'); assert(#queue==3,'symbolInfo dispatched to unsupported generic server')
for _,request in ipairs(queue) do assert(request.params.position.character==(request.name=='clangd' and 3 or 4),'client encoding ignored') end
replies('member'); assert(vim.wait(200,function() return opened() end)); assert(opened().metadata.name=='std::vector::size'); close()
deep.lookup('literal','cpp'); deep.lookup('literal','cpp'); assert(canceled>=3); replies('member'); assert(vim.wait(200,function() return opened() end)); close()
deep.lookup('literal','cpp'); vim.api.nvim_win_set_cursor(0,{2,0}); replies('member'); vim.wait(30,function() return false end); assert(not opened(),'stale cursor opened manual')
vim.api.nvim_win_set_cursor(0,{1,4}); deep.lookup('literal','cpp'); vim.api.nvim_buf_set_text(source,1,0,1,0,{'edited '}); replies('member'); vim.wait(30,function() return false end); assert(not opened(),'stale changedtick opened manual')
deep.lookup('literal','cpp'); local other=vim.api.nvim_create_buf(true,false); vim.api.nvim_set_current_buf(other); replies('member'); vim.wait(30,function() return false end); assert(not opened(),'buffer switch stole focus')
vim.api.nvim_set_current_buf(source); vim.api.nvim_win_set_cursor(0,{1,4}); deep.lookup('literal','cpp'); assert(vim.wait(300,function() return opened() end)); assert(opened().metadata.name=='literal'); replies('member'); vim.wait(20,function() return false end); assert(opened().metadata.name=='literal'); close()
local pick=require('mini.pick'); local seen
vim.defer_fn(function() if pick.get_picker_state() then pick.stop() end end,1500)
vim.defer_fn(function()
  assert(pick.get_picker_state()); seen=table.concat(pick.get_picker_query()); assert(seen=='Path.exists',seen)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab><Tab><CR>',true,false,true),'t',false)
end,40)
deep.lookup('exists','python'); replies('python'); assert(vim.wait(500,function() return opened() end)); assert(seen=='Path.exists'); close()
deep.lookup('literal','cpp'); deep.cleanup(); replies('member'); vim.wait(20,function() return false end); assert(not opened())
for _,id in ipairs(clients) do vim.lsp.get_client_by_id(id):stop(true) end
assert(not package.loaded.devdocs and not package.loaded['telescope.pickers'])
vim.api.nvim_buf_delete(other,{force=true}); vim.fn.delete(dir,'rf')
print('CUSTOM DOCS: validated cached store, corruption/traversal, exact/section/cap/history, async UTF/cancel/stale/timeout, guarded MiniPick and no plugin/network PASS')
