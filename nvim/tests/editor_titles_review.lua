-- Full config: nvim --headless '+lua dofile("nvim/tests/editor_titles_review.lua")' +qa!
local ui = require('config.editor_ui')
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp .. '/子目录', 'p')
local file = tmp .. '/子目录/' .. string.rep('文件', 20) .. '%test.lua'
vim.cmd.edit(vim.fn.fnameescape(file))
vim.cmd.vsplit()
local first = vim.api.nvim_get_current_win()
vim.cmd.lcd(vim.fn.fnameescape(tmp))
vim.cmd.wincmd('p')
local second = vim.api.nvim_get_current_win()
vim.cmd.lcd(vim.fn.fnameescape(tmp .. '/子目录'))
vim.api.nvim_win_set_width(first, 20)
vim.bo.modified, vim.bo.readonly = true, true
ui.update()
for _, win in ipairs({first, second}) do
  local rendered = vim.api.nvim_eval_statusline(vim.wo[win].winbar, {winid = win, use_winbar = true}).str
  assert(vim.fn.strdisplaywidth(rendered) <= vim.api.nvim_win_get_width(win), 'title exceeded window width')
  assert(not rendered:find('�', 1, true), 'Unicode title was broken')
  assert(rendered:find('test.lua', 1, true), 'truncation lost filename extension')
  assert(rendered:find('[RO]', 1, true), 'readonly state lost')
end
-- A short filename exposes the window-specific directory difference.
vim.api.nvim_buf_set_name(0, tmp .. '/子目录/ok%file.lua')
vim.api.nvim_win_set_width(first, 50)
ui.update()
local a = vim.api.nvim_eval_statusline(vim.wo[first].winbar, {winid=first, use_winbar=true}).str
local b = vim.api.nvim_eval_statusline(vim.wo[second].winbar, {winid=second, use_winbar=true}).str
assert(a:find('子目录',1,true) and not b:find('子目录',1,true), 'paths must honor each window local cwd')
assert(a:find('ok%file.lua',1,true), 'literal percent lost')
vim.bo.buftype = 'nofile'
ui.update()
assert(vim.wo[first].winbar == '' and vim.wo[second].winbar == '', 'special buffer kept file title')
vim.fn.delete(tmp,'rf')
print('EDITOR TITLES PASS: Unicode, narrow width, local cwd, percent, readonly, special-buffer cleanup')
