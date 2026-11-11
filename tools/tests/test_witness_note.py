"""Regeneration must change only the derived vocabulary and make drift observable."""
from pathlib import Path
import json
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_witnesses as witnesses


class AuthorityNote(unittest.TestCase):
    def test_schema_change_is_detected_and_regeneration_preserves_owner_prose(self):
        source = Path(witnesses.COMMITTED) / 'authority-witnesses-v5.json'
        document = (Path(witnesses.COMMITTED) / 'witness-file-v1.md').read_text()
        before, rest = document.split(witnesses.NOTE_BEGIN)
        _, after = rest.split(witnesses.NOTE_END)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            emission = root / source.name
            corpus = json.loads(source.read_text())
            corpus['schema'] += 1
            emission.write_text(json.dumps(corpus))
            note = root / 'witness-file-v1.md'
            note.write_text(document)
            with patch.object(witnesses, 'COMMITTED', directory):
                self.assertEqual(len(witnesses.sync_authority_note([str(emission)], False)), 1)
                self.assertEqual(witnesses.sync_authority_note([str(emission)], True), [])
                self.assertEqual(witnesses.sync_authority_note([str(emission)], False), [])
            updated = note.read_text()
            self.assertEqual(updated.split(witnesses.NOTE_BEGIN)[0], before)
            self.assertEqual(updated.split(witnesses.NOTE_END)[1], after)

    def test_missing_and_duplicate_markers_are_refused_without_destroying_prose(self):
        source = str(Path(witnesses.COMMITTED) / 'authority-witnesses-v5.json')
        with tempfile.TemporaryDirectory() as directory:
            note = Path(directory) / 'witness-file-v1.md'
            with patch.object(witnesses, 'COMMITTED', directory):
                self.assertEqual(len(witnesses.sync_authority_note([source], False)), 1)
                for content in ('Owner prose', witnesses.NOTE_BEGIN * 2 + witnesses.NOTE_END):
                    note.write_text(content)
                    self.assertEqual(len(witnesses.sync_authority_note([source], True)), 1)
                    self.assertEqual(note.read_text(), content)
