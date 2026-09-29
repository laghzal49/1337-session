NVIM ?= nvim
PYTHON ?= python3
export XDG_CONFIG_HOME := $(CURDIR)

.PHONY: all test review bench check
all: test

## Run standalone test suite
test:
	$(NVIM) --headless -c "luafile nvim/tests/standalone.lua" -c "qa!"

## Run full UI review suite
review:
	$(PYTHON) nvim/tests/ui_review.py

## Run startup benchmark
bench:
	$(PYTHON) nvim/tests/startup_bench.py

## Run all test suites
check: test review
