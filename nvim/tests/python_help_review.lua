-- Full config: strict fresh-process test of builtin fallback lifetime and isolation.
local docs = require('config.documentation')
local open, system, cwd = docs.open, vim.system, vim.uv.cwd()
local dir = vim.fn.tempname()
vim.fn.mkdir(dir,'p')
local opened, callbacks, probes, fallbacks = {}, {}, 0, 0
local function reset()
  package.loaded['config.python_help'] = nil
  return require('config.python_help')
end
local function fallback() fallbacks = fallbacks + 1 end
local function mock(_, opts, callback)
  probes = probes + 1
  assert(opts.timeout == 1500, 'builtin subprocess lacks deadline')
  callbacks[#callbacks+1] = callback
  return {}
end
local function response(callback)
  callback({code=0,stdout=vim.json.encode({signature='sum(iterable, /, start=0)',doc='Return the sum of the items.'})})
end
local ok, err = xpcall(function()
  docs.open = function(lines) opened[#opened+1] = table.concat(lines,'\n') end
  vim.cmd.enew()
  vim.bo.filetype='python'
  vim.api.nvim_buf_set_lines(0,0,-1,false,{'sum','sum'})
  vim.api.nvim_win_set_cursor(0,{1,0})
  vim.system=mock
  local helper=reset()
  helper.show('sum',fallback)
  vim.api.nvim_win_set_cursor(0,{2,0})
  helper.show('sum',fallback)
  assert(probes==1,'concurrent builtin requests did not coalesce')
  response(callbacks[1])
  assert(vim.wait(1000,function() return #opened==1 end))
  assert(fallbacks==0 and opened[1]:find('sum%(iterable'),'stale first request displaced current anchor')
  -- A cached response belongs to the initiating window, even for the same buffer.
  helper.show('sum',fallback)
  vim.cmd.vsplit()
  vim.wait(50)
  assert(#opened==1,'cached docs escaped into a different window')
  vim.cmd.close()
  -- Spawn errors and timeout results release waiters and allow a later retry.
  helper=reset()
  vim.system=function() error('fixture spawn failure') end
  helper.show('divmod',fallback)
  assert(vim.wait(1000,function() return fallbacks==1 end),'spawn failure stranded waiter')
  vim.system=mock
  helper.show('divmod',fallback)
  callbacks[#callbacks]({code=124,stdout=''})
  assert(vim.wait(1000,function() return fallbacks==2 end),'deadline failure stranded waiter')
  helper.show('divmod',fallback)
  response(callbacks[#callbacks])
  assert(vim.wait(1000,function() return #opened==2 end),'temporary failure poisoned builtin cache')
  -- Real isolated Python must ignore modules in the project working directory.
  local marker=dir..'/unsafe-imported'
  for _, name in ipairs({'inspect','json','builtins'}) do
    vim.fn.writefile({'open('..string.format('%q',marker)..', "w").write("unsafe")','raise RuntimeError("project module imported")'},dir..'/'..name..'.py')
  end
  vim.cmd.cd(vim.fn.fnameescape(dir))
  vim.system=system
  helper=reset()
  helper.show('sum',fallback)
  assert(vim.wait(5000,function() return #opened==3 end),'real isolated builtin docs missing')
  assert(opened[3]:find('sum',1,true) and opened[3]:lower():find('sum',1,true),'real builtin content missing')
  assert(vim.fn.filereadable(marker)==0,'builtin lookup executed a project module')
end,debug.traceback)
docs.open,vim.system=open,system
vim.cmd.cd(vim.fn.fnameescape(cwd))
vim.fn.delete(dir,'rf')
if not ok then error(err) end
print('PYTHON HELP PASS: bounded/coalesced lookup, spawn/timeout recovery, exact window stale guards and real isolated builtin docs')
