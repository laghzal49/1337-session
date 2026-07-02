#!/usr/bin/env bash
# One-shot setup on a fresh 1337 machine: zsh config + Carbon neofetch
set -e
mkdir -p ~/.local/bin ~/.config/neofetch
# neofetch is a standalone script — no root needed
curl -fsSL https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch \
  -o ~/.local/bin/neofetch && chmod +x ~/.local/bin/neofetch
cp "$(dirname "$0")/neofetch.conf" ~/.config/neofetch/config.conf
cp "$(dirname "$0")/zshrc" ~/.zshrc
echo "done — open a new terminal"
