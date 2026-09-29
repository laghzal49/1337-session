-- Run with the repository config; all fixtures are temporary.
local make = require("config.makefile")
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
vim.fn.writefile({
  "PYTHON := python3", "OTHER ::= value", ".PHONY: test review", "%.o: %.c",
  "## Shared recipe", "test review: ## Run checks", "\t@echo checked",
  "test:", "\t@echo twice", "inline: ; @echo inline", "$(GENERATED):",
}, dir .. "/GNUmakefile")
local targets = make.parse(dir .. "/GNUmakefile")
assert(#targets == 3 and targets[1].name == "test" and targets[2].name == "review")
assert(targets[1].desc == "Run checks" and #targets[1].recipes == 2)
assert(targets[2].recipes[1] == "@echo checked")
assert(targets[3].recipes[1] == "@echo inline")
vim.fn.writefile({ "wrong:" }, dir .. "/Makefile")
assert(make.find_makefile(dir) == dir .. "/GNUmakefile", "GNU Make precedence")
local old_cwd, terminal = vim.fn.getcwd(), Snacks.terminal
local calls = {}
vim.cmd.cd(dir)
Snacks.terminal = function(cmd) calls[#calls + 1] = cmd end
make.run()
make.run("test; echo injected")
Snacks.terminal = terminal
vim.cmd.cd(old_cwd)
assert(#calls[1] == 5 and calls[1][4] == "-f")
assert(calls[2][6] == "--" and calls[2][7] == "test; echo injected")
vim.fn.delete(dir, "rf")

local plugins = require("lazy.core.config").plugins
local lock = vim.json.decode(table.concat(vim.fn.readfile("nvim/lazy-lock.json"), "\n"))
for name in pairs(plugins) do assert(lock[name], "Unpinned plugin: " .. name) end
for name in pairs(lock) do assert(plugins[name], "Unused lock entry: " .. name) end
for _, name in ipairs({ "nvim-cmp", "cmp-nvim-lsp", "lsp_signature.nvim", "nvim-dap" }) do
  assert(not plugins[name], "Obsolete plugin: " .. name)
end
assert(not pcall(require, "cmp"), "Completion shim still available")
local noice_opts = require("lazy.core.plugin").values(plugins["noice.nvim"], "opts", false)
assert(noice_opts.lsp.signature.enabled == false)
assert(require("blink.cmp.config").signature.enabled)

-- Buffer closing must preserve two splits and their contents.
vim.cmd.enew()
local first = vim.api.nvim_get_current_buf()
vim.cmd.vnew()
local second = vim.api.nvim_get_current_buf()
local count = #vim.api.nvim_list_wins()
Snacks.bufdelete(second)
assert(#vim.api.nvim_list_wins() == count, "Closing a buffer destroyed a split")
assert(vim.api.nvim_buf_is_valid(first) and not vim.bo[second].buflisted and not vim.api.nvim_buf_is_loaded(second))
vim.cmd.only()
print("WORKFLOW: Makefile parsing, safe arguments, lockfile, real completion and split-preserving close PASS")
