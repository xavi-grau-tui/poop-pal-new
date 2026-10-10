import os
from PIL import Image, ImageDraw, ImageFont
from drinks_v2 import DRINKS, PIXEL
from drinks_draft import ORIGINALS, OUTD, PROJ
import level_icons as LI
F = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 16); FB = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 30); FS = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 20)
TYPES = [('watery', 'Watery', 'second chance', (180, 208, 226)), ('fizzy', 'Fizzy', 'more lift', (232, 192, 184)),
         ('caffeinated', 'Energy', 'easier timing', (206, 186, 164)), ('milky', 'Milky', 'sturdier', (238, 232, 220)), ('fruity', 'Fruity', 'more rewards', (240, 200, 160))]
INK = (60, 40, 32)

def sym(d, kind, x, y, s, col):
    """the type's symbol, ~8 px art at scale s"""
    P = lambda a, b: (x + a * s, y + b * s)
    if kind == 'watery':      # droplet
        d.polygon([P(4, 0), P(7, 5), P(4, 8), P(1, 5)], fill=col, outline=INK)
    elif kind == 'fizzy':     # bubble
        d.ellipse([*P(.5, .5), *P(7.5, 7.5)], fill=col, outline=INK, width=max(1, s // 2))
        d.ellipse([*P(2, 2), *P(4, 4)], fill=(255, 255, 255))
    elif kind == 'caffeinated':   # bolt
        d.polygon([P(5, 0), P(1, 5), P(4, 5), P(3, 8), P(7, 3), P(4, 3)], fill=col, outline=INK)
    elif kind == 'milky':     # a little milk bottle
        d.polygon([P(3, 0), P(5, 0), P(5, 2), P(7, 4), P(7, 8), P(1, 8), P(1, 4), P(3, 2)], fill=col, outline=INK)
        d.rectangle([*P(1.4, 5), *P(6.6, 6.2)], fill=(110, 150, 210))
    else:                     # fruity: star
        import math
        pts = [P(4 + math.cos(-math.pi / 2 + i * math.pi / 5) * (4 if i % 2 == 0 else 1.8), 4.2 + math.sin(-math.pi / 2 + i * math.pi / 5) * (4 if i % 2 == 0 else 1.8)) for i in range(10)]
        d.polygon(pts, fill=col, outline=INK)

SYMCOL = {'watery': (110, 170, 230), 'fizzy': (236, 120, 110), 'caffeinated': (240, 200, 60), 'milky': (250, 250, 250), 'fruity': (250, 160, 60)}
items = {}
for k, v in DRINKS.items(): items[(v['type'], v['lvl'])] = (v['name'], Image.open(f'{OUTD}/{k}.png'), False)
for k, ((t, l, n), _) in PIXEL.items(): items[(t, l)] = (n, Image.open(f'{OUTD}/{k}.png'), False)
for k, (t, l, n) in ORIGINALS.items(): items[(t, l)] = (n, Image.open(f'{PROJ}/textures/drinks/{k}.png').convert('RGBA'), True)
SC = 4; CW = 190; CH = 210; M = 30; LW = 190
W = 940; H = 130 + CH * 5 + 240
sh = Image.new('RGBA', (W, H), (244, 240, 230, 255)); d = ImageDraw.Draw(sh)
d.text((M, 24), 'Drinks draft: 5 types x 3 power levels = 15', fill=(40, 30, 30), font=FB)
d.text((M, 62), '* = original, kept as it is.  The symbols under each drink = its power level (1-3).', fill=(120, 110, 100), font=F)
for j in range(3):
    t = f'LEVEL {j + 1}'
    d.text((M + LW + j * CW + (CW - d.textlength(t, font=FS)) / 2, 98), t, fill=(90, 80, 70), font=FS)
for i, (t, lab, perk, col) in enumerate(TYPES):
    y = 130 + i * CH
    d.rounded_rectangle([M - 8, y, W - M + 8, y + CH - 12], radius=12, fill=(255, 252, 244), outline=tuple(int(v * .8) for v in col), width=3)
    d.text((M + 6, y + 14), lab.upper(), fill=tuple(int(v * .55) for v in col), font=FS)
    d.text((M + 6, y + 40), perk, fill=(120, 110, 100), font=F)
    big = LI.icon(t); sh.alpha_composite(big.resize((big.width * 5, big.height * 5), Image.NEAREST), (M + 8, y + 66))
    for j in range(3):
        n, im, orig = items[(t, j + 1)]
        x = M + LW + j * CW
        sh.alpha_composite(im.resize((32 * SC, 32 * SC), Image.NEAREST), (x + (CW - 32 * SC) // 2, y + 8))
        tt = n + (' *' if orig else '')
        d.text((x + (CW - d.textlength(tt, font=F)) / 2, y + 8 + 32 * SC + 4), tt, fill=(60, 50, 50), font=F)
        rw = LI.row(t, j + 1); rw = rw.resize((rw.width * 2, rw.height * 2), Image.NEAREST)
        sh.alpha_composite(rw, (int(x + (CW - rw.width) / 2), y + 8 + 32 * SC + 24))
# how the level shows in the menu and on the pal
y = 130 + 5 * CH + 10
d.text((M, y), 'In the menu: the type word stays, the level icons sit on the tag\'s top-right corner (mock-up)', fill=(40, 30, 30), font=FS)
frame = Image.open(PROJ + '/textures/menus/foodmenulabel_food.png').convert('RGBA')
tagt = Image.open(PROJ + '/textures/menus/foodtag.png').convert('RGBA')
for k, (key, t, lvl, name) in enumerate([('water', 'watery', 1, 'Water'), ('sodafloat', 'fizzy', 3, 'Soda Float')]):
    fr = frame.copy()
    p = f'{OUTD}/{key}.png' if os.path.exists(f'{OUTD}/{key}.png') else f'{PROJ}/textures/drinks/{key}.png'
    fr.alpha_composite(Image.open(p).convert('RGBA').resize((74, 74), Image.NEAREST), (round(57.1 - 37), round(57.9 - 37)))
    col = dict((a, c) for a, _, _, c in TYPES)[t]
    tg = tagt.resize((round(tagt.width * .84), round(tagt.height * .84))); px = tg.load()
    for yy in range(tg.height):
        for xx in range(tg.width):
            pr, pg, pb, pa = px[xx, yy]; px[xx, yy] = (pr * col[0] // 255, pg * col[1] // 255, pb * col[2] // 255, pa)
    tx, ty = 274 + 53 // 2 - tg.width // 2 + 26, 55 + 25 - tg.height // 2
    fr.alpha_composite(tg, (tx, ty))
    dd = ImageDraw.Draw(fr)
    word = dict((a_, l_) for a_, l_, _, _ in TYPES)[t]
    fw = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 21)
    dd.text((tx + (tg.width - dd.textlength(word, font=fw)) / 2, ty + tg.height / 2 - 11), word, fill=(92, 60, 44), font=fw)
    rw = LI.row(t, lvl); rw = rw.resize((rw.width * 2, rw.height * 2), Image.NEAREST)
    fr.alpha_composite(rw, (tx + tg.width - rw.width + 8, ty - rw.height // 2 - 2))
    sh.alpha_composite(fr, (M + k * 450, y + 34))
    ImageDraw.Draw(sh).text((M + k * 450 + 130, y + 34 + 40), name, fill=(166, 129, 94), font=FB)
y2 = y + 34 + 140
d.text((M, y2), 'On the pal (boost badge) and in the game HUD: the same 1-3 symbols, e.g.', fill=(60, 50, 50), font=F)
for k, (t, l) in enumerate([('watery', 1), ('fizzy', 2), ('caffeinated', 3)]):
    bx = M + 590 + k * 100
    d.rounded_rectangle([bx, y2 - 8, bx + 90, y2 + 28], radius=8, fill=(255, 252, 244), outline=INK, width=2)
    rw = LI.row(t, l); rw = rw.resize((rw.width * 3, rw.height * 3), Image.NEAREST)
    sh.alpha_composite(rw, (int(bx + 45 - rw.width / 2), int(y2 + 10 - rw.height / 2)))
sh.save('out/drinks_sheet.png'); print(sh.size)
