local M = {}
function M.files()
  return { windows = {
    max_number = vim.o.columns < 100 and 1 or 3,
    width_focus = math.max(1, math.min(36, vim.o.columns - 8)),
    width_nofocus = 16, preview = false,
  } }
end

function M.decorate_files(ev)
  local state = require('mini.files').get_explorer_state()
  if not state or not vim.api.nvim_win_is_valid(ev.data.win_id) then return end
  local total, before, path = 0, 0, nil
  for _, win in ipairs(state.windows) do
    local width = vim.api.nvim_win_get_width(win.win_id) + 2
    if win.win_id == ev.data.win_id then path = win.path; before = total end
    total = total + width
  end
  if not path then return end
  local cfg = vim.api.nvim_win_get_config(ev.data.win_id)
  local tab = vim.o.showtabline == 2 or (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1)
  local row = (tab and 1 or 0) + (vim.o.lines >= 20 and 2 or 0)
  cfg.row = row
  cfg.col = math.max(0, math.min(2, vim.o.columns - total)) + before
  cfg.height = math.max(1, math.min(cfg.height, 18, vim.o.lines - row - 3))
  cfg.border = { ' ', '─', ' ', ' ', ' ', ' ', ' ', ' ' }
  local name = vim.fn.fnamemodify(path, ':t')
  if name == '' then name = '/' end
  local room = math.max(1, cfg.width - 5)
  if vim.fn.strdisplaywidth(name) > room then
    while vim.fn.strdisplaywidth(name) > room - 1 and name ~= '' do
      name = vim.fn.strcharpart(name, 0, vim.fn.strchars(name) - 1)
    end
    name = name .. '…'
  end
  cfg.title = '  ' .. name .. ' '
  cfg.title_pos = 'left'
  vim.api.nvim_win_set_config(ev.data.win_id, cfg)
  vim.wo[ev.data.win_id].winblend = 0
end

function M.setup()
  local group = vim.api.nvim_create_augroup('ToolLayout', { clear = true })
  vim.api.nvim_create_autocmd('VimResized', { group = group, callback = function()
    local files = package.loaded['mini.files']
    if files and files.get_explorer_state() then files.refresh(M.files()) end
  end })
  vim.api.nvim_create_autocmd('User', { group = group, pattern = 'MiniFilesWindowUpdate', callback = M.decorate_files })
end
return M
