import json, os, sys
from PIL import Image, ImageDraw, ImageFont
from palgen2 import render, P
from sets import SET_A, SET_B
PROJ = '/Users/xaviergrau/Documents/PoopPal Godot/poop-pal-main-kiro'
OUTD = 'out'; os.makedirs(OUTD, exist_ok=True)
FAMS = ['green', 'sweet', 'greasy', 'spicy', 'sour']
FAMLABEL = {'green': 'GREEN', 'sweet': 'SWEET', 'greasy': 'GREASY', 'spicy': 'SPICY', 'sour': 'SOUR'}
FAMCOL = {'green': (50, 144, 68), 'sweet': (82, 106, 144), 'greasy': (240, 158, 30), 'spicy': (200, 50, 44), 'sour': (152, 182, 40)}
font = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 16)
fontb = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 32)
fonts = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 22)

def parse(line):
    n, b, p, a, f, e, note = line.split('|')
    if b.startswith('='):
        return n, dict(special=b[1:]), note
    spec = dict(b=b, p=p, f=f.split(), e=e)
    if a != '-': spec['a'] = a
    return n, spec, note

def current():
    d = json.load(open(PROJ + '/data/evolution_tree.json'))
    forms = d['forms']
    def spr(k):
        return Image.open(f'{PROJ}/textures/pet/forms/{k}-1.png').convert('RGBA').crop((60, 60, 170, 160))
    out = {'title': 'Current 120 pals'}
    for fam in FAMS:
        baby = d['starters'][fam]
        kids = [d['next'][baby][f] for f in FAMS]
        adults = []
        for kd in kids:
            ad = sorted([k for k, v in forms.items() if v['from'] == kd and v['stage'] == 3], key=lambda k: forms[k]['no'])
            adults += ad
        out[fam] = {'baby': (forms[baby]['name'], spr(baby), forms[baby]['desc']),
                    'kids': [(forms[k]['name'], spr(k), forms[k]['desc']) for k in kids],
                    'adults': [(forms[k]['name'], spr(k), forms[k]['desc']) for k in adults]}
    mut = sorted([k for k, v in forms.items() if v['stage'] == 4], key=lambda k: forms[k]['no'])
    leg = sorted([k for k, v in forms.items() if v['stage'] == 5], key=lambda k: forms[k]['no'])
    out['mutants'] = [(forms[k]['name'], spr(k), forms[k]['desc']) for k in mut]
    out['legends'] = [(forms[k]['name'], spr(k), forms[k]['desc']) for k in leg]
    return out

def rendered(S):
    out = {'title': S['title']}
    for fam in FAMS:
        f = S[fam]
        def r(line, st):
            n, spec, note = parse(line); return (n, render(spec, st), note)
        out[fam] = {'baby': r(f['baby'], 'baby'), 'kids': [r(l, 'kid') for l in f['kids']], 'adults': [r(l, 'adult') for l in f['adults']]}
    out['mutants'] = [(lambda n, s, no: (n, render(s, 'mutant'), no))(*parse(l)) for l in S['mutants']]
    out['legends'] = [(lambda n, s, no: (n, render(s, 'legend'), no))(*parse(l)) for l in S['legends']]
    return out

CW, CH = 200, 214     # cell: 2x sprite (220x200 cropped to width) + label
SPR = 2
def cell(sheet, x, y, item, tint=None):
    n, im, _ = item
    big = im.resize((110 * SPR, 100 * SPR), Image.NEAREST).crop((10, 10, 210, 200))
    sheet.alpha_composite(big, (x, y))
    d = ImageDraw.Draw(sheet)
    w = d.textlength(n, font=font)
    d.text((x + (CW - w) / 2, y + 192), n, fill=(60, 50, 50), font=font)

def sheet(data, path, key):
    M = 30; HEAD = 90; BANDH = CH * 4 + 90
    W_ = M * 2 + CW * 6 + 30
    H_ = HEAD + BANDH * 5 + (CH + 60) * 3 + M
    sh = Image.new('RGBA', (W_, H_), (244, 240, 230, 255))
    d = ImageDraw.Draw(sh)
    d.text((M, 26), data['title'], fill=(40, 30, 30), font=fontb)
    d.text((W_ - M - 560, 36), 'baby  |  kids (2nd food: G S F H U)  |  3 adults below each kid', fill=(120, 110, 100), font=font)
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
            d.rectangle([x + 20, cy + 4, x + CW - 20, cy + 8], fill=FAMCOL[fc])
            cell(sh, x, cy + 10, kd)
            for j in range(3):
                cell(sh, x, cy + 10 + CH * (j + 1), f['adults'][i * 3 + j])
        y += BANDH
    for title, items, cols in (('MUTANTS (microchip / alien goo)', data['mutants'], 6), ('LEGENDS', data['legends'], 6)):
        d.text((M, y), title, fill=(40, 30, 30), font=fonts)
        rows = (len(items) + cols - 1) // cols
        for i, it in enumerate(items):
            cell(sh, M + 15 + CW * (i % cols), y + 30 + CH * (i // cols), it)
        y += 30 + CH * rows + 20
    sh = sh.crop((0, 0, W_, y + M))
    sh.save(path)
    # individual sprites for the gallery
    os.makedirs(f'{OUTD}/{key}', exist_ok=True)
    idx = []
    def save(item, fam, stage, i):
        n, im, note = item
        fn = f'{key}/{len(idx):03d}.png'
        im.save(f'{OUTD}/{fn}'); idx.append(dict(n=n, fam=fam, stage=stage, note=note, img=fn, i=i))
    for fam in FAMS:
        f = data[fam]; save(f['baby'], fam, 'baby', 0)
        for i, kd in enumerate(f['kids']):
            save(kd, fam, 'kid', i)
            for j in range(3): save(f['adults'][i * 3 + j], fam, 'adult', i)
    for it in data['mutants']: save(it, 'mutant', 'mutant', 0)
    for it in data['legends']: save(it, 'legend', 'legend', 0)
    return idx

if __name__ == '__main__':
    which = sys.argv[1:] or ['current', 'a', 'b']
    allidx = {}
    for w in which:
        data = current() if w == 'current' else rendered(SET_A if w == 'a' else SET_B)
        allidx[w] = sheet(data, f'{OUTD}/sheet_{w}.png', w)
        print(w, len(allidx[w]))
    json.dump(allidx, open(f'{OUTD}/index_{"_".join(which)}.json', 'w'), indent=0)
