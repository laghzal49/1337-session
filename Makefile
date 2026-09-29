NVIM ?= nvim
PYTHON ?= python3
export XDG_CONFIG_HOME := $(CURDIR)

.PHONY: all test review bench check workflow
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
check: test workflow review
