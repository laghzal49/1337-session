local M = {}
local history, dropped, generation, added = {}, 0, 0, 0
local limit = 500
local config
local ui = require("config.ui")
local function expire(notify, id, delay)
  local epoch = generation
  vim.defer_fn(function() if epoch == generation then notify.remove(id) end end, delay)
end
local levels = { [0] = "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "OFF" }
local icon_names = { ERROR='error', WARN='warn', INFO='info', DEBUG='hint', TRACE='hint' }
local severity_hl = { ERROR='DiagnosticError', WARN='DiagnosticWarn', INFO='DiagnosticInfo', DEBUG='DiagnosticHint', TRACE='DiagnosticHint' }
local headers = {}
local namespace = vim.api.nvim_create_namespace('BlackNoticeHeadings')
local function icon(level) return ui.icon(icon_names[level] or 'info') end
local function highlight_headers(buf)
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  for row, line in ipairs(vim.api.nvim_buf_get_lines(buf,0,-1,false)) do
    if headers[line] then vim.api.nvim_buf_add_highlight(buf,namespace,headers[line],row-1,0,-1) end
  end
end


-- Transform display copies only; the bounded journal stores original messages.
function M.sort(items)
  local result, groups, errors = {}, {}, nil
  for _, item in ipairs(require("mini.notify").default_sort(items)) do
    if item.level == "ERROR" then
      if not errors then
        errors = item
        errors.data.count = 0
        result[#result + 1] = errors
      end
      errors.data.count = errors.data.count + (item.data.error_count or 1)
    else
      local key = item.level .. "\0" .. (item.data.title or "") .. "\0" .. item.msg
      if groups[key] then
        groups[key].data.count = groups[key].data.count + (item.data.count or 1)
      else
        item.data.count = item.data.count or 1
        groups[key] = item
        result[#result + 1] = item
      end
    end
  end
  if errors then
    errors.data.error_count = errors.data.count
    errors.data.latest = errors.data.latest or errors.msg
    errors.msg = errors.data.count .. " errors · <leader>n\n" .. vim.fn.strcharpart(errors.data.latest:gsub("%s+", " "), 0, 90)
    errors.data.count = nil
  end
  return vim.list_slice(result, 1, 3)
end

function M.notify(msg, level, opts)
  if vim.in_fast_event() then vim.schedule(function() M.notify(msg, level, opts) end); return end
  level = level or vim.log.levels.INFO
  local name = type(level) == "string" and level:upper() or levels[level]
  if not icon_names[name] then return end
  opts = opts or {}
  local title = opts.title and vim.fn.strcharpart(tostring(opts.title), 0, 200) or nil
  msg = tostring(msg)
  if #msg > 16384 then msg = msg:sub(1, 16384) .. "\n[message truncated at 16 KiB]" end
  local notify = require("mini.notify")
  history[#history + 1] = { msg = tostring(msg), level = name, title = title, time = os.date("%H:%M:%S") }
  if #history > limit then table.remove(history, 1); dropped = dropped + 1 end
  if added >= limit then
    -- Public setup resets MiniNotify's otherwise unbounded internal history.
    -- Keep visible groups, including the persistent unacknowledged error count.
    local active = M.sort(vim.tbl_filter(function(item) return item.ts_remove == nil end, notify.get_all()))
    generation, added, headers = generation + 1, 0, {}
    notify.setup(config)
    for _, item in ipairs(active) do
      local keep = notify.add(item.msg, item.level, item.hl_group, item.data)
      added = added + 1
      if item.level ~= "ERROR" then
        expire(notify, keep, math.max(1, (item.data.expires or vim.uv.hrtime() / 1e6) - vim.uv.hrtime() / 1e6))
      end
    end
    vim.notify = M.notify
  end
  added = added + 1
  local id = notify.add(tostring(msg), name, "MiniNotifyNormal", { title = title, expires = vim.uv.hrtime() / 1e6 + (name == "WARN" and 6000 or 3000) })
  -- Errors stay active until acknowledged; expired messages remain in history.
  if name ~= "ERROR" then
    expire(notify, id, name == "WARN" and 6000 or 3000)
  end
  return id
end

function M.setup()
  config = {
    lsp_progress = { enable = false },
    content = {
      sort = M.sort,
      format = function(item)
        local title = item.data.title and (" · " .. item.data.title) or ""
        local count = item.data.count and item.data.count > 1 and (" ×" .. item.data.count) or ""
        local header = icon(item.level) .. " " .. item.level .. count .. title
        headers[header] = severity_hl[item.level]
        return header .. "\n" .. item.msg
      end,
    },
    window = {
      winblend = 0,
      max_width_share = 0.38,
      config = function(buf)
        highlight_headers(buf)
        local width = math.max(1,math.min(62,math.floor(vim.o.columns*0.55),vim.o.columns-4))
        local rows = 0
        for _,line in ipairs(vim.api.nvim_buf_get_lines(buf,0,-1,false)) do
          rows = rows + math.max(1,math.ceil(vim.fn.strdisplaywidth(line)/width))
        end
        return {
          width = width,
          height = math.max(1,math.min(rows,10,vim.o.lines-6)),
          border = ui.border,
          title = '  Notifications ',
          title_pos = 'left',
        }
      end,
    },
  }
  require("mini.notify").setup(config)
  vim.notify = M.notify
  vim.api.nvim_create_autocmd('User', {
    group=vim.api.nvim_create_augroup('BlackNoticePreset',{clear=true}), pattern='BlackUIPresetChanged',
    callback=function() require('mini.notify').refresh() end,
  })
end

function M.history()
  M.dismiss()
  vim.cmd("botright " .. math.max(4, math.floor(vim.o.lines * 0.3)) .. "split")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  local lines = { "Latest " .. #history .. " notifications · " .. dropped .. " older records discarded", "" }
  local marks = {}
  if #history == 0 then lines[#lines+1] = 'No notifications yet.' end
  for index=#history,1,-1 do
    local item = history[index]
    lines[#lines + 1] = item.time .. " " .. icon(item.level) .. " " .. item.level .. (item.title and " · " .. item.title or "")
    marks[#marks+1] = {#lines-1,severity_hl[item.level]}
    vim.list_extend(lines, vim.split(item.msg, "\n", { plain = true }))
    lines[#lines + 1] = ""
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for _,mark in ipairs(marks) do vim.api.nvim_buf_add_highlight(buf,namespace,mark[2],mark[1],0,-1) end
  vim.bo[buf].filetype = "mininotify-history"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  vim.wo.wrap = true
  vim.wo.linebreak = true
  vim.wo.number, vim.wo.relativenumber = false, false
  vim.wo.signcolumn = "no"
  vim.wo.winhighlight = "Normal:BlackDocs,NormalNC:BlackDocs"
  vim.wo.winbar = " Notification history · q to close"
  for _,key in ipairs({'q','<Esc>'}) do
    vim.keymap.set('n', key, '<cmd>close<cr>', { buffer = true, silent = true })
  end
end

function M.dismiss() require("mini.notify").clear(); headers={} end
function M.stats() return { retained = #history, discarded = dropped, backend = added } end
return M
