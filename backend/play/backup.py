"""Take an atomic, consistent SQLite snapshot without copying a live WAL file."""
import os
import sqlite3
import sys
from contextlib import closing
from datetime import datetime, timezone
from pathlib import Path
from tempfile import NamedTemporaryFile


def daily_snapshot(database: Path, destination: Path, keep: int = 14) -> Path:
    destination.mkdir(mode=0o700, parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    published = destination / f"receipts-{stamp}.sqlite3"
    if published.exists():
        return published
    with NamedTemporaryFile(dir=destination, prefix="receipts-", suffix=".tmp", delete=False) as temporary:
        staged = Path(temporary.name)
    try:
        with closing(sqlite3.connect(database.resolve().as_uri() + "?mode=ro", uri=True)) as source:
            with closing(sqlite3.connect(staged)) as copy:
                source.backup(copy)
                if copy.execute("PRAGMA quick_check").fetchone() != ("ok",):
                    raise RuntimeError("SQLite snapshot validation failed")
        staged.replace(published)
    finally:
        staged.unlink(missing_ok=True)
    for record in sorted(destination.glob("receipts-????-??-??.sqlite3"), reverse=True)[keep:]:
        record.unlink()
    return published


if __name__ == "__main__":
    os.umask(0o077)
    database_path = Path(os.environ["HBT_PLAY_DB"])
    if database_path.is_file():
        result = daily_snapshot(database_path, Path(sys.argv[1]))
        print(f"SQLite snapshot ready {result.name}")
    else:
        print("Awaiting first verifier database initialization")
