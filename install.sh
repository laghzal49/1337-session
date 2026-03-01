#!/usr/bin/env bash
# ============================================================================
# 1337-session bootstrap — a COMPLETE dev environment on Ubuntu, ZERO sudo.
# ============================================================================
# Everything installs into ~/.local from official prebuilt release binaries:
#
#   font      JetBrainsMono Nerd Font (icons for the whole UI)
#   editor    Neovim (latest stable) + this repo's config linked in
#   search    ripgrep, fd, fzf
#   git ui    lazygit  (<leader>gg in LazyVim)
#   node      Node.js LTS (LSP servers / mason packages that need npm)
#   python    uv (+ a managed Python if the system one can't make venvs —
#             mason needs `python3 -m venv` for basedpyright/mypy/debugpy)
#   parsers   tree-sitter CLI + a `cc` shim via zig if no C compiler exists
#             (nvim-treesitter's main branch compiles grammars with cc)
#   plugins   headless `nvim +Lazy! sync` so the first real launch is instant
#
# Usage:
#   ./install.sh              install everything that's missing
#   ./install.sh --force      reinstall everything
#   ./install.sh --no-sync    skip the headless plugin download at the end
#
# Idempotent: safe to re-run; existing tools are skipped unless --force.
# Never calls sudo. Never touches anything outside $HOME.
# ============================================================================

set -euo pipefail

FORCE=0
NOSYNC=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --no-sync) NOSYNC=1 ;;
    *) echo "unknown flag: $arg (known: --force --no-sync)" >&2; exit 2 ;;
  esac
done

# ── layout ──────────────────────────────────────────────────────────────────
LOCAL="$HOME/.local"
BIN="$LOCAL/bin"
OPT="$LOCAL/opt"
FONTS="$LOCAL/share/fonts"
mkdir -p "$BIN" "$OPT" "$FONTS"
export PATH="$BIN:$PATH" # so later steps see what earlier steps installed

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ── pretty logging ──────────────────────────────────────────────────────────
if [ -t 1 ]; then
  C_CYAN=$'\033[1;36m'; C_GREEN=$'\033[1;32m'; C_YELLOW=$'\033[1;33m'
  C_RED=$'\033[1;31m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else
  C_CYAN=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_DIM=""; C_OFF=""
fi
step() { printf '\n%s▸ %s%s\n' "$C_CYAN" "$*" "$C_OFF"; }
ok()   { printf '%s  ✓ %s%s\n' "$C_GREEN" "$*" "$C_OFF"; }
skip() { printf '%s  ↷ %s (already installed — use --force to redo)%s\n' "$C_DIM" "$*" "$C_OFF"; }
warn() { printf '%s  ! %s%s\n' "$C_YELLOW" "$*" "$C_OFF"; WARNINGS+=("$*"); }
die()  { printf '%s  ✗ %s%s\n' "$C_RED" "$*" "$C_OFF"; exit 1; }
WARNINGS=()

have() { command -v "$1" >/dev/null 2>&1; }

# fresh install wanted? (0 = yes, install it)
want() { # want <command>
  if [ "$FORCE" = 1 ]; then return 0; fi
  if have "$1"; then skip "$1"; return 1; fi
  return 0
}

# ── downloads ───────────────────────────────────────────────────────────────
fetch() { # fetch <url> <dest-file>
  if have curl; then
    curl -fL --retry 3 --retry-delay 2 --progress-bar -o "$2" "$1"
  else
    wget -q --show-progress --tries=3 -O "$2" "$1"
  fi
}

# latest release tag of a GitHub repo, via the /releases/latest redirect
# (no API call, so no rate limits)
gh_tag() { # gh_tag <owner/repo>
  if have curl; then
    curl -fsSLI -o /dev/null -w '%{url_effective}' \
      "https://github.com/$1/releases/latest" | sed 's|.*/tag/||'
  else
    wget -q --max-redirect=10 --server-response --spider \
      "https://github.com/$1/releases/latest" 2>&1 |
      sed -n 's|.*Location: .*/tag/\([^[:space:]]*\).*|\1|p' | tail -1
  fi
}

# ── arch detection ──────────────────────────────────────────────────────────
case "$(uname -m)" in
  x86_64)  A_NVIM="x86_64"; A_RG="x86_64-unknown-linux-musl"
           A_FD="x86_64-unknown-linux-musl"; A_FZF="linux_amd64"
           A_LG="linux_x86_64"; A_NODE="linux-x64"; A_TS="linux-x64"
           A_ZIG="x86_64" ;;
  aarch64) A_NVIM="arm64"; A_RG="aarch64-unknown-linux-gnu"
           A_FD="aarch64-unknown-linux-musl"; A_FZF="linux_arm64"
           A_LG="linux_arm64"; A_NODE="linux-arm64"; A_TS="linux-arm64"
           A_ZIG="aarch64" ;;
  *) die "unsupported architecture: $(uname -m) (x86_64 / aarch64 only)" ;;
esac

# ============================================================================
step "0/10 · prerequisites"
# ============================================================================
have curl || have wget || die "need curl or wget to download anything"
have tar || die "need tar (present on every Ubuntu)"
have gzip || die "need gzip (present on every Ubuntu)"
if have git; then
  ok "git $(git --version | awk '{print $3}')"
else
  # git can't be user-installed sanely (needs its template/exec dirs); it's
  # the one thing that genuinely requires apt — but it ships in every Ubuntu
  # cloud/desktop image, so this should never fire.
  die "git is missing and can't be installed without sudo — ask an admin for: apt install git"
fi

# mason unpacks some of its packages from .zip (stylua) and .tar.xz
# (shellcheck), and the Nerd Font ships as .tar.xz — but minimal Ubuntu
# images often lack unzip/xz, and neither can be installed without sudo.
# python3 (always present) can do both jobs, so shim them when missing.
if ! have unzip && have python3; then
  cat > "$BIN/unzip" <<'UNZIP_SHIM'
#!/bin/sh
# unzip shim via python3 zipfile (no-sudo fallback).
# Supports the common form: unzip [-o] [-q] ARCHIVE [-d DIR]
exec python3 - "$@" <<'PYEOF'
import os, sys, zipfile
args, dest, src, i = sys.argv[1:], ".", None, 0
while i < len(args):
    a = args[i]
    if a == "-d" and i + 1 < len(args):
        i += 1
        dest = args[i]
    elif not a.startswith("-") and src is None:
        src = a
    i += 1
if src is None:
    sys.exit("unzip shim: no archive given")
with zipfile.ZipFile(src) as z:
    z.extractall(dest)
    for info in z.infolist():  # zipfile drops exec bits; restore them
        mode = info.external_attr >> 16
        if mode:
            os.chmod(os.path.join(dest, info.filename), mode)
PYEOF
UNZIP_SHIM
  chmod +x "$BIN/unzip"
  ok "no system unzip — shimmed via python3 (exec bits preserved)"
fi
if ! have xz && have python3; then
  cat > "$BIN/xz" <<'XZ_SHIM'
#!/bin/sh
# xz shim via python3 lzma (no-sudo fallback): decompress-only, stdin→stdout
# — exactly the way tar -xJf invokes it.
for a in "$@"; do
  case "$a" in
    -d|--decompress|-dc|-cd|-dk|-T0) DEC=1 ;;
  esac
done
if [ "${DEC:-0}" = 1 ]; then
  exec python3 -c 'import sys,lzma,shutil; shutil.copyfileobj(lzma.LZMAFile(sys.stdin.buffer), sys.stdout.buffer)'
fi
echo "xz shim: only decompression (-d) from stdin is supported" >&2
exit 1
XZ_SHIM
  chmod +x "$BIN/xz"
  ok "no system xz — shimmed via python3 lzma"
fi
have python3 || warn "python3 missing (very unusual for Ubuntu) — mason's pip tools and the unzip/xz shims need it"

# ============================================================================
step "1/10 · PATH — ~/.local/bin in every future shell"
# ============================================================================
PATH_LINE='export PATH="$HOME/.local/bin:$PATH" # 1337-session'
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rc" ] && ! grep -qs '# 1337-session' "$rc"; then
    printf '\n%s\n' "$PATH_LINE" >> "$rc"
    ok "added to ${rc/#$HOME/~}"
  fi
done
# make sure at least bashrc exists and carries it
if [ ! -f "$HOME/.bashrc" ]; then
  printf '%s\n' "$PATH_LINE" > "$HOME/.bashrc"
  ok "created ~/.bashrc"
fi

# ============================================================================
step "2/10 · JetBrainsMono Nerd Font (the UI's icons)"
# ============================================================================
if [ -e "$FONTS/JetBrainsMonoNerdFont-Regular.ttf" ] && [ "$FORCE" = 0 ]; then
  skip "JetBrainsMono Nerd Font"
else
  if fetch "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" "$TMP/font.tar.xz" \
      && tar -C "$FONTS" -xJf "$TMP/font.tar.xz" 2>/dev/null; then
    :
  else
    # xz missing or asset shape changed — fall back to the zip
    warn "tar.xz route failed, trying zip"
    fetch "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" "$TMP/font.zip"
    if have unzip; then unzip -oq "$TMP/font.zip" -d "$FONTS"
    else die "need either xz or unzip to extract the font"; fi
  fi
  have fc-cache && fc-cache -f "$FONTS" >/dev/null 2>&1 || true
  ok "JetBrainsMono Nerd Font → ~/.local/share/fonts"
fi

# ============================================================================
step "3/10 · Neovim (latest stable)"
# ============================================================================
if want nvim; then
  fetch "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${A_NVIM}.tar.gz" "$TMP/nvim.tar.gz"
  rm -rf "$OPT/nvim-linux-${A_NVIM}"
  tar -C "$OPT" -xzf "$TMP/nvim.tar.gz"
  ln -sf "$OPT/nvim-linux-${A_NVIM}/bin/nvim" "$BIN/nvim"
  ok "$("$BIN/nvim" --version | head -1) → ~/.local/bin/nvim"
fi

# ============================================================================
step "4/10 · search tools — ripgrep · fd · fzf"
# ============================================================================
if want rg; then
  RG_TAG="$(gh_tag BurntSushi/ripgrep)" # tags have no v prefix
  fetch "https://github.com/BurntSushi/ripgrep/releases/download/${RG_TAG}/ripgrep-${RG_TAG}-${A_RG}.tar.gz" "$TMP/rg.tar.gz"
  tar -C "$TMP" -xzf "$TMP/rg.tar.gz"
  install -m755 "$TMP/ripgrep-${RG_TAG}-${A_RG}/rg" "$BIN/rg"
  ok "ripgrep $RG_TAG"
fi
if want fd; then
  FD_TAG="$(gh_tag sharkdp/fd)" # tags look like v10.2.0
  fetch "https://github.com/sharkdp/fd/releases/download/${FD_TAG}/fd-${FD_TAG}-${A_FD}.tar.gz" "$TMP/fd.tar.gz"
  tar -C "$TMP" -xzf "$TMP/fd.tar.gz"
  install -m755 "$TMP/fd-${FD_TAG}-${A_FD}/fd" "$BIN/fd"
  ok "fd $FD_TAG"
fi
if want fzf; then
  FZF_TAG="$(gh_tag junegunn/fzf)" # v0.60.0 → asset uses 0.60.0
  fetch "https://github.com/junegunn/fzf/releases/download/${FZF_TAG}/fzf-${FZF_TAG#v}-${A_FZF}.tar.gz" "$TMP/fzf.tar.gz"
  tar -C "$TMP" -xzf "$TMP/fzf.tar.gz"
  install -m755 "$TMP/fzf" "$BIN/fzf"
  ok "fzf $FZF_TAG"
fi

# ============================================================================
step "5/10 · lazygit (LazyVim's <leader>gg)"
# ============================================================================
if want lazygit; then
  LG_TAG="$(gh_tag jesseduffield/lazygit)" # v0.45.0 → asset uses 0.45.0
  fetch "https://github.com/jesseduffield/lazygit/releases/download/${LG_TAG}/lazygit_${LG_TAG#v}_${A_LG}.tar.gz" "$TMP/lg.tar.gz"
  tar -C "$TMP" -xzf "$TMP/lg.tar.gz" lazygit
  install -m755 "$TMP/lazygit" "$BIN/lazygit"
  ok "lazygit $LG_TAG"
fi

# ============================================================================
step "6/10 · Node.js LTS (mason/LSP packages that need npm)"
# ============================================================================
if want node; then
  # first row of index.tab whose LTS column isn't "-" = newest LTS
  NODE_V="$(fetch "https://nodejs.org/dist/index.tab" "$TMP/node-index.tab" >/dev/null 2>&1 \
    && awk -F'\t' 'NR>1 && $10 != "-" {print $1; exit}' "$TMP/node-index.tab")"
  [ -n "$NODE_V" ] || die "couldn't resolve the Node.js LTS version"
  fetch "https://nodejs.org/dist/${NODE_V}/node-${NODE_V}-${A_NODE}.tar.gz" "$TMP/node.tar.gz"
  rm -rf "$OPT/node-${NODE_V}-${A_NODE}"
  tar -C "$OPT" -xzf "$TMP/node.tar.gz"
  for b in node npm npx; do
    ln -sf "$OPT/node-${NODE_V}-${A_NODE}/bin/$b" "$BIN/$b"
  done
  ok "node $NODE_V (+ npm, npx)"
fi

# ============================================================================
step "7/10 · Python tooling — uv (+ venv capability for mason)"
# ============================================================================
if want uv; then
  fetch "https://astral.sh/uv/install.sh" "$TMP/uv-install.sh"
  env UV_NO_MODIFY_PATH=1 UV_INSTALL_DIR="$BIN" sh "$TMP/uv-install.sh" >/dev/null 2>&1 \
    || sh "$TMP/uv-install.sh" >/dev/null 2>&1 || warn "uv installer failed"
  have uv && ok "uv $(uv --version 2>/dev/null | awk '{print $2}')"
fi
# mason builds venvs for basedpyright/mypy/debugpy — Ubuntu without sudo
# often lacks python3-venv, so hand mason a Python that can do it
if python3 -m venv "$TMP/venv-probe" >/dev/null 2>&1; then
  ok "system python3 can create venvs"
elif have uv; then
  uv python install --default --preview >/dev/null 2>&1 \
    || uv python install --default >/dev/null 2>&1 \
    || warn "couldn't install a managed Python — mason's pip packages may fail (fix: apt install python3-venv)"
  have python3 && ok "uv-managed Python shimmed into ~/.local/bin"
else
  warn "no venv-capable python3 and no uv — mason's pip packages may fail"
fi

# ============================================================================
step "8/10 · treesitter toolchain — CLI + C compiler"
# ============================================================================
if want tree-sitter; then
  TS_TAG="$(gh_tag tree-sitter/tree-sitter)"
  fetch "https://github.com/tree-sitter/tree-sitter/releases/download/${TS_TAG}/tree-sitter-${A_TS}.gz" "$TMP/ts.gz"
  gunzip -f "$TMP/ts.gz"
  install -m755 "$TMP/ts" "$BIN/tree-sitter"
  ok "tree-sitter CLI $TS_TAG"
fi
# grammars compile with `cc` — if the box has none, shim one from zig
# (a single user-space tarball that bundles a full C compiler, no sudo)
if have cc || have gcc || have clang; then
  ok "C compiler present ($(command -v cc || command -v gcc || command -v clang))"
else
  ZIG_V="0.14.0" # pinned: 0.14.x is the last release with this asset naming
  if fetch "https://ziglang.org/download/${ZIG_V}/zig-linux-${A_ZIG}-${ZIG_V}.tar.xz" "$TMP/zig.tar.xz" \
      && tar -C "$OPT" -xJf "$TMP/zig.tar.xz" 2>/dev/null; then
    printf '#!/bin/sh\nexec "%s/zig-linux-%s-%s/zig" cc "$@"\n' "$OPT" "$A_ZIG" "$ZIG_V" > "$BIN/cc"
    chmod +x "$BIN/cc"
    ok "no system compiler — installed zig ${ZIG_V} and shimmed it as cc"
  else
    warn "no C compiler and zig download failed — :TSInstall won't compile grammars (fix: apt install build-essential)"
  fi
fi

# ============================================================================
step "9/10 · this repo's Neovim config → ~/.config/nvim"
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [ -d "$SCRIPT_DIR/nvim" ]; then
  REPO_DIR="$SCRIPT_DIR"
else
  # running via `curl | bash` — grab the repo first
  REPO_DIR="$HOME/1337-session"
  if [ ! -d "$REPO_DIR/.git" ]; then
    git clone --depth=1 "https://github.com/laghzal49/1337-session.git" "$REPO_DIR"
  fi
fi
mkdir -p "$HOME/.config"
if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  BAK="$HOME/.config/nvim.bak.$(date +%Y%m%d%H%M%S)"
  mv "$HOME/.config/nvim" "$BAK"
  warn "existing ~/.config/nvim moved to ${BAK/#$HOME/~}"
fi
ln -sfn "$REPO_DIR/nvim" "$HOME/.config/nvim"
ok "~/.config/nvim → ${REPO_DIR/#$HOME/~}/nvim"

# ============================================================================
step "10/10 · preinstall plugins (headless) — first launch is instant"
# ============================================================================
if [ "$NOSYNC" = 1 ]; then
  printf '%s  ↷ skipped (--no-sync)%s\n' "$C_DIM" "$C_OFF"
elif have nvim; then
  if have timeout; then
    timeout 900 nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 \
      && ok "plugins installed" \
      || warn "headless plugin sync didn't finish — first nvim launch will finish it"
  else
    nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 \
      && ok "plugins installed" \
      || warn "headless plugin sync didn't finish — first nvim launch will finish it"
  fi
  # mason installs its tools (ruff, basedpyright, mypy, stylua, …) in the
  # background on the first real launch; nothing to do here
fi

# ── clipboard note (informational only — needs no install) ─────────────────
if ! have xclip && ! have wl-copy; then
  warn "no xclip/wl-clipboard — Neovim will use OSC52 (works in modern terminals over SSH too)"
fi

# ============================================================================
printf '\n%s━━━ done ━━━%s\n\n' "$C_GREEN" "$C_OFF"
printf '  next steps:\n'
printf '   1. restart your terminal (or: source ~/.bashrc)\n'
printf '   2. set your terminal font to %sJetBrainsMono Nerd Font%s\n' "$C_CYAN" "$C_OFF"
printf '   3. run %snvim%s — mason finishes the language tools on first launch\n' "$C_CYAN" "$C_OFF"
if [ "${#WARNINGS[@]}" -gt 0 ]; then
  printf '\n  warnings to review:\n'
  for w in "${WARNINGS[@]}"; do printf '   %s! %s%s\n' "$C_YELLOW" "$w" "$C_OFF"; done
fi
printf '\n'
