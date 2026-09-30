"""Full-config attached-UI review of command suggestions and spatial panels."""
import atexit
import os
from pathlib import Path
import select
import shutil
import subprocess
import time

import msgpack

root = Path(__file__).resolve().parents[2]
env = dict(os.environ, XDG_CONFIG_HOME=str(root), TERM="xterm-256color")
exe = os.environ.get("NVIM_BIN") or shutil.which("nvim")
if not exe:
    raise SystemExit("Neovim is required; set NVIM_BIN.")
process = subprocess.Popen([exe, "--embed"], cwd=root, env=env,
                           stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                           stderr=subprocess.DEVNULL)
atexit.register(lambda: process.terminate() if process.poll() is None else None)
unpacker = msgpack.Unpacker(raw=False)
pending = {}
serial = 0


def pump(seconds=0.2):
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        ready, _, _ = select.select([process.stdout], [], [], max(0, end - time.monotonic()))
        if not ready:
            break
        data = os.read(process.stdout.fileno(), 65536)
        if not data:
            break
        unpacker.feed(data)
        for message in unpacker:
            if message[0] == 1:
                pending[message[1]] = message


def call(method, args):
    global serial
    serial += 1
    request = serial
    process.stdin.write(msgpack.packb([0, request, method, args], use_bin_type=True))
    process.stdin.flush()
    deadline = time.monotonic() + 15
    while request not in pending and time.monotonic() < deadline:
        pump(0.005)
    result = pending.pop(request, None)
    assert result is not None, "RPC timeout: " + method
    assert result[2] is None, result[2]
    return result[3]


def lua(code, *args):
    return call("nvim_exec_lua", [code, list(args)])


call("nvim_ui_attach", [140, 42, {"rgb": True, "ext_linegrid": True}])
pump(1)
lua("dofile('nvim/tests/spatial_review.lua')")
pump()

# Actual command-line typing: suggestions must come from native completion,
# while Noice owns presentation. Selection must leave the editor in cmdline.
call("nvim_input", [":colo"])
pump(0.8)
completion = lua("local c=require('blink.cmp'); return {mode=vim.fn.mode(),line=vim.fn.getcmdline(),visible=c.is_menu_visible(),items=c.get_items(),selected=c.get_selected_item_idx()}")
assert completion["mode"] == "c" and completion["line"] == "colo", completion
assert completion["visible"] and any(item["label"] == "colorscheme" for item in completion["items"]), completion
assert "selected" not in completion, completion
call("nvim_input", ["<Tab>"])
pump(0.3)
assert lua("return require('blink.cmp').get_selected_item().label") == "colorscheme"
call("nvim_input", ["<Esc>"])
pump()
print("COMMAND SUGGESTIONS: Blink automatic cmdline suggestions and Tab selection with Noice presentation PASS", flush=True)
lua("_G.spatial_command_runs=0; vim.api.nvim_create_user_command('SpatialReviewCommand',function() spatial_command_runs=spatial_command_runs+1 end,{})")
call("nvim_input", [":SpatialReviewC"])
pump(0.4)
call("nvim_input", ["<Tab>"])
pump(0.05)
call("nvim_input", ["<CR>"])
pump(0.15)
assert lua("return spatial_command_runs") == 1, "selected command did not accept and execute exactly once"
print("COMMAND ACCEPTANCE: selected suggestion executes once on Enter PASS", flush=True)

# Capture the 180ms beacon immediately after a real navigation input.
def beacon_state():
    return lua("return {row=vim.api.nvim_win_get_cursor(0)[1],marks=#vim.api.nvim_buf_get_extmarks(0,require('config.cursor_ui').namespace,0,-1,{})}")


def assert_landing(row):
    state = beacon_state()
    assert state["row"] == row and state["marks"] == 1, state


call("nvim_command", ["enew!"])
lua("vim.api.nvim_buf_set_lines(0,0,-1,false,{'origin','middle','destination'}); vim.api.nvim_win_set_cursor(0,{1,0}); require('config.cursor_ui').clear()")
call("nvim_input", ["/destination"])
pump(0.2)
call("nvim_input", ["<Esc>"])
pump(0.04)
assert beacon_state()["row"] == 1 and beacon_state()["marks"] == 0, beacon_state()
call("nvim_input", ["/destination<CR>"])
pump(0.04)
assert_landing(3)
lua("vim.fn.setqflist({},'r',{items={{bufnr=vim.api.nvim_get_current_buf(),lnum=1,col=1},{bufnr=vim.api.nvim_get_current_buf(),lnum=3,col=1}}}); vim.cmd.cfirst(); vim.cmd.copen()")
pump(0.3)
lua("vim.api.nvim_win_set_cursor(0,{2,0}); require('config.cursor_ui').clear()")
call("nvim_input", ["<CR>"])
pump(0.04)
assert_landing(3)
call("nvim_command", ["cclose"])
lua("vim.cmd.cfirst(); require('config.cursor_ui').clear()")
call("nvim_input", [":cnext<CR>"])
pump(0.04)
assert_landing(3)
print("SEARCH / QUICKFIX: canceled search clean, accepted search, result Enter and :cnext beacon PASS", flush=True)

lua("vim.api.nvim_win_set_cursor(0,{1,0}); require('config.cursor_ui').clear(); vim.schedule(function() require('flash').jump({pattern='destination',search={mode='exact'}}) end)")
pump(0.3)
label = lua("for s in pairs(require('flash.state')._states) do if s.visible then for _,m in ipairs(s.results) do if m.pos[1]==3 and m.label then return m.label end end end end")
assert label, "Flash destination label missing"
call("nvim_input", [label])
pump(0.04)
assert_landing(3)
print("FLASH: real match selection delegates native jump and emphasizes destination PASS", flush=True)

# MiniPick's native grep result opens a position in the current buffer.
lua("vim.api.nvim_win_set_cursor(0,{1,0}); require('config.cursor_ui').clear(); require('lazy').load({plugins={'mini.pick'}}); _G.spatial_pick_buf=vim.api.nvim_get_current_buf(); vim.schedule(function() require('mini.pick').start({source={items={{bufnr=spatial_pick_buf,lnum=3,col=1,text='destination'}},name='Same-buffer grep'}}) end)")
pump(0.3)
assert lua("return require('mini.pick').get_picker_state()~=nil")
call("nvim_input", ["<CR>"])
pump(0.04)
assert_landing(3)
print("MINIPICK: same-buffer native grep-position selection beacon PASS", flush=True)

lua("require('lazy').load({plugins={'aerial.nvim','trouble.nvim','edgy.nvim'}})")
pump(0.5)
call("nvim_command", ["enew!"])
lua("vim.api.nvim_buf_set_lines(0,0,-1,false,{'def search(values):','    return values',''}); vim.bo.filetype='python'; _G.spatial_code=vim.api.nvim_get_current_buf()")

def inspect_layout(label):
    pump(0.6)
    state = lua("""
        require('config.focus_ui').update()
        local r={wins={},active=vim.api.nvim_get_current_win(),edgy=false}
        for _,w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local c=vim.api.nvim_win_get_config(w)
          if c.relative=='' then
            local b=vim.api.nvim_win_get_buf(w)
            r.wins[#r.wins+1]={id=w,ft=vim.bo[b].filetype,hl=vim.wo[w].winhighlight,
              width=vim.api.nvim_win_get_width(w),height=vim.api.nvim_win_get_height(w)}
            if vim.wo[w].winhighlight:find('Edgy',1,true) then r.edgy=true end
          end
        end
        return r
    """)
    assert len(state["wins"]) > 1, (label, state)
    assert any("BlackActiveSeparator" in win["hl"] for win in state["wins"]), (label, state)
    for win in state["wins"]:
        assert 0 < win["width"] <= 140 and 0 < win["height"] < 42, (label, win)
        call("nvim_set_current_win", [win["id"]])
        lua("require('config.focus_ui').update()")
        check = lua("local r={} for _,w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do if vim.api.nvim_win_get_config(w).relative=='' then r[#r+1]=vim.wo[w].winhighlight end end return r")
        assert any("BlackActiveSeparator" in value for value in check), (label, check)
    print("LAYOUT:", label, "focus transfer, edge and geometry PASS", flush=True)


call("nvim_command", ["vsplit"])
inspect_layout("two code splits")
call("nvim_command", ["only!"])
call("nvim_command", ["AerialOpen right"])
inspect_layout("code + Aerial")
lua("for _,w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do local b=vim.api.nvim_win_get_buf(w); if b==spatial_code then vim.api.nvim_win_set_cursor(w,{3,0}) end end; for _,w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype=='aerial' then vim.api.nvim_set_current_win(w); vim.api.nvim_win_set_cursor(w,{1,0}); break end end; require('config.cursor_ui').clear()")
call("nvim_input", ["<CR>"])
pump(0.04)
assert_landing(1)
print("AERIAL: real outline Enter returns focus to code with shared beacon PASS", flush=True)
call("nvim_command", ["AerialClose"])
lua("vim.api.nvim_set_current_buf(spatial_code); Snacks.terminal.open('cat',{win={position='bottom'}})")
call("nvim_input", ["<C-\\><C-n>"])
inspect_layout("code + terminal")
call("nvim_command", ["AerialOpen right"])
inspect_layout("code + Aerial + terminal")
lua("require('aerial').close(); for _,w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do if vim.bo[vim.api.nvim_win_get_buf(w)].buftype=='terminal' then vim.api.nvim_win_close(w,true) end end; vim.api.nvim_set_current_buf(spatial_code); vim.diagnostic.set(vim.api.nvim_create_namespace('spatial_layout'),spatial_code,{{lnum=1,col=0,message='review',severity=2}})")
call("nvim_command", ["Trouble diagnostics open"])
inspect_layout("code + Trouble")
call("nvim_command", ["Trouble close"])
assert call("nvim_eval", ["v:errors"]) == []
serial += 1
process.stdin.write(msgpack.packb([0, serial, "nvim_command", ["silent! qa!"]], use_bin_type=True))
process.stdin.flush()
deadline = time.monotonic() + 8
while process.poll() is None and time.monotonic() < deadline:
    pump(0.2)
    if process.poll() is None:
        serial += 1
        try:
            process.stdin.write(msgpack.packb([0, serial, "nvim_input", ["<CR>"]], use_bin_type=True))
            process.stdin.flush()
        except BrokenPipeError:
            break
process.wait(timeout=5)
try:
    process.stdin.close()
except BrokenPipeError:
    pass
process.stdout.close()
print("SPATIAL UI REVIEW PASS", flush=True)
