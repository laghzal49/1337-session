-- A compact project home; rendering never shells out or walks the filesystem.
local ui = require('config.ui')
local function fit(value, width)
  if vim.fn.strdisplaywidth(value) <= width then return value end
  local chars = vim.fn.strchars(value)
  while chars > 0 and vim.fn.strdisplaywidth(vim.fn.strcharpart(value, 0, chars) .. '…') > width do chars = chars - 1 end
  return vim.fn.strcharpart(value, 0, chars) .. '…'
end
local function action(icon, label, key, callback, pane)
  local icon_width = vim.g.have_nerd_font == false and 8 or 4
  return { pane = pane or 1, key = key, action = callback,
    text = { { key .. '  ', hl = 'BlackDashboardKey', width = 3 },
      { ui.icon(icon) .. '  ', hl = 'SnacksDashboardIcon', width = icon_width },
      { label, hl = 'SnacksDashboardDesc', width = 25 } } }
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
      local separator = ui.accessible and '  | ' or '  • '
      local status = separator .. (info.dirty and 'tracked changes' or 'tracked clean')
      local room = width - vim.fn.strdisplaywidth(prefix .. status)
      branch_text = room >= 1 and (prefix .. fit(info.branch, room) .. status)
        or fit(info.dirty and 'tracked changes' or 'tracked clean', width)
    else
      branch_text = fit(vim.fn.fnamemodify(info.root, ':~'), width)
    end
    local sections = {
      { text = { { fit('1337  /  PERFECT BLACK', width), hl = 'SnacksDashboardHeader' } }, padding = tall and 2 or 1 },
      { text = fit('YOUR WORKSPACE  ·  READY TO BUILD', width), hl = 'BlackMuted', padding = 1 },
      { text = { { 'PROJECT  ', hl = 'BlackLabel' }, { fit(info.name, math.max(1, width - 9)), hl = 'BlackBrand' } }, padding = 1 },
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
        local room = math.max(1, width - section.text[1].width - section.text[2].width)
        section.text[3][1] = fit(section.text[3][1], room)
        section.text[3].width = math.min(25, room)
      end
      if size.height < 24 then section.padding = nil end
    end
    if wide and tall then
      local groups = {
        { 'MOVE THROUGH YOUR PROJECT', { { 'Space e', 'Explorer' }, { 'Space f', 'Files' },
          { 'Space /', 'Search' }, { 'Space r', 'Project tasks' } } },
        { 'WRITE AND INSPECT', { { 'Ctrl-S', 'Save' }, { 'Ctrl-T', 'Terminal' },
          { 'K', 'Documentation' }, { 'gK', 'Deep reference' } } },
        { 'DEBUG', { { 'F5', 'Start / continue' }, { 'F10', 'Step over' },
          { 'Space Db', 'Breakpoint' }, { 'Space Dg', 'Generate profile' } } },
      }
      for _, group in ipairs(groups) do
        sections[#sections + 1] = { pane = 2, text = group[1], hl = 'BlackLabel', padding = 1 }
        for _, entry in ipairs(group[2]) do
          sections[#sections + 1] = { pane = 2, text = {
            { entry[1], hl = 'BlackDashboardKey', width = 11 },
            { entry[2], hl = 'BlackMuted' },
          } }
        end
        sections[#sections + 1] = { pane = 2, text = ' ' }
      end
    end
    return sections
  end,
}
