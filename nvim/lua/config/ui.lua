-- Shared UI constants and design tokens for borders, sizes, and blending.
-- Referenced by options.lua, lazy.lua, and every plugin that draws a panel.
local palette = require('config.palette')
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
    cursor = palette.focus,
    cursor_insert = '#7FE3C2',
    cursor_command = '#FFD166',
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
    shell = { nerd = '󰞌', text = '[SH]' },
    docker = { nerd = '󰡨', text = '[DOCKER]' },
    buffer = { nerd = '󰓩', text = '[B]' },
    terminal = { nerd = '󰞌', text = '>_' },
    branch = { nerd = '󰊢', text = 'git:' },
    git = { nerd = '󰊢', text = '[GIT]' },
    diff = { nerd = '󰊢', text = '[DIFF]' },
    symbols = { nerd = '󰅩', text = '[S]' },
    diagnostics = { nerd = '󰅚', text = '[!]' },
    help = { nerd = '󰋖', text = '[?]' },
    command = { nerd = '󰘳', text = ':' },
    quit = { nerd = '󰅖', text = '[Q]' },
    read = { nerd = '󰍔', text = '[read]' },
    session = { nerd = '󰗈', text = '[SES]' },
    lock = { nerd = '󰌾', text = '[ro]' },
    modified = { nerd = '●', text = '*' },
    error = { nerd = '󰅚', text = 'E' },
    warn = { nerd = '󰀪', text = 'W' },
    info = { nerd = '󰋽', text = 'I' },
    hint = { nerd = '󰌵', text = 'H' },
    check = { nerd = '󰄬', text = '[OK]' },
    close = { nerd = '󰅖', text = 'x' },
    arrow_right = { nerd = '󰅂', text = '->' },
    arrow_down = { nerd = '󰅀', text = 'v' },
    dot = { nerd = '●', text = '.' },
    ellipsis = { nerd = '…', text = '...' },
    star = { nerd = '󰓎', text = '*' },
    lightning = { nerd = '⚡', text = '!' },
    gear = { nerd = '󰒓', text = '[CFG]' },
    package = { nerd = '󰏖', text = '[PKG]' },
    telescope = { nerd = '󰍉', text = '[TEL]' },
    key = { nerd = '󰌋', text = '[KEY]' },
    clock = { nerd = '󰅐', text = '[TIME]' },
    calendar = { nerd = '󰃭', text = '[DATE]' },
    person = { nerd = '󰀄', text = '[USR]' },
    debug = { nerd = '󰃤', text = '[DBG]' },
    breakpoint = { nerd = '', text = '●' },
    breakpoint_condition = { nerd = '󰘧', text = '◆' },
    debug_stopped = { nerd = '󰐊', text = '▶' },
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

local original_font, original_border = vim.g.have_nerd_font, M.border
M.accessible = false
function M.set_accessible(enabled)
  enabled = enabled == true
  if enabled == M.accessible then return end
  if enabled then original_font, original_border = vim.g.have_nerd_font, M.border end
  M.accessible = enabled
  vim.g.black_ui_preset = enabled and 'accessible' or 'default'
  if enabled then vim.g.have_nerd_font = false else vim.g.have_nerd_font = original_font end
  M.border = enabled and 'single' or original_border
end
M.set_accessible((vim.g.black_ui_preset or vim.env.NVIM_UI_PRESET) == 'accessible')

function M.icon(name)
  local icon = M.icons[name] or M.icons.file
  return vim.g.have_nerd_font == false and icon.text or icon.nerd
end

function M.symbol(name)
  if vim.g.have_nerd_font == false then return "*" end
  return M.symbols[name] or M.symbols.Variable
end

return M
