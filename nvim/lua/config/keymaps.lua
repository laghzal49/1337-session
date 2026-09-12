-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>cN", function()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return vim.notify("Save the file before running Norminette")
  end
  vim.cmd.update()
  Snacks.terminal({ vim.fn.expand("~/.local/bin/norminette"), file }, { auto_close = false })
end, { desc = "Norminette current file" })

-- Open the working layout, retaining focus in the source file.
vim.keymap.set("n", "<leader>uW", function()
  require("neo-tree.command").execute({
    action = "show",
    source = "filesystem",
    position = "left",
    dir = LazyVim.root(),
  })
  if vim.o.columns >= 150 then
    vim.cmd("AerialOpen!")
  end
end, { desc = "Open coding workspace" })
vim.keymap.set("n", "<leader>uz", function()
  Snacks.zen()
end, { desc = "Focus on code (Zen)" })
