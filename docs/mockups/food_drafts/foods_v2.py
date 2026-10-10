"""Second round of food drafts (user feedback 2026-10-10). Builds on foods_draft.py."""
import os, math
import numpy as np
from PIL import Image, ImageDraw
import foods_draft as fd
from hires import field, height, material, seam, dots
import foods_draft as fd
from foods_draft import (FOODS, food, B, sq, M, L, ell, draw, OUTC, BREAD, WOOD, PLATE, CHOC, CREAM, VEG,
                         PALEVEG, RED, JALA, GLAZE, MEAT, RICE, PICKLE, CABBAGE, BOWLW, FRY, BOX, CHERRY, GLASS, EGG)

OUTA = np.array(OUTC, np.float32)
for k in ('peapod', 'springrolls', 'chocodonut', 'parfait', 'hotwings', 'curryrice', 'broccoli', 'chocobar',
          'truffle', 'jalapeno', 'pickle', 'kimchi', 'fries'):
    FOODS.pop(k, None)
FOODS.pop('meringue', None)
FOODS.pop('lemontart', None)
fd.ORIGINALS['donut'] = ('sweet', 'kid', 'Glazed Donut')

SKIN = [(18, 40, 18), (32, 66, 26), (52, 96, 36), (80, 124, 48), (120, 156, 70)]
FLESH = [(150, 170, 60), (196, 210, 96), (222, 232, 136), (238, 244, 176), (250, 252, 214)]
PIT = [(60, 30, 16), (100, 56, 30), (140, 86, 50), (176, 120, 76), (210, 160, 110)]
DOUGH = [(170, 176, 150), (210, 216, 190), (232, 238, 214), (246, 250, 234), (255, 255, 248)]
BAMBOO = [(96, 64, 26), (150, 108, 46), (196, 152, 72), (224, 190, 110), (244, 222, 160)]
COOKIE = [(110, 62, 22), (168, 108, 46), (210, 150, 72), (232, 186, 106), (248, 218, 150)]
UME = [(90, 10, 30), (150, 26, 50), (200, 56, 74), (230, 104, 112), (250, 164, 166)]
ONGGI = [(34, 20, 16), (60, 36, 26), (92, 58, 40), (124, 84, 58), (160, 118, 86)]
STONEW = [(52, 70, 96), (90, 112, 140), (150, 170, 190), (200, 214, 226), (236, 242, 248)]


@food('green', 'baby', 'Broccoli')
def broccoli(c):
    f = sq(c, 16, 27.2, 4.6, 3.6, 4)
    M(c, f, f > 1, PALEVEG, spec_amt=.2)
    rr = np.random.default_rng(3)
    for (x, y, r) in [(6.5, 14, 6.5), (25.5, 14, 6.5), (16, 6.5, 7), (10, 7.5, 6), (22, 7.5, 6), (9.5, 19, 6.2), (22.5, 19, 6.2), (16, 14, 7), (16, 20.5, 5.5)]:
        ff = field(c, [(x, y, r, r * .92)])
        micro = [(x + rr.uniform(-.7, .7) * r, y + rr.uniform(-.7, .6) * r, 1.8, 1.8, .4) for _ in range(10)]
        h = np.clip(height(ff, .5) * .7 + height(field(c, micro), .6) * .5, 0, 1.3)
        material(c, h, ff > 1, VEG, bump=7, spec_amt=.15, grain=.22, ao=.55)
        seam(c, ff > 1, (c.a > .5) & ~(ff > 1), .35, np.array((24, 46, 22), np.float32))


@food('green', 'baby', 'Avocado')
def avocado(c):
    balls = [(16, 19.5, 11.5, 10.5), (16, 9.5, 8, 7.5)]
    f = field(c, balls)
    M(c, f, f > 1, SKIN, spec_amt=.4, grain=.14)
    fi = field(c, [(16, 19.8, 9.6, 8.6), (16, 10, 6.2, 5.8)])
    M(c, fi, fi > 1, FLESH, spec_amt=.25, grain=.1)
    seam(c, fi > 1, (f > 1) & ~(fi > 1), .4, np.array((60, 90, 30), np.float32))
    B(c, [(16, 20, 5.4, 5.4)], PIT, spec_amt=.7, spec_pow=14, grain=.08)


@food('green', 'adult', 'Veggie Dumplings')
def dumplings(c):
    for (x, y, r) in [(9, 10, 5.6), (23, 10, 5.6), (16, 7.5, 6)]:
        B(c, [(x, y, r, r * .85), (x, y - r * .6, r * .55, r * .5)], [(150, 170, 120), (196, 214, 160), (224, 236, 196), (242, 248, 226), (255, 255, 246)], spec_amt=.35, grain=.08)
        seam(c, field(c, [(x, y, r, r * .85)]) > 1, (c.a > .5) & ~(field(c, [(x, y, r, r * .85)]) > 1), .4, OUTA)
        L(c, [[(x - r * .5, y - r * .3), (x, y - r * .95), (x + r * .5, y - r * .3)]], (176, 190, 150), .6)
        B(c, [(x + r * .3, y + r * .1, 1.2, .9)], VEG, spec_amt=.1)
    f = sq(c, 16, 23.5, 14.5, 7, 4)
    M(c, f, f > 1, BAMBOO, spec_amt=.25, grain=.14)
    draw(c, lambda d: [d.line([c.P(2.5, y), c.P(29.5, y)], fill=(110, 76, 34), width=int(.7 * c.k * c.z)) for y in (19, 23.5, 27.5)])
    rim = sq(c, 16, 16.8, 15, 1.6, 4)
    M(c, rim, rim > 1, BAMBOO, spec_amt=.35, grain=.1)


@food('sweet', 'baby', 'Chocolate')
def chocolate(c):
    f = sq(c, 16, 16, 13.2, 13.2, 10)
    M(c, f, f > 1, CHOC, spec_amt=.2, grain=.08)
    for (x0, y0) in [(9.4, 9.4), (22.6, 9.4), (9.4, 22.6), (22.6, 22.6)]:
        t = sq(c, x0, y0, 5.6, 5.6, 10)
        hb = np.clip((5.6 - np.maximum(np.abs(c.x - x0), np.abs(c.y - y0))) / 1.6, 0, 1) ** .6
        material(c, hb, t > 1, CHOC, bump=9, spec_amt=.35, spec_pow=14, grain=.1, ao=.2)


@food('sweet', 'baby', 'Cookie')
def cookie(c):
    f = field(c, [(16, 16, 13.8, 13.2)])
    edge = 1 + .05 * np.sin(np.arctan2(c.y - 16, c.x - 16) * 9)
    M(c, f * edge, f * edge > 1, COOKIE, spec_amt=.2, grain=.26, bump=6)
    for (x, y, r) in [(10, 10, 2.4), (19, 8.5, 2.1), (23, 15, 2.4), (13, 17, 2.6), (19.5, 22, 2.3), (9, 22, 2), (16, 12.5, 1.6), (25, 21.5, 1.6)]:
        B(c, [(x, y, r, r * .85)], CHOC, spec_amt=.5, grain=.06)
    dots(c, 14, (4, 4, 28, 28, lambda x, y: c.alpha_at(x, y) > .5), [(250, 232, 180)], r=.45, seed=12)


@food('greasy', 'baby', 'Fries')
def fries(c):
    rr = np.random.default_rng(2)
    for x in [8.5, 23.5, 11, 21, 13.5, 18.5, 16]:
        y = rr.uniform(6, 9.5)
        f = sq(c, x + rr.uniform(-.4, .4), y + 5, 1.6, 6.5, 6)
        m = f > 1
        M(c, f, m, FRY, spec_amt=.3, grain=.12)
        seam(c, m, (c.a > .5) & ~m, .45, OUTA)
    pts = [(6, 14), (26, 14), (23.5, 29), (8.5, 29)]
    im = Image.new('L', (c.w * c.k, c.h * c.k)); ImageDraw.Draw(im).polygon([c.P(*p) for p in pts], fill=255)
    m = np.asarray(im) > 127
    hb = np.clip(1 - np.abs(c.x - 16) / 11, 0, 1) ** .5
    material(c, hb, m, BOX, bump=3, spec_amt=.3, grain=.12)
    seam(c, m, (c.a > .5) & ~m, .5, OUTA)
    draw(c, lambda d: d.ellipse([*c.P(13, 19), *c.P(19, 24)], fill=(246, 210, 90)))


@food('spicy', 'baby', 'Jalapeño')
def jalapeno(c):
    B(c, [(9 + i * 2.3, 9.5 + i * 2.3 + math.sin(i / 7 * math.pi) * -1.2, 6.2 - i * .5, 5.8 - i * .45) for i in range(8)], JALA, spec_amt=.85, spec_pow=14, grain=.08)
    B(c, [(8, 8, 4.4, 2.6)], [(30, 60, 20), (50, 90, 30), (80, 120, 44), (110, 150, 60), (150, 190, 90)], spec_amt=.3)
    L(c, [[(7.5, 7), (5, 4), (6.5, 1.5)]], (90, 110, 50), 2.0)


@food('spicy', 'kid', 'Hot Drumstick')
def drumstick(c):
    L(c, [[(5, 5), (13, 13)]], (240, 230, 210), 3.0)
    for (x, y) in [(3.6, 5.8), (5.8, 3.6)]:
        B(c, [(x, y, 2.2, 2.2)], CREAM, spec_amt=.3, grain=.05)
    B(c, [(19, 19, 10.5, 10), (13.5, 13.5, 4.5, 4.5)], GLAZE, spec_amt=.75, spec_pow=16, grain=.16, bump=6)
    dots(c, 16, (9, 9, 29, 29, lambda x, y: c.alpha_at(x, y) > .5 and (x + y) > 24), [(150, 20, 14), (240, 228, 200)], r=.55, seed=4)


@food('spicy', 'adult', 'Curry Bowl')
def currybowl(c):
    bowl = field(c, [(16, 17.5, 15, 13.5)])
    M(c, bowl, bowl > 1, STONEW, spec_amt=.5, grain=.06)
    top = field(c, [(16, 15.5, 13.4, 11.6)])
    M(c, top, top > 1, [(70, 30, 8), (118, 60, 16), (160, 94, 28), (196, 134, 50), (230, 180, 96)], spec_amt=.6, spec_pow=18, grain=.08)
    seam(c, top > 1, (bowl > 1) & ~(top > 1), .45, OUTA)
    B(c, [(10, 11.5, 6.4, 5.6), (9, 9, 4, 3.2)], RICE, spec_amt=.15, grain=.35, bump=7)
    for (x, y, r, pal) in [(19.5, 11.5, 2.8, MEAT), (24.5, 15.5, 2.6, FRY), (20, 18.5, 2.4, BOX), (14, 20, 2.4, MEAT), (24, 21, 2, FRY), (17, 15, 2, BOX)]:
        B(c, [(x, y, r, r * .85)], pal, spec_amt=.35, grain=.12)
    B(c, [(9.5, 19, 2.6, 1.5)], CHERRY, spec_amt=.4)


@food('sour', 'baby', 'Pickle')
def pickle(c):
    B(c, [(7 + i * 2.3, 25 - i * 2.4 - math.sin(i / 7 * math.pi) * 1.2, 5.2, 5.2) for i in range(8)], PICKLE, spec_amt=.35, grain=.18)
    rr = np.random.default_rng(5)
    warts = [(rr.uniform(4, 27), rr.uniform(5, 28), .85, .85, .3) for _ in range(55)]
    wf = field(c, warts)
    m = (c.a > .5) & (wf > 1)
    material(c, np.ones_like(c.x) * .85, m, PICKLE, bump=0, spec_amt=.4, grain=.05)
    dk = (c.a > .5) & (np.sin((c.x + c.y) * 1.3) > .85) & (wf < .6)
    material(c, np.ones_like(c.x) * .35, dk, PICKLE, bump=0, spec_amt=0, grain=.1)


@food('sour', 'kid', 'Kimchi')
def kimchi(c):
    bowl = field(c, [(16, 20, 15, 10)])
    M(c, bowl, (bowl > 1) & (c.y > 17), ONGGI, spec_amt=.55, grain=.12)
    draw(c, lambda d: d.line([c.P(3, 23.5), c.P(29, 23.5)], fill=(140, 100, 70), width=int(.8 * c.k * c.z)))
    for (x, y, rx, ry) in [(8.5, 14, 5.4, 3.6), (16, 11.5, 6, 4), (23.5, 14, 5.4, 3.6), (12, 16.5, 5.4, 3), (20, 16.5, 5.4, 3), (16, 7, 4.4, 3), (11, 9.5, 3.6, 2.6), (21, 9.5, 3.6, 2.6)]:
        B(c, [(x, y, rx, ry)], CABBAGE, bump=7, spec_amt=.5, grain=.2)
    dots(c, 12, (5, 5, 27, 18, lambda x, y: c.alpha_at(x, y) > .5), [(250, 236, 214), (110, 160, 60)], r=.55, seed=6)


CUSTARD = [(170, 110, 20), (224, 164, 46), (246, 204, 92), (252, 228, 148), (255, 246, 206)]
CARAMEL = [(50, 18, 8), (96, 40, 14), (146, 70, 24), (190, 110, 44), (226, 160, 90)]


@food('sweet', 'adult', 'Purin')
def purin(c):
    pts = [(7, 8), (25, 8), (29.5, 26.5), (2.5, 26.5)]
    im = Image.new('L', (c.w * c.k, c.h * c.k)); ImageDraw.Draw(im).rounded_rectangle  # (keeps PIL imported)
    d = ImageDraw.Draw(im); d.polygon([c.P(*p) for p in pts], fill=255)
    m = np.asarray(im) > 127
    hb = np.clip(1 - np.abs(c.x - 16) / 14, 0, 1) ** .5
    material(c, hb, m, CUSTARD, bump=3, spec_amt=.5, grain=.1)
    seam(c, m, (c.a > .5) & ~m, .5, OUTA)
    drip = m & (c.y < 11.5 + 3.2 * np.exp(-((c.x - 10.5) / 1.2) ** 2) + 5 * np.exp(-((c.x - 19.5) / 1.3) ** 2) + 2.2 * np.exp(-((c.x - 24) / 1.0) ** 2))
    material(c, hb, drip, CARAMEL, bump=3, spec_amt=.85, spec_pow=16, grain=.05)
    top = field(c, [(16, 7.6, 9.2, 2.6)])
    M(c, top, top > 1, CARAMEL, spec_amt=.6, grain=.05)
    B(c, [(16, 5, 5.4, 2.6), (16, 2.8, 2.6, 1.8)], CREAM, spec_amt=.25, grain=.08)
    B(c, [(18.5, 1.8, 2.2, 2.1)], CHERRY, spec_amt=.9, grain=.04)
    pl = sq(c, 16, 27.6, 15.5, 2.2, 3)
    material(c, np.clip(height(pl, .5), 0, 1), pl > 1, PLATE, bump=3, spec_amt=.5, grain=.05, ao=.15)
    seam(c, pl > 1, (c.a > .5) & ~(pl > 1), .45, OUTA)


@food('sour', 'kid', 'Umeboshi')
def umeboshi(c):
    f = sq(c, 16, 23, 15, 6.5, 4)
    M(c, f, f > 1, STONEW, spec_amt=.5, grain=.06)
    B(c, [(9, 9, 6, 3), (12, 7, 3, 2)], VEG, spec_amt=.2, grain=.12)
    for (x, y, r) in [(10, 16, 5.6), (21.5, 16, 5.6), (16, 11, 5.8)]:
        B(c, [(x, y, r, r * .92)], UME, bump=8, spec_amt=.6, spec_pow=16, grain=.32)


@food('sour', 'adult', 'Pickle Jar')
def picklejar(c):
    jar = sq(c, 16, 18.5, 11, 11.5, 3.2)
    M(c, jar, jar > 1, GLASS, spec_amt=.9, spec_pow=28, grain=.03, ao=.1)
    inner = (sq(c, 16, 19.5, 9.4, 9.6, 3.2) > 1)
    material(c, np.clip(height(jar, .5), 0, 1) * .7, inner & (c.y > 11.5), [(130, 140, 40), (176, 180, 70), (206, 206, 110), (228, 226, 150), (244, 240, 196)], bump=2, spec_amt=.4, grain=.05)
    for (x, y, rx) in [(10.5, 19.5, 3), (16, 19, 3.2), (21.5, 20, 3)]:
        ff = field(c, [(x, y - 4 + i * 2.5, rx, 2.4) for i in range(4)])
        material(c, np.clip(height(ff, .5), 0, 1), (ff > 1) & inner & (c.y > 11.5), PICKLE, bump=5, spec_amt=.3, grain=.18)
    lid = sq(c, 16, 6, 10, 3.2, 5)
    M(c, lid, lid > 1, RED, spec_amt=.6, grain=.08)
    draw(c, lambda d: [d.line([c.P(7 + i * 3, 3.6), c.P(7 + i * 3, 8.4)], fill=(250, 236, 220), width=int(.8 * c.k * c.z)) for i in range(7)])


for k in ('ramen', 'tomyum', 'dumplings'):
    FOODS.pop(k, None)
YOLK2 = [(176, 92, 10), (226, 140, 20), (250, 184, 40), (255, 214, 90), (255, 240, 170)]
BROTH2 = [(110, 30, 14), (170, 62, 26), (214, 104, 44), (238, 150, 76), (252, 200, 130)]
BOWLRED2 = [(60, 14, 14), (110, 26, 24), (156, 44, 36), (190, 74, 58), (220, 120, 100)]
SHRIMP2 = [(130, 40, 26), (200, 80, 50), (236, 128, 88), (250, 170, 130), (255, 214, 186)]
LIME2 = [(30, 70, 20), (60, 120, 30), (100, 170, 50), (150, 206, 84), (206, 236, 150)]


def soup_bowl(c, bowl_pal, soup_pal):
    """seen from above-ish like the curry: the soup fills it, the bowl is a thin band"""
    bowl = field(c, [(16, 17.5, 15, 13.5)])
    M(c, bowl, bowl > 1, bowl_pal, spec_amt=.55, grain=.06)
    top = field(c, [(16, 15.5, 13.4, 11.6)])
    M(c, top, top > 1, soup_pal, spec_amt=.55, grain=.1)
    seam(c, top > 1, (bowl > 1) & ~(top > 1), .45, OUTA)


@food('spicy', 'adult', 'Fire Ramen')
def ramen(c):
    soup_bowl(c, [(14, 12, 14), (30, 26, 30), (52, 46, 52), (80, 72, 80), (120, 110, 120)], BROTH2)
    L(c, [[(5.5 + i * 2.6, 12.5 + (i % 2) * 1.5), (8 + i * 2.6, 21.5 - (i % 2) * 1.5)] for i in range(8)], (250, 228, 160), 1.3)
    B(c, [(20.5, 12, 4.4, 3.8)], EGG, spec_amt=.4, grain=.06)
    B(c, [(20.5, 12.2, 2.2, 2)], YOLK2, spec_amt=.6, grain=.06)
    B(c, [(9.5, 11, 3, 2), (13, 9.5, 2, 1.5)], VEG, spec_amt=.2)
    f = sq(c, 12, 20, 3.6, 2.6, 3)
    M(c, f, f > 1, [(110, 60, 50), (170, 110, 96), (220, 170, 156), (240, 214, 204), (255, 240, 236)], spec_amt=.3)
    dots(c, 8, (5, 8, 27, 24, lambda x, y: c.alpha_at(x, y) > .5), [(150, 20, 14)], r=.6, seed=5, angle=False)


@food('sour', 'adult', 'Tom Yum')
def tomyum(c):
    soup_bowl(c, BOWLW, BROTH2)
    for (x, y) in [(10, 13.5), (17, 18.5)]:
        B(c, [(x + math.cos(t) * 3, y + math.sin(t) * 2.4, 2.1 - t * .15, 2 - t * .15) for t in np.linspace(0, 4, 6)], SHRIMP2, spec_amt=.5, grain=.08)
    w = ell(c, 22.5, 11, 5, 3.8) & (c.y < 12.5)
    material(c, np.clip(height(field(c, [(22.5, 11, 5, 3.8)]), .5), 0, 1), w, LIME2, bump=4, spec_amt=.5, grain=.08)
    B(c, [(13.5, 21, 2.2, 1.3), (23, 18.5, 2, 1.2), (8, 18, 1.6, 1)], VEG, spec_amt=.2)
    dots(c, 8, (5, 8, 27, 24, lambda x, y: c.alpha_at(x, y) > .5), [(200, 30, 20)], r=.6, seed=9, angle=False)


@food('green', 'adult', 'Veggie Dumplings')
def dumplings(c):
    f = sq(c, 16, 25.5, 14.5, 4.6, 6)
    M(c, f, f > 1, BAMBOO, spec_amt=.25, grain=.14)
    draw(c, lambda d: [d.line([c.P(2.5, y), c.P(29.5, y)], fill=(110, 76, 34), width=int(.7 * c.k * c.z)) for y in (24, 27.5)])
    inner = field(c, [(16, 19, 14.5, 7.2)])
    M(c, inner, inner > 1, [(70, 46, 20), (110, 76, 34), (150, 108, 50), (184, 140, 70), (214, 176, 104)], spec_amt=.2, grain=.12)
    for (x, y, r) in [(9, 16.5, 6), (23, 16.5, 6), (16, 12.5, 6.4), (16, 20, 5.6)]:
        ff = field(c, [(x, y, r, r * .85), (x, y - r * .55, r * .55, r * .5)])
        M(c, ff, ff > 1, [(150, 170, 120), (196, 214, 160), (224, 236, 196), (242, 248, 226), (255, 255, 246)], spec_amt=.35, grain=.08)
        seam(c, ff > 1, (c.a > .5) & ~(ff > 1), .4, OUTA)
        L(c, [[(x - r * .5, y - r * .3), (x, y - r * .95), (x + r * .5, y - r * .3)]], (176, 190, 150), .6)


FLAT = {'chocolate', 'dumplings', 'purin'}       # flat bottoms: no stray narrow pixel row under the outline


def render(name):
    im = fd.render(name)
    if name in FLAT:
        a = np.asarray(im).copy()
        rows = np.nonzero(a[..., 3].sum(1))[0]
        b = rows[-1]
        if (a[b, :, 3] > 0).sum() < .8 * (a[b - 1, :, 3] > 0).sum():
            a[b] = 0                                       # drop it...
            im = fd.centred(Image.fromarray(a, 'RGBA'))    # ...and re-centre
    return im


if __name__ == '__main__':
    import glob
    for p in glob.glob(os.path.join(fd.OUTD, '*.png')):
        os.remove(p)
    for name in FOODS:
        im = render(name)
        im.save(os.path.join(fd.OUTD, name + '.png'))
        print(name, FOODS[name]['fam'], FOODS[name]['stage'], im.getbbox(), flush=True)
