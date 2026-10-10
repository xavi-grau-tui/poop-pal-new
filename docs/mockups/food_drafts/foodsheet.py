import os
from PIL import Image, ImageDraw, ImageFont
from foods_v2 import FOODS
from foods_draft import ORIGINALS, OUTD, PROJ
F = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 16); FB = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 30); FS = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 20)
FAMS = ['green', 'sweet', 'greasy', 'spicy', 'sour']; STAGES = ['baby', 'kid', 'adult', 'spare']
COL = {'green': (50, 144, 68), 'sweet': (82, 106, 144), 'greasy': (240, 158, 30), 'spicy': (200, 50, 44), 'sour': (152, 182, 40)}
TAG = {"green": (176, 200, 150), "sweet": (232, 182, 196), "greasy": (222, 186, 144), "spicy": (226, 160, 144), "sour": (226, 214, 150)}
items = {}
for k, v in FOODS.items(): items.setdefault((v['fam'], v['stage']), []).append((v['name'], Image.open(f'{OUTD}/{k}.png'), False))
for k, (fam, st, n) in ORIGINALS.items(): items.setdefault((fam, st), []).insert(0, (n, Image.open(f'{PROJ}/textures/food/{k}.png').convert('RGBA'), True))
SC = 4; CW = 150; CH = 175; M = 30; LW = 130
W = M * 2 + LW + CW * 7 + 120; H = 120 + CH * 5 + 260
sh = Image.new('RGBA', (W, H), (244, 240, 230, 255)); d = ImageDraw.Draw(sh)
d.text((M, 24), 'Foods draft: 5 types x baby / kid / adult x 2 = 30', fill=(40, 30, 30), font=FB)
d.text((M, 62), '* = kept as it is (the 8 originals + the glazed donut).  Spare = an extra option.', fill=(120, 110, 100), font=F)
for j, st in enumerate(STAGES):
    x = M + LW + 20 + j * (CW * 2 + 20)
    d.text((x + CW - d.textlength(st.upper(), font=FS) / 2, 92), st.upper(), fill=(90, 80, 70), font=FS)
for i, fam in enumerate(FAMS):
    y = 120 + i * CH
    d.rounded_rectangle([M - 8, y, W - M + 8, y + CH - 12], radius=12, fill=(255, 252, 244), outline=COL[fam], width=3)
    d.text((M + 6, y + 10), fam.upper(), fill=COL[fam], font=FS)
    for j, st in enumerate(STAGES):
        for k, (n, im, orig) in enumerate(items.get((fam, st), [])):
            x = M + LW + 20 + j * (CW * 2 + 20) + k * CW
            sh.alpha_composite(im.resize((32 * SC, 32 * SC), Image.NEAREST), (x + (CW - 32 * SC) // 2, y + 8))
            t = n + (' *' if orig else '')
            d.text((x + (CW - d.textlength(t, font=F)) / 2, y + 8 + 32 * SC + 6), t, fill=(60, 50, 50), font=F)
# the menu label mock: frame + type tag + icon centred in the eat ring
y = 120 + 5 * CH + 10
d.text((M, y), 'In the menu (mock-up): the icon centred in its round slot', fill=(40, 30, 30), font=FS)
frame = Image.open(PROJ + '/textures/menus/foodmenulabel_food.png').convert('RGBA')
ring = Image.open(PROJ + '/textures/menus/circleborder_small.png').convert('RGBA')
tagt = Image.open(PROJ + '/textures/menus/foodtag.png').convert('RGBA')
for k, (key, fam) in enumerate([('chocolate', 'sweet'), ('ramen', 'spicy')]):
    fr = frame.copy()
    rg = ring.resize((round(123 / 1.5), round(119 / 1.5)))
    cx, cy = 57.1, 57.9                     # the eat ring's centre in the frame's pixels
    p = f'{OUTD}/{key}.png' if os.path.exists(f'{OUTD}/{key}.png') else f'{PROJ}/textures/food/{key}.png'
    ic = Image.open(p).convert('RGBA').resize((74, 74), Image.NEAREST)
    fr.alpha_composite(ic, (round(cx - 37), round(cy - 37)))
    tg = tagt.resize((round(tagt.width * .84), round(tagt.height * .84)))
    r, g, b = TAG[fam]; px = tg.load()
    for yy in range(tg.height):
        for xx in range(tg.width):
            pr, pg, pb, pa = px[xx, yy]; px[xx, yy] = (pr * r // 255, pg * g // 255, pb * b // 255, pa)
    fr.alpha_composite(tg, (274 + 53 // 2 - tg.width // 2 + 26, 55 + 25 - tg.height // 2))
    sh.alpha_composite(fr, (M + k * 430, y + 34))
    dd = ImageDraw.Draw(sh); dd.text((M + k * 430 + 130, y + 34 + 40), {'chocolate': 'Chocolate', 'ramen': 'Fire\n Ramen'}[key], fill=(166, 129, 94), font=FB)
sh.save('out/foods_sheet.png'); print(sh.size)
