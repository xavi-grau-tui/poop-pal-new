"""The evolution tree as GAME DATA (read by PetState): every pal with its id, stage, family,
face, Pal-Pedia text, and what each food turns it into.

    python3 tools/design/evolution_data.py   -> data/evolution_tree.json

Names and rules come from evolution_tree.py (the picture). Food families in the game:
green, sweet, greasy, spicy, sour (basic), tech, cosmic (exotic), legend (legendary foods,
each with "legend_of": the family it belongs to).

JSON: { "forms": { id: {no, name, stage, stage_name, family, from, variant, face, desc, hint} },
        "starters": { family: id },
        "next": { id: { food family: id } },          # kid / adult steps, mutants
        "legend": { ultra adult id: { "food": legend food family, "to": id } } }
"""
import json, os, re
import evolution_tree as T

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
WORD = {'G': 'green', 'S': 'sweet', 'F': 'greasy', 'H': 'spicy', 'U': 'sour'}
ADJ = {'G': 'green', 'S': 'sweet', 'F': 'greasy', 'H': 'spicy', 'U': 'sour'}
STAGE_NO = {'baby': 1, 'kid': 2, 'adult': 3, 'mutant': 4, 'legend': 5}
KEEP_IDS = {'Sprig': 'sprig', 'Swirlet': 'swirlet', 'Nugget': 'nugget', 'Broccolump': 'broccolump',
            'Neapoolitan': 'neapoolitan', 'Greasy Chonk': 'greasy_chonk'}
KEEP_TEXT = {   # the 6 that already exist keep their Pal-Pedia text
    'sprig': ("Hatched from a salad. Photosynthesises when nobody is looking.", "Start a pal with something green."),
    'broccolump': ("Grown on greens. Proudly fibrous, faintly smug.", "A Sprig that keeps eating its greens..."),
    'swirlet': ("Born from sugar. Hums when it is happy, which is always.", "Start a pal with something sweet."),
    'neapoolitan': ("Three flavours, one cherry, zero regrets.", "Something sweet, then something sweeter..."),
    'nugget': ("Deep-fried at birth. Squeaks when poked.", "Start a pal with something greasy."),
    'greasy_chonk': ("Glistening. Content. Do not squeeze.", "What happens if a Nugget never stops eating junk?"),
}
KID_FLAVOUR = {'G': "Now it photosynthesises a little.", 'S': "Sticky, and proud of it.",
               'F': "Glistens under the lights.", 'H': "Smoulders when it gets excited.",
               'U': "Puckers at absolutely everything."}
# faces: happy, sparkle, sleepy, stars (old) + neutral ._. , sad, angry, evil, dizzy, visor, three
KID_FACE = {'G': 'happy', 'S': 'sparkle', 'F': 'sleepy', 'H': 'angry', 'U': 'neutral'}
BABY_FACE = {'G': 'happy', 'S': 'sparkle', 'F': 'happy', 'H': 'happy', 'U': 'neutral'}
FACE_OVERRIDE = {
    'Cold Sweat': 'sad', 'Salad Shame': 'sad', 'Sour Gummy': 'angry', 'Warhead': 'angry', 'Dulce Diablo': 'evil',
    'Ghost Pepper': 'evil', 'Vindaloo': 'angry', 'Inferno Taco': 'angry', 'Curdle Brute': 'angry', 'Thornbrute': 'angry',
    'Hot Pocketeer': 'evil', 'Kimchi Kaiju': 'angry', 'Gochujang': 'evil', 'Malt Marauder': 'evil',
    'Rhubarb Rascal': 'evil', 'Fruitcakey': 'dizzy', 'Kombuchoo': 'dizzy', 'Candy Kraut': 'dizzy',
    'Chimichunga': 'dizzy', 'Pad Thai Tiger': 'angry', 'Lard Lord': 'sleepy', 'Cucumbersome': 'neutral',
    'Pickled Garden': 'neutral', 'Matcha Monk': 'sleepy', 'Citrus Sage': 'sleepy', 'Tempura Sage': 'sleepy',
    'Sundae Supreme': 'stars', 'Salsa Diablo': 'evil', 'Fish Taco': 'neutral', 'Chippy': 'happy',
    'Sherbet Shock': 'dizzy', 'Hot Sauce': 'angry', 'Mole Mole': 'neutral', 'Habanerd': 'neutral',
    'Firecracker': 'sparkle', 'Magma Mound': 'angry', 'Vinegaroon': 'evil', 'Treefolk': 'sleepy',
    'Buffalo Blaze': 'angry', 'Wasabeast': 'angry', 'Sauerkraut': 'sad', 'Glazed Duke': 'sparkle',
}
VARIANT_FACE = {'ULTRA': 'stars', 'BLOOM': 'sparkle', 'CLASH': 'angry', 'ROOT': 'neutral', 'PEAK': None, 'CHAOS': 'dizzy'}
LEGEND_TEXT = {
    'G': "The first pal ever to grow a whole forest. Birds nest in it, politely.",
    'S': "Made of stardust and soft serve. Tastes like a wish.",
    'F': "Fried in dragon oil until it became one. Breathes warm butter.",
    'H': "Burns, flushes, and hatches again from its own hot sauce.",
    'U': "Eight pickled tentacles, one ancient grudge. Lives in the brine of time.",
}


def ident(name):
    if name in KEEP_IDS:
        return KEEP_IDS[name]
    return re.sub(r'[^a-z0-9]+', '_', name.lower()).strip('_')


def build():
    forms, nxt, legend = {}, {}, {}
    starters = {}
    def put(name, stage, fam, frm, variant, face, desc, hint):
        i = ident(name)
        assert i not in forms, i
        if i in KEEP_TEXT:
            desc, hint = KEEP_TEXT[i]
        forms[i] = {'no': len(forms) + 1, 'name': name, 'stage': STAGE_NO[stage], 'stage_name': stage,
                    'family': WORD[fam], 'from': ident(frm) if frm else '', 'variant': variant,
                    'face': FACE_OVERRIDE.get(name, face), 'desc': desc, 'hint': hint}
        return i
    for a in T.FAM:
        b_id = put(T.BABY[a], 'baby', a, '', 'BABY', BABY_FACE[a],
                   f"Hatched from something {ADJ[a]}. " + {'G': '', 'S': '', 'F': '',
                   'H': "Always slightly warm to the touch.", 'U': "Permanently unimpressed."}[a],
                   f"Start a pal with something {ADJ[a]}.")
        starters[WORD[a]] = b_id
    for a in T.FAM:
        for b in T.FAM:
            k = T.KID[a + b]
            kid_id = put(k, 'kid', a, T.BABY[a], 'KID', KID_FACE[b],
                         f"A {T.BABY[a]} that tried something {ADJ[b]}. {KID_FLAVOUR[b]}",
                         f"A {T.BABY[a]} that eats something {ADJ[b]}...")
            nxt.setdefault(ident(T.BABY[a]), {})[WORD[b]] = kid_id
    for a in T.FAM:
        for b in T.FAM:
            kname = T.KID[a + b]
            kid_id = ident(kname)
            names = T.ADULT[a + b]
            step = nxt.setdefault(kid_id, {})
            if a == b:
                fr, rv = T.friends(a), T.rivals(a)
                u = put(names[0], 'adult', a, kname, 'ULTRA', 'stars',
                        f"The purest {ADJ[a]} pal there is. Ate nothing else, regrets nothing.",
                        f"A {kname} that only ever eats {ADJ[a]}...")
                bl = put(names[1], 'adult', a, kname, 'BLOOM', 'sparkle',
                         f"A {kname} that made a friend: {' or '.join(ADJ[f] for f in fr)} food.",
                         f"A {kname} that eats something friendly...")
                cl = put(names[2], 'adult', a, kname, 'CLASH', 'angry',
                         f"A {kname} that ate its rival food. It has not forgiven anyone.",
                         f"A {kname} that eats its rival...")
                step[WORD[a]] = u
                for f in fr:
                    step[WORD[f]] = bl
                for f in rv:
                    step[WORD[f]] = cl
                legend[u] = {'food': WORD[a], 'to': None}
            else:
                r = put(names[0], 'adult', a, kname, 'ROOT', 'neutral',
                        f"A {kname} that went back to its {ADJ[a]} roots.",
                        f"A {kname} that remembers where it came from...")
                p = put(names[1], 'adult', a, kname, 'PEAK', KID_FACE[b],
                        f"A {kname} that doubled down on {ADJ[b]}.",
                        f"A {kname} that wants more {ADJ[b]}...")
                c = put(names[2], 'adult', a, kname, 'CHAOS', 'dizzy',
                        f"A {kname} that ate whatever was around. This happened.",
                        f"A {kname} that eats something else entirely...")
                for f in T.FAM:
                    step[WORD[f]] = r if f == a else (p if f == b else c)
    adults_by_fam = {}
    for i, f in forms.items():
        if f['stage_name'] == 'adult':
            adults_by_fam.setdefault(f['family'], []).append(i)
    for a in T.FAM:
        t = put(T.MUTANT[a][0], 'mutant', a, '', 'TECH', 'visor',
                f"A {ADJ[a]} pal upgraded with a microchip. Beeps when it's hungry.",
                f"Feed a grown-up {ADJ[a]} pal some tech...")
        c = put(T.MUTANT[a][1], 'mutant', a, '', 'COSMIC', 'three',
                f"Something from space got into this {ADJ[a]} pal. It knows things.",
                f"Feed a grown-up {ADJ[a]} pal something from space...")
        for ad in adults_by_fam[WORD[a]]:
            nxt.setdefault(ad, {})['tech'] = t
            nxt[ad]['cosmic'] = c
        forms[t]['from'] = 'any adult'
        forms[c]['from'] = 'any adult'
    for a in T.FAM:
        ultra = ident(T.ADULT[a + a][0])
        lg = put(T.LEGEND[a], 'legend', a, T.ADULT[a + a][0], 'LEGEND', 'stars', LEGEND_TEXT[a],
                 f"The purest {ADJ[a]} pal + {T.LEGEND_FOOD[a]}...")
        legend[ultra] = {'food': T.LEGEND_FOOD[a], 'family': WORD[a], 'to': lg}
    assert len(forms) == 120
    return {'forms': forms, 'starters': starters, 'next': nxt, 'legend': legend}


if __name__ == '__main__':
    data = build()
    with open(os.path.join(ROOT, 'data', 'evolution_tree.json'), 'w') as f:
        json.dump(data, f, indent=1)
    faces = {}
    for i, fm in data['forms'].items():
        faces[fm['face']] = faces.get(fm['face'], 0) + 1
    print('ok', len(data['forms']), 'forms; faces', faces)
