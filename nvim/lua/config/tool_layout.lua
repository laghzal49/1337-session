local M = {}
function M.files()
  return { windows = {
    max_number = vim.o.columns < 100 and 1 or 3,
    width_focus = math.max(12, math.min(36, vim.o.columns - 8)),
    width_nofocus = 16, preview = false,
  } }
end
function M.setup()
  local group = vim.api.nvim_create_augroup("ToolLayout", { clear = true })
  vim.api.nvim_create_autocmd("VimResized", { group = group, callback = function()
    local files = package.loaded["mini.files"]
    if files and files.get_explorer_state() then files.refresh(M.files()) end
  end })
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "MiniFilesWindowOpen", callback = function(ev)
    vim.api.nvim_win_set_config(ev.data.win_id, { border = "none" })
    vim.wo[ev.data.win_id].winblend = 0
  end })
end
return M
