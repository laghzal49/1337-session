-- ============================================================================
-- lua/carbon/palette.lua — IBM Carbon palette + memoized color math
-- ============================================================================
-- The single source of truth for every color in this config, plus the two
-- math primitives every animation uses: blend() and ease().
--
-- blend() is MEMOIZED: animations request the same handful of frames over
-- and over (mode morphs always run purple→cyan, cyan→pink, …), so after the
-- first morph each frame is a table lookup, not string math. t is quantized
-- to 1/255 — finer steps are invisible anyway and it keeps the cache tight.
-- ============================================================================

local M = {}

M.colors = {
  bg = "#161616",
  bg2 = "#262626",
  gray = "#525252",
  cyan = "#3ddbd9",
  blue = "#78a9ff",
  purple = "#be95ff",
  pink = "#ff7eb6",
  mint = "#08bdba",
  green = "#42be65",
  white = "#f2f4f8",
}

local rgb_cache = {}
local function to_rgb(hex)
  local c = rgb_cache[hex]
  if not c then
    c = {
      tonumber(hex:sub(2, 3), 16),
      tonumber(hex:sub(4, 5), 16),
      tonumber(hex:sub(6, 7), 16),
    }
    rgb_cache[hex] = c
  end
  return c
end

local blend_cache = {}

--- blend(a, b, t): t=1 → pure a, t=0 → pure b.
function M.blend(a, b, t)
  local q = math.floor(t * 255 + 0.5)
  if q <= 0 then return b end
  if q >= 255 then return a end
  local key = a .. b .. q
  local hit = blend_cache[key]
  if hit then return hit end
  local ca, cb = to_rgb(a), to_rgb(b)
  local u = q / 255
  local out = string.format(
    "#%02x%02x%02x",
    math.floor(ca[1] * u + cb[1] * (1 - u) + 0.5),
    math.floor(ca[2] * u + cb[2] * (1 - u) + 0.5),
    math.floor(ca[3] * u + cb[3] * (1 - u) + 0.5)
  )
  blend_cache[key] = out
  return out
end

--- ease-out cubic: fast start, soft landing. Every tween in the config
--- runs through this — it's what makes the morphs feel physical.
function M.ease(t)
  local u = 1 - t
  return 1 - u * u * u
end

return M
