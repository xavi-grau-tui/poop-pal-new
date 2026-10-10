"""Drink drafts (32x32) in the look of the 4 original drinks (water, cola, energy drink, orange juice):
simple bottle / can / glass shapes, cylinder shading, muted colours, thick dark olive-brown outline,
nearly full height. Brainstorm only: writes to the scratchpad."""
import sys, os, math
sys.path.insert(0, '/Users/xaviergrau/Documents/PoopPal Godot/poop-pal-main-kiro/tools/art')
import numpy as np
from PIL import Image, ImageDraw
from hires import field, height, material, outline, shrink, to_image, dots, seam
import food_new as fn
from food_new import fitted
import foods_draft as fd

PROJ = fd.PROJ
OUTD = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'out', 'drinks')
os.makedirs(OUTD, exist_ok=True)
OUTC = np.array((52, 42, 30), np.float32)

GLASSP = [(140, 150, 150), (180, 188, 186), (210, 216, 212), (230, 234, 230), (248, 250, 246)]
AMBER = [(100, 52, 14), (150, 86, 26), (190, 124, 48), (214, 160, 80), (236, 198, 130)]
COCO = [(54, 30, 18), (90, 54, 32), (126, 82, 50), (160, 112, 72), (196, 150, 104)]
WHITE = [(170, 168, 160), (206, 204, 196), (230, 228, 220), (244, 242, 236), (254, 252, 248)]
PINKP = [(150, 50, 80), (200, 90, 120), (230, 136, 160), (244, 178, 196), (252, 216, 226)]
LEMONP = [(170, 140, 40), (214, 188, 70), (238, 218, 110), (248, 236, 160), (255, 250, 210)]
AQUA = [(60, 120, 130), (96, 160, 170), (136, 196, 204), (180, 222, 228), (222, 244, 246)]
TEAG = [(60, 90, 30), (96, 130, 44), (132, 166, 64), (168, 196, 96), (206, 224, 150)]
CERAM = [(150, 140, 116), (196, 186, 160), (224, 216, 194), (240, 234, 218), (252, 250, 240)]
COFFEE = [(36, 20, 14), (62, 36, 22), (92, 58, 36), (124, 84, 56), (164, 122, 88)]
BLUEP = [(50, 76, 120), (78, 110, 160), (112, 146, 196), (150, 180, 220), (196, 216, 240)]
PEACH = [(170, 80, 60), (220, 124, 96), (240, 162, 130), (250, 196, 166), (255, 228, 206)]
BERRY = [(90, 20, 50), (140, 40, 80), (186, 70, 110), (216, 110, 146), (240, 166, 190)]
RED = fd.RED
VEG = fd.VEG
CHERRY = fd.CHERRY
CREAM = fd.CREAM


def poly(c, pts):
    im = Image.new('L', (c.w * c.k, c.h * c.k)); ImageDraw.Draw(im).polygon([c.P(*p) for p in pts], fill=255)
    return np.asarray(im) > 127


def rrect(c, x0, y0, x1, y1, r):
    im = Image.new('L', (c.w * c.k, c.h * c.k))
    ImageDraw.Draw(im).rounded_rectangle([*c.P(x0, y0), *c.P(x1, y1)], radius=int(r * c.k * c.z), fill=255)
    return np.asarray(im) > 127


def cyl(c, mask, pal, cx, hw, spec=.35, grain=.1, bump=2, ao=.3):
    """the originals' soft cylinder shading: light from the left, flat top to bottom"""
    h = np.clip(1 - ((c.x - cx + hw * .25) / (hw * 1.15)) ** 2, 0, 1) ** .5
    material(c, h, mask, pal, bump=bump, spec_amt=spec, spec_pow=10, grain=grain, ao=ao)


def edge(c, mask):
    seam(c, mask, (c.a > .5) & ~mask, .75, OUTC)


def draw(c, f):
    fd.draw(c, f)


def W(c, v):
    return max(1, int(v * c.k * c.z))


DRINKS = {}


def drink(typ, lvl, name):
    def deco(f):
        DRINKS[f.__name__] = dict(type=typ, lvl=lvl, name=name, fn=f)
        return f
    return deco


ORIGINALS = {'water': ('watery', 1, 'Water'), 'soda': ('fizzy', 1, 'Cola'),
             'energydrink': ('caffeinated', 3, 'Energy Drink'), 'orangejuice': ('fruity', 1, 'Orange Juice')}


# ------------------------------------------------------------------ WATERY
@drink('watery', 2, 'Barley Tea')
def barleytea(c):
    body = rrect(c, 8, 9, 24, 30, 2.2) | poly(c, [(10, 9.5), (22, 9.5), (19.5, 6), (12.5, 6)])
    cyl(c, body, GLASSP, 16, 8, spec=.5)
    liq = body & (c.y > 10.5) & (np.abs(c.x - 16) < 7)
    cyl(c, liq, AMBER, 16, 7, spec=.45)
    lab = body & (c.y > 15) & (c.y < 22)
    cyl(c, lab, [(110, 30, 20), (160, 50, 30), (196, 80, 46), (220, 120, 80), (240, 170, 130)], 16, 8)
    draw(c, lambda d: d.rectangle([*c.P(11, 17.4), *c.P(21, 19.6)], fill=(236, 220, 180)))
    cap = rrect(c, 12, 2, 20, 6.2, 1)
    cyl(c, cap, [(90, 30, 20), (140, 50, 30), (180, 80, 46), (210, 120, 80), (236, 170, 130)], 16, 4)
    edge(c, cap); edge(c, body)


@drink('watery', 3, 'Coconut Water')
def coconut(c):
    f = field(c, [(15, 20, 12, 10.5)])
    fd.M(c, f, f > 1, COCO, spec_amt=.25, grain=.28, bump=6)
    top = fd.ell(c, 15, 12.5, 8.5, 3.2)
    material(c, np.ones_like(c.x) * .8, top & (f > 1), WHITE, bump=0, spec_amt=.1, grain=.1)
    seam(c, top & (f > 1), (f > 1) & ~top, .5, OUTC)
    fd.L(c, [[(17, 12.5), (21, 3), (24.5, 1.5)]], (230, 110, 140), 1.6)


# ------------------------------------------------------------------ FIZZY
@drink('fizzy', 2, 'Lemonade')
def lemonade(c):
    gl = rrect(c, 5, 5, 23, 30, 1.2)
    cyl(c, gl, GLASSP, 14, 9, spec=.6)
    liq = rrect(c, 6.6, 9, 21.4, 28.4, .8)
    cyl(c, liq, LEMONP, 14, 7.5, spec=.4)
    dots(c, 9, (8, 11, 20, 27, lambda x, y: True), [(255, 255, 240)], r=.6, seed=3, angle=False)
    edge(c, gl)
    sl = fd.ell(c, 23, 7, 5, 5)
    material(c, np.ones_like(c.x) * .85, sl, LEMONP, bump=0, spec_amt=.1, grain=.08)
    draw(c, lambda d: [d.line([c.P(23, 7), c.P(23 + math.cos(k * math.pi / 3) * 4, 7 + math.sin(k * math.pi / 3) * 4)], fill=(255, 250, 220), width=W(c, .5)) for k in range(6)])
    edge(c, sl)


@drink('fizzy', 3, 'Ramune')
def ramune(c):
    body = rrect(c, 9, 15, 23, 30, 3) | poly(c, [(9.5, 16), (22.5, 16), (19, 11), (13, 11)])
    neck = rrect(c, 12.5, 4, 19.5, 12, 1.5) & ~(fd.ell(c, 10.5, 9.5, 1.6, 1.6) | fd.ell(c, 21.5, 9.5, 1.6, 1.6))
    m = body | neck
    cyl(c, m, AQUA, 16, 7, spec=.7)
    liq = body & (c.y > 17)
    cyl(c, liq, [(70, 130, 150), (110, 170, 190), (150, 206, 220), (196, 232, 240), (236, 250, 252)], 16, 6.5, spec=.5)
    dots(c, 8, (11, 18, 21, 28, lambda x, y: True), [(250, 255, 255)], r=.55, seed=6, angle=False)
    edge(c, m)
    fd.B(c, [(16, 9.5, 2.5, 2.5)], GLASSP, spec_amt=.9, spec_pow=18, grain=.03)
    cap = rrect(c, 12, 1.5, 20, 4.6, 1)
    cyl(c, cap, [(40, 70, 120), (70, 100, 160), (110, 140, 196), (150, 180, 220), (196, 216, 240)], 16, 4)
    edge(c, cap)


# ------------------------------------------------------------------ CAFFEINATED
@drink('caffeinated', 1, 'Green Tea')
def greentea(c):
    cup = poly(c, [(7, 8), (25, 8), (23.5, 29), (8.5, 29)])
    cyl(c, cup, [(60, 74, 70), (96, 112, 104), (136, 150, 140), (172, 184, 172), (210, 220, 208)], 16, 9, spec=.4)
    for y in (13, 24):
        band = cup & (np.abs(c.y - y) < .9)
        cyl(c, band, [(40, 50, 48), (64, 76, 72), (90, 104, 98), (120, 134, 126), (160, 172, 162)], 16, 9)
    edge(c, cup)
    top = fd.ell(c, 16, 8.4, 9, 2.4)
    material(c, np.ones_like(c.x) * .8, top, TEAG, bump=0, spec_amt=.3, grain=.06)
    edge(c, top)
    fd.L(c, [[(13, 5.6), (14, 4.2), (13, 3)], [(19, 5.6), (20, 4.2), (19, 3)]], (220, 224, 220), .8)


@drink('caffeinated', 2, 'Coffee')
def coffee(c):
    h = fd.ell(c, 24.5, 17.5, 5, 6) & ~fd.ell(c, 24.5, 17.5, 2.6, 3.4)
    cyl(c, h, CERAM, 24.5, 5)
    edge(c, h)
    mug = rrect(c, 4, 7, 24, 29, 2)
    cyl(c, mug, CERAM, 14, 10, spec=.45)
    edge(c, mug)
    top = fd.ell(c, 14, 7.6, 9.4, 2.3)
    material(c, np.ones_like(c.x) * .7, top, COFFEE, bump=0, spec_amt=.3, grain=.06)
    draw(c, lambda d: d.ellipse([*c.P(11.5, 6.8), *c.P(16.5, 8.6)], fill=(214, 176, 130)))
    edge(c, top)


# ------------------------------------------------------------------ MILKY
@drink('milky', 1, 'Milk')
def milk(c):
    front = poly(c, [(8, 11), (20, 11), (20, 30), (8, 30)])
    side = poly(c, [(20, 11), (25, 9), (25, 28), (20, 30)])
    gable = poly(c, [(8, 11), (20, 11), (17.5, 4), (10.5, 4)])
    gside = poly(c, [(20, 11), (25, 9), (21.5, 3), (17.5, 4)])
    material(c, np.ones_like(c.x) * .85, front, WHITE, bump=0, spec_amt=.1, grain=.08)
    material(c, np.ones_like(c.x) * .55, side, WHITE, bump=0, spec_amt=.05, grain=.08)
    material(c, np.ones_like(c.x) * .9, gable, WHITE, bump=0, spec_amt=.1, grain=.08)
    material(c, np.ones_like(c.x) * .6, gside, WHITE, bump=0, spec_amt=.05, grain=.08)
    band = (front | side) & (c.y > 17 - (c.x > 20) * (c.x - 20) * .4) & (c.y < 23 - (c.x > 20) * (c.x - 20) * .4)
    material(c, np.ones_like(c.x) * .75, band & front, BLUEP, bump=0, spec_amt=.1, grain=.08)
    material(c, np.ones_like(c.x) * .45, band & side, BLUEP, bump=0, spec_amt=.05, grain=.08)
    tab = poly(c, [(10, 4.2), (18, 4.2), (17.4, 2), (10.6, 2)])
    material(c, np.ones_like(c.x) * .8, tab, WHITE, bump=0, spec_amt=.1, grain=.08)
    for m in (front, side, gable, gside, tab):
        edge(c, m)


@drink('milky', 2, 'Yogurt Drink')
def yogurt(c):
    body = rrect(c, 8, 12, 24, 30, 4) | poly(c, [(9, 13), (23, 13), (20, 8), (12, 8)])
    cyl(c, body, WHITE, 16, 8, spec=.5)
    lab = body & (c.y > 16) & (c.y < 25)
    cyl(c, lab, BLUEP, 16, 8)
    draw(c, lambda d: [d.ellipse([*c.P(x - 1.3, y - 1.3), *c.P(x + 1.3, y + 1.3)], fill=(250, 250, 255)) for (x, y) in [(11, 18.5), (16, 17.8), (21, 18.5), (13.5, 22.5), (18.5, 22.5)]])
    cap = rrect(c, 11.5, 3, 20.5, 8.4, 1.2)
    cyl(c, cap, PINKP, 16, 4.5)
    edge(c, cap); edge(c, body)


@drink('milky', 3, 'Milkshake')
def milkshake(c):
    gl = poly(c, [(6, 10), (24, 10), (19, 29), (11, 29)])
    cyl(c, gl, GLASSP, 15, 9, spec=.6)
    liq = poly(c, [(7.6, 11.5), (22.4, 11.5), (18, 27.6), (12, 27.6)])
    cyl(c, liq, PINKP, 15, 7.4, spec=.4)
    edge(c, gl)
    fd.B(c, [(15, 9, 9.6, 3), (12, 7, 4, 3), (18, 6.6, 4, 3), (15, 4.6, 3.4, 2.6)], CREAM, spec_amt=.25, grain=.08)
    fd.B(c, [(16.5, 2.4, 2.4, 2.2)], CHERRY, spec_amt=.9, grain=.04)
    fd.L(c, [[(20, 7), (24, 1)]], (230, 110, 140), 1.6)


# ------------------------------------------------------------------ FRUITY
@drink('fruity', 2, 'Peach Juice')
def peachjuice(c):
    front = poly(c, [(7, 8), (21, 8), (21, 30), (7, 30)])
    side = poly(c, [(21, 8), (25, 6), (25, 28), (21, 30)])
    topf = poly(c, [(7, 8), (21, 8), (25, 6), (11, 6)])
    material(c, np.ones_like(c.x) * .85, front, PEACH, bump=0, spec_amt=.1, grain=.1)
    material(c, np.ones_like(c.x) * .5, side, PEACH, bump=0, spec_amt=.05, grain=.1)
    material(c, np.ones_like(c.x) * .95, topf, PEACH, bump=0, spec_amt=.1, grain=.1)
    for m in (front, side, topf):
        edge(c, m)
    fd.B(c, [(14, 20, 5, 4.8)], [(200, 80, 70), (236, 120, 100), (250, 160, 130), (255, 196, 170), (255, 226, 206)], spec_amt=.4, grain=.08)
    fd.B(c, [(16.5, 14.5, 2.6, 1.3)], VEG, spec_amt=.2)
    fd.L(c, [[(12, 7), (12, 2.5), (15, 1.2)]], (240, 240, 236), 1.4)


@drink('fruity', 3, 'Smoothie')
def smoothie(c):
    cup = poly(c, [(6, 11), (26, 11), (23.5, 30), (8.5, 30)])
    cyl(c, cup, GLASSP, 16, 10, spec=.6)
    liq = poly(c, [(7.6, 12.5), (24.4, 12.5), (22.2, 28.6), (9.8, 28.6)])
    cyl(c, liq, BERRY, 16, 8.4, spec=.4)
    edge(c, cup)
    lid = fd.ell(c, 16, 10.5, 11, 5.2) & (c.y < 11.5)
    cyl(c, lid, GLASSP, 16, 11, spec=.8)
    rim = rrect(c, 4.5, 10, 27.5, 12.4, 1)
    cyl(c, rim, GLASSP, 16, 11.5)
    edge(c, lid); edge(c, rim)
    fd.L(c, [[(18, 7), (21, 1)]], (90, 160, 200), 2.2)


def render(name):
    c = fitted(DRINKS[name]['fn'], name)
    outline(c, c.a > .5, 1.5, col=OUTC)        # the originals' outline is heavier than the foods'
    _, small = shrink(c, alpha_cut=90)
    return fd.centred(fd.chunky(small, 20))


if __name__ == '__main__':
    for name in DRINKS:
        im = render(name)
        im.save(os.path.join(OUTD, name + '.png'))
        print(name, im.getbbox())
