NVIM ?= nvim
PYTHON ?= python3
export XDG_CONFIG_HOME := $(CURDIR)
export NVIM_BLACK_DOCS_AUTO_UPDATE := 0

.PHONY: all test review bench check workflow spatial reference
all: test

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
check: test workflow spatial reference review

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
