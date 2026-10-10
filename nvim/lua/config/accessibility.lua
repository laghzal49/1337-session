-- Reversible UI preferences; never changes buffers, windows, or plugin loading.
local M = {}
local ui = require('config.ui')
local saved, applied = {}, {}
local function native(spec)
  local hl = {}
  for _, key in ipairs({'fg','bg','sp'}) do
    if spec[key] then hl[key] = tonumber(spec[key]:sub(2),16) end
  end
  for attr in (spec.fmt or ''):gmatch('[^,]+') do hl[attr] = true end
  return hl
end
local function highlights(startup)
  if not ui.accessible then return end
  local surfaces = require('config.surfaces')
  surfaces.set_accessible(false)
  local standard = surfaces.highlights(false)
  surfaces.set_accessible(true)
  local accessible = surfaces.highlights(true)
  local function set(name, changes, baseline)
    if not saved[name] then
      saved[name] = startup and baseline or vim.api.nvim_get_hl(0,{name=name,link=true})
    end
    local hl = vim.api.nvim_get_hl(0,{name=name,link=false})
    for key, value in pairs(changes) do hl[key] = value end
    vim.api.nvim_set_hl(0,name,hl)
    applied[name] = vim.api.nvim_get_hl(0,{name=name,link=true})
  end
  for name, spec in pairs(accessible) do
    local base = standard[name] or {}
    if not vim.deep_equal(spec,base) then
      local before, after, changes = native(base), native(spec), {}
      for key, value in pairs(after) do if before[key] ~= value then changes[key] = value end end
      for key in pairs(before) do if after[key] == nil then changes[key] = false end end
      set(name,changes,native(base))
    end
    -- Third-party themes also receive the stronger panel boundaries.
    if name:find('Border',1,true) or name == 'WinSeparator' then
      set(name,{fg=tonumber((spec.fg or '#D7E3FF'):sub(2),16)},native(base))
    end
  end
  for _, name in ipairs({'Comment','SpecialComment','TreesitterContext','BlinkCmpGhostText'}) do
    set(name,{italic=false},vim.api.nvim_get_hl(0,{name=name,link=true}))
  end
end
local function restore()
  for name, hl in pairs(saved) do
    -- Respect explicit edits the user made while the preset was active.
    if vim.deep_equal(vim.api.nvim_get_hl(0,{name=name,link=true}),applied[name]) then
      vim.api.nvim_set_hl(0,name,hl)
    end
  end
  saved, applied = {}, {}
end
function M.set(enabled)
  enabled = enabled == true
  if enabled == ui.accessible then return ui.accessible end
  if not enabled then restore() end
  ui.set_accessible(enabled)
  require('config.surfaces').set_accessible(ui.accessible)
  highlights()
  local icons = package.loaded['mini.icons']
  if icons then
    local opts = vim.deepcopy(icons.config)
    opts.style = vim.g.have_nerd_font == false and 'ascii' or 'glyph'
    icons.setup(opts)
  end
  local debugging = package.loaded['config.debugging']
  if debugging and debugging.refresh_signs then debugging.refresh_signs() end
  local specs = require('plugins.statusline')
  for index, module in ipairs({'lualine','bufferline'}) do
    if package.loaded[module] then package.loaded[module].setup(specs[index].opts()) end
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.diagnostic.is_enabled({bufnr=buf}) then
      vim.diagnostic.show(nil,buf)
    end
  end
  local titles = package.loaded['config.editor_ui']
  if titles then titles.update() end
  local symbols = package.loaded['config.symbol_context']
  if symbols then symbols.update() end
  if _G.Snacks then Snacks.dashboard.update() end
  vim.cmd.redrawstatus()
  vim.api.nvim_exec_autocmds('User', {pattern='BlackUIPresetChanged',modeline=false})
  return ui.accessible
end
function M.toggle() return M.set(not ui.accessible) end
function M.setup()
  vim.api.nvim_create_user_command('UIAccessibility', function(args)
    local mode = args.args
    if mode == '' or mode == 'toggle' then M.toggle()
    elseif mode == 'on' then M.set(true)
    elseif mode == 'off' then M.set(false)
    else vim.notify('Use :UIAccessibility on, off or toggle',vim.log.levels.WARN); return end
    vim.notify('UI preset: '..(ui.accessible and 'accessible' or 'default'),vim.log.levels.INFO)
  end, {nargs='?',force=true,complete=function() return {'on','off','toggle'} end,desc='Toggle plain icons and stronger UI contrast'})
  vim.keymap.set('n','<leader>ua',M.toggle,{desc='Toggle accessible UI preset'})
  vim.api.nvim_create_autocmd('ColorScheme', {
    group=vim.api.nvim_create_augroup('BlackAccessibleUI',{clear=true}),callback=function()
      saved, applied = {}, {}
      highlights(vim.g.colors_name == 'perfect-black')
    end,
  })
  highlights(true)
end
return M
