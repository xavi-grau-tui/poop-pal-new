"""All the pals of the evolution tree (data/evolution_tree.json), built from parts in the same
paint-big-then-shrink style as forms.py (the 6 hand-made ones there are kept as they are).

A pal = the BODY of its family (the baby's food) at the size of its stage
      + a TOPPING for the food that shaped it (kid: the 2nd food; adults: see VARIANT)
      + an adult EXTRA (crown, flowers, bandage, spots...)
      + a FACE (happy, sparkle, sleepy, stars, neutral ._., sad, angry, evil, dizzy, visor, three)
Mutants: the family body in metal (tech) or alien goo (cosmic). Legends: their own showpieces.

    python3 tools/art/forms_gen.py            -> textures/pet/forms/<id>-1.png, -2.png (all new ones)
    python3 tools/art/forms_gen.py sproutberry ember   (only these)
"""
import json, math, os, sys, zlib
from hires import *
import forms as base
from forms import F, W, H, K, BROWN, PINK, VAN, CHOC, GREEN, ORANGE, CHEESE, SPRINK, SEAM, split

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, '..', '..', 'data', 'evolution_tree.json')

RED = [(70, 10, 16), (140, 24, 30), (200, 50, 44), (232, 92, 70), (250, 150, 120), (255, 214, 190)]
PICKLE = [(30, 50, 16), (70, 100, 30), (118, 150, 52), (160, 186, 80), (206, 220, 130), (240, 246, 200)]
LEMON = [(150, 110, 10), (220, 176, 30), (250, 216, 60), (255, 236, 120), (255, 250, 210)]
FLAME = [(150, 20, 10), (226, 70, 24), (250, 140, 40), (255, 200, 80), (255, 244, 190)]
METAL = [(36, 40, 52), (80, 88, 106), (130, 140, 160), (176, 186, 204), (222, 230, 242), (255, 255, 255)]
GOO = [(36, 18, 70), (80, 44, 140), (126, 84, 200), (164, 132, 230), (206, 186, 250), (240, 232, 255)]
GOLD = [(110, 66, 10), (176, 120, 20), (226, 176, 40), (250, 214, 90), (255, 244, 190)]
PETAL = {'G': [(200, 220, 120), (240, 250, 190)], 'S': [(240, 140, 180), (255, 214, 230)],
         'F': [(250, 200, 80), (255, 240, 170)], 'H': [(240, 90, 60), (255, 180, 140)], 'U': [(230, 220, 70), (255, 250, 180)]}

FAM_CODE = {'green': 'G', 'sweet': 'S', 'greasy': 'F', 'spicy': 'H', 'sour': 'U'}
STAGE_SCALE = {'baby': 1.3, 'kid': 1.62, 'adult': 1.9, 'mutant': 1.9, 'legend': 2.05}
EYE = {'baby': (5.4, 10.5), 'kid': (5.2, 11.5), 'adult': (5.0, 12.5), 'mutant': (5.0, 12.5), 'legend': (5.2, 13.5)}


MAX_HALF_W = 41.0                       # body half-width cap (room for wings, the canvas is 110 wide)


def Sc(balls, s, a=(55, 93), sx=None):
    sx = s if sx is None else sx
    return [(a[0] + (b[0] - a[0]) * sx, a[1] + (b[1] - a[1]) * s, b[2] * sx, b[3] * s, *b[4:]) for b in balls]


def x_scale(fam, s):
    return min(s, MAX_HALF_W / max(b[2] for b in BODY[fam][0]))


def Yc(y, s):
    return 93 + (y - 93) * s


# ------------------------------------------------------------------ bodies
BODY = {   # unit shapes (baby-sized), face height
    'G': ([(55, 86, 21, 7.5), (55, 78, 16, 9)], 80.5),
    'S': ([(55, 86, 22, 7.5), (55, 76, 16.5, 6.5), (56, 67, 9.5, 5.5)], 83.5),
    'F': ([(55, 87, 27, 6.5), (55, 80, 21, 7.5), (56, 72, 11, 5.5)], 80.5),
    'H': ([(55, 86, 18, 7.5), (55, 78, 15, 8.5), (56, 69, 10, 7), (57, 62, 5, 4)], 80.0),
    'U': ([(55, 85, 16, 8.5), (55, 75, 14, 10.5), (55, 66, 10, 7)], 78.5),
}
BODY_PAL = {'G': BROWN, 'S': PINK, 'F': ORANGE, 'H': RED, 'U': PICKLE}


def body(c, fam, s, pal=None, rng=None):
    balls, fy = BODY[fam]
    balls = [list(b) for b in balls]
    if rng is not None:                         # a little variety per pal
        w = rng.uniform(0.94, 1.08)
        for b in balls:
            b[2] *= w
    balls = Sc([tuple(b) for b in balls], s, sx=x_scale(fam, s))
    pal = pal or BODY_PAL[fam]
    if fam == 'S' and pal is PINK:              # soft serve tiers: pink / vanilla / pink
        fs = [field(c, [b]) for b in balls]
        mask, parts, tot = split(c, fs)
        for f, m, p in zip(fs, parts, [PINK, VAN, PINK, VAN]):
            material(c, height(f, .55), m, p, bump=4, spec_amt=.45, spec_pow=22, grain=.08)
        for i in range(len(parts) - 1):
            seam(c, parts[i + 1], parts[i], .5, SEAM(90, 30, 50))
        f = sum(fs)
    else:
        f = field(c, balls)
        mask = f > 1
        shiny = {'F': (.75, 16), 'H': (.7, 18)}.get(fam, (.35, 22))
        material(c, height(f, .55), mask, pal, bump=4, spec_amt=shiny[0], spec_pow=shiny[1], grain=.08)
        if fam == 'U':                           # pickle warts
            rr = np.random.default_rng(7)
            top = min(b[1] - b[3] for b in balls)
            warts = []
            for _ in range(int(9 * s)):
                x, y = rr.uniform(55 - 14 * s, 55 + 14 * s), rr.uniform(top + 3, 92)
                if f[min(int(y * K * F), H * K - 1), min(int(x * K * F), W * K - 1)] > 1.6:
                    warts.append((x, y, 1.5 * s ** .5, 1.5 * s ** .5, .25))
            if warts:
                wf = field(c, warts)
                material(c, np.clip(height(f, .55) + height(wf, .5) * .4, 0, 1.3), mask & (wf > .9), pal, bump=6, spec_amt=.3, grain=.08)
    top = min(b[1] - b[3] for b in balls)
    return f, mask, top, Yc(fy, s)


def stem(c, x, y, s, col=(60, 110, 40)):
    im = to_image(c); d = ImageDraw.Draw(im)
    d.line([*c.P(x, y + 2), *c.P(x + 1.5 * s, y - 3 * s), *c.P(x + 4 * s, y - 5 * s)], fill=col, width=int(2.6 * K * F * s ** .5), joint='curve')
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


# ------------------------------------------------------------------ toppings (the food that shaped it)
def top_green(c, top, s, n=3, big=1.0, seed=5):
    rr = np.random.default_rng(seed)
    fl = []
    for i in range(n):
        t = (i - (n - 1) / 2)
        fl.append((55 + t * 9 * s * .7 * big, top + 1.0 * s + abs(t) * 2.2 * s, 5.5 * s * .78 * big, 5 * s * .78 * big))
    ffs = [field(c, [f]) for f in fl]
    for f, (fx, fy, rx, ry) in zip(ffs, fl):
        micro = [(fx + rr.uniform(-.7, .7) * rx, fy + rr.uniform(-.7, .6) * ry, 2.4, 2.4, .4) for _ in range(6)]
        h = np.clip(height(f, .5) * .75 + height(field(c, micro), .6) * .45, 0, 1.3)
        material(c, h, f > 1, GREEN, bump=6, spec_amt=.2, grain=.16, ao=.5)
        seam(c, f > 1, (c.a > .5) & ~(f > 1), .4, SEAM(22, 46, 24))


def top_sweet(c, bodyf, top, s, depth=0.32, seed=9, pal=PINK):
    """a frosting cap with a wavy drip edge + sprinkles"""
    span = (93 - top)
    line = lambda x: top + span * depth + 1.6 * s * np.sin(x * .55) + 2.4 * s * np.exp(-((x - 44) / 2.6) ** 2) + 2 * s * np.exp(-((x - 67) / 2.4) ** 2)
    m = (bodyf > 1) & (c.y < line(c.x))
    material(c, height(bodyf, .55) * 1.05, m, pal, bump=4, spec_amt=.5, spec_pow=24, grain=.05)
    seam(c, m, (bodyf > 1) & ~m, .45, SEAM(120, 40, 70))
    dots(c, int(5 * s), (55 - 12 * s, top + 1, 55 + 12 * s, top + span * depth,
         lambda x, y: m[min(int(y * K * F), H * K - 1), min(int(x * K * F), W * K - 1)]), SPRINK, r=1.4, seed=seed)


def top_greasy(c, bodyf, top, s, depth=0.42):
    span = (93 - top)
    line = lambda x: top + span * depth + 1.5 * np.sin(x * .5) + 6 * np.exp(-((x - 38) / 2.4) ** 2) + 8 * np.exp(-((x - 72) / 2.6) ** 2)
    m = (bodyf > 1) & (c.y < line(c.x))
    material(c, height(bodyf, .5) * 1.05, m, CHEESE, bump=4, spec_amt=.55, spec_pow=22, grain=.05)
    seam(c, m, (bodyf > 1) & ~m, .5, SEAM(120, 56, 16))


def top_spicy(c, top, s, big=1.0):
    """a little flame tuft on the head"""
    k = s * .85 * big
    fl = [(55, top - 2.5 * k, 4.2 * k, 7 * k),
          (55 - 4.6 * k, top - .2 * k, 3 * k, 5 * k),
          (55 + 4.8 * k, top - .4 * k, 3.2 * k, 5.2 * k)]
    f = field(c, fl)
    m = (f > 1) & (c.a < .5)
    material(c, np.clip(1.0 - (c.y - (top - 9 * k)) / (12 * k), 0, 1), m, FLAME, bump=2, spec_amt=.1, grain=.05, ao=0)


def top_sour(c, top, s, x=63):
    """a lemon slice stuck on top"""
    r = 6.0 * s * .7
    cx, cy = x, top - r * .15
    d = np.hypot(c.x - cx, (c.y - cy) * 1.35)
    m = d < r
    rind = m & (d > r * .78)
    pulp = m & ~rind
    paint(c, rind, np.array([250, 214, 60], np.float32))
    material(c, np.clip(1 - d / r, 0, 1), pulp, LEMON, bump=2, spec_amt=.2, grain=.12, ao=.1)
    im = to_image(c); dr = ImageDraw.Draw(im)
    for k in range(6):
        a = k * math.pi / 3
        dr.line([*c.P(cx, cy), *c.P(cx + math.cos(a) * r * .78, cy + math.sin(a) * r * .78 / 1.35)], fill=(250, 240, 200), width=int(.6 * K * F * s ** .5))
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


def topping(c, fam, bodyf, top, s, big=1.0, seed=5, x=None):
    if fam == 'G':
        top_green(c, top, s, n=3 if big <= 1 else 5, big=big, seed=seed)
    elif fam == 'S':
        top_sweet(c, bodyf, top, s, depth=.3 * big, seed=seed)
    elif fam == 'F':
        top_greasy(c, bodyf, top, s, depth=.38 * big)
    elif fam == 'H':
        top_spicy(c, top, s, big=big)
    elif fam == 'U':
        top_sour(c, top, s, x=x or 63)


# ------------------------------------------------------------------ adult extras
def crown(c, top, s):
    cx, y = 55, top - .5
    w, h = 7.5 * s * .8, 6.5 * s * .8
    im = to_image(c); d = ImageDraw.Draw(im)
    pts = [(cx - w, y), (cx - w, y - h * .6), (cx - w * .5, y - h * .25), (cx, y - h), (cx + w * .5, y - h * .25), (cx + w, y - h * .6), (cx + w, y)]
    d.polygon([c.P(*p) for p in pts], fill=(240, 196, 60))
    d.line([c.P(cx - w, y - h * .15), c.P(cx + w, y - h * .15)], fill=(255, 236, 150), width=int(.9 * K * F * s ** .5))
    for p in [(cx, y - h * .55), (cx - w * .55, y - h * .35), (cx + w * .55, y - h * .35)]:
        d.ellipse([*c.P(p[0] - .9, p[1] - .9), *c.P(p[0] + .9, p[1] + .9)], fill=(214, 60, 90))
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


def flowers(c, fam_friend, top, s, seed=3):
    rr = np.random.default_rng(seed)
    im = to_image(c); d = ImageDraw.Draw(im)
    pc, cc = PETAL[fam_friend]
    for i in range(3):
        x = 55 + (i - 1) * 9 * s * .55 + rr.uniform(-2, 2)
        y = top + 4 * s + abs(i - 1) * 3 * s + rr.uniform(-1, 1)
        r = 1.9 * s * .55
        for k in range(5):
            a = k * 2 * math.pi / 5
            px, py = x + math.cos(a) * r, y + math.sin(a) * r
            d.ellipse([*c.P(px - r * .8, py - r * .8), *c.P(px + r * .8, py + r * .8)], fill=pc)
        d.ellipse([*c.P(x - r * .6, y - r * .6), *c.P(x + r * .6, y + r * .6)], fill=(250, 214, 80))
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


def bandage(c, top, s):
    im = to_image(c); d = ImageDraw.Draw(im)
    x, y = 55 + 8 * s * .55, top + 5 * s
    L, Wd = 6 * s * .55, 2.2 * s * .55
    for ang in (.6, -.6):
        dx, dy = math.cos(ang) * L, math.sin(ang) * L
        nx, ny = -math.sin(ang) * Wd, math.cos(ang) * Wd
        poly = [(x - dx - nx, y - dy - ny), (x + dx - nx, y + dy - ny), (x + dx + nx, y + dy + ny), (x - dx + nx, y - dy + ny)]
        d.polygon([c.P(*p) for p in poly], fill=(250, 226, 196), outline=OUT_T)
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


OUT_T = tuple(int(v) for v in OUT)


def spots(c, mask, top, s, col, seed=4):
    rr = np.random.default_rng(seed)
    blobs = [(rr.uniform(55 - 14 * s, 55 + 14 * s), rr.uniform(top + 4, 90), 1.6 * s * .6, 1.3 * s * .6) for _ in range(int(5 * s))]
    f = field(c, blobs)
    m = mask & (f > 1)
    paint(c, m, np.array(col, np.float32))


# ------------------------------------------------------------------ faces
def face2(c, cx, cy, spread, style, eye_r):
    if style in ('happy', 'sparkle', 'sleepy', 'stars'):
        face(c, cx, cy, spread=spread, style=style, eye_r=eye_r)
        return
    k = c.k
    im = to_image(c); d = ImageDraw.Draw(im, 'RGBA')
    P = c.P
    u = eye_r / 3.4
    ink = (18, 8, 14)
    ex = [cx - spread, cx + spread]
    my = cy + 3.0 * u
    if style == 'neutral':            # ._.   small dot eyes, flat little mouth
        for e in ex:
            d.ellipse([*P(e - eye_r * .55, cy - eye_r * .55), *P(e + eye_r * .55, cy + eye_r * .55)], fill=ink)
        d.line([P(cx - 1.6 * u, my + 1.2 * u), P(cx + 1.6 * u, my + 1.2 * u)], fill=ink, width=max(2, int(1.3 * k * c.f)))
    elif style in ('sad', 'angry', 'evil'):
        for i, e in enumerate(ex):
            side = -1 if i == 0 else 1
            if style == 'evil':       # half-closed, looking sideways
                d.chord([*P(e - eye_r, cy - eye_r * 1.0), *P(e + eye_r, cy + eye_r * 1.0)], 0, 180, fill=ink)
                d.ellipse([*P(e + eye_r * .1, cy + eye_r * .05), *P(e + eye_r * .55, cy + eye_r * .5)], fill=(255, 255, 255))
            else:
                d.ellipse([*P(e - eye_r, cy - eye_r * 1.1), *P(e + eye_r, cy + eye_r * 1.1)], fill=ink)
                d.ellipse([*P(e - eye_r * .55, cy - eye_r * .75), *P(e + eye_r * .15, cy - eye_r * .05)], fill=(255, 255, 255))
            # brows: angry/evil slant down to the middle, sad slants up to the middle
            inner = e - side * eye_r * 1.0
            outer = e + side * eye_r * 1.1
            if style == 'sad':
                p1, p2 = P(inner, cy - eye_r * 1.9), P(outer, cy - eye_r * 1.35)
            else:
                p1, p2 = P(inner, cy - eye_r * 1.15), P(outer, cy - eye_r * 1.85)
            d.line([p1, p2], fill=ink, width=max(2, int(1.5 * k * c.f * u)))
        if style == 'sad':
            d.arc([*P(cx - 2.6 * u, my + .6 * u), *P(cx + 2.6 * u, my + 4.6 * u)], 200, 340, fill=ink, width=max(2, int(1.3 * k * c.f)))
            d.ellipse([*P(ex[1] + eye_r * .3, cy + eye_r * 1.3), *P(ex[1] + eye_r * 1.0, cy + eye_r * 2.4)], fill=(130, 190, 240))
        elif style == 'angry':
            d.rectangle([*P(cx - 2.6 * u, my - .2 * u), *P(cx + 2.6 * u, my + 1.8 * u)], fill=ink)
            d.line([P(cx - 2.2 * u, my + .8 * u), P(cx + 2.2 * u, my + .8 * u)], fill=(255, 255, 255), width=max(1, int(.6 * k * c.f)))
        else:                          # evil: a lopsided grin with a fang
            d.chord([*P(cx - 3.4 * u, my - 2.0 * u), *P(cx + 3.6 * u, my + 3.4 * u)], 10, 170, fill=ink)
            d.polygon([P(cx + 1.0 * u, my + .6 * u), P(cx + 2.0 * u, my + .6 * u), P(cx + 1.5 * u, my + 2.0 * u)], fill=(255, 255, 255))
    elif style == 'dizzy':             # x x  and a wobbly mouth
        for e in ex:
            r = eye_r * .9
            w = max(2, int(1.5 * k * c.f * u))
            d.line([P(e - r, cy - r), P(e + r, cy + r)], fill=ink, width=w)
            d.line([P(e - r, cy + r), P(e + r, cy - r)], fill=ink, width=w)
        pts = [P(cx - 3 * u + i * 1.5 * u, my + 1.2 * u + (1 if i % 2 else -1) * .7 * u) for i in range(5)]
        d.line(pts, fill=ink, width=max(2, int(1.2 * k * c.f)))
    elif style == 'visor':             # tech: a glowing visor
        d.rounded_rectangle([*P(cx - spread - eye_r * 1.6, cy - eye_r * 1.0), *P(cx + spread + eye_r * 1.6, cy + eye_r * 1.0)], radius=int(eye_r * k * c.f), fill=(20, 24, 34))
        for e in ex:
            d.rectangle([*P(e - eye_r * .8, cy - eye_r * .35), *P(e + eye_r * .8, cy + eye_r * .35)], fill=(120, 255, 200))
        d.line([P(cx - 2 * u, my + 1.5 * u), P(cx + 2 * u, my + 1.5 * u)], fill=ink, width=max(2, int(1.2 * k * c.f)))
    elif style == 'three':             # cosmic: three eyes
        for e, yy, r in [(ex[0], cy, eye_r * .9), (ex[1], cy, eye_r * .9), (cx, cy - eye_r * 1.9, eye_r * .8)]:
            d.ellipse([*P(e - r, yy - r * 1.1), *P(e + r, yy + r * 1.1)], fill=ink)
            d.ellipse([*P(e - r * .55, yy - r * .75), *P(e + r * .15, yy - r * .05)], fill=(190, 255, 220))
        d.chord([*P(cx - 2.4 * u, my - 2.0 * u), *P(cx + 2.4 * u, my + 3.0 * u)], 0, 180, fill=ink)
    a = np.asarray(im, np.float32)
    c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


# ------------------------------------------------------------------ mutants / legends
def antenna(c, top, s, tip=(240, 60, 60), x=55, lean=0.0):
    im = to_image(c); d = ImageDraw.Draw(im)
    d.line([*c.P(x, top + 1), *c.P(x + lean, top - 6 * s * .55)], fill=(60, 64, 80), width=int(1.2 * K * F * s ** .5))
    r = 1.7 * s * .55
    tx, ty = x + lean, top - 6 * s * .55
    d.ellipse([*c.P(tx - r, ty - r), *c.P(tx + r, ty + r)], fill=tip)
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


def rivets(c, mask, top, s):
    rr = np.random.default_rng(2)
    im = to_image(c); d = ImageDraw.Draw(im)
    y = top + (93 - top) * .62
    for i in range(7):
        x = 55 - 15 * s * .62 + i * 5 * s * .62
        if mask[min(int(y * K * F), H * K - 1), min(int(x * K * F), W * K - 1)]:
            d.ellipse([*c.P(x - .8, y - .8), *c.P(x + .8, y + .8)], fill=(230, 236, 250))
    d.line([c.P(55 - 16 * s * .62, y - 2), c.P(55 + 16 * s * .62, y - 2)], fill=(60, 66, 84), width=int(.8 * K * F))
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


def stars(c, mask, top, s, n=8, col=(255, 250, 220), seed=6):
    rr = np.random.default_rng(seed)
    im = to_image(c); d = ImageDraw.Draw(im)
    for _ in range(n):
        x, y = rr.uniform(55 - 15 * s * .6, 55 + 15 * s * .6), rr.uniform(top + 2, 90)
        if mask[min(int(y * K * F), H * K - 1), min(int(x * K * F), W * K - 1)]:
            r = rr.uniform(.6, 1.1)
            d.polygon([c.P(x, y - r * 1.8), c.P(x + r * .5, y), c.P(x, y + r * 1.8), c.P(x - r * .5, y)], fill=col)
            d.polygon([c.P(x - r * 1.8, y), c.P(x, y + r * .5), c.P(x + r * 1.8, y), c.P(x, y - r * .5)], fill=col)
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


def horns(c, top, s, col=GOLD):
    """two curved horns (drawn BEHIND the body)"""
    for side in (-1, 1):
        balls = []
        for j in range(6):
            t = j / 5
            balls.append((55 + side * (10 + t * 7), top + 6 - t * 13 + t * t * 3, 3.4 - t * 2.4, 3.4 - t * 2.2))
        f = field(c, balls)
        material(c, height(f, .5), f > 1, col, bump=3, spec_amt=.5, grain=.04)


def half_width(fam, s):
    return max(b[2] for b in BODY[fam][0]) * x_scale(fam, s)


def body_top(fam, s):
    return Yc(min(b[1] - b[3] for b in BODY[fam][0]), s)


def wings(c, top, s, pal, hw):
    """three feathers per side, fanning up and out (drawn BEHIND the body)"""
    for side in (-1, 1):
        for i in range(3):
            ang = math.radians(-35 + i * 28)
            x0, y0 = 55 + side * hw * .8, top + 12 + i * 7
            balls = []
            for j in range(5):
                t = j / 4
                L = (22 + 5 * (2 - i)) * t
                balls.append((x0 + side * math.cos(ang) * L, y0 - math.sin(ang) * L * .9 - 3, (5.0 - t * 3.2), (3.4 - t * 1.9)))
            f = field(c, balls)
            material(c, height(f, .5), f > 1, pal, bump=3, spec_amt=.3, grain=.05)


def tentacles(c, s, pal, hw):
    """four curling tentacles coming out from under the body (drawn BEHIND it)"""
    for side in (-1, 1):
        for j in range(2):
            balls = []
            for i in range(9):
                t = i / 8
                x = 55 + side * (hw * (.6 + j * .25) + t * (18 + j * 4))
                y = 90 - j * 2 - math.sin(t * math.pi * 1.2) * (5 + j * 3) + t * 2
                balls.append((x, y, 3.6 - t * 2.4, 3.2 - t * 2.0))
            f = field(c, balls)
            material(c, height(f, .5), f > 1, pal, bump=4, spec_amt=.35, grain=.06)


def halo(c, top, s):
    im = to_image(c); d = ImageDraw.Draw(im)
    w, h = 9 * s * .55, 2.4 * s * .55
    y = top - 6 * s * .55
    d.ellipse([*c.P(55 - w, y - h), *c.P(55 + w, y + h)], outline=(250, 214, 80), width=int(1.4 * K * F * s ** .5))
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


# ------------------------------------------------------------------ one pal
def draw_form(c, fid, fm, data):
    stage = fm['stage_name']
    A = FAM_CODE[fm['family']]
    s = STAGE_SCALE[stage]
    rr = np.random.default_rng(zlib.crc32(fid.encode()))
    eye_r, spread = EYE[stage]
    variant = fm['variant']
    # which foods shaped it: kid = 2nd food; adults: from the transition table
    B = None
    if stage in ('kid', 'adult'):
        kid_id = fid if stage == 'kid' else fm['from']
        for food, to in data['next'][data['forms'][kid_id]['from']].items():
            if to == kid_id:
                B = FAM_CODE[food]
    if stage == 'mutant':
        pal = METAL if variant == 'TECH' else GOO
        f, m, top, fy = body(c, A, s, pal=pal, rng=rr)
        if variant == 'TECH':
            rivets(c, m, top, s)
            outline(c, c.a > .5, 1.0)
            antenna(c, top, s, x=55 + 4, lean=2)
        else:
            stars(c, m, top, s, n=10, col=(220, 255, 240))
            outline(c, c.a > .5, 1.0)
            antenna(c, top, s, tip=(160, 255, 200), x=50, lean=-3)
            antenna(c, top, s, tip=(160, 255, 200), x=60, lean=3)
        outline(c, c.a > .5, 1.0)
        face2(c, 55, fy, spread, fm['face'], eye_r)
        return
    if stage == 'legend':
        if A == 'G':
            f, m, top, fy = body(c, A, s, rng=rr)
            top_green(c, top, s, n=5, big=1.25, seed=11)          # a canopy in two layers
            top_green(c, top - 4.5 * s, s, n=3, big=1.2, seed=12)
            stars(c, c.a > .5, top - 9 * s, s, n=10, col=(255, 236, 120))
        elif A == 'S':
            f, m, top, fy = body(c, A, s, rng=rr)
            top_sweet(c, f, top, s, depth=.33, pal=[(90, 60, 140), (150, 120, 210), (200, 180, 240), (230, 220, 255), (255, 255, 255)])
            stars(c, m, top, s, n=8)
            halo(c, top, s)
        elif A == 'F':
            t0 = body_top(A, s)
            wings(c, t0, s, ORANGE, half_width(A, s))
            horns(c, t0, s)
            f, m, top, fy = body(c, A, s, pal=GOLD, rng=rr)
            top_greasy(c, f, top, s, depth=.3)
        elif A == 'H':
            t0 = body_top(A, s)
            wings(c, t0, s, FLAME, half_width(A, s))
            f, m, top, fy = body(c, A, s, rng=rr)
            top_spicy(c, top + 3 * s, s, big=1.15)
        else:
            sea = [(20, 60, 50), (40, 110, 90), (70, 160, 130), (120, 200, 170), (190, 236, 210), (240, 255, 248)]
            tentacles(c, s, sea[:5], half_width(A, s))
            f, m, top, fy = body(c, A, s, pal=sea, rng=rr)
            crown(c, top, s)
        outline(c, c.a > .5, 1.0)
        face2(c, 55, fy, spread, fm['face'], eye_r)
        return
    f, m, top, fy = body(c, A, s, rng=rr)
    if A == 'H':
        stem(c, 57.5, top + .5, s)
    if stage == 'baby':
        if A == 'G':
            top_green(c, top, s, n=3, seed=5)
    elif stage == 'kid':
        topping(c, B, f, top, s, seed=len(fid))
    else:
        if variant in ('ULTRA', 'BLOOM', 'CLASH'):
            topping(c, A, f, top, s, big=1.35, seed=len(fid))
        elif variant == 'ROOT':
            topping(c, A, f, top, s, big=1.2, seed=len(fid))
            if B != A:
                topping(c, B, f, top, s, big=.75, seed=len(fid) + 1, x=47)
        elif variant == 'PEAK':
            topping(c, B, f, top, s, big=1.5, seed=len(fid))
        else:   # CHAOS: its 2nd food plus some third food's colour in spots
            topping(c, B, f, top, s, seed=len(fid))
            others = [x for x in 'GSFHU' if x not in (A, B)]
            C = others[len(fid) % len(others)]
            spots(c, m, top, s, BODY_PAL[C][3] if C != 'S' else PINK[2], seed=len(fid))
    outline(c, c.a > .5, 1.0)
    if variant == 'ULTRA':
        crown(c, top - 3 * s if A in 'GH' else top, s)
    elif variant == 'BLOOM':
        fr = {'G': 'S', 'S': 'F', 'F': 'H', 'H': 'U', 'U': 'G'}[A]
        flowers(c, fr, top, s, seed=len(fid))
    elif variant == 'CLASH':
        bandage(c, top, s)
    outline(c, c.a > .5, 1.0)
    face2(c, 55, fy, spread, fm['face'], eye_r)


def faces():
    """{form: (cx, cy, spread, eye_r)} for every generated pal (for accessories.py & co)"""
    data = json.load(open(DATA))
    out = {}
    for fid, fm in data['forms'].items():
        if fid in base.FORMS:
            continue
        stage = fm['stage_name']
        A = FAM_CODE[fm['family']]
        s = STAGE_SCALE[stage]
        eye_r, spread = EYE[stage]
        out[fid] = (55, Yc(BODY[A][1], s), spread, eye_r)
    return out


def render_all(ids=None):
    data = json.load(open(DATA))
    DEST = os.path.join(PROJ, 'pet', 'forms')
    os.makedirs(DEST, exist_ok=True)
    done = []
    for fid, fm in data['forms'].items():
        if fid in base.FORMS:                # the 6 hand-made ones stay
            continue
        if ids and fid not in ids:
            continue
        for row, sq in enumerate([(1.0, 1.0), (1.03, 0.95)]):
            c = Canvas(W, H, K, F, squash=sq, anchor=(55, 93))
            draw_form(c, fid, fm, data)
            _, small = shrink(c)
            up2 = small.resize((W * 2, H * 2), Image.NEAREST)
            out = Image.new('RGBA', (232, 196), (0, 0, 0, 0))
            out.alpha_composite(up2, (60, 60))
            out.save(os.path.join(DEST, f'{fid}-{row + 1}.png'))
        done.append(fid)
        print(fid, flush=True)
    return done


def sheet(path, ids=None, cols=10):
    data = json.load(open(DATA))
    ids = ids or list(data['forms'].keys())
    rows = (len(ids) + cols - 1) // cols
    cell = (200, 170)
    im = Image.new('RGBA', (cols * cell[0], rows * cell[1]), (236, 200, 196, 255))
    d = ImageDraw.Draw(im)
    for i, fid in enumerate(ids):
        p = os.path.join(PROJ, 'pet', 'forms', f'{fid}-1.png')
        if not os.path.exists(p):
            continue
        sp = Image.open(p).crop((16, 0, 216, 160))
        x, y = (i % cols) * cell[0], (i // cols) * cell[1]
        im.alpha_composite(sp, (x, y))
        d.text((x + 4, y + cell[1] - 14), data['forms'][fid]['name'][:20], fill=(60, 30, 30))
    im.save(path)


if __name__ == '__main__':
    ids = sys.argv[1:] or None
    render_all(ids)
    sheet(os.path.join(SCR, 'forms_sheet.png'))
    print('ok')
