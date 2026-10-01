"""DRAFT evolution tree: 120 pals, path-dependent (what you ate, in which order).

    python3 tools/design/evolution_tree.py
        -> docs/evolution_tree_draft.png   (the picture to review)
        -> data/evolution_tree_draft.json  (the same tree as data, to implement later)

Rules (one pal per flush cycle, every meal can change it):
  meal 1  BABY    the food type you start with (5 basic types)
  meal 2  KID     baby x food type                                  5 x 5 = 25
  meal 3  ADULT   3 per kid:
            mixed kid (A then B):  ROOT  = A again   PEAK = B again   CHAOS = any other
            pure kid  (A then A):  ULTRA = A again   BLOOM = a friend  CLASH = a rival
          friends/rivals: the food pentagon  Green - Sweet - Greasy - Spicy - Sour - (Green)
          neighbours are friends, the other two are rivals                  25 x 3 = 75
  meal 4+ MUTANT  any adult + an exotic food (Tech / Cosmic): the family's mutant   5 x 2 = 10
          LEGEND  an ULTRA adult + its legendary food (very rare)                 5
  total 5 + 25 + 75 + 10 + 5 = 120
"""
import json, os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')

FAM = ['G', 'S', 'F', 'H', 'U']          # green, sweet, greasy (fried), spicy (hot), sour
FAM_NAME = {'G': 'Green', 'S': 'Sweet', 'F': 'Greasy', 'H': 'Spicy', 'U': 'Sour', 'T': 'Tech', 'C': 'Cosmic', 'L': 'Legendary'}
FOOD_COL = {'G': (118, 168, 78), 'S': (236, 132, 172), 'F': (204, 134, 62), 'H': (214, 74, 58), 'U': (214, 196, 52),
            'T': (104, 136, 168), 'C': (146, 104, 200), 'L': (226, 176, 40)}
FOOD_EXAMPLES = {
    'G': 'salad, broccoli, avocado',
    'S': 'cake, ice cream, candy',
    'F': 'fries, burger, nuggets',
    'H': 'chili, wings, curry  (new: unlocked in a minigame)',
    'U': 'pickles, lemon, kimchi  (new: unlocked in a minigame)',
    'T': 'microchip, battery  (exotic: rare, from minigames)',
    'C': 'alien goo, stardust  (exotic: Lucky Pinch)',
    'L': 'one per family, hardcore late game',
}
LEGEND_FOOD = {'G': 'Golden Seed', 'S': 'Stardust Sugar', 'F': 'Dragon Oil', 'H': 'Phoenix Pepper', 'U': 'Kraken Brine'}

BABY = {'G': 'Sprig', 'S': 'Swirlet', 'F': 'Nugget', 'H': 'Ember', 'U': 'Picklet'}
KID = {
    'GG': 'Broccolump', 'GS': 'Sproutberry', 'GF': 'Fritterleaf', 'GH': 'Jalapling', 'GU': 'Gherkid',
    'SG': 'Matcharoo', 'SS': 'Neapoolitan', 'SF': 'Donutto', 'SH': 'Spicecake', 'SU': 'Lemoncurdle',
    'FG': 'Wrapster', 'FS': 'Churrolo', 'FF': 'Greasy Chonk', 'FH': 'Wingding', 'FU': 'Vinegrub',
    'HG': 'Pepperpod', 'HS': 'Chilimango', 'HF': 'Nachunk', 'HH': 'Scorchling', 'HU': 'Salsette',
    'UG': 'Kimchling', 'US': 'Sourpatch', 'UF': 'Dillfry', 'UH': 'Fermento', 'UU': 'Puckerpus',
}
# per kid: (ROOT/ULTRA, PEAK/BLOOM, CHAOS/CLASH)
ADULT = {
    'GG': ('Treefolk', 'Blossomoss', 'Thornbrute'),
    'GS': ('Orchardon', 'Jamboree', 'Fruitcakey'),
    'GF': ('Tempura Sage', 'Onion Ringo', 'Kebabble'),
    'GH': ('Pepper Hedge', 'Habanerd', 'Currycane'),
    'GU': ('Cucumbersome', 'Dill Pickler', 'Kombuchoo'),
    'SG': ('Matcha Monk', 'Mint Mochi', 'Rhubarb Rascal'),
    'SS': ('Sundae Supreme', 'Caramelord', 'Sour Gummy'),
    'SF': ('Glazed Duke', 'Deep-Fried Bar', 'Funnelcake'),
    'SH': ('Cinnabun', 'Chili Choco', 'Ginger Snap'),
    'SU': ('Lemon Tart', 'Sherbet Shock', 'Yuzu Fizz'),
    'FG': ('Loaded Wrap', 'Garden Burger', 'Pizza Verde'),
    'FF': ('Lard Lord', 'Maple Baconeer', 'Salad Shame'),
    'FS': ('Fair Fritter', 'Churro King', 'Dulce Diablo'),
    'FH': ('Bucket Boss', 'Buffalo Blaze', 'Hot Pocketeer'),
    'FU': ('Chippy', 'Malt Marauder', 'Fish Taco'),
    'HG': ('Ghost Pepper', 'Wasabeast', 'Pad Thai Tiger'),
    'HS': ('Mole Mole', 'Mango Tango', 'Hot Honey'),
    'HF': ('Inferno Taco', 'Nacho Grande', 'Chimichunga'),
    'HH': ('Magma Mound', 'Firecracker', 'Cold Sweat'),
    'HU': ('Salsa Diablo', 'Tom Yum', 'Ceviche'),
    'UG': ('Sauerkraut', 'Kimchi Kaiju', 'Pickled Garden'),
    'US': ('Warhead', 'Sweet Tart', 'Candy Kraut'),
    'UF': ('Pickle Spear', 'Fried Pickle', 'Reuben'),
    'UH': ('Vindaloo', 'Hot Sauce', 'Gochujang'),
    'UU': ('Vinegaroon', 'Citrus Sage', 'Curdle Brute'),
}
MUTANT = {
    'G': ('Cyborg Sprout', 'Moss Martian'), 'S': ('Robo Sundae', 'Nebula Swirl'),
    'F': ('Mecha Nugget', 'Blob Beyond'), 'H': ('Overclock', 'Solar Flare'), 'U': ('Acid Battery', 'Void Pickle'),
}
LEGEND = {'G': 'World Tree', 'S': 'Celestial Sundae', 'F': 'Deep-Fried Dragon', 'H': 'Phoenix', 'U': 'Kraken'}
DRAWN = set()   # (every pal has art now: tools/art/forms.py + forms_gen.py)


def friends(a):
    i = FAM.index(a)
    return [FAM[(i - 1) % 5], FAM[(i + 1) % 5]]


def rivals(a):
    return [f for f in FAM if f != a and f not in friends(a)]


def build():
    forms = []
    def add(name, stage, family, frm, rule):
        forms.append({'no': len(forms) + 1, 'name': name, 'stage': stage, 'family': family, 'from': frm, 'rule': rule})
    for a in FAM:
        add(BABY[a], 'baby', a, '', 'first meal: ' + FAM_NAME[a])
    for a in FAM:
        for b in FAM:
            add(KID[a + b], 'kid', a, BABY[a], 'then ' + FAM_NAME[b])
    for a in FAM:
        for b in FAM:
            k = KID[a + b]
            r, p, c = ADULT[a + b]
            if a == b:
                add(r, 'adult', a, k, 'ULTRA: ' + FAM_NAME[a] + ' again')
                add(p, 'adult', a, k, 'BLOOM: a friend (' + '/'.join(FAM_NAME[f] for f in friends(a)) + ')')
                add(c, 'adult', a, k, 'CLASH: a rival (' + '/'.join(FAM_NAME[f] for f in rivals(a)) + ')')
            else:
                add(r, 'adult', a, k, 'ROOT: ' + FAM_NAME[a] + ' again')
                add(p, 'adult', a, k, 'PEAK: ' + FAM_NAME[b] + ' again')
                add(c, 'adult', a, k, 'CHAOS: any other basic food')
    for a in FAM:
        add(MUTANT[a][0], 'mutant', a, 'any ' + FAM_NAME[a] + ' adult', 'Tech food')
        add(MUTANT[a][1], 'mutant', a, 'any ' + FAM_NAME[a] + ' adult', 'Cosmic food')
    for a in FAM:
        add(LEGEND[a], 'legend', a, ADULT[a + a][0], 'legendary food: ' + LEGEND_FOOD[a])
    return forms


# ------------------------------------------------------------------ drawing
def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()

F_TITLE = font(os.path.join(ROOT, 'fonts', 'pixChicago.ttf'), 30)
F_HEAD = font(os.path.join(ROOT, 'fonts', 'pixChicago.ttf'), 20)
F_NAME = font('/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf', 19)
F_SMALL = font('/System/Library/Fonts/Supplemental/Arial.ttf', 15)
F_TEXT = font('/System/Library/Fonts/Supplemental/Arial.ttf', 19)
F_BOLD = font('/System/Library/Fonts/Supplemental/Arial Bold.ttf', 19)

INK = (74, 44, 32)
BG = (250, 240, 214)
PANEL = (242, 226, 192)
ROW = 34
X_BABY, W_BABY = 40, 150
X_KID, W_KID = 300, 180
X_ADULT, W_ADULT = 620, 200
X_SPEC, W_SPEC = 1060, 260
WIDTH = 1560
HEADER_H = 560


def light(c, k=0.55):
    return tuple(int(v + (255 - v) * k) for v in c)


def node(d, x, y, w, name, fam, stage_tag, drawn=False, special=None):
    h = 26
    col = FOOD_COL[special or fam]
    d.rounded_rectangle([x, y - h // 2, x + w, y + h // 2], radius=9, fill=light(col, 0.62), outline=INK, width=2)
    d.text((x + 10, y), name, font=F_NAME, fill=INK, anchor='lm')
    if drawn:
        d.text((x + w - 8, y), '*', font=F_BOLD, fill=(60, 120, 60), anchor='rm')


def chip(d, x, y, letters, label=None):
    """little coloured food circles on an edge"""
    for i, l in enumerate(letters):
        cx = x + i * 20
        d.ellipse([cx - 9, y - 9, cx + 9, y + 9], fill=FOOD_COL[l], outline=INK, width=2)
        d.text((cx, y), l, font=F_SMALL, fill=(255, 255, 255), anchor='mm')
    if label:
        d.text((x + len(letters) * 20 - 2, y), label, font=F_SMALL, fill=INK, anchor='lm')


def edge(d, x0, y0, x1, y1, col=INK, width=2, dash=False):
    mx = (x0 + x1) / 2
    pts = [(x0, y0), (mx, y0), (mx, y1), (x1, y1)]
    if not dash:
        d.line(pts, fill=col, width=width, joint='curve')
        return
    for (a, b) in zip(pts, pts[1:]):
        n = int(max(abs(b[0] - a[0]), abs(b[1] - a[1])) // 10) + 1
        for i in range(0, n, 2):
            p = (a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n)
            q = (a[0] + (b[0] - a[0]) * min(i + 1, n) / n, a[1] + (b[1] - a[1]) * min(i + 1, n) / n)
            d.line([p, q], fill=col, width=width)


def draw(forms):
    block = 15 * ROW + 70
    H = HEADER_H + block * 5 + 60
    im = Image.new('RGB', (WIDTH, H), BG)
    d = ImageDraw.Draw(im)
    d.text((40, 30), 'POOP PAL  -  EVOLUTION TREE (DRAFT)', font=F_TITLE, fill=INK)
    d.text((40, 78), '120 pals. Every meal can change your pal, and the ORDER of the foods matters.', font=F_TEXT, fill=INK)
    # rules panel
    d.rounded_rectangle([30, 125, 1010, HEADER_H - 20], radius=14, fill=PANEL, outline=INK, width=2)
    lines = [
        ('1st meal', 'BABY: the food type you start with (5 basic types)'),
        ('2nd meal', 'KID: baby x next food type (5 x 5 = 25)'),
        ('3rd meal', 'ADULT, 3 per kid (75):'),
        ('', 'mixed kid (A then B):  ROOT = A again,  PEAK = B again,  CHAOS = any other'),
        ('', 'pure kid (A then A):  ULTRA = A again,  BLOOM = a friend,  CLASH = a rival'),
        ('4th meal +', 'MUTANT: any adult + Tech or Cosmic food (10)'),
        ('', 'LEGEND: an ULTRA adult + its legendary food (5)'),
        ('', 'An adult keeps eating normally (no change) unless the food'),
        ('', 'is exotic or legendary.  Flush = start again.'),
    ]
    y = 150
    for a, b in lines:
        d.text((50, y), a, font=F_BOLD, fill=INK)
        d.text((170, y), b, font=F_TEXT, fill=INK)
        y += 30
    # pentagon of friends / rivals
    import math
    cx, cy, R = 920, 330, 70
    pts = {}
    for i, f in enumerate(FAM):
        ang = -math.pi / 2 + i * 2 * math.pi / 5
        pts[f] = (cx + R * math.cos(ang), cy + R * math.sin(ang))
    for i, f in enumerate(FAM):
        g = FAM[(i + 1) % 5]
        d.line([pts[f], pts[g]], fill=(60, 140, 60), width=4)
    for f in FAM:
        for r in rivals(f):
            d.line([pts[f], pts[r]], fill=(200, 80, 70), width=1)
    for f in FAM:
        x, yv = pts[f]
        d.ellipse([x - 15, yv - 15, x + 15, yv + 15], fill=FOOD_COL[f], outline=INK, width=2)
        d.text((x, yv), f, font=F_BOLD, fill=(255, 255, 255), anchor='mm')
    d.text((cx - 70, cy + 105), 'friends: green lines', font=F_SMALL, fill=(60, 140, 60))
    d.text((cx - 70, cy + 123), 'rivals: thin red lines', font=F_SMALL, fill=(200, 80, 70))
    # food legend
    d.rounded_rectangle([1030, 125, WIDTH - 30, HEADER_H - 20], radius=14, fill=PANEL, outline=INK, width=2)
    d.text((1050, 145), 'FOOD TYPES', font=F_HEAD, fill=INK)
    y = 195
    for f in ['G', 'S', 'F', 'H', 'U', 'T', 'C', 'L']:
        d.ellipse([1050, y - 11, 1072, y + 11], fill=FOOD_COL[f], outline=INK, width=2)
        d.text((1061, y), f, font=F_SMALL, fill=(255, 255, 255), anchor='mm')
        d.text((1084, y - 11), FAM_NAME[f], font=F_BOLD, fill=INK)
        d.text((1084, y + 9), FOOD_EXAMPLES[f], font=F_SMALL, fill=INK)
        y += 42
    # column titles
    y0 = HEADER_H
    for x, t in [(X_BABY, 'BABY'), (X_KID, 'KID - 2nd meal'), (X_ADULT, 'ADULT - 3rd meal'), (X_SPEC, 'MUTANT / LEGEND')]:
        d.text((x, y0 + 4), t, font=F_HEAD, fill=INK)
    y0 += 50
    for a in FAM:
        top = y0
        d.rounded_rectangle([20, top - 8, WIDTH - 20, top + 15 * ROW + 10], radius=16, outline=light(FOOD_COL[a], 0.2), width=3, fill=light(FOOD_COL[a], 0.88))
        adult_y = [top + 16 + i * ROW for i in range(15)]
        kid_y = [sum(adult_y[k * 3:k * 3 + 3]) / 3 for k in range(5)]
        baby_y = sum(kid_y) / 5
        # baby
        node(d, X_BABY, baby_y, W_BABY, BABY[a], a, 'baby', BABY[a] in DRAWN)
        chip(d, X_BABY + 8, baby_y - 30, [a], ' first meal')
        for k, b in enumerate(FAM):
            edge(d, X_BABY + W_BABY, baby_y, X_KID, kid_y[k])
            chip(d, X_KID - 34, kid_y[k] - 16, [b])
            node(d, X_KID, kid_y[k], W_KID, KID[a + b], a, 'kid', KID[a + b] in DRAWN)
            names = ADULT[a + b]
            if a == b:
                trig = [[a], friends(a), rivals(a)]
                tags = ['ULTRA', 'BLOOM', 'CLASH']
            else:
                trig = [[a], [b], None]
                tags = ['ROOT', 'PEAK', 'CHAOS']
            for j in range(3):
                yy = adult_y[k * 3 + j]
                edge(d, X_KID + W_KID, kid_y[k], X_ADULT, yy)
                if trig[j]:
                    chip(d, X_ADULT - 18 - 20 * (len(trig[j]) - 1), yy, trig[j])
                else:
                    d.text((X_ADULT - 8, yy), 'other', font=F_SMALL, fill=INK, anchor='rm')
                node(d, X_ADULT, yy, W_ADULT, names[j], a, 'adult', names[j] in DRAWN)
                d.text((X_ADULT + W_ADULT + 8, yy), tags[j], font=F_SMALL, fill=INK, anchor='lm')
        # mutants (from the "any adult" bracket) + the legend (straight from the ULTRA adult)
        ultra_row = FAM.index(a) * 3
        free = sorted([1, 4, 7, 10, 13], key=lambda r: -abs(r - ultra_row))
        mut_rows = sorted(free[:2])
        bx = X_ADULT + W_ADULT + 80
        d.line([(bx, adult_y[0]), (bx, adult_y[-1])], fill=INK, width=2)
        d.text((bx + 6, adult_y[0] - 12), 'any adult', font=F_SMALL, fill=INK)
        for (name, kind, row, label) in [(MUTANT[a][0], 'T', mut_rows[0], 'any adult + Tech food'),
                                         (MUTANT[a][1], 'C', mut_rows[1], 'any adult + Cosmic food')]:
            yy = adult_y[row]
            edge(d, bx, yy, X_SPEC, yy, col=FOOD_COL[kind], width=3, dash=True)
            d.text((X_SPEC + 4, yy - 27), label, font=F_SMALL, fill=INK)
            node(d, X_SPEC, yy, W_SPEC, name, a, kind, special=kind)
        yy = adult_y[ultra_row]
        d.line([(X_ADULT + W_ADULT + 62, yy), (X_SPEC, yy)], fill=FOOD_COL['L'], width=5)
        d.polygon([(X_SPEC - 2, yy), (X_SPEC - 14, yy - 7), (X_SPEC - 14, yy + 7)], fill=FOOD_COL['L'])
        d.text((X_SPEC + 4, yy - 27), 'ULTRA ' + ADULT[a + a][0] + ' + ' + LEGEND_FOOD[a], font=F_SMALL, fill=INK)
        node(d, X_SPEC, yy, W_SPEC, LEGEND[a], a, 'L', special='L')
        d.text((24 + 10, top - 4), FAM_NAME[a].upper() + ' LINE', font=F_SMALL, fill=INK)
        y0 += block
    return im


if __name__ == '__main__':
    forms = build()
    assert len(forms) == 120, len(forms)
    names = [f['name'] for f in forms]
    assert len(set(names)) == 120, [n for n in names if names.count(n) > 1]
    os.makedirs(os.path.join(ROOT, 'docs'), exist_ok=True)
    with open(os.path.join(ROOT, 'data', 'evolution_tree_draft.json'), 'w') as f:
        json.dump({'families': FAM_NAME, 'legendary_foods': LEGEND_FOOD, 'forms': forms}, f, indent=1)
    im = draw(forms)
    out = os.path.join(ROOT, 'docs', 'evolution_tree_draft.png')
    im.save(out)
    print('ok', im.size, out)
