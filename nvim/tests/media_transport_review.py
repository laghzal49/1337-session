"""Exercise the real Rust PDF cache: scrolling must never re-upload pixel data."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

plugin = Path(os.environ.get('XDG_DATA_HOME', str(Path.home()/'.local/share'))) / 'nvim/lazy/nvim-gfx'
binary = Path(os.environ.get('NVIM_GFX_BIN', str(plugin/'bin/nvim-gfx')))
fixture = plugin/'tests/fixtures/two-pages.pdf'
with tempfile.NamedTemporaryFile() as output:
    with subprocess.Popen([str(binary)], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True,
                          env=dict(os.environ, NVIM_GFX_TTY=output.name)) as process:
        def send(command):
            process.stdin.write(json.dumps(command)+'\n')
            process.stdin.flush()
        def ready():
            # Poll the process pipe with a deadline; never hang the test suite.
            import select
            deadline=time.monotonic()+10
            data=b''
            while time.monotonic()<deadline:
                readable,_,_=select.select([process.stdout],[],[],max(0,deadline-time.monotonic()))
                if not readable:break
                chunk=os.read(process.stdout.fileno(),65536)
                if not chunk:raise AssertionError('reader exited: '+process.stderr.read())
                data+=chunk
                lines=data.split(b'\n');data=lines.pop()
                for line in lines:
                    event=json.loads(line)
                    assert event['event']!='error',event
                    if event['event']=='ready':return
            raise AssertionError('PDF render timed out')
        def graphics():
            return Path(output.name).read_bytes()
        try:
            show=dict(cmd='show',path=str(fixture),row=0,col=0,width=160,height=60)
            send(show);ready()
            initial=graphics()
            assert b'a=t,f=100' in initial, 'first page was not uploaded as PNG'
            before=len(initial)
            for index in range(20):
                send(dict(cmd='pan',dx=0,dy=1 if index%2==0 else -1))
            send(dict(cmd='zoom',factor=1.25))
            send(show);ready()
            delta=graphics()[before:]
            assert b'a=t' not in delta and b'a=T' not in delta, 'scroll/zoom re-uploaded pixels'
            assert len(delta)<8192, f'excessive scroll traffic: {len(delta)} bytes'
            assert delta.count(b'a=p')==22, 'placement updates missing'
            # Revisiting a rendered page must use the terminal cache as well.
            send(dict(cmd='page',delta=1));send(show);ready()
            before=len(graphics())
            send(dict(cmd='page_goto',page=1));send(show);ready()
            assert b'a=t' not in graphics()[before:], 'returning to cached page re-uploaded pixels'
            send(dict(cmd='quit'))
            assert process.wait(timeout=3)==0
            assert b'a=d,d=I' in graphics(), 'cached terminal pages were not freed'
            print(f'MEDIA TRANSPORT PASS: 20 pans + zoom + redraw = {len(delta)} bytes; cached page reuse and cleanup')
        finally:
            if process.poll() is None:process.kill()
            process.wait()
