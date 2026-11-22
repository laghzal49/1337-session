-- Adapted from nvimz's clean Moon statusline design (MIT, © 2026 @andev0x).
-- Rendered using native statusline syntax so it adds zero statusline plugins.
local M = {}
local c = require('config.palette')
local last_code_buf = nil

local modes = {
  n = {' ● ', 'NvimzModeNormal'}, no = {' ● ', 'NvimzModeNormal'},
  i = {' ✎ ', 'NvimzModeInsert'}, ic = {' ✎ ', 'NvimzModeInsert'},
  v = {' ◈ ', 'NvimzModeVisual'}, V = {' ◆ ', 'NvimzModeVisual'},
  ['\22'] = {' ■ ', 'NvimzModeVisual'},
  R = {' ↺ ', 'NvimzModeReplace'}, c = {' ⌘ ', 'NvimzModeCommand'},
  s = {' ◇ ', 'NvimzModeVisual'}, t = {' ▸ ', 'NvimzModeTerminal'},
}
local function hl(name) return '%#' .. name .. '#' end
local function escape(text) return (tostring(text or ''):gsub('%%', '%%%%'):gsub('[%c]', '?')) end
local function setup_highlights()
  local set = vim.api.nvim_set_hl
  local mode = {
    Normal = c.focus, Insert = c.success, Visual = c.keyword,
    Replace = c.error, Command = c.literal, Terminal = c.type,
  }
  for name, color in pairs(mode) do
    set(0, 'NvimzMode' .. name, { fg = c.on_accent, bg = color, bold = true })
  end
  local bg = c.panel
  local groups = {
    NvimzStatusText = { fg = c.path, bg = bg },
    NvimzStatusFile = { fg = c.strong, bg = bg, bold = true },
    NvimzStatusChanged = { fg = c.warning, bg = bg, bold = true },
    NvimzStatusPath = { fg = c.muted, bg = bg },
    NvimzStatusGit = { fg = c.muted, bg = bg },
    NvimzStatusError = { fg = c.error, bg = bg, bold = true },
    NvimzStatusWarning = { fg = c.warning, bg = bg, bold = true },
    NvimzStatusLSP = { fg = c.muted, bg = bg },
    NvimzStatusPill = { fg = c.keyword, bg = c.line, bold = true },
    NvimzStatusLocation = { fg = c.strong, bg = c.line, bold = true },
    NvimzStatusProgress = { fg = c.muted, bg = c.line },
    NvimzStatusInactive = { fg = c.muted, bg = bg },
  }
  for name, spec in pairs(groups) do set(0, name, spec) end
end
local function get_mode()
  local value = vim.fn.mode(1)
  return modes[value] or modes[value:sub(1, 1)] or modes.n
end
local function code_buffer()
  local current = vim.api.nvim_get_current_buf()
  if vim.bo[current].buftype == '' and vim.api.nvim_buf_get_name(current) ~= '' then return current end
  if last_code_buf and vim.api.nvim_buf_is_valid(last_code_buf) then return last_code_buf end
  return current
end
local function name_info(buf)
  local full = vim.api.nvim_buf_get_name(buf)
  local name = full ~= '' and vim.fn.fnamemodify(full, ':t') or ''
  if name == '' or vim.bo[buf].filetype == 'nvimz_dashboard' then
    return '󰖔  Welcome, @' .. (vim.env.USER or 'developer'), false, true
  end
  return escape(name), vim.bo[buf].modified, false
end
local function git()
  -- workspace_info has its own caching. No shell commands on a redraw.
  local ok, info = pcall(function() return require('config.workspace_info').get() end)
  if not ok or not info or not info.branch or info.branch == '' then return '' end
  return '  󰊢 ' .. escape(info.branch)
end
local file_sizes = {}
local function update_size(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local path = vim.api.nvim_buf_get_name(buf)
  local stat = path ~= '' and vim.uv.fs_stat(path) or nil
  local bytes = stat and stat.size or 0
  if bytes < 1 then file_sizes[buf] = ''
  elseif bytes < 1024 then file_sizes[buf] = bytes .. 'B'
  elseif bytes < 1024 * 1024 then file_sizes[buf] = string.format('%.1fKB', bytes / 1024)
  else file_sizes[buf] = string.format('%.1fMB', bytes / 1048576) end
end
local function diagnostics(buf)
  local counts = vim.diagnostic.count(buf)
  local errors = counts[vim.diagnostic.severity.ERROR] or 0
  local warnings = counts[vim.diagnostic.severity.WARN] or 0
  local entries = {}
  if errors > 0 then entries[#entries + 1] = hl('NvimzStatusError') .. ' ' .. errors end
  if warnings > 0 then entries[#entries + 1] = hl('NvimzStatusWarning') .. ' ' .. warnings end
  return table.concat(entries, ' ')
end
local function lsp(buf)
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    if client.name ~= 'copilot' then names[#names + 1] = client.name end
  end
  table.sort(names)
  return #names > 0 and ('󰒋 ' .. escape(table.concat(names, ','))) or ''
end
local function day_icon()
  local hour = tonumber(os.date('%H'))
  if hour >= 7 and hour < 12 then return '󰖨'
  elseif hour >= 12 and hour < 18 then return '󰖚'
  elseif hour >= 18 and hour < 22 then return '󰅶'
  else return '󰖔' end
end
function M.render()
  local mode = get_mode()
  local buf = code_buffer()
  local filename, changed, welcome = name_info(buf)
  local out = hl(mode[2]) .. mode[1] .. hl('NvimzStatusText') .. '  '
  out = out .. hl(changed and 'NvimzStatusChanged' or 'NvimzStatusFile') .. filename
  if changed then out = out .. ' ●' end
  if vim.bo[buf].readonly then out = out .. ' 󰌾' end
  if not welcome and vim.o.columns >= 95 then
    local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':~:.:h')
    if path ~= '.' and path ~= '' then
      out = out .. hl('NvimzStatusPath') .. '  ' .. escape(path)
    end
  end
  if not welcome and vim.o.columns >= 85 then
    out = out .. hl('NvimzStatusGit') .. git()
  end
  out = out .. hl('NvimzStatusText') .. '%<%='
  if not welcome then
    local diags = diagnostics(buf)
    if diags ~= '' then out = out .. diags .. '  ' end
    if vim.o.columns >= 95 then
      local server = lsp(buf)
      if server ~= '' then out = out .. hl('NvimzStatusLSP') .. server .. '  ' end
    end
    if vim.o.columns >= 110 then
      local size = file_sizes[buf] or ''
      if size ~= '' then out = out .. hl('NvimzStatusPath') .. '󰈐 ' .. size .. '  ' end
    end
  end
  out = out .. hl('NvimzStatusPill') .. ' ' .. day_icon() .. '  '
  out = out .. hl('NvimzStatusLocation') .. '%l:%c  '
  out = out .. hl('NvimzStatusProgress') .. '%p%% '
  return out
end
function M.setup()
  setup_highlights()
  vim.o.laststatus = 3
  vim.o.showtabline = 0 -- enforced after the plugin manager initializes
  vim.o.relativenumber = false -- match upstream nvimz numbering
  vim.o.statusline = "%!v:lua.require'config.nvimz_statusline'.render()"
  local current = vim.api.nvim_get_current_buf()
  if vim.bo[current].buftype == '' and vim.api.nvim_buf_get_name(current) ~= '' then last_code_buf = current end
  local group = vim.api.nvim_create_augroup('NvimzStatusline', { clear = true })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function(ev)
      if vim.bo[ev.buf].buftype == '' and vim.api.nvim_buf_get_name(ev.buf) ~= '' then
        last_code_buf = ev.buf
      end
    end,
  })
  vim.api.nvim_create_autocmd('BufWipeout', { group = group, callback = function(ev)
    file_sizes[ev.buf] = nil
    if last_code_buf == ev.buf then last_code_buf = nil end
  end })
  vim.api.nvim_create_autocmd('ColorScheme', { group = group, callback = setup_highlights })
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'BufEnter' }, {
    group = group, callback = function(ev) update_size(ev.buf) end,
  })
end
return M
