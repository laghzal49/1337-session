# Perfect Black Neovim

Pure black code, clearer Python syntax, a useful documentation panel, and a
composed status bar. Built on LazyVim with **ty + Ruff** for Python.

## Editing

![Python palette and bottom status bar](assets/python.png)

Upright JetBrains Mono keeps code readable. Comments retain italics. Variables
are light blue, functions warm gold, types teal, and keywords lavender.

## Completion documentation

![Completion and documentation panel](assets/documentation.png)

A distinct reference surface, symbol icons, readable kind labels, and visible
keyboard hints. This actual Neovim capture uses a deterministic demo completion
source, not a live ty response.

## Commands

![Command palette](assets/command.png)

Explicit operation labels, consistent padding, and a subtle outline over code.

## Workspace and search

![1337 workspace](assets/workspace.png)

![Adaptive project search](assets/perfect-black.png)

All images are actual Neovim UI-grid captures rendered with the configured font
faces. Python examples are unsaved demonstration buffers.

## Keys

`<leader>` is Space.

| Action | Keys |
| --- | --- |
| Find files | `<leader><space>` |
| Search project | `<leader>/` |
| Toggle picker preview | `Ctrl-P` in the picker |
| Toggle completion documentation | `Ctrl-D` |
| Open/scroll completion documentation | `Ctrl-B` / `Ctrl-F` |
| Toggle file tree | `<leader>e` |
| Notification history | `<leader>n` |
| Dismiss live notifications | `<leader>un` |

Normal-mode Ctrl-B retains page-up behavior. Documentation shortcuts apply in
insert/select mode while using completion.

## Font and setup

Choose **JetBrainsMono Nerd Font Mono — Regular — 13 pt** in your terminal.
Comments use Italic and emphasis uses Bold. The repository's
[Kitty](../dotfiles/.config/kitty/kitty.conf) and
[Alacritty](../dotfiles/.config/alacritty/alacritty.toml) settings select the real
font faces. Installing only Neovim's config does not change terminal settings.

See the [repository installation guide](../Readme.md) and the complete
[design decisions](DESIGN.md).

## UI checks

With plugins installed and Python `msgpack` available:

```sh
NVIM_BIN=/path/to/nvim python3 nvim/tests/ui_review.py
```

Use the same `XDG_DATA_HOME` as your plugin installation if it is nonstandard.
The suite checks diagnostic collisions, notification overflow, adaptive search,
large buffers, responsive navigation, and completion-documentation mappings.
