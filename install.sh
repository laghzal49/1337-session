#!/usr/bin/env bash
# ============================================================================
# 1337-session bootstrap — a user-local Neovim environment, ZERO sudo.
# ============================================================================
# Installed tools stay in ~/.local. Downloads and build files use a private
# temporary directory so a small home quota is not consumed twice.
#
#   font      JetBrainsMono Nerd Font (icons for the whole UI)
#   editor    Neovim (latest stable) + this repo's config linked in
#   search    ripgrep, fd, fzf
#   git ui    lazygit  (<leader>gg)
#   node      Node.js LTS (LSP servers / mason packages that need npm)
#   python    uv, ty, Ruff, and isolated debugpy for the Python debugger
#             (+ a managed Python if the system one can't make venvs)
#   parsers   tree-sitter CLI + a `cc` shim via zig if no C compiler exists
#             (nvim-treesitter's main branch compiles grammars with cc)
#   c/c++     clangd language server for C and C++
#   plugins   headless `nvim +Lazy! restore` so the first real launch is instant
#
# Usage:
#   ./install.sh              install everything that's missing
#   ./install.sh --force      reinstall everything
#   ./install.sh --no-sync    skip the headless plugin download at the end
#   ./install.sh --config-only safely link config on Linux/macOS/WSL
#
# Idempotent: safe to re-run; existing tools are skipped unless --force.
# Never calls sudo. Temporary files are removed on exit.
# ============================================================================

set -euo pipefail

FORCE=0
NOSYNC=0
CONFIG_ONLY=0
INSTALL_FAILED=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --no-sync) NOSYNC=1 ;;
    --config-only) CONFIG_ONLY=1 ;;
    --help|-h)
      sed -n '2,22p' "$0"
      exit 0
      ;;
    *) echo "unknown flag: $arg (known: --force --no-sync --config-only --help)" >&2; exit 2 ;;
  esac
done

# ── layout ──────────────────────────────────────────────────────────────────
LOCAL="$HOME/.local"
BIN="$LOCAL/bin"
OPT="$LOCAL/opt"
FONTS="$LOCAL/share/fonts"
umask 077
mkdir -p "$BIN" "$OPT" "$FONTS"
export PATH="$BIN:$PATH" # so later steps see what earlier steps installed

# mktemp creates an unpredictable private directory even on a shared /tmp.
# Honor TMPDIR for machines with a dedicated scratch filesystem.
TMP="$(mktemp -d "${TMPDIR:-/tmp}/1337-session.XXXXXXXX")" \
  || { printf 'could not create private temporary directory\n' >&2; exit 1; }
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

# ── platform and minimal config-only setup ────────────────────────────────
# Full binary archives below are Linux-specific. Homebrew resolves the right
# binaries on Intel/Apple Silicon macOS; --config-only works without any downloads.
PLATFORM="$(uname -s)"
case "$PLATFORM" in
  Linux|Darwin) ;;
  *) die "unsupported system: $PLATFORM. On Windows, use WSL2 (Linux) or install Neovim separately." ;;
esac
if [ "$PLATFORM" = Darwin ] || [ "$CONFIG_ONLY" = 1 ]; then
  SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
  if [ -f "$SOURCE_DIR/nvim/init.lua" ] && [ -f "$SOURCE_DIR/scripts/link-config.sh" ]; then
    REPO_DIR="$SOURCE_DIR"
  else
    REPO_DIR="$HOME/1337-session"
    if [ ! -f "$REPO_DIR/nvim/init.lua" ]; then
      have git || die "git is required to clone the configuration"
      [ ! -e "$REPO_DIR" ] || die "$REPO_DIR exists but is not a valid 1337-session checkout"
      git clone --depth=1 https://github.com/laghzal49/1337-session.git "$REPO_DIR" || die "cannot clone 1337-session"
    fi
  fi
  [ -f "$REPO_DIR/scripts/link-config.sh" ] || die "link-config.sh missing; update the checkout"
  if [ "$CONFIG_ONLY" = 1 ]; then
    bash "$REPO_DIR/scripts/link-config.sh" "$REPO_DIR/nvim"
    exit 0
  fi
  [ -f "$REPO_DIR/scripts/install-macos.sh" ] || die "install-macos.sh missing; update the checkout"
  exec bash "$REPO_DIR/scripts/install-macos.sh" "$@"
fi

# ── downloads ───────────────────────────────────────────────────────────────
fetch() { # fetch <url> <dest-file>
  if have curl; then
    curl --fail --location --proto '=https' --tlsv1.2 \
      --retry 3 --retry-delay 2 --progress-bar -o "$2" "$1"
  else
    wget --https-only --no-verbose --tries=3 -O "$2" "$1"
  fi
}

fetch_verified() { # fetch_verified <url> <dest> <published-sha256>
  fetch "$1" "$2" || return 1
  if ! python3 "$REPO_DIR/scripts/download-integrity.py" verify "$2" "$3"; then
    rm -f "$2"
    return 1
  fi
}
fetch_release() { # fetch_release <owner/repo> <tag-or-latest> <asset> <dest>
  local repo="$1" tag="$2" asset="$3" dest="$4" endpoint metadata details expected
  local -a fields
  endpoint="tags/$tag"
  [ "$tag" != latest ] || endpoint=latest
  metadata="$TMP/${repo//\//-}-release.json"
  fetch "https://api.github.com/repos/$repo/releases/$endpoint" "$metadata" || return 1
  details="$(python3 "$REPO_DIR/scripts/download-integrity.py" github "$metadata" "$repo" "$asset")" || return 1
  mapfile -t fields <<< "$details"
  expected="${fields[1]}"
  if [ -z "$expected" ]; then
    fetch "${fields[2]}" "$dest.checksums" || return 1
    expected="$(python3 "$REPO_DIR/scripts/download-integrity.py" checksum "$dest.checksums" "$asset" "${fields[3]}")" || return 1
  fi
  fetch_verified "${fields[0]}" "$dest" "$expected"
}

# latest release tag of a GitHub repo, via the /releases/latest redirect
# (no API call, so no rate limits)
gh_tag() { # gh_tag <owner/repo>
  if have curl; then
    curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
      --head -o /dev/null -w '%{url_effective}' \
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
           A_ZIG="x86_64"; A_UV="x86_64-unknown-linux-musl" ;;
  aarch64) A_NVIM="arm64"; A_RG="aarch64-unknown-linux-gnu"
           A_FD="aarch64-unknown-linux-musl"; A_FZF="linux_arm64"
           A_LG="linux_arm64"; A_NODE="linux-arm64"; A_TS="linux-arm64"
           A_ZIG="aarch64"; A_UV="aarch64-unknown-linux-musl" ;;
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

# Locate the repository helpers before downloading tool archives.
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
have python3 || die "python3 is required to verify release checksums"
[ -f "$REPO_DIR/scripts/download-integrity.py" ] || die "checksum helper missing — update the repository checkout before installing"

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
PATH_LINE="export PATH=\"\$HOME/.local/bin:\$PATH\" # 1337-session"
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
if [ -e "$FONTS/JetBrainsMonoNerdFontMono-Regular.ttf" ] \
    && [ -e "$FONTS/JetBrainsMonoNerdFontMono-Bold.ttf" ] \
    && [ -e "$FONTS/JetBrainsMonoNerdFontMono-Italic.ttf" ] \
    && [ -e "$FONTS/JetBrainsMonoNerdFontMono-BoldItalic.ttf" ] && [ "$FORCE" = 0 ]; then
  skip "JetBrainsMono Nerd Font"
else
  if fetch_release ryanoasis/nerd-fonts latest JetBrainsMono.tar.xz "$TMP/font.tar.xz" \
      && tar -C "$FONTS" -xJf "$TMP/font.tar.xz" 2>/dev/null; then
    :
  else
    # xz missing or asset shape changed — fall back to the zip
    warn "tar.xz route failed, trying zip"
    fetch_release ryanoasis/nerd-fonts latest JetBrainsMono.zip "$TMP/font.zip"
    if have unzip; then unzip -oq "$TMP/font.zip" -d "$FONTS"
    else die "need either xz or unzip to extract the font"; fi
  fi
  have fc-cache && fc-cache -f "$FONTS" >/dev/null 2>&1 || true
  ok "JetBrainsMono Nerd Font → ~/.local/share/fonts"
fi

# ============================================================================
step "3/10 · Neovim (latest stable)"
# ============================================================================
if [ "$FORCE" = 1 ] || ! have nvim || ! nvim --clean --headless \
    -c 'if !has("nvim-0.11") | cquit 1 | endif' -c qa >/dev/null 2>&1; then
  fetch_release neovim/neovim latest "nvim-linux-${A_NVIM}.tar.gz" "$TMP/nvim.tar.gz"
  rm -rf "$OPT/nvim-linux-${A_NVIM}"
  tar -C "$OPT" -xzf "$TMP/nvim.tar.gz"
  ln -sf "$OPT/nvim-linux-${A_NVIM}/bin/nvim" "$BIN/nvim"
  ok "$("$BIN/nvim" --version | head -1) → ~/.local/bin/nvim"
else
  skip "Neovim (0.11 or newer)"
fi

# ============================================================================
step "4/10 · search tools — ripgrep · fd · fzf"
# ============================================================================
if want rg; then
  RG_TAG="$(gh_tag BurntSushi/ripgrep)" # tags have no v prefix
  fetch_release BurntSushi/ripgrep "$RG_TAG" "ripgrep-${RG_TAG}-${A_RG}.tar.gz" "$TMP/rg.tar.gz"
  tar -C "$TMP" -xzf "$TMP/rg.tar.gz"
  install -m755 "$TMP/ripgrep-${RG_TAG}-${A_RG}/rg" "$BIN/rg"
  ok "ripgrep $RG_TAG"
fi
if want fd; then
  FD_TAG="$(gh_tag sharkdp/fd)" # tags look like v10.2.0
  fetch_release sharkdp/fd "$FD_TAG" "fd-${FD_TAG}-${A_FD}.tar.gz" "$TMP/fd.tar.gz"
  tar -C "$TMP" -xzf "$TMP/fd.tar.gz"
  install -m755 "$TMP/fd-${FD_TAG}-${A_FD}/fd" "$BIN/fd"
  ok "fd $FD_TAG"
fi
if want fzf; then
  FZF_TAG="$(gh_tag junegunn/fzf)" # v0.60.0 → asset uses 0.60.0
  fetch_release junegunn/fzf "$FZF_TAG" "fzf-${FZF_TAG#v}-${A_FZF}.tar.gz" "$TMP/fzf.tar.gz"
  tar -C "$TMP" -xzf "$TMP/fzf.tar.gz"
  install -m755 "$TMP/fzf" "$BIN/fzf"
  ok "fzf $FZF_TAG"
fi

# ============================================================================
step "5/10 · lazygit (<leader>gg)"
# ============================================================================
if want lazygit; then
  LG_TAG="$(gh_tag jesseduffield/lazygit)" # v0.45.0 → asset uses 0.45.0
  fetch_release jesseduffield/lazygit "$LG_TAG" "lazygit_${LG_TAG#v}_${A_LG}.tar.gz" "$TMP/lg.tar.gz"
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
  fetch "https://nodejs.org/dist/${NODE_V}/SHASUMS256.txt" "$TMP/node-checksums.txt"
  NODE_SHA="$(python3 "$REPO_DIR/scripts/download-integrity.py" checksum "$TMP/node-checksums.txt" "node-${NODE_V}-${A_NODE}.tar.gz")"
  fetch_verified "https://nodejs.org/dist/${NODE_V}/node-${NODE_V}-${A_NODE}.tar.gz" "$TMP/node.tar.gz" "$NODE_SHA"
  rm -rf "$OPT/node-${NODE_V}-${A_NODE}"
  tar -C "$OPT" -xzf "$TMP/node.tar.gz"
  for b in node npm npx; do
    ln -sf "$OPT/node-${NODE_V}-${A_NODE}/bin/$b" "$BIN/$b"
  done
  ok "node $NODE_V (+ npm, npx)"
fi
if have node && have npm && have npx; then
  ok "node/npm/npx are on PATH for Mason packages"
elif have node; then
  warn "Node is installed but npm or npx is missing; Mason npm packages may fail"
fi

# ============================================================================
step "7/10 · Python tooling — uv (+ venv capability for mason)"
# ============================================================================
if want uv; then
  if fetch_release astral-sh/uv latest "uv-${A_UV}.tar.gz" "$TMP/uv.tar.gz" \
      && tar -C "$TMP" -xzf "$TMP/uv.tar.gz" \
      && install -m755 "$TMP/uv-${A_UV}/uv" "$TMP/uv-${A_UV}/uvx" "$BIN/"; then
    ok "uv $(uv --version 2>/dev/null | awk '{print $2}')"
  else
    warn "uv download or checksum verification failed"
  fi
fi
# Install the Python language server without sudo; uv places its executable in ~/.local/bin.
if want ty; then
  if have uv && uv tool install --no-cache ty >/dev/null 2>&1; then
    ok "ty language server"
  else
    warn "ty installation failed — run: uv tool install ty"
  fi
fi
if want ruff; then
  if have uv && uv tool install --no-cache ruff >/dev/null 2>&1; then
    ok "Ruff linter and formatter"
  else
    warn "Ruff installation failed — run: uv tool install ruff"
  fi
fi
if have ty; then
  ok "ty $(ty --version 2>/dev/null | head -1)"
else
  warn "ty is not on PATH; Python type diagnostics will be unavailable"
fi
if have ruff; then
  ok "ruff $(ruff --version 2>/dev/null | head -1)"
else
  warn "Ruff is not on PATH; Python linting and formatting will be unavailable"
fi
# mason builds venvs for its Python packages — Ubuntu without sudo
# often lacks python3-venv, so hand mason a Python that can do it
if python3 -m venv "$TMP/venv-probe" >/dev/null 2>&1; then
  ok "system python3 can create venvs"
elif have uv; then
  uv python install --default --preview >/dev/null 2>&1 \
    || uv python install --default >/dev/null 2>&1 \
    || warn "couldn't install a managed Python — mason's pip packages may fail (fix: apt install python3-venv)"
  if [ -d "$HOME/.local/share/uv/python" ]; then
    ok "uv-managed Python installed for user-local tooling"
  else
    warn "uv installed but no managed Python was found"
  fi
else
  warn "no venv-capable python3 and no uv — mason's pip packages may fail"
fi

# The DAP adapter looks in Neovim's data directory first. Keep its Python
# separate from projects and honor XDG_DATA_HOME like vim.fn.stdpath('data').
DEBUGPY_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/debugpy"
DEBUGPY_PYTHON="$DEBUGPY_DIR/bin/python"
if [ "$FORCE" = 0 ] && [ -x "$DEBUGPY_PYTHON" ] \
    && "$DEBUGPY_PYTHON" -c 'import debugpy.adapter' >/dev/null 2>&1; then
  skip "debugpy (isolated Neovim debugger adapter)"
elif have uv; then
  DEBUGPY_PIP_FLAGS=(--no-cache --link-mode copy)
  if [ "$FORCE" = 1 ]; then DEBUGPY_PIP_FLAGS+=(--reinstall-package debugpy --upgrade); fi
  if uv venv --allow-existing "$DEBUGPY_DIR" >"$TMP/debugpy-install.log" 2>&1 \
      && uv pip install "${DEBUGPY_PIP_FLAGS[@]}" --python "$DEBUGPY_PYTHON" debugpy >>"$TMP/debugpy-install.log" 2>&1 \
      && "$DEBUGPY_PYTHON" -c 'import debugpy.adapter' >>"$TMP/debugpy-install.log" 2>&1; then
    ok "debugpy adapter → ${DEBUGPY_DIR/#$HOME/~}"
  else
    tail -n 12 "$TMP/debugpy-install.log" >&2
    warn "debugpy installation failed; Python debugging needs: uv venv --allow-existing '$DEBUGPY_DIR' && uv pip install --python '$DEBUGPY_PYTHON' debugpy"
    INSTALL_FAILED=1
  fi
else
  warn "uv is unavailable; cannot install the default Python debugger adapter"
  INSTALL_FAILED=1
fi

# ============================================================================
step "8/10 · treesitter & C/C++ toolchain — tree-sitter · cc · clangd"
# ============================================================================
if want tree-sitter; then
  TS_TAG="$(gh_tag tree-sitter/tree-sitter)"
  fetch_release tree-sitter/tree-sitter "$TS_TAG" "tree-sitter-${A_TS}.gz" "$TMP/ts.gz"
  gunzip -f "$TMP/ts.gz"
  install -m755 "$TMP/ts" "$BIN/tree-sitter"
  ok "tree-sitter CLI $TS_TAG"
fi
# grammars compile with `cc` — if the box has none, shim one from zig
# (a single user-space tarball that bundles a full C compiler, no sudo)
if have cc; then
  ok "C compiler present ($(command -v cc))"
elif have gcc || have clang; then
  COMPILER="$(command -v gcc || command -v clang)"
  ln -sfn "$COMPILER" "$BIN/cc"
  ok "no cc command — linked compiler $COMPILER as ~/.local/bin/cc"
else
  ZIG_V="0.14.0" # pinned: 0.14.x is the last release with this asset naming
  if fetch "https://ziglang.org/download/index.json" "$TMP/zig-index.json" \
      && ZIG_INFO="$(python3 "$REPO_DIR/scripts/download-integrity.py" zig "$TMP/zig-index.json" "$ZIG_V" "$A_ZIG")" \
      && fetch_verified "${ZIG_INFO%%$'\n'*}" "$TMP/zig.tar.xz" "${ZIG_INFO#*$'\n'}" \
      && tar -C "$OPT" -xJf "$TMP/zig.tar.xz" 2>/dev/null; then
    printf '#!/bin/sh\nexec "%s/zig-linux-%s-%s/zig" cc "$@"\n' "$OPT" "$A_ZIG" "$ZIG_V" > "$BIN/cc"
    chmod +x "$BIN/cc"
    ok "no system compiler — installed zig ${ZIG_V} and shimmed it as cc"
  else
    warn "no C compiler and zig download failed — :TSInstall won't compile grammars (fix: apt install build-essential)"
  fi
fi
if want clangd; then
  if [ "$A_NVIM" = "x86_64" ]; then
    CLANGD_TAG="$(gh_tag clangd/clangd)"
    if fetch_release clangd/clangd "$CLANGD_TAG" "clangd-linux-${CLANGD_TAG}.zip" "$TMP/clangd.zip" \
        && unzip -oq "$TMP/clangd.zip" -d "$OPT" 2>/dev/null; then
      ln -sf "$OPT/clangd_${CLANGD_TAG}/bin/clangd" "$BIN/clangd"
      ok "clangd $CLANGD_TAG → ~/.local/bin/clangd"
    else
      warn "clangd release download failed — C/C++ LSP requires clangd on PATH"
    fi
  else
    warn "clangd prebuilt releases only available for x86_64 — install clangd via system package manager"
  fi
fi
if have clangd; then
  ok "clangd $(clangd --version 2>/dev/null | head -1)"
else
  warn "clangd is not on PATH; C/C++ language server will be unavailable"
fi

# ============================================================================
step "9/10 · this repo's Neovim config → XDG config home"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
bash "$REPO_DIR/scripts/link-config.sh" "$REPO_DIR/nvim" || die "could not link Neovim configuration"
ok "$CONFIG_HOME/nvim → ${REPO_DIR/#$HOME/~}/nvim"

# ============================================================================
step "10/10 · preinstall pinned plugins and parsers"
# ============================================================================
if [ "$NOSYNC" = 1 ]; then
  printf '%s  ↷ skipped (--no-sync)%s\n' "$C_DIM" "$C_OFF"
elif have nvim; then
  run_nvim_phase() {
    local phase="$1" log="$TMP/nvim-$1.log"
    local -a command=(nvim --headless -c 'lua dofile(vim.env.NVIM_BOOTSTRAP_SCRIPT)')
    if have timeout; then command=(timeout 900 "${command[@]}"); fi
    if env NVIM_APPNAME=nvim XDG_CONFIG_HOME="$CONFIG_HOME" XDG_CACHE_HOME="$TMP/nvim-cache" \
        TMPDIR="$TMP" NVIM_BLACK_DOCS_AUTO_UPDATE=0 \
        NVIM_BOOTSTRAP_MODE="$phase" NVIM_BOOTSTRAP_SCRIPT="$REPO_DIR/scripts/nvim-bootstrap.lua" \
        "${command[@]}" >"$log" 2>&1 \
        && grep -Fq "BOOTSTRAP PASS: $phase" "$log"; then
      return 0
    fi
    tail -n 12 "$log" >&2
    return 1
  }
  if run_nvim_phase plugins; then
    ok "pinned plugins installed and restore tasks verified"
  else
    warn "plugin restore failed — review errors above and rerun the installer"
    INSTALL_FAILED=1
  fi
  if run_nvim_phase parsers; then
    ok "syntax parsers installed, updated and query-compatible"
  else
    warn "parser setup incomplete — review errors above; run :TSUpdate python c cpp lua vim vimdoc query markdown markdown_inline"
    INSTALL_FAILED=1
  fi
fi

# ── offline reference manuals (optional network setup) ────────────────────
if [ "$NOSYNC" != 1 ]; then
  if have uv; then
    if bash "$REPO_DIR/scripts/update-docs" all; then
      ok "offline reference manuals installed"
    else
      warn "offline manuals incomplete — rerun scripts/update-docs all when online"
    fi
  else
    warn "uv unavailable — run scripts/update-docs all after installing uv"
  fi
fi

# ── clipboard note (informational only — needs no install) ─────────────────
if ! have xclip && ! have wl-copy; then
  warn "no xclip/wl-clipboard — Neovim will use OSC52 (works in modern terminals over SSH too)"
fi

# ============================================================================
if [ "$INSTALL_FAILED" = 1 ]; then
  printf '\n%s━━━ setup incomplete ━━━%s\n\n' "$C_RED" "$C_OFF"
else
  printf '\n%s━━━ done ━━━%s\n\n' "$C_GREEN" "$C_OFF"
fi
printf '  next steps:\n'
printf '   1. restart your terminal (or: source ~/.bashrc)\n'
printf '   2. set your terminal font to %sJetBrainsMono Nerd Font Mono, Regular, 13pt%s\n' "$C_CYAN" "$C_OFF"
printf '   3. run %snvim%s — mason finishes the language tools on first launch\n' "$C_CYAN" "$C_OFF"
if [ "${#WARNINGS[@]}" -gt 0 ]; then
  printf '\n  warnings to review:\n'
  for w in "${WARNINGS[@]}"; do printf '   %s! %s%s\n' "$C_YELLOW" "$w" "$C_OFF"; done
fi
printf '\n'

# Core setup failures must propagate to callers; optional-tool warnings remain advisory.
if [ "$INSTALL_FAILED" = 1 ]; then exit 1; fi
