#!/usr/bin/env bash
# Homebrew-based macOS companion to install.sh. No sudo is used.
set -euo pipefail

FORCE=0
NOSYNC=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --no-sync) NOSYNC=1 ;;
    --help|-h)
      printf 'Usage: ./install.sh [--force] [--no-sync] [--config-only]\n'
      exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$ROOT/nvim/init.lua" ] || { echo 'Missing Neovim configuration' >&2; exit 1; }
if ! command -v brew >/dev/null 2>&1; then
  echo 'macOS setup needs an existing Homebrew installation (brew.sh).' >&2
  echo 'Alternatively: ./install.sh --config-only (requires Neovim already installed).' >&2
  exit 1
fi

# Homebrew manages binary compatibility on Intel and Apple Silicon.
export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin"
failed=0
install_formula() {
  local formula="$1" command="$2"
  if [ "$FORCE" != 1 ] && command -v "$command" >/dev/null 2>&1; then
    printf 'Already available: %s\n' "$command"
    return 0
  fi
  if brew list --formula "$formula" >/dev/null 2>&1; then
    [ "$FORCE" = 1 ] || return 0
    brew reinstall "$formula" || { echo "Failed to reinstall $formula" >&2; failed=1; }
  else
    brew install "$formula" || { echo "Failed to install $formula" >&2; failed=1; }
  fi
}

install_formula neovim nvim
install_formula ripgrep rg
install_formula fd fd
install_formula fzf fzf
install_formula lazygit lazygit
install_formula node node
install_formula uv uv
install_formula tree-sitter tree-sitter
if ! command -v python3 >/dev/null 2>&1; then install_formula python python3; fi

# Let login shells discover binaries installed by uv.
path_line='export PATH="$HOME/.local/bin:$PATH" # 1337-session'
for rc in "$HOME/.zprofile" "$HOME/.bash_profile"; do
  if [ ! -f "$rc" ] || ! grep -Fq '# 1337-session' "$rc"; then
    printf '\n%s\n' "$path_line" >> "$rc"
  fi
done

bash "$ROOT/scripts/link-config.sh" "$ROOT/nvim"

if command -v uv >/dev/null 2>&1; then
  uv tool install ty || { echo 'ty installation failed' >&2; failed=1; }
  uv tool install ruff || { echo 'Ruff installation failed' >&2; failed=1; }
else
  echo 'uv not found: Python LSP/formatter must be installed manually' >&2
  failed=1
fi

if ! command -v nvim >/dev/null 2>&1 ||
  ! nvim --clean --headless -c 'if !has("nvim-0.11") | cquit 1 | endif' -c 'qa!' >/dev/null 2>&1; then
  echo 'Neovim 0.11+ is required; plugin bootstrap cannot continue.' >&2
  exit 1
fi

if [ "$NOSYNC" != 1 ]; then
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/1337-macos.XXXXXXXX")"
  trap 'rm -rf "$tmp"' EXIT
  for phase in plugins parsers; do
    log="$tmp/$phase.log"
    if ! env NVIM_APPNAME=nvim XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}" \
       NVIM_BLACK_DOCS_AUTO_UPDATE=0 NVIM_BOOTSTRAP_MODE="$phase" \
       NVIM_BOOTSTRAP_SCRIPT="$ROOT/scripts/nvim-bootstrap.lua" \
       nvim --headless -c 'lua dofile(vim.env.NVIM_BOOTSTRAP_SCRIPT)' >"$log" 2>&1 ||
       ! grep -Fq "BOOTSTRAP PASS: $phase" "$log"; then
      tail -n 15 "$log" >&2
      echo "Neovim $phase bootstrap failed" >&2
      failed=1
    fi
  done
  if ! bash "$ROOT/scripts/update-docs" all; then
    echo 'Offline manual update incomplete (optional).' >&2
  fi
else
  echo 'Skipping plugin/parser sync (--no-sync)'
fi

if ! command -v clangd >/dev/null 2>&1; then
  echo 'Optional C/C++ language server missing: install Xcode Command Line Tools or llvm.' >&2
fi
echo 'Set terminal font to JetBrainsMono Nerd Font, or use NVIM_ASCII_ICONS=1 nvim.'
echo 'Then run: nvim'
exit "$failed"
