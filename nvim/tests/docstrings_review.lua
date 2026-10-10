assert(not require('lazy.core.config').plugins.neogen._.loaded, 'docstrings add startup work')
local generate = require('config.docstrings').generate
local function buffer(lines, row, col)
  if vim.snippet.active() then vim.snippet.stop() end
  vim.cmd.stopinsert()
  vim.cmd.enew({ bang = true })
  vim.bo.filetype = 'python'
  vim.bo.expandtab, vim.bo.shiftwidth = true, 4
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { row or 1, col or 0 })
end
local function text() return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n') .. '\n' end
local function valid(before)
  local check = vim.system({ 'python3', '-c', [[
import ast,json,sys
before,after=json.load(sys.stdin)
def strip(node):
    for child in ast.walk(node):
        if isinstance(child,(ast.Module,ast.FunctionDef,ast.AsyncFunctionDef,ast.ClassDef)):
            if ast.get_docstring(child) is not None:
                child.body.pop(0)
    return ast.dump(node,include_attributes=False)
assert strip(ast.parse(before)) == strip(ast.parse(after)), 'code changed beyond docstrings'
]] }, { text = true, stdin = vim.json.encode({ before, text() }) }):wait()
  assert(check.code == 0, check.stderr)
  local lint = vim.system({ 'ruff', 'check', '--isolated', '--select', 'D200,D205,D209,D210,D211,D300,D400',
    '--stdin-filename', 'docstring_review.py', '-' }, { text = true, stdin = text() }):wait()
  assert(lint.code == 0, lint.stdout .. lint.stderr)
end

buffer({ 'def scale(value: int, factor: int = 2) -> int:', '    if factor < 0:',
  '        raise ValueError("negative factor")', '    return value * factor' })
local before = text()
vim.cmd.PythonDocstring()
assert(require('lazy.core.config').plugins.neogen._.loaded, 'first command did not load generator')
assert(vim.snippet.active(), 'docstring fields are not editable snippet placeholders')
assert(text():find('Args:', 1, true) and text():find('value:', 1, true) and text():find('factor:', 1, true), 'parameters missing')
assert(text():find('Returns:', 1, true) and text():find('ValueError:', 1, true), 'return or raise fields missing')
assert(text():find('factor: Describe this argument.', 1, true), 'typed argument has the wrong editable field')
valid(before)
local once = text()
assert(not generate() and text() == once, 'existing docstring duplicated or overwritten')

for _, case in ipairs({
  { { 'async def load(', '    name: str,', '    *, retry: bool = False,', ') -> str:', '    return name' }, 2, 4 },
  { { 'def values(*args, **kwargs):', '    for item in args:', '        yield item' }, 1, 0 },
  { { 'class Counter:', '    def count(self, values: list[int]) -> int:', '        return len(values)' }, 2, 8 },
  { { 'def inline(value: int) -> int: return value + 1  # keep this comment' }, 1, 0 },
  { { 'class Empty: pass' }, 1, 0 },
  { { '@staticmethod', 'def build(value: int) -> int:', '    return value' }, 1, 2 },
  { { '#!/usr/bin/env python3', '# coding: utf-8', 'from __future__ import annotations', 'value = 3' }, 4, 0, 'file' },
  { { 'class Settings:', '    enabled = True' }, 1, 0, 'class' },
  { { '' }, 1, 0, 'file' },
  { { '# A module description belongs after this comment.' }, 1, 0, 'file' },
}) do
  buffer(case[1], case[2], case[3])
  before = text()
  assert(generate(case[4]), 'generation failed for ' .. before)
  valid(before)
end
buffer({ 'def mixed(first: str, second=1, /, *values: int, flag=True, **options: str):', '    return first' })
before = text(); assert(generate()); valid(before)
local position = 0
for _, name in ipairs({ 'first', 'second', '*values', 'flag', '**options' }) do
  local next_position = text():find(name .. ': Describe this argument.', position + 1, true)
  assert(next_position, 'signature order or argument missing: ' .. name)
  position = next_position
end
for _, definition in ipairs({
  { 'class Factory:', '    def build(self: "Factory", value: int):', '        return value' },
  { 'class Factory:', '    @classmethod', '    def build(cls: type, value: int):', '        return value' },
  { 'class Factory:', '    @identity', '    @staticmethod', '    def build(value: int):', '        return value' },
}) do
  buffer(definition, #definition, 8)
  before = text(); assert(generate()); valid(before)
  assert(text():find('value: Describe this argument.', 1, true), 'method argument missing')
  assert(not text():find('self:', text():find('Args:', 1, true), true), 'receiver documented as a caller argument')
end
buffer({ 'def tabs(value):', '\treturn value' })
vim.bo.expandtab, vim.bo.shiftwidth = false, 8
before = text(); assert(generate()); valid(before)

buffer({ 'def documented():', '    # keep this note', '    ("Existing " "documentation.")', '    return 1' }, 4, 4)
before = text(); assert(not generate() and text() == before, 'parenthesized docstring overwritten')
buffer({ 'def broken(', '    return 1' })
before = text(); assert(not generate('func') and text() == before, 'invalid syntax was modified')
buffer({ 'def unchanged():', '    pass' })
vim.bo.modifiable = false
before = text(); assert(not generate() and text() == before, 'read-only buffer modified')
vim.bo.modifiable = true
vim.cmd.enew({ bang = true })
print('DOCSTRINGS PASS: first-use lazy command, native fields, PEP formatting, AST equivalence, async/multiline/decorators/classes/inline suites/tabs/shebangs and existing-doc protection')
