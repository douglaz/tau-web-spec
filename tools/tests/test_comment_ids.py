"""Comment collisions, stable diagnostics, read-only execution, and runner failure."""

import itertools
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
GATE = ROOT / "tools/check_comment_ids.py"
EXPORT = Path(".beads/issues.jsonl")


def issue(identifier, *comment_ids, **fields):
    return {"id": identifier,
            "comments": [{"id": value, "text": "same private text"} for value in comment_ids],
            **fields}


class CommentIdentifiers(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "tools").mkdir()
        (self.root / ".beads").mkdir()
        shutil.copyfile(GATE, self.root / "tools/check_comment_ids.py")

    def write(self, records):
        (self.root / EXPORT).write_text(
            "".join(json.dumps(record) + "\n" for record in records), encoding="utf-8")

    def run_gate(self):
        # The script must discover its own root, independent of cwd and git.
        result = subprocess.run([sys.executable, str(self.root / "tools/check_comment_ids.py")],
                                cwd=self.root / "tools", capture_output=True, text=True)
        self.assertEqual(result.stderr, "")
        self.assertNotIn("same private text", result.stdout)
        return result.returncode, result.stdout

    def test_distinct_identifiers_pass_without_database_or_git(self):
        self.write([issue("tw-a", 7, 8), issue("tw-b", 9, status="closed"),
                    {"id": "tw-c"}, issue("tw-d")])
        before = (self.root / EXPORT).read_bytes()
        self.assertEqual(self.run_gate(), (0, "DUPLICATE COMMENT IDS: none\n"))
        self.assertEqual((self.root / EXPORT).read_bytes(), before)
        self.assertEqual({p.relative_to(self.root).as_posix()
                          for p in self.root.rglob("*") if p.is_file()},
                         {str(EXPORT), "tools/check_comment_ids.py"})

    def test_empty_export_passes(self):
        self.write([])
        self.assertEqual(self.run_gate(), (0, "DUPLICATE COMMENT IDS: none\n"))

    def test_collision_across_issues_includes_closed_owner(self):
        self.write([issue("tw-b", 7, status="closed"), issue("tw-a", 7)])
        self.assertEqual(self.run_gate(), (1,
            'DUPLICATE COMMENT IDS: 7 -> "tw-a" comments[1], "tw-b" comments[1]\n'))

    def test_collision_within_issue_preserves_positions(self):
        self.write([issue("tw-a", 7, 8, 7)])
        self.assertEqual(self.run_gate(), (1,
            'DUPLICATE COMMENT IDS: 7 -> "tw-a" comments[1], "tw-a" comments[3]\n'))

    def test_all_occurrences_and_groups_are_stable_under_record_reordering(self):
        records = [issue("tw-z", 7, 42, status="closed"),
                   issue("tw-a", 42, 7, 7), issue("tw-m", 7, 42)]
        expected = (1,
            'DUPLICATE COMMENT IDS: 42 -> "tw-a" comments[1], "tw-m" comments[2], '
            '"tw-z" comments[2]\n'
            'DUPLICATE COMMENT IDS: 7 -> "tw-a" comments[2], "tw-a" comments[3], '
            '"tw-m" comments[1], "tw-z" comments[1]\n')
        for ordering in itertools.permutations(records):
            with self.subTest(order=[record["id"] for record in ordering]):
                self.write(ordering)
                self.assertEqual(self.run_gate(), expected)
                self.write([issue("tw-unrelated", 123), *ordering, {"id": "tw-empty"}])
                self.assertEqual(self.run_gate(), expected)

    def test_gate_leaves_export_and_existing_database_files_untouched(self):
        # Deliberately unusable bytes also expose any attempt to open a database.
        for name in ("beads.db", "beads.db-wal", "beads.db-shm"):
            (self.root / ".beads" / name).write_bytes(b"not a database\x00\xff")
        for records in ([issue("tw-a", 7, 8)], [issue("tw-a", 7, 7)]):
            with self.subTest(records=records):
                self.write(records)
                before = {p.name: p.read_bytes() for p in (self.root / ".beads").iterdir()}
                self.assertEqual(self.run_gate()[0], 0 if len(records[0]["comments"]) ==
                                 len({c["id"] for c in records[0]["comments"]}) else 1)
                self.assertEqual({p.name: p.read_bytes()
                                  for p in (self.root / ".beads").iterdir()}, before)

    def test_null_identifier_is_rejected(self):
        self.write([issue("tw-a", None)])
        before = (self.root / EXPORT).read_bytes()
        self.assertEqual(self.run_gate(), (2,
            "COMMENT EXPORT ERROR: .beads/issues.jsonl: cannot read comment identifiers\n"))
        self.assertEqual((self.root / EXPORT).read_bytes(), before)

    def test_non_integer_identifiers_are_rejected(self):
        for identifier in (True, False, 7.0, "7", [], {}):
            with self.subTest(identifier=identifier):
                self.write([issue("tw-a", identifier)])
                before = (self.root / EXPORT).read_bytes()
                self.assertEqual(self.run_gate(), (2,
                    "COMMENT EXPORT ERROR: .beads/issues.jsonl: cannot read comment identifiers\n"))
                self.assertEqual((self.root / EXPORT).read_bytes(), before)

    def test_unreadable_input_has_one_finding_without_record_content(self):
        for raw in (None, b"{private malformed record", b"\xff\n",
                    b'{"id":"tw-a","comments":[{}]}\n',
                    b'{"comments":[{"id":7}]}\n',
                    b'{"id":"tw-a","comments":null}\n', b"null\n"):
            with self.subTest(raw=raw):
                path = self.root / EXPORT
                if raw is None:
                    path.unlink(missing_ok=True)
                else:
                    path.write_bytes(raw)
                self.assertEqual(self.run_gate(), (2,
                    "COMMENT EXPORT ERROR: .beads/issues.jsonl: cannot read comment identifiers\n"))
                if raw is not None:
                    self.assertEqual(path.read_bytes(), raw)

    def test_aggregate_runner_captures_collision_and_continues(self):
        shutil.copyfile(ROOT / "tools/check-all.sh", self.root / "tools/check-all.sh")
        (self.root / "tools/check_formal.sh").write_text('echo "formal ran"\n')
        # Keep the real runner and collision gate; isolate unrelated, expensive gates.
        for filename in ("check_witnesses.py", "check_regions.py", "render_state_machine_atlas.py",
                         "check_ids.py", "check_fixtures.py", "check_obligations.py",
                         "check_citations.py", "check_coverage.py"):
            (self.root / "tools" / filename).write_text(f'print("{filename} ran")\n')
        for comment_ids, other_failure, expected_status in (((7, 8), False, 0),
                                                           ((7, 7), False, 1),
                                                           ((7, 8), True, 1)):
            with self.subTest(comment_ids=comment_ids, other_failure=other_failure):
                self.write([issue("tw-a", *comment_ids)])
                (self.root / "tools/check_fixtures.py").write_text(
                    f"raise SystemExit({int(other_failure)})\n")
                result = subprocess.run(["bash", "tools/check-all.sh"], cwd=self.root,
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, expected_status, result.stdout + result.stderr)
                self.assertEqual(result.stderr, "")
                self.assertIn("check_coverage.py ran", result.stdout)
                self.assertTrue(result.stdout.index("formal ran") <
                                result.stdout.index("DUPLICATE COMMENT IDS:"))
                status = "FAIL" if comment_ids == (7, 7) else "PASS"
                self.assertRegex(result.stdout, rf"{status}\s+comment ids")
                self.assertIn("One or more gates FAILED." if expected_status else
                              "All gates passed.", result.stdout)


if __name__ == "__main__":
    unittest.main()
