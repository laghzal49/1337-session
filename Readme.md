# 1337-session

My 1337 Session Setting: nvim, vscode, zsh and also Zed.

## Perfect Black Neovim

Pure black editing, clearer Python colors, a redesigned documentation panel,
and a composed status bar. JetBrains Mono with selective italics. Python uses
`ty` and Ruff.

![Python palette and status bar](nvim/assets/python.png)

![Blink completion and documentation](nvim/assets/completion.png)

Completion shows local matches while the language server responds, then favors
semantic suggestions. Ctrl-N/Ctrl-P navigate; Ctrl-D toggles documentation;
Tab/Shift-Tab follow snippet placeholders. Exact matches rank first, and the
native matcher retains typo tolerance and usage history.

The completion and Makefile images are captures of the current Neovim UI with
demonstration content. The Python palette image above is from an earlier revision.
See the [Neovim guide](nvim/README.md) for shortcuts and setup, and the
[design notes](nvim/DESIGN.md) for behavior and testing limits.

![Makefile target picker](nvim/assets/makefile.png)

Makefile targets run directly from Neovim with `<leader>cm`; `<leader>cM` runs
Make's default target. DAP and its debugger panels have been removed.

## One-command dev environment (Ubuntu, zero sudo)

```sh
git clone https://github.com/laghzal49/1337-session.git && ./1337-session/install.sh
```

`install.sh` builds the complete environment into `~/.local` from official
prebuilt binaries — **never calls sudo, never leaves $HOME**:

- JetBrainsMono **Nerd Font Mono** (regular, bold, italic, and bold-italic faces
  for the UI's icons and italic comments; select this family in the terminal)
- **Neovim** latest stable + this repo's config linked to `~/.config/nvim`
  (an existing config is backed up, never deleted)
- **ripgrep · fd · fzf · lazygit**
- **Node.js LTS** (for LSP/mason packages that need npm)
- **uv**, plus a managed Python if the system one can't create venvs
- **ty** and **Ruff** installed through uv's user tool directory
- **tree-sitter CLI**, and a `cc` shim via zig if the box has no C compiler
- **clangd** language server for C and C++
- plugins preinstalled headlessly, so the first launch is instant

Idempotent — re-run it any time; installed tools are skipped
(`--force` reinstalls, `--no-sync` skips the headless plugin download).
The installer supports Linux `x86_64` and `aarch64`, keeps downloads and
temporary files under `~/.local`, and never calls `sudo`.

## Personal dotfiles

Current shell, terminal and desktop configs are in [`dotfiles/`](dotfiles/README.md), with restore instructions.
