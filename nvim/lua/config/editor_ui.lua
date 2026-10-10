-- Native window titles: no parser calls or filesystem work on draw.
local M = {}
local ui = require('config.ui')
local function escape(value) return value:gsub('[%c]', '?'):gsub('%%', '%%%%') end
local function fit(value, width)
  if width <= 0 then return '' end
  if vim.fn.strdisplaywidth(value) <= width then return value end
  local marker = ui.accessible and '.' or '…'
  local count = vim.fn.strchars(value)
  for start = 1, count do
    local tail = vim.fn.strcharpart(value, start)
    if vim.fn.strdisplaywidth(marker .. tail) <= width then return marker .. tail end
  end
  return marker
end
function M.update()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local markdown = package.loaded['config.markdown']
    local reading = markdown and markdown.reader_active and markdown.reader_active(win)
    if vim.api.nvim_win_get_config(win).relative == '' and vim.bo[buf].buftype == '' and not reading then
      local file = vim.api.nvim_buf_get_name(buf)
      if file == '' then vim.wo[win].winbar = '' else
        -- :lcd and :tcd can give each window a different relative path.
        local relative = vim.fs.relpath(vim.fn.getcwd(win), file) or vim.fn.fnamemodify(file, ':~')
        relative = relative:gsub('[%c]', '?')
        local folder, name = relative:match('^(.*)/([^/]+)$')
        name = name or relative
        local suffix = (vim.bo[buf].modified and (' ' .. ui.icon('modified')) or '') .. (vim.bo[buf].readonly and ' [RO]' or '')
        local width = math.max(1, vim.api.nvim_win_get_width(win) - 2)
        suffix = fit(suffix, width)
        local available = math.max(0, width - vim.fn.strdisplaywidth(suffix))
        name = fit(name, available)
        local separator = ui.accessible and ' / ' or '  ›  '
        local folder_width = available - vim.fn.strdisplaywidth(name) - vim.fn.strdisplaywidth(separator)
        folder = not ui.accessible and folder and folder_width >= 3 and fit(folder, folder_width) or nil
        vim.wo[win].winbar = '%#BlackPath#  ' .. (folder and escape(folder) .. separator or '')
          .. '%#BlackFileTitle#' .. escape(name)
          .. (vim.bo[buf].modified and '%#BlackModified#' or '') .. escape(suffix) .. '%*'
      end
    elseif not reading and vim.wo[win].winbar:find('%%#BlackPath#', 1) then
      vim.wo[win].winbar = ''
    end
  end
end
function M.setup()
  local group = vim.api.nvim_create_augroup('BlackEditorTitles', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufFilePost', 'BufModifiedSet', 'DirChanged', 'WinResized' }, {
    group = group, callback = M.update,
  })
  vim.api.nvim_create_autocmd('OptionSet', { group = group, pattern = 'readonly', callback = M.update })
  M.update()
end
return M
