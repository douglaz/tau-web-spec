"""Improved coverage must not make regression controls vacuous."""
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import coverage_control


class CoverageControl(unittest.TestCase):
    def test_padding_consumes_only_slack_and_preserves_baseline(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            baseline = root / 'baseline.json'
            baseline.write_text('{"max_uncovered_ratcheted": 4}')
            document = root / '03-state-and-recovery.md'
            document.write_text('Owner prose\n')
            api = coverage_control.coverage
            with patch.object(api, 'ROOT', directory), patch.object(api, 'BASELINE', str(baseline)), \
                 patch.object(api, 'measure', return_value=({'STA-24': '03-state-and-recovery.md'}, ['STA-24'])):
                coverage_control.consume_slack()
                self.assertEqual(document.read_text().count('**STA-'), 3)
                document.write_text('Owner prose\n')
                coverage_control.consume_slack(1)
                self.assertEqual(document.read_text().count('**STA-'), 4)
                self.assertTrue(document.read_text().startswith('Owner prose\n'))
                self.assertEqual(baseline.read_text(), '{"max_uncovered_ratcheted": 4}')
