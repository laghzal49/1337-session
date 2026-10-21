-- Opt-in observations only. Never wraps LSP calls or records source text/paths.
local M = {}
local group, timer, generation = nil, nil, 0
local pending, stats, pending_count = {}, {}, 0
local function now() return vim.uv.hrtime() / 1e6 end
local function record(name, elapsed)
  local entry = stats[name] or { count = 0, total = 0, max = 0 }
  entry.count, entry.total = entry.count + 1, entry.total + elapsed
  entry.max = math.max(entry.max, elapsed)
  stats[name] = entry
end
function M.stop()
  generation = generation + 1
  if timer then timer:stop(); timer:close(); timer = nil end
  if group then vim.api.nvim_del_augroup_by_id(group); group = nil end
  pending, pending_count = {}, 0
end
function M.start()
  M.stop()
  stats = {}
  local token = generation
  group = vim.api.nvim_create_augroup('SessionLiveProfile', { clear = true })
  vim.api.nvim_create_autocmd('LspRequest', {
    group = group,
    callback = function(ev)
      local data = ev.data
      local request = data.request
      local key = data.client_id .. ':' .. data.request_id
      if request.type == 'pending' then
        -- Bound storage even if a server never responds.
        if not pending[key] and pending_count < 512 then
          local client = vim.lsp.get_client_by_id(data.client_id)
          pending[key] = { started = now(), name = (client and client.name or 'LSP') .. ' ' .. request.method }
          pending_count = pending_count + 1
        end
      elseif pending[key] then
        if request.type == 'complete' then record(pending[key].name, now() - pending[key].started) end
        pending[key], pending_count = nil, pending_count - 1
      end
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', { group = group, callback = M.stop })
  timer = assert(vim.uv.new_timer())
  local function arm()
    local due = now() + 100
    timer:start(100, 0, vim.schedule_wrap(function()
      if generation ~= token or not timer then return end
      record('Event-loop delay beyond 100 ms probe', math.max(0, now() - due))
      arm() -- one pending callback at a time, including while the editor is busy
    end))
  end
  arm()
end
function M.snapshot() return vim.deepcopy(stats) end
function M.report()
  local lines = { 'Session profile (' .. (timer and 'recording' or 'stopped') .. ')',
    'Completed LSP round trips, not end-to-end popup/typing latency.',
    'Event-loop delay includes blocking work, OS scheduling and system sleep.',
    'Cancelled and unfinished requests are excluded.', '' }
  local names = vim.tbl_keys(stats)
  table.sort(names)
  for _, name in ipairs(names) do
    local entry = stats[name]
    lines[#lines + 1] = ('%s: n=%d mean=%.1f ms max=%.1f ms'):format(
      name, entry.count, entry.total / entry.count, entry.max)
  end
  if not next(stats) then lines[#lines + 1] = 'No samples yet. Start, use completion/K/save, then stop.' end
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'Session profile' })
end
function M.command(action)
  if action == 'start' then
    M.start()
    vim.notify('Profiling started. Use completion, K, search and save; then :SessionProfile stop')
  elseif action == 'stop' then M.stop(); M.report()
  elseif action == '' or action == 'report' then M.report()
  else vim.notify('Use :SessionProfile start, stop or report', vim.log.levels.WARN) end
end
return M
