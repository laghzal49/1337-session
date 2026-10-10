-- Keep a usable editor beside debugger panels at every terminal size.
local M = { active = false, owned = {} }
local function profile()
  if vim.o.columns < 80 or vim.o.lines < 24 then return {3} end
  return vim.o.columns >= 120 and vim.o.lines >= 32 and {1,2} or {1}
end
local function owned_intact()
  local visible = false
  for win, buf in pairs(M.owned) do
    if vim.api.nvim_win_is_valid(win) then
      if vim.api.nvim_win_get_buf(win) ~= buf then return false end
      visible = true
    end
  end
  return visible
end
function M.open()
  local ui = require('dapui')
  local current = vim.api.nvim_get_current_win()
  if M.active and M.tab ~= vim.api.nvim_get_current_tabpage() then M.close() end
  M.tab = vim.api.nvim_get_current_tabpage()
  ui.close()
  for _, layout in ipairs(profile()) do ui.open({layout=layout,reset=true}) end
  M.owned = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(M.tab)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    if ft:match('^dapui_') or ft == 'dap-repl' then M.owned[win] = buf end
  end
  M.active = true
  if vim.api.nvim_win_is_valid(current) then vim.api.nvim_set_current_win(current) end
end
function M.close()
  if owned_intact() then
    for win in pairs(M.owned) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_call(win, function() require('dapui').close() end)
        break
      end
    end
  end
  M.active, M.owned = false, {}
end
function M.toggle()
  if M.active and M.tab == vim.api.nvim_get_current_tabpage() and owned_intact() then M.close() else M.open() end
end
function M.inspect(element)
  require('dapui').float_element(element, {
    enter=true, width=math.max(1,math.min(76,vim.o.columns-6)),
    height=math.max(1,math.min(18,vim.o.lines-6)),
  })
end
function M.setup()
  local group = vim.api.nvim_create_augroup('BlackDebugPanels', {clear=true})
  vim.api.nvim_create_autocmd('VimResized', {group=group, callback=function()
    if not M.active or M.tab ~= vim.api.nvim_get_current_tabpage() then return end
    -- A panel repurposed by the user is no longer ours to rearrange.
    if not owned_intact() then M.active=false; return end
    M.open()
  end})
end
return M
