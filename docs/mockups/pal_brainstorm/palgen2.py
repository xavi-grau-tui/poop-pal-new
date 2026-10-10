"""Brainstorm pals in the CURRENT Poop Pal art style: same canvas, resolution (K=20), stage sizes,
metaball soft shading, outline and face proportions as tools/art/forms_gen.py, but every pal gets
its own silhouette and parts instead of 'family body + food topping'."""
import sys, math
sys.path.insert(0, '/Users/xaviergrau/Documents/PoopPal Godot/poop-pal-main-kiro/tools/art')
import numpy as np
from PIL import Image, ImageDraw
from hires import Canvas, field, height, material, outline, seam, paint, to_image, shrink, OUT
import forms_gen as fg
from forms_gen import F, W, H, K, top_spicy, crown, halo, stem as fg_stem, GREEN, PICKLE
from palgen import P as PAL0, SHAPES

GROUND = 93
INK = (18, 8, 14)
P = dict(PAL0)
P['sour'] = PICKLE                      # Picklet's own green-yellow
P['leaf'] = GREEN
STAGE = {'baby': 1.25, 'kid': 1.58, 'adult': 1.88, 'mutant': 1.88, 'legend': 2.0}
EYE = {'baby': (5.4, 10.5), 'kid': (5.2, 11.5), 'adult': (5.0, 12.5), 'mutant': (5.0, 12.5), 'legend': (5.2, 13.5)}
SHINY = {'greasy': (.75, 16), 'spicy': (.7, 18), 'gold': (.75, 16), 'metal': (.8, 14), 'goo': (.7, 16), 'sweet': (.5, 20),
         'navy': (.5, 20), 'choc': (.5, 20), 'coral': (.55, 18), 'ice': (.7, 16)}


def sfield(c, prims):
    Fd = np.zeros_like(c.x)
    for b in prims:
        cx, cy, rx, ry = b[:4]
        p = b[4] if len(b) > 4 else 2
        w = b[5] if len(b) > 5 else 1.0
        d = (np.abs((c.x - cx) / rx) ** p + np.abs((c.y - cy) / ry) ** p) ** (2 / p)
        Fd += w / np.maximum(d, 1e-4)
    return Fd


def chain(p0, p1, r0, r1, n=6, bend=0.0):
    """balls along a (slightly bent) line, radius tapering r0 -> r1: horns, ears, spikes, fins, tails."""
    (x0, y0), (x1, y1) = p0, p1
    nx, ny = -(y1 - y0), (x1 - x0)
    L = math.hypot(nx, ny) or 1
    out = []
    for j in range(n):
        t = j / (n - 1)
        b = math.sin(t * math.pi) * bend
        r = r0 + (r1 - r0) * t
        out.append((x0 + (x1 - x0) * t + nx / L * b, y0 + (y1 - y0) * t + ny / L * b, r, r))
    return out


def draw_on(c, fn):
    im = to_image(c)
    d = ImageDraw.Draw(im, 'RGBA')
    fn(d)
    a = np.asarray(im, np.float32)
    c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


def Wd(c, v):
    return max(2, int(v * c.k * c.f))


class Geo:
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

    def inside(s, x, y):
        return s.mask[min(max(int(y * s.k), 0), s.mask.shape[0] - 1), min(max(int(x * s.k), 0), s.mask.shape[1] - 1)]


# ------------------------------------------------------------------ faces, current proportions, mostly not smiling
def face(c, g, style, stage, fy, light=False):
    er, sp = EYE[stage]
    sp = min(sp, g.half_w(fy) * .5)
    cx = 55
    u = er / 3.4
    ink = (240, 236, 240) if light else INK
    my = fy + 3.0 * u
    lw = Wd(c, 1.3)
    P_ = c.P
    ex = (cx - sp, cx + sp)

    def glossy(d, x, y, r):
        d.ellipse([*P_(x - r, y - r * 1.1), *P_(x + r, y + r * 1.1)], fill=INK)
        d.ellipse([*P_(x - r * .55, y - r * .75), *P_(x + r * .15, y - r * .05)], fill=(255, 255, 255))

    def dot(d, x, y, r):
        d.ellipse([*P_(x - r, y - r), *P_(x + r, y + r)], fill=ink)

    def flat(d, w=1.6):
        d.line([P_(cx - w * u, my + 1.2 * u), P_(cx + w * u, my + 1.2 * u)], fill=ink, width=lw)

    def fn(d):
        st = style
        if st in ('flat', 'dot', 'o', 'cat', 'fang', 'pout', 'smirk', 'zip'):      # Picklet dots
            for e in ex: dot(d, e, fy, er * .55)
        if st == 'flat': flat(d)
        if st == 'o':
            d.ellipse([*P_(cx - 1.1 * u, my), *P_(cx + 1.1 * u, my + 2.6 * u)], fill=ink)
        if st == 'cat':
            m = my + .8 * u
            d.line([P_(cx - 2.4 * u, m), P_(cx - 1.2 * u, m + 1 * u), P_(cx, m), P_(cx + 1.2 * u, m + 1 * u), P_(cx + 2.4 * u, m)], fill=ink, width=lw, joint='curve')
        if st == 'fang':
            flat(d, 2.0)
            d.polygon([P_(cx + .3 * u, my + 1.2 * u), P_(cx + 1.6 * u, my + 1.2 * u), P_(cx + .95 * u, my + 2.8 * u)], fill=(255, 255, 255))
        if st == 'pout':
            d.line([P_(cx - 1.6 * u, my + 2 * u), P_(cx, my + 1 * u), P_(cx + 1.6 * u, my + 2 * u)], fill=ink, width=lw)
        if st == 'smirk':
            d.line([P_(cx - 1.2 * u, my + 1.6 * u), P_(cx + 1.2 * u, my + 1.4 * u), P_(cx + 2 * u, my + .6 * u)], fill=ink, width=lw)
        if st == 'zip':
            d.line([P_(cx - 2.6 * u, my + 1.2 * u), P_(cx + 2.6 * u, my + 1.2 * u)], fill=ink, width=lw)
            for i in range(-2, 3):
                d.line([P_(cx + i * 1.1 * u, my + .5 * u), P_(cx + i * 1.1 * u, my + 1.9 * u)], fill=ink, width=max(2, lw // 2))
        if st in ('big', 'stern', 'worried', 'tiny'):     # glossy current-style eyes, no smile
            r = er * (.75 if st == 'tiny' else 1)
            for e in ex: glossy(d, e, fy, r)
            if st == 'big': flat(d, 1.2)
            if st == 'tiny':
                d.ellipse([*P_(cx - .8 * u, my + .6 * u), *P_(cx + .8 * u, my + 2.2 * u)], fill=ink)
            for i, e in enumerate(ex):
                side = -1 if i == 0 else 1
                inner, outer = e - side * er * 1.0, e + side * er * 1.1
                if st == 'stern':      # level, determined: a flat brow just over the eye
                    d.line([P_(inner, fy - er * 1.45), P_(outer, fy - er * 1.6)], fill=ink, width=Wd(c, 1.4 * u))
                if st == 'worried':
                    d.line([P_(inner, fy - er * 1.9), P_(outer, fy - er * 1.4)], fill=ink, width=Wd(c, 1.4 * u))
            if st == 'stern': flat(d, 1.3)
            if st == 'worried':
                d.arc([*P_(cx - 2.2 * u, my + .8 * u), *P_(cx + 2.2 * u, my + 4.0 * u)], 200, 340, fill=ink, width=lw)
        if st in ('lid', 'bored'):     # half-closed, unimpressed (evil eyes without the grin)
            for e in ex:
                d.chord([*P_(e - er, fy - er), *P_(e + er, fy + er)], 0, 180, fill=INK)
                d.ellipse([*P_(e + er * .1, fy + er * .05), *P_(e + er * .55, fy + er * .5)], fill=(255, 255, 255))
                d.line([P_(e - er * 1.15, fy - er * .02), P_(e + er * 1.15, fy - er * .02)], fill=INK, width=Wd(c, 1.1))
            if st == 'bored': flat(d, 1.4)
        if st == 'side':
            for e in ex:
                d.ellipse([*P_(e - er * .95, fy - er * 1.05), *P_(e + er * .95, fy + er * 1.05)], fill=(252, 250, 244), outline=INK, width=Wd(c, .8))
                d.ellipse([*P_(e + er * .05, fy - er * .45), *P_(e + er * .85, fy + er * .45)], fill=INK)
            flat(d, 1.2)
        if st == 'squint':
            for e in ex:
                d.line([P_(e - er * .9, fy), P_(e + er * .9, fy)], fill=ink, width=Wd(c, 1.5))
            flat(d, 1.0)
        if st == 'sleep':
            for e in ex:
                d.arc([*P_(e - er * .9, fy - er * .9), *P_(e + er * .9, fy + er * .7)], 20, 160, fill=ink, width=Wd(c, 1.5))
            d.ellipse([*P_(cx - .7 * u, my + .8 * u), *P_(cx + .7 * u, my + 2.0 * u)], fill=ink)
        if st == 'dash':
            for e in ex:
                d.line([P_(e, fy - er * .8), P_(e, fy + er * .8)], fill=ink, width=Wd(c, 1.7))
        if st == 'wink':
            dot(d, ex[0], fy, er * .55)
            d.line([P_(ex[1] - er * .8, fy + er * .2), P_(ex[1], fy - er * .5), P_(ex[1] + er * .8, fy + er * .2)], fill=ink, width=Wd(c, 1.4))
            flat(d, 1.2)
        if st == 'ring':
            for e in ex:
                d.ellipse([*P_(e - er * .95, fy - er * .95), *P_(e + er * .95, fy + er * .95)], outline=ink, width=Wd(c, 1.3))
                dot(d, e, fy, er * .3)
        if st == 'one':
            r = er * 1.55
            d.ellipse([*P_(cx - r, fy - r), *P_(cx + r, fy + r)], fill=(252, 250, 244), outline=INK, width=Wd(c, .9))
            glossy(d, cx, fy, r * .55)
            d.line([P_(cx - 1.3 * u, fy + r + 2.2 * u), P_(cx + 1.3 * u, fy + r + 2.2 * u)], fill=ink, width=lw)
        if st == 'tri':
            for e, yy, r in [(ex[0], fy, er * .8), (ex[1], fy, er * .8), (cx, fy - er * 1.9, er * .7)]:
                d.ellipse([*P_(e - r, yy - r * 1.1), *P_(e + r, yy + r * 1.1)], fill=INK)
                d.ellipse([*P_(e - r * .55, yy - r * .75), *P_(e + r * .15, yy - r * .05)], fill=(190, 255, 220))
            flat(d, 1.2)
        if st == 'visor':
            d.rounded_rectangle([*P_(cx - sp - er * 1.6, fy - er), *P_(cx + sp + er * 1.6, fy + er)], radius=int(er * c.k * c.f), fill=(20, 24, 34))
            for e in ex:
                d.rectangle([*P_(e - er * .8, fy - er * .35), *P_(e + er * .8, fy + er * .35)], fill=(120, 255, 200))
        if st == 'sun':
            for e in ex:
                d.arc([*P_(e - er, fy - er * .4), *P_(e + er, fy + er * 1.4)], 200, 340, fill=ink, width=Wd(c, 1.5))
        if st == 'star':
            for e in ex:
                pts = []
                for i in range(10):
                    r = er * (1.15 if i % 2 == 0 else .5); a = -math.pi / 2 + i * math.pi / 5
                    pts.append(P_(e + r * math.cos(a), fy + r * math.sin(a)))
                d.polygon(pts, fill=INK)
            flat(d, 1.2)
    draw_on(c, fn)


# ------------------------------------------------------------------ the pal
PROJ = '/Users/xaviergrau/Documents/PoopPal Godot/poop-pal-main-kiro'


def special(name):
    if name == 'picklet':                       # kept exactly as it is in the game
        return Image.open(PROJ + '/textures/pet/forms/picklet-1.png').convert('RGBA').crop((60, 60, 170, 160))
    if name.startswith('ember'):                # Ember's own body + stem, calmer face
        style = name.partition(':')[2] or 'big'
        c = Canvas(W, H, K, F, anchor=(55, GROUND))
        f, m, top, fy = fg.body(c, 'H', 1.3)
        fg_stem(c, 57.5, top + .5, 1.3)
        outline(c, c.a > .5, 1.0)
        outline(c, c.a > .5, 1.0)
        if style.endswith('+blush'):
            style = style[:-6]
            def bl(d):
                for sd in (-1, 1):
                    x = 55 + sd * 14
                    d.ellipse([*c.P(x - 3, fy + 3.4), *c.P(x + 3, fy + 5.8)], fill=(236, 130, 145, 150))
            draw_on(c, bl)
        face(c, Geo(c, m), style, 'baby', fy)
        _, small = shrink(c)
        return small.resize((W * 2, H * 2), Image.NEAREST)


def render(spec, stage):
    if 'special' in spec:
        return special(spec['special'])
    c = Canvas(W, H, K, F, anchor=(55, GROUND))
    s = STAGE[stage]
    sx = spec.get('sx', 1.0)
    pname = spec['p']
    pal = P[pname]
    acc = P[spec.get('a', pname)]
    feats = spec.get('f', [])

    def prims(sx):
        out = []
        for b in SHAPES[spec['b']]:
            x, y, rx, ry = b[:4]
            out.append((55 + x * s * sx, GROUND + y * s, rx * s * sx, ry * s, *b[4:]))
        return out
    bf = sfield(c, prims(sx)); bm = bf > 1
    g = Geo(c, bm)
    lim = 80 if stage != 'legend' else 74
    if g.w > lim:
        sx *= lim / g.w
        bf = sfield(c, prims(sx)); bm = bf > 1
        g = Geo(c, bm)
    u = g.w / 44
    cx = 55
    tt = g.top_at(cx)
    fy = g.top + g.h * spec.get('fy', .57)
    hw_face = g.half_w(fy)
    sh = SHINY.get(pname, (.38, 22))

    def col(tok, default=None):
        if not tok: return default if default is not None else acc
        return pal if tok == 'p' else acc if tok == 'a' else P[tok]

    back, front, lines, over = [], [], [], []    # metaball parts: (field, palette)
    for ft in feats:
        name, _, tok = ft.partition(':')
        fp = col(tok)
        if name in ('sprout', 'leaf2'):
            lp = col(tok, P['leaf'])
            lines.append(('stem', (cx, tt + 1.5), (cx + .8 * u, tt - 4.5 * u), 2.2 * u ** .5, (60, 110, 40)))
            if name == 'sprout':
                back.append((sfield(c, chain((cx + 1 * u, tt - 4.5 * u), (cx + 8 * u, tt - 7.5 * u), 2.6 * u, 1.4 * u, 6, 1.2 * u)), lp))
            else:
                back.append((sfield(c, chain((cx, tt - 4 * u), (cx - 7 * u, tt - 7 * u), 2.4 * u, 1.3 * u, 6, -1 * u)), lp))
                back.append((sfield(c, chain((cx, tt - 4 * u), (cx + 7 * u, tt - 7.5 * u), 2.4 * u, 1.3 * u, 6, 1 * u)), lp))
        elif name == 'stem':
            lines.append(('stem', (cx + 1, tt + 1.5), (cx + 2.5 * u, tt - 5 * u), 2.4 * u ** .5, tuple(int(v) for v in col(tok, P['choc'])[2])))
        elif name == 'twig':
            lines.append(('stem', (cx - 1, tt + 1.5), (cx - 3 * u, tt - 7 * u), 2.0 * u ** .5, tuple(int(v) for v in col(tok, P['choc'])[2])))
        elif name == 'horns':
            y = g.top + g.h * .2; hw = g.half_w(y)
            for sd in (-1, 1):
                back.append((sfield(c, chain((cx + sd * hw * .55, y + 3), (cx + sd * (hw * .9 + 3 * u), y - 9 * u), 3.2 * u, 1.0 * u, 7, -sd * 1.8 * u)), col(tok, P['gold'] if not tok else None)))
        elif name == 'nubs':
            y = g.top + g.h * .16; hw = g.half_w(y)
            for sd in (-1, 1):
                back.append((sfield(c, [(cx + sd * hw * .55, y - 1.5 * u, 3 * u, 3 * u)]), fp))
        elif name == 'ears':
            y = g.top + g.h * .25; hw = g.half_w(y)
            for sd in (-1, 1):
                back.append((sfield(c, chain((cx + sd * hw * .6, y + 2), (cx + sd * (hw * .85 + 2 * u), y - 8 * u), 4.2 * u, 1.2 * u, 7)), fp))
        elif name == 'longears':
            y = g.top + g.h * .15
            for sd in (-1, 1):
                back.append((sfield(c, chain((cx + sd * 5 * u, y + 2), (cx + sd * 8 * u, y - 13 * u), 3.0 * u, 2.2 * u, 7)), fp))
        elif name in ('antenna', 'antennae'):
            tips = [(cx + 3 * u, -1)] if name == 'antenna' else [(cx - 6 * u, -1), (cx + 6 * u, 1)]
            for x, sd in tips:
                x0 = cx + (x - cx) * .35
                lines.append(('stem', (x0, g.top_at(x0) + 1.5), (x, tt - 8 * u), 1.1 * u ** .5, (50, 46, 60)))
                front.append((sfield(c, [(x, tt - 8.5 * u, 2.2 * u, 2.2 * u)]), fp))
        elif name in ('crest', 'spikes'):
            xs = (-6, 0, 6) if name == 'crest' else (-12, -6, 0, 6, 12)
            for dx in xs:
                x = cx + dx * u
                if x < g.l + 3 or x > g.r - 3: continue
                t = g.top_at(x)
                hgt = (7 if (dx == 0 and name == 'crest') else 4.6) * u
                back.append((sfield(c, chain((x, t + 2.5), (x + dx * .25 * u, t - hgt), 2.8 * u, .6 * u, 6)), fp))
        elif name == 'fins':
            y = fy + 2; hw = g.half_w(y)
            for sd in (-1, 1):
                back.append((sfield(c, chain((cx + sd * (hw - 3), y), (cx + sd * (hw + 8 * u), y - 5 * u), 3.6 * u, 1.2 * u, 7, sd * 1.5 * u)), fp))
        elif name == 'arms':
            y = g.top + g.h * .74; hw = g.half_w(y)
            for sd in (-1, 1):
                front.append((sfield(c, [(cx + sd * (hw - .5), y, 3.4 * u, 2.6 * u)]), fp))
        elif name == 'feet':
            front.append((sfield(c, [(cx - 7.5 * u, g.bot - 1, 4.6 * u, 2.6 * u), (cx + 7.5 * u, g.bot - 1, 4.6 * u, 2.6 * u)]), fp))
        elif name == 'legs':
            f_ = np.zeros_like(c.x)
            for dx in (-10, -3.5, 3.5, 10):
                f_ += sfield(c, chain((cx + dx * u, g.bot - 4), (cx + dx * 1.2 * u, g.bot + 1.5), 1.6 * u, 1.3 * u, 4))
            back.append((f_, fp))
        elif name == 'tail':
            y = g.bot - g.h * .25; x = g.r - 3
            back.append((sfield(c, chain((x, y + 2), (x + 9 * u, y - 7 * u), 3.0 * u, 2.0 * u, 8, -3 * u)), fp))
        elif name == 'wings':
            y = g.top + g.h * .4; hw = g.half_w(y)
            for sd in (-1, 1):
                for i in range(3):
                    ang = math.radians(-30 + i * 28)
                    x0, y0 = cx + sd * hw * .7, y + i * 4 * u
                    L = (13 + 3 * (2 - i)) * u
                    back.append((sfield(c, chain((x0, y0), (x0 + sd * math.cos(ang) * L, y0 - math.sin(ang) * L), 3.4 * u, 1.6 * u, 6)), fp))
        elif name == 'tentacles':
            hw = g.half_w(g.bot - 4)
            for sd in (-1, 1):
                for j in range(2):
                    balls = []
                    for i in range(9):
                        t = i / 8
                        x = cx + sd * (hw * (.45 + j * .3) + t * (10 + j * 3) * u)
                        y = g.bot - 2 - j * 1.5 - math.sin(t * math.pi * 1.2) * (3 + j * 2) * u + t * 2
                        balls.append((x, y, (3.2 - t * 2.0) * u, (2.8 - t * 1.7) * u))
                    back.append((sfield(c, balls), fp))
        elif name == 'petals':
            f_ = np.zeros_like(c.x)
            for i in range(7):
                a = math.pi + i * math.pi / 6
                f_ += sfield(c, [(cx + math.cos(a) * g.w * .5, g.top + g.h * .48 + math.sin(a) * g.h * .55, 4.6 * u, 4.6 * u)])
            back.append((f_, col(tok, P['pink'])))
        elif name == 'flame':
            front.append(('flame', tok))
        elif name == 'tuft':
            back.append((sfield(c, chain((cx, tt + 2), (cx + 6 * u, tt - 5 * u), 2.6 * u, 1.2 * u, 7, -2.5 * u)), fp))
        elif name == 'mushcap':
            t = g.top + g.h * .22
            front.append((sfield(c, [(cx, t, g.w * .52, g.h * .16), (cx, t - g.h * .07, g.w * .36, g.h * .16)]), fp))
        elif name == 'ring':
            yy = g.top + g.h * .62
            ring = sfield(c, [(cx, yy, g.w * .78, 5 * u)]) - 1.0 * sfield(c, [(cx, yy - .6 * u, g.w * .6, 2.6 * u)])
            back.append((np.where(c.y < yy, ring, 0), fp)); front.append((np.where(c.y >= yy, ring, 0), fp))
        else:
            over.append((name, fp))

    # paint
    for f_, p_ in back:
        m = (f_ > 1) & ~bm
        material(c, height(f_, .5), m, p_, bump=4, spec_amt=.35, spec_pow=22, grain=.06)
        seam(c, m, (c.a > .5) & ~m & ~bm, .4)
    bh = height(bf, .55)
    material(c, bh, bm, pal, bump=4, spec_amt=sh[0], spec_pow=sh[1], grain=.08)
    for f_, p_ in back:
        seam(c, bm, (f_ > 1) & ~bm, .5)
    if pname == 'sour' and spec.get('warts', True):          # Picklet's pickle warts
        rr = np.random.default_rng(int(g.w * 13))
        warts = []
        for _ in range(int(9 * s)):
            x, y = rr.uniform(g.l + 3, g.r - 3), rr.uniform(g.top + 3, g.bot - 1)
            if bf[min(int(y * K * F), H * K - 1), min(int(x * K * F), W * K - 1)] > 1.6 and not (abs(y - fy) < 5 and abs(x - cx) < hw_face * .7):
                warts.append((x, y, 1.5 * s ** .5, 1.5 * s ** .5, 2, .25))
        if warts:
            wf = sfield(c, warts)
            material(c, np.clip(bh + height(wf, .5) * .4, 0, 1.3), bm & (wf > .9), pal, bump=6, spec_amt=.3, grain=.08)
    for ft in feats:
        name, _, tok = ft.partition(':')
        fp = col(tok)
        reg = None
        if name == 'cap':
            reg = bm & (c.y < g.top + g.h * .4 + 1.6 * u * np.sin(c.x * .55))
        elif name == 'drip':
            base = g.top + g.h * .36
            dr = base + 1.5 * np.sin(c.x * .5) + 6 * u * np.exp(-((c.x - (cx - 10 * u)) / 2.4) ** 2) + 8 * u * np.exp(-((c.x - (cx + 8 * u)) / 2.6) ** 2)
            reg = bm & (c.y < dr)
        elif name == 'base':
            reg = bm & (c.y > g.bot - g.h * .28 + .8 * np.sin(c.x * .6))
        elif name == 'band':
            y0 = g.top + g.h * .72
            reg = bm & (c.y > y0) & (c.y < y0 + g.h * .13)
        elif name == 'belly':
            reg = bm & (sfield(c, [(cx, g.bot - g.h * .08, min(g.w * .19, hw_face * .45), g.h * .13)]) > 1)
        elif name == 'half':
            reg = bm & (c.x > cx + .8 * np.sin(c.y * .8))
        elif name == 'diag':
            reg = bm & ((c.x - cx) * .7 + (c.y - (g.top + g.h * .5)) < 0)
        elif name == 'spots':
            rr = np.random.default_rng(int(g.w * 7))
            bl = []
            for _ in range(int(5 * s)):
                x, y = rr.uniform(g.l + 4, g.r - 4), rr.uniform(g.top + 3, g.bot - 3)
                if abs(y - fy) < 6 * u and abs(x - cx) < hw_face * .75: continue
                bl.append((x, y, 2.2 * u, 1.8 * u))
            reg = bm & (sfield(c, bl) > 1) if bl else None
        elif name == 'stripes':
            reg = bm & (np.sin((c.x - cx) * 1.0 / u) > .55) & (c.y < g.top + g.h * .42)
        elif name == 'hstripes':
            reg = bm & (np.sin((c.y - g.bot) * 1.1 / u) > .6) & (c.y > fy + 6 * u)
        elif name == 'tip':
            reg = bm & (c.y < g.top + g.h * .2)
        elif name == 'shell':
            reg = bm & (c.y < g.top + g.h * .45 + 1.2 * np.sin(c.x * .7))
        if reg is not None:
            material(c, bh * 1.03, reg, fp, bump=4, spec_amt=.5, spec_pow=22, grain=.06)
            seam(c, reg, bm & ~reg, .45)
    for item in front:
        if isinstance(item[0], str):
            fl = col(item[1], P['flame'])
            top_spicy(c, tt + 2.5, s * .62)
            continue
        f_, p_ = item
        m = f_ > 1
        material(c, height(f_, .5), m, p_, bump=4, spec_amt=.4, spec_pow=22, grain=.06)
        seam(c, m, (c.a > .5) & ~m, .45)

    def ln(d):
        for kind, p0, p1, w, colr in lines:
            d.line([c.P(*p0), c.P((p0[0] + p1[0]) / 2 + .6, (p0[1] + p1[1]) / 2), c.P(*p1)], fill=colr, width=int(w * K * F), joint='curve')
    draw_on(c, ln)
    outline(c, c.a > .5, 1.0)
    outline(c, c.a > .5, 1.0)          # twice, like forms_gen: the solid 2px Picklet outline

    def deco(d):
        P_ = c.P
        for name, fp in over:
            dk = tuple(int(v) for v in fp[1]); lt = tuple(int(v) for v in fp[-2])
            if name == 'freckles':
                for sd in (-1, 1):
                    for i in range(3):
                        x = cx + sd * (hw_face * .62 + i * 1.4 * u); y = fy + 4.4 * u + (i % 2) * u
                        d.ellipse([*P_(x - .6, y - .6), *P_(x + .6, y + .6)], fill=dk)
            elif name == 'seeds':
                rr = np.random.default_rng(3)
                for _ in range(int(16 * u)):
                    x, y = rr.uniform(g.l + 3, g.r - 3), rr.uniform(g.top + 3, g.bot - 3)
                    if not g.inside(x, y) or (abs(y - fy) < 6 * u and abs(x - cx) < hw_face * .7): continue
                    d.ellipse([*P_(x - .6, y - .9), *P_(x + .6, y + .9)], fill=lt)
            elif name == 'crack':
                y = g.top + g.h * .22; x = cx + g.w * .2
                d.line([P_(x, y), P_(x - 2 * u, y + 3 * u), P_(x + 1 * u, y + 5 * u), P_(x - 1 * u, y + 8 * u)], fill=INK, width=Wd(c, .9))
            elif name == 'bolts':
                y = fy + 4 * u
                for sd in (-1, 1):
                    x = cx + sd * (g.half_w(y) - .5)
                    d.ellipse([*P_(x - 1.6 * u, y - 1.6 * u), *P_(x + 1.6 * u, y + 1.6 * u)], fill=(200, 208, 222), outline=INK, width=Wd(c, .5))
            elif name == 'chip':
                y = g.top + g.h * .27; r = 3 * u
                d.rectangle([*P_(cx - r, y - r * .8), *P_(cx + r, y + r * .8)], fill=(40, 46, 56), outline=INK, width=Wd(c, .5))
                for i in (-1, 0, 1):
                    for sgn in (-1, 1):
                        d.line([P_(cx + i * r * .55, y + sgn * r * .8), P_(cx + i * r * .55, y + sgn * r * 1.3)], fill=(220, 190, 80), width=Wd(c, .6))
                d.rectangle([*P_(cx - r * .4, y - r * .3), *P_(cx + r * .4, y + r * .3)], fill=(90, 220, 200))
            elif name == 'stache':
                y = fy + 4.6 * u
                for sd in (-1, 1):
                    x0 = cx + (0 if sd > 0 else -5.5 * u)
                    d.chord([*P_(x0, y - 1.8 * u), *P_(x0 + 5.5 * u, y + 1.8 * u)], 180, 360, fill=dk)
            elif name == 'bubbles':
                for (dx, dy, r) in ((-1.0, -.2, 1.8), (-1.15, -.55, 1.1), (1.05, -.4, 1.4), (1.2, -.75, .9)):
                    x = cx + dx * g.w * .55; y = g.top + g.h * .5 + dy * g.h
                    d.ellipse([*P_(x - r * u, y - r * u), *P_(x + r * u, y + r * u)], fill=(255, 255, 255, 90), outline=dk, width=Wd(c, .5))
            elif name == 'steam':
                for dx in (-5, 0, 5):
                    x = cx + dx * u; t = g.top_at(x) - 3
                    d.line([P_(x, t), P_(x + 1.2, t - 2), P_(x - 1.2, t - 4), P_(x, t - 6)], fill=(214, 214, 222), width=Wd(c, .9), joint='curve')
            elif name == 'sparkles':
                for (x, y, r) in ((g.l - 2, g.top + 4, 2.6), (g.r + 2, g.top + 10, 2.0), (g.r, g.bot - 6, 1.5)):
                    d.polygon([P_(x, y - r), P_(x + r * .3, y - r * .3), P_(x + r, y), P_(x + r * .3, y + r * .3), P_(x, y + r),
                               P_(x - r * .3, y + r * .3), P_(x - r, y), P_(x - r * .3, y - r * .3)], fill=(255, 236, 140))
            elif name == 'drop':
                x = g.r - 3; y = g.top + g.h * .3
                d.polygon([P_(x, y - 2.8 * u), P_(x + 1.6 * u, y), P_(x - 1.6 * u, y)], fill=(150, 205, 250))
                d.ellipse([*P_(x - 1.6 * u, y - 1.4 * u), *P_(x + 1.6 * u, y + 1.8 * u)], fill=(150, 205, 250))
            elif name == 'blush':
                for sd in (-1, 1):
                    x = cx + sd * hw_face * .62
                    d.ellipse([*P_(x - 2.6 * u, fy + 2.6 * u), *P_(x + 2.6 * u, fy + 4.6 * u)], fill=(236, 130, 145, 170))
            elif name == 'gem':
                y = g.top + g.h * .28
                d.polygon([P_(cx, y - 3 * u), P_(cx + 2.4 * u, y), P_(cx, y + 3 * u), P_(cx - 2.4 * u, y)], fill=tuple(int(v) for v in fp[3]), outline=INK)
            elif name == 'stars':
                rr = np.random.default_rng(6)
                for _ in range(10):
                    x, y = rr.uniform(g.l + 3, g.r - 3), rr.uniform(g.top + 2, g.bot - 2)
                    if not g.inside(x, y) or (abs(y - fy) < 6 * u and abs(x - cx) < hw_face * .7): continue
                    r = rr.uniform(.6, 1.1)
                    d.polygon([P_(x, y - r * 1.8), P_(x + r * .5, y), P_(x, y + r * 1.8), P_(x - r * .5, y)], fill=(255, 250, 220))
                    d.polygon([P_(x - r * 1.8, y), P_(x, y + r * .5), P_(x + r * 1.8, y), P_(x, y - r * .5)], fill=(255, 250, 220))
    draw_on(c, deco)
    for ft in feats:
        if ft == 'crown': crown(c, tt, s)
        if ft == 'halo': halo(c, g.top, s)
    light = pname in ('char', 'navy', 'choc') and spec.get('e') not in ('side', 'one', 'lid', 'bored', 'visor', 'big', 'stern', 'worried', 'tiny', 'tri')
    face(c, g, spec.get('e', 'flat'), stage, fy, light=light)
    _, small = shrink(c)
    return small.resize((W * 2, H * 2), Image.NEAREST)
