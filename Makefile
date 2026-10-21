NVIM ?= $(if $(NVIM_BIN),$(NVIM_BIN),nvim)
PYTHON ?= python3
export NVIM_BIN := $(NVIM)
export NVIM_APPNAME := nvim
export XDG_CONFIG_HOME := $(CURDIR)
export NVIM_BLACK_DOCS_AUTO_UPDATE := 0

.PHONY: all test review bench check workflow spatial reference upgrade integrity-metadata portable runtime
all: test

## Validate installer portability and backups without network or Neovim
portable:
	$(PYTHON) nvim/tests/portable_installer_review.py

## Check runtime portability offline without third-party plugins
runtime:
	$(NVIM) --headless -u NONE -l nvim/tests/portable_runtime_review.lua
	$(PYTHON) nvim/tests/bootstrap_failure_review.py
	$(NVIM) --headless -u NONE -l nvim/tests/session_comfort_review.lua
	$(PYTHON) nvim/tests/recovery_review.py

## Run standalone test suite
test:
	$(NVIM) --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/standalone.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"

## Run full UI review suite
review:
	$(PYTHON) nvim/tests/ui_review.py

## Run startup benchmark
bench:
	$(PYTHON) nvim/tests/startup_bench.py

## Verify Makefile, completion and buffer workflows
workflow:
	$(NVIM) --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/workflow.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"

## Run all test suites
check: portable runtime test workflow spatial reference review upgrade

## Verify navigation feedback, cached symbols, split focus and command suggestions
spatial:
	$(PYTHON) nvim/tests/spatial_review.py

## Verify documentation, semantic highlights, Markdown and terminal escape
reference:
	$(NVIM) --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/deep_docs_review.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"
	$(NVIM) --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/smart_docs_review.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"
	$(NVIM) --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/docs_lifecycle_review.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"
	$(PYTHON) nvim/tests/black_deck_review.py --expect-black-deck --compare-baseline nvim/tests/black_deck_before_results.json
	$(PYTHON) nvim/tests/docs_update_review.py
	$(NVIM) --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/semantic_review.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"
	$(NVIM) --headless -c "lua local ok, err = pcall(dofile, 'nvim/tests/markdown_review.lua'); if not ok then print(err); vim.cmd('cquit 1') end" -c "qa!"
	$(PYTHON) nvim/tests/terminal_escape_review.py
	$(PYTHON) nvim/tests/documentation_review.py

## Run strict upgrade regressions in fresh Neovim processes (requires debugpy, ty and Ruff)
upgrade:
	$(NVIM) --headless -u NONE -l nvim/tests/python_environment.lua
	$(PYTHON) nvim/tests/installer_review.py
	$(PYTHON) nvim/tests/download_integrity_review.py
	$(PYTHON) nvim/tests/runner_review.py
	$(PYTHON) nvim/tests/migration_review.py
	$(PYTHON) nvim/tests/smoke.py

## Inspect official checksum metadata for both Linux architectures (no archives downloaded)
integrity-metadata:
	$(PYTHON) nvim/tests/download_metadata_review.py
