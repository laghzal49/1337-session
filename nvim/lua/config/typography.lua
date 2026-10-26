-- Regular font weight throughout the editor, including plugin defaults.
local M = {}
local pending = false
function M.apply()
  -- Preserve the source theme's keyword and heading weights.
  if vim.g.colors_name == 'electrovoid' then return end
  for name, hl in pairs(vim.api.nvim_get_hl(0, {link=true})) do
    -- Keep links intact: changing their target also updates every linked group.
    if not hl.link and (hl.bold or (hl.cterm and hl.cterm.bold)) then
      hl.bold = false
      if hl.cterm then hl.cterm.bold = false end
      vim.api.nvim_set_hl(0, name, hl)
    end
  end
end
local function refresh()
  if pending then return end
  pending = true
  vim.schedule(function() pending = false; M.apply() end)
end
function M.setup()
  local group = vim.api.nvim_create_augroup('BlackRegularTypography', {clear=true})
  vim.api.nvim_create_autocmd('ColorScheme', {group=group, callback=refresh})
  vim.api.nvim_create_autocmd('User', {
    group=group, pattern={'LazyLoad','VeryLazy','BlackUIPresetChanged'}, callback=refresh,
  })
  M.apply()
end
return M
