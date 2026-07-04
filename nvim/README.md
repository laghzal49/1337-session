# nvim

A [LazyVim](https://github.com/LazyVim/LazyVim) config with a full oxocarbon
("Carbon") UI overhaul, a hand-written animation engine, and a complete
Python IDE stack bolted on top.

## ★ Carbon Pulse — the animation engine (`lua/carbon/`)

Hand-written, unique to this config, display-only. Three small modules:

- **`carbon/pulse.lua`** — a **single-clock tween engine**. Every animation
  in the editor is a tween on ONE shared 30fps timer that starts with the
  first tween and stops the instant the last one finishes: an idle editor
  runs **zero timers**, and any number of live animations cost exactly one
  redraw per tick.
- **`carbon/reactive.lua`** — the living layer, all riding that one clock:
  - **Mode morph** — the whole UI *animates* between mode accents (150ms
    eased cross-fade, not a snap): cursorline, line number, indent scope,
    matchparen, float borders, window separators, and the **actual cursor
    block** (normal=purple · insert=cyan · visual=pink · replace=mint ·
    cmdline=blue · terminal=green).
  - **Typing heat** — a keystroke-velocity meter. The cursorline glow
    intensifies while you type fast and cools when you pause, and lualine
    carries a live spark (▁▂▃▄▅▆▇█) that climbs from gray to the mode
    accent while you're in flow. The hot path is one arithmetic op per key.
  - **Yank pulse** — yanked text flashes pink and eases out.
  - **Focus fade** — the split you leave dissolves into the inactive dim
    instead of cutting instantly.
  - **Living dashboard** — the "1337" header melts through the palette;
    cancelled the moment you leave the dashboard.
- **`carbon/palette.lua`** — the Carbon colors plus **memoized** `blend()`
  and easing; steady-state animation frames are table lookups, not math.

## UI

- **Colorscheme**: `oxocarbon`, with every plugin below restyled onto the
  Carbon palette (`lua/plugins/ui.lua`).
- Rounded-bubble `lualine` statusline with a hand-built **per-mode Carbon
  theme** — the statusline bubbles recolor with the same accent map as the
  reactive engine — plus the typing-heat spark and a **per-buffer cached**
  LSP-client readout (recomputed on attach/detach, not every redraw).
- Slant `bufferline` (cyan underline on the active buffer, pink modified
  dot), floating `noice` cmdline, `dropbar` winbar breadcrumbs,
  `rainbow-delimiters`, inline hex/rgb color swatches, rendered markdown,
  and a `smear-cursor` trail.
- "1337" dashboard header with the living Carbon gradient.
- **Every menu is a Carbon panel**: blink.cmp completion menu + docs
  (rounded, cyan fuzzy matches), which-key, Mason, the `:Lazy` manager
  (rounded + backdrop), and quickfix via `quicker.nvim` (syntax-highlighted,
  editable).
- **Diagnostics**: cursor-line chips via `tiny-inline-diagnostic.nvim`
  (rounded, multi-line, names the source — basedpyright/flake8/mypy), plus
  a rounded float panel; stock virtual_text is off.
- Everything above is display-only — it never touches LSP config, the
  picker, or keymaps. **No keymap has ever changed**: the config's only
  additions remain `<leader>un`, `<leader>cv`, `<leader>dPt`/`<leader>dPc`.

## Performance / no-conflict rules

- **One clock for everything**: all animations share the single Pulse timer
  (see above) — no per-animation timers, no competing redraws, zero idle
  cost.
- **One system per job**: snacks (which LazyVim already ships) owns
  notifications, indent guides, the file explorer, dashboard, statuscolumn,
  and smooth scroll — all restyled in Carbon. No `nvim-notify`, no
  `neo-tree`, no `indent-blankline` duplicating them.
- **Everything lazy-loads**: `defaults.lazy = true`; every custom plugin
  declares an `event`/`ft`/`cmd`/`keys` trigger. Startup pays only for the
  colorscheme.
- **Latest fast stack, verified**: blink.cmp with the Rust fuzzy matcher
  (pinned explicitly) and the nvim-treesitter `main` rewrite with async
  parsing, both via LazyVim.
- The statusline polls at lualine's slow default; the typing spark drives
  `:redrawstatus` itself only while animating. Diagnostic chips render only
  the cursor line (cheaper than stock virtual text on every line).
- Unused built-in plugins (netrw, gzip, tar/zip, tutor, tohtml, rplugin)
  are disabled from the runtimepath; LazyVim's duplicate yank-flash autocmd
  is removed (Carbon owns the yank pulse); tokyonight + catppuccin are
  disabled (oxocarbon is the identity — run `:Lazy clean` once to drop
  leftovers like neo-tree/nvim-notify from older config versions).

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
lua/carbon/    ★ hand-written animation library: palette, pulse (engine), reactive
lua/plugins/   ui.lua (visuals), lint.lua (flake8+mypy), python.lua (LSP/format/debug)
```
