"""A failed bootstrap must exit promptly and nonzero without needing input."""
import os
import pathlib
import subprocess

root = pathlib.Path(__file__).resolve().parents[2]
script = """
vim.uv.fs_stat = function() return nil end
local system = vim.fn.system
vim.fn.system = function() system('exit 1'); return 'simulated clone failure' end
dofile('nvim/lua/config/lazy.lua')
"""
run = subprocess.run(
    [os.environ.get('NVIM_BIN', 'nvim'), '--headless', '-u', 'NONE',
     '-c', 'lua ' + script, '-c', 'qa!'],
    cwd=root, capture_output=True, text=True, timeout=5,
)
assert run.returncode != 0, run
assert 'simulated clone failure' in run.stderr, run.stderr
print('BOOTSTRAP FAILURE PASS: exits nonzero without waiting for input')
