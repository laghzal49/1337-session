-- Commands are cheap; indices and pages stay lazy. Background work starts after startup.
local M = {}
local job, timer
local defaults = { 'python', 'c', 'cpp', 'lua', 'bash', 'cmake' }

function M.update(name, quiet)
  name = name and name ~= '' and name or 'all'
  if name ~= 'all' and not vim.tbl_contains(defaults, name) then
    vim.notify('Unknown docset: ' .. name, vim.log.levels.WARN); return
  end
  if job then if not quiet then vim.notify('Docs update already running') end; return end
  local script = vim.fn.stdpath('config') .. '/scripts/update_docs.py'
  local source = debug.getinfo(1, 'S').source:sub(2)
  if vim.fn.filereadable(script) == 0 then
    script = vim.fn.fnamemodify(source, ':h:h:h') .. '/scripts/update_docs.py'
  end
  local command
  if vim.fn.executable('uv') == 1 then command = { 'uv', 'run', '--script', script }
  elseif vim.fn.executable('python3') == 1 then command = { 'python3', script }
  else vim.notify('Offline docs need Python 3.11+ or uv', vim.log.levels.WARN); return end
  vim.list_extend(command, { name, '--data', require('config.docs_store').root() })
  if vim.g.black_docs_catalog then vim.list_extend(command, { '--catalog', vim.g.black_docs_catalog }) end
  if not quiet then vim.notify('Updating offline docs: ' .. name) end
  local ok, result = pcall(vim.system, command, { text = true }, function(output)
    vim.schedule(function()
      job = nil
      require('config.docs_store').invalidate()
      if output.code ~= 0 then
        local detail = vim.trim((output.stderr or '') .. '\n' .. (output.stdout or ''))
        vim.notify('Offline docs update failed; existing docs preserved.\n' .. detail:sub(-3000), vim.log.levels.WARN)
      elseif not quiet then vim.notify('Offline docs updated') end
    end)
  end)
  if ok then job = result else vim.notify(tostring(result), vim.log.levels.WARN) end
end

function M.browse(arguments)
  local words = vim.split(arguments or '', '%s+', { trimempty = true })
  local docset
  if vim.tbl_contains(defaults, words[1]) then docset = table.remove(words, 1) end
  require('config.deep_docs').search(table.concat(words, ' '), docset)
end

function M.health()
  local store = require('config.docs_store')
  local manifest = store.manifest()
  local lines = { '# BLACK DOCS', '' }
  local bytes, healthy_count = 0, 0
  for _, name in ipairs(defaults) do
    local set = manifest and manifest.docsets[name]
    if set then
      local age = math.max(0, math.floor((os.time() - set.updated_at) / 86400))
      local healthy = store.load_index(name) ~= nil
      if healthy then healthy_count = healthy_count + 1 end
      lines[#lines + 1] = ('- **%s** · %s · updated %dd ago'):format(name, healthy and 'installed' or 'index damaged', age)
      bytes = bytes + set.bytes
    else lines[#lines + 1] = '- **' .. name .. '** · missing' end
  end
  vim.list_extend(lines, { '', ('Active page data: %.1f MiB'):format(bytes / 1048576), '',
    ('Auto update: %s · max age %s days'):format(vim.g.black_docs_auto_update and 'enabled' or 'disabled', vim.g.black_docs_max_age_days),
    '', ('Index: %d/%d default sets healthy'):format(healthy_count, #defaults),
    '', 'Storage: `' .. store.root() .. '`' })
  local docs = require('config.documentation')
  local origin = vim.api.nvim_get_current_win()
  local function display()
    if vim.api.nvim_get_current_win() ~= origin then return end
    docs.close(); docs.open(lines, 'BLACK DOCS')
  end
  if vim.fn.executable('du') == 1 and vim.uv.fs_stat(store.root()) then
    vim.system({ 'du', '-sk', '--', store.root() }, { text = true }, function(result)
      vim.schedule(function()
        local kib = tonumber((result.stdout or ''):match('^(%d+)'))
        if result.code == 0 and kib then lines[#lines + 1] = ('Disk usage: %.1f MiB'):format(kib / 1024) end
        display()
      end)
    end)
  else display() end
end

function M.check()
  if not vim.g.black_docs_auto_update then return end
  local manifest = require('config.docs_store').manifest()
  local max_age = math.max(1, tonumber(vim.g.black_docs_max_age_days) or 7) * 86400
  for _, name in ipairs(defaults) do
    local set = manifest and manifest.docsets[name]
    local index = set and require('config.docs_store').root() .. '/' .. set.root .. '/index.json'
    if not set or not vim.uv.fs_stat(index) or os.time() - set.updated_at > max_age then
      M.update('all', true); return
    end
  end
end

function M.cleanup()
  if timer then timer:stop(); timer:close(); timer = nil end
  if job then job:kill(15); job = nil end
  pcall(vim.api.nvim_del_augroup_by_name, 'BlackDocsLifecycle')
end

function M.setup()
  M.cleanup()
  if vim.g.black_docs_auto_update == nil then vim.g.black_docs_auto_update = vim.env.NVIM_BLACK_DOCS_AUTO_UPDATE ~= '0' end
  if vim.g.black_docs_max_age_days == nil then vim.g.black_docs_max_age_days = 7 end
  for name, callback in pairs({ DocsUpdate = function(args) M.update(args.args) end,
    DocsBrowse = function(args) M.browse(args.args) end, DocsHealth = M.health }) do
    local options = { nargs = name == 'DocsHealth' and 0 or '*', desc = name, force = true }
    if name ~= 'DocsHealth' then options.complete = function() return defaults end end
    vim.api.nvim_create_user_command(name, callback, options)
  end
  vim.api.nvim_create_user_command('Docs', function(args)
    local action, rest = args.args:match('^(%S+)%s*(.*)$')
    if action == 'update' then M.update(rest)
    elseif action == 'health' then M.health()
    elseif action == 'browse' then M.browse(rest)
    else M.browse(args.args) end
  end, { nargs = '*', force = true, desc = 'Offline docs: browse, update or health',
    complete = function() return { 'browse', 'update', 'health', 'python', 'c', 'cpp', 'lua', 'bash', 'cmake' } end })
  -- Existing users saw these names before the custom store replaced the plugin.
  vim.api.nvim_create_user_command('Devdocs', function(args) M.browse(args.args) end,
    { nargs = '*', force = true, desc = 'Browse offline docs (compatibility)' })
  vim.api.nvim_create_user_command('DevdocsUpdate', function(args) M.update(args.args) end,
    { nargs = '?', force = true, desc = 'Update offline docs (compatibility)' })
  local group = vim.api.nvim_create_augroup('BlackDocsLifecycle', { clear = true })
  vim.api.nvim_create_autocmd('VimLeavePre', { group = group, callback = M.cleanup })
  local function later()
    if not vim.g.black_docs_auto_update then return end
    timer = vim.uv.new_timer()
    timer:start(5000, 0, vim.schedule_wrap(function()
      timer:close(); timer = nil
      M.check()
    end))
  end
  if vim.v.vim_did_enter == 1 then later()
  else vim.api.nvim_create_autocmd('VimEnter', { group = group, once = true, callback = later }) end
end

return M
