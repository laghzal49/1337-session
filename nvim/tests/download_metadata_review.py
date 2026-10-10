"""Inspect official archive metadata for both supported architectures; download no archives."""
import argparse
import concurrent.futures
import importlib.util
import json
from pathlib import Path
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('integrity', ROOT/'scripts/download-integrity.py')
integrity = importlib.util.module_from_spec(spec)
spec.loader.exec_module(integrity)
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, default=Path('/tmp/download-metadata-review.json'))
args = parser.parse_args()

def request(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent':'1337-session-integrity-review'}), timeout=30) as response:
        return response.read().decode()

def github(repo):
    metadata = json.loads(request('https://api.github.com/repos/'+repo+'/releases/latest'))
    tag = metadata['tag_name']
    version = tag.lstrip('v')
    names = {
        'ryanoasis/nerd-fonts': ['JetBrainsMono.tar.xz','JetBrainsMono.zip'],
        'neovim/neovim': ['nvim-linux-'+arch+'.tar.gz' for arch in ('x86_64','arm64')],
        'BurntSushi/ripgrep': ['ripgrep-'+tag+'-'+arch+'.tar.gz' for arch in ('x86_64-unknown-linux-musl','aarch64-unknown-linux-gnu')],
        'sharkdp/fd': ['fd-'+tag+'-'+arch+'.tar.gz' for arch in ('x86_64-unknown-linux-musl','aarch64-unknown-linux-musl')],
        'junegunn/fzf': ['fzf-'+version+'-linux_'+arch+'.tar.gz' for arch in ('amd64','arm64')],
        'jesseduffield/lazygit': ['lazygit_'+version+'_linux_'+arch+'.tar.gz' for arch in ('x86_64','arm64')],
        'tree-sitter/tree-sitter': ['tree-sitter-linux-'+arch+'.gz' for arch in ('x64','arm64')],
        'clangd/clangd': ['clangd-linux-'+tag+'.zip'],
        'astral-sh/uv': ['uv-'+arch+'-unknown-linux-musl.tar.gz' for arch in ('x86_64','aarch64')],
    }[repo]
    results = []
    for name in names:
        url, sha, checksum_url, mode = integrity.github(metadata,repo,name)
        if not sha:
            sha = integrity.checksum(request(checksum_url),name,mode=='per-asset')
        results.append({'publisher':repo,'release':tag,'asset':name,'sha256':sha,'url':url})
    return results

repos = ['ryanoasis/nerd-fonts','neovim/neovim','BurntSushi/ripgrep','sharkdp/fd','junegunn/fzf',
         'jesseduffield/lazygit','tree-sitter/tree-sitter','clangd/clangd','astral-sh/uv']
results = []
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
    for items in pool.map(github,repos): results.extend(items)
node = next(line.split('\t')[0] for line in request('https://nodejs.org/dist/index.tab').splitlines()[1:]
            if line.split('\t')[9] != '-')
checksums = request('https://nodejs.org/dist/'+node+'/SHASUMS256.txt')
for arch in ('x64','arm64'):
    name = 'node-'+node+'-linux-'+arch+'.tar.gz'
    results.append({'publisher':'nodejs.org','release':node,'asset':name,'sha256':integrity.checksum(checksums,name)})
zig = json.loads(request('https://ziglang.org/download/index.json'))['0.14.0']
for arch in ('x86_64','aarch64'):
    item = zig[arch+'-linux']
    results.append({'publisher':'ziglang.org','release':'0.14.0','asset':item['tarball'].rsplit('/',1)[1],
                    'sha256':integrity.digest(item['shasum'])})
args.output.write_text(json.dumps({'archives':results,'archive_downloads':0},indent=2)+'\n')
print('OFFICIAL METADATA PASS: '+str(len(results))+' archive variants; x86_64/arm64, Node and Zig; no archive downloads')
