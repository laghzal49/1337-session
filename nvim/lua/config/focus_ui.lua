-- Native separators and cursorline; leave panel chrome owned by its plugin.
local M = {}
local group, pending = nil, false
local saved = {}

local function merge(win, values)
  local entries = {}
  for entry in vim.wo[win].winhighlight:gmatch('[^,]+') do
    local from = entry:match('^([^:]+):')
    if values[from] == nil then entries[#entries + 1] = entry end
  end
  for from, to in pairs(values) do
    if to ~= false then entries[#entries + 1] = from .. ':' .. to end
  end
  local value = table.concat(entries, ',')
  if vim.wo[win].winhighlight ~= value then vim.wo[win].winhighlight = value end
end

function M.update()
  local current, windows = vim.api.nvim_get_current_win(), {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative == '' then
      local p = vim.api.nvim_win_get_position(win)
      windows[#windows + 1] = { id = win, row = p[1], col = p[2],
        width = vim.api.nvim_win_get_width(win), height = vim.api.nvim_win_get_height(win) }
    end
  end
  local active, owner
  for _, win in ipairs(windows) do if win.id == current then active = win end end
  -- Prefer the active window's right separator, otherwise the left neighbor's.
  -- Separator color belongs to the left/upper window in Neovim.
  if active then
    for _, win in ipairs(windows) do
      if win.col == active.col + active.width + 1 and win.row < active.row + active.height
        and win.row + win.height > active.row then owner = active.id; break end
    end
    if not owner then
      for _, win in ipairs(windows) do
        if win.col + win.width + 1 == active.col and win.row < active.row + active.height
          and win.row + win.height > active.row then owner = win.id; break end
      end
    end
    if not owner then
      for _, win in ipairs(windows) do
        if win.row > active.row and win.col == active.col then owner = active.id; break end
        if win.row < active.row and win.col == active.col then owner = win.id end
      end
    end
  end
  for _, item in ipairs(windows) do
    local win, buf = item.id, vim.api.nvim_win_get_buf(item.id)
    if not saved[win] then
      saved[win] = { cursorline = vim.wo[win].cursorline, cursorlineopt = vim.wo[win].cursorlineopt,
        winhighlight = vim.wo[win].winhighlight }
    end
    local dashboard = vim.bo[buf].filetype == 'snacks_dashboard'
    local reader = vim.bo[buf].filetype == 'markdown' and vim.wo[win].conceallevel == 3 and vim.wo[win].wrap
    vim.wo[win].cursorline = win == current and not dashboard and not reader
    vim.wo[win].cursorlineopt = win == current and 'number,line' or 'number'
    local values = { WinSeparator = win == owner and 'BlackActiveSeparator' or 'WinSeparator' }
    -- Only normal editor buffers get our Normal remapping. Edgy, Aerial,
    -- Trouble, quickfix and help retain their own Normal/WinBar mappings.
    if vim.bo[buf].buftype == '' then
      values.Normal = win == current and 'Normal' or 'NormalNC'
      values.NormalNC = 'NormalNC'
    else
      local normal = vim.wo[win].winhighlight:match('Normal:([^,]+)')
      if normal == 'Normal' or normal == 'NormalNC' then values.Normal, values.NormalNC = false, false end
    end
    merge(win, values)
  end
end

local function schedule()
  if pending then return end
  pending = true
  vim.schedule(function()
    pending = false
    if group then M.update() end
  end)
end

function M.cleanup()
  if group then vim.api.nvim_del_augroup_by_id(group); group = nil end
  for win, options in pairs(saved) do
    if vim.api.nvim_win_is_valid(win) then
      vim.wo[win].cursorline, vim.wo[win].cursorlineopt = options.cursorline, options.cursorlineopt
      -- Remove only our separator/normal entries, retaining later plugin chrome.
      local values = { WinSeparator = false, Normal = false, NormalNC = false }
      for entry in options.winhighlight:gmatch('[^,]+') do
        local from, to = entry:match('^([^:]+):(.+)$')
        if values[from] ~= nil then values[from] = to end
      end
      if vim.bo[vim.api.nvim_win_get_buf(win)].buftype ~= '' then values.Normal, values.NormalNC = nil, nil end
      merge(win, values)
    end
  end
  saved = {}
end

function M.setup()
  M.cleanup()
  group = vim.api.nvim_create_augroup('BlackWindowFocus', { clear = true })
  vim.api.nvim_create_autocmd({ 'VimEnter', 'WinEnter', 'WinLeave', 'BufWinEnter', 'WinNew', 'WinClosed', 'WinResized', 'TabEnter' }, {
    group = group, callback = schedule,
  })
  vim.api.nvim_create_autocmd('WinClosed', { group = group, callback = function(ev) saved[tonumber(ev.match)] = nil end })
  M.update()
end

return M
