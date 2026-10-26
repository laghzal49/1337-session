# Resolve the checkout even when invoked with make -f from another directory.
SESSION_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SESSION_USER_CONFIG_HOME := $(if $(XDG_CONFIG_HOME),$(XDG_CONFIG_HOME),$(HOME)/.config)
SESSION_LOCAL_BIN := $(HOME)/.local/bin
NVIM ?= $(if $(NVIM_BIN),$(NVIM_BIN),$(if $(wildcard $(SESSION_LOCAL_BIN)/nvim),$(SESSION_LOCAL_BIN)/nvim,nvim))
PYTHON ?= python3
INSTALL_FLAGS ?=
NVIM_ARGS ?=
export PATH := $(SESSION_LOCAL_BIN):$(PATH)
export NVIM_BIN := $(NVIM)
export NVIM_APPNAME := nvim
override export XDG_CONFIG_HOME := $(SESSION_ROOT)
export NVIM_BLACK_DOCS_AUTO_UPDATE := 0

.PHONY: all test review bench check workflow spatial reference upgrade integrity-metadata portable runtime media help setup install config cluster run doctor media-build
.DEFAULT_GOAL := help
all: run

## Validate installer portability and backups without network or Neovim
portable:
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/makefile_portability_review.py
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/portable_installer_review.py

## Check runtime portability offline without third-party plugins
runtime:
	@cd "$(SESSION_ROOT)" && "$(NVIM)" --headless -u NONE -l nvim/tests/portable_runtime_review.lua
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/bootstrap_failure_review.py
	@cd "$(SESSION_ROOT)" && "$(NVIM)" --headless -u NONE -l nvim/tests/session_comfort_review.lua
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/recovery_review.py

## Run standalone test suite
test:
	@cd "$(SESSION_ROOT)" && "$(NVIM)" --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/standalone.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"

## Run full UI review suite
review:
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/ui_review.py

## Run startup benchmark
bench:
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/startup_bench.py

## Verify Makefile, completion and buffer workflows
workflow:
	@cd "$(SESSION_ROOT)" && "$(NVIM)" --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/workflow.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"

## Run all test suites
check: portable runtime test workflow spatial reference review upgrade

## Verify navigation feedback, cached symbols, split focus and command suggestions
spatial:
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/spatial_review.py

## Verify documentation, semantic highlights, Markdown and terminal escape
reference:
	@cd "$(SESSION_ROOT)" && "$(NVIM)" --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/deep_docs_review.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"
	@cd "$(SESSION_ROOT)" && "$(NVIM)" --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/smart_docs_review.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"
	@cd "$(SESSION_ROOT)" && "$(NVIM)" --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/docs_lifecycle_review.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/black_deck_review.py --expect-black-deck --compare-baseline nvim/tests/black_deck_before_results.json
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/docs_update_review.py
	@cd "$(SESSION_ROOT)" && "$(NVIM)" --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/semantic_review.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"
	@cd "$(SESSION_ROOT)" && "$(NVIM)" --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/markdown_review.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/terminal_escape_review.py
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/documentation_review.py

## Run strict upgrade regressions in fresh Neovim processes (requires debugpy, ty and Ruff)
upgrade:
	@cd "$(SESSION_ROOT)" && "$(NVIM)" --headless -u NONE -l nvim/tests/python_environment.lua
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/installer_review.py
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/download_integrity_review.py
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/runner_review.py
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/migration_review.py
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/smoke.py

## Inspect official checksum metadata for both Linux architectures (no archives downloaded)
integrity-metadata:
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/download_metadata_review.py

## Verify the installed Rust image/PDF reader and text fallback
media:
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/smoke.py media_review.lua
	@cd "$(SESSION_ROOT)" && "$(PYTHON)" nvim/tests/media_transport_review.py

## Show setup commands without downloading anything or changing configuration.
help:
	@printf '%s\n' '1337-session — portable Neovim setup' '' \
	  'make setup       Install missing tools/config/plugins in ~/.local (no sudo)' \
	  'make cluster     Same user-local setup for a shared Linux cluster' \
	  'make config      Link config only, with backup of the previous config' \
	  'make run         Launch this checkout with the installed Neovim' \
	  'make doctor      Report platform, paths and available tools' \
	  'make media-build Build the Rust image/PDF backend' \
	  'make portable    Run offline installer portability checks' \
	  'make media       Test the installed image/PDF reader' '' \
	  'Overrides: NVIM=/path/to/nvim PYTHON=python3 INSTALL_FLAGS=--no-sync' \
	  'Use TMPDIR=/your/scratch make setup for downloads on scratch storage.'

## Reuse the platform-aware, zero-sudo installer; retain the user's XDG destination.
setup install:
	@cd "$(SESSION_ROOT)" && XDG_CONFIG_HOME="$(SESSION_USER_CONFIG_HOME)" bash ./install.sh $(INSTALL_FLAGS)

cluster: setup

config:
	@cd "$(SESSION_ROOT)" && XDG_CONFIG_HOME="$(SESSION_USER_CONFIG_HOME)" bash ./install.sh --config-only

run:
	@command -v "$(NVIM)" >/dev/null 2>&1 || { printf '%s\n' 'Neovim is missing. Run make setup or set NVIM=/path/to/nvim.' >&2; exit 1; }
	@cd "$(SESSION_ROOT)" && "$(NVIM)" $(NVIM_ARGS)

doctor:
	@printf 'Platform: '; uname -sm
	@printf 'Checkout: %s\nConfig destination: %s/nvim\n' "$(SESSION_ROOT)" "$(SESSION_USER_CONFIG_HOME)"
	@for tool in "$(NVIM)" "$(PYTHON)" git bash rg fd fzf cargo pdfinfo pdftoppm pdftotext; do \
	  if command -v "$$tool" >/dev/null 2>&1; then command -v "$$tool"; \
	  else printf 'Missing: %s\n' "$$tool"; fi; done

media-build:
	@cd "$(SESSION_ROOT)" && "$(NVIM)" --headless -c 'lua local ok,err=pcall(function() require("lazy").load({plugins={"nvim-gfx"}}); local p=assert(require("lazy.core.config").plugins["nvim-gfx"],"media plugin missing"); local result=vim.fn.system({"$(PYTHON)",vim.fn.stdpath("config").."/scripts/build_media.py",p.dir}); print(result); assert(vim.v.shell_error==0,"media build failed") end); if not ok then print(err); vim.cmd("cquit 1") end' -c 'qa!'
