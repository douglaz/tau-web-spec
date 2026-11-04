"""Local paths in the tracked issue export: findings, stable diagnostics, read-only execution."""

import itertools
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
GATE = ROOT / "tools/check_tracker_paths.py"
EXPORT = Path(".beads/issues.jsonl")
CLEAN = "SOURCE REPO PATH: none\nLOCAL PATH: none\n"
ERROR = "TRACKER EXPORT ERROR: .beads/issues.jsonl: cannot read the issue export\n"
PRIVATE = "/home/alice/private-checkout"


class TrackerPaths(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "tools").mkdir()
        (self.root / ".beads").mkdir()
        shutil.copyfile(GATE, self.root / "tools/check_tracker_paths.py")

    def write(self, records):
        (self.root / EXPORT).write_text(
            "".join(json.dumps(record) + "\n" for record in records), encoding="utf-8")

    def run_gate(self):
        # The script must discover its own root, independent of cwd and git.
        result = subprocess.run([sys.executable, str(self.root / "tools/check_tracker_paths.py")],
                                cwd=self.root / "tools", capture_output=True, text=True)
        self.assertEqual(result.stderr, "")
        self.assertNotIn("alice", result.stdout)
        return result.returncode, result.stdout

    def test_clean_export_passes_without_database_or_git(self):
        self.write([{"id": "tw-a", "source_repo": "tau-web", "description": "plain"},
                    {"id": "tw-b", "status": "closed", "comments": [{"id": 1, "text": "x"}]}])
        before = (self.root / EXPORT).read_bytes()
        self.assertEqual(self.run_gate(), (0, CLEAN))
        self.assertEqual((self.root / EXPORT).read_bytes(), before)
        self.assertEqual({p.relative_to(self.root).as_posix()
                          for p in self.root.rglob("*") if p.is_file()},
                         {str(EXPORT), "tools/check_tracker_paths.py"})

    def test_empty_export_passes(self):
        self.write([])
        self.assertEqual(self.run_gate(), (0, CLEAN))

    def test_source_repo_path_is_refused_whatever_its_value(self):
        # The key itself is the finding: an empty, null or relative value is refused too.
        for value in (PRIVATE, "", None, ".", "tau-web", [], {}):
            with self.subTest(value=value):
                self.write([{"id": "tw-a", "source_repo": "tau-web", "source_repo_path": value}])
                self.assertEqual(self.run_gate(), (1,
                    'SOURCE REPO PATH: "tw-a" source_repo_path\nLOCAL PATH: none\n'))

    def test_nested_source_repo_path_names_its_field(self):
        self.write([{"id": "tw-a", "comments": [{"id": 1}, {"id": 2, "source_repo_path": "x"}]}])
        self.assertEqual(self.run_gate(), (1,
            'SOURCE REPO PATH: "tw-a" comments[2].source_repo_path\nLOCAL PATH: none\n'))

    def test_local_paths_in_any_string_field_are_named_by_field(self):
        for text in (PRIVATE, f"see `{PRIVATE}/notes`", "(/Users/alice/x)", "/tmp/run.1",
                     "wrote /var/tmp/lane-1/out", "a\n/home/alice", "path:/home/alice/notes",
                     ":/tmp/x", "see (path:/Users/alice)", "file:///tmp/run/log",
                     "FILE:///home/alice", "file://localhost/var/tmp/lane",
                     "/tmp/.private-checkout/notes", "/var/tmp/.worktree/notes", "/home/.alice",
                     "/tmp/-lane", "/Users/..alice"):
            with self.subTest(text=text):
                self.write([{"id": "tw-a", "description": "plain",
                             "comments": [{"id": 1, "text": "plain"}, {"id": 2, "text": text}]}])
                self.assertEqual(self.run_gate(), (1,
                    'SOURCE REPO PATH: none\nLOCAL PATH: "tw-a" comments[2].text\n'))

    def test_paths_that_are_not_this_machines_local_paths_pass(self):
        # Machine paths the specification names, relative paths, URLs and bare roots.
        for text in ("/root/.ssh/authorized_keys", "/var/lib/tau", "/etc/hosts", "lib/tmp/x",
                     "https://example.com/home/alice", "~/tmp/x", "a-/tmp/x", "/home/", "/tmp",
                     "/home/...", "tools/check-controls.sh", "http://host:8080/tmp/x",
                     "https://example.com:443/home/alice", "file://example.com/tmp/x",
                     "https:/x/home/alice", "s3://bucket/tmp/x", "/tmp/.", "/home/.../x",
                     "/var/tmp/-"):
            with self.subTest(text=text):
                self.write([{"id": "tw-a", "description": text}])
                self.assertEqual(self.run_gate(), (0, CLEAN))

    def test_key_and_local_path_in_one_record_are_two_findings(self):
        self.write([{"id": "tw-a", "source_repo_path": PRIVATE, "notes": PRIVATE}])
        self.assertEqual(self.run_gate(), (1,
            'SOURCE REPO PATH: "tw-a" source_repo_path\nLOCAL PATH: "tw-a" notes\n'))

    def test_findings_are_stable_under_record_reordering(self):
        records = [{"id": "tw-z", "source_repo_path": PRIVATE, "status": "closed"},
                   {"id": "tw-a", "title": "/tmp/x", "description": PRIVATE},
                   {"id": "tw-m", "source_repo_path": PRIVATE}]
        expected = (1,
            'SOURCE REPO PATH: "tw-m" source_repo_path\n'
            'SOURCE REPO PATH: "tw-z" source_repo_path\n'
            'LOCAL PATH: "tw-a" description\n'
            'LOCAL PATH: "tw-a" title\n')
        for ordering in itertools.permutations(records):
            with self.subTest(order=[record["id"] for record in ordering]):
                self.write([*ordering, {"id": "tw-clean"}])
                self.assertEqual(self.run_gate(), expected)

    def test_gate_leaves_export_and_existing_database_files_untouched(self):
        for name in ("beads.db", "beads.db-wal", "beads.db-shm"):
            (self.root / ".beads" / name).write_bytes(b"not a database\x00\xff")
        for record, status in (({"id": "tw-a"}, 0), ({"id": "tw-a", "source_repo_path": "x"}, 1)):
            with self.subTest(record=record):
                self.write([record])
                before = {p.name: p.read_bytes() for p in (self.root / ".beads").iterdir()}
                self.assertEqual(self.run_gate()[0], status)
                self.assertEqual({p.name: p.read_bytes()
                                  for p in (self.root / ".beads").iterdir()}, before)

    def test_unreadable_input_has_one_finding_without_record_content(self):
        for raw in (None, b"{" + PRIVATE.encode() + b" malformed", b"\xff\n", b"null\n",
                    b'["tw-a"]\n', b'{"title":"' + PRIVATE.encode() + b'"}\n',
                    b'{"id":7}\n', b'{"id":null}\n'):
            with self.subTest(raw=raw):
                path = self.root / EXPORT
                if raw is None:
                    path.unlink(missing_ok=True)
                else:
                    path.write_bytes(raw)
                self.assertEqual(self.run_gate(), (2, ERROR))
                if raw is not None:
                    self.assertEqual(path.read_bytes(), raw)


if __name__ == "__main__":
    unittest.main()
