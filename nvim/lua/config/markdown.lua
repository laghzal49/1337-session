local M = {}
local states = {}

local function save(buf)
  states[buf] = {
    win = vim.api.nvim_get_current_win(),
    wrap = vim.wo.wrap,
    linebreak = vim.wo.linebreak,
    number = vim.wo.number,
    relativenumber = vim.wo.relativenumber,
    signcolumn = vim.wo.signcolumn,
    cursorline = vim.wo.cursorline,
    conceallevel = vim.wo.conceallevel,
    spell = vim.wo.spell,
  }
end

local function restore(buf)
  local state = states[buf]
  if not state then return end
  local win = vim.api.nvim_win_is_valid(state.win) and state.win or 0
  for option, value in pairs(state) do
    if option ~= 'win' then vim.wo[win][option] = value end
  end
  states[buf] = nil
end

function M.toggle()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo.filetype ~= 'markdown' then
    vim.notify('Markdown reader mode is only available for Markdown buffers', vim.log.levels.WARN)
    return
  end
  if states[buf] then
    restore(buf)
    pcall(vim.cmd, 'RenderMarkdown disable')
    vim.notify('Markdown reader mode off', vim.log.levels.INFO)
    return
  end
  save(buf)
  vim.wo.wrap = true
  vim.wo.linebreak = true
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  vim.wo.cursorline = false
  vim.wo.conceallevel = 3
  vim.wo.spell = true
  pcall(vim.cmd, 'RenderMarkdown enable')
  vim.notify('Markdown reader mode on · <leader>mr toggles back', vim.log.levels.INFO)
end

return M
