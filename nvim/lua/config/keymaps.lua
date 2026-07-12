-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Terminal buffers (incl. the Claude terminal) pass Esc straight through to
-- the program running inside — Claude itself uses Esc to interrupt/cancel,
-- so Neovim can't also claim it. Ctrl-q leaves terminal mode instead,
-- without touching Esc.
vim.keymap.set("t", "<C-q>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
