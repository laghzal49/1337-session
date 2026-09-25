local M = {}
local states = {}
local options = {
  'wrap', 'linebreak', 'breakindent', 'breakindentopt', 'number', 'relativenumber',
  'numberwidth', 'signcolumn', 'statuscolumn', 'cursorline', 'cursorcolumn',
  'foldcolumn', 'colorcolumn', 'conceallevel', 'concealcursor', 'spell', 'list',
  'statusline', 'winbar', 'sidescrolloff',
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
  local ok, err = pcall(vim.cmd, 'RenderMarkdown ' .. action)
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
  wo.spell = true
  wo.list = false
  wo.statusline = ' '
  wo.winbar = ''
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
  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    callback = function(ev) states[tonumber(ev.match)] = nil end,
  })
end

return M
