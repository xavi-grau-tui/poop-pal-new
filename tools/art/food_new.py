"""New food icons (32x32, same paint-big-then-shrink style as food.py): spicy, sour, the exotic
tech / cosmic foods and the five legendary ones.

    python3 tools/art/food_new.py   -> textures/food/<name>.png
"""
import math, os
from hires import *

DEST = os.path.join(PROJ, 'food')
os.makedirs(DEST, exist_ok=True)

RED = [(70, 10, 16), (140, 24, 30), (200, 50, 44), (232, 92, 70), (250, 150, 120)]
GREEN_S = [(24, 50, 28), (46, 92, 40), (84, 140, 56), (126, 180, 74), (178, 214, 110)]
PICKLE = [(30, 50, 16), (70, 100, 30), (118, 150, 52), (160, 186, 80), (206, 220, 130)]
LEMON = [(150, 110, 10), (220, 176, 30), (250, 216, 60), (255, 236, 120), (255, 250, 210)]
GLAZE = [(90, 24, 10), (160, 52, 20), (210, 92, 36), (238, 140, 60), (255, 200, 120)]
BONE = [(150, 130, 110), (210, 196, 170), (240, 232, 210), (255, 250, 240), (255, 255, 255)]
BOWL = [(60, 40, 30), (110, 74, 52), (160, 112, 80), (200, 152, 110), (236, 200, 160)]
CURRY = [(120, 60, 10), (190, 110, 20), (230, 160, 40), (250, 200, 80), (255, 236, 150)]
RICE = [(170, 166, 156), (214, 210, 200), (240, 238, 230), (252, 252, 248), (255, 255, 255)]
CABBAGE = [(110, 20, 20), (180, 40, 30), (220, 80, 50), (240, 130, 90), (255, 200, 160)]
CHIP = [(18, 22, 28), (40, 46, 56), (66, 74, 88), (96, 106, 122), (140, 150, 168)]
SILVER = [(80, 86, 100), (140, 148, 164), (196, 202, 216), (230, 234, 244), (255, 255, 255)]
BATT = [(14, 40, 20), (30, 90, 44), (60, 150, 70), (110, 200, 110), (180, 240, 170)]
GOO = [(20, 60, 30), (40, 140, 60), (90, 210, 90), (160, 250, 140), (230, 255, 210)]
GLASS = [(120, 140, 160), (170, 196, 214), (210, 230, 240), (236, 246, 252), (255, 255, 255)]
ROCK = [(40, 40, 50), (80, 80, 94), (122, 122, 138), (166, 166, 180), (210, 210, 222)]
GOLD = [(110, 66, 10), (176, 120, 20), (226, 176, 40), (250, 214, 90), (255, 244, 190)]
SUGAR = [(150, 130, 190), (200, 186, 236), (232, 224, 252), (248, 244, 255), (255, 255, 255)]
OIL = [(120, 50, 0), (190, 100, 10), (240, 160, 30), (255, 210, 80), (255, 244, 180)]
PHOENIX = [(120, 20, 10), (210, 60, 20), (250, 140, 30), (255, 210, 70), (255, 250, 200)]
BRINE = [(10, 50, 50), (20, 100, 96), (50, 160, 150), (120, 214, 200), (210, 250, 240)]
TENT = [(60, 20, 60), (120, 40, 110), (180, 80, 160), (220, 140, 200), (250, 210, 240)]


def blob(c, balls, pal, **kw):
    f = field(c, balls)
    m = f > 1
    material(c, height(f, .5), m, pal, **{**dict(bump=5, spec_amt=.4, grain=.08), **kw})
    return f, m


def draw_lines(c, lines, col, w):
    im = to_image(c); d = ImageDraw.Draw(im)
    for l in lines:
        d.line([c.P(*p) for p in l], fill=col, width=int(w * c.k), joint='curve')
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


def jar(c, pal_in, label=None):
    """a glass jar with something glowing inside"""
    blob(c, [(16, 19, 9, 10.5)], GLASS, spec_amt=.9, spec_pow=30, grain=.02, ao=.1)
    inner = field(c, [(16, 21, 7.5, 8)])
    m = (inner > 1) & (c.y > 15)
    material(c, height(inner, .5), m, pal_in, bump=3, spec_amt=.5, grain=.05)
    blob(c, [(16, 7.5, 7.5, 2.4)], [(70, 50, 40), (120, 90, 70), (170, 130, 100), (210, 170, 140), (240, 210, 180)])


def save(c, name):
    outline(c, c.a > .5, 1.0)
    _, small = shrink(c)
    small.save(os.path.join(DEST, name + '.png'))
    return small


ICONS = {}


def icon(fn):
    ICONS[fn.__name__] = fn
    return fn


@icon
def chilipepper(c):
    blob(c, [(10 + i * 2.2, 13 + i * 1.6 + (i * i) * .12, 4.4 - i * .35, 4.0 - i * .3) for i in range(9)], RED, spec_amt=.8, spec_pow=18)
    draw_lines(c, [[(9, 10), (8, 6), (11, 4)]], (60, 120, 40), 2.2)


@icon
def hotwings(c):
    for (x, y, a) in [(11, 18, .5), (20, 15, -.4)]:
        draw_lines(c, [[(x + math.cos(a) * 3, y - 8), (x + math.cos(a) * 1, y - 2)]], (240, 230, 210), 2.4)
        blob(c, [(x, y, 6, 7), (x + 1, y + 3, 5, 4.5)], GLAZE, spec_amt=.7, spec_pow=16)
    dots(c, 10, (4, 10, 28, 26, lambda x, y: True), [(240, 230, 210), (80, 40, 20)], r=.5, seed=4)


@icon
def curry(c):
    blob(c, [(16, 21, 12.5, 6.5)], BOWL)
    f = field(c, [(16, 17, 11, 3.6)])
    material(c, height(f, .5), f > 1, CURRY, bump=3, spec_amt=.5, grain=.06)
    blob(c, [(20, 14.5, 5, 3.2)], RICE, spec_amt=.2, grain=.15)
    dots(c, 5, (8, 15, 18, 19, lambda x, y: True), [(110, 170, 70)], r=.7, seed=2)


@icon
def pickle(c):
    blob(c, [(9 + i * 2, 24 - i * 2.1, 5.2, 5.2) for i in range(8)], PICKLE, spec_amt=.35)
    dots(c, 12, (5, 7, 27, 28, lambda x, y: c.a[min(int(y * c.k), c.h * c.k - 1), min(int(x * c.k), c.w * c.k - 1)] > .5), [(206, 220, 130), (50, 80, 24)], r=.6, seed=5)


@icon
def lemon(c):
    blob(c, [(16, 17, 10, 8), (6.5, 17, 2.4, 2), (25.5, 17, 2.4, 2)], LEMON, spec_amt=.6)
    blob(c, [(19, 7.5, 4.5, 2.2)], GREEN_S)


@icon
def kimchi(c):
    blob(c, [(16, 22, 12, 6)], [(40, 40, 50), (90, 90, 104), (150, 150, 166), (200, 200, 214), (240, 240, 248)])
    for (x, y) in [(11, 15), (17, 13), (22, 16), (14, 18.5), (20, 19)]:
        blob(c, [(x, y, 4.2, 2.8)], CABBAGE, bump=6, grain=.12)
    dots(c, 8, (6, 11, 26, 21, lambda x, y: True), [(255, 240, 220), (240, 60, 40)], r=.5, seed=6)


@icon
def microchip(c):
    sq = (np.abs(c.x - 16) < 9) & (np.abs(c.y - 16) < 9)
    material(c, np.ones_like(c.x) * .6, sq, CHIP, bump=0, spec_amt=.2, grain=.05)
    draw_lines(c, [[(5 + i * 4.4 - 4, 4), (5 + i * 4.4 - 4, 7)] for i in range(1, 6)] + [[(5 + i * 4.4 - 4, 25), (5 + i * 4.4 - 4, 28)] for i in range(1, 6)]
               + [[(4, 5 + i * 4.4 - 4), (7, 5 + i * 4.4 - 4)] for i in range(1, 6)] + [[(25, 5 + i * 4.4 - 4), (28, 5 + i * 4.4 - 4)] for i in range(1, 6)], (200, 206, 220), 1.4)
    draw_lines(c, [[(11, 12), (15, 12), (17, 16)], [(12, 20), (16, 20), (21, 15)]], (226, 176, 40), 1.0)


@icon
def battery(c):
    body_ = (np.abs(c.x - 16) < 7) & (c.y > 8) & (c.y < 27)
    h = np.clip(1 - np.abs(c.x - 16) / 7, 0, 1) ** .5
    material(c, h, body_, BATT, bump=3, spec_amt=.4, grain=.04)
    cap = (np.abs(c.x - 16) < 3) & (c.y > 5) & (c.y <= 8)
    material(c, h, cap, SILVER, bump=2, spec_amt=.6, grain=.02)
    band = body_ & (c.y > 22)
    material(c, h, band, SILVER, bump=2, spec_amt=.6, grain=.02)
    draw_lines(c, [[(14, 15), (18, 15)], [(16, 13), (16, 17)]], (240, 255, 230), 1.2)


@icon
def aliengoo(c):
    jar(c, GOO)
    dots(c, 4, (11, 17, 21, 26, lambda x, y: True), [(240, 255, 230)], r=.6, seed=8)


@icon
def moonrock(c):
    blob(c, [(16, 18, 11, 8.5), (12, 14, 6, 5), (21, 15, 5, 4.5)], ROCK, bump=7, grain=.14)
    im = to_image(c); d = ImageDraw.Draw(im)
    for (x, y, r) in [(12, 18, 2), (20, 21, 1.6), (19, 13, 1.2)]:
        d.ellipse([*c.P(x - r, y - r), *c.P(x + r, y + r)], fill=(90, 90, 104))
    d.polygon([c.P(25, 6), c.P(26, 8.5), c.P(28.5, 9), c.P(26, 10), c.P(25, 12.5), c.P(24, 10), c.P(21.5, 9), c.P(24, 8.5)], fill=(255, 250, 200))
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


@icon
def goldenseed(c):
    blob(c, [(16, 18, 6.5, 9), (16, 11, 4, 4)], GOLD, spec_amt=.9, spec_pow=20)
    draw_lines(c, [[(16, 8), (17, 4), (21, 3)]], (90, 150, 50), 1.8)
    for (x, y) in [(7, 9), (25, 13), (8, 24)]:
        draw_lines(c, [[(x - 1.6, y), (x + 1.6, y)], [(x, y - 1.6), (x, y + 1.6)]], (255, 244, 170), .9)


@icon
def stardustsugar(c):
    cube = (np.abs(c.x - 16) < 8) & (np.abs(c.y - 18) < 8)
    material(c, np.clip(1 - (np.abs(c.x - 16) + np.abs(c.y - 18)) / 16, 0, 1) ** .4, cube, SUGAR, bump=2, spec_amt=.3, grain=.18)
    for (x, y, r) in [(13, 15, 1.4), (19, 20, 1.1), (24, 7, 1.8), (8, 8, 1.2)]:
        im = to_image(c); d = ImageDraw.Draw(im)
        d.polygon([c.P(x, y - r * 1.8), c.P(x + r * .5, y), c.P(x, y + r * 1.8), c.P(x - r * .5, y)], fill=(250, 214, 80))
        d.polygon([c.P(x - r * 1.8, y), c.P(x, y + r * .5), c.P(x + r * 1.8, y), c.P(x, y - r * .5)], fill=(250, 214, 80))
        a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


@icon
def dragonoil(c):
    blob(c, [(16, 20, 8.5, 9)], GLASS, spec_amt=.9, spec_pow=30, grain=.02, ao=.1)
    inner = field(c, [(16, 21.5, 7, 7)])
    material(c, height(inner, .5), (inner > 1) & (c.y > 17), OIL, bump=3, spec_amt=.6, grain=.04)
    neck = (np.abs(c.x - 16) < 2.4) & (c.y > 5) & (c.y < 12)
    material(c, np.ones_like(c.x) * .7, neck, GLASS, bump=0, spec_amt=.3, grain=.02)
    blob(c, [(16, 5, 3, 1.8)], [(90, 30, 20), (150, 50, 30), (200, 80, 40), (230, 120, 70), (250, 180, 130)])
    f = field(c, [(16, 22, 2.2, 3.2), (16, 19.5, 1.2, 2)])
    material(c, height(f, .5), f > 1, PHOENIX, bump=2, spec_amt=.1, grain=.03, ao=0)


@icon
def phoenixpepper(c):
    blob(c, [(10 + i * 2.2, 13 + i * 1.6 + (i * i) * .12, 4.4 - i * .35, 4.0 - i * .3) for i in range(9)], PHOENIX, spec_amt=.8, spec_pow=18)
    for (x0, y0, ang) in [(8, 10, 2.2), (11, 8, 1.7), (14, 9, 1.2)]:
        f = field(c, [(x0 + math.cos(ang) * t * 4, y0 - math.sin(ang) * t * 4, 1.6 - t * .5, 1.6 - t * .5) for t in (0, .5, 1, 1.5)])
        m = (f > 1) & (c.a < .5)
        material(c, height(f, .5), m, PHOENIX, bump=2, spec_amt=.2, grain=.03, ao=0)


@icon
def krakenbrine(c):
    jar(c, BRINE)
    f = field(c, [(12 + t * 2, 25 - t * 3.2 - math.sin(t) * 1.5, 1.8 - t * .3, 1.8 - t * .3) for t in (0, .7, 1.4, 2.1, 2.8)])
    material(c, height(f, .5), (f > 1) & (c.y > 15), TENT, bump=3, spec_amt=.4, grain=.04)


if __name__ == '__main__':
    out = []
    for name, fn in ICONS.items():
        c = Canvas(32, 32, 16)
        fn(c)
        out.append(save(c, name))
    prev = Image.new('RGBA', (len(out) * 36, 36), (236, 220, 190, 255))
    for i, im in enumerate(out):
        prev.alpha_composite(im, (i * 36 + 2, 2))
    prev.resize((prev.width * 4, prev.height * 4), Image.NEAREST).save(os.path.join(SCR, 'food_new_preview.png'))
    print('ok', len(out))
