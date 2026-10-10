# Verification for Perfect Black II

The matched startup/idle measurements and picker tradeoff are recorded in
`redesign_results.json`. They use Neovim 0.11.5, installed plugin data and isolated
cache/state directories; headless startup does not measure LSP readiness.

From the repository root, run the strict upgrade suite with your installed
Neovim. Each review runs in a fresh process and propagates Lua/startup errors
through a nonzero exit status. Fixtures use temporary directories:

```sh
make upgrade NVIM=/path/to/nvim
# Run one review with the same strict checks:
NVIM_BIN=/path/to/nvim python3 nvim/tests/smoke.py performance_review.lua
```

The debugger test needs debugpy in `stdpath('data')/debugpy` (see the main guide).
The responsiveness review expects a non-cluster host without a Station override.
The performance review's context completion timeout is not a latency measurement.
It verifies bounded size checks and shutdown of already-attached decorations.
The suite also checks small dashboards, Unicode titles, project discovery,
keybinding ownership, async Git refreshes, tasks and workspace lifecycle.
Critical regression coverage includes literal statusline labels, exact diagnostic
text-object deletion, task subprocess cancellation, failed environment creation,
and debugger panels after abrupt session closure. Runner timeout tests verify
cleanup of disposable descendant processes.

For attached UI checks and grid screenshots:

```sh
NVIM_BIN=/path/to/nvim python3 nvim/tests/redesign_ui.py
NVIM_BIN=/path/to/nvim python3 nvim/tests/ui_review.py
```

`redesign_ui.py` requires Python msgpack/Pillow and fontconfig; set
`NVIM_PREVIEW_FONT=/path/to/monospaced.ttf` to select the capture font. It renders
real RGB Neovim grid events into the dashboard/editor/picker PNGs and checks
responsive bounds and Escape. The live debugger screenshot was captured while
real debugpy stopped on a breakpoint, rather than drawn as a mockup.

`ui_review.py` needs installed Python/Markdown parsers and exercises navigation,
completion, documents, snippets, explorer, TreeSJ, text objects, quickfix and
LSP mock interactions. `picker_bench.py` retains a direct MiniPick baseline and
compares the actual Snacks picker; the richer preview has a measured overhead.

The debugger review also verifies a live local attach session and checks that
both the debugger and external debugpy server exit. Manual C/C++ debugging
requires GDB 14+ with Python/DAP support; a live GDB session remains untested.
Background project tasks are
noninteractive; interactive jobs can use the existing Make/project terminal.
