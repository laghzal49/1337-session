-- Full config: nvim --headless '+lua dofile("nvim/tests/statusline_safety_review.lua")' +qa!
local workspace = require('config.workspace_info')
local get, lsp_status, tasks = workspace.get, vim.lsp.status, package.loaded['config.tasks']
local label = [[label%{luaeval('(function() vim.g.statusline_injected=true; return 42 end)()')}]]
workspace.get = function() return {name=label,branch=label,dirty=true} end
package.loaded['config.tasks'] = {running={task={name=label}}}
vim.lsp.status = function() return label end
vim.o.columns = 140
local opts = require('plugins.statusline')[1].opts()
for index, component in ipairs({opts.sections.lualine_b[1],opts.sections.lualine_b[2],opts.sections.lualine_x[2],opts.sections.lualine_x[6]}) do
  local raw = component[1]()
  local rendered = vim.api.nvim_eval_statusline(raw, {}).str
  assert(rendered:find(label:sub(1,16),1,true), 'dynamic statusline text interpreted markup')
  assert(vim.g.statusline_injected == nil, 'statusline label executed an expression')
end
-- Exercise the actual lualine component pipeline as well as individual callbacks.
require('lualine').setup(opts)
local line = require('lualine').statusline(true)
local rendered = vim.api.nvim_eval_statusline(line, {maxwidth=1000}).str
assert(rendered:find(label:sub(1,16),1,true),'lualine did not retain literal percent expressions')
assert(vim.g.statusline_injected == nil,'lualine executed an expression from a project label')
workspace.get = function() return {name='a-very-long-project-name',branch='main',dirty=false} end
vim.o.columns = 80
assert(opts.sections.lualine_b[1].cond() and not opts.sections.lualine_b[2].cond(),
  'narrow statusline must keep the project without the branch')
assert(vim.fn.strdisplaywidth(opts.sections.lualine_b[1][1]()) <= 14,
  'project label consumed the narrow statusline')
for _,width in ipairs({100,140}) do
  vim.o.columns=width
  vim.lsp.status=function() return string.rep('indexing-project ',20) end
  local component=opts.sections.lualine_x[6]
  assert(component.cond() and vim.fn.strdisplaywidth(vim.api.nvim_eval_statusline(component[1](),{}).str)<=(width==140 and 36 or 20), 'LSP progress overflows its budget')
  vim.lsp.status=function() return '%{1+1}' end
  assert(vim.api.nvim_eval_statusline(component[1](),{}).str=='%{1+1}', 'short progress interpreted statusline code')
end
workspace.get, vim.lsp.status, package.loaded['config.tasks'] = get, lsp_status, tasks
print('STATUSLINE SAFETY PASS: project, branch, task and LSP text cannot inject statusline expressions')
