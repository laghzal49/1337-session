-- Full config: nvim --headless '+lua dofile("nvim/tests/dashboard_review.lua")' +qa!
local dashboard = require('config.dashboard')
local workspace = require('config.workspace_info')
local get = workspace.get
workspace.get = function() return {name=string.rep('项目',40),root='/tmp/project',branch=string.rep('feature/',30),dirty=true} end
for _, size in ipairs({{40,20},{80,24},{100,30},{140,42}}) do
  vim.o.columns, vim.o.lines = size[1], size[2]
  Snacks.dashboard.open()
  vim.wait(50)
  assert(vim.bo.filetype == 'snacks_dashboard', 'dashboard did not open')
  local lines = vim.api.nvim_buf_get_lines(0,0,-1,false)
  for _, line in ipairs(lines) do
    assert(vim.fn.strdisplaywidth(line) <= size[1], 'dashboard line overflow at width '..size[1])
  end
  assert(table.concat(lines, '\n'):find('tracked changes',1,true), 'long branch hid tracked-change state')
  if size[2] == 20 then assert(#lines <= 20, 'small dashboard needs unnecessary scrolling') end
  vim.cmd.enew()
end
workspace.get = function() return {name='project',root='/tmp/project',branch=string.rep('feature/',30),dirty=false} end
local sections = dashboard.sections({_size={width=40,height=20},opts={}})
assert(sections[4].text:find('tracked clean',1,true),'long branch hid clean state')
assert(vim.fn.strdisplaywidth(sections[4].text) <= 36,'clean status line exceeded dashboard width')
local called = false
local tasks = require('config.tasks')
local pick = tasks.pick
tasks.pick = function() called=true end
for _, section in ipairs(dashboard.sections()) do if section.key == 'b' then section.action() end end
assert(called,'dashboard build action must discover all supported project tasks')
tasks.pick, workspace.get = pick, get
print('DASHBOARD PASS: 40/80/100/140-column bounds, long Unicode workspace/branch, compact height, project tasks')
