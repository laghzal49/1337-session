# Personal dotfiles

The hidden files and `.config/` tree mirror their locations under `$HOME`.
Snapshot of the CachyOS development desktop: Zsh, Bash, Fish, Kitty,
Alacritty, Starship, tmux, lazygit, Hyprland, fonts, UWSM and the user SSH agent.
Neovim lives in [`../nvim`](../nvim).

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
Terminals use JetBrainsMono Nerd Font and `/usr/bin/zsh`; lazygit uses delta.
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
JetBrains Mono Nerd Font, italic, 12pt setup.

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
