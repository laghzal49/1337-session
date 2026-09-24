# Perfect Black Neovim

Pure black code, clearer Python syntax, a useful documentation panel, and a
composed status bar. Panels share one palette and consistent outlines. Built on LazyVim with **ty + Ruff** for Python.

## Editing

![Python palette and bottom status bar](assets/python.png)

Upright JetBrains Mono keeps code readable. Comments retain italics. Variables
are light blue, functions warm gold, types teal, and keywords lavender.

## Completion documentation

![Completion and documentation panel](assets/documentation.png)

A distinct reference surface, consistent symbol icons, short kind labels, and visible
keyboard hints. This actual Neovim capture uses a deterministic demo completion
source, not a live ty response.

## Commands

![Command palette](assets/command.png)

Explicit operation labels, content-sized width, and the same outline as search
and documentation.

## Workspace and search

![1337 workspace](assets/workspace.png)

![Adaptive project search](assets/perfect-black.png)

File locations occupy the result list while code stays in the preview. Toggle
the preview off and matching code returns to the rows.

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
| Mini Files: current file / project | `<leader>fm` / `<leader>fM` |
| Namu: file / workspace symbols | `<leader>cs` / `<leader>cS` |
| Glance: definition / references | `<leader>cgd` / `<leader>cgr` |
| Glance: type / implementation | `<leader>cgt` / `<leader>cgi` |
| Rename with live preview | `<leader>cr` |
| Split/join list, dict, or call | `<leader>cj` |
| Editable quickfix | `<leader>xQ` |
| Expand/collapse quickfix context | `>` / `<` in quickfix |
| Inner/around Python indentation | `ii` / `ai` after an operator or in Visual mode |
| Inner/around snake_case subword | `iS` / `aS` after an operator or in Visual mode |
| Toggle LSP inlay hints at line ends | `<leader>uh` |
| Notification history | `<leader>n` |
| Dismiss live notifications | `<leader>un` |

Normal-mode Ctrl-B retains page-up behavior. Documentation shortcuts apply in
insert/select mode while using completion.

## Added workflow tools

All eleven shortlisted plugins are included and pinned in `lazy-lock.json`.
Mini Files is an on-demand alternative; Neo-tree keeps its sidebar shortcut.
Namu provides symbol navigation, while Glance previews definitions/references.
TreeSJ handles structural split/join; selected Various Textobjs mappings extend
existing motions without enabling its full default keymap set.

Tiny Inline Diagnostic displays full, wrapped cursor-line messages and stays
quiet while typing. Mini Notify owns notifications: info lasts 3 seconds,
warnings 6 seconds, and errors persist until history is opened or notifications
are dismissed. At most three grouped entries are displayed in one window;
every original message stays in session history.

Colorful Menu enriches completion when possible, with plain-label fallback.
The upstream plugin does not list a dedicated ty formatter: this integration
uses its generic fallback rather than pretending ty is pyright. Endhints only
shows hints supplied by the active server. Namu is beta; its tested revision is
pinned. Ruff may reformat structures after a TreeSJ edit when you save.

Quicker `:w` applies result edits to source buffers. Its default autosave policy
writes previously unmodified buffers; already modified buffers remain unsaved.

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
large buffers, responsive navigation, and documentation mappings with deliberately
slow completion responses. It also loads all eleven additions, checks Mini Files,
TreeSJ and quickfix edits in temporary files, and exercises Glance, Namu, rename,
and endhints with a deterministic test LSP. This is integration coverage, not a
claim about live ty accuracy, external-server latency, or cluster performance.

Python environment-discovery checks (run from the repository root):

```sh
nvim --headless -u NONE -l nvim/tests/python_environment.lua
```

Standalone Python user-package discovery is asynchronous and cached. Project
roots and active environments keep their normal discovery behavior.
