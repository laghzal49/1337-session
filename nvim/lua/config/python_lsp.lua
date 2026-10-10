-- Python-specific source actions and environment controls, loaded without jobs.
local M = {}
local generations, pending_restarts = {}, {}

local function warn(message) vim.notify(message, vim.log.levels.WARN, { title = 'Python LSP' }) end

function M.source_action(kind, done)
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= 'python' then warn('Open a Python file first'); return end
  if require('config.performance').large(buf) then warn('Source actions are disabled for guarded large files'); return end
  local client = vim.lsp.get_clients({ bufnr = buf, name = 'ruff' })[1]
  if not client then warn('Ruff is not attached. Install ruff and reopen this Python file.'); return end
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local finished, request_id = false, nil
  local function finish(ok, message)
    if finished then return end
    finished = true
    if message then warn(message) end
    if done then done(ok, message) end
  end
  local function protected(callback)
    return function(...)
      local ok, message = pcall(callback, ...)
      if not ok then finish(false, 'Ruff source action failed: ' .. tostring(message)) end
    end
  end
  local function current()
    return vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_changedtick(buf) == tick
  end
  local function apply(action)
    if finished then return end
    if not current() then return finish(false, 'Source action canceled because the buffer changed') end
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
      return finish(true)
    end
    if action.command then
      local command = type(action.command) == 'table' and action.command or action
      client:exec_cmd(command, { bufnr = buf }, function(err)
        finish(not err, err and ('Ruff source action failed: ' .. err.message) or nil)
      end)
      return
    end
    finish(false, 'Ruff returned no edits for this source action')
  end
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  params.context = { only = { kind }, diagnostics = {}, triggerKind = 1 }
  local call_ok, sent, initial_id = pcall(client.request, client, 'textDocument/codeAction', params, protected(function(err, actions)
    if finished then return end
    if err then return finish(false, 'Ruff source action failed: ' .. err.message) end
    local selected
    for _, action in ipairs(actions or {}) do
      if not action.disabled and (action.kind == kind or vim.startswith(action.kind or '', kind .. '.')) then
        selected = action
        break
      end
    end
    if not selected then return finish(true) end -- Already clean.
    if not selected.edit and selected.data and client:supports_method('codeAction/resolve') then
      local resolving
      resolving, request_id = client:request('codeAction/resolve', selected, protected(function(resolve_err, resolved)
        if resolve_err then finish(false, 'Ruff could not resolve source action: ' .. resolve_err.message)
        else apply(resolved or selected) end
      end), buf)
      if not resolving then finish(false, 'Ruff could not start action resolution') end
    else apply(selected) end
  end), buf)
  request_id = initial_id
  if not call_ok then return finish(false, 'Ruff source action failed: ' .. tostring(sent)) end
  if not sent then return finish(false, 'Ruff could not start the source action') end
  vim.defer_fn(function()
    if finished then return end
    if request_id then pcall(client.cancel_request, client, request_id) end
    finish(false, 'Ruff source action timed out')
  end, 5000)
end

function M.info()
  local root = require('config.python_environment').project_root(0)
  local python, source = require('config.python_environment').interpreter(root)
  local lines = { 'Root: ' .. root, 'Interpreter candidate: ' .. (python ~= '' and python or 'not found'),
    'Selection: ' .. source, 'Project ty.toml/pyproject.toml remains authoritative unless an override is set.' }
  for _, name in ipairs({ 'ty', 'ruff' }) do
    local client = vim.lsp.get_clients({ bufnr = 0, name = name })[1]
    lines[#lines + 1] = name .. ': ' .. (client and 'attached' or 'not attached') .. ' · '
      .. (vim.fn.exepath(name) ~= '' and vim.fn.exepath(name) or 'missing on PATH')
  end
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'Python LSP' })
  return lines
end

function M.set_interpreter(path)
  if vim.bo.filetype ~= 'python' then warn('Open a Python file first'); return false end
  local environment = require('config.python_environment')
  local root = environment.project_root(0)
  path = path ~= 'auto' and vim.fn.fnamemodify(vim.fn.expand(path), ':p') or nil
  local ok, message = environment.set_interpreter(root, path)
  if not ok then warn(message); return false end
  generations[root] = (generations[root] or 0) + 1
  local generation = generations[root]
  local pending = pending_restarts[root]
  if pending then pending.generation = generation end
  for _, client in ipairs(vim.lsp.get_clients({ name = 'ty' })) do
    if client.config.root_dir == root and not client:is_stopped() then
      -- Ty currently reads editor configuration at initialization; a config
      -- notification has no handler. Restart only this project's Ty client.
      local config = vim.deepcopy(client.config)
      config.settings = vim.deepcopy(config._python_base_settings or config.settings)
      local buffers = vim.tbl_keys(client.attached_buffers)
      pending = { config = config, buffers = buffers, generation = generation }
      pending_restarts[root] = pending
      client:stop(true)
      local function restart()
        if pending_restarts[root] ~= pending or generations[root] ~= pending.generation then return end
        pending_restarts[root] = nil
        local id
        for _, attached in ipairs(pending.buffers) do
          if vim.api.nvim_buf_is_valid(attached) and vim.api.nvim_buf_is_loaded(attached)
            and vim.bo[attached].filetype == 'python' and environment.project_root(attached) == root
            and not require('config.performance').large(attached) then
            if not id then id = vim.lsp.start(config, { bufnr = attached, reuse_client = function() return false end })
            else vim.lsp.buf_attach_client(attached, id) end
          end
        end
      end
      vim.schedule(restart)
    end
  end
  vim.notify('Python interpreter selection saved; restarting this project\'s ty client', vim.log.levels.INFO,
    { title = 'Python LSP' })
  return true
end

function M.setup()
  vim.api.nvim_create_user_command('PythonLspInfo', M.info, { desc = 'Python servers, project and environment selection' })
  vim.api.nvim_create_user_command('PythonInterpreter', function(opts)
    if opts.args == '' then M.info() else M.set_interpreter(opts.args) end
  end, { nargs = '?', complete = 'file', desc = 'Set a project interpreter path, or auto to restore discovery' })
  vim.api.nvim_create_user_command('PythonOrganizeImports', function() M.source_action('source.organizeImports') end,
    { desc = 'Organize Python imports with the attached Ruff server' })
  vim.api.nvim_create_user_command('PythonFixAll', function() M.source_action('source.fixAll') end,
    { desc = 'Apply configured Ruff fixes to the current Python buffer' })
end

return M
