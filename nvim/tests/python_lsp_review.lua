-- Real configured Ty: project docs, active parameter docs, types and venv imports.
assert(vim.fn.executable('ty')==1,'Install ty or add it to PATH before this review')
local dir=vim.fn.tempname()
vim.fn.mkdir(dir,'p')
local buf, client
-- This review checks Ty's project .venv discovery. A test runner such as
-- `uv run` may export its own active environment, which takes precedence.
local active_venv, active_conda = vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX
vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX = nil, nil
local ok, err=xpcall(function()
  vim.fn.writefile({'[project]','name="python-lsp-review"','version="0.1.0"'},dir..'/pyproject.toml')
  local venv=vim.system({'python3','-m','venv','--without-pip',dir..'/.venv'},{text=true}):wait()
  assert(venv.code==0,venv.stderr)
  local site=vim.trim(vim.system({dir..'/.venv/bin/python','-I','-c','import site; print(site.getsitepackages()[0])'},{text=true}):wait().stdout)
  vim.fn.mkdir(site..'/review_dependency','p')
  vim.fn.writefile({'def external(value: str) -> str:','    """Return a value from the selected environment."""','    return value'},site..'/review_dependency/__init__.py')
  vim.fn.writefile({
    'def greet(name: str, count: int = 1) -> str:',
    '    """Create a greeting for the requested user.',
    '',
    '    Args:',
    '        name: Display name for the greeting.',
    '        count: Number of greetings to generate.',
    '    """',
    '    return name * count',
    '',
    'greet("user", 2)',
    'broken: int = "wrong"',
    'from review_dependency import external',
    'external("ok")',
  },dir..'/main.py')
  vim.cmd.edit(dir..'/main.py')
  buf=vim.api.nvim_get_current_buf()
  assert(vim.wait(15000,function() client=vim.lsp.get_clients({bufnr=buf,name='ty'})[1]; return client and client.initialized end),'configured Ty failed to attach')
  local function request(method,line,col)
    local response=client:request_sync(method,{textDocument={uri=vim.uri_from_bufnr(buf)},position={line=line,character=col}},10000,buf)
    assert(response and not response.err,vim.inspect(response))
    return response.result
  end
  assert(client:supports_method('textDocument/signatureHelp'),'real server lacks signatureHelp')
  local signature=request('textDocument/signatureHelp',9,13)
  assert(signature and #signature.signatures>0,'real signature missing')
  local active=signature.activeParameter or signature.signatures[1].activeParameter
  assert(active==1,'incorrect real active parameter: '..vim.inspect(signature))
  assert(vim.inspect(signature):find('Number of greetings to generate.',1,true),'real parameter documentation missing')
  local hover=request('textDocument/hover',9,3)
  assert(vim.inspect(hover):find('Create a greeting for the requested user.',1,true),'real project docstring missing')
  local locations=request('textDocument/definition',12,3)
  assert(vim.inspect(locations):find('review_dependency',1,true),'selected venv dependency not resolved')
  assert(vim.wait(10000,function()
    for _, diagnostic in ipairs(vim.diagnostic.get(buf)) do
      if diagnostic.source=='ty' and diagnostic.lnum==10 and diagnostic.code=='invalid-assignment' then return true end
    end
    return false
  end),'actual annotated type mismatch diagnostic missing')
  -- Exercise the configured manual signature surface with the real server.
  vim.api.nvim_win_set_cursor(0,{10,13})
  require('config.symbol_help').show(nil,true,true)
  assert(vim.wait(5000,function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative~='' then
        local text=table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win),0,-1,false),'\n')
        if text:find('Number of greetings to generate.',1,true) then return true end
      end
    end
  end),'real active parameter docs did not reach signature UI')
  require('config.documentation').close()
end,debug.traceback)
if client then client:stop(true); vim.wait(1000,function() return client:is_stopped() end) end
if buf and vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf,{force=true}) end
vim.fn.delete(dir,'rf')
vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX = active_venv, active_conda
if not ok then error(err) end
print('REAL PYTHON LSP PASS: configured Ty, active parameter docs/signature UI, project docstring, actual type mismatch, .venv import')
