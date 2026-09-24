local M = {}
local levels = { [0] = "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "OFF" }
local icons = { ERROR = "", WARN = "", INFO = "", DEBUG = "", TRACE = "" }

-- Transform display copies only: every original message remains in history.
function M.sort(items)
  local result, groups, errors = {}, {}, nil
  for _, item in ipairs(require("mini.notify").default_sort(items)) do
    if item.level == "ERROR" then
      if not errors then
        errors = item
        errors.data.count = 0
        result[#result + 1] = errors
      end
      errors.data.count = errors.data.count + 1
    else
      local key = item.level .. "\0" .. (item.data.title or "") .. "\0" .. item.msg
      if groups[key] then
        groups[key].data.count = groups[key].data.count + 1
      else
        item.data.count = 1
        groups[key] = item
        result[#result + 1] = item
      end
    end
  end
  if errors then
    errors.msg = errors.data.count .. " errors · <leader>n\n" .. vim.fn.strcharpart(errors.msg:gsub("%s+", " "), 0, 90)
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
  local notify = require("mini.notify")
  local id = notify.add(tostring(msg), name, "Diagnostic" .. ({ ERROR = "Error", WARN = "Warn", INFO = "Info", DEBUG = "Hint", TRACE = "Hint" })[name], { title = opts.title })
  -- Errors stay active until acknowledged; expired messages remain in history.
  if name ~= "ERROR" then
    vim.defer_fn(function() notify.remove(id) end, name == "WARN" and 6000 or 3000)
  end
  return id
end

function M.setup()
  require("mini.notify").setup({
    lsp_progress = { enable = false },
    content = {
      sort = M.sort,
      format = function(item)
        local title = item.data.title and (item.data.title .. " · ") or ""
        local count = item.data.count and item.data.count > 1 and (" ×" .. item.data.count) or ""
        return (icons[item.level] or "") .. " " .. title .. item.level .. count .. "\n" .. item.msg
      end,
    },
    window = { winblend = 0, max_width_share = 0.4, config = function()
      return { border = "rounded", title = " Notifications ", title_pos = "left" }
    end },
  })
  vim.notify = M.notify
end

function M.history()
  M.dismiss()
  vim.cmd("botright " .. math.max(4, math.floor(vim.o.lines * 0.3)) .. "split")
  require("mini.notify").show_history()
  vim.wo.wrap = true
  vim.wo.winbar = " Notification history · q to close"
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true, silent = true })
end

function M.dismiss() require("mini.notify").clear() end
return M
