-- One async Git probe per project, shared by the dashboard and statusline.
local M, cache = {}, {}
function M.get(root)
  root = root or require('config.project').root()
  local entry = cache[root]
  if not entry then entry = { root = root, name = vim.fs.basename(root), branch = '', dirty = false }; cache[root] = entry end
  return entry
end
function M.refresh(root, force)
  local entry = M.get(root)
  local now = vim.uv.now()
  if entry.pending then
    -- A write during a probe needs a second snapshot after that probe finishes.
    entry.refresh_again = entry.refresh_again or force
    return
  end
  if not force and entry.checked and now - entry.checked < 5000 then return end
  entry.checked = now
  if vim.fn.executable('git') == 0 then return end
  entry.pending = true
  local ok = pcall(vim.system, { 'git', '-C', entry.root, 'status', '--porcelain=v1', '--branch', '--untracked-files=no' },
    { text = true, timeout = 1500 }, vim.schedule_wrap(function(result)
      entry.pending = false
      if result.code == 0 then
        local header = (result.stdout or ''):match('^## ([^\n]+)') or ''
        entry.branch = header:match('^(.-)%.%.%.') or header
        entry.dirty = (result.stdout or ''):find('\n[^\n]') ~= nil
      else entry.branch, entry.dirty = '', false end
      vim.cmd.redrawstatus()
      local snacks = rawget(_G, 'Snacks')
      if snacks and snacks.dashboard then
        snacks.dashboard.update()
      end
      if entry.refresh_again then
        entry.refresh_again = nil
        M.refresh(entry.root, true)
      end
    end))
  if not ok then
    entry.pending, entry.refresh_again = false, nil
    entry.branch, entry.dirty = '', false
  end
end
function M.setup()
  vim.api.nvim_create_autocmd({ 'BufEnter', 'DirChanged', 'FocusGained', 'BufWritePost' }, {
    group = vim.api.nvim_create_augroup('BlackWorkspaceInfo', { clear = true }),
    callback = function(ev)
      if vim.bo.buftype == '' or vim.bo.filetype == 'snacks_dashboard' then
        M.refresh(nil, ev.event == 'BufWritePost' or ev.event == 'FocusGained')
      end
    end,
  })
  vim.schedule(function() M.refresh() end)
end
return M
