-- Called by ui_review.py with an attached UI. All mutations use temporary files.
local plugins = {
  "mini.files", "tiny-inline-diagnostic.nvim", "quicker.nvim", "mini.pick", "mini.extra",
  "mini.notify", "glance.nvim", "inc-rename.nvim", "aerial.nvim", "treesj",
  "nvim-various-textobjs",
}
require("lazy").load({ plugins = plugins })
local ready = false
vim.schedule(function() ready = true end)
assert(vim.wait(1500, function() return ready end))
for _, name in ipairs(plugins) do assert(require("lazy.core.config").plugins[name]._.loaded, name) end
assert(vim.notify == require("config.notifications").notify)
assert(not Snacks.config.notifier.enabled)
assert(not require("noice.config").options.notify.enabled)
assert(vim.diagnostic.config().virtual_text == false)
assert(not require("lazy.core.config").plugins.LazyVim, "distribution must not be installed")
assert(not Snacks.config.picker.enabled)
for _, name in ipairs({ "neo-tree.nvim", "namu.nvim", "colorful-menu.nvim", "nvim-lsp-endhints" }) do
  assert(not require("lazy.core.config").plugins[name], "removed plugin still active: " .. name)
end

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local path = dir .. "/sample.py"
vim.fn.writefile({ 'values = {"first": 1, "second": 2}', '', 'def total(values):', '    return sum(values)', '', 'answer = total(values)' }, path)
vim.cmd.edit(path)
local buf = vim.api.nvim_get_current_buf()
vim.bo[buf].filetype = "python"
vim.b[buf].autoformat = false
vim.treesitter.start(buf)
vim.api.nvim_win_set_cursor(0, {1, 12})
require("treesj").split()
assert(vim.api.nvim_buf_line_count(buf) > 6, "TreeSJ did not split dictionary")
require("treesj").join()
assert(vim.api.nvim_buf_line_count(buf) == 6, "TreeSJ did not rejoin dictionary")
vim.api.nvim_win_set_cursor(0, {4, 6})
require("various-textobjs").indentation("inner", "inner")
assert(vim.fn.mode():match("[vV]"), "indentation object did not select")
vim.cmd('execute "normal! \\<Esc>"')
vim.fn.writefile({"temporary"}, dir .. "/rename_me.txt")
require("mini.files").open(dir)
assert(require("mini.files").get_explorer_state(), "Mini Files failed to open")
local fbuf = vim.api.nvim_get_current_buf()
vim.api.nvim_exec_autocmds("TextChanged", {buffer=fbuf})
local file_lines = vim.api.nvim_buf_get_lines(fbuf, 0, -1, false)
local renamed = false
for i, line in ipairs(file_lines) do
  if line:find("rename_me.txt", 1, true) then
    vim.api.nvim_buf_set_lines(fbuf, i - 1, i, false, {(line:gsub("rename_me%.txt", "renamed.txt"))})
    renamed = true
    break
  end
end
assert(renamed, "temporary file missing in explorer")
vim.api.nvim_exec_autocmds("TextChanged", {buffer=fbuf})
local confirm = vim.fn.confirm
vim.fn.confirm = function() return 1 end
local ok, err = pcall(require("mini.files").synchronize)
vim.fn.confirm = confirm
assert(ok, err)
assert(vim.fn.filereadable(dir .. "/renamed.txt") == 1, "Mini Files rename failed")
assert(vim.fn.filereadable(dir .. "/rename_me.txt") == 0)
require("mini.files").close()
vim.api.nvim_set_current_buf(buf)

vim.cmd.write()

-- Exercise quickfix editing against a disposable file, not repository content.
vim.fn.setqflist({}, "r", { title = "Plugin smoke", items = { { filename = path, lnum = 6, col = 1, text = 'answer = total(values)' } } })
vim.cmd.copen()
local qbuf = vim.api.nvim_get_current_buf()
assert(vim.wait(1500, function() return vim.b[qbuf].qf_ext_id_to_item_idx ~= nil end), "quickfix rendering not ready")
assert(vim.bo[qbuf].filetype == "qf" and vim.bo[qbuf].modifiable)
local lines = vim.api.nvim_buf_get_lines(qbuf, 0, -1, false)
local changed = false
for i, line in ipairs(lines) do
  if line:find("answer =", 1, true) then
    local col = line:find("answer =", 1, true) - 1
    vim.api.nvim_buf_set_text(qbuf, i - 1, col, i - 1, col + 6, { "result" })
    changed = true
  end
end
assert(changed, "quickfix result missing")
vim.cmd.write()
assert(vim.wait(1000, function() return vim.fn.readfile(path)[6] == "result = total(values)" end), "quickfix edit not saved")
vim.cmd.cclose()
vim.api.nvim_set_current_buf(buf)

-- Deterministic LSP transport exercises adapters without requiring installed ty.
local range = { start = { line = 2, character = 4 }, ["end"] = { line = 2, character = 9 } }
local uri = vim.uri_from_fname(path)
local closed, serial = false, 0
local client_id = vim.lsp.start({
  name = "plugin-review", root_dir = dir,
  cmd = function(dispatchers)
    return {
      request = function(method, params, callback)
        serial = serial + 1
        local value
        if method == "initialize" then
          value = { capabilities = { textDocumentSync = 1, definitionProvider = true, referencesProvider = true,
            documentSymbolProvider = true, workspaceSymbolProvider = true, renameProvider = true, inlayHintProvider = true } }
        elseif method == "textDocument/documentSymbol" then
          value = {{ name = "total", kind = 12, range = { start = { line = 2, character = 0 }, ["end"] = { line = 3, character = 22 } }, selectionRange = range }}
        elseif method == "workspace/symbol" then
          value = {{ name = "total", kind = 12, location = { uri = uri, range = range } }}
        elseif method == "textDocument/definition" or method == "textDocument/references" then
          value = {{ uri = uri, range = range }}
        elseif method == "textDocument/rename" then
          value = { changes = { [uri] = {{ range = range, newText = params.newName }} } }
        elseif method == "textDocument/inlayHint" then
          value = {{ position = { line = 5, character = 6 }, label = ": int", kind = 1 }}
        end
        vim.schedule(function() callback(nil, value) end)
        return true, serial
      end,
      notify = function(method)
        if method == "exit" then closed = true; dispatchers.on_exit(0, 0) end
        return true
      end,
      is_closing = function() return closed end,
      terminate = function() closed = true; dispatchers.on_exit(0, 0) end,
    }
  end,
}, { bufnr = buf })
assert(vim.wait(1500, function() local c = vim.lsp.get_client_by_id(client_id); return c and c.initialized end))
vim.api.nvim_win_set_cursor(0, {3, 5})
local diagnostics = vim.api.nvim_create_namespace("plugin_review_diagnostics")
vim.diagnostic.set(diagnostics, buf, {{ lnum = 2, col = 4, severity = 1, source = "review",
  message = "A deliberately long Python type error that should wrap rather than being cut off before the important details.\nExpected int, received str." }})
assert(vim.wait(1500, function()
  return #vim.api.nvim_buf_get_extmarks(buf, vim.api.nvim_create_namespace("TinyInlineDiagnostic"), 0, -1, {}) > 0
end), "inline diagnostics did not render")
vim.diagnostic.reset(diagnostics, buf)
vim.lsp.inlay_hint.enable(true, { bufnr = buf })
assert(vim.lsp.inlay_hint.is_enabled({bufnr=buf}), "native hints toggle failed")
vim.lsp.inlay_hint.enable(false, {bufnr=buf})

_G.plugin_review = { buf = buf, dir = dir, client = client_id }
return { plugins = #plugins, file = path }
