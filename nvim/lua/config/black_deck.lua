-- Which-Key remains the renderer and executes the existing mappings.
local M = {}
local order = {}
for i, key in ipairs({ 'e', ' ', '/', ',', ':', 'n', 'f', 'b', 'r', 'D', 'c', 'd', 'm', 'g', 's', 'w', 'x', 'q', 'u', 'l', '1', 'h', '?' }) do
  order[key] = i
end

function M.groups()
  local icon = require('config.ui').icon
  local entries = {
    { 'r', 'Tasks', 'gear', 'yellow' }, { 'f', 'Files', 'file', 'cyan' },
    { 'b', 'Buffers', 'buffer', 'cyan' }, { 'D', 'Debug', 'debug', 'red' },
    { 'c', 'Code', 'code', 'orange' }, { 'd', 'Docs', 'read', 'blue' },
    { 'm', 'Markdown', 'markdown', 'blue' }, { 'g', 'Git', 'git', 'orange' },
    { 's', 'Search', 'search', 'green' }, { 'w', 'Windows', 'workspace', 'azure' },
    { 'x', 'Trouble', 'diagnostics', 'red' }, { 'q', 'Session', 'session', 'purple' },
    { 'u', 'UI', 'gear', 'purple' }, { 'l', 'LSP', 'symbols', 'cyan' },
    { '1', 'Station', 'gear', 'yellow' }, { 'h', 'Help', 'help', 'blue' },
  }
  local groups = {}
  for _, entry in ipairs(entries) do
    groups[#groups + 1] = { '<leader>' .. entry[1], group = entry[2],
      icon = { icon = icon(entry[3]), color = entry[4] } }
  end
  return groups
end

function M.rank(item)
  local node = item.node
  local parent = node and node.parent
  if parent and parent.keys == require('which-key.util').norm(vim.g.mapleader or '\\') then
    local key = item.raw_key or node.key
    if key == '<Space>' then key = ' ' end
    return order[key] or 1000
  end
  return 1000
end

function M.options()
  return {
    preset = 'modern', delay = 180, show_keys = false, show_help = true,
    sort = { M.rank, 'local', 'order', 'alphanum', 'mod', 'case' },
    icons = { breadcrumb = '›', separator = ' ', group = '', mappings = true, rules = false,
      keys = { Space = 'SPC', Esc = 'Esc', BS = 'BS' } },
    win = {
      border = require('config.ui').border, padding = { 1, 2 },
      width = { min = 40, max = 110 }, height = { min = 4, max = 0.65 },
      col = 0.5, row = -1, title = ' BLACK DECK ', title_pos = 'left',
      wo = { winblend = 0, winhighlight = 'Normal:WhichKeyNormal,FloatBorder:WhichKeyBorder,FloatTitle:WhichKeyTitle' },
    },
    layout = { width = { min = 27, max = 38 }, spacing = 3, align = 'left' },
    spec = M.groups(),
  }
end

function M.setup()
  vim.api.nvim_create_autocmd('User', { pattern = 'BlackUIPresetChanged',
    callback = function()
      require('which-key.config').options.win.border = require('config.ui').border
      require('which-key').add(M.groups())
    end,
    desc = 'Refresh Black Deck group icons for the UI preset' })
  vim.api.nvim_create_user_command('BlackDeck', function()
    require('which-key').show({ keys = '<leader>', loop = true })
  end, { desc = 'Open the Black Deck command guide', force = true })
end

return M
