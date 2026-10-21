-- One tool inventory for :ConfigTools, health reports and action failures.
local M = {}
M.tools = {
  { 'git', 'plugin installation and Git operations', 'Install Git and put it on PATH' },
  { 'rg', 'project text search', 'Install ripgrep and put rg on PATH' },
  { 'uv', 'Python environment creation', 'Install uv and put it on PATH' },
  { 'ty', 'Python type checking and navigation', 'Run uv tool install ty, or install ty through :Mason' },
  { 'ruff', 'Python linting and formatting', 'Run uv tool install ruff, or install ruff through :Mason' },
  { 'clangd', 'C/C++ completion and navigation', 'Run :MasonInstall clangd' },
  { 'tree-sitter', 'building syntax parsers', 'Install the tree-sitter CLI and put it on PATH' },
  { 'cc', 'building native parsers on Unix', 'Install a C compiler; Windows builds may use clang or cl instead' },
  { 'lazygit', 'the optional Git UI', 'Install lazygit and put it on PATH' },
}
function M.missing(tool)
  return tool[1] .. ' missing: ' .. tool[2] .. '. ' .. tool[3]
end
function M.require_tool(name)
  if vim.fn.executable(name) == 1 then return true end
  for _, tool in ipairs(M.tools) do
    if tool[1] == name then
      vim.notify(M.missing(tool), vim.log.levels.WARN, { title = 'Config tools' })
      return false
    end
  end
  return false
end
function M.show()
  local lines = { 'Tools (only required for the workflows listed):' }
  for _, tool in ipairs(M.tools) do
    local path = vim.fn.exepath(tool[1])
    lines[#lines + 1] = path ~= '' and (tool[1] .. ': ' .. path) or M.missing(tool)
  end
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'Config tools' })
end
return M
