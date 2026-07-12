-- ============================================================================
-- lua/plugins/claude.lua — Claude Code IDE integration
-- ============================================================================
-- Talks to a running `claude` CLI session over the same WebSocket protocol
-- the official VS Code / JetBrains extensions use: send the current
-- selection/buffer as context, jump Claude's edits back into your buffers,
-- see diffs inline. Requires the `claude` CLI on $PATH (already true here).
-- ============================================================================

return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {},
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection" },
      {
        "<leader>aa",
        "<cmd>ClaudeCodeDiffAccept<cr>",
        desc = "Accept diff",
      },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  },
}

-- ============================================================================
-- WHAT THIS FILE ADDS (for diffing):
--   coder/claudecode.nvim   Claude Code CLI <-> nvim bridge, <leader>a* keys
-- ============================================================================
