# Perfect Black Neovim

A LazyVim workspace with a pure black editor, compact search, readable italic
type, and restrained Nerd Font icons. Python intelligence comes from `ty`,
with Ruff for linting and formatting.

![1337 workspace](assets/workspace.png)

![Python syntax palette](assets/python.png)

![Perfect Black Neovim — adaptive picker and italic JetBrains Mono](assets/perfect-black.png)

Actual Neovim UI-grid captures rendered with JetBrains Mono Nerd Font Mono
Italic and Bold Italic. No generated mockup or composited interface elements.

## Design

- A two-pane 1337 launch screen pairs direct actions with project-local recent
  files. Small terminals use a compact single column without the wordmark.
- Python variables are off-white, members blue-gray, functions blue, keywords
  lavender, types sand, and values muted green/peach. LSP token overrides keep
  the main identifier roles consistent with Tree-sitter.
- The command bar uses a padded charcoal surface. Completion documentation
  and hover use a quieter surface with no outline glyphs.
- Full mode names on wide screens and a bold active filename anchor the statusline.

- Search shrinks to its results after matching finishes. The input stays near
  the top; changing selection does not repeatedly resize a settled list.
- Filename first, bold; directories muted and long paths shortened in the
  middle. More horizontal space goes to results than to preview.
- One cell of filled padding surrounds the picker, with a separate preview
  fill. There are no visible outline characters.
- Monochrome language glyphs, outlined folder icons, and chevrons keep the
  tree quiet. Git state colors its markers instead of entire filenames.
- Repeated notifications batch; errors share one summary with full session
  history. One diagnostic sign per line leaves room for its Git marker.

## Shortcuts

`<leader>` is Space in this configuration.

| Action | Keys |
| --- | --- |
| Find files | `<leader><space>` |
| Search project | `<leader>/` |
| Toggle picker preview | `Ctrl-P` in the input or list |
| Toggle completion documentation | `Ctrl-D` in completion |
| Scroll completion documentation | `Ctrl-B` / `Ctrl-F` |
| Toggle file tree | `<leader>e` |
| Review notification history | `<leader>n` |
| Dismiss live notifications | `<leader>un` |
| Close history drawer | `q` |

Below 110 columns, the tree closes after you open a file. Search previews
start hidden on narrow terminals and can be opened with `Ctrl-P`.

## JetBrains Mono Italic

Use **JetBrainsMono Nerd Font Mono**, **Italic**, **13 pt** in your terminal.
The Mono variant keeps Nerd Font glyphs within terminal cells. Comments also
request italics in the Neovim theme, so they remain italic with a regular
terminal font. Neovim itself cannot select the font in a terminal emulator.

The repository's [Kitty config](../dotfiles/.config/kitty/kitty.conf) selects
`JetBrainsMonoNFM-Italic` and its Bold Italic face. The
[Alacritty config](../dotfiles/.config/alacritty/alacritty.toml) selects the
same family and styles at 13 pt. These settings take effect when you apply
the terminal dotfiles; updating only the Neovim config does not change the
terminal font.

The [installer](../install.sh) installs the Nerd Font archive and checks that
both Mono Italic and Bold Italic faces exist. For the cluster terminal, select
the family/style in the terminal profile's custom font setting after installation.

## Install and verify

Follow the [repository installation guide](../Readme.md#one-command-dev-environment-ubuntu-zero-sudo).
With plugins installed, the UI regression suite runs with:

```sh
uv run --with msgpack python nvim/tests/ui_review.py
```

Run it from the repository root. Set `NVIM_BIN` if needed. The suite uses
unsaved buffers and checks diagnostics, notification bursts, responsive
pickers, adaptive sizing, previews, and narrow-screen tree behavior.

See [DESIGN.md](DESIGN.md) for the palette, tradeoffs, and measured test scope.
