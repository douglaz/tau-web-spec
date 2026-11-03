"""Offline structural pair checks; no protocol outcomes are recomputed."""

import json
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_witnesses as gate
from witness_pair_cases import NEGATIVE, POSITIVE, SERIALIZED, mutate, serialized_mutation, verify

ROOT = Path(gate.ROOT)


def trace(declaration, partner, side, value=1):
    return {'declarations': [declaration], 'pair': {'side': side, 'with': partner},
            'start': {'value': value}, 'assumptions': {'guard': side == 'refused'},
            'steps': [{'event': {'kind': 'input', 'nested': {'array': [1, 2]},
                                 'provenance': 'source'}, 'outcome': 'same'}]}


def pair(value=1):
    return [trace('A', 'B', 'refused', value), trace('B', 'A', 'admitted', value)]


class WitnessPairs(unittest.TestCase):
    def findings(self, corpus):
        return gate.pair_findings(corpus, 'test-witnesses-v1.json')

    def test_corpus_and_controls(self):
        for case in (*NEGATIVE, *POSITIVE):
            if case in SERIALIZED:
                continue  # Raw serialized cases exercise decoding through main.
            module = 'dispatch' if case in ('repeated', 'repeated_valid') else 'allocation'
            source, = (ROOT / 'docs/design').glob(f'{module}-witnesses-v*.json')
            corpus = json.loads(source.read_text())
            mutate(corpus, case)
            with self.subTest(case=case):
                findings = self.findings(corpus)
                if case in NEGATIVE:
                    self.assertEqual(len(findings), 1, findings)
                    self.assertIn(NEGATIVE[case], findings[0])
                    self.assertIn('declarations=', findings[0])
                    self.assertIn('$[', findings[0])
                else:
                    self.assertEqual(findings, [])

    def test_every_emitted_file(self):
        files = sorted(Path(gate.EMITTED).glob(gate.SUFFIX_GLOB))
        self.assertTrue(files, 'check-all must produce the current emission first')
        for source in files:
            with self.subTest(source=source.name):
                self.assertEqual(gate.pair_findings(json.loads(source.read_text()), source.name), [])

    def test_repeated_declarations_match_inputs_independently_of_order(self):
        a, b = pair(1)
        c, d = pair(2)
        self.assertEqual(self.findings([d, a, c, b]), [])
        d['steps'][0]['event']['nested']['array'].reverse()
        findings = self.findings([d, a, c, b])
        self.assertEqual(len(findings), 1)
        self.assertIn('changed ordered event inputs', findings[0])
        self.assertIn('$[0]', findings[0])
        self.assertIn('$[2]', findings[0])
        self.assertNotIn('$[1]', findings[0])

    def test_full_start_and_scalar_types(self):
        for first, second in ((False, 0), (True, 1), (1, 1.0), (1, '1'),
                              ({'x': [1, 2]}, {'x': [2, 1]})):
            a, b = pair()
            a['start']['nested'], b['start']['nested'] = first, second
            with self.subTest(first=first, second=second):
                self.assertIn('changed complete start', self.findings([a, b])[0])

    def test_nested_event_types_and_order(self):
        for first, second in ((False, 0), (True, 1), (1, 1.0), (None, ''),
                              ([1, 2], [2, 1]), ({'x': True}, {'x': 1})):
            a, b = pair()
            a['steps'][0]['event']['arg'] = first
            b['steps'][0]['event']['arg'] = second
            with self.subTest(first=first, second=second):
                self.assertIn('changed ordered event inputs', self.findings([a, b])[0])

    def test_nested_pair_field_is_compared_as_input(self):
        a, b = pair()
        for trace in (a, b):
            trace['steps'][0]['event']['argument'] = {'pair': [False, 2]}
        self.assertEqual(self.findings([a, b]), [])
        b['steps'][0]['event']['argument']['pair'][0] = 0
        findings = self.findings([a, b])
        self.assertEqual(len(findings), 1)
        self.assertIn('changed ordered event inputs', findings[0])

    def test_assumption_types_and_outputs_are_independent(self):
        a, b = pair()
        a['assumptions'], b['assumptions'] = {'g': True}, {'g': 1}
        self.assertEqual(self.findings([a, b]), [])
        b['steps'][0]['outcome'] = 'different'
        b['steps'][0]['state'] = {'ignored': True}
        self.assertEqual(self.findings([a, b]), [])

    def test_references_can_use_any_declaration(self):
        a, b = pair()
        a['declarations'].insert(0, 'Another')
        b['pair']['with'] = 'Another'
        self.assertEqual(self.findings({'nested': [a, b]}), [])

    def test_unmarked_and_other_files_do_not_supply_partners(self):
        a, b = pair()
        del b['pair']
        self.assertIn('missing marked counterpart', self.findings([a, b])[0])
        self.assertIn('missing marked counterpart', self.findings([a])[0])

    def test_malformed_members_are_actionable(self):
        mutations = [('pair', p) for p in (None, [], 'bad', {}, {'side': [], 'with': {}},
                                          {'side': 'refused', 'with': ''},
                                          {'side': 'refused', 'with': 'B', 'extra': 1})]
        mutations += [('declarations', x) for x in (None, [], [None], 'A')]
        mutations += [('start', None), ('assumptions', []), ('steps', None),
                      ('steps', [{}]), ('steps', [{'event': []}])]
        for key, value in mutations:
            a, b = pair()
            a[key] = value
            with self.subTest(key=key, value=value):
                findings = self.findings([a, b])
                self.assertTrue(findings)
                self.assertTrue(any('malformed' in f for f in findings))

    def test_two_broken_pairs_remain_two_finding_items(self):
        a, b = pair()
        c, d = pair(2)
        a['start']['value'], c['start']['value'] = 10, 20
        c['declarations'], d['declarations'] = ['C'], ['D']
        c['pair']['with'], d['pair']['with'] = 'D', 'C'
        self.assertEqual(len(self.findings([a, b, c, d])), 2)

    def test_matching_bytes_do_not_bypass_main_and_invalid_json_is_actionable(self):
        for text, token in (('{', 'malformed JSON corpus'),
                            (json.dumps(pair()[:1]), 'missing marked counterpart')):
            with self.subTest(token=token):
                status, output = self.run_main(text.encode())
                self.assertEqual(status, 1)
                verify(output, token, 'test-witnesses-v1.json')

    def run_main(self, emitted_bytes, committed_bytes=None):
        if committed_bytes is None:
            committed_bytes = emitted_bytes
        with tempfile.TemporaryDirectory(prefix='tau-web-witness-pairs-') as scratch:
            emitted, committed = Path(scratch) / 'emitted', Path(scratch) / 'committed'
            emitted.mkdir()
            committed.mkdir()
            for directory, content in ((emitted, emitted_bytes), (committed, committed_bytes)):
                (directory / 'test-witnesses-v1.json').write_bytes(content)
            output = StringIO()
            with patch.object(gate, 'EMITTED', str(emitted)), \
                    patch.object(gate, 'COMMITTED', str(committed)), \
                    patch.object(sys, 'argv', ['check_witnesses.py']), redirect_stdout(output):
                status = gate.main()
            return status, output.getvalue()

    def test_serialized_controls_through_main(self):
        for case in SERIALIZED:
            content = serialized_mutation({'witnesses': pair()}, case)
            with self.subTest(case=case):
                status, output = self.run_main(content)
                if case in NEGATIVE:
                    self.assertEqual(status, 1)
                    verify(output, NEGATIVE[case], 'test-witnesses-v1.json')
                else:
                    self.assertEqual(status, 0, output)
                    self.assertIn('WITNESS PAIRS: none', output)

    def test_equal_precise_numeric_inputs_through_main(self):
        for literal in ('9007199254740993.0', '9007199254740993e0',
                        '0.10000000000000000001', '1e400', '1e-400'):
            corpus = pair('raw_numeric_input')
            for trace in corpus:
                trace['steps'][0]['event']['nested']['value'] = 'raw_numeric_input'
            content = json.dumps(corpus).replace('"raw_numeric_input"', literal).encode()
            with self.subTest(literal=literal):
                status, output = self.run_main(content)
                self.assertEqual(status, 0, output)

    def test_unrepresentable_numeric_inputs_through_main(self):
        source, = (ROOT / 'docs/design').glob('allocation-witnesses-v*.json')
        for field in ('start', 'event'):
            for literals in (('1e9223372036854775808',) * 2,
                             ('1e9999999999999999999', '2e9999999999999999999')):
                corpus = json.loads(source.read_text())
                markers = ('tw316_extreme_left', 'tw316_extreme_right')
                for trace, marker in zip(corpus['witnesses'][:2], markers):
                    target = trace['start'] if field == 'start' else trace['steps'][0]['event']
                    target['seed'] = marker
                content = json.dumps(corpus)
                for marker, literal in zip(markers, literals):
                    self.assertEqual(content.count(json.dumps(marker)), 1)
                    content = content.replace(json.dumps(marker), literal)
                with self.subTest(field=field, literals=literals):
                    status, output = self.run_main(content.encode())
                    self.assertEqual(status, 1, output)
                    verify(output, 'numeric conversion failed', 'test-witnesses-v1.json')
                    self.assertIn('Decimal', output)

    def test_scalar_type_distinctions_through_main(self):
        for first, second in ((True, 1), (False, 0), (1, 1.0)):
            a, b = pair()
            a['start']['value'], b['start']['value'] = first, second
            with self.subTest(first=first, second=second):
                status, output = self.run_main(json.dumps([a, b]).encode())
                self.assertEqual(status, 1)
                verify(output, 'changed complete start', 'test-witnesses-v1.json')

    def test_malformed_bytes_in_either_copy_keep_drift_check(self):
        good, bad = json.dumps(pair()).encode(), bytes.fromhex('ff fe 7b 7d')
        for emitted, committed, token in ((bad, good, 'malformed UTF-8 emission'),
                                          (good, bad, 'malformed UTF-8 committed copy')):
            with self.subTest(token=token):
                status, output = self.run_main(emitted, committed)
                self.assertEqual(status, 1)
                self.assertIn(token, output)
                self.assertIn('test-witnesses-v1.json', output)
                self.assertIn('invalid start byte', output)
                self.assertIn('differs from the emission', output)
                self.assertNotIn('declarations=', output)
                self.assertNotIn('Traceback', output)

    def test_emission_equality_is_byte_for_byte(self):
        content = (json.dumps(pair()) + '\n').encode()
        status, output = self.run_main(content, content.replace(b'\n', b'\r\n'))
        self.assertEqual(status, 1)
        self.assertIn('differs from the emission', output)
        self.assertIn('WITNESS PAIRS: none', output)

    def test_control_assertion_counts_items_and_rejects_unrelated_output(self):
        output = "witness files checked: 1\nWITNESS DRIFT: none\nWITNESS PAIRS: "
        item = 'docs/design/file $[0] declarations=A defect'
        verify(output + repr([item]), 'defect', 'file')
        for bad in (repr([item, item]), repr([]), 'none'):
            with self.subTest(bad=bad), self.assertRaises((AssertionError, ValueError)):
                verify(output + bad, 'defect', 'file')
        with self.assertRaises(AssertionError):
            verify(output.replace('DRIFT: none', "DRIFT: ['other']") + repr([item]), 'defect', 'file')


if __name__ == '__main__':
    unittest.main()
