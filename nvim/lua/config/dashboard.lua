-- A compact project home; rendering never shells out or walks the filesystem.
local ui = require('config.ui')
local function fit(value, width)
  if vim.fn.strdisplaywidth(value) <= width then return value end
  local chars = vim.fn.strchars(value)
  while chars > 0 and vim.fn.strdisplaywidth(vim.fn.strcharpart(value, 0, chars) .. '…') > width do chars = chars - 1 end
  return vim.fn.strcharpart(value, 0, chars) .. '…'
end
local function action(icon, label, key, callback, pane)
  return { pane = pane or 1, key = key, action = callback,
    text = { { ui.icon(icon) .. '  ', hl = 'SnacksDashboardIcon' },
      { label, hl = 'SnacksDashboardDesc', width = 25 }, { ' ' .. key .. ' ', hl = 'BlackKey' } } }
end
return {
  width = 42, pane_gap = 6,
  sections = function(dashboard)
    local size = dashboard and dashboard._size or { width = vim.o.columns, height = vim.o.lines }
    local width = math.min(42, math.max(1, size.width - 4))
    if dashboard then dashboard.opts.width = width end
    local wide, tall = size.width >= 100, size.height >= 32
    local info = require('config.workspace_info').get()
    local branch_text
    if info.branch ~= '' then
      local prefix = ui.icon('branch') .. ' '
      local status = info.dirty and '  • tracked changes' or '  • tracked clean'
      local room = width - vim.fn.strdisplaywidth(prefix .. status)
      branch_text = room >= 1 and (prefix .. fit(info.branch, room) .. status)
        or fit(info.dirty and 'tracked changes' or 'tracked clean', width)
    else
      branch_text = fit(vim.fn.fnamemodify(info.root, ':~'), width)
    end
    local sections = {
      { text = { { tall and 'P E R F E C T\nB L A C K   /   I I' or fit('PERFECT BLACK / II', width), hl = 'SnacksDashboardHeader' } }, padding = 1 },
      { text = fit('CODE  /  BUILD  /  DEBUG', width), hl = 'BlackMuted', padding = 1 },
      { text = { { 'WORKSPACE  ', hl = 'BlackLabel' }, { fit(info.name, math.max(1, width - 11)), hl = 'BlackBrand' } }, padding = 1 },
      { text = branch_text, hl = 'BlackMuted', padding = 1 },
      action('file', 'Find files', 'f', function() require('config.pick').open('files') end),
      action('search', 'Search project', 'g', function() require('config.pick').open('grep') end),
      action('clock', 'Recent files', 'r', function() require('config.pick').open('oldfiles') end),
      action('file_new', 'New buffer', 'n', ':ene | startinsert'),
      action('session', 'Restore session', 's', function() require('persistence').load() end),
      action('terminal', 'Project terminal', 't', function() require('config.terminal').toggle() end),
      action('code', 'Build / project tasks', 'b', function() require('config.tasks').pick() end),
      action('help', 'Keys & workflows', '?', function() require('config.cheatsheet').toggle() end),
      action('quit', 'Quit', 'q', ':qa'),
    }
    for _, section in ipairs(sections) do
      if section.action then
        section.text[2][1] = fit(section.text[2][1], math.max(1, width - 8))
        section.text[2].width = math.min(25, math.max(1, width - 8))
      end
      if size.height < 24 then section.padding = nil end
    end
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
