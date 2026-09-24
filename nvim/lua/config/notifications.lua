local M = {}
local active, errors, scheduled = {}, 0, false
local summary_id = "perfect-black-error-summary"
local priority = { trace = 0, debug = 1, info = 2, warn = 3, error = 4 }

function M.filter(notif)
  if notif.level == "error" and notif.id ~= summary_id then
    errors = errors + 1
    if not scheduled then
      scheduled = true
      vim.schedule(function()
        scheduled = false
        if errors > 0 then
          Snacks.notifier.notify(errors .. " errors · <leader>n", "error", {
            id = summary_id, title = "Errors", timeout = false, history = false,
          })
        end
      end)
    end
    return false -- Original message is already retained in Snacks history.
  end

  if notif.timeout == 3000 and notif.level == "warn" then notif.timeout = 6000 end
  active = vim.tbl_filter(function(item) return not item.hidden end, active)
  local key = notif.level .. "\0" .. (notif.title or "") .. "\0" .. notif.msg
  local count = 1
  for i = #active, 1, -1 do
    local item = active[i]
    if item._black_key == key or item.id == notif.id then
      if item._black_key == key then count = (item._black_count or 1) + 1 end
      if item.id ~= notif.id then Snacks.notifier.hide(item.id) end
      table.remove(active, i)
    end
  end
  notif._black_key, notif._black_count = key, count
  if count > 1 then notif.title = (notif.title ~= "" and notif.title or "Notification") .. " ×" .. count end
  active[#active + 1] = notif
  if #active > 3 then
    local lowest = 1
    for i, item in ipairs(active) do
      if priority[item.level] < priority[active[lowest].level] then lowest = i end
    end
    local removed = table.remove(active, lowest)
    if removed == notif then return false end
    Snacks.notifier.hide(removed.id)
  end
  return true
end

function M.history()
  errors = 0
  Snacks.notifier.hide(summary_id)
  Snacks.notifier.show_history()
end

function M.dismiss()
  errors = 0
  Snacks.notifier.hide()
  active = {}
end

return M
