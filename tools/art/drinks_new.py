"""New drink icons (32x32, like textures/drinks/*.png): coconut water, lemonade, coffee, milk,
milkshake, smoothie.

    python3 tools/art/drinks_new.py   -> textures/drinks/<name>.png
"""
import math, os
from hires import *

DEST = os.path.join(PROJ, 'drinks')

GLASS = [(150, 168, 180), (196, 214, 222), (226, 238, 242), (244, 250, 252), (255, 255, 255)]
COCO = [(70, 44, 26), (110, 72, 44), (150, 104, 66), (184, 138, 96), (214, 176, 136)]
COCO_IN = [(200, 196, 180), (230, 228, 214), (246, 244, 236), (252, 252, 248), (255, 255, 255)]
LEMON = [(170, 140, 30), (226, 200, 60), (246, 228, 110), (252, 242, 170), (255, 252, 220)]
COFFEE = [(40, 20, 12), (80, 44, 26), (120, 72, 44), (160, 104, 66), (200, 150, 110)]
CUP = [(150, 140, 130), (206, 198, 188), (236, 232, 224), (248, 246, 240), (255, 255, 255)]
MILK = [(170, 176, 190), (214, 220, 230), (240, 242, 248), (250, 252, 255), (255, 255, 255)]
CARTON = [(60, 100, 150), (90, 140, 200), (130, 176, 226), (180, 210, 240), (230, 240, 252)]
PINK = [(150, 60, 90), (210, 110, 140), (240, 160, 186), (250, 200, 216), (255, 236, 242)]
BERRY = [(90, 20, 60), (150, 40, 90), (200, 70, 120), (230, 120, 160), (250, 190, 210)]


def rect(c, x0, y0, x1, y1):
    return (c.x >= x0) & (c.x <= x1) & (c.y >= y0) & (c.y <= y1)


def cyl_h(c, cx, hw):
    return np.clip(1 - np.abs(c.x - cx) / hw, 0, 1) ** .5


def draw(c, fn):
    im = to_image(c); d = ImageDraw.Draw(im)
    fn(d)
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


def glass(c, x0, x1, y0, y1, fill_pal, fill_top):
    """a tumbler: glass walls + the drink up to fill_top"""
    cx, hw = (x0 + x1) / 2, (x1 - x0) / 2
    m = rect(c, x0, y0, x1, y1)
    material(c, cyl_h(c, cx, hw), m, GLASS, bump=0, spec_amt=.6, grain=.02, ao=.1)
    inner = rect(c, x0 + 1.5, fill_top, x1 - 1.5, y1 - 1.5)
    material(c, cyl_h(c, cx, hw), inner, fill_pal, bump=0, spec_amt=.3, grain=.06, ao=.1)


ICONS = {}


def icon(fn):
    ICONS[fn.__name__] = fn
    return fn


@icon
def coconutwater(c):
    f = field(c, [(16, 19, 11, 10.5)])
    material(c, height(f, .5), f > 1, COCO, bump=6, grain=.18)
    top = (np.hypot(c.x - 16, (c.y - 12) * 2.2) < 7.5)
    material(c, np.ones_like(c.x) * .7, top & (f > 1), COCO_IN, bump=0, spec_amt=.2, grain=.05)
    draw(c, lambda d: d.line([c.P(19, 12), c.P(23, 3)], fill=(240, 120, 150), width=int(1.8 * c.k)))


@icon
def lemonade(c):
    glass(c, 8, 24, 7, 28, LEMON, 11)
    dots(c, 7, (10, 13, 22, 26, lambda x, y: True), [(255, 255, 240)], r=.6, seed=3)
    f = field(c, [(22, 8, 4.5, 4.5)])
    material(c, height(f, .5), (f > 1), LEMON, bump=3, spec_amt=.4, grain=.06)


@icon
def coffee(c):
    m = rect(c, 7, 11, 22, 27)
    material(c, cyl_h(c, 14.5, 7.5), m, CUP, bump=0, spec_amt=.4, grain=.03, ao=.1)
    top = np.hypot(c.x - 14.5, (c.y - 11) * 2.4) < 7.2
    material(c, np.ones_like(c.x) * .6, top, COFFEE, bump=0, spec_amt=.3, grain=.05)
    draw(c, lambda d: d.arc([*c.P(19, 14), *c.P(27, 22)], 270, 90, fill=(236, 232, 224), width=int(2.2 * c.k)))
    draw(c, lambda d: [d.line([c.P(11 + i * 4, 8), c.P(12 + i * 4, 4)], fill=(250, 250, 250), width=int(1 * c.k)) for i in range(2)])


@icon
def milk(c):
    m = rect(c, 9, 10, 23, 28)
    material(c, cyl_h(c, 16, 7), m, MILK, bump=0, spec_amt=.3, grain=.03)
    band = rect(c, 9, 15, 23, 22)
    material(c, cyl_h(c, 16, 7), band, CARTON, bump=0, spec_amt=.3, grain=.03)
    roof = (c.y >= 4) & (c.y < 10) & (np.abs(c.x - 16) <= 7 - (10 - c.y) * .6)
    material(c, np.ones_like(c.x) * .8, roof, MILK, bump=0, spec_amt=.2, grain=.03)
    draw(c, lambda d: d.ellipse([*c.P(14, 16.5), *c.P(18, 20.5)], fill=(250, 252, 255)))


@icon
def milkshake(c):
    glass(c, 9, 23, 11, 28, PINK, 12)
    f = field(c, [(16, 10, 8, 4), (16, 7, 5, 3)])
    material(c, height(f, .5), f > 1, [(200, 180, 170), (236, 224, 214), (250, 244, 238), (255, 252, 248), (255, 255, 255)], bump=3, spec_amt=.3, grain=.05)
    cherry = field(c, [(17, 3.5, 2.4, 2.4)])
    material(c, height(cherry, .5), cherry > 1, BERRY, bump=3, spec_amt=.8, grain=.03)
    draw(c, lambda d: d.line([c.P(20, 9), c.P(25, 1)], fill=(240, 120, 150), width=int(1.6 * c.k)))


@icon
def smoothie(c):
    glass(c, 9, 23, 8, 28, BERRY, 10)
    dots(c, 8, (11, 12, 21, 26, lambda x, y: True), [(250, 200, 220), (120, 30, 70)], r=.5, seed=5)
    f = field(c, [(22.5, 9, 3.6, 2.6)])
    material(c, height(f, .5), f > 1, [(40, 80, 30), (70, 130, 50), (110, 170, 70), (160, 210, 110), (210, 240, 170)], bump=3, grain=.08)


if __name__ == '__main__':
    out = []
    for name, fn in ICONS.items():
        c = Canvas(32, 32, 16)
        fn(c)
        outline(c, c.a > .5, 1.0)
        _, small = shrink(c)
        small.save(os.path.join(DEST, name + '.png'))
        out.append(small)
    prev = Image.new('RGBA', (len(out) * 36, 36), (236, 220, 190, 255))
    for i, im in enumerate(out):
        prev.alpha_composite(im, (i * 36 + 2, 2))
    prev.resize((prev.width * 4, prev.height * 4), Image.NEAREST).save(os.path.join(SCR, 'drinks_new_preview.png'))
    print('ok', len(out))
