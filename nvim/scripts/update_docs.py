#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Build immutable, indexed Perfect Black manuals; publish only complete sets."""
import argparse
import fcntl
from html.parser import HTMLParser
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import tempfile
import time
import urllib.request
import uuid

CATALOG = {"python": {"slug": "python~3.14", "lang": "python"},
           "c": {"slug": "c", "lang": "c"}, "cpp": {"slug": "cpp", "lang": "cpp"},
           "lua": {"slug": "lua~5.1", "lang": "lua"},
           "bash": {"slug": "bash", "lang": "bash"}, "cmake": {"slug": "cmake", "lang": "cmake"}}


class Node:
    def __init__(self, tag="", attrs=()):
        self.tag, self.attrs, self.children = tag, dict(attrs), []


class Document(HTMLParser):
    def __init__(self, source):
        super().__init__(convert_charrefs=True)
        self.root = Node()
        self.stack = [self.root]
        self.feed(source)

    def handle_starttag(self, tag, attrs):
        node = Node(tag, attrs)
        self.stack[-1].children.append(node)
        if tag not in {"br", "hr", "img", "meta", "link", "input", "wbr", "source"}:
            self.stack.append(node)

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        self.handle_endtag(tag)

    def handle_endtag(self, tag):
        for i in range(len(self.stack) - 1, 0, -1):
            if self.stack[i].tag == tag:
                del self.stack[i:]
                return

    def handle_data(self, data):
        self.stack[-1].children.append(data)


def plain(node):
    return node if isinstance(node, str) else "".join(plain(c) for c in node.children)


def markdown(source, language):
    """Keep actual declarations and code intact; never synthesize API details."""
    def render(node):
        if isinstance(node, str):
            return re.sub(r"\s+", " ", node)
        tag = node.tag
        if tag in {"script", "style", "nav"}:
            return ""
        if tag == "pre":
            text = plain(node).strip("\n")
            fence = "`" * max(3, max((len(m.group()) + 1 for m in re.finditer(r"`+", text)), default=3))
            return f"\n\n{fence}{language}\n{text}\n{fence}\n\n"
        if tag == "code":
            text = plain(node)
            fence = "`" * max(1, max((len(m.group()) + 1 for m in re.finditer(r"`+", text)), default=1))
            return fence + text + fence
        if tag == "table":
            rows = []
            def visit(current):
                if isinstance(current, str): return
                if current.tag == "tr":
                    cells = [re.sub(r"\s+", " ", render(c)).strip().replace("|", "\\|")
                             for c in current.children if isinstance(c, Node) and c.tag in {"td", "th"}]
                    if cells: rows.append(cells)
                else:
                    for child in current.children: visit(child)
            visit(node)
            if not rows: return ""
            width = max(map(len, rows))
            rows = [r + [""] * (width - len(r)) for r in rows]
            rows.insert(1, ["---"] * width)
            return "\n\n" + "\n".join("| " + " | ".join(r) + " |" for r in rows) + "\n\n"
        if tag == 'ol':
            items = [c for c in node.children if isinstance(c, Node) and c.tag == 'li']
            return '\n\n' + '\n'.join(f'{i}. ' + ''.join(render(c) for c in item.children).strip().replace('\n', '\n   ')
                                      for i, item in enumerate(items, 1)) + '\n\n'
        body = "".join(render(c) for c in node.children)
        if re.fullmatch(r"h[1-6]", tag): return "\n\n" + "#" * int(tag[1]) + " " + body.strip() + "\n\n"
        if tag in {"strong", "b"}: return "**" + body.strip() + "**"
        if tag in {"em", "i"}: return "*" + body.strip() + "*"
        if tag == "a":
            href = node.attrs.get("href", "")
            return "[" + body.strip() + "](" + href + ")" if href and body.strip() else body
        if tag == "li": return "\n- " + body.strip().replace("\n", "\n  ") + "\n"
        if tag == "dt": return "\n\n" + body.strip() + "\n"
        if tag == "dd": return "\n" + body.strip() + "\n\n"
        if tag == "br": return "\n"
        if tag == "hr": return "\n\n---\n\n"
        if tag in {"p", "div", "section", "article", "ul", "ol", "dl", "blockquote"}:
            return "\n\n" + body.strip() + "\n\n"
        return body
    text = render(Document(source).root)
    # Do not normalize whitespace inside code fences.
    pieces, in_code = [], False
    for line in text.splitlines():
        if line.startswith("```"): in_code = not in_code
        if in_code or line.strip() or not pieces or pieces[-1] != "": pieces.append(line.rstrip() if not in_code else line)
    return "\n".join(pieces).strip() + "\n"


def safe_path(value):
    if not isinstance(value, str) or not value or "\\" in value or "\x00" in value:
        raise ValueError(f"Unsafe page path: {value!r}")
    path = PurePosixPath(value.split("#", 1)[0])
    if path.is_absolute() or ".." in path.parts or not path.parts:
        raise ValueError(f"Unsafe page path: {value!r}")
    return path


def normalize(name):
    return re.sub(r"\(\)$", "", name.strip())


def indexed(entries):
    exact, suffix = {}, {}
    for i, entry in enumerate(entries, 1):
        if not isinstance(entry, dict) or not isinstance(entry.get("name"), str):
            raise ValueError("Invalid documentation entry")
        safe_path(entry.get("path"))
        name = normalize(entry["name"])
        if name in exact: exact[name] = False
        else: exact[name] = i
        parts = re.split(r"::|\.", name)
        for offset in range(1, len(parts)):
            # Preserve the original separator spelling.
            candidate = re.split(r"(?<=::)|(?<=\.)", name)
            tail = "".join(candidate[offset:])
            if tail in suffix and suffix[tail] != i: suffix[tail] = False
            else: suffix[tail] = i
    return {"entries": entries, "exact": exact, "suffix": suffix}


def download(slug, part):
    request = urllib.request.Request(f"https://documents.devdocs.io/{slug}/{part}.json",
                                    headers={"User-Agent": "1337-session offline docs"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def load_manifest(data):
    path = data / "manifest.json"
    if not path.exists(): return {"schema": 1, "docsets": {}}
    manifest = json.loads(path.read_text())
    if manifest.get("schema") != 1 or not isinstance(manifest.get("docsets"), dict):
        raise ValueError("Invalid existing documentation manifest; refusing to replace it")
    return manifest


def atomic_json(path, value):
    temporary = path.with_name(path.name + ".tmp-" + uuid.uuid4().hex)
    try:
        with temporary.open("w", encoding="utf-8") as file:
            json.dump(value, file, ensure_ascii=False, separators=(",", ":"))
            file.flush()
            os.fsync(file.fileno())
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def prune_generations(parent, current, previous):
    """Keep the published generation and its rollback; never follow symlinks."""
    keep = {current}
    if previous:
        old = PurePosixPath(previous)
        if len(old.parts) == 3 and old.parts[:2] == ('sets', parent.name):
            keep.add(old.parts[2])
    for child in parent.iterdir():
        if child.name in keep or child.is_symlink() or not child.is_dir(): continue
        if re.fullmatch(r'[0-9]+-[0-9a-f]{12}', child.name):
            shutil.rmtree(child)


def update(name, catalog, data, existing=None):
    if not re.fullmatch(r"[a-zA-Z0-9_-]+", name): raise ValueError("Unsafe docset name")
    settings = catalog[name]
    slug, language = settings["slug"], settings["lang"]
    if not isinstance(slug, str) or not re.fullmatch(r'[A-Za-z0-9_.~-]+', slug):
        raise ValueError('Unsafe docset slug')
    if not isinstance(language, str) or not re.fullmatch(r'[A-Za-z0-9_+-]+', language):
        raise ValueError('Invalid documentation language')
    print(f"{name}: {'importing' if existing else 'downloading'} {slug}…", flush=True)
    source = existing / slug if existing else None
    index = json.loads((source / "index.json").read_text()) if source else download(slug, "index")
    entries = index.get("entries")
    if not isinstance(entries, list) or not entries: raise ValueError("Empty or invalid index")
    maps = indexed(entries)
    pages = None if source else download(slug, "db")
    if pages is not None and (not isinstance(pages, dict) or not pages): raise ValueError("Empty or invalid page database")
    data.mkdir(parents=True, exist_ok=True)
    parent = data / "sets" / name
    parent.mkdir(parents=True, exist_ok=True)
    generation = f"{int(time.time())}-{uuid.uuid4().hex[:12]}"
    stage = Path(tempfile.mkdtemp(prefix=".build-", dir=parent))
    destination = parent / generation
    published = False
    try:
        paths = {str(safe_path(e["path"])) for e in entries}
        count, size = 0, 0
        for path in sorted(paths):
            if source:
                file = source / "pages-md" / (path + ".md")
                text = file.read_text(encoding="utf-8")
            else:
                if path not in pages or not isinstance(pages[path], str): raise ValueError(f"Missing page: {path}")
                text = markdown(pages[path], language)
            if not text.strip(): raise ValueError(f"Empty page: {path}")
            target = stage / "pages" / (path + ".md")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text, encoding="utf-8")
            count += 1
            size += len(text.encode("utf-8"))
            if count % 500 == 0: print(f"{name}: converted {count}/{len(paths)} pages", flush=True)
        atomic_json(stage / "index.json", maps)
        stage.rename(destination)
        manifest = load_manifest(data)
        previous = manifest['docsets'].get(name, {}).get('root')
        manifest["docsets"][name] = dict(settings, updated_at=int(time.time()),
            root=str(destination.relative_to(data)), entries=len(entries), pages=count, bytes=size)
        atomic_json(data / "manifest.json", manifest)
        published = True
        try:
            prune_generations(parent, generation, previous)
        except OSError as error:
            print(f'{name}: ready; older generation cleanup deferred: {error}', flush=True)
        print(f"{name}: ready · {len(entries)} entries / {count} pages", flush=True)
    except BaseException:
        shutil.rmtree(stage, ignore_errors=True)
        # Never remove old published generations. This one was never published.
        if not published: shutil.rmtree(destination, ignore_errors=True)
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("docset", nargs="?", default="all")
    parser.add_argument("--data", type=Path, default=Path(os.environ.get("XDG_DATA_HOME", Path.home()/".local/share"))/"nvim/perfect-black/docs")
    parser.add_argument("--catalog", type=Path, help="JSON mapping docset names to slug/lang")
    parser.add_argument("--import-existing", type=Path, help="Import existing DevDocs pages-md without network")
    args = parser.parse_args()
    catalog = json.loads(args.catalog.read_text()) if args.catalog else CATALOG
    names = list(catalog) if args.docset == "all" else [args.docset]
    if any(name not in catalog for name in names): parser.error("Unknown docset; provide --catalog to add one")
    args.data.mkdir(parents=True, exist_ok=True)
    failed = False
    with (args.data / "update.lock").open("a") as lock:
        try: fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError: parser.exit(2, "Documentation update already running\n")
        for name in names:
            try: update(name, catalog, args.data, args.import_existing)
            except Exception as error:
                failed = True
                print(f"{name}: update failed; existing docs preserved: {error}", flush=True)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
