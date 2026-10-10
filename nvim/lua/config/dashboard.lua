-- A compact project home; rendering never shells out or walks the filesystem.
local ui = require('config.ui')
local function action(icon, label, key, callback, pane)
  return { pane = pane or 1, key = key, action = callback,
    text = { { ui.icon(icon) .. '  ', hl = 'SnacksDashboardIcon' },
      { label, hl = 'SnacksDashboardDesc', width = 25 }, { ' ' .. key .. ' ', hl = 'BlackKey' } } }
end
return {
  width = 42, pane_gap = 6,
  sections = function()
    local wide, tall = vim.o.columns >= 100, vim.o.lines >= 32
    local info = require('config.workspace_info').get()
    local sections = {
      { text = { { tall and 'P E R F E C T\nB L A C K   /   I I' or 'PERFECT BLACK / II', hl = 'SnacksDashboardHeader' } }, padding = 1 },
      { text = 'CODE  /  BUILD  /  DEBUG', hl = 'BlackMuted', padding = 1 },
      { text = { { 'WORKSPACE  ', hl = 'BlackLabel' }, { info.name, hl = 'BlackBrand' } }, padding = 1 },
      { text = info.branch ~= '' and (ui.icon('branch') .. ' ' .. info.branch .. (info.dirty and '  • tracked changes' or '  • tracked clean'))
          or vim.fn.fnamemodify(info.root, ':~'), hl = 'BlackMuted', padding = 1 },
      action('file', 'Find files', 'f', function() require('config.pick').open('files') end),
      action('search', 'Search project', 'g', function() require('config.pick').open('grep') end),
      action('clock', 'Recent files', 'r', function() require('config.pick').open('oldfiles') end),
      action('file_new', 'New buffer', 'n', ':ene | startinsert'),
      action('session', 'Restore session', 's', function() require('persistence').load() end),
      action('terminal', 'Project terminal', 't', function() require('config.terminal').toggle() end),
      action('code', 'Build / Make targets', 'b', function() require('config.makefile').pick() end),
      action('help', 'Keys & workflows', '?', function() require('config.cheatsheet').toggle() end),
      action('quit', 'Quit', 'q', ':qa'),
    }
    if wide and tall then
      sections[#sections + 1] = { pane = 2, text = 'PICK UP WHERE YOU LEFT OFF', hl = 'BlackLabel', padding = 1 }
      sections[#sections + 1] = { pane = 2, section = 'recent_files', cwd = info.root, limit = 6, padding = 2 }
      sections[#sections + 1] = { pane = 2, text = 'EDITING', hl = 'BlackLabel', padding = 1 }
      sections[#sections + 1] = { pane = 2, text = 'Space  commands    Ctrl-S  save\nSpace e  explorer  Ctrl-T  terminal\nK  documentation  gK  deep reference', hl = 'BlackMuted', padding = 2 }
      sections[#sections + 1] = { pane = 2, text = 'DEBUGGING', hl = 'BlackLabel', padding = 1 }
      sections[#sections + 1] = { pane = 2, text = 'F5  start / continue   F10  step over\nSpace Db  breakpoint   Space Du  panels', hl = 'BlackMuted', padding = 2 }
      sections[#sections + 1] = { pane = 2, section = 'startup' }
    end
    return sections
  end,
}
