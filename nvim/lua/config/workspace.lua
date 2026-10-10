-- Adaptive coding layout; preserve existing windows and never close edited files.
local M = { active = false, owned_windows = {}, original_windows = {}, tab = nil }
local function retire_explorer(picker)
  if picker.closed or picker._workspace_retiring then return end
  local retirement = { tab = picker._workspace_tab }
  picker._workspace_retiring = retirement
  local buffers = {}
  for _, panel in pairs(picker.layout.wins) do
    if panel.win and vim.api.nvim_win_is_valid(panel.win) then buffers[panel.win] = vim.api.nvim_win_get_buf(panel.win) end
  end
  local close
  close = function()
    vim.schedule(function()
      if picker.closed or picker._workspace_retiring ~= retirement then return end
      for _, panel in pairs(picker.layout.wins) do
        if panel.win and vim.api.nvim_win_is_valid(panel.win) then
          local buf = vim.api.nvim_win_get_buf(panel.win)
          if (buffers[panel.win] and buffers[panel.win] ~= buf) or vim.bo[buf].buftype == '' or vim.bo[buf].modified then
            picker._workspace_retiring = nil
            return
          end
        end
      end
      local task = picker.finder and picker.finder.task
      -- BufEnter can replace the scan while a prior done callback was queued.
      if task and task:running() then task:on('done', close) else pcall(picker.close, picker) end
    end)
  end
  -- Snacks' first finder may still own async callbacks when its window appears.
  -- Let that finite directory scan finish before destroying its matcher state.
  close()
end
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
  M.session = {}
  local session = M.session
  M.active, M.tab = true, vim.api.nvim_get_current_tabpage()
  M.original_windows, M.owned_windows = windows(), {}
  M.editor = vim.api.nvim_get_current_win()
  M.view = vim.fn.winsaveview()
  -- Narrow terminals retain a real editing area rather than stacking panels.
  if vim.o.columns >= 100 then
    open_panel('file tree', function()
      local existing = {}
      for _, picker in ipairs(Snacks.picker.get({ source = 'explorer', tab = false })) do
        if picker:on_current_tab() or picker._workspace_tab == M.tab then existing[picker] = true end
      end
      for picker in pairs(existing) do
        if picker._workspace_retiring then
          picker._workspace_retiring = nil -- Reclaim our pending explorer on immediate re-entry.
          M.explorer = picker
          for _, panel in pairs(picker.layout.wins) do
            if panel.win and vim.api.nvim_win_is_valid(panel.win) then
              M.original_windows[panel.win] = nil
              M.owned_windows[panel.win] = vim.api.nvim_win_get_buf(panel.win)
            end
          end
        end
      end
      if next(existing) then return end
      local explorer = Snacks.explorer({ cwd = require('config.project').root(), focus = false, on_show = function(picker)
        if existing[picker] then return end
        if not M.active or (M.session ~= session and M.explorer ~= picker) then
          retire_explorer(picker)
          return
        end
        for _, panel in pairs(picker.layout.wins) do
          if panel.win and vim.api.nvim_win_is_valid(panel.win) and not M.original_windows[panel.win] then
            M.owned_windows[panel.win] = vim.api.nvim_win_get_buf(panel.win)
          end
        end
      end })
      if explorer and not existing[explorer] then
        M.explorer = explorer
        explorer._workspace_tab = M.tab
      end
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
  -- Close the picker itself, including one still waiting for its first redraw.
  -- A window repurposed for editing remains under the user's control.
  local explorer, explorer_windows = M.explorer, {}
  if explorer and explorer.layout then
    for _, panel in pairs(explorer.layout.wins) do
      if panel.win then explorer_windows[panel.win] = true end
    end
  end
  local safe = true
  for win in pairs(explorer_windows) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if (M.owned_windows[win] and buf ~= M.owned_windows[win])
        or vim.bo[buf].buftype == '' or vim.bo[buf].modified then safe = false end
    end
  end
  if explorer and safe and not explorer.closed then retire_explorer(explorer) end
  M.explorer, M.session = nil, nil
  for win, buf in pairs(M.owned_windows) do
    if not (explorer_windows[win] and safe) and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf and vim.api.nvim_buf_is_valid(buf)
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
