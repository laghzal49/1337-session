"""Attached-UI review of shared documentation and native LSP navigation/actions."""
import atexit
import os
from pathlib import Path
import select
import shutil
import subprocess
import time

import msgpack

root = Path(__file__).resolve().parents[2]
env = dict(os.environ, XDG_CONFIG_HOME=str(root), TERM="xterm-256color", NVIM_BLACK_DOCS_AUTO_UPDATE="0")
exe = os.environ.get("NVIM_BIN") or shutil.which("nvim")
if not exe:
    raise SystemExit("Neovim is required; set NVIM_BIN.")
process = subprocess.Popen([exe, "--embed"], cwd=root, env=env,
                           stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                           stderr=subprocess.DEVNULL)
atexit.register(lambda: process.terminate() if process.poll() is None else None)
unpacker = msgpack.Unpacker(raw=False, ext_hook=lambda code, data: msgpack.unpackb(data) if code in (0, 1, 2) else msgpack.ExtType(code, data))
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


def input_keys(keys, wait=0.25):
    call('nvim_input', [keys])
    pump(wait)


def docs():
    return lua("""
      local r={}
      for _,w in ipairs(vim.api.nvim_list_wins()) do
        local c=vim.api.nvim_win_get_config(w)
        local hl=vim.wo[w].winhighlight
        local b=vim.api.nvim_win_get_buf(w)
        local ft=vim.bo[b].filetype
        if c.relative~='' and (ft=='markdown' or ft=='blink-cmp-documentation' or ft=='blink-cmp-signature')
          and (hl:find('BlackDocs',1,true) or hl:find('BlinkCmpDoc',1,true) or hl:find('BlinkCmpSignatureHelp',1,true)) then
          local rendered=0
          for name,ns in pairs(vim.api.nvim_get_namespaces()) do
            if name:find('render',1,true) or name:find('Render',1,true) then
              rendered=rendered+#vim.api.nvim_buf_get_extmarks(b,ns,0,-1,{})
            end
          end
          r[#r+1]={win=w,buf=b,config=c,lines=vim.api.nvim_buf_get_lines(b,0,-1,false),hl=hl,conceal=vim.wo[w].conceallevel,rendered=rendered}
        end
      end
      return r
    """)


def reset(line='analyze', insert=False):
    input_keys('<Esc>', 0.03)
    lua("require('config.documentation').close(); require('blink.cmp').hide(); require('blink.cmp').hide_signature(); vim.api.nvim_set_current_buf(documentation_review.buf); vim.api.nvim_buf_set_lines(0,0,-1,false,{...,'middle','destination','other destination'}); vim.api.nvim_win_set_cursor(0,{1,0}); vim.bo.modified=false", line)
    if insert:
        input_keys('A', 0.04)
        lua("require('blink.cmp').hide(); require('blink.cmp').hide_signature()")
    else:
        lua("vim.api.nvim_win_set_cursor(0,{1,math.max(0,#vim.api.nvim_get_current_line()-1)})")


call('nvim_ui_attach', [140,42,{'rgb':True,'ext_linegrid':True}])
pump(0.7)
lua("dofile('nvim/tests/documentation_fixture.lua'); require('lazy').load({plugins={'mini.pick','mini.extra','render-markdown.nvim'}})")
pump(0.2)

for width,height in [(80,24),(100,30),(140,42)]:
    call('nvim_ui_try_resize', [width,height])
    reset()
    input_keys('K')
    current=docs()
    assert len(current)==1,current
    popup=current[0]
    text='\n'.join(popup['lines'])
    assert 'def analyze' in text and 'Parameters' in text and 'Input values' in text,text
    assert popup['config']['width']+2<=width and popup['config']['height']+2<=height,popup
    assert popup['conceal']>=2 and popup['rendered']>0,popup
    input_keys('<C-k>',0.06)
    assert len(docs())==1 and call('nvim_get_current_win',[])==popup['win'],(call('nvim_get_current_win',[]),popup['win'],lua("return vim.fn.maparg('<C-k>','n',false,true).desc"))
    before=lua("return vim.fn.winsaveview()")
    input_keys('<C-f>',0.05)
    after=lua("return vim.fn.winsaveview()")
    assert (before['topline'],before['skipcol'])!=(after['topline'],after['skipcol']),(before,after)
    input_keys('q',0.04)
    assert docs()==[],docs()
    reset()
    input_keys('<C-k>')
    input_keys('K',0.05)
    assert len(docs())==1,docs()
    input_keys('<Esc>',0.04)
    assert docs()==[],docs()

    for insert in [False,True]:
        reset('analyze([1], ',insert)
        hover_before=lua("return documentation_review.requests['textDocument/hover'] or 0")
        input_keys('<C-k>')
        current=docs()
        assert len(current)==1,current
        text='\n'.join(current[0]['lines'])
        assert 'Signature-priority documentation' in text and 'Maximum number of values' in text,text
        assert lua("return #vim.api.nvim_buf_get_extmarks(...,vim.api.nvim_get_namespaces().symbol_help_parameter,0,-1,{})>0",current[0]['buf']),'active signature parameter highlight missing'
        assert lua("return documentation_review.requests['textDocument/hover'] or 0")==hover_before,'hover requested despite successful signature'
        assert current[0]['config']['width']+2<=width and current[0]['config']['height']+2<=height,current
        if insert:
            input_keys('<C-k>',0.15)
            assert len(docs())==1,(docs(),call('nvim_get_mode',[]),call('nvim_get_current_win',[]))
            assert docs()[0]['config']['height']<=8,docs()
            assert call('nvim_get_mode',[])['mode'].startswith('i'),'signature stole insert focus'
            input_keys('<Esc>',0.04)
            assert docs()==[],'insert signature did not close on escape'
        lua("require('config.documentation').close(); require('blink.cmp').hide_signature()")
    print('NATIVE DOCS',width,height,'Markdown fences/lists, focus/scroll, q/Esc, signature priority normal/insert PASS',flush=True)

reset()
lua("require('config.symbol_help').show(nil,true)")
pump(0.25)
assert 'Signature-priority documentation' in '\n'.join(docs()[0]['lines']),docs()
lua("require('config.documentation').close()")

# Stale responses must not open a documentation surface after movement.
reset()
lua("documentation_review.delay=180")
input_keys('K',0.025)
input_keys('j',0.25)
assert docs()==[],docs()
lua("documentation_review.delay=60; documentation_review.hover=false; documentation_review.signature=false; vim.lsp.enable('ty',false); vim.bo[documentation_review.buf].filetype='python'; require('blink.cmp.config').signature.enabled=false")
reset('sum')
input_keys('K',0.6)
assert 'sum(iterable' in '\n'.join(docs()[0]['lines']),docs()
lua("require('config.documentation').close(); documentation_review.hover=true; documentation_review.signature=true; vim.bo[documentation_review.buf].filetype='documentation_review'")
print('SMART HELP: stale cursor reply suppressed and empty-LSP Python builtin fallback PASS',flush=True)

# Real Blink provider, delayed resolver, and the shared documentation draw hook.
lua("""
 package.preload['documentation_review.source']=function()
   local s={}; function s.new() return setmetatable({},{__index=s}) end
   function s:get_completions(_,cb) cb({items={{label='analyze_review',kind=3}},is_incomplete_forward=false,is_incomplete_backward=false}) end
   function s:resolve(item,cb) vim.defer_fn(function() item.documentation={kind='markdown',value=documentation_review.markdown}; cb(item) end,60) end
   return s
 end
 require('blink.cmp').add_source_provider('documentation_review',{name='Review',module='documentation_review.source'})
 _G.documentation_sources=require('blink.cmp.config').sources.default
 require('blink.cmp.config').sources.default={'documentation_review'}
""")
for width,height in [(80,24),(100,30),(140,42)]:
    call('nvim_ui_try_resize',[width,height])
    reset('',True)
    input_keys('ana',0.15)
    input_keys('<C-n>',0.25)
    lua("require('blink.cmp').show_documentation()"); pump(0.12)
    current=docs()
    assert len(current)==1,current
    popup=current[0]
    assert 'BlinkCmpDoc' in popup['hl'],popup
    assert popup['config']['width']+2<=width and popup['config']['height']+2<=height,popup
    assert 'def analyze' in '\n'.join(popup['lines']),popup
    assert popup['rendered']>0,'Blink documentation has no Markdown rendering marks'
    assert len(docs())==1,docs()
    before=lua("return vim.api.nvim_win_call(...,function() return vim.fn.winsaveview() end)",popup['win'])
    input_keys('<C-f>',0.04)
    after=lua("return vim.api.nvim_win_call(...,function() return vim.fn.winsaveview() end)",popup['win'])
    assert (before['topline'],before['skipcol'])!=(after['topline'],after['skipcol']),(before,after)
    input_keys('<C-d>',0.05)
    assert docs()==[],docs()
    input_keys('<C-d>',0.15)
    assert len(docs())==1,docs()
    input_keys('<Esc>',0.05)
    assert docs()==[],'completion documentation survived insert escape'
    print('BLINK DOCS',width,height,'shared bounds/rendering, completion documentation, scrolling and hide PASS',flush=True)
reset('',True)
input_keys('ana',0.15)
input_keys('<C-n>',0.25)
lua("require('config.documentation').open({'# Native reference','Native reference before completion selection.'},'Native reference')")
assert len(docs())==1 and 'BlackDocs' in docs()[0]['hl'],docs()
assert lua("return require('blink.cmp').get_selected_item()~=nil"),'native reference unexpectedly cleared the completion selection'
lua("require('blink.cmp').show_documentation()"); pump(0.15)
assert len(docs())==1 and 'BlinkCmpDoc' in docs()[0]['hl'],docs()
input_keys('<C-k>',0.2)
assert len(docs())==1 and 'BlinkCmpDoc' not in docs()[0]['hl'],docs()
assert 'Signature-priority documentation' in '\n'.join(docs()[0]['lines']),docs()
assert docs()[0]['config']['height']<=8,docs()
input_keys('<Esc>',0.05)
print('DOCUMENTATION OWNERSHIP: selected completion replaces native reference without textlock errors or duplicate surfaces PASS',flush=True)
lua("require('blink.cmp.config').sources.default=documentation_sources")

# Native location replies: empty feedback, single direct jump, multiple preview.
for method in ['definition','references','implementation','type_definition']:
    reset()
    lua("documentation_review.locations={}; _G.documentation_note_count=#require('mini.notify').get_all(); require('config.lsp_actions').locations(...)",method)
    pump(0.2)
    assert lua("return require('mini.pick').get_picker_state()==nil")
    assert lua("local notes=require('mini.notify').get_all(); for i=documentation_note_count+1,#notes do if notes[i].msg:lower():find('no ',1,true) then return true end end return false"),(method,lua("return {notes=require('mini.notify').get_all(),status=vim.v.statusmsg}"))
reset()
lua("documentation_review.locations={{uri=documentation_review.uri,range={start={line=2,character=0},['end']={line=2,character=1}}}}; require('config.cursor_ui').clear(); require('config.lsp_actions').locations('definition')")
pump(0.085)
assert lua("return vim.api.nvim_win_get_cursor(0)[1]==3 and #vim.api.nvim_buf_get_extmarks(0,require('config.cursor_ui').namespace,0,-1,{})==1"),'single location jump/beacon missing'
reset()
lua("documentation_review.locations={{targetUri=documentation_review.target_uri,targetRange={start={line=0,character=0},['end']={line=2,character=13}},targetSelectionRange={start={line=1,character=0},['end']={line=1,character=6}},originSelectionRange={start={line=0,character=0},['end']={line=0,character=7}}}}; require('config.cursor_ui').clear()")
input_keys('gd',0.085)
assert lua("return vim.api.nvim_buf_get_name(0)==documentation_review.target and vim.api.nvim_win_get_cursor(0)[1]==2 and #vim.api.nvim_buf_get_extmarks(0,require('config.cursor_ui').namespace,0,-1,{})==1"),'real gd LocationLink did not jump to target file/selection row with beacon'
assert lua("return #vim.fn.gettagstack().items>0"),'definition tagstack missing'
reset()
lua("documentation_review.locations={{uri=documentation_review.uri,range={start={line=2,character=0},['end']={line=2,character=1}}},{uri=documentation_review.uri,range={start={line=3,character=0},['end']={line=3,character=1}}}}; require('config.lsp_actions').locations('definition')")
pump(0.2)
assert lua("return #require('mini.pick').get_picker_items()==2")
input_keys('<C-x>',0.04)
assert lua("return #require('mini.pick').get_picker_matches().marked==1"),'location mark missing'
input_keys('<Tab>',0.05)
assert lua("local s=require('mini.pick').get_picker_state(); return s.buffers.preview~=nil and vim.api.nvim_win_get_buf(s.windows.main)==s.buffers.preview"),'location preview missing'
input_keys('<Tab><Esc>',0.06)
print('LSP LOCATIONS: empty feedback, single direct jump/beacon, multiple native preview/mark PASS',flush=True)

reset()
lua("documentation_review.empty_actions=true; _G.documentation_note_count=#require('mini.notify').get_all(); require('config.lsp_actions').code_action()")
pump(0.2)
assert lua("return require('mini.pick').get_picker_state()==nil"),'empty code actions opened picker'
assert lua("local notes=require('mini.notify').get_all(); for i=documentation_note_count+1,#notes do if notes[i].msg:lower():find('no code actions',1,true) then return true end end return false"),'empty code-action feedback missing'
lua("documentation_review.empty_actions=false")
lua("require('config.lsp_actions').code_action()")
pump(0.2)
assert lua("return #require('mini.pick').get_picker_items()==2")
input_keys('<Tab>',0.05)
preview=lua("local s=require('mini.pick').get_picker_state(); return vim.api.nvim_buf_get_lines(s.buffers.preview,0,-1,false)")
assert 'review_replacement' in '\n'.join(preview),preview
assert lua("return vim.api.nvim_buf_get_lines(documentation_review.buf,0,1,false)[1]")=='analyze','preview applied an edit'
input_keys('<Tab><C-n><Tab>',0.06)
preview=lua("local s=require('mini.pick').get_picker_state(); return vim.api.nvim_buf_get_lines(s.buffers.preview,0,-1,false)")
assert 'No text edits supplied' in '\n'.join(preview),preview
assert lua("return documentation_review.resolve")==0,'preview resolved an action'
input_keys('<Esc>',0.06)
print('CODE ACTIONS: supplied replacement preview is read-only; unresolved preview makes no resolve request PASS',flush=True)

lua("vim.lsp.get_client_by_id(documentation_review.client):stop(true); vim.api.nvim_buf_delete(documentation_review.buf,{force=true}); vim.fn.delete(documentation_review.dir,'rf')")
assert call('nvim_eval',['v:errors'])==[]
serial+=1
process.stdin.write(msgpack.packb([0,serial,'nvim_command',['silent! qa!']],use_bin_type=True)); process.stdin.flush()
deadline=time.monotonic()+8
while process.poll() is None and time.monotonic()<deadline:
    pump(0.1)
    if process.poll() is None:
        serial+=1
        try:
            process.stdin.write(msgpack.packb([0,serial,'nvim_input',['<CR>']],use_bin_type=True)); process.stdin.flush()
        except BrokenPipeError:
            break
process.wait(timeout=5)
try: process.stdin.close()
except BrokenPipeError: pass
process.stdout.close()
print('DOCUMENTATION / ACTIONS REVIEW PASS',flush=True)
