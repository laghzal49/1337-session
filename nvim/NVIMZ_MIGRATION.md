# nvimz-inspired lightweight UI preset

This branch keeps the **1337-session** Neovim feature set and brings its appearance
closer to nvimz's Tokyo Night interface. It is **not** a Rust rewrite of Neovim.

## What's changed

- Tokyo Night night variant is the base colorscheme.
- Shared nvimz palette now drives the explorer, picker, completion,
  diagnostics, debug panels, statusline, bufferline, and floating windows.
- Dashboard branding follows the new preset.
- Disables Snacks animation, animated scrolling and smoothscroll under
  the lightweight preset to reduce per-frame redraw overhead.
- Existing keyboard shortcuts, LSP, conform formatting, DAP, sessions,
  project tools, and per-language behavior are retained.

## Rust-powered speed

The existing `blink.cmp` setup already uses a Rust fuzzy matcher, so replacing
it would be unnecessary. For fast file/text search install the **Rust binaries**
`fd` and `ripgrep`; the current Snacks picker can use them.

On CachyOS/Arch:

```sh
sudo pacman -S --needed ripgrep fd
```

On the 1337 Ubuntu cluster, choose user-local binaries if sudo isn't available.

## Launch / rollback

The new theme is the default on this branch:

```sh
nvim .
```

Switch back to the previous appearance without modifying files:

```sh
NVIM_COLOR_STYLE=electrovoid nvim .
```

Other supported choices: `classic`, `rose`, `crimson`.

## Validation checklist

1. Run `:Lazy sync` once and restart to install Tokyo Night.
2. Open Python and Go files; inspect `:LspInfo`, `:ConformInfo` and completion.
3. Check `<leader>e` explorer, `<leader>ff` picker and the startup dashboard.
4. Compare startup with `nvim --startuptime /tmp/nvim-startup.log +qa`;
   use the same machine and installed plugins for any comparison.
5. If the theme fails, launch with `NVIM_COLOR_STYLE=electrovoid nvim`.

Performance was optimized at the configuration level. No real-world speedup
is claimed until measured on the target machine.
