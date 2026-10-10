"""Resolve publisher SHA256 metadata and verify archives before extraction."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

HEX = re.compile(r'[0-9a-fA-F]{64}')

def digest(value):
    if not isinstance(value, str) or not HEX.fullmatch(value):
        raise ValueError('publisher did not supply a valid SHA256 checksum')
    return value.lower()

def github(metadata, repo, name):
    assets = {item['name']: item for item in metadata.get('assets', [])}
    if name not in assets:
        raise ValueError('release asset not found: ' + name)
    prefix = f'https://github.com/{repo}/releases/download/'
    def url(item):
        value = item.get('browser_download_url', '')
        if not value.startswith(prefix):
            raise ValueError('release asset URL is outside the publisher repository')
        return value
    asset = assets[name]
    published = asset.get('digest')
    if published:
        if not isinstance(published, str) or not published.startswith('sha256:'):
            raise ValueError('unsupported release digest: ' + str(published))
        return url(asset), digest(published[7:]), '', ''
    candidates = [name + '.sha256', 'SHA-256.txt', 'sha256.sum', 'checksums.txt',
                  'fzf_' + metadata.get('tag_name', '').lstrip('v') + '_checksums.txt']
    for candidate in candidates:
        if candidate in assets:
            return url(asset), '', url(assets[candidate]), ('per-asset' if candidate == name + '.sha256' else 'named')
    raise ValueError('no published SHA256 checksum for ' + name + '; refusing unverified download')

def checksum(text, name, per_asset=False):
    found = []
    for line in text.splitlines():
        fields = line.strip().split(maxsplit=1)
        if len(fields) == 2 and HEX.fullmatch(fields[0]) and fields[1].lstrip('*') in (name, './' + name):
            found.append(digest(fields[0]))
        elif re.fullmatch(r'SHA256 \(' + re.escape(name) + r'\) = ([0-9a-fA-F]{64})', line.strip()):
            found.append(digest(line.strip().rsplit(' ', 1)[1]))
    # Per-asset .sha256 files sometimes contain only the digest.
    if per_asset and not found and HEX.fullmatch(text.strip()):
        found.append(digest(text.strip()))
    if len(found) != 1:
        raise ValueError('missing or ambiguous published checksum for ' + name)
    return found[0]

def verify(path, expected):
    expected = digest(expected)
    actual = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            actual.update(chunk)
    if actual.hexdigest() != expected:
        raise ValueError('SHA256 mismatch for ' + str(path) + '; refusing extraction')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['github', 'checksum', 'zig', 'verify'])
    parser.add_argument('values', nargs='+')
    args = parser.parse_args()
    if args.mode == 'github':
        metadata, repo, name = args.values
        print('\n'.join(github(json.loads(Path(metadata).read_text()), repo, name)))
    elif args.mode == 'checksum':
        file, name = args.values[:2]
        print(checksum(Path(file).read_text(), name, args.values[2:] == ['per-asset']))
    elif args.mode == 'zig':
        file, version, arch = args.values
        item = json.loads(Path(file).read_text())[version][arch + '-linux']
        url = item['tarball']
        if not url.startswith('https://ziglang.org/download/' + version + '/'):
            raise ValueError('Zig archive URL is outside the official release')
        print(url + '\n' + digest(item['shasum']))
    else:
        file, expected = args.values
        verify(file, expected)
        print('SHA256 verified: ' + Path(file).name)

if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, OSError) as err:
        print('Integrity check failed: ' + str(err), file=sys.stderr)
        sys.exit(1)
