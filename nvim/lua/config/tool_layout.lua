local M = {}
local ui = require('config.ui')

local border = {
  { '╭', 'MiniFilesBorder' }, { '─', 'MiniFilesBorder' },
  { '╮', 'MiniFilesBorder' }, { '│', 'MiniFilesBorder' },
  { '╯', 'MiniFilesBorder' }, { '─', 'MiniFilesBorder' },
  { '╰', 'MiniFilesBorder' }, { '│', 'MiniFilesBorder' },
}

function M.files()
  local wide = vim.o.columns >= 100
  return { windows = {
    max_number = wide and 3 or 1,
    width_focus = math.max(1, math.min(38, math.floor(vim.o.columns * 0.36), vim.o.columns - 8)),
    width_nofocus = 18,
    width_preview = 36,
    preview = wide,
  } }
end

local function syntax_preview(win_id, path)
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= 'file' then return end
  local buf = vim.api.nvim_win_get_buf(win_id)
  local ft = vim.filetype.match({ filename = path })
  if ft and ft ~= '' then vim.bo[buf].syntax = ft end
end

function M.decorate_files(ev)
  local state = require('mini.files').get_explorer_state()
  if not state or not vim.api.nvim_win_is_valid(ev.data.win_id) then return end
  local total, before, path = 0, 0, nil
  for _, win in ipairs(state.windows) do
    local width = vim.api.nvim_win_get_width(win.win_id) + 2
    if win.win_id == ev.data.win_id then
      path = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win.win_id))
      before = total
    end
    total = total + width
  end
  if not path then return end
  local cfg = vim.api.nvim_win_get_config(ev.data.win_id)
  syntax_preview(ev.data.win_id, path)
  local tab = vim.o.showtabline == 2 or (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1)
  local row = (tab and 1 or 0) + (vim.o.lines >= 20 and 2 or 0)
  cfg.row = row
  cfg.col = math.max(0, math.floor((vim.o.columns - total) / 2)) + before
  cfg.height = math.max(1, math.min(cfg.height, 20, vim.o.lines - row - 3))
  cfg.border = border
  local name = vim.fn.fnamemodify(path, ':t')
  if name == '' then name = '/' end
  local room = math.max(1, cfg.width - 5)
  if vim.fn.strdisplaywidth(name) > room then
    while vim.fn.strdisplaywidth(name) > room - 1 and name ~= '' do
      name = vim.fn.strcharpart(name, 0, vim.fn.strchars(name) - 1)
    end
    name = name .. '…'
  end
  cfg.title = ' ' .. ui.icon('folder') .. ' ' .. name .. ' '
  cfg.title_pos = 'left'
  vim.api.nvim_win_set_config(ev.data.win_id, cfg)
  vim.wo[ev.data.win_id].winblend = 0
end

local function create_entry(buf)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_get_current_buf() ~= buf then
    vim.notify('Mini Files is not focused; reopen it with <Space>e', vim.log.levels.ERROR)
    return
  end
  vim.api.nvim_buf_set_lines(buf, row, row, false, { '' })
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
  vim.cmd('startinsert')
  vim.notify('New entry: type a filename or folder/ · press = to apply', vim.log.levels.INFO)
end

local function synchronize()
  vim.notify('Review the change list, then press y/Enter to apply or n/Esc to cancel', vim.log.levels.INFO)
  require('mini.files').synchronize()
end

local function rename_entry()
  local entry = require('mini.files').get_fs_entry()
  if not entry or not entry.name then return end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  local start = line:find(vim.pesc(entry.name), 1)
  if not start then return end
  vim.api.nvim_win_set_cursor(0, { row, start - 1 })
  vim.cmd('startinsert')
  vim.notify('Rename entry · press <Esc>, then = to apply', vim.log.levels.INFO)
end

local function delete_entry()
  local entry = require('mini.files').get_fs_entry()
  if not entry then return end
  vim.cmd('normal! dd')
  vim.notify(('Marked for deletion: %s · press = to apply or <Esc> to undo'):format(entry.name),
    vim.log.levels.WARN)
end

local function register_file_keys(buf)
  local ok, which_key = pcall(require, 'which-key')
  if not ok then return end
  which_key.add({
    { 'a', desc = 'Create file or directory', buffer = buf },
    { 'r', desc = 'Rename entry', buffer = buf },
    { 'd', desc = 'Delete entry', buffer = buf },
    { '=', desc = 'Review/apply file changes', buffer = buf },
    { 'g?', desc = 'Show Mini Files help', buffer = buf },
    { 'q', desc = 'Close file browser', buffer = buf },
  })
end

function M.setup()
  local group = vim.api.nvim_create_augroup('ToolLayout', { clear = true })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'MiniFilesBufferCreate',
    callback = function(ev)
      local opts = { buffer = ev.data.buf_id, silent = true, desc = '' }
      vim.keymap.set('n', 'a', function() create_entry(ev.data.buf_id) end,
        vim.tbl_extend('force', opts, { desc = 'Create file or directory' }))
      vim.keymap.set('n', 'r', rename_entry, vim.tbl_extend('force', opts, { desc = 'Rename entry' }))
      vim.keymap.set('n', 'd', delete_entry, vim.tbl_extend('force', opts, { desc = 'Delete entry' }))
      vim.keymap.set('n', '=', synchronize, vim.tbl_extend('force', opts, {
        desc = 'Review and apply file changes',
      }))
      register_file_keys(ev.data.buf_id)
    end,
  })
  vim.api.nvim_create_autocmd('VimResized', { group = group, callback = function()
    local files = package.loaded['mini.files']
    if files and files.get_explorer_state() then files.refresh(M.files()) end
  end })
  for action, level in pairs({
    Create = vim.log.levels.INFO,
    Delete = vim.log.levels.WARN,
    Rename = vim.log.levels.INFO,
  }) do
    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'MiniFilesAction' .. action,
      callback = function(ev)
        local data = ev.data or {}
        local path = data.to or data.from or ''
        local name = vim.fn.fnamemodify(path, ':t')
        if name == '' then name = path end
        local message = ('%s: %s'):format(action, name)
        if action == 'Delete' and data.to then
          message = ('Moved to Mini Files trash: %s'):format(name)
        end
        vim.notify(message, level)
      end,
    })
  end
  vim.api.nvim_create_autocmd('User', { group = group, pattern = 'MiniFilesWindowUpdate', callback = M.decorate_files })
end

return M
