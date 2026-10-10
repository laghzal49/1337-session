-- Shared float chrome. Plugin buffers and their selection/request state stay
-- with the plugin; this module only owns window-local presentation.
local M = {}
local frames, pending = {}, false
local api = vim.api

function M.fit(text, width)
  text = tostring(text):gsub('[\r\n\t]', ' ')
  if vim.fn.strdisplaywidth(text) <= width then return text end
  if width < 2 then return '' end
  local count = vim.fn.strchars(text)
  while count > 0 and vim.fn.strdisplaywidth(vim.fn.strcharpart(text, 0, count)) > width - 1 do
    count = count - 1
  end
  return vim.fn.strcharpart(text, 0, count) .. '…'
end

-- Choose a complete hint, never a clipped key binding.
function M.hint(width, variants)
  for _, text in ipairs(variants or {}) do
    if vim.fn.strdisplaywidth(text) + 2 <= width then return ' ' .. text .. ' ' end
  end
  return ''
end

local function draw(win, opts)
  if not api.nvim_win_is_valid(win) or api.nvim_win_get_buf(win) ~= opts.buf then
    frames[win] = nil
    return
  end
  local config = api.nvim_win_get_config(win)
  if config.relative == '' then frames[win] = nil; return end
  local width = api.nvim_win_get_width(win)
  local update = {}
  if opts.center then
    width = math.max(1, math.min(opts.center.width, vim.o.columns-6))
    local height = math.max(1, math.min(opts.center.height, vim.o.lines-6))
    update.relative, update.anchor = 'editor', 'NW'
    update.width, update.height = width, height
    update.row, update.col = math.floor((vim.o.lines-height-2)*0.35), math.floor((vim.o.columns-width-2)/2)
  end
  local border = require('config.ui').border
  if opts.applied_border ~= border then update.border = border; opts.applied_border = border end
  if opts.title then
    local title = type(opts.title) == 'function' and opts.title() or opts.title
    update.title = {{ ' ' .. M.fit(title, math.max(0, width - 2)) .. ' ', opts.title_hl or 'FloatTitle' }}
    update.title_pos = 'left'
  end
  local hints = type(opts.hints) == 'function' and opts.hints(win) or opts.hints
  if hints then
    if opts.scroll then
      local first,last = vim.fn.line('w0',win),vim.fn.line('w$',win)
      local total = api.nvim_buf_line_count(opts.buf)
      if first > 1 or last < total then
        local position = string.format('%d–%d/%d',first,last,total)
        hints = vim.tbl_map(function(hint) return hint..' · '..position end,hints)
        hints[#hints+1] = position
      end
    end
    update.footer = {{ M.hint(width, hints), 'BlackPopupHint' }}
    update.footer_pos = 'right'
  end
  local changed = false
  for key, value in pairs(update) do if not vim.deep_equal(config[key], value) then changed = true; break end end
  if changed then
    api.nvim_win_set_config(win, update)
    -- Command mode needs an explicit redraw, as in Blink's own window code.
    if api.nvim_get_mode().mode == 'c' then api.nvim__redraw({win=win,flush=true}) end
  end
  if opts.pad then
    -- A window gutter gives Markdown breathing room without changing byte
    -- offsets used by Treesitter and active-parameter highlighting.
    vim.wo[win].foldcolumn = '1'
    vim.wo[win].statuscolumn = ' '
    vim.wo[win].signcolumn = 'no'
    vim.wo[win].number, vim.wo[win].relativenumber = false, false
    vim.wo[win].foldenable = false
    vim.wo[win].fillchars = 'eob: ,lastline: '
  end
end

function M.frame(win, opts)
  if not win or not api.nvim_win_is_valid(win) then return end
  local previous = frames[win]
  opts = vim.tbl_extend('force', opts, {buf=api.nvim_win_get_buf(win),
    applied_border=previous and previous.applied_border})
  frames[win] = opts
  draw(win, opts)
end

local function refresh()
  for win, opts in pairs(frames) do draw(win, opts) end
end

function M.blink_menu()
  local cmp = package.loaded['blink.cmp']
  if not cmp or not cmp.is_menu_visible() then return end
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if vim.bo[api.nvim_win_get_buf(win)].filetype == 'blink-cmp-menu' then
      M.frame(win, {
        title = function()
          local count, selected = #cmp.get_items(), cmp.get_selected_item_idx()
          return 'Suggestions · ' .. (selected and selected .. '/' or '') .. count
        end,
        hints = { 'C-n/p move · Enter accept · C-e close', 'Enter accept · C-e close', 'Enter accept' },
      })
    end
  end
end

function M.diagnostic(opts)
  local buf, win = vim.diagnostic.open_float(vim.tbl_extend('force', {
    border=require('config.ui').border, title=' Diagnostics ', header='',
    max_width=math.max(1,math.min(76,vim.o.columns-6)),
    max_height=math.max(1,math.min(14,vim.o.lines-6)), source='always',
  }, opts or {}))
  if win then
    vim.wo[win].winhighlight = 'Normal:BlackDocs,NormalNC:BlackDocs,FloatBorder:BlackDocsBorder,FloatTitle:BlackDocsTitle'
    vim.wo[win].linebreak = true
    M.frame(win, {title='Diagnostics', pad=true,
      hints={'<leader>cd focus · q close', 'q close (when focused)'}})
    vim.keymap.set('n','<Esc>',function() if api.nvim_win_is_valid(win) then api.nvim_win_close(win,true) end end,
      {buffer=buf,silent=true,nowait=true})
  end
  return buf, win
end

function M.setup()
  local group = api.nvim_create_augroup('BlackPopupChrome', {clear=true})
  local function schedule()
    if pending then return end
    pending = true
    vim.schedule(function() pending=false; refresh() end)
  end
  api.nvim_create_autocmd({'WinScrolled','WinEnter','VimResized'}, {group=group,callback=schedule})
  api.nvim_create_autocmd('WinClosed', {group=group,callback=function(args) frames[tonumber(args.match)]=nil end})
  api.nvim_create_autocmd('User', {group=group,pattern='BlackUIPresetChanged',callback=schedule})
  api.nvim_create_autocmd('User', {group=group,
    pattern={'BlinkCmpMenuOpen','BlinkCmpMenuPositionUpdate','BlinkCmpListSelect'},
    callback=function() vim.schedule(M.blink_menu) end})
  -- These plugins set their filetype while creating the window. Defer until
  -- their own geometry and window options have been applied.
  api.nvim_create_autocmd({'FileType','WinNew'}, {group=group,callback=function()
    vim.schedule(function()
      for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
        local ft = vim.bo[api.nvim_win_get_buf(win)].filetype
        if api.nvim_win_get_config(win).relative ~= '' then
          if ft == 'blink-cmp-signature' then
            M.frame(win,{title='Signature',pad=true,hints={'C-k parameter details','C-k details'}})
          elseif ft:match('^dapui_') then
            local name = ft:gsub('^dapui_',''):gsub('^%l',string.upper)
            M.frame(win,{title='Debug · '..name,pad=true,
              hints=ft=='dapui_watches' and {'e edit · d remove · Enter expand · q close','e edit · q close'}
                or {'Enter expand · q / Esc close','q / Esc close'}})
          elseif ft == 'aerial' then
            M.frame(win,{title='Symbols',hints={'Enter jump · q close','Enter jump'}})
          end
        end
      end
    end)
  end})
end

return M
