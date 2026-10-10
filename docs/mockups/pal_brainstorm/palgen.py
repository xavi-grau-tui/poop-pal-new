"""Brainstorm pal renderer: simple silhouettes + small features + minimal faces,
painted with the project's hires.py shading (paint big, shrink, 2x nearest)."""
import sys, math
sys.path.insert(0, '/Users/xaviergrau/Documents/PoopPal Godot/poop-pal-main-kiro/tools/art')
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import distance_transform_edt
from hires import Canvas, material, outline, seam, to_image, shrink, OUT

K, F = 8, 0.5            # hi-res: 4 px per design unit; design canvas 110 x 100
GROUND = 93
INK = (22, 14, 20)

# ------------------------------------------------------------------ palettes
P = {
 'sour':   [(40, 58, 10), (96, 124, 22), (152, 182, 40), (192, 214, 72), (224, 236, 132), (246, 250, 212)],
 'spicy':  [(70, 10, 16), (140, 24, 30), (200, 50, 44), (232, 92, 70), (250, 150, 120), (255, 214, 190)],
 'green':  [(14, 44, 24), (28, 92, 46), (50, 144, 68), (88, 184, 94), (150, 220, 140), (222, 246, 212)],
 'greasy': [(110, 54, 6), (196, 108, 16), (240, 158, 30), (252, 196, 70), (255, 226, 140), (255, 248, 222)],
 'sweet':  [(24, 30, 48), (46, 60, 90), (82, 106, 144), (112, 140, 178), (146, 174, 208), (214, 228, 244)],
 # off-family mix colours (the "unexpected" results)
 'purple': [(34, 14, 50), (70, 30, 96), (114, 60, 146), (150, 96, 184), (192, 150, 222), (236, 220, 250)],
 'teal':   [(8, 40, 44), (16, 86, 90), (30, 138, 138), (70, 180, 170), (140, 220, 206), (220, 248, 240)],
 'coral':  [(90, 24, 30), (170, 60, 60), (226, 108, 92), (244, 148, 120), (252, 194, 166), (255, 236, 222)],
 'olive':  [(36, 40, 12), (76, 82, 24), (120, 124, 44), (160, 160, 70), (200, 196, 120), (238, 236, 200)],
 'char':   [(14, 14, 18), (34, 34, 42), (58, 58, 70), (86, 86, 100), (130, 130, 146), (200, 200, 214)],
 'cream':  [(120, 96, 70), (190, 166, 132), (226, 210, 180), (244, 234, 212), (252, 248, 236), (255, 255, 252)],
 'pink':   [(100, 30, 60), (176, 66, 104), (226, 116, 148), (244, 160, 186), (255, 206, 222), (255, 240, 246)],
 'choc':   [(36, 16, 14), (72, 36, 26), (112, 62, 42), (150, 92, 64), (196, 140, 106), (236, 200, 170)],
 'mint':   [(20, 70, 60), (50, 130, 110), (100, 190, 160), (150, 222, 196), (200, 244, 226), (240, 255, 248)],
 'lilac':  [(60, 50, 90), (110, 96, 150), (156, 142, 196), (190, 178, 224), (220, 212, 242), (248, 244, 255)],
 'rust':   [(60, 20, 8), (120, 46, 16), (176, 80, 30), (210, 116, 56), (236, 166, 110), (252, 222, 190)],
 'navy':   [(10, 14, 30), (20, 30, 62), (36, 52, 100), (58, 80, 136), (96, 120, 176), (170, 190, 230)],
 'gold':   [(110, 66, 10), (176, 120, 20), (226, 176, 40), (250, 214, 90), (255, 244, 190), (255, 255, 240)],
 'metal':  [(36, 40, 52), (80, 88, 106), (130, 140, 160), (176, 186, 204), (222, 230, 242), (255, 255, 255)],
 'goo':    [(30, 60, 20), (60, 130, 30), (110, 200, 50), (160, 240, 90), (210, 255, 160), (245, 255, 230)],
 'ice':    [(40, 80, 110), (80, 140, 180), (130, 190, 220), (180, 225, 245), (225, 245, 255), (255, 255, 255)],
 'lime':   [(40, 70, 10), (90, 150, 20), (150, 210, 40), (196, 240, 80), (230, 255, 150), (250, 255, 225)],
 'magenta':[(70, 8, 50), (140, 20, 96), (200, 50, 140), (230, 100, 180), (248, 170, 220), (255, 230, 245)],
 'white':  [(140, 140, 150), (196, 196, 206), (228, 228, 236), (244, 244, 250), (252, 252, 255), (255, 255, 255)],
 'flame':  [(150, 20, 10), (226, 70, 24), (250, 140, 40), (255, 200, 80), (255, 244, 190), (255, 255, 240)],
}
FAMS = ['green', 'sweet', 'greasy', 'spicy', 'sour']


# ------------------------------------------------------------------ geometry helpers
def sfield(c, prims):
    """metaball field; prim = (cx, cy, rx, ry[, p, w]); p=2 ellipse, 4 rounded box, 1.2 diamond."""
    Fd = np.zeros_like(c.x)
    for b in prims:
        cx, cy, rx, ry = b[:4]
        p = b[4] if len(b) > 4 else 2
        w = b[5] if len(b) > 5 else 1.0
        d = (np.abs((c.x - cx) / rx) ** p + np.abs((c.y - cy) / ry) ** p) ** (2 / p)
        Fd += w / np.maximum(d, 1e-4)
    return Fd


def polymask(c, polys, ellipses=(), lines=()):
    im = Image.new('L', (c.w * c.k, c.h * c.k), 0)
    d = ImageDraw.Draw(im)
    for poly in polys:
        d.polygon([c.P(x, y) for x, y in poly], fill=255)
    for (x, y, rx, ry) in ellipses:
        d.ellipse([*c.P(x - rx, y - ry), *c.P(x + rx, y + ry)], fill=255)
    for (pts, wd) in lines:
        d.line([c.P(x, y) for x, y in pts], fill=255, width=max(1, int(wd * c.k * c.f)), joint='curve')
        for x, y in (pts[0], pts[-1]):
            r = wd / 2
            d.ellipse([*c.P(x - r, y - r), *c.P(x + r, y + r)], fill=255)
    return np.asarray(im) > 127


def hmap(c, mask, depth=9.0):
    d = distance_transform_edt(mask) / (c.k * c.f)
    return np.clip(d / depth, 0, 1) ** 0.5


def draw_on(c, fn):
    im = to_image(c)
    d = ImageDraw.Draw(im, 'RGBA')
    fn(d)
    a = np.asarray(im, np.float32)
    c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


def W(c, v):
    return max(1, int(v * c.k * c.f))


# ------------------------------------------------------------------ base shapes (baby size, ground-anchored, x around 0)
SHAPES = {
 'blob':    [(0, -9, 17, 9), (0, -18, 14, 11), (0, -26, 10, 7)],             # the Picklet blob
 'dome':    [(0, -8, 20, 8), (0, -17, 16, 11)],
 'drop':    [(0, -8, 18, 8), (0, -16, 15, 9), (0, -24, 9, 7), (0, -31, 4, 4)],
 'bean':    [(0, -9, 13, 9), (0, -20, 12, 11), (0, -31, 10, 8)],
 'loaf':    [(0, -7, 25, 7), (0, -14, 20, 8)],
 'box':     [(0, -14, 16, 14, 4.5)],
 'tallbox': [(0, -18, 13, 18, 4.5)],
 'peanut':  [(0, -9, 15, 9), (0, -26, 11, 9)],
 'pear':    [(0, -10, 18, 10), (0, -24, 10, 9)],
 'cone':    [(0, -7, 19, 7), (0, -15, 13, 8), (0, -23, 8, 7), (0, -30, 4, 5)],
 'disc':    [(0, -6, 26, 6), (0, -11, 19, 6)],
 'egg':     [(0, -12, 15, 12), (0, -22, 11, 10)],
 'diamond': [(0, -17, 17, 17, 1.4)],
 'twin':    [(-8, -12, 11, 12), (8, -12, 11, 12), (0, -7, 18, 7)],
 'mochi':   [(0, -9, 22, 9, 3), (0, -15, 16, 9)],
 'onion':   [(0, -11, 16, 11), (0, -24, 7, 8), (0, -32, 3, 5)],
 'bell':    [(0, -6, 21, 6), (0, -16, 14, 10), (0, -26, 10, 7)],
 'kiss':    [(0, -7, 19, 7), (0, -15, 14, 8), (0, -22, 8, 6), (0, -28, 4, 5), (2, -33, 2, 3)],
 'puff':    [(-10, -10, 10, 10), (10, -10, 10, 10), (0, -19, 12, 11), (0, -8, 16, 8)],
 'ball':    [(0, -15, 15, 15)],
 'tower':   [(0, -9, 14, 9), (0, -22, 12, 9), (0, -34, 9, 8)],
 'wedge':   [(0, -12, 18, 12, 1.6), (0, -7, 20, 7)],
 'bun':     [(0, -6, 22, 6, 3), (0, -13, 19, 9)],
}
STAGE = {'baby': 1.0, 'kid': 1.25, 'adult': 1.5, 'mutant': 1.5, 'legend': 1.62}


def body_prims(shape, s, sx=1.0):
    out = []
    for b in SHAPES[shape]:
        x, y, rx, ry = b[:4]
        out.append((55 + x * s * sx, GROUND + y * s, rx * s * sx, ry * s, *b[4:]))
    return out


class Geo:
    """measurements of the body mask in design units."""
    def __init__(s, c, mask):
        ys, xs = np.nonzero(mask)
        k = c.k * c.f
        s.top = ys.min() / k; s.bot = ys.max() / k
        s.l = xs.min() / k; s.r = xs.max() / k
        s.h = s.bot - s.top; s.w = s.r - s.l
        s.mask, s.k = mask, k

    def top_at(s, x):
        col = s.mask[:, min(max(int(x * s.k), 0), s.mask.shape[1] - 1)]
        ys = np.nonzero(col)[0]
        return ys.min() / s.k if len(ys) else s.bot

    def half_w(s, y):
        row = s.mask[min(max(int(y * s.k), 0), s.mask.shape[0] - 1)]
        xs = np.nonzero(row)[0]
        return (xs.max() - xs.min()) / s.k / 2 if len(xs) else 0


# ------------------------------------------------------------------ faces (small, mostly un-smiley)
def face(c, g, style, fx=55, fy=None, spread=None, er=None, light=False):
    u = g.w / 36
    fy = fy if fy is not None else g.top + g.h * 0.55
    sp = spread if spread is not None else 7.5 * max(u, .9) ** .8
    er = er if er is not None else 1.9 * max(u, .9) ** .6
    ink = (236, 236, 240) if light else INK
    lw = W(c, er * .62)
    e1, e2 = fx - sp, fx + sp
    P = c.P

    def dot(d, x, y, r=er, hl=True, col=None):
        d.ellipse([*P(x - r, y - r * 1.12), *P(x + r, y + r * 1.12)], fill=col or ink)
        if hl and not light and r > 1.4:
            d.ellipse([*P(x - r * .55, y - r * .8), *P(x - r * .05, y - r * .3)], fill=(255, 255, 255, 220))

    def line(d, pts, w=None):
        d.line([P(x, y) for x, y in pts], fill=ink, width=w or lw, joint='curve')

    def mouth_flat(d, w=2.2):
        line(d, [(fx - w * u ** .5, fy + er * 2.1), (fx + w * u ** .5, fy + er * 2.1)])

    def fn(d):
        st = style
        if st in ('dot', 'flat', 'o', 'cat', 'smirk', 'fang', 'stern', 'worried', 'focus', 'zip', 'tiny', 'close', 'pout'):
            r = er * (.7 if st == 'tiny' else 1)
            s_ = sp * (1.35 if st == 'tiny' else .72 if st == 'close' else 1)
            for e in (fx - s_, fx + s_):
                dot(d, e, fy, r)
        if st == 'flat' or st == 'focus':
            mouth_flat(d)
        if st == 'o':
            r = er * .65
            d.ellipse([*P(fx - r, fy + er * 1.6), *P(fx + r, fy + er * 1.6 + r * 2.2)], fill=ink)
        if st == 'cat':
            m = fy + er * 1.9; w_ = er * .9
            line(d, [(fx - 2 * w_, m), (fx - w_, m + w_ * .8), (fx, m), (fx + w_, m + w_ * .8), (fx + 2 * w_, m)])
        if st == 'smirk':
            line(d, [(fx - .5 * er, fy + er * 2.3), (fx + 1.6 * er, fy + er * 2.0), (fx + 2.2 * er, fy + er * 1.5)])
        if st == 'pout':
            line(d, [(fx - 1.3 * er, fy + er * 2.5), (fx, fy + er * 2.0), (fx + 1.3 * er, fy + er * 2.5)])
        if st == 'fang':
            mouth_flat(d, 2.6)
            m = fy + er * 2.1
            d.polygon([P(fx + .4 * er, m), P(fx + 1.4 * er, m), P(fx + .9 * er, m + er * 1.1)], fill=(255, 255, 255))
        if st == 'stern':      # calm, determined: flat low brows, not angry
            for e, sgn in ((fx - sp, 1), (fx + sp, -1)):
                line(d, [(e - er * 1.4, fy - er * 2.0 - sgn * .0), (e + er * 1.4, fy - er * 1.5 + 0)] if sgn > 0 else
                        [(e - er * 1.4, fy - er * 1.5), (e + er * 1.4, fy - er * 2.0)])
            mouth_flat(d, 1.6)
        if st == 'worried':
            for e, sgn in ((fx - sp, 1), (fx + sp, -1)):
                line(d, [(e - er * 1.3, fy - er * 1.6), (e + er * 1.3, fy - er * 2.3)] if sgn > 0 else
                        [(e - er * 1.3, fy - er * 2.3), (e + er * 1.3, fy - er * 1.6)])
            line(d, [(fx - 1.3 * er, fy + er * 2.4), (fx, fy + er * 2.0), (fx + 1.3 * er, fy + er * 2.4)])
        if st == 'zip':
            m = fy + er * 2.2
            line(d, [(fx - 2.4 * er, m), (fx + 2.4 * er, m)])
            for i in range(-2, 3):
                line(d, [(fx + i * er, m - er * .5), (fx + i * er, m + er * .5)], max(1, lw // 2))
        if st == 'side':       # glancing sideways
            for e in (fx - sp, fx + sp):
                d.ellipse([*P(e - er * 1.5, fy - er * 1.5), *P(e + er * 1.5, fy + er * 1.5)], fill=(250, 250, 246))
                dot(d, e + er * .7, fy, er * .85, hl=False, col=INK)
            mouth_flat(d, 1.4)
        if st in ('lid', 'bored'):     # half-lidded, unimpressed
            for e in (fx - sp, fx + sp):
                d.chord([*P(e - er * 1.2, fy - er * 1.2), *P(e + er * 1.2, fy + er * 1.3)], 0, 180, fill=ink)
                line(d, [(e - er * 1.6, fy - er * .05), (e + er * 1.6, fy - er * .05)])
            if st == 'bored':
                mouth_flat(d, 1.8)
        if st == 'squint':
            for e in (fx - sp, fx + sp):
                line(d, [(e - er * 1.4, fy), (e + er * 1.4, fy)])
            mouth_flat(d, 1.2)
        if st == 'sleep':
            for e in (fx - sp, fx + sp):
                d.arc([*P(e - er * 1.4, fy - er * 1.6), *P(e + er * 1.4, fy + er * 1.0)], 20, 160, fill=ink, width=lw)
        if st == 'wink':
            dot(d, fx - sp, fy)
            line(d, [(fx + sp - er * 1.3, fy + er * .2), (fx + sp, fy - er * .7), (fx + sp + er * 1.3, fy + er * .2)])
            mouth_flat(d, 1.4)
        if st == 'ring':       # hollow eyes, odd and calm
            for e in (fx - sp, fx + sp):
                d.ellipse([*P(e - er * 1.6, fy - er * 1.6), *P(e + er * 1.6, fy + er * 1.6)], outline=ink, width=lw)
                d.ellipse([*P(e - er * .35, fy - er * .35), *P(e + er * .35, fy + er * .35)], fill=ink)
        if st == 'one':
            r = er * 2.1
            d.ellipse([*P(fx - r * 1.25, fy - r * 1.25), *P(fx + r * 1.25, fy + r * 1.25)], fill=(250, 250, 246))
            dot(d, fx, fy, r * .7, col=INK)
            line(d, [(fx - er, fy + r * 1.9), (fx + er, fy + r * 1.9)])
        if st == 'tri':
            for e, y in ((fx - sp, fy), (fx + sp, fy), (fx, fy - er * 3.2)):
                dot(d, e, y, er * .9)
            mouth_flat(d, 1.4)
        if st == 'visor':
            r = er * 1.6
            d.rounded_rectangle([*P(fx - sp - r * 1.6, fy - r), *P(fx + sp + r * 1.6, fy + r)], radius=W(c, r), fill=(20, 24, 34))
            d.rounded_rectangle([*P(fx - sp - r * 1.1, fy - r * .35), *P(fx + sp + r * 1.1, fy + r * .15)], radius=W(c, r * .3), fill=(120, 240, 220))
        if st == 'x':
            for e in (fx - sp, fx + sp):
                line(d, [(e - er, fy - er), (e + er, fy + er)]); line(d, [(e - er, fy + er), (e + er, fy - er)])
            mouth_flat(d, 1.4)
        if st == 'star':
            for e in (fx - sp, fx + sp):
                pts = []
                for i in range(8):
                    r = er * (1.6 if i % 2 == 0 else .55); a = -math.pi / 2 + i * math.pi / 4
                    pts.append(P(e + r * math.cos(a), fy + r * math.sin(a)))
                d.polygon(pts, fill=ink)
        if st == 'sun':        # eyes closed, serene (legend)
            for e in (fx - sp, fx + sp):
                d.arc([*P(e - er * 1.5, fy - er * .6), *P(e + er * 1.5, fy + er * 2.2)], 200, 340, fill=ink, width=lw)
        if st == 'big':        # big glossy eyes but no smile
            for e in (fx - sp, fx + sp):
                dot(d, e, fy, er * 1.5)
            mouth_flat(d, 1.0)
        if st == 'dash':       # eyes as small vertical dashes
            for e in (fx - sp, fx + sp):
                line(d, [(e, fy - er * 1.3), (e, fy + er * 1.3)], W(c, er * 1.0))
    draw_on(c, fn)


# ------------------------------------------------------------------ the pal
def render(spec, stage):
    """spec: dict(b=shape, p=palette, a=accent palette, f=[features], e=face, sx=width mul)"""
    c = Canvas(55, 50, K, F, anchor=(55, GROUND))
    s = STAGE[stage]
    sx = spec.get('sx', 1.0)
    pal = P[spec['p']]
    acc = P[spec.get('a', spec['p'])]
    feats = spec.get('f', [])
    bm = sfield(c, body_prims(spec['b'], s, sx)) > 1
    wid = Geo(c, bm).w
    lim = 62 if stage != 'legend' else 58
    if wid > lim:
        sx *= lim / wid
        bm = sfield(c, body_prims(spec['b'], s, sx)) > 1
    g = Geo(c, bm)
    u = g.w / 36
    cx = 55
    ttop = g.top_at(cx)

    back, front, over = [], [], []          # (mask, palette)

    def fam(name):                          # feature colour token -> palette
        if name is None: return acc
        if name == 'p': return pal
        if name == 'a': return acc
        return P[name]

    for ft in feats:
        name, _, col = ft.partition(':')
        fp = fam(col or None)
        if name == 'sprout':
            m = polymask(c, [], [(cx + 4 * u, ttop - 5 * u, 4.2 * u, 2.2 * u)], [([(cx, ttop + 1), (cx + .5, ttop - 6 * u)], 1.6)])
            back.append((m, P[col] if col else P['green']))
        elif name == 'leaf2':
            m = polymask(c, [], [(cx - 4 * u, ttop - 4 * u, 4 * u, 2 * u), (cx + 4 * u, ttop - 4.5 * u, 4 * u, 2 * u)], [([(cx, ttop + 1), (cx, ttop - 4 * u)], 1.5)])
            back.append((m, P[col] if col else P['green']))
        elif name == 'stem':
            m = polymask(c, [], [], [([(cx, ttop + 2), (cx + 1.5 * u, ttop - 4 * u)], 2.0)])
            back.append((m, P[col] if col else P['choc']))
        elif name == 'horns':
            y = g.top + g.h * .22; hw = g.half_w(y)
            polys = [[(cx - hw * .75, y + 3), (cx - hw * 1.05, y - 9 * u), (cx - hw * .2, y + 1)],
                     [(cx + hw * .75, y + 3), (cx + hw * 1.05, y - 9 * u), (cx + hw * .2, y + 1)]]
            back.append((polymask(c, polys), fp))
        elif name == 'nubs':          # tiny round horns
            y = g.top + g.h * .2; hw = g.half_w(y)
            back.append((polymask(c, [], [(cx - hw * .6, y - 2.5 * u, 2.6 * u, 2.6 * u), (cx + hw * .6, y - 2.5 * u, 2.6 * u, 2.6 * u)]), fp))
        elif name == 'ears':
            y = g.top + g.h * .3; hw = g.half_w(y)
            polys = [[(cx - hw * .9, y + 3), (cx - hw * 1.15, y - 9 * u), (cx - hw * .25, y - 1)],
                     [(cx + hw * .9, y + 3), (cx + hw * 1.15, y - 9 * u), (cx + hw * .25, y - 1)]]
            back.append((polymask(c, polys), fp))
        elif name == 'longears':
            y = g.top + g.h * .25
            back.append((polymask(c, [], [(cx - 6 * u, y - 9 * u, 2.8 * u, 9 * u), (cx + 6 * u, y - 9 * u, 2.8 * u, 9 * u)]), fp))
        elif name == 'antenna':
            back.append((polymask(c, [], [(cx + 3 * u, ttop - 9 * u, 2.3 * u, 2.3 * u)], [([(cx, ttop + 1), (cx + 3 * u, ttop - 8 * u)], 1.1)]), fp))
        elif name == 'antennae':
            back.append((polymask(c, [], [(cx - 7 * u, ttop - 8 * u, 2 * u, 2 * u), (cx + 7 * u, ttop - 8 * u, 2 * u, 2 * u)],
                                  [([(cx - 3 * u, ttop + 2), (cx - 7 * u, ttop - 7 * u)], 1.0), ([(cx + 3 * u, ttop + 2), (cx + 7 * u, ttop - 7 * u)], 1.0)]), fp))
        elif name == 'crest':
            polys = []
            for i, dx in enumerate((-6, 0, 6)):
                x = cx + dx * u; t = g.top_at(x)
                hgt = (7 if dx == 0 else 5) * u
                polys.append([(x - 3 * u, t + 2), (x + dx * .2 * u, t - hgt), (x + 3 * u, t + 2)])
            back.append((polymask(c, polys), fp))
        elif name == 'spikes':        # spikes all round the top edge
            polys = []
            for dx in (-12, -6, 0, 6, 12):
                x = cx + dx * u
                if x < g.l + 2 or x > g.r - 2: continue
                t = g.top_at(x)
                polys.append([(x - 2.5 * u, t + 2), (x + dx * .15 * u, t - 4.5 * u), (x + 2.5 * u, t + 2)])
            back.append((polymask(c, polys), fp))
        elif name == 'fins':
            y = g.top + g.h * .55; hw = g.half_w(y)
            polys = [[(cx - hw + 2, y - 4 * u), (cx - hw - 7 * u, y - 7 * u), (cx - hw - 4 * u, y + 3 * u), (cx - hw + 2, y + 3 * u)],
                     [(cx + hw - 2, y - 4 * u), (cx + hw + 7 * u, y - 7 * u), (cx + hw + 4 * u, y + 3 * u), (cx + hw - 2, y + 3 * u)]]
            back.append((polymask(c, polys), fp))
        elif name == 'arms':
            y = g.top + g.h * .68; hw = g.half_w(y)
            front.append((polymask(c, [], [(cx - hw, y, 3.2 * u, 2.4 * u), (cx + hw, y, 3.2 * u, 2.4 * u)]), fp))
        elif name == 'feet':
            front.append((polymask(c, [], [(cx - 7 * u, g.bot - 1, 4.2 * u, 2.4 * u), (cx + 7 * u, g.bot - 1, 4.2 * u, 2.4 * u)]), fp))
        elif name == 'legs':
            ls = []
            for dx in (-9, -3, 3, 9):
                ls.append(([(cx + dx * u, g.bot - 4), (cx + dx * 1.15 * u, g.bot + 2.5)], 1.6 * u))
            back.append((polymask(c, [], [], ls), fp))
        elif name == 'tail':
            y = g.bot - g.h * .3; x = g.r - 2
            back.append((polymask(c, [], [(x + 7 * u, y - 7 * u, 2.6 * u, 2.6 * u)], [([(x - 3, y + 2), (x + 4 * u, y), (x + 7 * u, y - 6 * u)], 2.4 * u)]), fp))
        elif name == 'wings':
            y = g.top + g.h * .45; hw = g.half_w(y)
            polys = [[(cx - hw + 3, y + 3 * u), (cx - hw - 10 * u, y - 9 * u), (cx - hw - 7 * u, y + 1 * u), (cx - hw - 9 * u, y + 5 * u), (cx - hw + 3, y + 6 * u)],
                     [(cx + hw - 3, y + 3 * u), (cx + hw + 10 * u, y - 9 * u), (cx + hw + 7 * u, y + 1 * u), (cx + hw + 9 * u, y + 5 * u), (cx + hw - 3, y + 6 * u)]]
            back.append((polymask(c, polys), fp))
        elif name == 'petals':
            els = []
            for i in range(7):
                a = math.pi + i * math.pi / 6
                els.append((cx + math.cos(a) * g.w * .48, g.top + g.h * .45 + math.sin(a) * g.h * .55, 4.5 * u, 4.5 * u))
            back.append((polymask(c, [], els), fp))
        elif name == 'flame':
            t = ttop
            poly = [(cx - 6 * u, t + 3), (cx - 5 * u, t - 5 * u), (cx - 2 * u, t - 2 * u), (cx, t - 11 * u), (cx + 3 * u, t - 3 * u),
                    (cx + 5 * u, t - 7 * u), (cx + 6 * u, t + 3)]
            back.append((polymask(c, [poly]), P[col] if col else P['flame']))
        elif name == 'tuft':
            t = ttop
            back.append((polymask(c, [], [], [([(cx - 1, t + 2), (cx + 1 * u, t - 4 * u), (cx + 5 * u, t - 6 * u)], 2.2 * u)]), fp))
        elif name == 'mushcap':
            t = g.top + g.h * .28; hw = g.w * .68
            m = polymask(c, [], [(cx, t, hw, g.h * .32)]) & (c.y < t + g.h * .06)
            front.append((m, fp))
        elif name == 'halo':
            m = polymask(c, [], [(cx, g.top - 6 * u, 9 * u, 2.6 * u)]) & ~polymask(c, [], [(cx, g.top - 6 * u, 6.5 * u, 1.2 * u)])
            back.append((m, P['gold']))
        elif name == 'crown':
            t = ttop
            poly = [(cx - 7 * u, t + 2), (cx - 8 * u, t - 6 * u), (cx - 4 * u, t - 2.5 * u), (cx, t - 8 * u), (cx + 4 * u, t - 2.5 * u), (cx + 8 * u, t - 6 * u), (cx + 7 * u, t + 2)]
            front.append((polymask(c, [poly]) & (c.y < t + 2.5), P['gold']))
        elif name == 'tentacles':
            ls = []
            for dx in (-12, -6, 0, 6, 12):
                x = cx + dx * u
                ls.append(([(x, g.bot - 6), (x + 2 * u * np.sign(dx or 1), g.bot), (x - 1 * u * np.sign(dx or 1), g.bot + 3)], 3 * u))
            back.append((polymask(c, [], [], ls), fp))
        elif name == 'ring':
            y = g.top + g.h * .62
            outer = polymask(c, [], [(cx, y, g.w * .75, 5 * u)]); inner = polymask(c, [], [(cx, y - .5 * u, g.w * .58, 2.6 * u)])
            rm = outer & ~inner
            back.append((rm & (c.y < y), fp)); front.append((rm & (c.y >= y), fp))
        elif name == 'shell':
            t = g.top + g.h * .1
            front.append((bm & (c.y < t + g.h * .38), fp))
        elif name == 'hood':
            front.append((bm & ((c.y - (g.top + g.h * .62)) < -0.0) & ~polymask(c, [], [(cx, g.top + g.h * .58, g.w * .3, g.h * .2)]), fp))
        elif name == 'twig':
            back.append((polymask(c, [], [], [([(cx - 2 * u, ttop + 2), (cx - 4 * u, ttop - 7 * u)], 1.6), ([(cx - 3.2 * u, ttop - 4 * u), (cx + 1 * u, ttop - 7 * u)], 1.2)]), P[col] if col else P['choc']))
        elif name == 'gem':
            y = g.top + g.h * .3
            poly = [(cx, y - 3 * u), (cx + 2.4 * u, y), (cx, y + 3 * u), (cx - 2.4 * u, y)]
            over.append(('poly', poly, fp))
        else:
            over.append((name, None, fp))

    # paint: back parts, body, body accents, front parts
    for m, p in back:
        material(c, hmap(c, m, 4), m & ~bm, p, bump=4, spec_amt=.35, grain=.06)
    bh = hmap(c, bm, 7 + 4 * u)
    material(c, bh, bm, pal, bump=4, spec_amt=.4, spec_pow=22, grain=.07)
    for m, p in back:
        seam(c, bm, m & ~bm, .5)
    # region accents painted into the body
    for ft in feats:
        name, _, col = ft.partition(':')
        fp = fam(col or None)
        reg = None
        if name == 'cap':
            reg = bm & (c.y < g.top + g.h * .42 + 1.5 * np.sin(c.x * .9))
        elif name == 'drip':
            base = g.top + g.h * .38
            dr = base + 1.2 * np.sin(c.x * .7) + 7 * u * np.exp(-((c.x - (cx - 9 * u)) / 1.6) ** 2) + 9 * u * np.exp(-((c.x - (cx + 7 * u)) / 1.8) ** 2)
            reg = bm & (c.y < dr)
        elif name == 'base':
            reg = bm & (c.y > g.bot - g.h * .3)
        elif name == 'band':
            y0 = g.top + g.h * .66
            reg = bm & (c.y > y0) & (c.y < y0 + g.h * .14)
        elif name == 'belly':
            reg = bm & polymask(c, [], [(cx, g.bot - g.h * .12, g.w * .24, g.h * .16)])
        elif name == 'half':
            reg = bm & (c.x > cx + .8 * np.sin(c.y * .8))
        elif name == 'diag':
            reg = bm & ((c.x - cx) * .7 + (c.y - (g.top + g.h * .5)) < 0)
        elif name == 'spots':
            rr = np.random.default_rng(int(g.w * 7))
            els = []
            for _ in range(6):
                els.append((rr.uniform(g.l + 4, g.r - 4), rr.uniform(g.top + 3, g.bot - 4), 2.2 * u, 2.0 * u))
            reg = bm & polymask(c, [], els)
            fy = g.top + g.h * .55
            reg &= ~polymask(c, [], [(cx, fy + 1, 11 * u, 5 * u)])
        elif name == 'stripes':
            reg = bm & (np.sin((c.x - cx) * 1.0 / u) > .55) & (c.y < g.top + g.h * .45)
        elif name == 'hstripes':
            reg = bm & (np.sin((c.y - g.bot) * 1.1 / u) > .6) & (c.y > g.top + g.h * .72)
        elif name == 'tip':
            reg = bm & (c.y < g.top + g.h * .2)
        elif name == 'mask':
            fy = g.top + g.h * .55
            reg = bm & (np.abs(c.y - fy) < 2.6 * u)
        if reg is not None:
            material(c, bh, reg, fp, bump=4, spec_amt=.4, spec_pow=22, grain=.07)
            seam(c, reg, bm & ~reg, .45)
    for m, p in front:
        material(c, hmap(c, m, 4), m, p, bump=4, spec_amt=.4, grain=.06)
        seam(c, m, bm & ~m, .5)
    outline(c, c.a > .5, 1.0)

    # overlay details
    def deco(d):
        P_ = c.P
        for name, poly, fp in over:
            dk = tuple(int(v) for v in fp[1]); lt = tuple(int(v) for v in fp[-2])
            if name == 'poly':
                d.polygon([P_(x, y) for x, y in poly], fill=tuple(int(v) for v in fp[3]), outline=INK)
            elif name == 'freckles':
                fy = g.top + g.h * .55 + 3.6 * u
                for sgn in (-1, 1):
                    for i in range(3):
                        x = cx + sgn * (8.5 + i * 1.3) * u; y = fy + (i % 2) * u
                        d.ellipse([*P_(x - .5, y - .5), *P_(x + .5, y + .5)], fill=dk)
            elif name == 'seeds':
                rr = np.random.default_rng(3)
                for _ in range(int(14 * u)):
                    x, y = rr.uniform(g.l + 3, g.r - 3), rr.uniform(g.top + 2, g.bot - 2)
                    if not g.mask[min(int(y * g.k), g.mask.shape[0] - 1), int(x * g.k)]: continue
                    if abs(y - (g.top + g.h * .58)) < 5 * u and abs(x - cx) < 12 * u: continue
                    d.ellipse([*P_(x - .55, y - .8), *P_(x + .55, y + .8)], fill=lt)
            elif name == 'crack':
                y = g.top + g.h * .25; x = cx + g.w * .2
                d.line([P_(x, y), P_(x - 2 * u, y + 3 * u), P_(x + 1 * u, y + 5 * u), P_(x - 1 * u, y + 8 * u)], fill=INK, width=W(c, .7))
            elif name == 'bolts':
                y = g.top + g.h * .6
                for sgn in (-1, 1):
                    x = cx + sgn * (g.half_w(y) + .5)
                    d.rectangle([*P_(x - 1.6 * u, y - 1.2 * u), *P_(x + 1.6 * u, y + 1.2 * u)], fill=(150, 160, 176), outline=INK)
            elif name == 'chip':
                y = g.top + g.h * .28; r = 3 * u
                d.rectangle([*P_(cx - r, y - r * .8), *P_(cx + r, y + r * .8)], fill=(40, 46, 56), outline=INK)
                for i in (-1, 0, 1):
                    d.line([P_(cx + i * r * .55, y - r * .8), P_(cx + i * r * .55, y - r * 1.3)], fill=(220, 190, 80), width=W(c, .5))
                    d.line([P_(cx + i * r * .55, y + r * .8), P_(cx + i * r * .55, y + r * 1.3)], fill=(220, 190, 80), width=W(c, .5))
                d.rectangle([*P_(cx - r * .4, y - r * .3), *P_(cx + r * .4, y + r * .3)], fill=(90, 220, 200))
            elif name == 'stache':
                y = g.top + g.h * .55 + 4 * u
                for sgn in (-1, 1):
                    d.chord([*P_(cx + (sgn < 0) * -5 * u, y - 1.6 * u), *P_(cx + (sgn > 0) * 5 * u, y + 1.6 * u)], 180, 360, fill=dk)
            elif name == 'bubbles':
                for (dx, dy, r) in ((-1.0, -.2, 1.6), (-1.15, -.55, 1.0), (1.05, -.4, 1.3), (1.2, -.75, .8)):
                    x = cx + dx * g.w * .55; y = g.top + g.h * .5 + dy * g.h
                    d.ellipse([*P_(x - r * u, y - r * u), *P_(x + r * u, y + r * u)], outline=dk, width=W(c, .45))
            elif name == 'steam':
                for dx in (-5, 0, 5):
                    x = cx + dx * u; t = g.top_at(x) - 3
                    d.line([P_(x, t), P_(x + 1.2, t - 2), P_(x - 1.2, t - 4), P_(x, t - 6)], fill=(200, 200, 210), width=W(c, .7), joint='curve')
            elif name == 'sparkles':
                for (x, y, r) in ((g.l - 3, g.top + 4, 2.4), (g.r + 3, g.top + 10, 1.8), (g.r + 1, g.bot - 6, 1.4)):
                    d.polygon([P_(x, y - r), P_(x + r * .3, y - r * .3), P_(x + r, y), P_(x + r * .3, y + r * .3), P_(x, y + r),
                               P_(x - r * .3, y + r * .3), P_(x - r, y), P_(x - r * .3, y - r * .3)], fill=(255, 236, 140))
            elif name == 'drop':
                x = g.r - 3; y = g.top + g.h * .3
                d.polygon([P_(x, y - 2.6 * u), P_(x + 1.5 * u, y), P_(x - 1.5 * u, y)], fill=(170, 220, 255))
                d.ellipse([*P_(x - 1.5 * u, y - 1.4 * u), *P_(x + 1.5 * u, y + 1.6 * u)], fill=(170, 220, 255))
            elif name == 'scar':
                pass
            elif name == 'glow':
                pass
            elif name == 'dots3':
                y = g.top + g.h * .25
                for dx in (-3, 0, 3):
                    d.ellipse([*P_(cx + dx * u - .8 * u, y - .8 * u), *P_(cx + dx * u + .8 * u, y + .8 * u)], fill=lt)
            elif name == 'line':
                y = g.top + g.h * .22
                d.line([P_(cx - 5 * u, y), P_(cx + 5 * u, y)], fill=dk, width=W(c, .8))
            elif name == 'blush':
                fy = g.top + g.h * .55 + 2.8 * u
                for sgn in (-1, 1):
                    x = cx + sgn * 10 * u
                    d.ellipse([*P_(x - 2 * u, fy - .9 * u), *P_(x + 2 * u, fy + .9 * u)], fill=(236, 120, 130, 150))
    draw_on(c, deco)
    light = spec['p'] in ('char', 'navy', 'choc') and not spec.get('darkeyes')
    face(c, g, spec.get('e', 'dot'), fy=g.top + g.h * spec.get('fy', .55), light=light)
    _, small = shrink(c)
    return small.resize((110, 100), Image.NEAREST)
