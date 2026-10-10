-- Full integration: nvim --headless '+lua dofile("nvim/tests/performance_review.lua")' '+qa!'
vim.opt.rtp:prepend(vim.fn.getcwd() .. '/nvim')
local performance = require('config.performance')
performance.setup()
local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(buf)
vim.bo[buf].filetype = 'lua'
assert(not performance.large(), 'normal buffer classified as large')
assert(not performance.large(0), 'current-buffer sentinel failed')
vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/mini.hipatterns')
local hipatterns = require('mini.hipatterns')
hipatterns.setup({ highlighters = { todo = { pattern = 'TODO', group = 'Todo' } } })
hipatterns.enable(buf)
vim.wait(20, function() return false end)
assert(vim.tbl_contains(hipatterns.get_enabled_buffers(), buf), 'decoration fixture did not attach')
-- A local RPC fixture verifies real client attachment/detachment without tools.
local function local_rpc(dispatchers)
    local rpc_closed, request_id = false, 0
    return {
      request = function(method, _, callback)
        request_id = request_id + 1
        vim.schedule(function()
          callback(nil, method == 'initialize' and { capabilities = { textDocumentSync = 1 } } or nil)
        end)
        return true, request_id
      end,
      notify = function() return true end,
      is_closing = function() return rpc_closed end,
      terminate = function() rpc_closed = true; dispatchers.on_exit(0, 0) end,
    }
end
local client_id = vim.lsp.start({
  name = 'performance-guard-review',
  cmd = local_rpc,
}, { bufnr = buf })
assert(client_id, 'LSP fixture did not start')
assert(vim.wait(5000, function()
  local client = vim.lsp.get_client_by_id(client_id)
  return client and client.initialized
end), 'LSP fixture did not initialize')
assert(vim.lsp.buf_is_attached(buf, client_id), 'normal buffer rejected LSP fixture')
vim.wo.foldmethod = 'expr'
vim.wo.spell = true
vim.wo.cursorcolumn = true
local had_treesitter = vim.treesitter.highlighter.active[buf] ~= nil
local disabled_namespace = vim.api.nvim_create_namespace('performance-disabled-diagnostics')
vim.diagnostic.get_namespace(disabled_namespace)
vim.diagnostic.enable(false, { bufnr = buf, ns_id = disabled_namespace })
local context_refreshed = false
local previous_context = package.loaded['treesitter-context']
local previous_enable
if previous_context then
  if not previous_context.enabled() then previous_context.enable() end
  previous_enable = previous_context.enable
  previous_context.enable = function()
    context_refreshed = true
    previous_enable()
  end
else
  package.loaded['treesitter-context'] = {
    enabled = function() return true end,
    enable = function() context_refreshed = true end,
  }
end
local lines = {}
for i = 1, 20001 do lines[i] = 'x' end
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
assert(performance.large(buf), 'line budget missed small-byte generated file')
local started = vim.uv.hrtime()
for _ = 1, 10000 do assert(performance.large(buf)) end
local check_ms = (vim.uv.hrtime() - started) / 1e6
performance.guard(buf)
-- Real installed parsers may already have queued work during fixture growth.
-- This is a completion assertion, not a latency benchmark.
assert(vim.wait(5000, function() return context_refreshed end), 'context attachment was not reevaluated')
if previous_context then previous_context.enable = previous_enable end
package.loaded['treesitter-context'] = previous_context
assert(vim.b[buf].bigfile and vim.b[buf].performance_guard, 'growth guard did not classify buffer')
assert(vim.b[buf].minihipatterns_disable, 'pattern decorations were not permanently disabled')
assert(not vim.tbl_contains(hipatterns.get_enabled_buffers(), buf), 'existing pattern attachment survived growth')
assert(vim.b[buf].snacks_indent == false and vim.b[buf].snacks_scope == false, 'indent/scope decorations remain enabled')
assert(vim.wo.foldmethod == 'manual', 'growth guard did not suppress expensive folds')
assert(not vim.diagnostic.is_enabled({ bufnr = buf }), 'growth guard did not suppress diagnostics')
assert(not vim.lsp.buf_is_attached(buf, client_id), 'existing LSP attachment survived growth')
vim.lsp.buf_attach_client(buf, client_id)
assert(vim.wait(5000, function() return not vim.lsp.buf_is_attached(buf, client_id) end),
  'new LSP attachment bypassed large-buffer guard')
local restored, refusal = performance.restore(buf)
assert(not restored and refusal:find('still exceeds'), 'restore allowed an oversized buffer')
local small = vim.api.nvim_create_buf(true, false)
vim.cmd.vsplit()
local split = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(split, small)
vim.wo[split].foldmethod = 'expr'
vim.wo[split].spell = true
vim.wo[split].cursorcolumn = true
vim.api.nvim_win_set_buf(split, buf)
assert(vim.wo[split].foldmethod == 'manual' and not vim.wo[split].spell
  and not vim.wo[split].cursorcolumn, 'guard was not applied to a newly displayed split')
vim.api.nvim_win_close(split, true)
vim.api.nvim_set_current_buf(small)
assert(vim.wo.foldmethod == 'expr' and vim.wo.spell and vim.wo.cursorcolumn,
  'guard window options leaked into a normal buffer')
vim.api.nvim_set_current_buf(buf)
-- Restore before a pending LspAttach rejection must cancel that rejection.
vim.lsp.buf_attach_client(buf, client_id)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'local unsaved = "keep me"' })
local before_restore = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
local was_modified = vim.bo[buf].modified
assert(performance.restore(buf), 'small-buffer restoration failed')
assert(vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), before_restore)
  and vim.bo[buf].modified == was_modified, 'restore changed unsaved edits')
assert(not vim.b[buf].bigfile and not vim.b[buf].performance_guard, 'guard markers survived restoration')
assert(vim.b[buf].minihipatterns_disable == nil and vim.b[buf].snacks_indent == nil
  and vim.b[buf].snacks_scope == nil, 'unset feature preferences were not restored')
assert(vim.wo.foldmethod == 'expr' and vim.wo.spell and vim.wo.cursorcolumn, 'window preferences were not restored')
assert(vim.diagnostic.is_enabled({ bufnr = buf }), 'diagnostics were not restored')
assert(not vim.diagnostic.is_enabled({ bufnr = buf, ns_id = disabled_namespace }),
  'restore overrode a disabled diagnostic namespace')
assert(vim.lsp.buf_is_attached(buf, client_id), 'previous LSP client did not reattach')
vim.wait(20, function() return false end)
assert(vim.lsp.buf_is_attached(buf, client_id), 'pending guard detached a restored LSP client')
assert(vim.tbl_contains(hipatterns.get_enabled_buffers(), buf), 'pattern decorations did not reattach')
if had_treesitter then assert(vim.treesitter.highlighter.active[buf], 'parser highlighting did not restart') end
assert(not performance.restore(buf), 'unguarded buffer was restored twice')
local client = vim.lsp.get_client_by_id(client_id)
if client then client:stop(true) end
-- Preserve deliberately disabled user preferences, even after large-file mode.
local disabled = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(disabled)
vim.diagnostic.enable(false, { bufnr = disabled })
vim.b[disabled].minihipatterns_disable = true
vim.b[disabled].snacks_indent = false
vim.b[disabled].snacks_scope = false
vim.api.nvim_buf_set_lines(disabled, 0, -1, false, lines)
performance.guard(disabled)
vim.api.nvim_buf_set_lines(disabled, 0, -1, false, { 'small' })
assert(performance.restore(disabled))
assert(not vim.diagnostic.is_enabled({ bufnr = disabled }), 'restore overrode disabled diagnostics')
assert(vim.b[disabled].minihipatterns_disable and vim.b[disabled].snacks_indent == false
  and vim.b[disabled].snacks_scope == false, 'restore overrode disabled decorations')
if package.loaded['lazy'] then
  local disk_path = vim.fn.tempname() .. '.lua'
  vim.fn.writefile({ string.rep('x', performance.max_bytes + 1) }, disk_path)
  vim.cmd.edit(vim.fn.fnameescape(disk_path))
  local disk_buf = vim.api.nvim_get_current_buf()
  assert(vim.bo.filetype == 'bigfile' and vim.b.performance_guard, 'disk bigfile fixture was not protected')
  vim.api.nvim_buf_set_lines(disk_buf, 0, -1, false, { string.rep('x', 2000) })
  assert(not performance.restore(disk_buf), 'minified disk buffer was restored unsafely')
  vim.api.nvim_buf_set_lines(disk_buf, 0, -1, false, { 'local unsaved = 42' })
  assert(performance.restore(disk_buf), 'disk-classified buffer did not restore')
  assert(vim.bo.filetype == 'lua' and not vim.b.bigfile, 'real disk filetype was not restored')
  assert(vim.bo.modified and vim.api.nvim_buf_get_lines(disk_buf, 0, -1, false)[1] == 'local unsaved = 42',
    'disk restoration lost edits')
  assert(vim.treesitter.highlighter.active[disk_buf], 'disk restoration did not restart parser highlighting')
  vim.fn.delete(disk_path)
  local line_path = vim.fn.tempname() .. '.lua'
  local server_name = 'performance-restore-filetype-review'
  vim.lsp.config(server_name, {
    cmd = local_rpc, filetypes = { 'lua' },
    root_dir = function(_, on_dir) on_dir(vim.fn.getcwd()) end,
  })
  vim.lsp.enable(server_name)
  vim.fn.writefile(lines, line_path)
  vim.cmd.edit(vim.fn.fnameescape(line_path))
  local line_buf = vim.api.nvim_get_current_buf()
  assert(vim.wait(5000, function()
    return vim.b[line_buf].performance_guard and not vim.treesitter.highlighter.active[line_buf]
  end), 'native Lua ftplugin restarted parsing in a guarded file')
  vim.api.nvim_buf_set_lines(line_buf, 0, -1, false, { 'local unsaved = 43' })
  assert(performance.restore(line_buf), 'line-budget disk buffer did not restore')
  assert(vim.treesitter.highlighter.active[line_buf], 'line-budget disk restoration missed native parser state')
  assert(vim.wait(5000, function()
    return #vim.lsp.get_clients({ bufnr = line_buf, name = server_name }) > 0
  end), 'line-budget disk restoration missed enabled FileType LSP attachment')
  vim.lsp.enable(server_name, false)
  vim.fn.delete(line_path)
end
local bytes = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_lines(bytes, 0, -1, false, { string.rep('x', performance.max_bytes + 1) })
assert(performance.large(bytes), 'byte budget missed single-line generated file')
vim.api.nvim_set_current_buf(bytes)
vim.wo.foldmethod = 'expr'
vim.wo.spell = true
performance.guard(0)
assert(vim.wo.foldmethod == 'manual' and not vim.wo.spell, 'guard current-buffer sentinel skipped window options')
local normal = vim.api.nvim_create_buf(true, false)
assert(not performance.large(normal), 'large-file state leaked to normal buffer')
vim.bo[normal].buftype = 'nofile'
vim.api.nvim_buf_set_lines(normal, 0, -1, false, lines)
assert(not performance.large(normal), 'special buffer was guarded')
assert(not performance.restore(normal), 'special buffer allowed restoration')
print(vim.json.encode({ checks = 'passed', size_checks = 10000, size_check_total_ms = check_ms }))
