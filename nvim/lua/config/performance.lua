-- Buffer size checks use Neovim's byte offsets, never copy the entire buffer.
local M = { max_bytes = 1024 * 1024, max_lines = 20000 }
local saved = {}
local protected_windows = {}
local flags = { 'bigfile', 'performance_guard', 'minihipatterns_disable', 'snacks_indent', 'snacks_scope' }
local window_options = { 'foldmethod', 'spell', 'cursorcolumn' }

local function current(buf)
  return (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
end

local function oversized(buf)
  local lines = vim.api.nvim_buf_line_count(buf)
  return lines > M.max_lines or vim.api.nvim_buf_get_offset(buf, lines) > M.max_bytes
end

local function refresh_context()
  local context = package.loaded['treesitter-context']
  if context and context.enabled() then
    vim.schedule(function() if context.enabled() then context.enable() end end)
  end
end

local function release_window(win)
  local previous = protected_windows[win]
  if not previous then return end
  for option, value in pairs(previous.options) do vim.wo[win][option] = value end
  protected_windows[win] = nil
end

local function remember(buf)
  if saved[buf] then return saved[buf] end
  local state = {
    flags = {}, windows = {}, clients = vim.lsp.get_clients({ bufnr = buf }),
    syntax = vim.bo[buf].syntax, filetype = vim.bo[buf].filetype,
    initial_read = not vim.bo[buf].modified and vim.api.nvim_buf_get_name(buf) ~= '',
    diagnostics = vim.diagnostic.is_enabled({ bufnr = buf }), diagnostic_namespaces = {},
    treesitter = vim.treesitter.highlighter.active[buf] ~= nil,
  }
  for _, name in ipairs(flags) do state.flags[name] = vim.b[buf][name] end
  if state.diagnostics then
    for namespace in pairs(vim.diagnostic.get_namespaces()) do
      if not vim.diagnostic.is_enabled({ bufnr = buf, ns_id = namespace }) then
        state.diagnostic_namespaces[#state.diagnostic_namespaces + 1] = namespace
      end
    end
  end
  if state.filetype == 'bigfile' then
    state.filetype = vim.filetype.match({ buf = buf }) or ''
    state.disk_bigfile = true
    -- This marker reflects classification, not a user-selected feature setting.
    state.flags.bigfile = nil
  end
  local hipatterns = package.loaded['mini.hipatterns']
  state.hipatterns = hipatterns and vim.tbl_contains(hipatterns.get_enabled_buffers(), buf) or false
  saved[buf] = state
  return state
end

function M.large(buf)
  buf = current(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= '' then return false end
  if vim.b[buf].bigfile or vim.bo[buf].filetype == 'bigfile' then return true end
  return oversized(buf)
end

function M.guard(buf)
  buf = current(buf)
  if not M.large(buf) then
    if next(protected_windows) then
      for _, win in ipairs(vim.fn.win_findbuf(buf)) do release_window(win) end
    end
    return
  end
  local state = remember(buf)
  -- Window-local options need applying again when a guarded buffer enters a
  -- different split; one-time buffer classification alone does not cover it.
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if not state.windows[win] then
      local previous = protected_windows[win]
      if previous then
        -- Transfer the normal window preferences between guarded buffers,
        -- without briefly enabling expensive folds on the newly shown giant.
        state.windows[win] = vim.deepcopy(previous.options)
      else
        state.windows[win] = {}
        for _, option in ipairs(window_options) do state.windows[win][option] = vim.wo[win][option] end
      end
    end
    protected_windows[win] = { buf = buf, options = state.windows[win] }
    if vim.wo[win].foldmethod ~= 'manual' then vim.wo[win].foldmethod = 'manual' end
    if vim.wo[win].spell then vim.wo[win].spell = false end
    if vim.wo[win].cursorcolumn then vim.wo[win].cursorcolumn = false end
  end
  -- Built-in ftplugins (notably Lua) can restart highlighting after BufReadPost.
  -- Reassert the safety boundary even when classification already happened.
  if vim.treesitter.highlighter.active[buf] then
    if state.initial_read then state.treesitter = true end
    pcall(vim.treesitter.stop, buf)
  end
  if vim.bo[buf].syntax ~= '' then
    if state.initial_read and state.syntax == '' then state.syntax = vim.bo[buf].syntax end
    vim.bo[buf].syntax = ''
  end
  if vim.b[buf].performance_guard then return end
  vim.b[buf].performance_guard = true
  vim.b[buf].bigfile = true
  vim.b[buf].minihipatterns_disable = true
  vim.b[buf].snacks_indent = false
  vim.b[buf].snacks_scope = false
  local hipatterns = package.loaded['mini.hipatterns']
  if hipatterns then hipatterns.disable(buf) end
  refresh_context()
  vim.diagnostic.enable(false, { bufnr = buf })
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    vim.lsp.buf_detach_client(buf, client.id)
  end
end

function M.restore(buf)
  buf = current(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= '' then
    return false, 'Restore is only available for normal editing buffers'
  end
  local state = saved[buf]
  if not state or not vim.b[buf].performance_guard then return false, 'This buffer is not in performance mode' end
  if oversized(buf) then return false, 'Buffer still exceeds the 1 MiB / 20,000 line budget' end
  local lines = vim.api.nvim_buf_line_count(buf)
  -- Keep protecting a disk-classified minified file, even below the byte cap.
  if state.disk_bigfile and vim.api.nvim_buf_get_offset(buf, lines) / lines > 1000 then
    return false, 'Buffer still contains oversized minified lines'
  end
  if state.filetype == 'markdown' and (lines > 5000 or vim.api.nvim_buf_get_offset(buf, lines) > 512 * 1024) then
    return false, 'Buffer still exceeds the Markdown rendering budget'
  end
  for _, name in ipairs(flags) do vim.b[buf][name] = state.flags[name] end
  vim.diagnostic.enable(state.diagnostics, { bufnr = buf })
  if state.diagnostics then
    for _, namespace in ipairs(state.diagnostic_namespaces) do
      vim.diagnostic.enable(false, { bufnr = buf, ns_id = namespace })
    end
  end
  vim.bo[buf].syntax = state.syntax
  for win, options in pairs(state.windows) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      for option, value in pairs(options) do vim.wo[win][option] = value end
      protected_windows[win] = nil
    end
  end
  saved[buf] = nil
  if state.disk_bigfile or state.initial_read then
    -- Initial disk protection can precede normal FileType tools/LSP attachment,
    -- including files that exceeded only the line budget. Reapply those tools.
    vim.bo[buf].filetype = state.filetype
  elseif state.treesitter then
    pcall(vim.treesitter.start, buf)
  end
  local hipatterns = package.loaded['mini.hipatterns']
  if hipatterns and state.hipatterns then hipatterns.enable(buf) end
  for _, prior in ipairs(state.clients) do
    local live = vim.lsp.get_client_by_id(prior.id)
    if live and not live:is_stopped() then
      vim.lsp.buf_attach_client(buf, prior.id)
    else
      vim.lsp.start(prior.config, { bufnr = buf })
    end
  end
  refresh_context()
  vim.cmd.redraw()
  return true, 'Restored buffer features without changing unsaved edits'
end

function M.setup()
  local group = vim.api.nvim_create_augroup('BlackBufferPerformance', { clear = true })
  vim.api.nvim_create_user_command('BufferPerformanceRestore', function()
    local ok, message = M.restore()
    vim.notify(message, ok and vim.log.levels.INFO or vim.log.levels.WARN)
  end, { desc = 'Restore features after shrinking a guarded buffer', force = true })
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = group,
    callback = function(ev) saved[ev.buf] = nil end,
  })
  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    callback = function(ev)
      local win = tonumber(ev.match)
      local previous = protected_windows[win]
      if previous and saved[previous.buf] then saved[previous.buf].windows[win] = nil end
      protected_windows[win] = nil
    end,
  })
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWinEnter', 'TextChanged', 'TextChangedI' }, {
    group = group,
    callback = function(ev) M.guard(ev.buf) end,
  })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function(ev)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ev.buf) then M.guard(ev.buf) end
      end)
    end,
  })
  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(ev)
      if M.large(ev.buf) then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ev.buf) and M.large(ev.buf) then
            vim.lsp.buf_detach_client(ev.buf, ev.data.client_id)
          end
        end)
      end
    end,
  })
end

return M
