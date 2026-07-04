-- ============================================================================
-- lua/carbon/pulse.lua — ★ CARBON PULSE: single-clock animation engine ★
-- ============================================================================
-- Every animation in this config — mode morph, typing heat, yank fade,
-- dashboard gradient — is a *tween* registered on ONE shared 30fps libuv
-- timer. The clock starts when the first tween registers and stops the
-- instant the last one finishes:
--
--   · an idle editor runs ZERO timers and pays zero cost
--   · one redraw per tick, no matter how many animations are live
--     (v4 ran a separate timer with its own redraw per animation)
--   · tweens are keyed by id — restarting "mode" mid-morph replaces the
--     running tween instead of stacking a second timer on top of it
--
-- Pure display machinery: no keymaps, no handlers, no behavior.
-- ============================================================================

local M = {}

---@class CarbonTween
---@field start number   vim.uv.now() at registration (ms)
---@field duration number ms; math.huge = loop forever until M.stop(id)
---@field frame fun(p: number) p = progress 0..1 (or elapsed ms for loops)
---@field done fun()|nil  called once when a finite tween completes

local tweens = {} ---@type table<string, CarbonTween>
local active = 0
local timer -- created lazily, then reused forever (never closed)
local running = false

local function tick()
  local t = vim.uv.now()
  local any = false
  -- iterate a snapshot: frame()/done() may add or remove tweens, and
  -- mutating a table mid-pairs is undefined behavior in Lua
  for _, id in ipairs(vim.tbl_keys(tweens)) do
    local tw = tweens[id]
    if tw then
      any = true
      if tw.duration == math.huge then
        tw.frame(t - tw.start) -- loops get elapsed ms
      else
        local p = math.min((t - tw.start) / tw.duration, 1)
        tw.frame(p)
        if p >= 1 and tweens[id] == tw then
          tweens[id] = nil
          active = active - 1
          if tw.done then tw.done() end
        end
      end
    end
  end
  if any then
    vim.cmd.redraw() -- ONE paint for every live animation
  end
  if active <= 0 and running then
    timer:stop() -- clock goes to sleep; editor is 100% timer-free again
    running = false
  end
end

--- Register (or replace) a tween on the shared clock.
---@param id string     same id replaces the running tween (clean restarts)
---@param duration number ms, or math.huge to loop until M.stop(id)
---@param frame fun(p: number)
---@param done fun()|nil
function M.start(id, duration, frame, done)
  if not tweens[id] then
    active = active + 1
  end
  tweens[id] = { start = vim.uv.now(), duration = duration, frame = frame, done = done }
  if not running then
    timer = timer or vim.uv.new_timer()
    timer:start(0, 33, vim.schedule_wrap(tick)) -- ~30fps
    running = true
  end
end

--- Cancel a tween (no-op if it isn't running). The clock stops itself on
--- the next tick if this was the last one.
function M.stop(id)
  if tweens[id] then
    tweens[id] = nil
    active = active - 1
  end
end

return M
