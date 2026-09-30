local M = {}
local large_folds = {}
M.max_lines = 5000
M.max_bytes = 512 * 1024
function M.large(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= 'markdown' or vim.bo[buf].buftype ~= '' then return false end
  local lines = vim.api.nvim_buf_line_count(buf)
  return lines > M.max_lines or vim.api.nvim_buf_get_offset(buf, lines) > M.max_bytes
end
function M.guard(buf)
  if vim.bo[buf].filetype ~= 'markdown' or vim.bo[buf].buftype ~= ''
    or vim.b[buf].black_markdown_large or not M.large(buf) then return end
  vim.b[buf].black_markdown_large = true
  pcall(vim.treesitter.stop, buf)
  local renderer = package.loaded['render-markdown']
  if renderer then vim.api.nvim_buf_call(buf, renderer.buf_disable) end
  local context = package.loaded['treesitter-context']
  if context and context.enabled() then
    -- Reevaluate its public on_attach guard once when the threshold is crossed.
    vim.schedule(function() if context.enabled() then context.enable() end end)
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    large_folds[win] = large_folds[win] or vim.wo[win].foldmethod
    vim.wo[win].foldmethod = 'manual'
  end
end
local states = {}
local options = {
  'wrap', 'linebreak', 'breakindent', 'breakindentopt', 'number', 'relativenumber',
  'numberwidth', 'signcolumn', 'statuscolumn', 'cursorline', 'cursorcolumn',
  'foldcolumn', 'colorcolumn', 'conceallevel', 'concealcursor', 'spell', 'list',
  'statusline', 'winbar', 'sidescrolloff', 'scrolloff', 'foldmethod', 'foldexpr',
}

local function save(win)
  local state = {}
  for _, option in ipairs(options) do state[option] = vim.wo[win][option] end
  states[win] = state
end

local function restore(win)
  local state = states[win]
  if not state or not vim.api.nvim_win_is_valid(win) then return false end
  for option, value in pairs(state) do vim.wo[win][option] = value end
  states[win] = nil
  return true
end

local function render(action)
  if vim.fn.exists(':RenderMarkdown') ~= 2 then return end
  local ok, err = pcall(function()
    local renderer = require('render-markdown')
    if action == 'enable' then
      if not M.large(0) then renderer.buf_enable() end
    else
      renderer.buf_disable()
    end
  end)
  if not ok then vim.notify('Markdown rendering could not be toggled: ' .. err, vim.log.levels.WARN) end
end

local function ensure_markdown()
  if vim.bo.filetype ~= 'markdown' then
    vim.notify('Markdown reader mode is only available for Markdown buffers', vim.log.levels.WARN)
    return false
  end
  return true
end

local function set_reader_options(win)
  local wo = vim.wo[win]
  wo.wrap = true
  wo.linebreak = true
  wo.breakindent = true
  wo.breakindentopt = 'shift:2,min:40,sbr'

  wo.number = false
  wo.relativenumber = false
  wo.numberwidth = 1
  wo.signcolumn = 'no'
  wo.statuscolumn = ''
  wo.foldcolumn = '0'
  wo.colorcolumn = ''
  wo.cursorline = false
  wo.cursorcolumn = false

  wo.conceallevel = 3
  wo.concealcursor = 'nc'
  -- Reading shouldn't invoke dictionary checks or fold-expression parsing.
  wo.spell = false
  wo.foldmethod = 'manual'
  wo.list = false
  wo.statusline = ' '
  wo.winbar = ''
  wo.scrolloff = 4
  wo.sidescrolloff = 12
end

function M.enable()
  if not ensure_markdown() then return false end
  local win = vim.api.nvim_get_current_win()
  if states[win] then return true end
  save(win)
  set_reader_options(win)
  render('enable')
  vim.notify('Markdown reader mode on · :MarkdownReaderToggle toggles back', vim.log.levels.INFO)
  return true
end

function M.disable()
  local win = vim.api.nvim_get_current_win()
  if not states[win] then return false end
  render('disable')
  restore(win)
  vim.notify('Markdown reader mode off', vim.log.levels.INFO)
  return true
end

function M.toggle()
  if not ensure_markdown() then return false end
  if states[vim.api.nvim_get_current_win()] then return M.disable() end
  return M.enable()
end

function M.setup()
  vim.api.nvim_create_user_command('MarkdownReaderToggle', M.toggle, { desc = 'Toggle Markdown reader mode', force = true })
  vim.api.nvim_create_user_command('MarkdownReaderEnable', M.enable, { desc = 'Enable Markdown reader mode', force = true })
  vim.api.nvim_create_user_command('MarkdownReaderDisable', M.disable, { desc = 'Disable Markdown reader mode', force = true })
  local group = vim.api.nvim_create_augroup('MarkdownReaderMode', { clear = true })
  vim.api.nvim_create_autocmd({ 'FileType', 'TextChanged', 'TextChangedI' }, {
    group = group,
    callback = function(ev) M.guard(ev.buf) end,
  })
  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    callback = function(ev)
      states[tonumber(ev.match)], large_folds[tonumber(ev.match)] = nil, nil
    end,
  })
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = group,
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if states[vim.api.nvim_get_current_win()] and vim.bo.filetype ~= 'markdown' then
        restore(vim.api.nvim_get_current_win())
      end
      if large_folds[win] and not M.large(0) then
        vim.wo[win].foldmethod = large_folds[win]
        large_folds[win] = nil
      elseif M.large(0) then
        large_folds[win] = large_folds[win] or vim.wo[win].foldmethod
        vim.wo[win].foldmethod = 'manual'
      end
    end,
  })
end

return M
