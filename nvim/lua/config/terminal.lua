local M = {}

function M.toggle()
  local ok, err = pcall(function()
    local terminal = vim.b[0].snacks_terminal
    local root = type(terminal) == 'table' and terminal.cwd or require('config.project').root()
    local cwd = root and vim.fn.isdirectory(root) == 1 and root or vim.fn.getcwd()
    Snacks.terminal.focus(nil, { cwd = cwd })
  end)
  if not ok then
    vim.notify('Terminal could not open: ' .. tostring(err), vim.log.levels.ERROR)
  end
  return ok
end

return M
