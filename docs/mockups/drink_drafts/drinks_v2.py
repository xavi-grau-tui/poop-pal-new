"""Drinks round 2 (user feedback 2026-10-10). Lemonade and Barley Tea are built FROM the original
Orange Juice and Water pixels (recoloured), the rest redrawn."""
import os, math, colorsys
import numpy as np
from PIL import Image
import drinks_draft as dd
from drinks_draft import (DRINKS, drink, poly, rrect, cyl, edge, draw, W, GLASSP, WHITE, PINKP, CERAM, COFFEE, BLUEP,
                          CHERRY, CREAM, fd, OUTD, PROJ)
from hires import field, material, dots, seam

dd.OUTC[:] = (60, 49, 33)                  # the originals' outline colour
for k in ('lemonade', 'barleytea', 'ramune', 'greentea', 'coffee', 'milk', 'yogurt', 'milkshake'):
    DRINKS.pop(k, None)

MILKTEA = [(110, 70, 40), (160, 112, 72), (196, 150, 106), (220, 184, 144), (240, 216, 186)]
PEARL = [(16, 10, 8), (34, 22, 18), (56, 38, 30), (84, 60, 48), (120, 92, 76)]
MELON = [(30, 110, 40), (60, 160, 60), (100, 200, 90), (150, 228, 130), (206, 246, 190)]
TEA = [(110, 50, 14), (160, 84, 26), (196, 120, 46), (220, 156, 80), (240, 196, 130)]


def recolour(src, fn):
    im = Image.open(f'{PROJ}/textures/drinks/{src}.png').convert('RGBA')
    a = np.asarray(im).astype(np.float32) / 255
    out = a.copy()
    for y in range(32):
        for x in range(32):
            if a[y, x, 3] == 0: continue
            h, s, v = colorsys.rgb_to_hsv(*a[y, x, :3])
            r = fn(h, s, v, x, y)
            if r is not None:
                out[y, x, :3] = colorsys.hsv_to_rgb(*r)
    return Image.fromarray((out * 255).astype(np.uint8), 'RGBA').copy()


def lemonade_px():
    """the Orange Juice glass and slice, made lemon yellow, with a few bubbles"""
    def fn(h, s, v, x, y):
        if v > .4 and s > .3 and .03 < h < .16:          # orange juice + slice -> lemon
            return (.14, s * .8, min(1, v * 1.04))
        return None
    im = recolour('orangejuice', fn)
    px = im.load()
    for (x, y) in [(10, 14), (14, 20), (18, 12), (12, 25), (19, 22), (16, 17)]:
        r, g, b, a = px[x, y]
        if a and r > 200:
            px[x, y] = (255, 252, 222, 255)
    return im


def barleytea_px():
    """the Water bottle filled with amber barley tea, with a red-brown cap and label"""
    def fn(h, s, v, x, y):
        if v < .35:
            return None                                    # the outline
        if .08 < h < .2 and s < .4 and v > .8:
            return None                                    # the cream shine stays
        if .5 < h < .75 and s > .3:                        # the cap and the band -> red-brown
            return (.03, .6, v * .85)
        return (.085, .6, min(1, v * .95))                 # everything else (the water) -> amber tea
    return recolour('water', fn)


@drink('caffeinated', 1, 'Tea')
def tea(c):
    """a deep teacup filling the icon, a small saucer, the tea bag's tag over the front"""
    fd.B(c, [(15, 28, 12.5, 2.6)], CERAM, spec_amt=.5, grain=.06)
    h = fd.ell(c, 25, 15.5, 4.2, 5) & ~fd.ell(c, 25, 15.5, 2, 2.8)
    cyl(c, h, CERAM, 25, 4.2)
    edge(c, h)
    cup = (fd.ell(c, 15, 12, 10, 15) & (c.y > 6.5) & (c.y < 26.5))
    cyl(c, cup, CERAM, 15, 10, spec=.45)
    band = cup & (np.abs(c.y - 10.5) < 1)
    cyl(c, band, [(60, 90, 140), (90, 120, 170), (120, 150, 196), (160, 186, 220), (200, 216, 240)], 15, 10)
    edge(c, cup)
    top = fd.ell(c, 15, 6.8, 9.2, 2.3)
    material(c, np.ones_like(c.x) * .75, top, TEA, bump=0, spec_amt=.3, grain=.06)
    edge(c, top)
    fd.L(c, [[(11.5, 6.5), (10.5, 11), (10.5, 15)]], (236, 232, 218), .55)
    tag = rrect(c, 8.4, 15, 12.6, 19.6, .4)
    material(c, np.ones_like(c.x) * .8, tag, [(150, 40, 30), (190, 60, 40), (220, 90, 60), (240, 130, 100), (250, 180, 150)], bump=0, spec_amt=.1, grain=.05)
    edge(c, tag)
    fd.L(c, [[(13, 4.4), (14, 2.6), (13, 1)], [(17.5, 4.4), (18.5, 2.6), (17.5, 1)]], (220, 224, 220), .7)


@drink('caffeinated', 2, 'Coffee')
def coffee(c):
    h = fd.ell(c, 24.5, 17, 5, 6) & ~fd.ell(c, 24.5, 17, 2.6, 3.4)
    cyl(c, h, CERAM, 24.5, 5)
    edge(c, h)
    mug = (fd.sq(c, 14, 15, 10, 9.5, 5) > 1) | (fd.ell(c, 14, 20, 10, 9.5) & (c.y > 15))   # round-bottomed mug
    cyl(c, mug, CERAM, 14, 10, spec=.45)
    edge(c, mug)
    top = fd.ell(c, 14, 7.2, 9.4, 2.3)
    material(c, np.ones_like(c.x) * .7, top, COFFEE, bump=0, spec_amt=.3, grain=.06)
    draw(c, lambda d: d.ellipse([*c.P(11.5, 6.4), *c.P(16.5, 8.2)], fill=(214, 176, 130)))
    edge(c, top)


@drink('milky', 1, 'Milk')
def milk(c):
    """a carton seen straight from the front"""
    body = rrect(c, 8, 11, 24, 30, .8)
    gable = poly(c, [(8, 11.4), (24, 11.4), (21, 5), (11, 5)])
    tab = rrect(c, 10.5, 2.6, 21.5, 5.4, .4)
    for m, v in ((tab, .8), (gable, .92), (body, .88)):
        material(c, np.ones_like(c.x) * v, m, WHITE, bump=0, spec_amt=.1, grain=.08)
    cyl(c, body, WHITE, 16, 8)
    band = body & (c.y > 17) & (c.y < 25)
    cyl(c, band, BLUEP, 16, 8)
    drop = poly(c, [(16, 17.8), (18.4, 21.4), (16, 23.6), (13.6, 21.4)])
    material(c, np.ones_like(c.x) * .9, drop, WHITE, bump=0, spec_amt=.1, grain=.04)
    for m in (tab, gable, body):
        edge(c, m)
    draw(c, lambda d: d.line([c.P(16, 5.4), c.P(16, 11)], fill=(190, 188, 180), width=W(c, .6)))


@drink('milky', 2, 'Bubble Tea')
def bubbletea(c):
    cup = poly(c, [(7, 9), (25, 9), (23, 30), (9, 30)])
    cyl(c, cup, GLASSP, 16, 9, spec=.6)
    liq = poly(c, [(8.4, 11), (23.6, 11), (21.8, 28.6), (10.2, 28.6)])
    cyl(c, liq, MILKTEA, 16, 7.6, spec=.35)
    for (x, y) in [(11.5, 26.5), (14.5, 27), (17.5, 26.8), (20.5, 26.4), (13, 24), (16, 24.4), (19, 24), (21.5, 23.6), (11, 23.2)]:
        fd.B(c, [(x, y, 1.5, 1.5)], PEARL, spec_amt=.9, spec_pow=14, grain=.02)
    edge(c, cup)
    lid = rrect(c, 5.5, 7.5, 26.5, 10.4, .8)
    cyl(c, lid, GLASSP, 16, 10.5, spec=.7)
    edge(c, lid)
    straw = poly(c, [(15.5, 8), (18.5, 8), (21.5, .8), (18.5, .8)])
    cyl(c, straw, [(110, 40, 80), (160, 60, 110), (200, 96, 146), (226, 140, 180), (244, 190, 214)], 18.5, 2)
    edge(c, straw)


@drink('fizzy', 3, 'Soda Float')
def sodafloat(c):
    """a tall glass of melon soda with ice, one round scoop on top, a cherry and a straw"""
    gl = poly(c, [(5, 12), (25, 12), (22.5, 30), (7.5, 30)])
    cyl(c, gl, GLASSP, 15, 10, spec=.6)
    liq = poly(c, [(6.6, 13.4), (23.4, 13.4), (21.2, 28.6), (8.8, 28.6)])
    cyl(c, liq, MELON, 15, 8.4, spec=.45)
    for (x, y) in [(11, 18), (18.5, 21.5)]:
        ice = rrect(c, x - 2, y - 2, x + 2, y + 2, .6)
        material(c, np.ones_like(c.x) * .85, ice, [(150, 210, 180), (190, 236, 210), (220, 248, 232), (240, 255, 246), (255, 255, 255)], bump=0, spec_amt=.3, grain=.04)
    dots(c, 7, (9, 15, 21, 27, lambda x, y: True), [(236, 255, 230)], r=.5, seed=4, angle=False)
    edge(c, gl)
    fd.L(c, [[(20, 11), (26.5, 2)]], (230, 110, 140), 1.7)
    sc = field(c, [(15, 9, 8.6, 6)])
    fd.M(c, sc, (sc > 1) & (c.y < 12.6 + 1.0 * np.sin(c.x * 1.4)), CREAM, spec_amt=.3, grain=.1)
    seam(c, (sc > 1) & (c.y < 12.6 + 1.0 * np.sin(c.x * 1.4)), (c.a > .5) & ~(sc > 1), .6, dd.OUTC)
    fd.B(c, [(15.5, 2.2, 2.6, 2.5)], CHERRY, spec_amt=.9, grain=.04)


@drink('milky', 3, 'Milkshake')
def milkshake(c):
    """re-arranged: a straight glass like the originals', the shake, a cream dome, cherry, straw"""
    gl = rrect(c, 6.5, 11, 23.5, 30, 1.2)
    cyl(c, gl, GLASSP, 15, 8.5, spec=.6)
    liq = rrect(c, 8, 12.5, 22, 28.6, .8)
    cyl(c, liq, PINKP, 15, 7, spec=.4)
    edge(c, gl)
    fd.B(c, [(15, 10.6, 9.6, 3.2), (11, 9.2, 3.6, 2.8), (19, 9.2, 3.6, 2.8), (15, 7.4, 5, 3.2)], CREAM, spec_amt=.25, grain=.08)
    fd.B(c, [(15, 3.6, 2.6, 2.5)], CHERRY, spec_amt=.9, grain=.04)
    fd.L(c, [[(20, 8), (25, 1)]], (230, 110, 140), 1.8)


PIXEL = {'lemonade': (('fizzy', 2, 'Lemonade'), lemonade_px), 'barleytea': (('watery', 2, 'Barley Tea'), barleytea_px)}


if __name__ == '__main__':
    import glob
    for p in glob.glob(os.path.join(OUTD, '*.png')):
        os.remove(p)
    for name in DRINKS:
        dd.render(name).save(os.path.join(OUTD, name + '.png'))
    for name, (_, fnc) in PIXEL.items():
        fnc().save(os.path.join(OUTD, name + '.png'))
    print('ok')
