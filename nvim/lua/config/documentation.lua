local M = {}

-- Decorate the actual completion window after cmp has resolved its contents.
-- Public window APIs keep this independent of cmp's internal view objects.
function M.label()
  vim.defer_fn(function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "cmp_docs" then
        local config = vim.api.nvim_win_get_config(win)
        if config.relative ~= "" and config.width >= 28 then
          vim.api.nvim_win_set_config(win, {
            title = { { "  DOCUMENTATION ", "BlackDocsTitle" } },
            title_pos = "left",
            footer = { { config.width >= 42 and " C-b / C-f scroll · C-d close " or " C-d close ", "BlackDocsHint" } },
            footer_pos = "right",
          })
        end
      end
    end
  end, 60)
end

return M
