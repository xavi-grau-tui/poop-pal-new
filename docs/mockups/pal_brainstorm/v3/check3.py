"""Variety check: per sheet and family band, which body plans repeat (more than twice = flagged)."""
from collections import Counter
from sets3 import SETS, FAMS

def plan_of(line):
    p = line.split('|')[1].strip()
    return p.split()[0]

for key, S in SETS.items():
    for fam in FAMS:
        f = S[fam]
        lines = [f['baby']] + f['kids'] + f['adults']
        plans = [plan_of(l) for l in lines if not plan_of(l).startswith('=')]
        c = Counter(plans)
        bad = {p: n for p, n in c.items() if n > 2}
        if bad:
            names = {p: [l.split('|')[0].strip() for l in lines if plan_of(l) == p] for p in bad}
            print(key, fam, names)
