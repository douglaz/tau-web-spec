"""Scratch-control preparation; never rewrites the committed coverage baseline."""
from pathlib import Path
import json
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_coverage as coverage


def consume_slack(extra=0):
    requirements, uncovered = coverage.measure()
    measured = sum(not coverage.excluded_reason(r, requirements[r]) for r in uncovered)
    limit = json.loads(Path(coverage.BASELINE).read_text())['max_uncovered_ratcheted']
    if measured > limit:
        raise ValueError('control preparation requires an initially passing corpus')
    next_id = 1 + max(int(r.split('-')[1]) for r in requirements if re.fullmatch(r'STA-\d+', r))
    padding = ''.join(f'\n**STA-{next_id + i}** Coverage-control missing obligation.\n'
                      for i in range(limit - measured + extra))
    with (Path(coverage.ROOT) / '03-state-and-recovery.md').open('a') as document:
        document.write(padding)


if __name__ == '__main__':
    if sys.argv[1:] not in (['pad'], ['append']):
        raise SystemExit('usage: coverage_control.py pad|append (scratch copy only)')
    consume_slack(int(sys.argv[1] == 'append'))
