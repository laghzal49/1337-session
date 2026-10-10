"""Copy a project .venv to local storage, retaining the original as a backup."""
import argparse
import json
import os
from pathlib import Path
import shutil
import sys
import uuid


def migrate(source, target):
    source, target = Path(source).absolute(), Path(target).absolute()
    if source.name != '.venv' or source.is_symlink() or not source.is_dir():
        raise ValueError('Source must be a real project .venv directory')
    if not (source / 'pyvenv.cfg').is_file():
        raise ValueError('Source does not contain pyvenv.cfg')
    if target.exists() or target.is_symlink():
        raise ValueError('Destination already exists; nothing was overwritten')
    if source == target or source in target.parents or target in source.parents:
        raise ValueError('Source and destination must be separate directories')
    target.parent.mkdir(parents=True, exist_ok=True)
    suffix = uuid.uuid4().hex
    staging = target.with_name(target.name + '.copy-' + suffix)
    backup = source.with_name(source.name + '.backup-' + suffix)
    lock = source.with_name(source.name + '.migration.lock')
    descriptor = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    os.close(descriptor)
    moved = False
    try:
        identity = source.stat()
        shutil.copytree(source, staging, symlinks=True)
        current = source.lstat()
        if source.is_symlink() or (current.st_dev, current.st_ino) != (identity.st_dev, identity.st_ino):
            raise RuntimeError('Source changed during migration; original left in place')
        if target.exists() or target.is_symlink():
            raise RuntimeError('Destination appeared during copy; original left in place')
        staging.rename(target)
        source.rename(backup)
        moved = True
        source.symlink_to(target, target_is_directory=True)
        return {'source': str(source), 'target': str(target), 'backup': str(backup)}
    except Exception:
        if moved and not source.exists() and not source.is_symlink():
            backup.rename(source)
        # Only a uniquely named unpublished copy is removed. Original backups
        # and a completed destination copy remain available for recovery.
        if staging.exists():
            shutil.rmtree(staging)
        raise
    finally:
        lock.unlink(missing_ok=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', required=True)
    parser.add_argument('--target', required=True)
    args = parser.parse_args()
    try:
        print(json.dumps(migrate(args.source, args.target)))
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
