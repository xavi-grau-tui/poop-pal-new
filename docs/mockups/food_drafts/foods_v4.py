"""Food round 4 (user, 2026-10-11): from round 3 keep the greens, Pancakes and Ceviche (with less
glass); redo the Pizza Slice; invent the rest again, in the look of the originals (big chunky
shapes filling the box, warm muted colours, painted grain, strong outline).
Round 4b (same day, "mind sizes"): every new food fills the box like the originals (about 30 x 26-30,
seen a little from above rather than flat from the side), and the Ceviche sits inside its bowl.
    python foods_v4.py   -> icons4/<name>.png + foods4_sheet.png"""
import os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import foods_draft as fd
import foods_v3 as v3
from hires import field, height, material, seam, dots
from foods_draft import (B, sq, M, L, ell, draw, OUTC, BREAD, PLATE, CHOC, CREAM, BLUE, VEG, RED, MEAT, LEMON,
                         PASTRY, EGG, YOLK, FRY, BOX, GLASS, LIME)
from foods_v3 import food, NEW, FISH, ONION, LIMEPULP, CHEESE, PEPPERONI

HERE = os.path.dirname(os.path.abspath(__file__))
OUTA = np.array(OUTC, np.float32)

SHELL = [(40, 52, 86), (70, 90, 136), (106, 130, 178), (146, 168, 208), (192, 208, 236)]      # sweet blue
SHELLFOOT = [(70, 90, 136), (106, 130, 178), (146, 168, 208), (180, 198, 228), (214, 226, 246)]
DORA = [(90, 44, 18), (146, 82, 34), (190, 120, 56), (220, 160, 92), (242, 200, 140)]
ANKO = [(40, 14, 14), (70, 26, 24), (100, 42, 36), (128, 62, 52), (160, 92, 80)]
RINGFRY = [(150, 92, 20), (204, 140, 40), (234, 184, 72), (248, 214, 120), (255, 238, 180)]
BUCKETW = [(170, 160, 150), (216, 210, 200), (240, 236, 228), (250, 248, 242), (255, 255, 252)]
CHICKEN = [(110, 52, 16), (164, 92, 30), (204, 132, 52), (230, 170, 86), (248, 206, 134)]
CHIP = [(160, 96, 20), (212, 144, 40), (238, 182, 70), (250, 212, 112), (255, 236, 170)]
CHORIZO = [(70, 12, 12), (130, 26, 22), (176, 46, 34), (208, 82, 60), (232, 130, 104)]
IRON = [(18, 16, 18), (34, 32, 36), (54, 52, 58), (78, 76, 84), (110, 108, 118)]
SAUCE = v3.SAUCE
APPLE = [(40, 84, 20), (76, 136, 34), (118, 182, 56), (164, 214, 92), (214, 240, 156)]
GRIND = [(180, 120, 20), (226, 166, 40), (246, 204, 80), (252, 228, 136), (255, 246, 200)]
BOWLW_ = [(120, 126, 130), (176, 184, 188), (214, 220, 222), (238, 242, 242), (255, 255, 255)]
DORAEDGE = [(150, 96, 40), (204, 148, 78), (232, 186, 116), (246, 214, 156), (255, 236, 196)]   # the pale rims
DORATOP = [(64, 26, 10), (108, 52, 20), (150, 84, 36), (188, 120, 60), (222, 166, 100)]       # the browned tops
PITH = [(220, 200, 170), (240, 226, 204), (250, 240, 224), (254, 248, 238), (255, 252, 248)]
GPINK = [(170, 30, 50), (220, 64, 76), (240, 104, 108), (250, 146, 140), (255, 196, 186)]
TERRA = [(96, 42, 26), (150, 74, 44), (194, 108, 64), (224, 146, 94), (244, 190, 140)]       # a clay bowl
TIGRE = [(150, 164, 112), (196, 206, 160), (224, 230, 192), (240, 244, 218), (252, 254, 240)]  # milky lime juice
CAMOTE = [(150, 60, 10), (210, 106, 24), (240, 150, 50), (252, 190, 96), (255, 226, 160)]
GFLESH = [(150, 40, 50), (206, 76, 82), (236, 120, 118), (248, 166, 156), (255, 210, 200)]


def at(c, arr, x, y):
    """an array's value at the design point (x, y)"""
    px, py = c.P(x, y)
    return arr[min(max(int(py), 0), arr.shape[0] - 1), min(max(int(px), 0), arr.shape[1] - 1)]


def band(c, cx, cy0, cy1, rx, ry, pal, **kw):
    """an upright disc seen a little from above, top ellipse at cy0 and bottom one at cy1 (its whole
    silhouette, shaded like a puffy side; paint the top face over it)"""
    u = np.clip(1 - ((c.x - cx) / rx) ** 2, 0, 1)
    s = ry * np.sqrt(u)
    t = np.clip((c.y - cy0 - s) / max(cy1 - cy0, .1), 0, 1)
    m = (np.abs(c.x - cx) < rx) & (c.y > cy0 - s) & (c.y < cy1 + s)
    h = np.sqrt(u) * .8 + np.sqrt(np.clip(1 - (2 * t - 1) ** 2, 0, 1)) * .5
    material(c, h, m, pal, **{**dict(bump=4, spec_amt=.3, grain=.12, ao=.3), **kw})
    return m


@food('sweet', 'baby', 'Macaron')
def macaron(c):
    bot = sq(c, 16, 21.5, 13, 4.6, 3)
    M(c, bot, bot > 1, SHELL, spec_amt=.35, grain=.14)
    cr = sq(c, 16, 16.2, 12.4, 2.2, 4)
    M(c, cr, cr > 1, CREAM, spec_amt=.3, grain=.1)
    for yy in (18.6, 13.6):                    # the shells' ruffled "feet"
        ft = sq(c, 16, yy, 13.3, 1.3, 4)
        M(c, ft & (np.sin(c.x * 3.2) > -.6) if False else ft, ft > 1, SHELLFOOT, spec_amt=.2, grain=.2)
    top = field(c, [(16, 9.5, 13, 5.8)])
    M(c, top, (top > 1) & (c.y < 12.8), SHELL, spec_amt=.55, spec_pow=16, grain=.12)


@food('sweet', 'kid', 'Dorayaki')
def dorayaki(c):
    # seen a little from above: two puffy pancakes, the dark bean paste between them, the top browned
    # (dark in the middle, golden at the rim)
    band(c, 16, 19.5, 23.2, 13.4, 8, DORAEDGE)
    band(c, 16, 17.2, 19.6, 13.9, 8.2, ANKO, spec_amt=.5, spec_pow=14, grain=.16)
    band(c, 16, 13.2, 17.2, 13.4, 8, DORAEDGE)
    top = field(c, [(16, 13.2, 13.4, 8)])
    M(c, top, top > 1, DORAEDGE, spec_amt=.3, grain=.12)
    brown = field(c, [(16, 12.9, 11.2, 6.4)])
    material(c, np.clip(height(top, .5), 0, 1), brown > 1, DORATOP, bump=4, spec_amt=.45, spec_pow=16, grain=.14, ao=.3)


@food('greasy', 'baby', 'Onion Rings')
def onionrings(c):
    # a little pile of three rings, seen a little from above
    rr = np.random.default_rng(4)
    for (x, y, R, w) in [(9.8, 21.5, 8.4, 2.7), (22.2, 21.5, 8.4, 2.7), (16, 10, 8.8, 2.8)]:
        d = np.hypot(c.x - x, (c.y - y) / .85)
        ring = np.abs(d - R + w) < w
        hh = np.clip(1 - np.abs(d - R + w) / w, 0, 1) ** .5
        micro = [(rr.uniform(x - R, x + R), rr.uniform(y - R, y + R), 1.3, 1.3, .3) for _ in range(30)]
        material(c, np.clip(hh * .8 + height(field(c, micro), .6) * .3, 0, 1.3), ring, RINGFRY, bump=6, spec_amt=.35, grain=.2, ao=.4)
        seam(c, ring, (c.a > .5) & ~ring, .4, OUTA)


@food('greasy', 'kid', 'Pizza Slice')
def pizzaslice(c):
    # a big slice tipped a little, the crust a thick arc at the top, pepperoni scattered (no face!)
    tri = (c.y > 6.5) & (c.y < 31) & (np.abs(c.x - 16 - (c.y - 6.5) * .12) < (31 - c.y) * .62 + .4)
    hh = np.clip((31 - c.y) / 25, 0, 1) ** .25
    material(c, hh, tri, CHEESE, bump=5, spec_amt=.5, spec_pow=14, grain=.16, ao=.3)
    dots(c, 12, (4, 9, 28, 28, lambda x, y: c.alpha_at(x, y) > .5), [(214, 134, 30), (196, 116, 22)], r=.9, seed=12, angle=False)
    for (x, y, r) in [(9.5, 11, 3.0), (21, 10, 2.7), (16.5, 15.5, 3.1), (13, 20.5, 2.4), (19.5, 23.5, 2.1)]:
        B(c, [(x, y, r, r * .92)], PEPPERONI, spec_amt=.55, spec_pow=14, grain=.1)
    crust = field(c, [(16, 6, 15.5, 3.8)])
    M(c, crust, crust > 1, BREAD, spec_amt=.3, grain=.18)
    for x in (7.5, 24):
        dr = field(c, [(x + 1, 25 - abs(x - 16) * .5, 1.3, 2.4)])
        material(c, np.clip(height(dr, .5), 0, 1), dr > 1, CHEESE, bump=3, spec_amt=.6, grain=.08)


@food('greasy', 'adult', 'Fried Chicken')
def friedchicken(c):
    rr = np.random.default_rng(6)
    for (x, y, a) in [(9, 10.5, -.5), (16.5, 8.5, 0), (24, 10.5, .5)]:
        bone = [(x + math.sin(a) * 5.4, y - 5.4, 1.1, 2.0), (x + math.sin(a) * 6, y - 7.2, 1.5, 1.3)]
        B(c, bone, BUCKETW, spec_amt=.4, grain=.06)
        f = field(c, [(x, y, 5.2, 5.6), (x + math.sin(a) * 2.5, y - 3, 3.2, 3.2)])
        micro = [(x + rr.uniform(-5, 5), y + rr.uniform(-5, 5), 1.3, 1.3, .3) for _ in range(14)]
        material(c, np.clip(height(f, .5) * .8 + height(field(c, micro), .6) * .35, 0, 1.3), f > 1, CHICKEN, bump=6, spec_amt=.3, grain=.2, ao=.45)
        seam(c, f > 1, (c.a > .5) & ~(f > 1), .4, OUTA)
    bk = (c.y > 13) & (c.y < 30.5) & (np.abs(c.x - 16) < 14.6 - (c.y - 13) * .16)
    hb = np.clip(1 - np.abs(c.x - 16) / 15, 0, 1) ** .45
    stripe = bk & (np.abs(((c.x - 16) / 5.4) % 1 - .5) < .26)
    material(c, hb, bk & ~stripe, BOX, bump=3, spec_amt=.3, grain=.08)
    material(c, hb, stripe, BUCKETW, bump=3, spec_amt=.3, grain=.06)
    rim = sq(c, 16, 13.6, 15.2, 1.6, 4)
    M(c, rim, rim > 1, BUCKETW, spec_amt=.4, grain=.06)


@food('spicy', 'baby', 'Spicy Chip')
def spicychip(c):
    pts = np.stack([c.x, c.y], -1)
    a, b, cc = np.array([2.5, 27.5]), np.array([29.5, 23.5]), np.array([12.5, 3.0])

    def side(p, q):
        return (q[0] - p[0]) * (pts[..., 1] - p[1]) - (q[1] - p[1]) * (pts[..., 0] - p[0])
    inside = (side(a, b) <= 0) & (side(b, cc) <= 0) & (side(cc, a) <= 0)
    cen = (a + b + cc) / 3
    hh = np.clip(1 - np.hypot(c.x - cen[0], c.y - cen[1]) / 16, 0, 1) ** .4
    material(c, hh, inside, CHIP, bump=4, spec_amt=.35, grain=.2)
    dots(c, 26, (4, 4, 28, 27, lambda x, y: c.alpha_at(x, y) > .5), [(200, 54, 28), (176, 40, 24), (226, 90, 40)], r=.75, seed=3, angle=False)


@food('spicy', 'kid', 'Chorizo')
def chorizo(c):
    # two long curved sausages, tied together by a string
    for (p0, p1, bend, r) in [((3.5, 25), (17, 23.5), 2.6, 3.4), ((15.5, 16.5), (28.5, 6.5), 2.4, 3.3)]:
        (x0, y0), (x1, y1) = p0, p1
        nx, ny = -(y1 - y0), (x1 - x0)
        Ln = math.hypot(nx, ny)
        balls = []
        for t in np.linspace(0, 1, 12):
            b = math.sin(t * math.pi) * bend
            rr_ = r * (0.75 + 0.25 * math.sin(t * math.pi))
            balls.append((x0 + (x1 - x0) * t + nx / Ln * b, y0 + (y1 - y0) * t + ny / Ln * b, rr_, rr_))
        f = field(c, balls)
        M(c, f, f > 1, CHORIZO, spec_amt=.65, spec_pow=14, grain=.12)
        seam(c, f > 1, (c.a > .5) & ~(f > 1), .4, OUTA)
    L(c, [[(17.5, 22.5), (16, 19.5), (16.5, 17)]], (236, 220, 190), 1.0)
    dots(c, 9, (3, 5, 30, 29, lambda x, y: c.alpha_at(x, y) > .5), [(240, 208, 190)], r=.5, seed=5, angle=False)


@food('spicy', 'adult', 'Shakshuka')
def shakshuka(c):
    # the pan seen from above, its handle up and to the right, three eggs in the tomato sauce
    L(c, [[(25, 8), (29.5, 2.5)]], (40, 36, 40), 2.8)
    pan = field(c, [(15.5, 17.5, 13.8, 11.6)])
    M(c, pan, pan > 1, IRON, spec_amt=.5, grain=.08)
    sa = field(c, [(15.5, 16.8, 11.8, 9.6)])
    M(c, sa, sa > 1, SAUCE, spec_amt=.55, spec_pow=14, grain=.14)
    for (x, y) in [(10.5, 15), (20, 13.5), (16, 21)]:
        B(c, [(x, y, 3.8, 3.1)], EGG, spec_amt=.5, grain=.06)
        B(c, [(x + .3, y - .3, 1.8, 1.6)], YOLK, spec_amt=.8, spec_pow=12, grain=.04)
    dots(c, 10, (4, 8, 27, 26, lambda x, y: c.alpha_at(x, y) > .5), [(90, 150, 60), (60, 120, 40)], r=.7, seed=8, angle=True)


@food('sour', 'baby', 'Green Apple')
def greenapple(c):
    f = field(c, [(11, 18, 9.5, 10.5), (21, 18, 9.5, 10.5), (16, 22, 9, 8)])
    M(c, f, f > 1, APPLE, spec_amt=.65, spec_pow=14, grain=.1)
    draw(c, lambda d: d.ellipse([*c.P(13.5, 6.5), *c.P(18.5, 9.5)], fill=(60, 110, 30)))
    L(c, [[(16, 9), (16.5, 5), (18, 2.5)]], (90, 60, 30), 1.5)
    B(c, [(21.5, 4, 3.6, 1.8)], VEG, spec_amt=.3)


@food('sour', 'kid', 'Grapefruit')
def grapefruit(c):
    # half a grapefruit seen from above: the pink segments in a ring of white pith, the peel below
    B(c, [(16, 19, 14.5, 11)], GRIND, spec_amt=.45, grain=.12)
    pith = field(c, [(16, 14.5, 14.2, 9.8)])
    M(c, pith, pith > 1, PITH, spec_amt=.2, grain=.08)
    fl = field(c, [(16, 14.5, 12.5, 8.4)])
    M(c, fl, fl > 1, GPINK, spec_amt=.6, spec_pow=14, grain=.12)
    draw(c, lambda d: [d.line([c.P(16, 14.5), c.P(16 + math.cos(k * math.pi / 5) * 12.5, 14.5 + math.sin(k * math.pi / 5) * 8.4)], fill=(252, 236, 228), width=int(.6 * c.k * c.z)) for k in range(10)])
    B(c, [(16, 14.5, 1.8, 1.3)], [(230, 214, 204), (246, 232, 226), (252, 244, 240), (255, 250, 248), (255, 255, 255)], spec_amt=.2)


@food('sour', 'adult', 'Ceviche')
def ceviche(c):
    # a clay bowl seen from above (like the Tom Yum and the Curry) with the ceviche INSIDE it: white fish
    # cubes in milky lime juice, red onion, coriander, a slice of sweet potato and a lime wedge
    body = field(c, [(16, 17.5, 14.4, 12)])
    M(c, body, (body > 1) & (c.y > 15), TERRA, spec_amt=.4, grain=.1)
    rim = field(c, [(16, 15, 14.4, 10.8)])
    M(c, rim, rim > 1, TERRA, spec_amt=.5, grain=.08)
    wall = field(c, [(16, 15.4, 12.4, 8.8)])
    m_in = wall > 1
    material(c, 1 - np.clip(height(wall, .5), 0, 1), m_in, TERRA, bump=4, spec_amt=.1, grain=.1, ao=.2)
    juice = field(c, [(16, 16.4, 12, 7.8)])
    m_j = (juice > 1) & m_in
    material(c, np.clip(height(juice, .5), 0, 1) * .3, m_j, TIGRE, bump=2, spec_amt=.4, grain=.08)
    B(c, [(9, 16.5, 3.2, 2.4)], CAMOTE, spec_amt=.5, grain=.08)
    w = ell(c, 22.5, 12.5, 4, 3) & (c.y < 13.6)
    material(c, np.clip(height(field(c, [(22.5, 12.5, 4, 3)]), .5), 0, 1), w, LIME, bump=4, spec_amt=.5, grain=.08)
    for (x, y) in [(13, 13.5), (17, 13), (11.5, 18.5), (15.5, 17.5), (19.5, 16.5), (23.5, 17), (14, 21.5), (18.5, 21), (22, 20.5)]:
        f = sq(c, x, y, 1.9, 1.6, 4)
        material(c, np.clip(height(f, .5), 0, 1), (f > 1) & m_in, FISH, bump=4, spec_amt=.45, grain=.08)
        seam(c, f > 1, (c.a > .5) & ~(f > 1) & m_in, .3, OUTA)
    L(c, [[(9.5, 13), (11.5, 11.8), (13.5, 12.2)], [(20, 19), (21.5, 18.2), (23.5, 18.8)], [(15, 15.6), (17, 15), (18.5, 15.4)]], (150, 50, 110), .9)
    dots(c, 8, (6, 10, 26, 23, lambda x, y: at(c, m_j, x, y)), [(70, 140, 50), (50, 110, 40)], r=.6, seed=6, angle=True)


import food_new
food_new.FIT.update({'greenapple': .92})       # (a solid ball looks bigger than its box)

ORDER4 = ['edamame', 'avocadotoast', 'bento', 'macaron', 'dorayaki', 'pancakes', 'onionrings', 'pizzaslice',
          'friedchicken', 'spicychip', 'chorizo', 'shakshuka', 'greenapple', 'grapefruit', 'ceviche']

if __name__ == '__main__':
    os.makedirs(os.path.join(HERE, 'icons4'), exist_ok=True)
    ims = []
    for name in ORDER4:
        im = fd.render(name)
        im.save(os.path.join(HERE, 'icons4', name + '.png'))
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
    sh.save(os.path.join(HERE, 'foods4_sheet.png'))
    print('sheet ok')
