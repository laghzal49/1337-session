#!/bin/sh
# Safely link this repository's Neovim configuration. No sudo or GNU-only flags.
set -eu

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "usage: $0 /absolute/path/to/1337-session/nvim" >&2
  exit 2
fi

source_dir=$1
case "$source_dir" in
  /*) ;;
  *) echo "config source must be an absolute path: $source_dir" >&2; exit 2 ;;
esac

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
mkdir -p "$config_home"
destination="$config_home/nvim"

# Re-running is safe, including when a prior symlink is dangling.
if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source_dir" ]; then
  printf 'Neovim config already linked: %s\n' "$destination"
  exit 0
fi

backup=
if [ -e "$destination" ] || [ -L "$destination" ]; then
  backup="$destination.bak.$(date +%Y%m%d%H%M%S).$$"
  mv "$destination" "$backup"
  printf 'Previous Neovim config backed up: %s\n' "$backup"
fi

# Restore the previous config if linking fails.
if ! ln -s "$source_dir" "$destination"; then
  if [ -n "$backup" ]; then mv "$backup" "$destination"; fi
  echo "failed to link Neovim config" >&2
  exit 1
fi
printf 'Neovim config linked: %s -> %s\n' "$destination" "$source_dir"
