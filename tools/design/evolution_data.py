"""The evolution tree as GAME DATA (read by PetState): every pal with its id, stage, family,
Pal-Pedia text, and what each food turns it into.

    python3 tools/design/evolution_data.py   -> data/evolution_tree.json

The pals are the user's sheet 4 (docs/mockups/pal_brainstorm/v3/sets4.py, picture: sheet4.png):
per family 1 Sho (baby), 5 Chu (kids, one per 2nd food), 15 Dai (adults, 3 per Chu), 2 mutants
and 1 legend = 24, 120 in all. The rules are evolution_tree.py's:
  baby + a Chu food of type B           -> its kid for B
  mixed kid (A+B) + a Dai food           -> ROOT (A again), PEAK (B again), CHAOS (any other)
  pure kid (A+A) + a Dai food            -> ULTRA (A again), BLOOM (a friend), CLASH (a rival)
  any adult of family A + tech / cosmic  -> A's tech / cosmic mutant
  A's ULTRA + A's legendary food         -> A's legend
The food circle (friends = neighbours): green - sweet - greasy - spicy - sour - green.
Food families in the game: green, sweet, greasy, spicy, sour (basic), tech, cosmic (exotic),
legend (legendary foods, each with "legend_of": the family it belongs to).

JSON: { "forms": { id: {no, name, stage, stage_name, family, from, variant, foods, desc, hint, line} },
        "starters": { family: id },
        "next": { id: { food family: id } },          # kid / adult steps, mutants
        "legend": { ultra adult id: { "food": legend food name, "family": family, "to": id } } }
  no      Pal-Pedia number, family by family (green 1-24, sweet 25-48...): Sho, its 5 Chu, their
          15 Dai (Chu by Chu), the tech and cosmic mutants, the legend
  foods   the food families that lead here from "from" (the Pedia's food-path icons)
  line    the pal's look (palgen3 spec line, for the art tools)
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
sys.path.insert(0, os.path.join(ROOT, 'docs', 'mockups', 'pal_brainstorm', 'v3'))
from sets4 import SHEET4

FAMS = ['green', 'sweet', 'greasy', 'spicy', 'sour']
STAGE_NO = {'baby': 1, 'kid': 2, 'adult': 3, 'mutant': 4, 'legend': 5}
LEGEND_FOOD = {'green': 'Golden Seed', 'sweet': 'Stardust Sugar', 'greasy': 'Dragon Oil', 'spicy': 'Phoenix Pepper',
               'sour': 'Kraken Brine'}
DESC = {   # sheet notes that were notes for us, not Pal-Pedia text
    'Ember': "Hatched from something spicy. Always slightly warm to the touch.",
    'Picklet': "Hatched from something sour. Permanently unimpressed.",
}


def friends(a):
    i = FAMS.index(a)
    return [FAMS[(i - 1) % 5], FAMS[(i + 1) % 5]]


def rivals(a):
    return [f for f in FAMS if f != a and f not in friends(a)]


def ident(name):
    return re.sub(r'[^a-z0-9]+', '_', name.lower()).strip('_')


def fields(line):
    f = [x.strip() for x in line.split('|')]
    return f[0], (f[5] if len(f) > 5 else '')


def build():
    forms, nxt, legend, starters = {}, {}, {}, {}

    def put(line, stage, fam, frm, variant, foods, hint):
        name, note = fields(line)
        i = ident(name)
        assert i not in forms, i
        forms[i] = {'no': len(forms) + 1, 'name': name, 'stage': STAGE_NO[stage], 'stage_name': stage,
                    'family': fam, 'from': frm, 'variant': variant, 'foods': foods,
                    'desc': DESC.get(name, note), 'hint': hint, 'line': line}
        return i

    for a in FAMS:
        part = SHEET4[a]
        baby = put(part['baby'], 'baby', a, '', 'BABY', [a], f"Start a pal with a {a} Sho food.")
        bname = forms[baby]['name']
        starters[a] = baby
        kids = []
        for b, line in zip(FAMS, part['kids']):
            k = put(line, 'kid', a, baby, 'KID', [b], f"Feed {bname} a {b} Chu food.")
            nxt.setdefault(baby, {})[b] = k
            kids.append(k)
        adults = []
        ultra = ''
        for j, (b, kid) in enumerate(zip(FAMS, kids)):
            kname = forms[kid]['name']
            lines = part['adults'][j * 3:j * 3 + 3]
            step = nxt.setdefault(kid, {})
            if a == b:
                fr, rv = friends(a), rivals(a)
                u = put(lines[0], 'adult', a, kid, 'ULTRA', [a], f"Feed {kname} a {a} Dai food: {a} all the way.")
                bl = put(lines[1], 'adult', a, kid, 'BLOOM', fr,
                         f"Feed {kname} a friend food: a {fr[0]} or {fr[1]} Dai food.")
                cl = put(lines[2], 'adult', a, kid, 'CLASH', rv,
                         f"Feed {kname} a rival food: a {rv[0]} or {rv[1]} Dai food.")
                step[a] = u
                for f in fr:
                    step[f] = bl
                for f in rv:
                    step[f] = cl
                legend[u] = {'food': LEGEND_FOOD[a], 'family': a, 'to': None}
                adults += [u, bl, cl]
                ultra = u
            else:
                other = [f for f in FAMS if f not in (a, b)]
                r = put(lines[0], 'adult', a, kid, 'ROOT', [a], f"Feed {kname} a {a} Dai food, back to its roots.")
                p = put(lines[1], 'adult', a, kid, 'PEAK', [b], f"Feed {kname} a {b} Dai food, even more {b}.")
                c = put(lines[2], 'adult', a, kid, 'CHAOS', other,
                        f"Feed {kname} any other Dai food: {', '.join(other[:-1])} or {other[-1]}.")
                for f in FAMS:
                    step[f] = r if f == a else (p if f == b else c)
                adults += [r, p, c]
        i = FAMS.index(a)
        t = put(SHEET4['mutants'][i * 2], 'mutant', a, 'any adult', 'TECH', ['tech'],
                f"Feed any grown-up (Dai) {a} pal some tech food.")
        c = put(SHEET4['mutants'][i * 2 + 1], 'mutant', a, 'any adult', 'COSMIC', ['cosmic'],
                f"Feed any grown-up (Dai) {a} pal some cosmic food.")
        for ad in adults:
            nxt.setdefault(ad, {})['tech'] = t
            nxt[ad]['cosmic'] = c
        lg = put(SHEET4['legends'][i], 'legend', a, ultra, 'LEGEND', ['legend'],
                 f"Feed {forms[ultra]['name']} (the ULTRA {a} pal) the {LEGEND_FOOD[a]}.")
        legend[ultra]['to'] = lg
    assert len(forms) == 120, len(forms)
    return {'forms': forms, 'starters': starters, 'next': nxt, 'legend': legend}


if __name__ == '__main__':
    data = build()
    with open(os.path.join(ROOT, 'data', 'evolution_tree.json'), 'w') as f:
        json.dump(data, f, indent=1)
    kinds = {}
    for fm in data['forms'].values():
        kinds[fm['variant']] = kinds.get(fm['variant'], 0) + 1
    print('ok', len(data['forms']), 'forms;', kinds)
