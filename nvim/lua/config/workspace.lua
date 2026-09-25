local M = {
  active = false,
  owned_windows = {},
  original_windows = {},
}

local function remember_windows()
  local known = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    known[win] = true
  end
  return known
end

local function remember_new_windows(known)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if not known[win] then M.owned_windows[win] = true end
  end
end

local function safely(label, callback)
  local ok, err = pcall(callback)
  if not ok then
    vim.notify(('Workspace: %s unavailable'):format(label), vim.log.levels.DEBUG)
  end
  return ok, err
end

local function open_files()
  local files = require('mini.files')
  local path = vim.api.nvim_buf_get_name(0)
  files.open(vim.uv.fs_stat(path) and path or require('config.project').root(), true,
    require('config.tool_layout').files())
end

local function open_dashboard()
  if Snacks and Snacks.dashboard and Snacks.dashboard.open then
    Snacks.dashboard.open()
  end
end

function M.open_git()
  if vim.fn.executable('lazygit') == 0 then
    vim.notify('Install lazygit to open Git UI', vim.log.levels.WARN)
    return
  end
  Snacks.lazygit({ cwd = require('config.project').root() })
end

function M.enter()
  if M.active then return end
  M.active = true
  M.original_windows = remember_windows()
  M.owned_windows = {}

  local known = remember_windows()
  safely('file tree', open_files)
  remember_new_windows(known)

  known = remember_windows()
  safely('symbols', function() vim.cmd('AerialOpen') end)
  remember_new_windows(known)

  known = remember_windows()
  safely('diagnostics', function() vim.cmd('Trouble diagnostics open') end)
  remember_new_windows(known)

  known = remember_windows()
  safely('terminal', function()
    Snacks.terminal(nil, { cwd = require('config.project').root() })
  end)
  remember_new_windows(known)

  local current = vim.api.nvim_get_current_buf()
  if vim.bo[current].buftype == '' and vim.fn.line('$') == 1 and vim.fn.getline(1) == '' then
    known = remember_windows()
    safely('dashboard', open_dashboard)
    remember_new_windows(known)
  end

  vim.notify('Workspace mode on · <leader>uw to exit', vim.log.levels.INFO)
end

function M.exit()
  if not M.active then return end
  for win in pairs(M.owned_windows) do
    if vim.api.nvim_win_is_valid(win) and not M.original_windows[win] then
      pcall(vim.api.nvim_win_close, win, false)
    end
  end
  M.active = false
  M.owned_windows = {}
  M.original_windows = {}
  vim.notify('Workspace mode off', vim.log.levels.INFO)
end

function M.toggle()
  if M.active then M.exit() else M.enter() end
end

vim.api.nvim_create_user_command('WorkspaceToggle', M.toggle, { desc = 'Toggle workspace mode' })
vim.api.nvim_create_user_command('WorkspaceExit', M.exit, { desc = 'Exit workspace mode' })

return M
