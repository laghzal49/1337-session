# Nvimz UI + performance audit — 2026-11-22

This audit covers the **nvimz** visual preset and its loaded UI/runtime routes.
It does **not** claim that all optional 1337-session commands or all external
language servers were executed on a user's computer.

## Actual UI views checked

| View | Implementation | Automated capture |
| --- | --- | --- |
| Dashboard | `config.nvimz_dashboard` | `nvimz-dashboard.png` |
| Code editor | customized Tokyo Night Moon + Tree-sitter | `nvimz-editor.png` |
| Filesystem explorer | Oil rounded floating window | `nvimz-explorer.png` |
| File/buffer picker | native three-pane `fd` / `rg` UI | `nvimz-picker.png` |
| Completion | Rust-backed blink.cmp | `nvimz-completion.png` |
| Documentation | existing Markdown/LSP documentation float | `nvimz-documentation.png` |

The `Neovim visual screenshot` workflow tests that all six screenshots are
actually captured and nonidentical to the startup dashboard. Real UI screenshots
are uploaded as the `neovim-visual-previews` artifact.

## Redundancy and dead-code cleanup

- **Dropped:** the redundant Oil Git-status plugin and its unused symbol/colour
  mapping. The main editor still has Gitsigns and git-aware statusline support.
  The added plugin was interfering with automated Oil rendering.
- **Fixed:** opening unnamed buffers (formerly attempted to edit a literal
  `[No Name] (N)` path); buffer previews now show unsaved content.
- **Fixed:** global statusline no longer loses the active code filename when a
  file picker or floating explorer gets focus.
- **Cleaned:** unused dashboard padding table and temporary UI debug tracing.
- **Limited:** picker displays up to 200 matches and avoids previews over 2 MiB.
  Git background work is not duplicated in the Oil explorer.
- **Disabled while using nvimz:** lualine, bufferline, Noice, Edgy,
  tiny-inline-diagnostic, Tree-sitter context, optional window-focus scanning,
  and custom diagnostic sign aggregation. The original alternate themes retain
  their own implementations.
- **Rust media viewer:** disabled by default on the lean preset because its
  build creates work and Git dirtiness unrelated to Go/Python editing. Opt in
  with `NVIM_ENABLE_MEDIA=1 nvim` if image/PDF viewing is wanted.

## Retained deliberately

- Native LSP configs for C, Python, Lua and the user's other tools
- Rust-backed blink.cmp completion
- Conform formatting
- Tree-sitter syntax and folds
- DAP debugging
- Gitsigns, advanced Snacks project pickers, mini.pick fallback
- Session restore, 1337 cluster Station Mode, Python environment tooling

These are intentionally **not** deleted as dead code; they are called by
keybindings, project workflows, another color preset, or development tooling.

## Tests and limits

- See `nvim/tests/nvimz_ui_review.lua` for startup/theme smoke assertions.
- See `.github/workflows/nvim-screenshot.yml` for the real screenshot test.
- External `gopls`, `ty`, `ruff`, and `clangd` are machine-dependent and
  must be exercised with `:LspInfo` and `:ConformInfo` locally.
- No performance improvement is claimed without a before/after benchmark on the
  same Neovim binary, filesystem, machine, and installed plugin set.

## Reproduce

```sh
sudo pacman -S --needed fd ripgrep
nvim .
```

Within Neovim run `:Lazy sync` once, then check Space+e, Space+ff,
Space+/, completion, and `:ConformInfo`.

Legacy appearance rollback: `NVIM_COLOR_STYLE=electrovoid nvim`.
