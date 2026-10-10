-- Execute one regression in a fresh configured process and propagate failures.
local function run()
  assert(vim.v.errmsg == '', 'startup error: ' .. vim.v.errmsg)
  local path = assert(vim.env.NVIM_SMOKE_TEST, 'missing NVIM_SMOKE_TEST')
  dofile(path)
  -- Observe queued work before declaring success; callbacks can otherwise be
  -- discarded by qa! even when they raise errors after the test returns.
  local drained = false
  vim.schedule(function() drained = true end)
  assert(vim.wait(1000, function() return drained end, 5), 'scheduled work did not drain')
  assert(#vim.v.errors == 0, table.concat(vim.v.errors, '\n'))
  assert(vim.v.errmsg == '', 'Neovim error: ' .. vim.v.errmsg)
  print('STRICT SMOKE PASS: ' .. path)
end
local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd('cquit 1')
else vim.cmd('qa!') end
