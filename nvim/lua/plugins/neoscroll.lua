return {
  "karb94/neoscroll.nvim",
  keys = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "gg", "G" }, -- Force lazy-loading on these keys
  config = function()
    local neoscroll = require("neoscroll")
    neoscroll.setup({
      hide_cursor = true,
      stop_eof = true,
      easing_function = "sine", -- "sine" or "quadratic" gives that smooth ramp-up/ramp-down feel
    })

    -- Explicitly map the movements to ensure your distro doesn't overwrite them
    local keymaps = {
      ["<C-u>"] = function() neoscroll.ctrl_u({ duration = 250 }) end,
      ["<C-d>"] = function() neoscroll.ctrl_d({ duration = 250 }) end,
      ["<C-b>"] = function() neoscroll.ctrl_b({ duration = 400 }) end,
      ["<C-f>"] = function() neoscroll.ctrl_f({ duration = 400 }) end,
    }

    local modes = { "n", "v", "x" }
    for key, func in pairs(keymaps) do
      for _, mode in ipairs(modes) do
        vim.keymap.set(mode, key, func, { replace_keycodes = false, silent = true })
      end
    end
  end,
}
