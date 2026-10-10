-- Adaptive coding layout; preserve existing windows and never close edited files.
local M = { active = false, owned_windows = {}, original_windows = {}, tab = nil }
local function windows()
  local result = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do result[win] = true end
  return result
end
local function open_panel(label, callback)
  local before = windows()
  local ok = pcall(callback)
  if not ok then vim.notify('Workspace: ' .. label .. ' unavailable', vim.log.levels.DEBUG) end
  for win in pairs(windows()) do
    if not before[win] then
      M.owned_windows[win] = vim.api.nvim_win_get_buf(win)
    end
  end
end
function M.open_git()
  if vim.fn.executable('lazygit') == 0 then vim.notify('Install lazygit to open Git UI', vim.log.levels.WARN); return end
  Snacks.lazygit({ cwd = require('config.project').root() })
end
function M.enter()
  if M.active then
    if M.tab and vim.api.nvim_tabpage_is_valid(M.tab) then vim.api.nvim_set_current_tabpage(M.tab) end
    return
  end
  M.active, M.tab = true, vim.api.nvim_get_current_tabpage()
  M.original_windows, M.owned_windows = windows(), {}
  M.editor = vim.api.nvim_get_current_win()
  M.view = vim.fn.winsaveview()
  -- Narrow terminals retain a real editing area rather than stacking panels.
  if vim.o.columns >= 100 then
    open_panel('file tree', function()
      Snacks.explorer({ cwd = require('config.project').root(), focus = false, on_show = function(picker)
        if not M.active or vim.api.nvim_get_current_tabpage() ~= M.tab then return end
        for _, panel in pairs(picker.layout.wins) do
          if panel.win and vim.api.nvim_win_is_valid(panel.win) and not M.original_windows[panel.win] then
            M.owned_windows[panel.win] = vim.api.nvim_win_get_buf(panel.win)
          end
        end
      end })
    end)
  end
  if vim.o.columns >= 150 and #vim.lsp.get_clients({ bufnr = vim.api.nvim_win_get_buf(M.editor) }) > 0 then
    open_panel('symbols', function() vim.cmd('AerialOpen') end)
  end
  if vim.o.lines >= 36 and #vim.diagnostic.get(nil, { severity = { min = vim.diagnostic.severity.WARN } }) > 0 then
    open_panel('diagnostics', function() vim.cmd('Trouble diagnostics open') end)
  end
  if vim.api.nvim_win_is_valid(M.editor) then
    vim.api.nvim_set_current_win(M.editor)
    vim.fn.winrestview(M.view)
  end
  vim.notify('Workspace on · editor focused · <C-t> terminal · <leader>uw exit', vim.log.levels.INFO)
end
function M.exit()
  if not M.active then return end
  for win, buf in pairs(M.owned_windows) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf and vim.api.nvim_buf_is_valid(buf)
      and vim.bo[buf].buftype ~= '' and not vim.bo[buf].modified then
      pcall(vim.api.nvim_win_close, win, false)
    end
  end
  if M.tab == vim.api.nvim_get_current_tabpage() and M.editor and vim.api.nvim_win_is_valid(M.editor) then
    vim.api.nvim_set_current_win(M.editor)
  end
  M.active, M.tab, M.editor, M.view = false, nil, nil, nil
  M.owned_windows, M.original_windows = {}, {}
  vim.notify('Workspace off', vim.log.levels.INFO)
end
function M.toggle() if M.active then M.exit() else M.enter() end end
vim.api.nvim_create_user_command('WorkspaceToggle', M.toggle, { desc = 'Toggle adaptive coding workspace' })
vim.api.nvim_create_user_command('WorkspaceExit', M.exit, { desc = 'Close only workspace-owned panels' })
return M
