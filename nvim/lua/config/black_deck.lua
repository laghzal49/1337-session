-- Which-Key remains the renderer and executes the existing mappings.
local M = {}
local order = {}
for i, key in ipairs({ 'e', ' ', '/', ',', ':', 'n', 'f', 'b', 'c', 'd', 'm', 'g', 's', 'w', 'x', 'q', 'u', 'l', '1', 'h', '?' }) do
  order[key] = i
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
    icons = { breadcrumb = '›', separator = ' ', group = '› ', mappings = false,
      keys = { Space = 'SPC', Esc = 'Esc', BS = 'BS' } },
    win = {
      border = require('config.ui').border, padding = { 1, 2 },
      width = { min = 40, max = 110 }, height = { min = 4, max = 0.65 },
      col = 0.5, row = -1, title = ' BLACK DECK ', title_pos = 'left',
      wo = { winblend = 0, winhighlight = 'Normal:WhichKeyNormal,FloatBorder:WhichKeyBorder,FloatTitle:WhichKeyTitle' },
    },
    layout = { width = { min = 27, max = 38 }, spacing = 3, align = 'left' },
    spec = {
      { '<leader>f', group = 'Files' }, { '<leader>b', group = 'Buffers' },
      { '<leader>c', group = 'Code' }, { '<leader>d', group = 'Docs' },
      { '<leader>m', group = 'Markdown' }, { '<leader>g', group = 'Git' },
      { '<leader>s', group = 'Search' }, { '<leader>w', group = 'Windows' },
      { '<leader>x', group = 'Trouble' }, { '<leader>q', group = 'Session' },
      { '<leader>u', group = 'UI' }, { '<leader>l', group = 'LSP' },
      { '<leader>1', group = 'Station' }, { '<leader>h', group = 'Help' },
    },
  }
end

function M.setup()
  vim.api.nvim_create_user_command('BlackDeck', function()
    require('which-key').show({ keys = '<leader>', loop = true })
  end, { desc = 'Open the Black Deck command guide', force = true })
end

return M
