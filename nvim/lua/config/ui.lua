-- Shared UI constants and design tokens for borders, sizes, and blending.
-- Referenced by options.lua, lazy.lua, and every plugin that draws a panel.
local M = {
  border = "rounded",
  blend = 0,
  max_width = 80,
  max_height = 20,
  colors = {
    teal = "#4FD1C5",
    lilac = "#C7A6FF",
    text = "#D7E3FF",
    selection = "#14263D",
    selection_bright = "#164B4A",
    border = "#25334A",
    border_soft = "#2A5961",
    error = "#FF8FA3",
    cursor = '#69AFFF',
    cursor_insert = '#7FE3C2',
  },
  -- Keep glyphs in one place so dashboard, panels, completion, and statusline
  -- do not slowly drift into competing icon sets. Set `vim.g.have_nerd_font`
  -- to false for a readable ASCII-only fallback on minimal terminals.
  icons = {
    workspace = { nerd = '󰉋', text = '[W]' },
    search = { nerd = '󰍉', text = '/' },
    file = { nerd = '󰈙', text = '[F]' },
    file_new = { nerd = '󰝒', text = '[+F]' },
    folder = { nerd = '󰉋', text = '[D]' },
    folder_open = { nerd = '󰝰', text = '[D/]' },
    markdown = { nerd = '󰍔', text = '[MD]' },
    code = { nerd = '󰅩', text = '[CODE]' },
    python = { nerd = '󰌠', text = '[PY]' },
    lua = { nerd = '󰢱', text = '[LUA]' },
    javascript = { nerd = '󰌞', text = '[JS]' },
    typescript = { nerd = '󰛦', text = '[TS]' },
    rust = { nerd = '󱘗', text = '[RS]' },
    shell = { nerd = '', text = '[SH]' },
    docker = { nerd = '󰡨', text = '[DOCKER]' },
    buffer = { nerd = '󰓩', text = '[B]' },
    terminal = { nerd = '', text = '>_' },
    branch = { nerd = '', text = 'git:' },
    git = { nerd = '󰊢', text = '[GIT]' },
    diff = { nerd = '', text = '[DIFF]' },
    symbols = { nerd = '󰅩', text = '[S]' },
    diagnostics = { nerd = '󰅚', text = '[!]' },
    help = { nerd = '󰋖', text = '[?]' },
    command = { nerd = '', text = ':' },
    read = { nerd = '󰗈', text = '[read]' },
    lock = { nerd = '󰌾', text = '[ro]' },
    modified = { nerd = '●', text = '*' },
    error = { nerd = '', text = 'E' },
    warn = { nerd = '', text = 'W' },
    info = { nerd = '', text = 'I' },
    hint = { nerd = '󰌵', text = 'H' },
    check = { nerd = '󰄬', text = '[OK]' },
    close = { nerd = '󰅖', text = 'x' },
    arrow_right = { nerd = '', text = '->' },
    arrow_down = { nerd = '', text = 'v' },
    dot = { nerd = '●', text = '·' },
    ellipsis = { nerd = '…', text = '...' },
    star = { nerd = '', text = '*' },
    lightning = { nerd = '⚡', text = '!' },
    gear = { nerd = '', text = '[CFG]' },
    package = { nerd = '', text = '[PKG]' },
    telescope = { nerd = '', text = '[TEL]' },
    key = { nerd = '󰌋', text = '[KEY]' },
    clock = { nerd = '󰅐', text = '[TIME]' },
    calendar = { nerd = '󰃭', text = '[DATE]' },
    person = { nerd = '󰀄', text = '[USR]' },
    debug = { nerd = '', text = '[DBG]' },
    play = { nerd = '󰐊', text = '[>]' },
    stop = { nerd = '󰓛', text = '[X]' },
  },
  symbols = {
    Array = "󱡠", Boolean = "󰨙", Class = "󰆧", Constant = "󰏿",
    Constructor = "", Enum = "", EnumMember = "", Event = "",
    Field = "", File = "󰈙", Function = "󰊕", Interface = "",
    Key = "󰌋", Method = "󰊕", Module = "", Namespace = "󰦮",
    Null = "󰟢", Number = "󰎠", Object = "", Operator = "󰆕",
    Package = "", Property = "", String = "", Struct = "󰆼",
    TypeParameter = "󰗴", Variable = "󰀫", Collapsed = "",
  },
}

if vim.g.have_nerd_font == nil then
  vim.g.have_nerd_font = vim.env.NVIM_ASCII_ICONS ~= '1'
end

function M.icon(name)
  local icon = M.icons[name] or M.icons.file
  return vim.g.have_nerd_font == false and icon.text or icon.nerd
end

function M.symbol(name)
  if vim.g.have_nerd_font == false then return "*" end
  return M.symbols[name] or M.symbols.Variable
end

return M
