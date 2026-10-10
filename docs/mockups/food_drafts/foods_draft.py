"""Food drafts (32x32) in the look of the 8 original foods: warm muted colours, chunky painted
texture, dark warm outline, filling the box and centred. Uses tools/art/food_new.py's fitting.
Brainstorm only: writes to the scratchpad, never to textures/."""
import sys, os, math
sys.path.insert(0, '/Users/xaviergrau/Documents/PoopPal Godot/poop-pal-main-kiro/tools/art')
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from hires import field, height, material, outline, shrink, to_image, dots, paint
import food_new as fn
from food_new import fitted

PROJ = '/Users/xaviergrau/Documents/PoopPal Godot/poop-pal-main-kiro'
OUTD = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'out', 'foods')
os.makedirs(OUTD, exist_ok=True)

# warm, slightly muted ramps (dark -> light), sampled by eye from the originals
BREAD = [(92, 52, 30), (150, 94, 50), (196, 136, 72), (226, 176, 104), (246, 214, 150)]
WOOD = [(70, 40, 24), (120, 74, 42), (168, 112, 64), (204, 150, 92), (232, 192, 132)]
PLATE = [(130, 130, 128), (186, 186, 182), (222, 222, 216), (242, 240, 234), (255, 255, 250)]
CHOC = [(40, 20, 16), (74, 40, 26), (112, 66, 40), (150, 98, 62), (194, 142, 100)]
SPONGE = [(58, 30, 22), (96, 56, 36), (134, 86, 56), (170, 120, 82), (206, 162, 120)]
CREAM = [(170, 150, 126), (216, 200, 176), (238, 228, 210), (250, 244, 232), (255, 252, 246)]
BLUE = [(34, 44, 70), (60, 78, 112), (96, 122, 160), (130, 158, 194), (176, 200, 228)]
VEG = [(30, 58, 26), (54, 100, 38), (92, 146, 54), (136, 184, 78), (186, 218, 122)]
PALEVEG = [(80, 110, 50), (124, 160, 76), (164, 196, 104), (198, 222, 140), (230, 242, 190)]
RED = [(74, 16, 16), (136, 30, 26), (190, 56, 38), (222, 96, 62), (244, 150, 112)]
JALA = [(26, 52, 24), (44, 90, 36), (72, 134, 50), (112, 172, 72), (166, 210, 116)]
GLAZE = [(78, 26, 12), (138, 54, 22), (186, 92, 38), (220, 136, 64), (244, 188, 116)]
TORT = [(130, 84, 24), (196, 140, 46), (230, 186, 80), (246, 218, 128), (255, 242, 190)]
MEAT = [(54, 28, 20), (92, 52, 32), (130, 80, 50), (164, 112, 74), (200, 152, 108)]
RICE = [(170, 166, 154), (210, 206, 194), (236, 232, 222), (248, 246, 238), (255, 255, 250)]
CURRY = [(110, 56, 14), (170, 98, 24), (212, 142, 44), (236, 184, 84), (252, 222, 140)]
BROTH = [(110, 30, 14), (170, 62, 26), (214, 104, 44), (238, 150, 76), (252, 200, 130)]
NOODLE = [(170, 130, 70), (214, 178, 108), (238, 210, 146), (250, 232, 180), (255, 248, 220)]
LEMON = [(140, 104, 16), (204, 164, 32), (238, 206, 64), (250, 230, 116), (255, 248, 196)]
PICKLE = [(34, 52, 18), (66, 94, 30), (108, 138, 50), (150, 174, 76), (196, 210, 120)]
CABBAGE = [(96, 20, 16), (160, 40, 28), (206, 78, 46), (232, 124, 84), (248, 182, 146)]
PASTRY = [(110, 64, 26), (170, 110, 50), (212, 156, 80), (236, 196, 120), (250, 228, 170)]
EGG = [(176, 168, 152), (220, 214, 200), (242, 238, 228), (252, 250, 244), (255, 255, 255)]
YOLK = [(176, 92, 10), (226, 140, 20), (250, 184, 40), (255, 214, 90), (255, 240, 170)]
FRY = [(160, 104, 20), (214, 158, 40), (240, 200, 76), (252, 226, 126), (255, 246, 190)]
BOX = [(90, 18, 18), (150, 34, 30), (198, 58, 44), (226, 98, 76), (246, 158, 132)]
GLASS = [(130, 150, 164), (176, 198, 210), (212, 228, 236), (236, 246, 250), (255, 255, 255)]
CHERRY = [(70, 8, 20), (140, 20, 34), (200, 40, 50), (236, 100, 100), (255, 200, 200)]
SHRIMP = [(130, 40, 26), (200, 80, 50), (236, 128, 88), (250, 170, 130), (255, 214, 186)]
BOWLRED = [(60, 14, 14), (110, 26, 24), (156, 44, 36), (190, 74, 58), (220, 120, 100)]
BOWLW = [(120, 126, 130), (176, 184, 188), (214, 220, 222), (238, 242, 242), (255, 255, 255)]
LIME = [(30, 70, 20), (60, 120, 30), (100, 170, 50), (150, 206, 84), (206, 236, 150)]
OUTC = (52, 30, 26)

G = dict(grain=.16, ao=.4)        # chunkier grain than the newer icons


def B(c, balls, pal, **kw):
    return fn.blob(c, balls, pal, **{**G, **kw})


def sq(c, cx, cy, rx, ry, p=6):
    return 1 / np.maximum((np.abs((c.x - cx) / rx) ** p + np.abs((c.y - cy) / ry) ** p) ** (2 / p), 1e-4)


def M(c, f, mask, pal, sharp=.5, **kw):
    material(c, np.clip(height(f, sharp), 0, 1.2), mask, pal, **{**dict(bump=5, spec_amt=.35, grain=.16, ao=.4), **kw})


def L(c, lines, col, w):
    fn.draw_lines(c, lines, col, w)


def ell(c, x, y, rx, ry):
    return ((c.x - x) / rx) ** 2 + ((c.y - y) / ry) ** 2 < 1


def draw(c, f):
    im = to_image(c); d = ImageDraw.Draw(im, 'RGBA'); f(d)
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


FOODS = {}


def food(fam, stage, name):
    def deco(f):
        FOODS[f.__name__] = dict(fam=fam, stage=stage, name=name, fn=f)
        return f
    return deco


# ------------------------------------------------------------------ GREEN
@food('green', 'baby', 'Broccoli')
def broccoli(c):
    B(c, [(16, 25, 3.4, 5.5), (14, 20, 2.2, 3), (18.5, 20, 2.2, 3)], PALEVEG, spec_amt=.2)
    rr = np.random.default_rng(3)
    for (x, y, r) in [(16, 10, 6), (9.5, 14, 5), (22.5, 14, 5), (12, 8.5, 4.2), (20.5, 8.5, 4.2), (16, 15, 5)]:
        f = field(c, [(x, y, r, r * .92)])
        micro = [(x + rr.uniform(-.7, .7) * r, y + rr.uniform(-.7, .6) * r, 1.8, 1.8, .4) for _ in range(9)]
        h = np.clip(height(f, .5) * .7 + height(field(c, micro), .6) * .5, 0, 1.3)
        material(c, h, f > 1, VEG, bump=7, spec_amt=.15, grain=.22, ao=.55)


@food('green', 'baby', 'Pea Pod')
def peapod(c):
    pod = [(6 + i * 2.6, 25 - i * 2.4, 4.6 - abs(i - 3.5) * .45, 4.2 - abs(i - 3.5) * .4) for i in range(8)]
    B(c, pod, [(30, 64, 24), (52, 104, 36), (84, 140, 50), (120, 170, 70), (170, 206, 110)], spec_amt=.3)
    for i in range(4):
        x, y = 8.8 + i * 4.3, 21.6 - i * 3.9
        B(c, [(x, y, 3.3, 3.3)], [(70, 120, 30), (110, 170, 50), (150, 210, 80), (196, 236, 120), (240, 252, 200)], spec_amt=.8, spec_pow=14, grain=.05)
    lip = np.zeros_like(c.x, bool)
    for i in range(8):
        lip |= ell(c, 7.5 + i * 2.6, 28 - i * 2.4, 3.0, 1.5)
    f = field(c, [(7.5 + i * 2.6, 28 - i * 2.4, 3.0, 1.5) for i in range(8)])
    M(c, f, lip & (c.a > .5), [(30, 64, 24), (52, 104, 36), (84, 140, 50), (120, 170, 70), (170, 206, 110)], spec_amt=.2)
    L(c, [[(27, 6), (28.5, 3.5), (27, 2)]], (70, 110, 40), 1.4)


@food('green', 'adult', 'Spring Rolls')
def springrolls(c):
    B(c, [(16, 23, 14.5, 6.5)], PLATE, spec_amt=.5, grain=.06)
    for (cx, cy) in [(12.5, 13.5), (19.5, 19.5)]:
        f = sq(c, cx, cy, 10, 4.6, 3)
        M(c, f, f > 1, CREAM, spec_amt=.55)
        draw(c, lambda d: [d.ellipse([*c.P(cx - 8 + i * 3.6 - 1.3, cy - 1.6), *c.P(cx - 8 + i * 3.6 + 1.3, cy + 1.6)], fill=[(110, 170, 80, 170), (236, 140, 70, 170), (220, 120, 140, 150)][i % 3]) for i in range(5)])
        f2 = field(c, [(cx + 10, cy, 1.8, 4)])
        M(c, f2, f2 > 1, VEG)
    B(c, [(24.5, 11, 3.8, 2.6)], RED, spec_amt=.7, grain=.06)


# ------------------------------------------------------------------ SWEET (chocolate first)
@food('sweet', 'baby', 'Chocolate Bar')
def chocobar(c):
    f = sq(c, 16, 15, 9, 11, 8)
    M(c, f, f > 1, CHOC, spec_amt=.25, grain=.1)
    draw(c, lambda d: ([d.line([c.P(7.5, 7 + i * 5.2), c.P(24.5, 7 + i * 5.2)], fill=(34, 16, 12), width=int(.8 * c.k * c.z)) for i in range(1, 4)]
                       + [d.line([c.P(16, 4.5), c.P(16, 25)], fill=(34, 16, 12), width=int(.8 * c.k * c.z))]))
    wrap = (f > 1) & (c.y > 19)
    material(c, np.clip(height(f, .5), 0, 1), wrap, BLUE, bump=4, spec_amt=.4, grain=.1)
    foil = (f > 1) & (c.y > 18.2) & (c.y < 19.6 + .6 * np.sin(c.x * 2.4))
    material(c, np.clip(height(f, .5), 0, 1), foil, PLATE, bump=3, spec_amt=.8, grain=.05)


@food('sweet', 'baby', 'Truffle')
def truffle(c):
    cup = (c.y > 19) & (sq(c, 16, 23, 11.5, 6, 3) > 1)
    material(c, np.clip(height(sq(c, 16, 23, 11.5, 6, 3), .5), 0, 1), cup, WOOD, bump=3, spec_amt=.2, grain=.1)
    draw(c, lambda d: [d.line([c.P(6 + i * 2.5, 20), c.P(7 + i * 2.2, 28)], fill=(90, 54, 32), width=int(.6 * c.k * c.z)) for i in range(9)])
    f = field(c, [(16, 15.5, 10, 9.5)])
    M(c, f, f > 1, CHOC, spec_amt=.2, grain=.3)
    L(c, [[(9, 12), (12, 10), (15, 12.5), (18, 9.5), (21, 12), (23, 10)]], (210, 170, 130), 1.0)


@food('sweet', 'kid', 'Choco Donut')
def chocodonut(c):
    outer = field(c, [(16, 17, 13.5, 12.5)])
    hole = ell(c, 16, 16, 4.4, 3.8)
    M(c, outer, (outer > 1) & ~hole, BREAD, spec_amt=.2)
    gl = ell(c, 16, 16.4, 12.2, 11) & ~ell(c, 16, 16, 5.6, 5.0) & (c.y < 22.5 + 1.6 * np.sin(c.x * 1.3))
    material(c, np.clip(height(outer, .5), 0, 1) * .8, gl, [(30, 14, 10), (56, 28, 18), (84, 46, 28), (116, 70, 44), (160, 110, 76)], bump=4, spec_amt=.6, spec_pow=16, grain=.06)
    rr = np.random.default_rng(4)
    def spr(d):
        for _ in range(16):
            a, r = rr.uniform(0, 2 * math.pi), rr.uniform(6.5, 10.5)
            x, y = 16 + math.cos(a) * r, 16.4 + math.sin(a) * r * .9
            if y > 21: continue
            t = rr.uniform(0, math.pi); dx, dy = math.cos(t) * 1.1, math.sin(t) * 1.1
            col = [(130, 158, 194), (250, 246, 236), (236, 150, 170)][rr.integers(3)]
            d.line([c.P(x - dx, y - dy), c.P(x + dx, y + dy)], fill=col, width=int(1.0 * c.k * c.z))
    draw(c, spr)


@food('sweet', 'adult', 'Choco Cake')
def chococake(c):
    body = sq(c, 16, 19.5, 12.5, 8.5, 6)
    M(c, body, body > 1, SPONGE, spec_amt=.15, grain=.2)
    for y0 in (16.5, 21.5):
        m = (body > 1) & (np.abs(c.y - y0) < .9)
        material(c, np.clip(height(body, .5), 0, 1), m, CREAM, bump=3, spec_amt=.3, grain=.08)
    top = (body > 1) & (c.y < 13.5 + 1.2 * np.exp(-((c.x - 9) / 1.2) ** 2) * 3 + 1.2 * np.exp(-((c.x - 20) / 1.3) ** 2) * 3)
    material(c, np.clip(height(body, .5), 0, 1), top, CHOC, bump=4, spec_amt=.7, spec_pow=16, grain=.08)
    B(c, [(16, 8.5, 5.5, 2.4), (12, 9.3, 2.4, 2), (20, 9.3, 2.4, 2)], CREAM, spec_amt=.3, grain=.08)
    B(c, [(16.5, 5.5, 3.2, 3)], CHERRY, spec_amt=.9, grain=.04)
    L(c, [[(17.5, 3), (19, 1.2), (21, .8)]], (80, 50, 30), .8)


@food('sweet', 'adult', 'Choco Parfait')
def parfait(c):
    cup = field(c, [(16, 17, 9, 11)]); cm = (cup > 1) & (c.y > 8)
    M(c, cup, cm, GLASS, spec_amt=.9, spec_pow=28, grain=.03, ao=.1)
    inner = (field(c, [(16, 17.5, 7.6, 9.5)]) > 1) & (c.y > 10)
    hh = np.clip(height(cup, .5), 0, 1)
    for (y0, y1, pal) in [(10, 14, CREAM), (14, 18, CHOC), (18, 21, CREAM), (21, 30, CHOC)]:
        material(c, hh, inner & (c.y >= y0 + .7 * np.sin(c.x)) & (c.y < y1 + .7 * np.sin(c.x)), pal, bump=3, spec_amt=.3, grain=.12)
    B(c, [(16, 9, 7.5, 2.6), (12.5, 7.5, 3, 2.4), (19.5, 7.5, 3, 2.4), (16, 6, 3.4, 2.6)], CREAM, spec_amt=.25, grain=.08)
    B(c, [(16, 3.6, 2.6, 2.4)], CHERRY, spec_amt=.9, grain=.04)
    f = sq(c, 22.5, 6, 1.1, 5, 4)
    M(c, f, f > 1, BREAD, spec_amt=.2)
    B(c, [(16, 29.2, 5, 1.4)], GLASS, spec_amt=.6, grain=.03)


# ------------------------------------------------------------------ GREASY
@food('greasy', 'baby', 'Fries')
def fries(c):
    rr = np.random.default_rng(2)
    for i, x in enumerate([9, 12, 15, 18, 21, 23.5, 10.5, 16.5, 20]):
        y = rr.uniform(6, 10)
        f = sq(c, x + rr.uniform(-.5, .5), y + 5, 1.4, 6.5, 6)
        M(c, f, f > 1, FRY, spec_amt=.3, grain=.12)
    pts = [(6, 14), (26, 14), (23.5, 29), (8.5, 29)]
    im = Image.new('L', (c.w * c.k, c.h * c.k)); ImageDraw.Draw(im).polygon([c.P(*p) for p in pts], fill=255)
    m = np.asarray(im) > 127
    hb = np.clip(1 - np.abs(c.x - 16) / 11, 0, 1) ** .5
    material(c, hb, m, BOX, bump=3, spec_amt=.3, grain=.12)
    draw(c, lambda d: d.ellipse([*c.P(13, 19), *c.P(19, 24)], fill=(246, 210, 90)))


@food('greasy', 'baby', 'Fried Egg')
def friedegg(c):
    f = field(c, [(14, 17, 10, 8), (20, 19, 8, 7), (11, 21, 6, 5), (19, 12, 6, 5)])
    h = height(f, .5)
    M(c, f, f > 1, EGG, spec_amt=.5, grain=.08)
    edge = (f > 1) & (h < .3)
    material(c, h, edge, PASTRY, bump=4, spec_amt=.3, grain=.25)
    B(c, [(16, 15.5, 5.6, 5)], YOLK, spec_amt=.95, spec_pow=18, grain=.05)


# ------------------------------------------------------------------ SPICY
@food('spicy', 'baby', 'Chili Pepper')
def chili(c):
    B(c, [(9 + i * 2.1, 10 + i * 2 + (i * i) * .1, 4.6 - i * .38, 4.2 - i * .33) for i in range(9)], RED, spec_amt=.8, spec_pow=18, grain=.1)
    B(c, [(8.5, 8.5, 3.4, 2.2)], JALA, spec_amt=.3)
    L(c, [[(8, 8), (6.5, 4.5), (8.5, 2.5)]], (60, 100, 36), 1.8)


@food('spicy', 'baby', 'Jalapeño')
def jalapeno(c):
    B(c, [(7 + i * 2.0, 8 + i * 1.5, 4.4 - i * .25, 4.2 - i * .22) for i in range(7)], JALA, spec_amt=.7, spec_pow=18, grain=.1)
    L(c, [[(6, 6), (4.5, 3), (6.5, 1.5)]], (70, 90, 40), 1.8)
    r = ell(c, 23, 25, 6.5, 5.6)
    material(c, np.clip(height(field(c, [(23, 25, 6.5, 5.6)]), .5), 0, 1), r, JALA, bump=4, spec_amt=.5, grain=.1)
    inner = ell(c, 23, 25, 5, 4.2)
    material(c, np.ones_like(c.x) * .7, inner, PALEVEG, bump=0, spec_amt=.1, grain=.12)
    dots(c, 6, (20, 22.5, 26, 27.5, lambda x, y: True), [(250, 244, 210)], r=.55, seed=3, angle=False)


@food('spicy', 'kid', 'Hot Wings')
def hotwings(c):
    B(c, [(16, 23, 14.5, 6.5)], PLATE, spec_amt=.5, grain=.06)
    for (x, y, bx, by) in [(10, 17, 7, 10), (21, 15, 25, 9), (16, 21, 17, 26)]:
        L(c, [[(x, y), ((x + bx) / 2, (y + by) / 2), (bx, by)]], (236, 226, 204), 2.4)
        B(c, [(x, y, 5.6, 4.6), (x + (bx - x) * .25, y + (by - y) * .25, 4, 3.4)], GLAZE, spec_amt=.75, spec_pow=16, grain=.12)
    dots(c, 14, (4, 10, 28, 26, lambda x, y: True), [(246, 236, 210), (120, 20, 16)], r=.45, seed=4)


@food('spicy', 'kid', 'Fire Skewer')
def skewer(c):
    L(c, [[(3, 30), (29, 3)]], (176, 130, 80), 1.6)
    for k, pal in enumerate([MEAT, RED, MEAT, JALA]):
        x, y = 9 + k * 5, 23 - k * 5
        B(c, [(x, y, 5.2, 4.6), (x + 1.5, y + 1.2, 4, 3.6)], pal, bump=6, spec_amt=.7, spec_pow=16, grain=.16)
    dots(c, 10, (5, 5, 27, 28, lambda x, y: c.alpha_at(x, y) > .5), [(200, 30, 20), (246, 236, 210)], r=.5, seed=8)


@food('spicy', 'adult', 'Curry Rice')
def curryrice(c):
    B(c, [(16, 21, 15, 8.5)], PLATE, spec_amt=.5, grain=.06)
    B(c, [(10.5, 16.5, 8, 6.5), (9, 13.5, 5, 4)], RICE, spec_amt=.15, grain=.35, bump=7)
    dots(c, 18, (4, 10, 17, 22, lambda x, y: c.alpha_at(x, y) > .5), [(255, 255, 250), (196, 190, 176)], r=.5, seed=2)
    f = field(c, [(20.5, 21, 9, 5.2), (16, 23, 6, 3.6)])
    M(c, f, f > 1, [(80, 36, 10), (130, 70, 20), (172, 106, 34), (206, 146, 60), (236, 190, 110)], spec_amt=.6, spec_pow=18, grain=.08)
    for (x, y, r, pal) in [(19, 20, 2, MEAT), (23, 21.5, 1.8, YOLK), (21, 23.5, 1.5, BOX), (25, 19, 1.4, MEAT)]:
        B(c, [(x, y, r, r * .85)], pal, spec_amt=.3, grain=.12)
    B(c, [(8, 22, 2.2, 1.4)], CHERRY, spec_amt=.4)


@food('spicy', 'adult', 'Fire Ramen')
def ramen(c):
    bowl = field(c, [(16, 19, 14.5, 10.5)])
    M(c, bowl, (bowl > 1) & (c.y > 16), BOWLRED, spec_amt=.6, grain=.08)
    br = field(c, [(16, 16.5, 13.5, 4.8)])
    M(c, br, br > 1, BROTH, spec_amt=.55, grain=.1)
    L(c, [[(5 + i * 2.5, 15 + (i % 2)), (7 + i * 2.5, 18.5 - (i % 2))] for i in range(8)], (246, 222, 160), .9)
    B(c, [(20.5, 15, 3.6, 3)], EGG, spec_amt=.4, grain=.06)
    B(c, [(20.5, 15.2, 1.8, 1.6)], YOLK, spec_amt=.6, grain=.06)
    B(c, [(10, 14.5, 2.4, 1.6), (13, 13.5, 1.6, 1.2)], VEG, spec_amt=.2)
    L(c, [[(6, 3), (26, 14)], [(9, 2), (28, 11.5)]], (140, 94, 52), 1.3)
    dots(c, 6, (6, 14, 26, 19, lambda x, y: True), [(150, 20, 14)], r=.6, seed=5, angle=False)


# ------------------------------------------------------------------ SOUR
@food('sour', 'baby', 'Lemon')
def lemon(c):
    ang = math.radians(35)
    u = (c.x - 15) * math.cos(ang) - (c.y - 17) * math.sin(ang)
    v = (c.x - 15) * math.sin(ang) + (c.y - 17) * math.cos(ang)
    f = 1 / np.maximum((u / 11) ** 2 + (v / 8.4) ** 2, 1e-4)
    for sd in (-1, 1):
        f = np.maximum(f, 1 / np.maximum(((u - sd * 11.6) / 2.4) ** 2 + (v / 2.0) ** 2, 1e-4))
    M(c, f, f > 1, LEMON, spec_amt=.55, grain=.14)
    tip = (15 + 12.6 * math.cos(ang), 17 - 12.6 * math.sin(ang))
    B(c, [(tip[0] - 2.8, tip[1] - 2.2, 4, 2), (tip[0] - 5, tip[1] - 3, 2, 1.4)], VEG, spec_amt=.3)


@food('sour', 'baby', 'Pickle')
def pickle(c):
    B(c, [(7 + i * 2.3, 25 - i * 2.4 - math.sin(i / 7 * math.pi) * 1.2, 5.0, 5.0) for i in range(8)], PICKLE, spec_amt=.35, grain=.12)
    rr = np.random.default_rng(5)
    warts = [(rr.uniform(5, 26), rr.uniform(6, 27), .9, .9, .3) for _ in range(30)]
    wf = field(c, warts)
    m = (c.a > .5) & (wf > 1)
    material(c, np.ones_like(c.x) * .8, m, PICKLE, bump=0, spec_amt=.3, grain=.05)


@food('sour', 'kid', 'Kimchi')
def kimchi(c):
    bowl = field(c, [(16, 21, 14, 8)])
    M(c, bowl, (bowl > 1) & (c.y > 17), BOWLW, spec_amt=.5, grain=.06)
    draw(c, lambda d: d.line([c.P(3.5, 23), c.P(28.5, 23)], fill=(80, 110, 160), width=int(.9 * c.k * c.z)))
    for (x, y, rx, ry) in [(9, 15, 5, 3.2), (16, 12.5, 5.5, 3.6), (22.5, 15, 5, 3.2), (12.5, 17.5, 5, 2.8), (19.5, 17.5, 5, 2.8), (16, 9, 3.6, 2.4)]:
        B(c, [(x, y, rx, ry)], CABBAGE, bump=7, spec_amt=.5, grain=.2)
    dots(c, 10, (6, 8, 26, 19, lambda x, y: True), [(250, 236, 214), (110, 160, 60)], r=.55, seed=6)


@food('sour', 'kid', 'Lemon Tart')
def lemontart(c):
    cr = field(c, [(16, 19, 14.5, 9)])
    edge = 1 + .1 * np.sin(np.arctan2(c.y - 19, c.x - 16) * 14)
    M(c, cr * edge, cr * edge > 1, [(84, 44, 18), (140, 84, 36), (186, 124, 60), (218, 164, 96), (240, 204, 144)], spec_amt=.25, grain=.18)
    cu = field(c, [(16, 17.6, 10, 5.2)])
    M(c, cu, cu > 1, [(200, 150, 10), (240, 196, 30), (255, 224, 70), (255, 240, 130), (255, 252, 210)], spec_amt=.8, spec_pow=18, grain=.05)
    sl = ell(c, 18, 15, 4.4, 3)
    material(c, np.ones_like(c.x) * .8, sl, LEMON, bump=0, spec_amt=.1, grain=.08)
    draw(c, lambda d: ([d.line([c.P(18, 15), c.P(18 + math.cos(k * math.pi / 3) * 3.6, 15 + math.sin(k * math.pi / 3) * 2.4)], fill=(255, 250, 220), width=int(.5 * c.k * c.z)) for k in range(6)]
                       + [d.ellipse([*c.P(13.6, 14), *c.P(22.4, 16.2)], outline=(226, 176, 30), width=int(.6 * c.k * c.z))]))
    B(c, [(12, 13.5, 2.8, 1.5)], VEG, spec_amt=.3)


@food('sour', 'adult', 'Lemon Meringue')
def meringue(c):
    cr = field(c, [(16, 23.5, 14.5, 5.5)])
    M(c, cr, cr > 1, PASTRY, spec_amt=.25, grain=.18)
    cu = sq(c, 16, 20.5, 12.5, 3, 4)
    M(c, cu, cu > 1, LEMON, spec_amt=.6, grain=.06)
    pk = [(8, 15, 4, 3.6), (14, 13.5, 4.4, 4), (20, 13, 4.4, 4), (25, 15.5, 3.6, 3.2), (11, 10, 3, 3), (17, 8.5, 3.4, 3.4), (22, 10, 3, 3), (17, 5, 1.6, 2.4)]
    f = field(c, pk)
    h = height(f, .5)
    M(c, f, f > 1, CREAM, spec_amt=.3, grain=.12)
    toast = (f > 1) & (c.y < 12) & (h > .5)
    material(c, h, toast, PASTRY, bump=4, spec_amt=.2, grain=.2)


@food('sour', 'adult', 'Tom Yum')
def tomyum(c):
    bowl = field(c, [(16, 19, 14.5, 10.5)])
    M(c, bowl, (bowl > 1) & (c.y > 16), BOWLW, spec_amt=.5, grain=.06)
    draw(c, lambda d: [d.arc([*c.P(2, 16 + i * 2.6), *c.P(30, 28 + i * 2.6)], 20, 160, fill=(70, 120, 120), width=int(.7 * c.k * c.z)) for i in range(1)])
    br = field(c, [(16, 16.5, 13.5, 4.8)])
    M(c, br, br > 1, BROTH, spec_amt=.55, grain=.1)
    for (x, y) in [(11, 15.5), (18, 14.5)]:
        B(c, [(x + math.cos(t) * 2.4, y + math.sin(t) * 1.8, 1.6 - t * .1, 1.5 - t * .1) for t in np.linspace(0, 4, 6)], SHRIMP, spec_amt=.5, grain=.08)
    w = ell(c, 24, 13, 4, 3) & (c.y < 14.5)
    material(c, np.clip(height(field(c, [(24, 13, 4, 3)]), .5), 0, 1), w, LIME, bump=4, spec_amt=.5, grain=.08)
    B(c, [(14, 18.5, 1.6, 1), (21, 18, 1.4, .9)], VEG, spec_amt=.2)
    dots(c, 5, (7, 14, 25, 19, lambda x, y: True), [(200, 30, 20)], r=.6, seed=9, angle=False)


ORIGINALS = {   # kept as they are (textures/food/)
    'cucumbersushi': ('green', 'adult', 'Cucumber Sushi'), 'saladbowl': ('green', 'kid', 'Salad Bowl'),
    'brownricevegs': ('green', 'kid', 'Rice and Vegs'), 'rainbowjelly': ('sweet', 'kid', 'Rainbow Jelly'),
    'hotdog': ('greasy', 'kid', 'Hot Dog'), 'spaghetthi': ('greasy', 'kid', 'Spaghetti'),
    'cheeseburger': ('greasy', 'adult', 'Cheeseburger'), 'clubsandwich': ('greasy', 'adult', 'Club Sandwich'),
}


def centred(im):
    """move the drawing so its box is centred in the 32x32 (the menu ring centres the icon)"""
    bb = im.getbbox()
    out = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    w, h = bb[2] - bb[0], bb[3] - bb[1]
    out.alpha_composite(im.crop(bb), ((32 - w) // 2, (32 - h) // 2))
    return out


def chunky(im, n=22):
    """fewer colours, like the originals' chunky clusters"""
    a = im.getchannel('A')
    q = im.convert('RGB').quantize(n, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert('RGBA')
    q.putalpha(a)
    return q


def render(name):
    fnc = FOODS[name]['fn']
    c = fitted(fnc, name)
    outline(c, c.a > .5, 1.0, col=np.array(OUTC, np.float32))
    _, small = shrink(c)
    return centred(chunky(small))


if __name__ == '__main__':
    out = {}
    for name in FOODS:
        im = render(name)
        im.save(os.path.join(OUTD, name + '.png'))
        out[name] = im
        print(name, im.getbbox(), flush=True)
