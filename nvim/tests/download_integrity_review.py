"""Check archive verification and real installer guards with tiny local fixtures."""
import hashlib
import importlib.util
import json
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('integrity', ROOT/'scripts/download-integrity.py')
integrity = importlib.util.module_from_spec(spec)
spec.loader.exec_module(integrity)
NAME = 'tool-linux-x64.tar.gz'
CONTENT = b'archive fixture; never extracted'
SHA = hashlib.sha256(CONTENT).hexdigest()
URL = 'https://github.com/publisher/tool/releases/download/v1/' + NAME
asset = {'name': NAME, 'browser_download_url': URL, 'digest': 'sha256:' + SHA}
assert integrity.github({'assets':[asset]}, 'publisher/tool', NAME)[1] == SHA
assert integrity.checksum(SHA+'  '+NAME, NAME) == SHA
assert integrity.checksum('SHA256 ('+NAME+') = '+SHA, NAME) == SHA
assert integrity.checksum(SHA, NAME, per_asset=True) == SHA
for text in (SHA, SHA+'  other.tar.gz', SHA+'  '+NAME+'\n'+SHA+'  '+NAME):
    try:
        integrity.checksum(text, NAME)
        raise AssertionError('accepted wrong/ambiguous checksum')
    except ValueError:
        pass

installer = (ROOT/'install.sh').read_text()
helpers = installer[installer.index('fetch_verified() {'):installer.index('# latest release tag')]
with tempfile.TemporaryDirectory(prefix='archive-integrity-review-') as folder:
    tmp = Path(folder)
    archive, metadata, sidecar = tmp/'source', tmp/'metadata.json', tmp/'sidecar'
    archive.write_bytes(CONTENT)
    sidecar.write_text(SHA)
    guard = tmp/'extracted'
    dest = tmp/'download'
    setup = 'TMP='+shlex.quote(folder)+'; REPO_DIR='+shlex.quote(str(ROOT))+';\n'
    fetch = 'fetch() { case "$1" in *api.github.com*) cp '+shlex.quote(str(metadata))+' "$2";; *.sha256|*checksums.txt) cp '+shlex.quote(str(sidecar))+' "$2";; *) cp '+shlex.quote(str(archive))+' "$2";; esac; }\n'

    def check(label, assets, content, passed):
        metadata.write_text(json.dumps({'tag_name':'v1','assets':assets}))
        archive.write_bytes(content)
        guard.unlink(missing_ok=True)
        dest.unlink(missing_ok=True)
        command = setup + fetch + helpers + '\nfetch_release publisher/tool v1 ' + shlex.quote(NAME) + ' ' + shlex.quote(str(dest)) + ' && touch ' + shlex.quote(str(guard))
        result = subprocess.run(['bash','-c',command], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=5)
        assert (result.returncode == 0) == passed, (label,result.stdout)
        assert guard.exists() == passed, (label,'extraction guard incorrectly allowed')
        if not passed: assert not dest.exists(), (label,'rejected archive left available')
        print('DOWNLOAD INTEGRITY PASS:',label)

    check('published digest match permits extraction', [asset], CONTENT, True)
    check('digest mismatch removes archive and blocks extraction', [asset], b'corrupted', False)
    no_digest = dict(asset, digest=None)
    checksum_asset = {'name':NAME+'.sha256','browser_download_url':URL+'.sha256'}
    check('published per-asset checksum fallback', [no_digest,checksum_asset], CONTENT, True)
    check('checksum fallback mismatch blocks extraction', [no_digest,checksum_asset], b'corrupted', False)
    sidecar.write_text(SHA+'  '+NAME+'\n')
    aggregate = {'name':'checksums.txt','browser_download_url':'https://github.com/publisher/tool/releases/download/v1/checksums.txt'}
    check('named aggregate published checksum fallback', [no_digest,aggregate], CONTENT, True)
    check('missing published checksum refuses download', [no_digest], CONTENT, False)
    check('malformed digest refuses download', [dict(asset,digest='sha256:invalid')],CONTENT,False)
    check('nonpublisher archive URL rejected', [dict(asset,browser_download_url='https://other.test/'+NAME)],CONTENT,False)
with tempfile.TemporaryDirectory(prefix='zig-integrity-review-') as folder:
    index = Path(folder)/'index.json'
    index.write_text(json.dumps({'0.14.0':{'x86_64-linux':{'tarball':'https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz','shasum':SHA}}}))
    result = subprocess.run([sys.executable,str(ROOT/'scripts/download-integrity.py'),'zig',str(index),'0.14.0','x86_64'],text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    assert result.returncode == 0 and SHA in result.stdout,result.stdout
    print('DOWNLOAD INTEGRITY PASS: official Zig index checksum')
print('DOWNLOAD INTEGRITY REVIEW PASS: publisher metadata, exact filenames, mismatch and extraction guards')
