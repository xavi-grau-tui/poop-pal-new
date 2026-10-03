"""Accessory icons for the dress-up list (32x32, the food icons' paint-big-then-shrink style),
so the list shows the item itself instead of the pal wearing it. Colours follow the worn art
(dark sunglasses, the red knitted scarf, the orange headphones with plum pads). "none" is an
empty coat hanger.

    python3 tools/art/accessory_icons.py   -> textures/pet/accessories/icons/<id>.png
"""
import math, os
from hires import *
from food_new import blob, draw_lines

DEST = os.path.join(PROJ, 'pet', 'accessories', 'icons')
os.makedirs(DEST, exist_ok=True)

LENS = [(10, 8, 16), (26, 20, 40), (50, 42, 72), (88, 80, 120), (170, 160, 210)]
FRAME = [(20, 14, 18), (40, 30, 36), (66, 52, 60), (100, 84, 92), (150, 132, 140)]
SCARF = [(90, 24, 34), (150, 48, 58), (200, 80, 86), (228, 118, 118), (250, 176, 166)]
SHELL = [(110, 50, 20), (190, 100, 50), (236, 150, 92), (252, 192, 132), (255, 232, 196)]
PAD = [(46, 22, 42), (86, 48, 80), (120, 70, 110), (160, 112, 150), (210, 170, 200)]
BAND = [(40, 22, 16), (74, 44, 32), (112, 72, 50), (150, 96, 70), (200, 150, 120)]
WOOD = [(70, 40, 20), (130, 80, 40), (180, 120, 64), (214, 160, 100), (240, 206, 150)]
STEEL = [(62, 58, 78), (118, 114, 138), (178, 176, 198), (224, 224, 238), (255, 255, 255)]
CREAM = (250, 236, 210)


def tube(c, pts, r):
    d = np.full(c.x.shape, 1e9, np.float32)
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        vx, vy = x1 - x0, y1 - y0
        t = np.clip(((c.x - x0) * vx + (c.y - y0) * vy) / max(vx * vx + vy * vy, 1e-6), 0, 1)
        d = np.minimum(d, np.hypot(c.x - (x0 + t * vx), c.y - (y0 + t * vy)))
    return (r / np.maximum(d, 1e-3)) ** 2


def arc(cx, cy, rx, ry, a0, a1, n=16):
    return [(cx + rx * math.cos(a), cy + ry * math.sin(a)) for a in np.linspace(a0, a1, n)]


def sunglasses(c):
    # temples, bridge and the brow bar behind the lenses
    bar = tube(c, [(3, 12.5), (29, 12.5)], 1.1)
    material(c, height(bar, .5), bar > 1, FRAME, bump=3, spec_amt=.5, grain=.03)
    for cx in (9.5, 22.5):
        rim = field(c, [(cx, 17, 6.4, 5.4)])
        material(c, height(rim, .5), rim > 1, FRAME, bump=4, spec_amt=.5, grain=.03)
        lens = field(c, [(cx, 17.2, 5.0, 4.1)])
        material(c, height(lens, .5), lens > 1, LENS, bump=4, spec_amt=.9, spec_pow=30, grain=.02, ao=.1)
    draw_lines(c, [[(6.5, 16.5), (9, 14.2)], [(19.5, 16.5), (22, 14.2)]], (220, 214, 240), 1.1)


def scarf(c):
    # a knitted scarf in a loop, one tail hanging down with a fringe
    loop = tube(c, arc(16, 11, 10, 5.5, 0.15 * math.pi, 0.85 * math.pi) , 3.0)
    back = tube(c, arc(16, 11, 10, 3.2, 1.1 * math.pi, 1.9 * math.pi), 2.4)
    material(c, height(back, .5), back > 1, [tuple(int(v * .78) for v in p) for p in SCARF], bump=4, spec_amt=.15, grain=.1)
    material(c, height(loop, .5), loop > 1, SCARF, bump=4, spec_amt=.2, grain=.1)
    tail = tube(c, [(21, 15), (22.5, 21), (23.5, 26)], 2.7)
    material(c, height(tail, .5), tail > 1, SCARF, bump=4, spec_amt=.2, grain=.1)
    # knit stripes
    draw_lines(c, [[(8.6, 13.8), (8.0, 17.6)], [(12.6, 15.4), (12.3, 19.4)], [(17.0, 15.8), (17.0, 19.8)],
                   [(20.4, 21.0), (24.8, 20.4)]], CREAM, 1.2)
    outline(c, c.a > .5, 1.0)
    draw_lines(c, [[(21.5 + i * 1.5, 28.2), (21.8 + i * 1.5, 30.4)] for i in range(3)], (34, 20, 22), 0.9)


def headphones(c):
    band = tube(c, arc(16, 18, 10.5, 12, math.pi * 1.04, math.pi * 1.96), 1.7)
    material(c, height(band, .5), band > 1, BAND, bump=4, spec_amt=.4, grain=.04)
    for cx, side in ((6.5, 1), (25.5, -1)):
        shell = field(c, [(cx, 21, 4.4, 5.6)])
        material(c, height(shell, .5), shell > 1, SHELL, bump=5, spec_amt=.6, spec_pow=18, grain=.04)
        pad = field(c, [(cx + side * 3.0, 21, 2.0, 4.8)])
        material(c, height(pad, .5), pad > 1, PAD, bump=4, spec_amt=.2, grain=.06)


def none(c):
    # an empty wooden coat hanger
    hook = tube(c, arc(16, 8.5, 2.6, 2.6, math.pi, 2.4 * math.pi, 12) + [(16, 12)], .8)
    material(c, height(hook, .5), hook > 1, STEEL, bump=3, spec_amt=.6, grain=.02)
    bar = tube(c, [(16, 12.5), (4, 22), (28, 22), (16, 12.5)], 1.25)
    material(c, height(bar, .5), bar > 1, WOOD, bump=4, spec_amt=.4, grain=.08)


ICONS = {'none': none, 'sunglasses': sunglasses, 'scarf': scarf, 'headphones': headphones}

if __name__ == '__main__':
    out = []
    for name, fn in ICONS.items():
        c = Canvas(32, 32, 16)
        fn(c)
        if name != 'scarf':
            outline(c, c.a > .5, 1.0)
        _, small = shrink(c)
        small.save(os.path.join(DEST, name + '.png'))
        out.append(small)
    prev = Image.new('RGBA', (len(out) * 36, 36), (236, 220, 190, 255))
    for i, im in enumerate(out):
        prev.alpha_composite(im, (i * 36 + 2, 2))
    prev.resize((prev.width * 6, prev.height * 6), Image.NEAREST).save(os.path.join(SCR, 'accessory_icons_preview.png'))
    print('ok', len(out))
