import sqlite3
import unittest
from contextlib import closing
from pathlib import Path
from tempfile import TemporaryDirectory

from backup import daily_snapshot


class BackupTests(unittest.TestCase):
    def test_backup_reads_live_wal_and_never_replaces_daily_snapshot(self):
        with TemporaryDirectory() as folder:
            root = Path(folder)
            database = root / "receipt.sqlite"
            with closing(sqlite3.connect(database)) as writer:
                writer.execute("PRAGMA journal_mode=WAL")
                writer.execute("CREATE TABLE receipt (status TEXT)")
                writer.execute("INSERT INTO receipt VALUES ('first')")
                writer.commit()
                published = daily_snapshot(database, root / "backups")
                writer.execute("INSERT INTO receipt VALUES ('later')")
                writer.commit()
                self.assertEqual(daily_snapshot(database, root / "backups"), published)
            with closing(sqlite3.connect(published)) as snapshot:
                self.assertEqual(snapshot.execute("SELECT status FROM receipt").fetchall(), [("first",)])
                self.assertEqual(snapshot.execute("PRAGMA quick_check").fetchone(), ("ok",))
            self.assertEqual(published.stat().st_mode & 0o777, 0o600)
            self.assertFalse(list(published.parent.glob("*.tmp")))


if __name__ == "__main__":
    unittest.main()
