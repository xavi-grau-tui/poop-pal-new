"""Sheet: the foods' size icons (tier_icons.py), the drinks' level icons' sibling.
1 icon = baby food, 2 = kid food, 3 = adult food. Shows the 30 foods (as they are in the game,
textures/food/), which packs you have from the start (Shop.START_FOODS) and mock-ups of the menu
tag. Run with the scratchpad venv (Pillow): python tiersheet.py -> foods_tier_sheet.png"""
import os
from PIL import Image, ImageDraw, ImageFont
import tier_icons as TI

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
F = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 16)
FB = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 30)
FS = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 20)
INK = (60, 40, 32)
FAMS = ['green', 'sweet', 'greasy', 'spicy', 'sour']
TIERS = ['baby', 'kid', 'adult']
COL = {'green': (50, 144, 68), 'sweet': (82, 106, 144), 'greasy': (220, 140, 20), 'spicy': (200, 50, 44), 'sour': (140, 168, 30)}
TAG = {'green': (176, 200, 150), 'sweet': (232, 182, 196), 'greasy': (222, 186, 144), 'spicy': (226, 160, 144), 'sour': (226, 214, 150)}
WORD = {'green': 'Green', 'sweet': 'Sweet', 'greasy': 'Greasy', 'spicy': 'Spicy', 'sour': 'Sour'}
START = {'baby': ['green', 'sweet', 'greasy'], 'kid': ['green', 'sweet'], 'adult': ['green']}   # Shop.START_FOODS
# (scripts/FoodLibrary.gd: name, icon file)
FOODS = {
 ('green', 'baby'): [('Broccoli', 'broccoli'), ('Avocado', 'avocado')],
 ('green', 'kid'): [('Rice and Vegs', 'brownricevegs'), ('Salad Bowl', 'saladbowl')],
 ('green', 'adult'): [('Cucumber Sushi', 'cucumbersushi'), ('Dumplings', 'dumplings')],
 ('sweet', 'baby'): [('Chocolate', 'chocolate'), ('Cookie', 'cookie')],
 ('sweet', 'kid'): [('Glazed Donut', 'donut'), ('Rainbow Jelly', 'rainbowjelly')],
 ('sweet', 'adult'): [('Choco Cake', 'chococake'), ('Purin', 'purin')],
 ('greasy', 'baby'): [('Fried Egg', 'friedegg'), ('Fries', 'fries')],
 ('greasy', 'kid'): [('Spaghetti', 'spaghetthi'), ('Hot Dog', 'hotdog')],
 ('greasy', 'adult'): [('Club Sandwich', 'clubsandwich'), ('Cheeseburger', 'cheeseburger')],
 ('spicy', 'baby'): [('Chili Pepper', 'chili'), ('Jalapeno', 'jalapeno')],
 ('spicy', 'kid'): [('Fire Skewer', 'skewer'), ('Drumstick', 'drumstick')],
 ('spicy', 'adult'): [('Fire Ramen', 'ramen'), ('Curry Bowl', 'currybowl')],
 ('sour', 'baby'): [('Lemon', 'lemon'), ('Pickle', 'pickle')],
 ('sour', 'kid'): [('Kimchi', 'kimchi'), ('Umeboshi', 'umeboshi')],
 ('sour', 'adult'): [('Tom Yum', 'tomyum'), ('Pickle Jar', 'picklejar')],
}


def food(key):
    return Image.open(f'{PROJ}/textures/food/{key}.png').convert('RGBA')


def icons(fam, n, s):
    r = TI.row(fam, n)
    return r.resize((r.width * s, r.height * s), Image.NEAREST)


SC = 3; FW = 120; CW = FW * 2 + 24; RH = 190; M = 30; LW = 150
W = M * 2 + LW + CW * 3; H = 150 + RH * 5 + 330
sh = Image.new('RGBA', (W, H), (244, 240, 230, 255)); d = ImageDraw.Draw(sh)
d.text((M, 24), 'Food sizes: the type\'s icon 1-3 times', fill=(40, 30, 30), font=FB)
d.text((M, 62), '1 icon = baby food (hatches a pal), 2 = kid food (grows a baby), 3 = adult food (grows a kid).', fill=(120, 110, 100), font=F)
d.text((M, 82), 'Like the drinks\' power levels: the tag keeps its word, the icons sit on its top-right corner.', fill=(120, 110, 100), font=F)
d.text((M, 102), 'START = yours from the first launch (3 baby, 2 kid, 1 adult: the first pal can grow all the way up); the rest is in the Shop.', fill=(120, 110, 100), font=F)
for j, t in enumerate(TIERS):
    x = M + LW + j * CW
    lab = t.upper() + ' FOOD'
    d.text((x + (CW - d.textlength(lab, font=FS)) / 2, 124), lab, fill=(90, 80, 70), font=FS)
for i, fam in enumerate(FAMS):
    y = 150 + i * RH
    d.rounded_rectangle([M - 8, y, W - M + 8, y + RH - 12], radius=12, fill=(255, 252, 244), outline=COL[fam], width=3)
    d.text((M + 6, y + 12), fam.upper(), fill=COL[fam], font=FS)
    big = TI.icon(fam)
    sh.alpha_composite(big.resize((big.width * 5, big.height * 5), Image.NEAREST), (M + 10, y + 50))
    for j, t in enumerate(TIERS):
        x = M + LW + j * CW
        if j:
            d.line([x - 2, y + 14, x - 2, y + RH - 26], fill=(226, 218, 204), width=2)
        for k, (n, key) in enumerate(FOODS[(fam, t)]):
            fx = x + 12 + k * FW
            im = food(key)
            sh.alpha_composite(im.resize((32 * SC, 32 * SC), Image.NEAREST), (fx + (FW - 32 * SC) // 2, y + 10))
            d.text((fx + (FW - d.textlength(n, font=F)) / 2, y + 10 + 32 * SC + 4), n, fill=(60, 50, 50), font=F)
        ic = icons(fam, j + 1, 2)
        iy = y + 10 + 32 * SC + 30
        sh.alpha_composite(ic, (int(x + (CW - ic.width) / 2), iy + (22 - ic.height) // 2))
        # free from the start, or a pack from the Shop (bottom-right of the cell, by the icons)
        badge = 'START' if fam in START[t] else 'SHOP'
        bw = d.textlength(badge, font=F) + 14
        bx = x + CW - bw - 10
        by = iy + 1
        d.rounded_rectangle([bx, by, bx + bw, by + 20], radius=6, fill=(236, 246, 228) if badge == 'START' else (250, 238, 210),
                            outline=(110, 160, 90) if badge == 'START' else (196, 150, 70), width=2)
        d.text((bx + 7, by + 2), badge, fill=(70, 120, 60) if badge == 'START' else (150, 104, 40), font=F)

# the menu tag (mock-up), like the drinks sheet
y = 150 + 5 * RH + 6
d.text((M, y), 'In the menu (mock-up): the type word stays, the size icons on the tag\'s top-right corner', fill=(40, 30, 30), font=FS)
frame = Image.open(PROJ + '/textures/menus/foodmenulabel_food.png').convert('RGBA')
tagt = Image.open(PROJ + '/textures/menus/foodtag.png').convert('RGBA')
lock = Image.new('RGBA', (9, 11), (0, 0, 0, 0))
for yy, rowp in enumerate(["..#####..", ".#.....#.", ".#.....#.", ".#.....#.", "#########", "#bbbbbbb#", "#bbb#bbb#",
                           "#bbb#bbb#", "#bbbbbbb#", "#ddddddd#", "#########"]):   # UiArt.lock()
    for xx, ch in enumerate(rowp):
        c = {'#': (74, 44, 32), 'b': (214, 176, 112), 'd': (176, 136, 80)}.get(ch)
        if c:
            lock.putpixel((xx, yy), c + (255,))
fw = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 21)
MOCKS = [('chocolate', 'sweet', 1, 'Chocolate', False), ('donut', 'sweet', 2, 'Glazed Donut', False),
         ('ramen', 'spicy', 3, 'Fire Ramen', False), ('hotdog', 'greasy', 2, 'Kid food', True)]
for k, (key, fam, n, name, locked) in enumerate(MOCKS):
    fr = frame.copy()
    im = food(key).resize((74, 74), Image.NEAREST)
    if locked:                                   # the locked card: its silhouette and a padlock
        px = im.load()
        for yy in range(im.height):
            for xx in range(im.width):
                if px[xx, yy][3] > 0:
                    px[xx, yy] = (26, 15, 13, int(px[xx, yy][3] * .85))
    fr.alpha_composite(im, (round(57.1 - 37), round(57.9 - 37)))
    if locked:
        lk = lock.resize((lock.width * 3, lock.height * 3), Image.NEAREST)
        fr.alpha_composite(lk, (round(57.1 - lk.width / 2), round(57.9 - lk.height / 2 + 4)))
    col = TAG[fam]
    tg = tagt.resize((round(tagt.width * .84), round(tagt.height * .84))); px = tg.load()
    for yy in range(tg.height):
        for xx in range(tg.width):
            pr, pg, pb, pa = px[xx, yy]; px[xx, yy] = (pr * col[0] // 255, pg * col[1] // 255, pb * col[2] // 255, pa)
    tx, ty = 274 + 53 // 2 - tg.width // 2 + 26, 55 + 25 - tg.height // 2
    fr.alpha_composite(tg, (tx, ty))
    dd = ImageDraw.Draw(fr)
    word = WORD[fam]
    dd.text((tx + (tg.width - dd.textlength(word, font=fw)) / 2, ty + tg.height / 2 - 11), word, fill=(92, 60, 44), font=fw)
    rw = icons(fam, n, 2)
    fr.alpha_composite(rw, (tx + tg.width - rw.width + 8, ty - rw.height // 2 - 2))
    cx, cy = M + (k % 2) * 520, y + 34 + (k // 2) * 130
    sh.alpha_composite(fr, (cx, cy))
    ImageDraw.Draw(sh).text((cx + 130, cy + 40), name, fill=(166, 129, 94), font=FB)
d.text((M, H - 34), 'The same icons on the Shop\'s food packs (e.g. "Spicy Kid" = 2 flames) and on the locked cards.', fill=(120, 110, 100), font=F)
sh.save(os.path.join(HERE, 'foods_tier_sheet.png')); print(sh.size)
