# Personal dotfiles

The hidden files and `.config/` tree mirror their locations under `$HOME`.
Snapshot of the CachyOS development desktop: Zsh, Bash, Fish, Kitty,
Alacritty, Starship, tmux, lazygit, Hyprland, fonts, UWSM and the user SSH agent.
The active LazyVim configuration is saved in [`.config/nvim`](.config/nvim).
The older custom Neovim setup is tracked separately under `../nvim`.

## Restore selected settings

Back up existing configs first. From the repository root, copy only what you need:

```sh
mkdir -p ~/.config
cp -i dotfiles/.zshrc ~/.zshrc
cp -r -i dotfiles/.config/kitty ~/.config/
cp -i dotfiles/.config/starship.toml ~/.config/starship.toml
# Likewise for tmux, lazygit, alacritty, fish, etc.
```

These are configuration files; copying them does not install applications.
The shell uses Neovim, fd, fzf, eza, bat, zoxide, Starship and Zsh plugins.
Terminals use Maple Mono NF and `/usr/bin/zsh`; lazygit uses delta.
Fish sources the CachyOS system configuration. Hyprland uses the installed
Lua configuration API and Noctalia shell; review monitor settings and app
bindings before using it on another machine. `devhelp` and `devpy` refer to
optional local `~/DEV-SETUP.md` and `~/.venvs/dev-tools` resources.

The SSH agent service contains no keys. To use it, copy the service into
`~/.config/systemd/user/`, run `systemctl --user daemon-reload`, then
`systemctl --user enable --now ssh-agent.service`. Add your own keys locally.

Credentials, SSH keys, shell history, application state and Fish universal
variables are deliberately excluded. Review future additions before committing.

## ElectroVoid terminal

Kitty, Alacritty, Starship and tmux match the default Neovim ElectroVoid theme.
The terminal themes use the exact 16 ANSI colors from
[`../nvim/themes/electrovoid.json`](../nvim/themes/electrovoid.json), including
its purple cursor and selection. Terminal font settings preserve the current
Maple Mono NF, 12pt setup with regular text and distinct bold and italic emphasis.

After backing up existing files, restore the terminal configs from the repo root:

```sh
mkdir -p ~/.config/kitty/themes ~/.config/alacritty/themes ~/.config/tmux
cp dotfiles/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf
cp dotfiles/.config/kitty/themes/electrovoid.conf ~/.config/kitty/themes/
cp dotfiles/.config/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml
cp dotfiles/.config/alacritty/themes/electrovoid.toml ~/.config/alacritty/themes/
cp dotfiles/.config/starship.toml ~/.config/starship.toml
cp dotfiles/.config/tmux/tmux.conf ~/.config/tmux/tmux.conf
```

Open a new terminal window, or reload Kitty with Ctrl+Shift+F5. Starship uses the
new colors on the next prompt. In tmux, run `tmux source-file ~/.config/tmux/tmux.conf`.
Neovim's installer links the editor config; restore the terminal configs separately.

## Current Ubuntu session snapshot (2026-10-30)

The active Neovim config (including its plugin lockfile), Zsh config, Starship
prompt, Neofetch, Kitty, Alacritty, fontconfig, and installed Maple Mono NF and
JetBrains Mono fonts are saved here. Paths mirror your home directory.
Font licenses and supplied documentation are included alongside the font files.

After backing up your existing settings, restore the parts you want:

```sh
mkdir -p ~/.config ~/.local/share/fonts
cp -r dotfiles/.config/nvim ~/.config/
cp dotfiles/.zshrc ~/.zshrc
cp dotfiles/.config/starship.toml ~/.config/
cp -r dotfiles/.config/neofetch ~/.config/
cp -r dotfiles/.config/kitty dotfiles/.config/alacritty ~/.config/
cp -r dotfiles/.config/fontconfig ~/.config/
tar -xJf dotfiles/.local/share/fonts.tar.xz -C ~/.local/share/
fc-cache -f
```

Neovim installs plugins on first launch. Zsh references optional locally installed
fzf and Zsh plugins; install those separately. Some aliases contain machine-specific
paths and should be adjusted when restoring on another computer. This snapshot
uses the terminal font sizes stored in the configs, superseding the older 12pt
notes above. The root installer still targets the older `nvim/` configuration;
use the copy commands above to restore this active LazyVim snapshot.
