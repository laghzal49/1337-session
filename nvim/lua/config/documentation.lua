-- One reference surface; request ownership stays with symbol_help or Blink.
local M = {}
local ui = require('config.ui')
local window

function M.options(title)
  return { border = ui.border, title = ' ' .. (title or 'Documentation') .. ' ', title_pos = 'left',
    max_width = math.max(1, math.min(ui.max_width, vim.o.columns - 4, math.floor(vim.o.columns * 0.75))),
    max_height = math.max(1, math.min(ui.max_height, math.floor((vim.o.lines - 4) * 0.5))),
    focus_id = 'black_documentation', wrap = true,
    close_events = { 'CursorMoved', 'CursorMovedI', 'InsertCharPre' } }
end

function M.close()
  if window and vim.api.nvim_win_is_valid(window) then vim.api.nvim_win_close(window, true) end
  window = nil
end

function M.focus()
  if window and vim.api.nvim_win_is_valid(window) then
    local target, origin = window, vim.api.nvim_get_current_win()
    local function focus()
      if vim.api.nvim_win_is_valid(target) and vim.api.nvim_get_current_win() == origin then
        vim.api.nvim_set_current_win(target)
        vim.cmd.stopinsert()
      end
    end
    -- Blink invokes Ctrl-K from an expression mapping under textlock.
    if vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then vim.schedule(focus) else focus() end
    return true
  end
  return false
end

function M.render(buf, win)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then return end
  -- Existing renderer, invoked only while reference text is actually visible.
  local ok, renderer = pcall(require, 'render-markdown')
  if ok then
    pcall(renderer.render, { buf = buf, win = win,
      config = { render_modes = true, anti_conceal = { enabled = false },
        sign = { enabled = false }, heading = { width = 'block', border = false },
        code = { width = 'full', border = 'hide', language = false },
        win_options = { conceallevel = { default = 2, rendered = 2 },
          concealcursor = { default = 'nc', rendered = 'nc' } } } })
  end
end

function M.open(lines, title, options)
  local cmp = package.loaded['blink.cmp']
  if cmp then cmp.hide_documentation(); cmp.hide_signature() end
  local opts = M.options(title)
  if options then opts = vim.tbl_extend('force', opts, options) end
  local buf, win = vim.lsp.util.open_floating_preview(lines, 'markdown', opts)
  window = win
  vim.wo[win].winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder,FloatTitle:BlackDocsTitle'
  vim.wo[win].spell = false
  vim.wo[win].scrolloff = 1
  for _, key in ipairs({ 'q', '<Esc>' }) do
    vim.keymap.set('n', key, M.close, { buffer = buf, silent = true, nowait = true })
  end
  M.render(buf, win)
  return buf, win
end

function M.completion_draw(opts)
  M.close()
  local cmp = package.loaded['blink.cmp']
  if cmp then cmp.hide_signature() end
  local bounds = M.options()
  opts.window.config.max_width, opts.window.config.max_height = bounds.max_width, bounds.max_height
  opts.default_implementation()
  local buf = opts.window:get_buf()
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  vim.schedule(function()
    local win = opts.window:get_win()
    if win and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_changedtick(buf) == tick then
      vim.api.nvim_win_set_config(win, { title = ' Documentation ', title_pos = 'left' })
      M.render(buf, win)
    end
  end)
end

return M
