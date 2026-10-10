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
  local role = ({file='Blue', search='Cyan', clock='Blue', file_new='Green',
    session='Purple', terminal='Green', code='Yellow', help='Blue', quit='Grey'})[icon] or 'Grey'
  return { pane = pane or 1, key = key, action = callback,
    text = { { key .. '  ', hl = 'BlackDashboardKey', width = 3 },
      { ui.icon(icon) .. '  ', hl = 'MiniIcons' .. role, width = icon_width },
      { label, hl = 'SnacksDashboardDesc', width = 25 } } }
end
local function recent_files(root)
  local files, seen = {}, {}
  root = root:gsub('/+$', '')
  -- oldfiles is already in memory; bound the scan and only stat candidates in
  -- this project so opening the dashboard stays cheap on large histories.
  for index = 1, math.min(#vim.v.oldfiles, 80) do
    local path = vim.v.oldfiles[index]
    if type(path) == 'string' and path:sub(1, #root + 1) == root .. '/'
      and not seen[path] and vim.fn.filereadable(path) == 1 then
      seen[path] = true
      files[#files + 1] = { path = path, label = path:sub(#root + 2) }
      if #files == 5 then break end
    end
  end
  return files
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
      sections[#sections + 1] = { pane = 2, text = 'PROJECT CONTEXT', hl = 'BlackDashboardHeading', padding = 1 }
      sections[#sections + 1] = { pane = 2, text = {
        { 'root  ', hl = 'BlackDashboardMeta', width = 6 },
        { fit(vim.fn.fnamemodify(info.root, ':~'), width - 6), hl = 'BlackDashboardPath' },
      } }
      sections[#sections + 1] = { pane = 2, text = ' ' }
      sections[#sections + 1] = { pane = 2, text = 'RECENT IN THIS PROJECT', hl = 'BlackDashboardHeading', padding = 1 }
      local files = recent_files(info.root)
      if #files == 0 then
        sections[#sections + 1] = { pane = 2, text = 'No recent project files', hl = 'BlackDashboardMeta' }
      end
      for index, item in ipairs(files) do
        local path = item.path
        sections[#sections + 1] = { pane = 2, key = tostring(index),
          action = function() vim.cmd.edit(vim.fn.fnameescape(path)) end,
          text = {
            { tostring(index) .. '  ', hl = 'BlackDashboardKey', width = 3 },
            { fit(item.label, width - 3), hl = 'BlackDashboardPath' },
          } }
      end
      sections[#sections + 1] = { pane = 2, text = ' ' }
      sections[#sections + 1] = { pane = 2, text = 'KEEP MOVING', hl = 'BlackDashboardHeading', padding = 1 }
      for _, entry in ipairs({ { 'Space e', 'Explorer' }, { 'Space /', 'Project search' },
        { 'Space rt', 'Project tasks' }, { 'Ctrl-T', 'Terminal' }, { 'F5', 'Start debugger' } }) do
        sections[#sections + 1] = { pane = 2, text = {
          { entry[1], hl = 'BlackDashboardKey', width = 11 },
          { entry[2], hl = 'BlackDashboardMeta' },
        } }
      end
    end
    return sections
  end,
}
