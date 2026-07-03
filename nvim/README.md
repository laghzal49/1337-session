# nvim

A [LazyVim](https://github.com/LazyVim/LazyVim) config with a full oxocarbon
("Carbon") UI overhaul and a complete Python IDE stack bolted on top.

## UI

- **Colorscheme**: `oxocarbon` + a hand-written "Carbon Reactive Engine"
  (`lua/plugins/ui.lua`) — the whole UI re-tints per mode (normal/insert/
  visual/replace/cmdline), yanks pulse-fade instead of flat-flashing, and the
  dashboard header animates through the palette.
- Rounded-bubble `lualine` statusline, slant `bufferline`, floating `noice`
  cmdline, `dropbar` winbar breadcrumbs, `rainbow-delimiters`, inline hex/rgb
  color swatches, rendered markdown, and a `smear-cursor` trail.
- Everything above is display-only — it never touches LSP config, the
  picker, or keymaps.

## Python

Fully wired in `lua/plugins/python.lua`:

- **LSP**: `basedpyright` (type checking left to mypy, see below).
- **Lint**: `flake8` + `mypy`, run on open and on every save
  (`lua/plugins/lint.lua`), surfaced as normal diagnostics.
- **Format**: `isort` + `autopep8` (the flake8/pycodestyle-driven
  formatter) on save, via `conform.nvim`.
- **Virtualenvs**: `<leader>cv` → `venv-selector.nvim`.
- **Debugging**: `debugpy` via `nvim-dap` + `nvim-dap-python`
  (`<leader>d*`, plus `<leader>dPt` / `<leader>dPc` for method/class debug).

Everything installs itself through `mason.nvim` on first launch.

## Structure

```
lua/config/    options, keymaps, autocmds, lazy.nvim bootstrap
lua/plugins/   ui.lua (visuals), lint.lua (flake8+mypy), python.lua (LSP/format/debug)
```
