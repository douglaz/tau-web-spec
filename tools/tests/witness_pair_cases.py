"""Corpus mutations and finding-item assertions for the witness pair controls."""

import ast
from copy import deepcopy
import json
from pathlib import Path
import sys

NEGATIVE = {
    'metadata': 'malformed pair metadata',
    'missing': 'missing marked counterpart',
    'nonreciprocal': 'nonreciprocal declaration references',
    'same_side': 'same-side counterparts',
    'start': 'changed complete start',
    'events': 'changed ordered event inputs',
    'nested': 'changed ordered event inputs',
    'provenance': 'changed ordered event inputs',
    'event_order': 'changed ordered event inputs',
    'scalar': 'changed ordered event inputs',
    'assumptions': 'equal assumptions',
    'ambiguous': 'ambiguous counterparts',
    'accounting': 'one-to-one accounting failed',
    'repeated': 'changed ordered event inputs',
    'malformed_steps': 'malformed steps',
    'malformed_start': 'malformed start',
    'malformed_assumptions': 'malformed assumptions',
    'malformed_declarations': 'malformed declarations',
    'invalid_json': 'malformed JSON corpus',
    'numeric_start': 'changed complete start',
    'numeric_events': 'changed ordered event inputs',
    'malformed_utf8': 'malformed UTF-8 emission',
}
POSITIVE = ('unchanged', 'reordered', 'repeated_valid', 'multiple_assumptions',
            'outputs', 'object_keys', 'unmarked', 'nonproduction', 'elsewhere', 'nested_pair_input',
            'numeric_equal', 'numeric_assumptions')
SERIALIZED = ('invalid_json', 'malformed_utf8', 'numeric_start', 'numeric_events',
              'numeric_equal', 'numeric_assumptions')


def serialized_mutation(corpus, case):
    """Write raw number tokens, never passing the new values through a float."""
    if case == 'invalid_json':
        return b'{ invalid JSON\n'
    if case == 'malformed_utf8':
        return bytes.fromhex('ff fe 7b 7d')
    a, b = corpus['witnesses'][:2]
    if case == 'numeric_start':
        targets = [t['start'] for t in (a, b)]
        key = 'seed'
        literals = ('9007199254740992e0', '9007199254740993e0')
    elif case in ('numeric_events', 'numeric_equal'):
        targets = [t['steps'][0]['event'] for t in (a, b)]
        key = 'precise'
        literals = ('9007199254740992.0', '9007199254740993.0')
        if case == 'numeric_equal':
            literals = ('9007199254740993.0000000000000000001',) * 2
    elif case == 'numeric_assumptions':
        a['assumptions'], b['assumptions'] = {}, {}
        targets = [t['assumptions'] for t in (a, b)]
        key = 'precise'
        literals = ('0.10000000000000000001', '0.10000000000000000002')
    else:
        raise ValueError(case)
    markers = ('tw316_raw_left', 'tw316_raw_right')
    for target, marker in zip(targets, markers):
        target[key] = marker
    content = json.dumps(corpus)
    for marker, literal in zip(markers, literals):
        assert content.count(json.dumps(marker)) == 1
        content = content.replace(json.dumps(marker), literal)
    for literal in set(literals):
        assert content.count(literal) == literals.count(literal)
    return content.encode('utf-8') + b'\n'


def mutate(corpus, case):
    traces = corpus['witnesses']
    a, b = traces[:2]
    if case in ('unchanged', 'repeated_valid'):
        # The committed corpus itself contains these retained cases.
        if case == 'repeated_valid':
            names = [w['declarations'][0] for w in traces if 'pair' in w]
            assert len(names) != len(set(names))
    elif case == 'metadata':
        a['pair']['side'] = 'invalid'
    elif case == 'missing':
        unmarked = deepcopy(b)
        del unmarked['pair']
        traces.remove(b)
        traces.append(unmarked)
        assert any(a['pair']['with'] in w['declarations'] for w in traces)
    elif case == 'nonreciprocal':
        a['pair']['with'] = a['declarations'][0]
    elif case == 'same_side':
        b['pair']['side'] = a['pair']['side']
    elif case == 'start':
        b['start']['seed'] = 1
    elif case == 'events':
        b['steps'].pop()
    elif case == 'nested':
        b['steps'][0]['event']['append']['provenance'] = 'changed append source'
    elif case == 'provenance':
        b['steps'][0]['event']['provenance'] = 'changed source'
    elif case == 'event_order':
        b['steps'].reverse()
    elif case == 'scalar':
        assert b['steps'][0]['event']['append']['durable'] is False
        b['steps'][0]['event']['append']['durable'] = 0
    elif case == 'assumptions':
        b['assumptions'] = deepcopy(a['assumptions'])
    elif case == 'ambiguous':
        traces.extend(deepcopy([a, b]))
    elif case == 'accounting':
        traces.append(deepcopy(a))
    elif case == 'repeated':
        matches = [w for w in traces if w.get('pair', {}).get('side') == 'refused'
                   and w['declarations'] == ['TauWeb.Dispatch.order_receipt_association_required']]
        assert len(matches) == 2
        matches[1]['steps'][0]['event']['provenance'] = 'changed repeated occurrence'
    elif case == 'malformed_steps':
        b['steps'] = [None]
    elif case.startswith('malformed_'):
        b[case.removeprefix('malformed_')] = None
    elif case == 'reordered':
        traces.reverse()
        corpus['enumeration'].reverse()
    elif case == 'multiple_assumptions':
        # In addition to the retained Pins pair, exercise this boundary here.
        b['assumptions'] = {k: not v for k, v in a['assumptions'].items()}
        assert sum(b['assumptions'][k] != v for k, v in a['assumptions'].items()) > 1
    elif case == 'outputs':
        for step in b['steps']:
            for key in list(step):
                if key != 'event':
                    step[key] = {'different': ['output', False]}
    elif case == 'object_keys':
        def reverse_keys(value):
            if isinstance(value, dict):
                return {k: reverse_keys(v) for k, v in reversed(value.items())}
            if isinstance(value, list):
                return list(map(reverse_keys, value))
            return value
        traces[1] = reverse_keys(b)
    elif case == 'unmarked':
        for trace in (a, b):
            extra = deepcopy(trace)
            del extra['pair']
            traces.append(extra)
    elif case == 'nonproduction':
        a['assumptions']['restoredAllocatesNone'] = False
        assert a['assumptions'] != b['assumptions']
    elif case == 'elsewhere':
        corpus['extra'] = {'nested': [traces.pop(1), traces.pop(0)]}
    elif case == 'nested_pair_input':
        for trace in (a, b):
            trace['steps'][0]['event']['argument'] = {'pair': ['input', 1]}
            trace['start']['pair'] = {'symbolic': True}
            trace['assumptions']['pair'] = 'hypothesis'
            trace['steps'][0]['pair'] = 'output'
        extra = deepcopy(a)
        del extra['pair']
        traces.append(extra)
    else:
        raise ValueError(case)


def apply(case):
    module = 'dispatch' if case in ('repeated', 'repeated_valid') else 'allocation'
    committed, = Path('docs/design').glob(f'{module}-witnesses-v*.json')
    emitted = Path('tools/formal/.lake/witnesses') / committed.name
    before = committed.read_bytes()
    assert before == emitted.read_bytes(), 'control needs equal starting copies'
    corpus = json.loads(before)
    original = deepcopy(corpus)
    if case in SERIALIZED:
        content = serialized_mutation(corpus, case)
        assert content != before
    else:
        mutate(corpus, case)
        assert (json.dumps(corpus) != json.dumps(original)
                or case in ('unchanged', 'repeated_valid')), 'mutation did not apply'
        content = json.dumps(corpus).encode() + b'\n'
    for path in (committed, emitted):
        path.write_bytes(content)
        assert path.read_bytes() == content
    assert committed.read_bytes() == emitted.read_bytes(), 'control introduced drift'


def verify(output, token, location):
    """Count items, not lines, and disallow traceback or unrelated diagnostics."""
    lines = output.splitlines()
    assert len(lines) == 3 and lines[0].startswith('witness files checked: '), output
    assert lines[1] == 'WITNESS DRIFT: none', output
    assert lines[2].startswith('WITNESS PAIRS: '), output
    items = ast.literal_eval(lines[2].removeprefix('WITNESS PAIRS: '))
    assert type(items) is list and len(items) == 1 and type(items[0]) is str, output
    assert token in items[0] and location in items[0], output
    assert 'docs/design/' in items[0], output
    if token not in ('malformed JSON corpus', 'malformed UTF-8 emission'):
        assert 'declarations=' in items[0] and '$[' in items[0], output


if __name__ == '__main__':
    if sys.argv[1] == 'verify':
        verify(sys.stdin.read(), sys.argv[2], sys.argv[3])
    else:
        apply(sys.argv[1])
