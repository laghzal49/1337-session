#!/usr/bin/env python3
"""Capture Neovim's REAL redraw grid as a PNG (not a fabricated theme mockup).

Requires Neovim 0.11+, Python 3, Pillow, and msgpack. No GUI, display server,
sudo, clipboard, or user config modifications required.

Examples:
    python3 scripts/capture-nvim.py --output nvim-preview.png
    python3 scripts/capture-nvim.py --output full-preview.png --full
    python3 scripts/capture-nvim.py --full --view explorer --output explorer.png
    python3 scripts/capture-nvim.py --full --view completion --output completion.png
    python3 scripts/capture-nvim.py --full --view documentation --output docs.png
"""
import argparse
import os
from pathlib import Path
import select
import subprocess
import sys
import tempfile
import time

import msgpack
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
DEMO_C = """/* 1337 SESSION - strchr.c                             */
#include <stddef.h>

/* Find the first occurrence of a character in a string.
 * The terminating null byte is part of the search. */
char *ft_strchr(const char *str, int needle)
{
    unsigned char target = (unsigned char)needle;

    while (*str)
    {
        if ((unsigned char)*str == target)
            return (char *)str;
        str++;
    }
    return target == 0 ? (char *)str : NULL;
}

/* C • Python • Lua • Markdown
 * Rose palette: pink identifiers, lilac keywords,
 * soft comments and a pure black background. */
"""
# The visible content is a normal Neovim buffer. Syntax coloring and cursor,
# line numbers and statusline are produced by Neovim and its loaded config.


class NvimGrid:
    def __init__(self, width, height):
        self.width, self.height = width, height
        self.cells = [[(" ", 0) for _ in range(width)] for _ in range(height)]
        self.attrs = {}
        self.fg = 0xE9E4E9
        self.bg = 0
        self.cursor = None
        self.last_reply = None

    def apply(self, name, event):
        if name == "default_colors_set":
            self.fg, self.bg = event[:2]
        elif name == "hl_attr_define":
            ident, attributes = event[:2]
            self.attrs[ident] = attributes
        elif name == "grid_resize":
            grid, width, height = event
            if grid == 1:
                self.width, self.height = width, height
                self.cells = [[(" ", 0) for _ in range(width)] for _ in range(height)]
        elif name == "grid_clear":
            if event[0] == 1:
                self.cells = [[(" ", 0) for _ in range(self.width)] for _ in range(self.height)]
        elif name == "grid_cursor_goto":
            if event[0] == 1:
                self.cursor = (event[1], event[2])
        elif name == "grid_line":
            grid, row, col, chunks = event[:4]
            if grid != 1 or not (0 <= row < self.height):
                return
            attr = 0
            for chunk in chunks:
                glyph = chunk[0]
                if len(chunk) > 1:
                    attr = chunk[1]
                repeat = chunk[2] if len(chunk) > 2 else 1
                for _ in range(repeat):
                    if 0 <= col < self.width:
                        self.cells[row][col] = (glyph, attr)
                    col += 1
        elif name == "grid_scroll":
            grid, top, bottom, left, right, rows, cols = event
            if grid != 1:
                return
            old = [list(line) for line in self.cells]
            for row in range(max(top, 0), min(bottom, self.height)):
                for col in range(max(left, 0), min(right, self.width)):
                    from_row, from_col = row + rows, col + cols
                    if top <= from_row < bottom and left <= from_col < right:
                        self.cells[row][col] = old[from_row][from_col]
                    else:
                        self.cells[row][col] = (" ", 0)


def get_font(size, specified):
    choices = [
        specified,
        os.environ.get("NVIM_PREVIEW_FONT"),
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/liberation2/LiberationMono-Regular.ttf",
        "/System/Library/Fonts/Menlo.ttc",
        "C:/Windows/Fonts/consola.ttf",
    ]
    for choice in choices:
        if not choice:
            continue
        try:
            return ImageFont.truetype(choice, size)
        except (OSError, ValueError):
            pass
    return ImageFont.load_default()


def rgb(value, default):
    if not isinstance(value, int) or value < 0:
        value = default
    return ((value >> 16) & 255, (value >> 8) & 255, value & 255)


def render(grid, destination, font_path=None):
    size = 20
    font = get_font(size, font_path)
    cell_w, cell_h = 13, 28
    pad_x, pad_y = 26, 23
    image = Image.new("RGB", (grid.width * cell_w + pad_x * 2, grid.height * cell_h + pad_y * 2),
                      rgb(grid.bg, 0x000000))
    draw = ImageDraw.Draw(image)
    for y, row in enumerate(grid.cells):
        for x, (glyph, ident) in enumerate(row):
            style = grid.attrs.get(ident, {})
            foreground, background = grid.fg, grid.bg
            if "foreground" in style:
                foreground = style["foreground"]
            if "background" in style:
                background = style["background"]
            if style.get("reverse"):
                foreground, background = background, foreground
            xpos, ypos = pad_x + x * cell_w, pad_y + y * cell_h
            if background != grid.bg:
                draw.rectangle((xpos, ypos, xpos + cell_w, ypos + cell_h),
                               fill=rgb(background, grid.bg))
            if glyph and glyph != " ":
                draw.text((xpos, ypos + 1), glyph, font=font, fill=rgb(foreground, grid.fg))
            if style.get("underline") or style.get("undercurl"):
                draw.line((xpos, ypos + cell_h - 4, xpos + cell_w, ypos + cell_h - 4),
                          fill=rgb(style.get("special", foreground), grid.fg))
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination, format="PNG")
    return image.size


def capture(binary, width, height, full, timeout, view="editor"):
    env = dict(os.environ, NVIM_ASCII_ICONS="1", NVIM_BLACK_DOCS_AUTO_UPDATE="0",
               NVIM_CAPTURE_VIEW=view)
    args = [binary, "--embed", "--cmd", "let g:station_1337 = v:false"]
    if not full:
        args += ["-u", "NONE", "--cmd", "set runtimepath^=" + str(ROOT / "nvim")]
    proc = subprocess.Popen(args, cwd=str(ROOT), env=env, stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    unpacker = msgpack.Unpacker(raw=False)
    grid = NvimGrid(width, height)
    serial, replies = 0, {}

    def write(method, params):
        nonlocal serial
        serial += 1
        proc.stdin.write(msgpack.packb([0, serial, method, params], use_bin_type=True))
        proc.stdin.flush()
        return serial

    def events(wait_for, duration=timeout):
        deadline = time.monotonic() + duration
        latest_flush = 0
        while time.monotonic() < deadline:
            if proc.poll() is not None:
                error = proc.stderr.read().decode("utf8", "replace")
                raise RuntimeError("Neovim exited during screenshot: " + error[-1500:])
            readable, _, _ = select.select([proc.stdout], [], [], 0.10)
            if readable:
                raw = os.read(proc.stdout.fileno(), 65536)
                if not raw:
                    raise RuntimeError("Neovim disconnected before screenshot")
                unpacker.feed(raw)
                for message in unpacker:
                    if message[0] == 1:
                        replies[message[1]] = message
                    elif message[0] == 2 and message[1] == "redraw":
                        for event in message[2]:
                            if event[0] == "flush":
                                latest_flush = time.monotonic()
                            else:
                                for occurrence in event[1:]:
                                    grid.apply(event[0], occurrence)
            if wait_for in replies and (latest_flush and time.monotonic() - latest_flush > 0.35):
                reply = replies.pop(wait_for)
                if reply[2] is not None:
                    raise RuntimeError("Neovim RPC error: " + str(reply[2]))
                grid.last_reply = reply[3]
                return grid
        if wait_for in replies:
            reply = replies[wait_for]
            if reply[2] is not None:
                raise RuntimeError("Neovim RPC error: " + str(reply[2]))
            grid.last_reply = reply[3]
            return grid
        raise TimeoutError("Timed out reading Neovim redraw RPC")

    try:
        attach = write("nvim_ui_attach", [width, height, {"rgb": True, "ext_linegrid": True}])
        events(attach, 12)
        with tempfile.TemporaryDirectory(prefix="nvim-rose-preview-") as temporary:
            demo = Path(temporary) / "strchr.c"
            demo.write_text(DEMO_C, encoding="utf8")
            script = """
                vim.cmd('edit ' .. vim.fn.fnameescape(...))
                vim.cmd('file src/strchr.c')
                vim.bo.filetype = 'c'
                vim.cmd('syntax enable')
                if vim.g.colors_name ~= 'perfect-black' then
                    vim.cmd.colorscheme('perfect-black')
                end
                vim.opt.number = true
                vim.opt.relativenumber = false
                vim.opt.cursorline = true
                if not vim.g.capture_full_ui then
                    vim.opt.showmode = false
                    vim.opt.laststatus = 2
                    vim.opt.signcolumn = 'yes'
                    vim.opt.cmdheight = 1
                end
                vim.api.nvim_win_set_cursor(0, {7, 1})
                local view = vim.env.NVIM_CAPTURE_VIEW or 'editor'
                local ready = true
                if view == 'explorer' then
                    require('lazy').load({plugins={'snacks.nvim'}})
                    assert(_G.Snacks and Snacks.explorer, 'Snacks explorer is unavailable')
                    Snacks.explorer()
                    ready = vim.wait(3500, function()
                        return #vim.api.nvim_tabpage_list_wins(0) >= 2
                    end, 50)
                elseif view == 'documentation' then
                    -- Let deferred startup UI handlers finish before the float opens.
                    vim.wait(700, function() return false end, 100)
                    local _, doc_win = require('config.documentation').open({
                        '### ft_strchr(const char *str, int c)',
                        '',
                        'Returns a pointer to the first matching character.',
                        'The terminating null byte is part of the search.',
                        '',
                        '```c',
                        [[char *match = ft_strchr("banana", 'n');]],
                        '// match points to the third character',
                        '```',
                        '',
                        '**Controls:** K to focus · Ctrl-B/F to scroll',
                    }, 'C reference · ft_strchr', { close_events = {} })
                    assert(doc_win and vim.api.nvim_win_is_valid(doc_win),
                      'documentation window failed to open')
                    vim.api.nvim_set_current_win(doc_win)
                    ready = vim.wait(1500, function()
                        return vim.api.nvim_win_is_valid(doc_win)
                    end, 40)
                elseif view == 'completion' then
                    require('lazy').load({plugins={'blink.cmp'}})
                    local cmp = require('blink.cmp')
                    -- A deliberately incomplete identifier matching this C buffer.
                    vim.api.nvim_buf_set_lines(0, 13, 13, false, {'        str'})
                    vim.api.nvim_win_set_cursor(0, {14, 11})
                    vim.cmd('startinsert')
                    cmp.show()
                    ready = vim.wait(4000, function() return cmp.is_menu_visible() end, 60)
                elseif view ~= 'editor' then
                    error('unknown screenshot view: ' .. view)
                end
                vim.cmd('redraw!')
                return {theme=vim.g.colors_name, view=view, ready=ready}
            """
            flag = write("nvim_set_var", ["capture_full_ui", full])
            events(flag, 5)
            request = write("nvim_exec_lua", [script, [str(demo)]])
            result = events(request, timeout)
            state = result.last_reply or {}
            if not isinstance(state, dict) or not state.get("ready"):
                raise RuntimeError(f"Cannot capture {view}: its real Neovim panel did not open")
            # Capture after deferred UI redraws have settled.
            request = write("nvim_eval", ["g:colors_name"])
            result = events(request, 6)
            visible = "\n".join("".join(ch for ch, _ in row)
                                 for row in result.cells)
            if view == "documentation" and "Returns a pointer" not in visible:
                raise RuntimeError("Documentation float disappeared before capture")
            if view == "completion" and "Suggestions" not in visible:
                raise RuntimeError("Blink completion menu disappeared before capture")
            if view == "explorer" and "Explorer" not in visible:
                raise RuntimeError("Snacks explorer pane disappeared before capture")
            return result
    finally:
        try:
            write("nvim_command", ["qa!"])
        except (BrokenPipeError, OSError):
            pass
        try:
            proc.communicate(timeout=3)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.communicate()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", default="nvim-preview.png", type=Path)
    parser.add_argument("--nvim", default=os.environ.get("NVIM_BIN", "nvim"))
    parser.add_argument("--font")
    parser.add_argument("--full", action="store_true", help="Load installed full 1337-session config")
    parser.add_argument("--view", choices=("editor", "explorer", "completion", "documentation"),
                        default="editor", help="Which real Neovim UI surface to capture")
    parser.add_argument("--width", type=int, default=100)
    parser.add_argument("--height", type=int, default=28)
    parser.add_argument("--timeout", type=int, default=35)
    args = parser.parse_args()
    if args.width < 40 or args.height < 12:
        parser.error("width must be >= 40 and height >= 12")
    if not (ROOT / "nvim" / "colors" / "perfect-black.lua").is_file():
        parser.error("Run inside a 1337-session checkout")
    if args.view != "editor" and not args.full:
        parser.error("panel previews need --full and installed plugins")
    result = capture(args.nvim, args.width, args.height, args.full, args.timeout, args.view)
    size = render(result, args.output, args.font)
    print(f"REAL NVIM REDRAW CAPTURE: {args.output} ({size[0]}x{size[1]})")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, TimeoutError, OSError) as exc:
        print(f"Neovim capture failed: {exc}", file=sys.stderr)
        sys.exit(1)
