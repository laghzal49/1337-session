-- Native window titles: cached paths, no parser calls or filesystem work on draw.
local M = {}
local function escape(value) return value:gsub('%%', '%%%%') end
function M.update()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local markdown = package.loaded['config.markdown']
    local reading = markdown and markdown.reader_active and markdown.reader_active(win)
    if vim.api.nvim_win_get_config(win).relative == '' and vim.bo[buf].buftype == '' and not reading then
      local file = vim.api.nvim_buf_get_name(buf)
      if file == '' then vim.wo[win].winbar = '' else
        local relative = vim.fn.fnamemodify(file, ':~:.')
        local folder, name = relative:match('^(.*)/([^/]+)$')
        name = name or relative
        local width = vim.api.nvim_win_get_width(win)
        if folder and #folder > math.max(10, width - #name - 10) then folder = '…/' .. vim.fs.basename(folder) end
        vim.wo[win].winbar = '%#BlackPath#  ' .. (folder and escape(folder) .. '  ›  ' or '')
          .. '%#BlackFileTitle#' .. escape(name) .. (vim.bo[buf].modified and ' %#BlackModified#●' or '')
          .. (vim.bo[buf].readonly and ' [RO]' or '') .. '%*'
      end
    end
  end
end
function M.setup()
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufFilePost', 'BufModifiedSet', 'DirChanged', 'WinResized' }, {
    group = vim.api.nvim_create_augroup('BlackEditorTitles', { clear = true }), callback = M.update,
  })
  M.update()
end
return M
