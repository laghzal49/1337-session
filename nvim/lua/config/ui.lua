-- Shared UI constants and design tokens for borders, sizes, and blending.
-- Referenced by options.lua, lazy.lua, and every plugin that draws a panel.
local M = {
  border = "rounded",
  blend = 0,
  max_width = 80,
  max_height = 20,
  colors = {
    teal = "#4FD1C5",
    lilac = "#C7A6FF",
    text = "#D7E3FF",
    selection = "#14263D",
    selection_bright = "#164B4A",
    border = "#25334A",
    border_soft = "#2A5961",
    error = "#FF8FA3",
  },
}
return M
