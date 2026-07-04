# nvim

A [LazyVim](https://github.com/LazyVim/LazyVim) config with a full oxocarbon
("Carbon") UI overhaul and a complete Python IDE stack bolted on top.

## UI

- **Colorscheme**: `oxocarbon` + a hand-written "Carbon Reactive Engine"
  (`lua/plugins/ui.lua`) — the whole UI re-tints per mode (normal/insert/
  visual/replace/cmdline), yanks pulse-fade instead of flat-flashing, and the
  dashboard header animates through the palette.
- Rounded-bubble `lualine` statusline with a hand-built **per-mode Carbon
  theme** — the statusline bubbles recolor with the same accent map as the
  reactive engine, so the whole UI shifts color together.
- Slant `bufferline` (cyan underline on the active buffer, pink modified
  dot), floating `noice` cmdline, `dropbar` winbar breadcrumbs,
  `rainbow-delimiters`, inline hex/rgb color swatches, rendered markdown,
  and a `smear-cursor` trail.
- "1337" dashboard header with an animated Carbon gradient; diagnostics
  float in a rounded panel that names its source (basedpyright/flake8/mypy).
- Everything above is display-only — it never touches LSP config, the
  picker, or keymaps.

## Performance / no-conflict rules

- **One system per job**: snacks (which LazyVim already ships) owns
  notifications, indent guides, the file explorer, dashboard, statuscolumn,
  and smooth scroll — all restyled in Carbon. No `nvim-notify`, no
  `neo-tree`, no `indent-blankline` duplicating them.
- **Everything lazy-loads**: `defaults.lazy = true`; every custom plugin
  declares an `event`/`ft`/`cmd`/`keys` trigger. Startup pays only for the
  colorscheme.
- Unused built-in plugins (netrw, gzip, tar/zip, tutor, tohtml, rplugin)
  are disabled from the runtimepath.
- The reactive-engine timers (yank pulse, dashboard gradient) self-destruct
  the moment their moment passes — zero idle cost while editing.

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
