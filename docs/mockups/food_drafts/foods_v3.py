"""Third food round (user, 2026-10-11): one more food per type and size, for variety (15).
Same look and pipeline as the first 30 (foods_draft.py / foods_v2.py: painted big, fitted to the
32x32 box, dark warm outline, chunky colours, centred).
    python foods_v3.py   -> icons3/<name>.png + foods3_sheet.png"""
import os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import foods_draft as fd
from hires import field, height, material, seam, dots
from foods_draft import (B, sq, M, L, ell, draw, OUTC, BREAD, WOOD, PLATE, CHOC, CREAM, BLUE, VEG, PALEVEG,
                         RED, JALA, TORT, MEAT, RICE, LEMON, PICKLE, PASTRY, EGG, YOLK, FRY, BOX, GLASS, CHERRY,
                         BOWLW, LIME, BOWLRED)

HERE = os.path.dirname(os.path.abspath(__file__))
OUTA = np.array(OUTC, np.float32)
NEW = {}


def food(fam, stage, name):
    def deco(f):
        NEW[f.__name__] = dict(fam=fam, stage=stage, name=name, fn=f)
        fd.FOODS[f.__name__] = NEW[f.__name__]
        return f
    return deco


POD = [(30, 64, 24), (52, 104, 36), (84, 140, 50), (120, 170, 70), (170, 206, 110)]
BEAN = [(70, 120, 30), (110, 170, 50), (150, 210, 80), (196, 236, 120), (240, 252, 200)]
AVO = [(70, 110, 30), (120, 160, 50), (166, 196, 84), (200, 222, 120), (232, 244, 176)]
LACQ = [(30, 10, 10), (60, 16, 16), (100, 26, 24), (140, 44, 36), (180, 80, 64)]
CARROT = [(150, 50, 10), (210, 96, 24), (240, 140, 50), (250, 180, 90), (255, 220, 150)]
CANDY_W = [(150, 60, 90), (210, 110, 140), (240, 160, 186), (250, 200, 216), (255, 236, 244)]
SCOOP = [(40, 54, 90), (70, 94, 140), (110, 140, 186), (150, 180, 220), (200, 220, 246)]
SYRUP = [(110, 50, 10), (170, 90, 20), (210, 130, 40), (236, 170, 70), (250, 210, 120)]
BUTTER = [(200, 170, 60), (236, 210, 100), (250, 232, 150), (255, 244, 196), (255, 252, 230)]
CHEESE = [(190, 130, 20), (236, 176, 40), (252, 210, 80), (255, 232, 130), (255, 248, 200)]
PEPPERONI = [(90, 14, 10), (150, 30, 20), (196, 54, 36), (226, 90, 60), (246, 140, 110)]
PAPER = [(150, 140, 124), (200, 192, 176), (230, 224, 210), (246, 242, 232), (255, 254, 248)]
SAUCE = [(90, 10, 10), (160, 24, 20), (210, 44, 30), (236, 90, 60), (250, 150, 120)]
CAP = [(20, 50, 20), (40, 90, 36), (70, 134, 56), (110, 170, 80), (160, 206, 120)]
TTEOK = [(170, 150, 130), (214, 196, 176), (236, 224, 208), (248, 242, 232), (255, 252, 246)]
LIMEPULP = [(120, 170, 60), (170, 210, 90), (206, 232, 130), (226, 244, 170), (244, 252, 214)]
KIWISKIN = [(60, 40, 20), (100, 70, 36), (140, 104, 56), (174, 138, 84), (206, 176, 120)]
KIWIFLESH = [(70, 120, 20), (110, 166, 40), (150, 200, 70), (186, 226, 110), (222, 244, 170)]
FISH = [(180, 170, 160), (220, 212, 202), (240, 236, 228), (250, 248, 242), (255, 255, 252)]
ONION = [(100, 30, 70), (150, 56, 110), (196, 100, 150), (226, 150, 190), (246, 204, 226)]


# ------------------------------------------------------------------ GREEN
@food('green', 'baby', 'Edamame')
def edamame(c):
    pod = [(5 + i * 3.0, 24 - i * 2.6, 4.4 - abs(i - 3) * .35, 4.0 - abs(i - 3) * .3) for i in range(8)]
    B(c, pod, POD, spec_amt=.25, grain=.2)
    for i in range(3):
        x, y = 9 + i * 6, 20.5 - i * 5.2
        B(c, [(x, y, 3.9, 3.7)], [(110, 160, 40), (150, 200, 70), (190, 232, 110), (222, 248, 160), (248, 255, 220)], spec_amt=.6, spec_pow=14, grain=.06)
        seam(c, field(c, [(x, y, 3.9, 3.7)]) > 1, (c.a > .5) & ~(field(c, [(x, y, 3.9, 3.7)]) > 1), .35, np.array((40, 80, 26), np.float32))
    L(c, [[(27, 6), (29, 3.5)]], (70, 110, 40), 1.3)


@food('green', 'kid', 'Avocado Toast')
def avocadotoast(c):
    t = sq(c, 16, 17, 13, 11.5, 5)
    M(c, t, t > 1, BREAD, spec_amt=.2, grain=.18)
    inner = sq(c, 16, 17.5, 10.6, 9, 5)
    M(c, inner, inner > 1, PASTRY, spec_amt=.15, grain=.2)
    for (x, y) in [(11, 13), (21, 13), (11, 22), (21, 22), (16, 17.5)]:
        ff = field(c, [(x, y, 4.2, 3.4)])
        M(c, ff, ff > 1, AVO, spec_amt=.35, grain=.12)
        seam(c, ff > 1, (c.a > .5) & ~(ff > 1), .35, np.array((60, 90, 30), np.float32))
    dots(c, 9, (6, 9, 26, 25, lambda x, y: c.alpha_at(x, y) > .5), [(200, 50, 30)], r=.55, seed=4, angle=False)


@food('green', 'adult', 'Veggie Bento')
def bento(c):
    box = sq(c, 16, 17, 14.5, 12, 8)
    M(c, box, box > 1, LACQ, spec_amt=.5, spec_pow=16, grain=.08)
    inner = sq(c, 16, 17.5, 12.6, 10, 8)
    M(c, inner, inner > 1, [(26, 20, 18), (44, 34, 30), (64, 52, 46), (86, 72, 64), (110, 96, 86)], spec_amt=.1, grain=.1)
    rice = sq(c, 10, 17.5, 5.6, 9.2, 6)
    M(c, rice, rice > 1, RICE, spec_amt=.25, grain=.2)
    B(c, [(9.5, 17.5, 1.6, 1.6)], [(90, 10, 30), (150, 26, 50), (200, 56, 74), (230, 104, 112), (250, 164, 166)], spec_amt=.6)
    rr = np.random.default_rng(5)
    for (x, y, r) in [(19.5, 12.5, 3.2), (24, 13, 3.0), (21.5, 9.8, 2.6)]:
        ff = field(c, [(x, y, r, r * .9)])
        micro = [(x + rr.uniform(-.7, .7) * r, y + rr.uniform(-.7, .6) * r, 1.2, 1.2, .4) for _ in range(6)]
        material(c, np.clip(height(ff, .5) * .7 + height(field(c, micro), .6) * .5, 0, 1.3), ff > 1, VEG, bump=7, spec_amt=.15, grain=.22, ao=.5)
    for (x, y) in [(19, 21.5), (24.5, 22)]:
        B(c, [(x, y, 2.6, 2.4)], CARROT, spec_amt=.4)
    B(c, [(22, 17, 4, 1.8)], [(150, 120, 30), (210, 176, 50), (240, 210, 90), (252, 232, 140), (255, 248, 200)], spec_amt=.4)


# ------------------------------------------------------------------ SWEET
@food('sweet', 'baby', 'Candy')
def candy(c):
    for sd in (-1, 1):
        f = field(c, [(16 + sd * 10.5, 16, 3.6, 6.5), (16 + sd * 7.5, 16, 2.2, 3)])
        M(c, f, f > 1, CANDY_W, spec_amt=.5, grain=.1)
        draw(c, lambda d, sd=sd: [d.line([c.P(16 + sd * 8.5, 16 + k), c.P(16 + sd * 13, 16 + k * 2.2)], fill=(200, 110, 140), width=int(.6 * c.k * c.z)) for k in (-2.5, 0, 2.5)])
    B(c, [(16, 16, 7.2, 6.4)], SCOOP, spec_amt=.8, spec_pow=12, grain=.06)


@food('sweet', 'kid', 'Ice Cream')
def icecream(c):
    h = np.clip((c.y - 14) / 16, 0, 1)
    cone = (c.y > 14) & (c.y < 30.5) & (np.abs(c.x - 16) < 8.6 * (1 - h) + .6)
    material(c, np.clip(1 - np.abs(c.x - 16) / 9.5, 0, 1) ** .4, cone, [(150, 96, 40), (206, 150, 72), (232, 190, 110), (246, 216, 150), (255, 236, 190)], bump=4, spec_amt=.2, grain=.12)
    draw(c, lambda d: [d.line([c.P(8 + k * 3.2, 14), c.P(16 + (k - 2.5) * .5, 30)], fill=(176, 120, 56), width=int(.45 * c.k * c.z)) for k in range(6)]
         + [d.line([c.P(24 - k * 3.2, 14), c.P(16 - (k - 2.5) * .5, 30)], fill=(176, 120, 56), width=int(.45 * c.k * c.z)) for k in range(6)])
    sc = field(c, [(16, 9.5, 9.2, 8), (9, 14, 3.2, 2.4), (23, 14.2, 3.2, 2.4), (16, 14.5, 7, 2.2), (12, 16.5, 1.4, 2.4)])
    M(c, sc, sc > 1, SCOOP, spec_amt=.6, grain=.08)
    B(c, [(19.5, 2.5, 2.2, 2.2)], CHERRY, spec_amt=.8)


@food('sweet', 'adult', 'Pancakes')
def pancakes(c):
    B(c, [(16, 26, 15, 4.6)], PLATE, spec_amt=.5, grain=.05)
    for i in range(3):
        f = sq(c, 16, 22.5 - i * 4.2, 12 - i * .6, 2.6, 3)
        M(c, f, f > 1, PASTRY, spec_amt=.3, grain=.14)
        seam(c, f > 1, (c.a > .5) & ~(f > 1), .35, OUTA)
    sy = field(c, [(16, 13.2, 10, 2.2), (9, 16, 1.6, 2.6), (22, 17, 1.6, 3.2)])
    M(c, sy, sy > 1, SYRUP, spec_amt=.8, spec_pow=12, grain=.05)
    B(c, [(16, 10.6, 3.4, 2.2)], BUTTER, spec_amt=.5)
    for (x, y) in [(10, 11.5), (22.5, 11.8), (19.5, 9.2)]:
        B(c, [(x, y, 1.7, 1.7)], SCOOP, spec_amt=.8, grain=.04)


# ------------------------------------------------------------------ GREASY
@food('greasy', 'baby', 'Nugget')
def nugget(c):
    rr = np.random.default_rng(8)
    for (x, y, rx, ry) in [(11, 19, 8, 6.5), (21, 14, 7.5, 6), (17, 23, 7, 5)]:
        f = field(c, [(x, y, rx, ry), (x + rx * .4, y - ry * .3, rx * .6, ry * .6)])
        micro = [(x + rr.uniform(-.8, .8) * rx, y + rr.uniform(-.8, .8) * ry, 1.5, 1.5, .35) for _ in range(12)]
        material(c, np.clip(height(f, .5) * .8 + height(field(c, micro), .6) * .35, 0, 1.3), f > 1, FRY, bump=6, spec_amt=.35, grain=.18, ao=.45)
        seam(c, f > 1, (c.a > .5) & ~(f > 1), .4, OUTA)


@food('greasy', 'kid', 'Pizza Slice')
def pizzaslice(c):
    tri = (c.y > 4) & (c.y < 29) & (np.abs(c.x - 16) < (29 - c.y) * .52)
    material(c, np.clip((29 - c.y) / 25, 0, 1) ** .3, tri, CHEESE, bump=4, spec_amt=.45, grain=.12)
    crust = sq(c, 16, 5.5, 13.5, 3, 4)
    M(c, crust, crust > 1, BREAD, spec_amt=.25, grain=.16)
    for (x, y) in [(12, 11), (19.5, 12.5), (15.5, 18.5), (17, 24)]:
        if not tri[min(int(y * c.k * c.z), tri.shape[0] - 1), min(int(x * c.k * c.z), tri.shape[1] - 1)]:
            pass
        B(c, [(x, y, 2.6 - (y - 10) * .04, 2.4 - (y - 10) * .04)], PEPPERONI, spec_amt=.5, grain=.08)


@food('greasy', 'adult', 'Fish and Chips')
def fishchips(c):
    cone = (c.y > 13) & (c.y < 30) & (np.abs(c.x - 13) < 9 - (c.y - 13) * .3)
    for i, (x, y) in enumerate([(7, 11), (10, 8), (13, 10.5), (16, 7.5), (8.5, 14), (12, 13), (15, 12.5)]):
        f = sq(c, x, y, 1.5, 5.2, 3)
        M(c, f, f > 1, FRY, spec_amt=.3, grain=.12)
    material(c, np.clip(1 - np.abs(c.x - 13) / 10, 0, 1) ** .5, cone, PAPER, bump=3, spec_amt=.2, grain=.08)
    draw(c, lambda d: [d.line([c.P(4, 17 + k * 4), c.P(22, 17 + k * 4)], fill=(196, 60, 50), width=int(.7 * c.k * c.z)) for k in range(3)])
    fish = field(c, [(23, 15, 6.5, 4.4), (17.5, 14, 2.6, 2.2), (28.5, 13, 2.2, 3.4)])
    rr = np.random.default_rng(2)
    micro = [(rr.uniform(17, 30), rr.uniform(10, 20), 1.4, 1.4, .3) for _ in range(14)]
    material(c, np.clip(height(fish, .5) * .8 + height(field(c, micro), .6) * .3, 0, 1.3), fish > 1, FRY, bump=6, spec_amt=.35, grain=.18)
    seam(c, fish > 1, (c.a > .5) & ~(fish > 1), .4, OUTA)
    w = ell(c, 26, 24, 4, 3) & (c.y < 25)
    material(c, np.clip(height(field(c, [(26, 24, 4, 3)]), .5), 0, 1), w, LEMON, bump=4, spec_amt=.5, grain=.08)


# ------------------------------------------------------------------ SPICY
@food('spicy', 'baby', 'Hot Sauce')
def hotsauce(c):
    b = sq(c, 16, 20, 7, 9.5, 4)
    M(c, b, b > 1, SAUCE, spec_amt=.85, spec_pow=12, grain=.06)
    n = sq(c, 16, 9, 3.4, 3, 4)
    M(c, n, n > 1, SAUCE, spec_amt=.85, spec_pow=12, grain=.06)
    cap = sq(c, 16, 5, 3.6, 2.4, 4)
    M(c, cap, cap > 1, CAP, spec_amt=.5, grain=.08)
    lab = sq(c, 16, 21, 6.8, 4.2, 4)
    M(c, lab, lab > 1, PAPER, spec_amt=.2, grain=.08)
    B(c, [(16, 21, 2.2, 3), (16, 17.6, .8, 1)], RED, spec_amt=.5)


@food('spicy', 'kid', 'Spicy Taco')
def taco(c):
    # the filling peeks out over the shell's top edge, the shell is a half-moon seen from the side
    for (x, y, r, pal) in [(7.5, 13, 3.4, VEG), (12, 11, 3.4, MEAT), (16.5, 10.5, 3.4, RED), (21, 11, 3.4, CHEESE), (25, 13, 3.2, VEG), (14.5, 13.5, 3, CHEESE), (19.5, 13.5, 3, MEAT)]:
        B(c, [(x, y, r, r * .85)], pal, spec_amt=.3, grain=.14)
    shell = field(c, [(16, 14, 14.5, 14)])
    m = (shell > 1) & (c.y > 13.5)
    material(c, np.clip(height(shell, .5), 0, 1), m, TORT, bump=4, spec_amt=.3, grain=.16)
    seam(c, m, (c.a > .5) & ~m, .45, OUTA)
    B(c, [(26.5, 6.5, 1.6, 3.6), (27.2, 2.8, .8, 1.2)], RED, spec_amt=.6)


@food('spicy', 'adult', 'Tteokbokki')
def tteokbokki(c):
    B(c, [(16, 20, 15, 9)], PLATE, spec_amt=.5, grain=.05)
    sa = field(c, [(16, 19, 12.5, 7)])
    M(c, sa, sa > 1, SAUCE, spec_amt=.7, spec_pow=12, grain=.08)
    for (x, y, a) in [(10, 17, .5), (16, 15.5, -.4), (21.5, 18, .3), (13, 21.5, -.2), (19.5, 22, .6)]:
        f = sq(c, x, y, 3.8, 1.8, 3)
        M(c, f, f > 1, TTEOK, spec_amt=.5, grain=.08)
        material(c, np.clip(height(f, .5), 0, 1), (f > 1) & (c.y > y), SAUCE, bump=3, spec_amt=.7, grain=.06)
    B(c, [(23.5, 13, 3, 2.6)], EGG, spec_amt=.5, grain=.06)
    B(c, [(23.5, 13, 1.4, 1.2)], YOLK, spec_amt=.6)
    dots(c, 7, (6, 13, 26, 24, lambda x, y: c.alpha_at(x, y) > .5), [(110, 170, 70)], r=.7, seed=3, angle=True)


# ------------------------------------------------------------------ SOUR
@food('sour', 'baby', 'Lime')
def lime(c):
    B(c, [(12, 18, 10, 9.5)], LIME, spec_amt=.6, grain=.1)
    rind = field(c, [(20, 15.5, 9.6, 9.6)])
    M(c, rind, rind > 1, LIME, spec_amt=.5, grain=.08)
    pulp = field(c, [(20, 15.5, 8, 8)])
    M(c, pulp, pulp > 1, LIMEPULP, spec_amt=.4, grain=.1)
    draw(c, lambda d: [d.line([c.P(20, 15.5), c.P(20 + math.cos(k * math.pi / 4) * 7.4, 15.5 + math.sin(k * math.pi / 4) * 7.4)], fill=(236, 248, 210), width=int(.55 * c.k * c.z)) for k in range(8)])


@food('sour', 'kid', 'Kiwi')
def kiwi(c):
    B(c, [(16, 16, 13.5, 12.5)], KIWISKIN, spec_amt=.2, grain=.2)
    fl = field(c, [(16, 16, 11.6, 10.6)])
    M(c, fl, fl > 1, KIWIFLESH, spec_amt=.45, grain=.1)
    B(c, [(16, 16, 4, 3.4)], [(200, 210, 170), (226, 234, 200), (240, 246, 222), (250, 252, 240), (255, 255, 252)], spec_amt=.3, grain=.06)
    draw(c, lambda d: [d.ellipse([*c.P(16 + math.cos(k * math.pi / 7) * 6 - .5, 16 + math.sin(k * math.pi / 7) * 5.4 - .7),
                                  *c.P(16 + math.cos(k * math.pi / 7) * 6 + .5, 16 + math.sin(k * math.pi / 7) * 5.4 + .7)], fill=(30, 26, 20)) for k in range(14)])


@food('sour', 'adult', 'Ceviche')
def ceviche(c):
    g = field(c, [(16, 19, 13, 10)])
    M(c, g, (g > 1) & (c.y > 14), GLASS, spec_amt=.9, spec_pow=26, grain=.02, ao=.1)
    top = field(c, [(16, 14.5, 12.5, 4.6)])
    M(c, top, top > 1, LIMEPULP, spec_amt=.5, grain=.08)
    for (x, y) in [(10, 13.5), (15, 12.5), (20, 13.2), (12.5, 16), (18, 16), (23, 15)]:
        f = sq(c, x, y, 2, 1.8, 4)
        M(c, f, f > 1, FISH, spec_amt=.4, grain=.08)
    for (x, y) in [(13.5, 14.5), (21.5, 12)]:
        B(c, [(x, y, 1.6, 1)], ONION, spec_amt=.4)
    dots(c, 6, (6, 10, 26, 18, lambda x, y: c.alpha_at(x, y) > .5), [(70, 140, 50)], r=.6, seed=6, angle=True)
    w = ell(c, 25, 8.5, 4, 3) & (c.y < 9.8)
    material(c, np.clip(height(field(c, [(25, 8.5, 4, 3)]), .5), 0, 1), w, LIME, bump=4, spec_amt=.5, grain=.08)


ORDER = ['edamame', 'avocadotoast', 'bento', 'candy', 'icecream', 'pancakes', 'nugget', 'pizzaslice', 'fishchips',
         'hotsauce', 'taco', 'tteokbokki', 'lime', 'kiwi', 'ceviche']

if __name__ == '__main__':
    os.makedirs(os.path.join(HERE, 'icons3'), exist_ok=True)
    ims = []
    for name in ORDER:
        im = fd.render(name)
        im.save(os.path.join(HERE, 'icons3', name + '.png'))
        ims.append((name, im))
        print(name, im.getbbox(), flush=True)
    font = ImageFont.truetype(fd.PROJ + '/fonts/Pixellari.ttf', 16)
    S = 4; CW = 170
    sh = Image.new('RGBA', (CW * 3 + 160, 40 + 5 * 190), (244, 240, 230, 255))
    d = ImageDraw.Draw(sh)
    for j, t in enumerate(['SHO (1)', 'CHU (2)', 'DAI (3)']):
        d.text((160 + j * CW + 40, 10), t, fill=(90, 80, 70), font=font)
    for i, fam in enumerate(['green', 'sweet', 'greasy', 'spicy', 'sour']):
        d.text((20, 40 + i * 190 + 70), fam.upper(), fill=(60, 50, 50), font=font)
        for j in range(3):
            name, im = ims[i * 3 + j]
            x, y = 160 + j * CW, 40 + i * 190
            sh.alpha_composite(im.resize((32 * S, 32 * S), Image.NEAREST), (x + (CW - 32 * S) // 2, y + 10))
            n = NEW[name]['name']
            d.text((x + (CW - d.textlength(n, font=font)) / 2, y + 32 * S + 18), n, fill=(60, 50, 50), font=font)
    sh.save(os.path.join(HERE, 'foods3_sheet.png'))
    print('sheet ok')
