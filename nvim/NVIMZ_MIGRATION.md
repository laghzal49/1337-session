# nvimz UI port for 1337-session

The `feat/nvimz-inspired-ui` branch ports the *actual* nvimz interface to the
existing 1337-session Neovim setup while preserving its development features.

## UI fidelity

- Tokyo Night **Moon** customized to nvimz's forest green / teal / steel-blue
  colors. Transparent editor and float backgrounds.
- Python syntax: violet class names, blue functions, teal methods and gold `__init__`. The Python Tree-sitter parser is recommended for accurate constructor coloring.
- Same centered ASCII dashboard layout, menu keys (f/g/e/q), and color hierarchy.
  Local username branding replaces upstream author's name.
- Native nvimz three-window **Files / Live Grep / Buffers** picker, with separate
  input, results, preview, rounded borders and async fd/rg searches.
- Oil file explorer on the left in a rounded floating window, with hidden files,
  hidden-file highlighting and file icons; Git signs stay with Gitsigns.
- Nvimz-style compact statusline: icon-based mode, filename, Git context,
  diagnostics, active LSP, file size, time icon, location.
- Hide the original bufferline, floating Noice command palette and custom winbar
  while this preset is active. Other editor features remain installed.
- Disable optional animated scrolling / UI animations under the new preset.
- Remove the offline Docs menu, updater, K/gK docs shortcuts, completion documentation popups and Neogen docstrings from the lean preset. Keep LSP completion, diagnostics, and formatting.
- Skip legacy lualine, bufferline, Edgy, Noice, tiny-inline-diagnostics, and sticky Tree-sitter context in this preset.
- Avoid custom focus-window rescans and diagnostic-sign aggregation in favor of Neovim's native options.
- The Rust media viewer is opt-in for this preset via `NVIM_ENABLE_MEDIA=1`; the old themes keep it by default.

The statusline is reimplemented with Neovim's native statusline; it closely
matches nvimz without loading an additional statusline plugin. Existing
project-specific picker modes still use Snacks. Because plugin ecosystems
differ, this is not a claim of pixel-perfect identical rendering in every window.

## Rust tools

- `blink.cmp` already has a Rust fuzzy matcher and remains enabled.
- The nvimz picker uses the Rust-based `fd` and `ripgrep` executables.

Install on CachyOS:

```sh
sudo pacman -S --needed fd ripgrep
```

If `fd` or `rg` is missing, find/grep falls back to the existing Snacks
picker. No sudo is required to run Neovim; cluster installation of tools can
be done into `~/.local/bin` separately.

## Try and roll back

Check out this Git branch in your 1337-session clone, then ensure your
installed `~/.config/nvim` is pointing to the checkout's `nvim/` directory.
Use `:Lazy sync` once to install Tokyo Night and Oil.

```sh
nvim .
```

To use the previous interface without changing the branch:

```sh
NVIM_COLOR_STYLE=electrovoid nvim .
```

`NVIM_COLOR_STYLE=rose`, `classic` and `crimson` remain available.

## Verify

1. Start with plain `nvim`, verify the nvimz dashboard and its f/g/e/q keys.
2. Open a Go/Python project and check the statusline, `<leader>e`, `<leader>ff`,
   `<leader>/`, completion, `:LspInfo`, and `:ConformInfo`.
3. Compare startup with `nvim --startuptime /tmp/startup-nvimz.log +qa` and the
   Electrovoid preset under the same installed plugin set.
4. Confirm fallback appearance with `NVIM_COLOR_STYLE=electrovoid nvim`.

**Performance note:** No device-local startup or editing speed improvement has
been measured yet. The cloned nvimz architecture is leaner than the existing
multi-feature 1337-session stack, so this port copies its UI rather than
claiming its startup figures.

## Upstream and license

The dashboard and native picker were adapted from
[nvimz by @andev0x](https://github.com/andev0x/nvimz), licensed under MIT.
The same source inspired the Moon palette, Oil explorer and statusline layout.
See `THIRD_PARTY_NOTICES.md` for the upstream license.
