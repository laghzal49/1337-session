-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Preserve hand-formatted 42 C files; use the project's Norminette rules.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "make" },
  callback = function()
    vim.bo.expandtab = false
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.softtabstop = 4
    if vim.bo.filetype == "c" then
      vim.b.autoformat = false
      vim.opt_local.colorcolumn = "81"
    end
  end,
})

-- Show the project tree beside the first source file in a graphical terminal.
local layout_opened = false
local function open_project_layout()
  if
    layout_opened
    or #vim.api.nvim_list_uis() == 0
    or vim.o.columns < 100
    or vim.bo.buftype ~= ""
    or vim.api.nvim_buf_get_name(0) == ""
  then
    return
  end
  layout_opened = true
  local win = vim.api.nvim_get_current_win()
  require("neo-tree.command").execute({
    action = "show",
    source = "filesystem",
    position = "left",
    dir = LazyVim.root(),
  })
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
end
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("student_project_layout", { clear = true }),
  callback = function()
    vim.defer_fn(open_project_layout, 150)
  end,
})
vim.defer_fn(open_project_layout, 150)
