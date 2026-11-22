-- nvimz-style rounded left Oil file explorer.
-- Visual behavior adapted from nvimz (MIT © 2026 @andev0x).
local M = {}
local ignored = {
  ['node_modules']=true, ['.git']=true, ['.cache']=true,
  ['dist']=true, ['build']=true, ['.next']=true, ['.astro']=true,
}
local function setup_highlights()
  vim.api.nvim_set_hl(0, 'OilGitIgnored', { link = 'Comment' })

end
function M.setup()
  require('oil').setup({
    default_file_explorer = true,
    columns = { 'icon' },
    win_options = { signcolumn = 'yes:2' },
    view_options = {
      show_hidden = true,
      highlight_filename = function(entry)
        if ignored[entry.name] or (entry.name:sub(1,1) == '.' and entry.name ~= '..') then
          return 'OilGitIgnored'
        end
      end,
    },
    float = {
      padding = 0,
      border = 'rounded',
      override = function(conf)
        conf.anchor = 'NW'
        conf.col, conf.row = 0, 1
        -- Float sizes must stay within the editor after a terminal resize.
        -- An oversized Oil window would otherwise trigger E5555.
        conf.width = math.max(1, math.min(vim.o.columns - 2,
          math.max(15, math.floor(vim.o.columns * 0.30))))
        conf.height = math.max(1, math.min(vim.o.lines - 3,
          math.max(5, math.floor(vim.o.lines * 0.85))))
        return conf
      end,
    },
  })
  setup_highlights()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('NvimzOilHighlights', { clear = true }),
    callback = setup_highlights,
  })
end
function M.open(directory)
  require('lazy').load({ plugins = { 'oil.nvim' } })
  require('oil').open_float(directory)
end
function M.toggle()
  require('lazy').load({ plugins = { 'oil.nvim' } })
  if vim.bo.filetype == 'oil' then
    require('oil').close()
  else
    require('oil').open_float()
  end
end
return M
