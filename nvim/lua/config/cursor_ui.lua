-- Explicit destination feedback. No movement watcher or idle animation.
local M = { namespace = vim.api.nvim_create_namespace('BlackCursorBeacon') }
local timer, marked_buf, generation = nil, nil, 0
local group, original_show, wrapped_show
local mappings, buffer_mappings = {}, {}

function M.clear()
  generation = generation + 1
  if timer then timer:stop(); timer:close(); timer = nil end
  if marked_buf and vim.api.nvim_buf_is_valid(marked_buf) then
    vim.api.nvim_buf_clear_namespace(marked_buf, M.namespace, 0, -1)
  end
  marked_buf = nil
end

function M.snapshot(win)
  win = win or vim.api.nvim_get_current_win()
  return { buf = vim.api.nvim_win_get_buf(win), win = win,
    pos = vim.api.nvim_win_get_cursor(win) }
end

function M.flash()
  M.clear()
  local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= '' or vim.api.nvim_win_get_config(win).relative ~= '' then return end
  local row = vim.api.nvim_win_get_cursor(win)[1] - 1
  vim.api.nvim_buf_set_extmark(buf, M.namespace, row, 0, {
    line_hl_group = 'BlackBeacon', number_hl_group = 'BlackBeaconNumber', priority = 150,
  })
  marked_buf = buf
  local epoch = generation
  timer = vim.uv.new_timer()
  timer:start(180, 0, vim.schedule_wrap(function()
    if generation == epoch then M.clear() end
  end))
end

function M.after(before)
  local now = M.snapshot()
  if before.buf ~= now.buf or before.pos[1] ~= now.pos[1] or before.pos[2] ~= now.pos[2] then
    M.flash()
  end
end

function M.schedule_flash()
  local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  vim.schedule(function()
    if group and vim.api.nvim_get_current_win() == win and vim.api.nvim_get_current_buf() == buf then M.flash() end
  end)
end

function M.native(key)
  local before = M.snapshot()
  vim.cmd.normal({ args = { tostring(vim.v.count1) .. key }, bang = true })
  M.after(before)
end

function M.cleanup()
  M.clear()
  if group then vim.api.nvim_del_augroup_by_id(group); group = nil end
  if wrapped_show and vim.lsp.util.show_document == wrapped_show then
    vim.lsp.util.show_document = original_show
  end
  for lhs, callback in pairs(mappings) do
    if vim.fn.maparg(lhs, 'n', false, true).callback == callback then pcall(vim.keymap.del, 'n', lhs) end
  end
  for buf, callback in pairs(buffer_mappings) do
    if vim.api.nvim_buf_is_valid(buf) then
      for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, 'n')) do
        if map.lhs == '<CR>' and map.callback == callback then pcall(vim.keymap.del, 'n', '<CR>', { buffer = buf }) end
      end
    end
  end
  mappings = {}
  buffer_mappings = {}
end

function M.setup()
  M.cleanup()
  vim.opt.guicursor = {
    'n:block-BlackCursorNormal', 'v-ve:block-BlackCursorVisual',
    'o:hor50-BlackCursorNormal', 'i:ver20-BlackCursorInsert',
    'r-cr:hor20-BlackCursorReplace', 'c-ci:ver25-BlackCursorCommand',
    'sm:block-BlackCursorNormal', 'a:blinkon0',
  }
  group = vim.api.nvim_create_augroup('BlackCursorUI', { clear = true })
  local entered = false
  vim.api.nvim_create_autocmd('BufEnter', { group = group, callback = function()
    if entered then
      -- BufEnter can precede restored cursor position; capture the final landing.
      M.schedule_flash()
    end
    entered = true
  end })
  vim.api.nvim_create_autocmd({ 'BufLeave', 'InsertEnter', 'WinLeave', 'VimLeavePre' }, {
    group = group, callback = M.clear,
  })
  vim.api.nvim_create_autocmd('BufWipeout', { group = group, callback = function(ev)
    if ev.buf == marked_buf then M.clear() end
    buffer_mappings[ev.buf] = nil
  end })
  vim.api.nvim_create_autocmd('QuickFixCmdPost', { group = group, pattern = { 'cnext', 'cprevious', 'cfirst', 'clast', 'cc', 'lnext', 'lprevious', 'lfirst', 'llast', 'll' }, callback = M.flash })
  local command_origin, command_landing
  vim.api.nvim_create_autocmd('CmdlineEnter', { group = group, callback = function()
    if command_landing then pcall(vim.api.nvim_del_autocmd, command_landing); command_landing = nil end
    command_origin = M.snapshot()
  end })
  local quickfix_commands = { cn = true, cnext = true, cp = true, cprev = true, cprevious = true,
    cf = true, cfirst = true, cl = true, clast = true, cc = true,
    lnext = true, lprevious = true, lfirst = true, llast = true, ll = true }
  vim.api.nvim_create_autocmd('CmdlineLeave', { group = group, callback = function(ev)
    local before = command_origin
    command_origin = nil
    local command = vim.fn.getcmdline():match('^%s*%d*%s*(%a+)')
    local navigation = ev.match == '/' or ev.match == '?' or (ev.match == ':' and quickfix_commands[command])
    if before and navigation and not vim.v.event.abort then
      -- CmdlineLeave fires before the command runs. SafeState waits for its
      -- committed destination, including Noice/Blink completion acceptance.
      command_landing = vim.api.nvim_create_autocmd('SafeState', { group = group, once = true, callback = function()
        command_landing = nil
        M.after(before)
      end })
    end
  end })
  vim.api.nvim_create_autocmd('FileType', { group = group, pattern = 'qf', callback = function(ev)
    -- Keep Quicker's editable results and use native Enter to select a result.
    if vim.fn.maparg('<CR>', 'n', false, true).buffer == 1 then return end
    local callback = function()
      local before = M.snapshot()
      vim.cmd.normal({ args = { '\r' }, bang = true })
      M.after(before)
    end
    buffer_mappings[ev.buf] = callback
    vim.keymap.set('n', '<CR>', callback, { buffer = ev.buf, silent = true, desc = 'Open result with destination beacon' })
  end })
  local picker_origin
  vim.api.nvim_create_autocmd('User', { group = group, pattern = 'MiniPickStart', callback = function()
    local state = require('mini.pick').get_picker_state()
    if state and vim.api.nvim_win_is_valid(state.windows.target) then picker_origin = M.snapshot(state.windows.target) end
  end })
  vim.api.nvim_create_autocmd('User', { group = group, pattern = 'MiniPickStop', callback = function()
    local before = picker_origin
    picker_origin = nil
    if before then vim.schedule(function() if group then M.after(before) end end) end
  end })
  for _, key in ipairs({ '<C-o>', '<C-i>', 'n', 'N', '[q', ']q' }) do
    local motion = key == '[q' and ':cprevious' or key == ']q' and ':cnext' or key
    local callback = function()
      if motion:sub(1, 1) == ':' then
        local before = M.snapshot()
        local ok, err = pcall(vim.cmd, tostring(vim.v.count1) .. motion:sub(2))
        if ok then M.after(before) else vim.notify(err, vim.log.levels.WARN) end
      else M.native(vim.api.nvim_replace_termcodes(motion, true, false, true)) end
    end
    mappings[key] = callback
    vim.keymap.set('n', key, callback, { silent = true, desc = 'Navigate with destination beacon' })
  end
  -- Native LSP definitions and Glance use this after asynchronous replies.
  -- Preserve focus=false previews and the original return contract.
  original_show = vim.lsp.util.show_document
  wrapped_show = function(location, encoding, opts)
    local before = M.snapshot()
    local result = original_show(location, encoding, opts)
    if result and (not opts or opts.focus ~= false) then M.after(before) end
    return result
  end
  vim.lsp.util.show_document = wrapped_show
end

return M
