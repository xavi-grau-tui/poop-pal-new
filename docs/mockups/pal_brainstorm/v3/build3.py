"""Builds the v3 brainstorm sheets (renders cached in out/<set>/).

    python build3.py                 every set + the mix sheet
    python build3.py snack critter   only these
Run with the scratchpad venv (numpy, scipy, Pillow)."""
import json, os, sys
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', 'food_drafts'))
import palgen3 as G
from sets3 import SETS
from sets4 import SHEET4
SETS = dict(SETS, sheet4=SHEET4)
import tier_icons as TI

PROJ = G.PROJ
OUTD = os.path.join(HERE, 'out')
FAMS = ['green', 'sweet', 'greasy', 'spicy', 'sour']
FAMLABEL = {'green': 'GREEN', 'sweet': 'SWEET', 'greasy': 'GREASY', 'spicy': 'SPICY', 'sour': 'SOUR'}
FAMCOL = {'green': (50, 144, 68), 'sweet': (72, 100, 150), 'greasy': (220, 140, 20), 'spicy': (200, 50, 44), 'sour': (130, 160, 40)}
font = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 16)
fontb = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 32)
fonts = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 22)
fontt = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 14)

CHECK = ['What I understood you are checking for:',
         '1  Picklet quality: one soft shape, solid 2 px outline, a gloss, light texture, a small face',
         '2  Cool, not sugary: deadpan, sleepy, side-eye, unimpressed, focused... only a few smile',
         '3  Simple: one idea per pal, a readable silhouette',
         '4  Variety: a different body for every pal, not one blob with toppings',
         '5  Original mixes: the 2nd / 3rd food makes a NEW thing that fits both foods',
         '6  Power Rangers colours: green, blue (sweet), yellow-orange, red, yellow-green',
         '7  Growth: baby small and simple, adults bigger and more elaborate']

# the pentagon: friends are neighbours, the other two are rivals (tools/design/evolution_tree.py)
def friends(a):
    i = FAMS.index(a)
    return [FAMS[(i - 1) % 5], FAMS[(i + 1) % 5]]

def rivals(a):
    return [f for f in FAMS if f != a and f not in friends(a)]

def triggers(a, b):
    """the 3rd foods that lead to each of a kid's 3 adults"""
    if a == b:
        return [[a], friends(a), rivals(a)], ['ULTRA', 'BLOOM', 'CLASH']
    return [[a], [b], [f for f in FAMS if f not in (a, b)]], ['ROOT', 'PEAK', 'CHAOS']


def validate(line):
    n, spec, note = G.parse(line)
    if 'special' in spec:
        return []
    bad = []
    if spec['plan'] not in G.PLANS: bad.append('plan ' + spec['plan'])
    for k in ('pal', 'acc', 'acc2'):
        if spec.get(k) and spec[k] not in G.P: bad.append('palette ' + spec[k])
    known = G.BACK | G.FRONT | G.REGION | G.OVER | {'cherry', 'flower', 'crown_b'}
    for p, tok in spec['parts']:
        if p not in known: bad.append('part ' + p)
        if tok and tok not in ('p', 'a', 'b') and tok not in G.P: bad.append('colour ' + tok)
    if spec['eyes'] not in G.EYES: bad.append('eyes ' + spec['eyes'])
    if spec['mouth'] not in G.MOUTHS: bad.append('mouth ' + spec['mouth'])
    return bad


import hashlib
RENDERER = hashlib.md5(open(os.path.join(HERE, 'palgen3.py'), 'rb').read()).hexdigest()[:10]


def render_line(key, idx, line, stage, force=False):
    os.makedirs(os.path.join(OUTD, key), exist_ok=True)
    path = os.path.join(OUTD, key, f'{idx:03d}.png')
    n, spec, note = G.parse(line)
    meta = path + '.txt'
    if not force and os.path.exists(path) and os.path.exists(meta) and open(meta).read() == line + '|' + stage + '|' + RENDERER:
        return n, Image.open(path).convert('RGBA'), note
    im = G.render(spec, stage, n)
    im.save(path)
    open(meta, 'w').write(line + '|' + stage + '|' + RENDERER)
    return n, im, note


NEW_NAMES = set()


def rendered(key, S):
    NEW_NAMES.clear()
    NEW_NAMES.update(S.get('new', []))
    out = {'title': S['title'], 'sub': S.get('sub', 'every kid line is a snack, a yokai or a critter; the other two sheets show the other two for the same line')}
    i = 0
    probs = []
    def r(line, st):
        nonlocal i
        b = validate(line)
        if b: probs.append((line.split('|')[0].strip(), b))
        res = render_line(key, i, line, st)
        i += 1
        return res
    for fam in FAMS:
        f = S[fam]
        out[fam] = {'baby': r(f['baby'], 'baby'), 'kids': [r(l, 'kid') for l in f['kids']], 'adults': [r(l, 'adult') for l in f['adults']],
                    'flavours': f.get('flavours')}
    out['mutants'] = [r(l, 'mutant') for l in S['mutants']]
    out['legends'] = [r(l, 'legend') for l in S['legends']]
    for p in probs:
        print('  !', key, p)
    names = [it[0] for fam in FAMS for it in [out[fam]['baby']] + out[fam]['kids'] + out[fam]['adults']] + [it[0] for it in out['mutants'] + out['legends']]
    keep = {'Bud', 'Ember', 'Picklet'}
    dup = sorted({n for n in names if names.count(n) > 1 and n not in keep})
    if dup:
        print('  ! duplicate names', key, dup)
    return out


def icon(fam, scale=2):
    im = TI.icon(fam)
    return im.resize((im.width * scale, im.height * scale), Image.NEAREST)


CW, CH = 220, 228
def cell(sheet, x, y, item, foods=None, tag=None):
    n, im, _ = item
    big = im.resize((110 * 2, 100 * 2), Image.NEAREST)        # the whole canvas: what the game shows
    sheet.alpha_composite(big, (x, y))
    d = ImageDraw.Draw(sheet)
    w = d.textlength(n, font=font)
    d.text((x + (CW - w) / 2, y + 204), n, fill=(60, 50, 50), font=font)
    if n in NEW_NAMES:                   # a new design (sheet 4)
        tw = d.textlength('NEW', font=fontt) + 10
        d.rounded_rectangle([x + CW - tw - 8, y + 182, x + CW - 8, y + 200], radius=5, fill=(110, 170, 90))
        d.text((x + CW - tw - 3, y + 184), 'NEW', fill=(255, 255, 255), font=fontt)
    if foods:                          # which 3rd foods lead here
        icons = [icon(f, 1 if len(foods) > 2 else 2) for f in foods]
        tw = sum(i.width for i in icons) + 3 * (len(icons) - 1)
        xx = x + 6
        for ic in icons:
            sheet.alpha_composite(ic, (xx, y + 6 + (22 - ic.height) // 2))
            xx += ic.width + 3
        if tag:
            d.text((xx + 4, y + 9), tag, fill=(170, 160, 150), font=fontt)


def sheet(data, path):
    M = 30; HEAD = 250; BANDH = CH * 4 + 90
    W_ = M * 2 + CW * 6 + 30
    H_ = HEAD + BANDH * 5 + (CH + 60) * 3 + M
    sh = Image.new('RGBA', (W_, H_), (244, 240, 230, 255))
    d = ImageDraw.Draw(sh)
    d.text((M, 22), data['title'], fill=(40, 30, 30), font=fontb)
    d.text((M, 62), data['sub'], fill=(120, 110, 100), font=font)
    for i, t in enumerate(CHECK):
        d.text((M + (0 if i == 0 else 14), 96 + i * 19), t, fill=(70, 60, 55) if i == 0 else (110, 100, 92), font=font)
    d.text((W_ - M - 430, 22), 'Picklet, Bud and Ember are kept in every set.', fill=(120, 110, 100), font=font)
    d.text((W_ - M - 430, 42), 'Column = the 2nd food; the icons on each adult =', fill=(120, 110, 100), font=font)
    d.text((W_ - M - 430, 62), 'the 3rd food that leads to it.', fill=(120, 110, 100), font=font)
    y = HEAD
    for fam in FAMS:
        f = data[fam]
        d.rounded_rectangle([M - 10, y, W_ - M + 10, y + BANDH - 20], radius=14, fill=(255, 252, 244), outline=FAMCOL[fam], width=4)
        d.rectangle([M - 10, y, M + 140, y + 34], fill=FAMCOL[fam])
        d.text((M + 4, y + 6), FAMLABEL[fam], fill=(255, 255, 255), font=fonts)
        cy = y + 40
        cell(sh, M, cy + CH * 1, f['baby'])
        d.text((M + 70, cy + CH * 1 - 4), 'baby', fill=(150, 140, 130), font=font)
        for i, kd in enumerate(f['kids']):
            x = M + 30 + CW * (i + 1)
            fc = FAMS[i]
            d.rectangle([x + 40, cy + 6, x + CW - 20, cy + 9], fill=FAMCOL[fc])
            sh.alpha_composite(icon(fc), (x + 12, cy - 4))
            if f.get('flavours'):
                t = f['flavours'][i]
                d.text((x + CW - 20 - d.textlength(t, font=fontt), cy + 12), t, fill=(170, 160, 150), font=fontt)
            cell(sh, x, cy + 14, kd)
            trig, tags = triggers(fam, fc)
            for j in range(3):
                cell(sh, x, cy + 14 + CH * (j + 1), f['adults'][i * 3 + j], trig[j], tags[j])
        y += BANDH
    d.text((M, y), 'MUTANTS: any adult + a microchip / battery (tech) or alien goo / moon rock (cosmic)', fill=(40, 30, 30), font=fonts)
    for i, it in enumerate(data['mutants']):
        cell(sh, M + 15 + CW * (i % 6) if i < 6 else M + 15 + CW * (i - 6), y + 30 + CH * (i // 6), it)
    y += 30 + CH * 2 + 20
    d.text((M, y), 'LEGENDS: the pure ULTRA adult + its legendary food', fill=(40, 30, 30), font=fonts)
    for i, it in enumerate(data['legends']):
        cell(sh, M + 15 + CW * i, y + 30, it)
    y += 30 + CH + 20
    sh = sh.crop((0, 0, W_, y + M))
    sh.save(path)
    print('sheet', path, sh.size)


if __name__ == '__main__':
    which = sys.argv[1:] or list(SETS)
    os.makedirs(OUTD, exist_ok=True)
    for i, key in enumerate(which):
        data = rendered(key, SETS[key])
        sheet(data, os.path.join(HERE, f'{key}.png'))
