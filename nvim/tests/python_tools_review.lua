-- Full config with ty and Ruff on PATH: actual source actions and live env changes.
assert(vim.fn.executable('ty') == 1 and vim.fn.executable('ruff') == 1, 'put ty and Ruff on PATH')
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
local buf, ty, ruff, other_buf
local ok, err = xpcall(function()
  vim.fn.writefile({ '[project]', 'name = "python-tools-review"', 'version = "0.1.0"' }, dir .. '/pyproject.toml')
  local alternate = dir .. '/alternate-env'
  local created = vim.system({ 'python3', '-m', 'venv', '--without-pip', alternate }, { text = true }):wait()
  assert(created.code == 0, created.stderr)
  local site = vim.trim(vim.system({ alternate .. '/bin/python', '-c', 'import site; print(site.getsitepackages()[0])' }, { text = true }):wait().stdout)
  vim.fn.mkdir(site .. '/review_selected_environment', 'p')
  vim.fn.writefile({ 'def external(value: str) -> str:', '    return value' }, site .. '/review_selected_environment/__init__.py')
  vim.fn.writefile({ 'import sys', 'import os', '', 'print(sys.version, os.name)' }, dir .. '/main.py')
  vim.cmd.edit(dir .. '/main.py')
  buf = vim.api.nvim_get_current_buf()
  assert(vim.wait(10000, function()
    ty = vim.lsp.get_clients({ bufnr = buf, name = 'ty' })[1]
    ruff = vim.lsp.get_clients({ bufnr = buf, name = 'ruff' })[1]
    return ty and ruff and ty.initialized and ruff.initialized
  end), 'configured ty and Ruff did not both attach')
  assert(ty.config.root_dir == ruff.config.root_dir and ty.config.root_dir == vim.uv.fs_realpath(dir), 'Python roots diverged')
  assert(ruff.server_capabilities.hoverProvider == false, 'duplicate Ruff hover provider')
  assert(ruff.server_capabilities.documentFormattingProvider == false, 'Ruff competes with Conform formatter')
  assert(ty.config.settings.ty.completions.completeFunctionParentheses, 'call snippet completion disabled')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    'def greet(name: str, count: int = 1) -> str:', '    return name * count', '', 'gre',
  })
  local completion = ty:request_sync('textDocument/completion', {
    textDocument = { uri = vim.uri_from_bufnr(buf) }, position = { line = 3, character = 3 },
  }, 10000, buf)
  assert(completion and completion.result, 'real completion response missing')
  local snippets = completion.result.items or completion.result
  assert(vim.iter(snippets):any(function(item)
    local insertion = (item.textEdit and item.textEdit.newText) or item.insertText or ''
    return item.label:find('greet', 1, true) and item.insertTextFormat == 2
      and insertion:find('(', 1, true) and insertion:find('$', 1, true)
  end), 'ty did not emit function-call snippet completion: ' .. vim.inspect(snippets))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'import sys', 'import os', '', 'print(sys.version, os.name)' })
  local python = require('config.python_lsp')
  local function action(kind)
    local finished, success, message
    python.source_action(kind, function(result, why) finished, success, message = true, result, why end)
    assert(vim.wait(10000, function() return finished end), 'source action did not finish')
    assert(success, message)
  end
  action('source.organizeImports')
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  assert(lines[1] == 'import os' and lines[2] == 'import sys', 'Ruff did not sort imports: ' .. vim.inspect(lines))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'import os', '', 'print("hello")' })
  action('source.fixAll')
  assert(not table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'):find('import os', 1, true), 'Ruff did not remove unused import')
  local original = vim.deepcopy(ty.config.settings)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'from review_selected_environment import external', 'external("ok")' })
  local function imported_definition()
    if not ty or not ty.initialized or ty:is_stopped() then return false end
    local response = ty:request_sync('textDocument/definition', {
      textDocument = { uri = vim.uri_from_bufnr(buf) }, position = { line = 1, character = 3 },
    }, 3000, buf)
    assert(response and not response.err, 'definition request failed: ' .. vim.inspect(response))
    return response and response.result and vim.inspect(response.result):find('review_selected_environment', 1, true)
  end
  local previous_id = ty.id
  local function ready_ty()
    for _, candidate in ipairs(vim.lsp.get_clients({ bufnr = buf, name = 'ty' })) do
      if candidate.id ~= previous_id and candidate.initialized and not candidate:is_stopped() then ty = candidate; return true end
    end
    return false
  end
  assert(python.set_interpreter(alternate .. '/bin/python'))
  assert(vim.wait(10000, ready_ty), 'replacement Ty did not initialize')
  assert(imported_definition(), 'live interpreter selection did not resolve alternate packages')
  previous_id = ty.id
  assert(python.set_interpreter('auto'))
  assert(vim.wait(10000, ready_ty), 'auto Ty did not initialize')
  assert(not imported_definition(), 'live auto reset retained alternate environment')
  assert(vim.deep_equal(ty.config.settings, original), 'auto reset lost original settings')
  previous_id = ty.id
  assert(python.set_interpreter(alternate .. '/bin/python'))
  assert(python.set_interpreter('auto'))
  assert(vim.wait(10000, ready_ty), 'rapid override/reset did not restart Ty')
  local active = vim.tbl_filter(function(candidate) return not candidate:is_stopped() end,
    vim.lsp.get_clients({ bufnr = buf, name = 'ty' }))
  assert(#active == 1 and vim.deep_equal(ty.config.settings, original), 'rapid selection spawned duplicate or obsolete Ty clients')

  -- Selecting an interpreter in one project must not disturb another project,
  -- its Ty client, or either attached Ruff client.
  local second = dir .. '/second-project'
  vim.fn.mkdir(second, 'p')
  vim.fn.writefile({ '[project]', 'name = "second-python-project"', 'version = "0.1.0"' }, second .. '/pyproject.toml')
  vim.fn.writefile({ 'value = 1' }, second .. '/other.py')
  vim.cmd.edit(second .. '/other.py')
  other_buf = vim.api.nvim_get_current_buf()
  local other_ty, other_ruff
  assert(vim.wait(10000, function()
    other_ty = vim.lsp.get_clients({ bufnr = other_buf, name = 'ty' })[1]
    other_ruff = vim.lsp.get_clients({ bufnr = other_buf, name = 'ruff' })[1]
    return other_ty and other_ruff and other_ty.initialized and other_ruff.initialized
  end), 'second project did not attach')
  local other_id, ruff_id = other_ty.id, ruff.id
  vim.api.nvim_set_current_buf(buf)
  previous_id = ty.id
  assert(python.set_interpreter(alternate .. '/bin/python'))
  assert(vim.wait(10000, ready_ty), 'scoped Ty restart did not attach')
  assert(vim.lsp.get_clients({ bufnr = other_buf, name = 'ty' })[1].id == other_id, 'other project Ty restarted')
  assert(vim.lsp.get_clients({ bufnr = buf, name = 'ruff' })[1].id == ruff_id and not other_ruff:is_stopped(), 'Ruff was disturbed by interpreter selection')
  other_ty:stop(true)
  other_ruff:stop(true)
end, debug.traceback)
if ty then ty:stop(true) end
if ruff then ruff:stop(true) end
vim.wait(2000, function() return (not ty or ty:is_stopped()) and (not ruff or ruff:is_stopped()) end)
if buf and vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
if other_buf and vim.api.nvim_buf_is_valid(other_buf) then vim.api.nvim_buf_delete(other_buf, { force = true }) end
vim.fn.delete(dir, 'rf')
if not ok then error(err) end
print('PYTHON TOOLS REVIEW PASS: real ty/Ruff roots, source actions, ownership, live interpreter override/reset')
