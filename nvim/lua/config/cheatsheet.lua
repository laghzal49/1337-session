-- Read-only keyboard reference, independent of Markdown editing plugins.
local M = {}
local ui = require('config.ui')
local sections = {}

local function setup_highlights()
  local s = require('config.surfaces')
  local groups = {
    CheatsheetNormal = { fg = s.text, bg = s.panel },
    CheatsheetBorder = { fg = s.edge_bright, bg = s.panel },
    CheatsheetTitle = { fg = s.text, bg = s.panel, bold = false },
    CheatsheetHeader = { fg = s.teal, bold = false },
    CheatsheetKey = { fg = s.lilac, bold = false },
    CheatsheetMuted = { fg = s.muted },
  }
  for name, value in pairs(groups) do vim.api.nvim_set_hl(0, name, value) end
end

local content_lines = {
  "## Debugger (Python / C / C++)",
  "  `<leader>D?` / `:DebugHelp` Tutorial │ `:DebugExample` Practice project",
  "  `<leader>DD` Actions │ `<leader>DR` Restart │ `<leader>DC` Run to cursor │ `<leader>Dw` Add watch",
  "  `<F5>` Continue/start │ `<F10>` Over │ `<F11>` Into │ `<F12>` Out",
  "  `<leader>Db` Breakpoint │ `<leader>DB` Conditional breakpoint",
  "  `<leader>Du` Panels │ `<leader>De` Evaluate │ `<leader>Dt` Stop",
  "  `<leader>Dv` Watch expressions │ `<leader>DS` Call stack │ `<leader>Dr` Console",
  "  `<leader>DL` Logpoint │ `<leader>Dp` Pause │ `<leader>Dl` Last session │ `<leader>Dx` Clear",
  "  `<leader>Df` Choose target │ `<leader>Dg` Generate │ `<leader>Dj` Edit │ `<leader>Dh` Check",
  "  Setup: debugpy for Python; GDB 14+ for C/C++. See :ConfigGuide.",
  "",
  "## Project Tasks & Workspace",
  "  `<leader>rt` Project tasks │ `<leader>rr` Repeat │ `<leader>rs` Stop │ `<leader>ro` Live output",
  "  Live logs update in batches without taking focus; scroll up to pause following",
  "  Auto-detects Make targets, package scripts, Cargo, Go and Python tests/lint",
  "  Failed builds open quickfix or raw output; `<leader>xn` / `<leader>xp` navigate errors",
  "  `<leader>uw` Adaptive workspace │ `<leader>uW` Exit while preserving editing windows",
  "  `<leader>uy` Copy relative file path │ Visual `<A-j>` / `<A-k>` Move selected lines",
  "",
  "## Everyday Controls",
  "  `<leader>ud` Buffer diagnostics │ `<leader>uv` Line wrap",
  "  `<leader>ul` Line numbers       │ `<leader>ur` Relative numbers",
  "  `<leader>ua` Accessible UI │ `<leader>uB` Restore features after shrinking a large buffer",
  "  `<leader>bo` Close other buffers (prompts for unsaved changes)",
  "  `j` / `k` Move by displayed lines; add a count for logical lines",
  "",
  "## File Explorer (`Snacks.explorer`)",
  "  `<leader>e`   Toggle file tree             │ `<leader>fe`  Focus file tree",
  "  Inside: `<CR>` open · `a` create · `d` trash · `r` rename · `c` copy · `m` move · `.` hidden · `q` close",
  "",
  "## Makefile & Completion",
  "  `<leader>cm` Pick Make target  │ `<leader>cM` Run default target  │ `:Make test` Run a target",
  "  `<C-n>` / `<C-p>` Next / previous completion (opens Blink when hidden)",
  "  `<C-space>` Completion  │ `<C-d>` Toggle docs  │ `<C-b>` / `<C-f>` Open / scroll docs",
  "  `<C-e>` Dismiss completion  │ `<C-k>` Signature & parameters",
  "",
  "## Floating Terminal",
  "  `<C-t>` / `<C-/>`  Focus or hide project terminal (Normal, Insert, Terminal mode)",
  "  `<Esc><Esc>`       Exit terminal mode back to Normal mode",
  "",
  "## Surround & Flash",
  "  `gsa` Add surrounding │ `gsd` Delete │ `gsr` Replace │ `gsf` / `gsF` Find",
  "  `gsh` Highlight │ `gsn` Search range │ `s` Flash jump (immediate)",
  "",
  "## Treesitter Text Objects",
  "  `daf` / `dif`  Delete func (outer/inner)   │ `caf` / `cif` Change func (outer/inner)",
  "  `dac` / `cic`  Class (outer/inner)         │ `daa` / `cia` Param (outer/inner)",
  "  `]m`  / `[m`   Jump next / prev func start",
  "",
  "## Fuzzy Finding & Search",
  "  `<leader><space>` or `<leader>ff` Find files│ `<leader>/`   Grep project",
  "  `<C-p>` / `<C-n>` Move │ `<Tab>` Select │ `<A-p>` Preview │ `<CR>` Open",
  "  `<leader>fb`   Buffers                     │ `<leader>fr`  Recent files  │ `<leader>sk` Keymaps",
  "",
  "## Code Navigation & LSP",
  "  `gd`  Definition   │ `gr`  References      │ `K`           Smart Docs",
  "  `gK`  Deep offline reference docs        │ `:DocsBrowse` Reference search",
  "  `<leader>ca`  Code action (quick fixes)    │ `<leader>cr`  Rename symbol (IncRename)",
  "  `[d`  / `]d`  Previous / next diagnostic error",
  "  Insert `<C-k>` Signature + parameter docs │ focus with `K`, `[s` / `]s` overloads",
  "  Python: `<leader>cI` Imports │ `<leader>cF` Ruff fixes │ `<leader>cp` LSP/environment",
  '  Python: Type `"""` first inside a function/class for a Google docstring │ Tab / Shift-Tab Fill fields',
  "  Python: `<leader>cD` / `:PythonDocstring` Generate for an existing definition",
  "  `:PythonInterpreter /path/to/python` Set project interpreter │ `auto` Restore discovery",
  "",
  "## TODO Comments",
  "  TODO / FIXME / NOTE / HACK / WARN / PERF / TEST highlight inside comments",
  "  `]t` Next TODO │ `[t` Previous TODO │ `<leader>st` Search project TODOs",
  "  Use TODO, TODO: or TODO(name): followed by your note",
  "",
  "## Git Integration",
  "  `<leader>gg`  Lazygit floating UI          │ `<leader>gL`  Commit history",
  "",
  "## 1337 Station Mode",
  "  `<leader>13`  Open Station Health & Repair │ `:StationFix` Safe repair /goinfre & cache",
  "  `:StationVenv` Rebuild project venv │ `:StationVenvMigrate` Move existing venv with backup",
  "",
  "  ────────────────────────────────────────────────────────────────────────────",
  "  Press `q` or `<Esc>` to close  ·  Use `j`/`k` or `<C-d>`/`<C-u>` to scroll",
}


-- Put frequent actions first; each heading is a navigation target.
local order = { 'Everyday Controls', 'File Explorer', 'Fuzzy Finding',
  'Code Navigation', 'Makefile', 'Project Tasks', 'Debugger', 'Floating Terminal',
  'Surround', 'Treesitter', 'TODO Comments', 'Git Integration', '1337 Station' }
local groups = {}
for _, line in ipairs(content_lines) do
  if line:match('^## ') then
    groups[#groups + 1] = { (line:sub(4):gsub(' %(`Snacks.explorer`%)', '')) }
  elseif #groups > 0 and not line:match('^%s*─') and not line:match('^%s*Press') then
    table.insert(groups[#groups], line)
  end
end
local ordered = {}
for _, prefix in ipairs(order) do
  for _, group in ipairs(groups) do
    if group[1]:sub(1, #prefix) == prefix then ordered[#ordered + 1] = group end
  end
end

local function layout()
  local width = math.max(1, math.min(88, vim.o.columns - 4))
  local height = math.max(1, math.min(34, vim.o.lines - 4))
  local footer = width >= 62 and ' / search   ]] next section   [[ previous   q close '
    or (width >= 34 and ' / find  ]] next  q close ' or ' q close ')
  return {
    relative = 'editor', width = width, height = height,
    row = math.max(0, math.floor((vim.o.lines - height - 2) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
    border = ui.border, title = ' ' .. ui.icon('help') .. ' Keymap Guide ',
    title_pos = 'center', footer = footer, footer_pos = 'center',
  }
end

local function render(buf, width)
  local lines, highlights = {}, {}
  sections = {}
  local function append(source, heading)
    source = source:gsub('<leader>', 'Space ')
    local text, spans, cursor = '', {}, 1
    while true do
      local first, last = source:find('`[^`]+`', cursor)
      if not first then text = text .. source:sub(cursor); break end
      text = text .. source:sub(cursor, first - 1)
      local start = #text
      text = text .. source:sub(first + 1, last - 1)
      spans[#spans + 1] = {start, #text}
      cursor = last + 1
    end
    lines[#lines + 1] = text
    if heading then
      sections[#sections + 1] = #lines
      highlights[#highlights + 1] = {#lines - 1, 0, -1, 'CheatsheetHeader'}
    else
      for _, span in ipairs(spans) do
        highlights[#highlights + 1] = {#lines - 1, span[1], span[2], 'CheatsheetKey'}
      end
    end
  end
  for _, group in ipairs(ordered) do
    append(group[1], true)
    for index = 2, #group do
      local line = group[index]
      -- Separate parallel actions when a narrow terminal cannot show the row.
      if vim.fn.strdisplaywidth(line:gsub('<leader>', 'Space '):gsub('`', '')) > width - 2
        and line:find('│', 1, true) then
        for _, part in ipairs(vim.split(line, '│', {plain=true})) do append('  ' .. vim.trim(part)) end
      else append(line) end
    end
    if lines[#lines] ~= '' then append('') end
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local ns = vim.api.nvim_create_namespace('cheatsheet_highlights')
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, ns, hl[4], hl[1], hl[2], hl[3])
  end
end

function M.close()
  local win, buf = M.win_id, M.buf_nr
  M.win_id, M.buf_nr = nil, nil
  if win and vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  if buf and vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, {force=true}) end
end

local function refresh()
  setup_highlights()
  if not M.win_id or not vim.api.nvim_win_is_valid(M.win_id) then return end
  local config = layout()
  local cursor = vim.api.nvim_win_get_cursor(M.win_id)[1]
  local section = 1
  for index, row in ipairs(sections) do if row <= cursor then section = index end end
  vim.api.nvim_win_set_config(M.win_id, config)
  render(M.buf_nr, config.width)
  vim.api.nvim_win_set_cursor(M.win_id, {sections[section] or 1, 0})
end

function M.show()
  if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
    vim.api.nvim_set_current_win(M.win_id)
    return M.win_id
  end
  setup_highlights()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype, vim.bo[buf].bufhidden = 'nofile', 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'configguide'
  local config = layout()
  render(buf, config.width)
  config.style = 'minimal'
  local win = vim.api.nvim_open_win(buf, true, config)
  M.win_id, M.buf_nr = win, buf
  for name, value in pairs({winblend=0, cursorline=false, wrap=true, linebreak=true,
    breakindent=true, number=false, relativenumber=false, signcolumn='no',
    foldcolumn='0', spell=false, conceallevel=0,
    winhighlight='Normal:CheatsheetNormal,FloatBorder:CheatsheetBorder,FloatTitle:CheatsheetTitle,FloatFooter:CheatsheetMuted'}) do
    vim.wo[win][name] = value
  end
  for _, key in ipairs({'q','<Esc>'}) do
    vim.keymap.set('n', key, M.close, {buffer=buf, nowait=true, silent=true, desc='Close guide'})
  end
  vim.keymap.set('n', 'j', 'gj', {buffer=buf, silent=true})
  vim.keymap.set('n', 'k', 'gk', {buffer=buf, silent=true})
  for key, direction in pairs({[']]']=1, ['[[']=-1}) do
    vim.keymap.set('n', key, function()
      local row = vim.api.nvim_win_get_cursor(win)[1]
      local target = direction == 1 and sections[1] or sections[#sections]
      for _, candidate in ipairs(sections) do
        if direction == 1 and candidate > row then target = candidate; break end
        if direction == -1 and candidate < row then target = candidate end
      end
      vim.api.nvim_win_set_cursor(win, {target, 0})
      vim.cmd('normal! zt')
    end, {buffer=buf, silent=true, desc=direction == 1 and 'Next section' or 'Previous section'})
  end
  vim.api.nvim_create_autocmd('WinClosed', {pattern=tostring(win), once=true, callback=function()
    if M.win_id == win then M.win_id, M.buf_nr = nil, nil end
  end})
  return win
end
function M.toggle()
  if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then M.close() else M.show() end
end
local group = vim.api.nvim_create_augroup('BlackKeymapGuide', {clear=true})
vim.api.nvim_create_autocmd({'VimResized', 'ColorScheme'}, {group=group, callback=refresh})
vim.api.nvim_create_autocmd('User', {group=group, pattern='BlackUIPresetChanged', callback=refresh})
return M
