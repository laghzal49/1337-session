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
local icons = {
  ERROR = ui.icon("error"), WARN = ui.icon("warn"), INFO = ui.icon("info"),
  DEBUG = ui.icon("hint"), TRACE = ui.icon("hint"),
}

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
  if not icons[name] then return end
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
    generation, added = generation + 1, 0
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
  local id = notify.add(tostring(msg), name, "Diagnostic" .. ({ ERROR = "Error", WARN = "Warn", INFO = "Info", DEBUG = "Hint", TRACE = "Hint" })[name], { title = title, expires = vim.uv.hrtime() / 1e6 + (name == "WARN" and 6000 or 3000) })
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
        local title = item.data.title and (item.data.title .. " · ") or ""
        local count = item.data.count and item.data.count > 1 and (" ×" .. item.data.count) or ""
        return (icons[item.level] or "") .. " " .. title .. item.level .. count .. "\n" .. item.msg
      end,
    },
    window = {
      winblend = 0,
      max_width_share = 0.38,
      config = function()
        return {
          border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
          title = '  Notifications ',
          title_pos = 'left',
        }
      end,
    },
  }
  require("mini.notify").setup(config)
  vim.notify = M.notify
end

function M.history()
  M.dismiss()
  vim.cmd("botright " .. math.max(4, math.floor(vim.o.lines * 0.3)) .. "split")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  local lines = { "Latest " .. #history .. " notifications · " .. dropped .. " older records discarded", "" }
  for _, item in ipairs(history) do
    lines[#lines + 1] = item.time .. " " .. (icons[item.level] or "") .. " " .. item.level .. (item.title and " · " .. item.title or "")
    vim.list_extend(lines, vim.split(item.msg, "\n", { plain = true }))
    lines[#lines + 1] = ""
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "mininotify-history"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  vim.wo.wrap = true
  vim.wo.winbar = " Notification history · q to close"
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true, silent = true })
end

function M.dismiss() require("mini.notify").clear() end
function M.stats() return { retained = #history, discarded = dropped, backend = added } end
return M
