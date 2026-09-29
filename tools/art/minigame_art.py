"""Sprites for Poo Splash (water ring toy) and Poo Dash (runner).

Shapes are drawn as masks at high resolution, given a rounded height from their distance
to the edge, shaded + outlined with the hires helpers and shrunk (same look as the pals).
Everything is 1 texel = 1 art pixel; the games draw them at x3.
Needs scipy on top of pillow/numpy.
"""
import math, os
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

from hires import Canvas, material, outline, shrink, paint, SCR, PROJ, OUT
from forms import BROWN, PINK, VAN, GREEN, CHEESE

K = 12
SPLASH = os.path.join(PROJ, 'minigames', 'splash')
DASH = os.path.join(PROJ, 'minigames', 'dash')

RING_PALS = {
    'pink':   [(120, 30, 70), (200, 70, 120), (240, 120, 160), (255, 176, 204), (255, 230, 240)],
    'yellow': [(140, 90, 10), (220, 160, 30), (250, 206, 70), (255, 232, 130), (255, 250, 214)],
    'mint':   [(20, 90, 70), (40, 160, 120), (100, 214, 170), (164, 240, 206), (226, 255, 240)],
    'blue':   [(30, 60, 130), (60, 110, 200), (110, 164, 240), (170, 206, 255), (230, 242, 255)],
}
BALL_PALS = {k: RING_PALS[k] for k in ('pink', 'yellow', 'mint')}
WHITE_PLASTIC = [(120, 110, 120), (200, 192, 200), (236, 230, 236), (250, 246, 250), (255, 255, 255)]
WOOD = [(90, 50, 24), (150, 92, 48), (196, 136, 80), (226, 176, 116), (250, 220, 170)]
RED = [(100, 16, 24), (170, 34, 42), (220, 70, 70), (246, 120, 110), (255, 200, 190)]
FLY = [(20, 16, 28), (40, 34, 56), (70, 62, 90), (110, 100, 130), (170, 160, 190)]


def canvas(w, h):
    return Canvas(w, h, K, 1.0)


def hmask(draw_fn, c):
    """Draw a shape at hi-res with PIL (coords in art pixels), return mask."""
    im = Image.new('L', (c.w * K, c.h * K), 0)
    d = ImageDraw.Draw(im)
    draw_fn(d, lambda v: v * K)
    return np.asarray(im) > 127


def bevel(mask, px=2.5):
    return np.clip(ndimage.distance_transform_edt(mask) / (px * K), 0, 1) ** 0.6


def solid(c, mask, pal, px=2.5, **kw):
    kw.setdefault('grain', 0.04)
    kw.setdefault('spec_amt', 0.5)
    material(c, bevel(mask, px), mask, pal, **kw)


def done(c, path, line=True, alpha_cut=120):
    if line:
        outline(c, c.a > .5, 1.0)
    _, small = shrink(c, alpha_cut)
    small.save(path)
    return small


# ------------------------------------------------------------------ POO SPLASH
def ring(pal, path):
    c = canvas(22, 22)
    d = np.hypot(c.x - 11, c.y - 11)
    R, t = 7.2, 3.4
    m = np.abs(d - R) < t
    h = np.sqrt(np.clip(t ** 2 - (d - R) ** 2, 0, None)) / t
    material(c, h, m, pal, bump=4, spec_amt=.6, spec_pow=18, grain=.03)
    return done(c, path)


def ball(pal, path):
    c = canvas(13, 13)
    d = np.hypot(c.x - 6.5, c.y - 6.5)
    m = d < 5.2
    material(c, np.sqrt(np.clip(1 - (d / 5.2) ** 2, 0, 1)), m, pal, bump=4, spec_amt=.7, spec_pow=16, grain=.03)
    return done(c, path)


def peg(path):
    c = canvas(10, 60)
    stick = hmask(lambda d, s: d.rounded_rectangle([s(3.6), s(6), s(6.4), s(56)], s(1.2), fill=255), c)
    solid(c, stick, WHITE_PLASTIC, 1.4)
    cap = hmask(lambda d, s: d.ellipse([s(2), s(1), s(8), s(7)], fill=255), c)
    solid(c, cap, RING_PALS['pink'], 3)
    base = hmask(lambda d, s: d.rounded_rectangle([s(0.5), s(54), s(9.5), s(59.5)], s(1.5), fill=255), c)
    solid(c, base, RING_PALS['pink'], 2)
    return done(c, path)


def cup(back_path, front_path):
    """A little basket: back = its dark inside, front = the wall in front of the ball."""
    W, H = 30, 26
    c = canvas(W, H)
    inside = hmask(lambda d, s: d.polygon([(s(3), s(4)), (s(27), s(4)), (s(23), s(24)), (s(7), s(24))], fill=255), c)
    paint(c, inside, np.array([70, 40, 60], np.float32))
    done(c, back_path)
    c = canvas(W, H)
    wall = hmask(lambda d, s: d.polygon([(s(2), s(9)), (s(28), s(9)), (s(24), s(25)), (s(6), s(25))], fill=255), c)
    solid(c, wall, RING_PALS['blue'], 3)
    rim = hmask(lambda d, s: d.rounded_rectangle([s(0.5), s(3), s(29.5), s(8.5)], s(2), fill=255), c)
    solid(c, rim, RING_PALS['yellow'], 2)
    # stripes on the wall
    for x0 in (9, 15, 21):
        stripe = hmask(lambda d, s, x0=x0: d.polygon([(s(x0 - 1), s(10)), (s(x0 + 1), s(10)), (s(x0 + 0.6 - (x0 - 15) * .15), s(24)), (s(x0 - 0.6 - (x0 - 15) * .15), s(24))], fill=255), c)
        paint(c, stripe & wall, np.array([150, 190, 250], np.float32))
    done(c, front_path)


def cup_rim_net(front_path, rim_path, net_path):
    """Split the basket front into a solid rim and a see-through mesh net, so balls are
    seen falling through the basket."""
    f = np.asarray(Image.open(front_path).convert('RGBA')).copy()
    H, W = f.shape[:2]
    rim = f.copy(); rim[10:] = 0
    body = f.copy(); body[:10] = 0
    fill = body[..., 3] > 0
    edge = fill & (body[..., :3].astype(int).sum(-1) < 200)
    yy, xx = np.mgrid[0:H, 0:W]
    mesh = ((xx + yy) % 4 == 0) | ((xx - yy) % 4 == 0)
    body[..., 3] = np.where(edge, 255, np.where(fill & mesh, 230, np.where(fill, 70, 0)))
    Image.fromarray(rim).save(rim_path)
    Image.fromarray(body).save(net_path)


def nozzle(path):
    c = canvas(22, 11)
    m = hmask(lambda d, s: (d.chord([s(2), s(1), s(20), s(19)], 180, 360, fill=255), d.rectangle([s(0), s(9), s(22), s(11)], fill=255)), c)
    solid(c, m, WHITE_PLASTIC, 3)
    hole = hmask(lambda d, s: d.ellipse([s(8), s(1.5), s(14), s(4.5)], fill=255), c)
    paint(c, hole, np.array([60, 60, 80], np.float32))
    return done(c, path)


def bubble(path, r):
    n = int(r * 2 + 3)
    c = canvas(n, n)
    d = np.hypot(c.x - n / 2, c.y - n / 2)
    ring_m = (d < r) & (d > r - 1.0)
    paint(c, ring_m, np.array([240, 252, 255], np.float32))
    c.a[ring_m] = 0.9
    glint = np.hypot(c.x - n / 2 + r * .35, c.y - n / 2 + r * .35) < max(0.8, r * .3)
    paint(c, glint, np.array([255, 255, 255], np.float32))
    return done(c, path, line=False, alpha_cut=90)


NOZZLES_ART = (79.0, 237.7)          # nozzle x in art px (x3 = 237, 713 in the game)
FLOOR_ART = 866.0 / 3                 # floor height right at a nozzle
SLOPE = 0.42


def funnel_floor(x):
    d = np.minimum(np.abs(x - NOZZLES_ART[0]), np.abs(x - NOZZLES_ART[1]))
    return FLOOR_ART - SLOPE * d


def pin(path):
    c = canvas(7, 7)
    d = np.hypot(c.x - 3.5, c.y - 3.5)
    m = d < 2.6
    material(c, np.sqrt(np.clip(1 - (d / 2.6) ** 2, 0, 1)), m, WHITE_PLASTIC, bump=3, spec_amt=.8, spec_pow=12, grain=0)
    return done(c, path)


def tank(path, W=317, H=316):
    """Water tank backdrop: plastic frame, water gradient, light rays, sandy floor."""
    y = np.arange(H)[:, None].repeat(W, 1).astype(np.float32)
    x = np.arange(W)[None, :].repeat(H, 0).astype(np.float32)
    top, bot = np.array([176, 228, 232]), np.array([104, 178, 204])
    t = (y / H)[..., None]
    img = top * (1 - t) + bot * t
    # soft light rays from the top-left
    rays = (np.sin((x * .9 + y * .35) * .045) * .5 + .5) ** 6 * np.clip(1 - y / (H * .8), 0, 1)
    img += rays[..., None] * 30
    # gentle wave lines near the surface
    for k, yy in enumerate((18, 30, 44)):
        wave = np.abs(y - (yy + 2.5 * np.sin(x * .09 + k))) < .8
        img[wave] = img[wave] * .7 + np.array([235, 250, 250]) * .3
    # two funnels: the floor slopes down to each nozzle, so balls always roll back to a pump
    fy = funnel_floor(x)
    floor = y > fy
    plastic = np.array([236, 140, 170]) * (1 - (y - fy)[..., None].clip(0, 40) / 160)
    img[floor] = plastic[floor]
    top_line = (y > fy) & (y <= fy + 2)
    img[top_line] = [255, 196, 214]
    edge = (y > fy - 1.2) & (y <= fy)
    img[edge] = OUT
    img = np.clip(img, 0, 255).astype(np.uint8)
    out = Image.fromarray(img, 'RGB').convert('RGBA')
    # no frame: the water fills the console screen edge to edge
    d = ImageDraw.Draw(out)
    out.save(path)
    return out


# ------------------------------------------------------------------ POO DASH
def ground_tiles(top_path, fill_path):
    """16x16 tileable blocks: a creamy frosting top over chocolate soil."""
    rng = np.random.default_rng(11)
    soil = np.zeros((16, 16, 3))
    base = np.array(BROWN[2], float)
    for y in range(16):
        soil[y] = base * (1.0 - y * .012)
    soil += (rng.random((16, 16, 1)) - .5) * 14
    for _ in range(6):                                   # darker pebbles
        px_, py_ = rng.integers(0, 15), rng.integers(0, 15)
        soil[py_, px_:px_ + 2] = BROWN[1]
    fill = Image.fromarray(np.clip(soil, 0, 255).astype(np.uint8), 'RGB').convert('RGBA')
    fill.save(fill_path)
    top = np.array(fill)[..., :3].astype(float).copy()
    for x in range(16):
        h = 5 + round(1.2 * math.sin(x / 16 * 2 * math.pi))      # tiles every 16 px
        top[:h, x] = VAN[2]
        top[0, x] = OUT
        top[1, x] = VAN[4]
        top[h - 1, x] = VAN[1]
        top[h, x] = BROWN[0]
    Image.fromarray(np.clip(top, 0, 255).astype(np.uint8), 'RGB').convert('RGBA').save(top_path)


def plunger(path):
    c = canvas(16, 28)
    stick = hmask(lambda d, s: d.rounded_rectangle([s(6.5), s(3), s(9.5), s(20)], s(1), fill=255), c)
    solid(c, stick, WOOD, 1.5)
    knob = hmask(lambda d, s: d.ellipse([s(5), s(0.5), s(11), s(5.5)], fill=255), c)
    solid(c, knob, WOOD, 2.5)
    cup_m = hmask(lambda d, s: (d.chord([s(1), s(18), s(15), s(34)], 180, 360, fill=255), d.rectangle([s(0.5), s(25), s(15.5), s(27.5)], fill=255)), c)
    solid(c, cup_m, RED, 3.5, spec_amt=.7)
    return done(c, path)


def fly(path_a, path_b):
    for wing_up, path in ((True, path_a), (False, path_b)):
        c = canvas(18, 14)
        wing = hmask(lambda d, s: (d.ellipse([s(3), s(0.5 if wing_up else 7), s(9), s(6.5 if wing_up else 11)], fill=255),
                                   d.ellipse([s(8), s(0 if wing_up else 7.5), s(15), s(6 if wing_up else 11.5)], fill=255)), c)
        paint(c, wing, np.array([220, 236, 250], np.float32))
        c.a[wing] = .85
        body = hmask(lambda d, s: d.ellipse([s(3), s(5), s(15), s(13)], fill=255), c)
        solid(c, body, FLY, 3, spec_amt=.6)
        for ex in (10.5, 13.2):
            eye = hmask(lambda d, s, ex=ex: d.ellipse([s(ex - 1.6), s(6.3), s(ex + 1.6), s(9.5)], fill=255), c)
            paint(c, eye, np.array([230, 60, 70], np.float32))
            glint = hmask(lambda d, s, ex=ex: d.ellipse([s(ex - 1), s(6.6), s(ex), s(7.6)], fill=255), c)
            paint(c, glint, np.array([255, 230, 230], np.float32))
        done(c, path)


def corn(path):
    c = canvas(10, 12)
    m = hmask(lambda d, s: d.polygon([(s(5), s(11.3)), (s(1), s(5)), (s(2), s(1.5)), (s(5), s(0.7)), (s(8), s(1.5)), (s(9), s(5))], fill=255), c)
    solid(c, m, CHEESE, 3, spec_amt=.8, spec_pow=14)
    return done(c, path)


# ------------------------------------------------------------------ POO BREAK
BREAK = os.path.join(PROJ, 'minigames', 'break')
TILE_PALS = {
    'pink': RING_PALS['pink'], 'yellow': RING_PALS['yellow'], 'mint': RING_PALS['mint'],
    'blue': RING_PALS['blue'], 'lilac': [(70, 40, 110), (130, 90, 190), (176, 140, 230), (214, 190, 250), (244, 232, 255)],
    'gold': [(110, 70, 10), (190, 130, 20), (240, 190, 50), (255, 224, 120), (255, 250, 220)],
}


def tp_roll(path, w=44):
    """Toilet-paper roll lying on its side: the paddle. Drawn in 3 slices (left end, middle, right end)
    so the game can stretch the middle when the paddle grows."""
    c = canvas(w, 12)
    body = hmask(lambda d, s: d.rounded_rectangle([s(3), s(0.5), s(w - 3), s(11.5)], s(3), fill=255), c)
    y = c.y
    h = np.sqrt(np.clip(1 - ((y - 6) / 5.6) ** 2, 0, 1))          # a cylinder along x
    material(c, h, body, WHITE_PLASTIC, bump=3, spec_amt=.35, grain=.05)
    # perforation lines
    for x0 in range(9, w - 6, 8):
        perf = hmask(lambda d, s, x0=x0: d.line([(s(x0), s(1.5)), (s(x0), s(10.5))], fill=255, width=int(0.8 * K)), c)
        paint(c, perf & body, np.array([200, 196, 206], np.float32))
    for ex in (3.2, w - 3.2):                                        # cardboard tube ends
        end = hmask(lambda d, s, ex=ex: d.ellipse([s(ex - 2.6), s(1), s(ex + 2.6), s(11)], fill=255), c)
        solid(c, end, WOOD, 1.5)
        hole = hmask(lambda d, s, ex=ex: d.ellipse([s(ex - 1.2), s(3.6), s(ex + 1.2), s(8.4)], fill=255), c)
        paint(c, hole, np.array([70, 40, 24], np.float32))
    return done(c, path)


def tile(pal, path, cracked=False):
    c = canvas(24, 11)
    m = hmask(lambda d, s: d.rounded_rectangle([s(0.8), s(0.8), s(23.2), s(10.2)], s(1.6), fill=255), c)
    solid(c, m, pal, 2.2, spec_amt=.55)
    gl = hmask(lambda d, s: d.line([(s(3), s(2.5)), (s(9), s(2.5))], fill=255, width=int(1.1 * K)), c)
    paint(c, gl & m, np.array(pal[-1], np.float32))
    if cracked:
        cr = hmask(lambda d, s: d.line([(s(13), s(1)), (s(11), s(4)), (s(14), s(6)), (s(12), s(10))], fill=255, width=int(0.9 * K)), c)
        paint(c, cr & m, np.array(pal[0], np.float32))
    return done(c, path)


def capsule(pal, path):
    c = canvas(18, 9)
    m = hmask(lambda d, s: d.rounded_rectangle([s(0.8), s(0.8), s(17.2), s(8.2)], s(3.6), fill=255), c)
    solid(c, m, pal, 3.5, spec_amt=.7)
    return done(c, path)


# ------------------------------------------------------------------ GERM ZAP
GERM = os.path.join(PROJ, 'minigames', 'germ')
GERM_PALS = {
    'coccus': [(20, 70, 30), (50, 140, 60), (110, 200, 90), (170, 236, 140), (230, 255, 210)],
    'bacillus': [(60, 20, 90), (110, 50, 160), (160, 100, 220), (206, 160, 250), (240, 226, 255)],
    'virus': [(100, 20, 50), (180, 40, 90), (236, 90, 130), (255, 150, 180), (255, 220, 232)],
}


def germ_face(c, cx, cy, spread, frame):
    """Tiny grumpy face: two eyes (blink on frame 2), frown."""
    for ex in (cx - spread, cx + spread):
        if frame == 0:
            eye = hmask(lambda d, s, ex=ex: d.ellipse([s(ex - 1.3), s(cy - 1.5), s(ex + 1.3), s(cy + 1.5)], fill=255), c)
            paint(c, eye, np.array([255, 255, 255], np.float32))
            pup = hmask(lambda d, s, ex=ex: d.ellipse([s(ex - 0.7), s(cy - 0.5), s(ex + 0.7), s(cy + 1.3)], fill=255), c)
            paint(c, pup, np.array([20, 10, 20], np.float32))
        else:
            eye = hmask(lambda d, s, ex=ex: d.line([(s(ex - 1.3), s(cy)), (s(ex + 1.3), s(cy))], fill=255, width=int(0.9 * K)), c)
            paint(c, eye, np.array([20, 10, 20], np.float32))
        brow = hmask(lambda d, s, ex=ex: d.line([(s(ex - 1.6), s(cy - 2.6 + (0.8 if ex < cx else 0))), (s(ex + 1.6), s(cy - 2.6 + (0 if ex < cx else 0.8)))], fill=255, width=int(0.8 * K)), c)
        paint(c, brow, np.array([20, 10, 20], np.float32))
    mouth = hmask(lambda d, s: d.arc([s(cx - 1.8), s(cy + 2.2), s(cx + 1.8), s(cy + 5)], 200, 340, fill=255, width=int(0.8 * K)), c)
    paint(c, mouth, np.array([20, 10, 20], np.float32))


def coccus(path, frame):
    c = canvas(18, 18)
    for i in range(10):                                   # wiggly cilia
        a = i / 10 * 2 * math.pi + frame * 0.3
        x1, y1 = 9 + 6.5 * math.cos(a), 9 + 6.5 * math.sin(a)
        x2, y2 = 9 + 8.6 * math.cos(a + 0.25), 9 + 8.6 * math.sin(a + 0.25)
        cil = hmask(lambda d, s, p=(x1, y1, x2, y2): d.line([(s(p[0]), s(p[1])), (s(p[2]), s(p[3]))], fill=255, width=int(1 * K)), c)
        paint(c, cil, np.array(GERM_PALS['coccus'][1], np.float32))
    body = hmask(lambda d, s: d.ellipse([s(2.6), s(2.6), s(15.4), s(15.4)], fill=255), c)
    solid(c, body, GERM_PALS['coccus'], 4, spec_amt=.5)
    for sx, sy in ((6, 12), (12, 5.5), (12.5, 12)):      # spots
        sp = hmask(lambda d, s, sx=sx, sy=sy: d.ellipse([s(sx - 1), s(sy - 1), s(sx + 1), s(sy + 1)], fill=255), c)
        paint(c, sp, np.array(GERM_PALS['coccus'][1], np.float32))
    germ_face(c, 9, 8.5, 2.6, frame)
    return done(c, path)


def bacillus(path, frame):
    c = canvas(26, 14)
    tail = hmask(lambda d, s: d.line([(s(4), s(7 + (1.5 if frame else -1.5))), (s(1), s(7 + (-1.5 if frame else 1.5)))], fill=255, width=int(1 * K)), c)
    paint(c, tail, np.array(GERM_PALS['bacillus'][1], np.float32))
    for x0 in (9, 17):
        leg = hmask(lambda d, s, x0=x0: (d.line([(s(x0), s(11)), (s(x0 - 1.5 + frame * 3), s(13.5))], fill=255, width=int(0.9 * K)),
                                         d.line([(s(x0), s(3)), (s(x0 - 1.5 + frame * 3), s(0.5))], fill=255, width=int(0.9 * K))), c)
        paint(c, leg, np.array(GERM_PALS['bacillus'][1], np.float32))
    body = hmask(lambda d, s: d.rounded_rectangle([s(3.5), s(2.5), s(24.5), s(11.5)], s(4.5), fill=255), c)
    solid(c, body, GERM_PALS['bacillus'], 3.5, spec_amt=.5)
    germ_face(c, 17, 6.5, 2.5, frame)
    return done(c, path)


def virus(path, frame):
    c = canvas(20, 20)
    for i in range(8):
        a = i / 8 * 2 * math.pi + frame * 0.2
        x1, y1 = 10 + 9 * math.cos(a), 10 + 9 * math.sin(a)
        spike = hmask(lambda d, s, p=(x1, y1, a): (d.line([(s(10), s(10)), (s(p[0]), s(p[1]))], fill=255, width=int(1.1 * K)),
                                                    d.ellipse([s(p[0] - 1.3), s(p[1] - 1.3), s(p[0] + 1.3), s(p[1] + 1.3)], fill=255)), c)
        solid(c, spike, GERM_PALS['virus'], 1)
    body = hmask(lambda d, s: d.regular_polygon((s(10), s(10), s(6.8)), 6, rotation=frame * 8, fill=255), c)
    solid(c, body, GERM_PALS['virus'], 3.5, spec_amt=.5)
    germ_face(c, 10, 9.5, 2.4, frame)
    return done(c, path)


def slime(path):
    c = canvas(7, 10)
    m = hmask(lambda d, s: (d.ellipse([s(0.8), s(3.5), s(6.2), s(9.2)], fill=255), d.polygon([(s(3.5), s(0.3)), (s(1.2), s(6)), (s(5.8), s(6))], fill=255)), c)
    solid(c, m, GERM_PALS['coccus'], 2.5, spec_amt=.8)
    return done(c, path)


def soap(path):
    c = canvas(8, 8)
    d = np.hypot(c.x - 4, c.y - 4)
    m = d < 3.3
    material(c, np.sqrt(np.clip(1 - (d / 3.3) ** 2, 0, 1)), m, [(120, 170, 220), (170, 210, 245), (210, 236, 255), (236, 248, 255), (255, 255, 255)], bump=3, spec_amt=.9, spec_pow=10, grain=0)
    return done(c, path)


if __name__ == '__main__':
    os.makedirs(SPLASH, exist_ok=True)
    os.makedirs(DASH, exist_ok=True)
    sheet = []
    for name, pal in RING_PALS.items():
        sheet.append(ring(pal, os.path.join(SPLASH, f'ring_{name}.png')))
    for name, pal in BALL_PALS.items():
        sheet.append(ball(pal, os.path.join(SPLASH, f'ball_{name}.png')))
    sheet.append(peg(os.path.join(SPLASH, 'peg.png')))
    cup(os.path.join(SPLASH, 'cup_back.png'), os.path.join(SPLASH, 'cup_front.png'))
    sheet.append(Image.open(os.path.join(SPLASH, 'cup_back.png')))
    sheet.append(Image.open(os.path.join(SPLASH, 'cup_front.png')))
    cup_rim_net(os.path.join(SPLASH, 'cup_front.png'), os.path.join(SPLASH, 'cup_rim.png'), os.path.join(SPLASH, 'cup_net.png'))
    sheet.append(nozzle(os.path.join(SPLASH, 'nozzle.png')))
    sheet.append(pin(os.path.join(SPLASH, 'pin.png')))
    sheet.append(bubble(os.path.join(SPLASH, 'bubble_big.png'), 3.2))
    sheet.append(bubble(os.path.join(SPLASH, 'bubble_small.png'), 2.0))
    tank(os.path.join(SPLASH, 'tank.png'))
    ground_tiles(os.path.join(DASH, 'ground_top.png'), os.path.join(DASH, 'ground.png'))
    sheet.append(Image.open(os.path.join(DASH, 'ground_top.png')))
    sheet.append(plunger(os.path.join(DASH, 'plunger.png')))
    fly(os.path.join(DASH, 'fly_1.png'), os.path.join(DASH, 'fly_2.png'))
    sheet.append(Image.open(os.path.join(DASH, 'fly_1.png')))
    sheet.append(Image.open(os.path.join(DASH, 'fly_2.png')))
    sheet.append(corn(os.path.join(DASH, 'corn.png')))
    os.makedirs(BREAK, exist_ok=True)
    os.makedirs(GERM, exist_ok=True)
    sheet.append(tp_roll(os.path.join(BREAK, 'paddle.png')))
    for name, pal in TILE_PALS.items():
        sheet.append(tile(pal, os.path.join(BREAK, f'tile_{name}.png')))
        if name != 'gold':
            tile(pal, os.path.join(BREAK, f'tile_{name}_cracked.png'), cracked=True)
    sheet.append(Image.open(os.path.join(BREAK, 'tile_pink_cracked.png')))
    for name in ('mint', 'yellow', 'pink'):
        sheet.append(capsule(RING_PALS[name], os.path.join(BREAK, f'capsule_{name}.png')))
    for f in range(2):
        sheet.append(coccus(os.path.join(GERM, f'coccus_{f + 1}.png'), f))
        sheet.append(bacillus(os.path.join(GERM, f'bacillus_{f + 1}.png'), f))
        sheet.append(virus(os.path.join(GERM, f'virus_{f + 1}.png'), f))
    sheet.append(slime(os.path.join(GERM, 'slime.png')))
    sheet.append(soap(os.path.join(GERM, 'soap.png')))
    # preview sheet at x3 on a neutral ground
    w = sum(s.width + 4 for s in sheet)
    prev = Image.new('RGBA', (w, 64), (150, 200, 210, 255))
    x = 2
    for s in sheet:
        prev.alpha_composite(s, (x, 2)); x += s.width + 4
    prev.resize((prev.width * 3, prev.height * 3), Image.NEAREST).save(os.path.join(SCR, 'minigame_sprites.png'))
    Image.open(os.path.join(SPLASH, 'tank.png')).resize((634, 632), Image.NEAREST).save(os.path.join(SCR, 'tank_preview.png'))
    print('ok')
