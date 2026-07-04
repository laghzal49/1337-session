-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Carbon Reactive (lua/carbon/reactive.lua) owns the yank flash — a pink
-- pulse that eases out. Drop LazyVim's default flat flash so the two don't
-- stack on every yank. (pcall: group name may change across LazyVim versions)
pcall(vim.api.nvim_del_augroup_by_name, "lazyvim_highlight_yank")
