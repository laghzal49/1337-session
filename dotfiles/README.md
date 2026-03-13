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
