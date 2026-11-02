"""Attribution validation and diagnostics against an isolated document corpus."""

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
AUTHENTIC = "in the operator's head or seed backup"
FABRICATED = "a thief who unlocks the store has it"
BARRIER = "The unresolved barrier holds per resource, not per call"


class Citations(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "tools/formal/.lake").mkdir(parents=True)
        for name in ("check_citations.py", "check_ids.py"):
            shutil.copyfile(ROOT / "tools" / name, self.root / "tools" / name)
        # Use the real operator-seed row, so a fixture paraphrase cannot
        # accidentally bless the original seed-row misquotation.
        inventory = (ROOT / "04-security-model.md").read_text()
        inventory = next(line for line in inventory.splitlines()
                         if line.startswith("| 15 | **Operator seed** |"))
        (self.root / "04-security-model.md").write_text("**SEC-5** Credential inventory.\n" + inventory)
        (self.root / "03-state-and-recovery.md").write_text(
            f"**STA-24** {BARRIER}.\n\n**STA-25** A separate requirement body.\n")
        (self.root / "tools/formal/.lake/index.jsonl").write_text(
            '{"decl":"TauWeb.Allocation.total","req":"STA-22a"}\n')
        (self.root / "tools/formal/TauWeb.lean").write_text("import TauWeb.Allocation\n")
        self.baseline({})

    def baseline(self, counts):
        (self.root / "tools/citation-baseline.json").write_text(json.dumps({
            "unquoted_attributions": counts, "recorded": "2026-11-02", "reason": "test corpus"}))

    def check(self, text, *, bad=(), unquoted=(), dangling=(), path="00-overview.md"):
        document = self.root / path
        document.parent.mkdir(parents=True, exist_ok=True)
        document.write_text(text)
        result = subprocess.run([sys.executable, "tools/check_citations.py"],
                                cwd=self.root, text=True, capture_output=True)
        self.assertEqual(result.stderr, "")
        self.assertEqual(result.returncode, int(bool(bad or unquoted or dangling)), result.stdout)
        for label, expected in (("UNVERIFIED QUOTES", bad),
                                ("NEW UNQUOTED ATTRIBUTIONS", unquoted),
                                ("UNRESOLVED TAUWEB NAMES", dangling)):
            line = f"{label}: {sorted(expected) if expected else 'none'}"
            self.assertIn(line + "\n", result.stdout)
        return result.stdout

    def test_seed_row_reproduction_checks_owner_and_finding(self):
        self.check(f'`SEC-5`\'s seed row says "{FABRICATED}".', bad=("00-overview.md:SEC-5",))
        self.check(f'`SEC-5`\'s seed row says "{AUTHENTIC}".')

    def test_present_speech_and_existing_possessive_that_forms(self):
        forms = [f"`SEC-5` {own}{verb}" for own in ("", "own ")
                 for verb in ("says", "states", "reads")]
        forms += ["`SEC-5` own\nsays", "`SEC-5`'s own rule\nthat"]
        forms += [f"`SEC-5`'s {own}{label}row {verb}"
                  for own in ("", "own ") for label in ("", "seed ", "operator-seed inventory ")
                  for verb in ("says", "states", "reads")]
        forms += [f"`SEC-5`'s {own}{noun} that" for own in ("", "own ")
                  for noun in ("rule", "claim", "wording", "statement", "sentence", "words", "text")]
        for form in forms:
            with self.subTest(form=form):
                self.check(f'{form} "{AUTHENTIC}".')
                self.check(f'{form} "{FABRICATED}".', bad=("00-overview.md:SEC-5",))

    def test_normalization_and_ellipsis_fragments_through_row(self):
        for quote in ('“IN THE **OPERATOR’S** head or `seed` backup”',
                      '"in the operator\'s\n head\t or seed backup"',
                      '"in the operator\'s head … seed backup"',
                      '“in the operator’s head ...seed backup”'):
            with self.subTest(quote=quote):
                self.check(f"`SEC-5`'s seed row states {quote}.")
        self.check('`SEC-5`\'s seed row states "in the operator\'s head … invented backup location".',
                   bad=("00-overview.md:SEC-5",))
        self.check('`SEC-5`\'s seed row states "in the operator\'s head ...invented backup location".',
                   bad=("00-overview.md:SEC-5",))

    def test_paired_quotes_and_minimum_length_are_preserved(self):
        for quote in ('"a thief who unlocks the store has it”', '"no"',
                      '“operator seed backup”', '"' + 'word ' * 81 + '"'):
            with self.subTest(quote=quote):
                self.check(f"`SEC-5`'s seed row says {quote}.",
                           unquoted=("00-overview.md:SEC-5",))

    def test_summary_and_historical_neighbors_stay_excluded(self):
        for subject in ("`SEC-5`", "`SEC-5`'s seed row"):
            for verb in ("forbids", "requires", "describes", "said", "stated", "read"):
                with self.subTest(subject=subject, verb=verb):
                    self.check(f'{subject} {verb} "{FABRICATED}".')

    def test_reads_checks_quoted_text_but_ignores_consultation(self):
        for subject in ("`SEC-5`", "`SEC-5` own", "`SEC-5`'s seed row",
                        "`SEC-5`'s seed\nrow"):
            with self.subTest(subject=subject):
                self.check(f"{subject} reads it from the sheet.")
                self.check(f'{subject} reads "{AUTHENTIC}".')
                self.check(f'{subject} reads "{FABRICATED}".', bad=("00-overview.md:SEC-5",))

    def test_row_bridge_is_bounded_and_does_not_cross_prose_boundaries(self):
        for subject in ("`SEC-5`'s\nseed row", "`SEC-5`'s seed\nrow",
                        "`SEC-5`'s seed row\n", "`SEC-5`'s own\nseed row",
                        "`SEC-5`'s operator-seed\n inventory row",
                        "`SEC-5`'s\n own\n operator-seed\n inventory\n row\n"):
            for verb in ("says", "states", "reads"):
                with self.subTest(subject=subject, verb=verb):
                    self.check(f'{subject} {verb} "{FABRICATED}".',
                               bad=("00-overview.md:SEC-5",))
                    self.check(f'{subject} {verb} "{AUTHENTIC}".')

        for bridge in ("seed inventory credential row says", "seed; row says",
                       "seed. row says", "seed | row says",
                       "x" * 33 + " row says", "seed row sometimes says",
                       "seed\n inventory credential row says",
                       "x" * 33 + "\n row says",
                       "seed row said", "seed rows say"):
            with self.subTest(bridge=bridge):
                self.check(f'`SEC-5`\'s {bridge} "{FABRICATED}".')
        for separator in ("; ", ": ", ". ", "! ", "? ", " | ",
                          "\n\n", "\n \t\n", "\n- ", "\n* ", "\n| "):
            for left, right in (("`SEC-5`'s", "seed row says"),
                                ("`SEC-5`'s seed", "row says"),
                                ("`SEC-5`'s seed row", "says")):
                with self.subTest(separator=separator, left=left):
                    self.check(f'{left}{separator}{right} "{FABRICATED}".')

    def test_adjacent_attributions_keep_their_own_quotations(self):
        forms = ("`SEC-5` says", "`SEC-5`'s claim that", "`SEC-5`'s seed row states",
                 "`SEC-5`'s\nseed row\nstates")
        neighbors = ("`STA-24` says", "`STA-24`'s rule that", "`STA-24`'s barrier row says",
                     "`STA-24`'s barrier\nrow says")
        for form in forms:
            for neighbor in neighbors:
                with self.subTest(form=form, neighbor=neighbor):
                    self.check(f'{form} "{FABRICATED}", and {neighbor} "{BARRIER}".',
                               bad=("00-overview.md:SEC-5",))
                    self.check(f'{form} an assertion, and {neighbor} "{BARRIER}".',
                               unquoted=("00-overview.md:SEC-5",))
                    self.check(f'{form} "{AUTHENTIC}", and {neighbor} "{FABRICATED}".',
                               bad=("00-overview.md:STA-24",))

    def test_sentence_list_and_table_boundaries_do_not_supply_a_quote(self):
        for separator in (". ", "! ", "? ", "\n\n", ";\n- ", ";\n* ", " |\n| "):
            with self.subTest(separator=separator):
                self.check(f'`SEC-5`\'s seed row says an assertion{separator}"{AUTHENTIC}".',
                           unquoted=("00-overview.md:SEC-5",))
                self.check(f'`SEC-5`\'s seed row says "{FABRICATED}"{separator}'
                           f'`STA-24` says "{BARRIER}".', bad=("00-overview.md:SEC-5",))
        self.check(f'"{AUTHENTIC}" precedes `SEC-5`\'s seed row says an assertion.',
                   unquoted=("00-overview.md:SEC-5",))

    def test_owner_body_does_not_include_neighboring_requirement(self):
        self.check(f'`STA-25`\'s barrier row says "{BARRIER}".', bad=("00-overview.md:STA-25",))

    def test_unquoted_ratchet_keeps_per_file_id_counts(self):
        for form in ("`SEC-5` says", "`SEC-5` own states", "`SEC-5`'s own rule that",
                     "`SEC-5`'s seed row states", "`SEC-5`'s seed\nrow states"):
            with self.subTest(form=form):
                self.baseline({})
                self.check(f"{form} an assertion.", unquoted=("00-overview.md:SEC-5",))
                self.baseline({"00-overview.md:SEC-5": 1})
                self.check(f"{form} an assertion.")
                output = self.check(f"{form} an assertion. {form} another assertion.",
                                    unquoted=("00-overview.md:SEC-5",))
                self.assertIn("unquoted attributions: 2 against baseline 1", output)

    def test_scanned_paths_and_dated_records(self):
        for path in ("00-overview.md", "docs/adr/9999-test.md", "docs/design/test.md",
                     "docs/tenants/test/profile.md", "docs/state-machine-atlas.md",
                     "docs/review/test.md", "docs/findings/test.md"):
            with self.subTest(path=path):
                # Each iteration replaces the only citing document in the corpus.
                self.check(f'`SEC-5`\'s seed row says "{FABRICATED}".', path=path,
                           bad=() if path.startswith(("docs/review/", "docs/findings/"))
                           else (f"{path}:SEC-5",))
                (self.root / path).unlink()

    def test_lean_name_validation_still_runs(self):
        self.check(f'`SEC-5`\'s seed row says "{AUTHENTIC}"; `TauWeb.Allocation.total`.')
        self.check(f'`SEC-5`\'s seed row says "{AUTHENTIC}"; `TauWeb.Missing`.',
                   dangling=("00-overview.md:TauWeb.Missing",))


if __name__ == "__main__":
    unittest.main()
