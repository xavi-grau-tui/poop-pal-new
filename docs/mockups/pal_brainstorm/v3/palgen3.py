"""Pal brainstorm v3: the CURRENT pals' render quality (tools/art/forms_gen.py: paint big with soft
metaball shading, shrink to the 55x50 native canvas, a solid 2 px outline drawn twice, glossy
eyes) with much more variety: ~35 body plans, ~60 parts, ~20 eyes x ~16 mouths.

A pal is one spec line (see sets3.py):
    Name | plan[ key=val ...] | palette[/accent[/accent2]] | parts ... | eyes mouth [extras] | note
  plan     a body plan (PLANS) + optional sx= sy= lean= fy= (face height) fx= (face x shift)
  parts    name[:colour] (colour: p = palette, a = accent, b = accent2, or a palette name)
  face     eyes (EYES), mouth (MOUTHS), extras: blush sweat freckles tear look=l/r lids
Run build3.py to make the sheets."""
import sys, math, zlib
sys.path.insert(0, '/Users/xaviergrau/Documents/PoopPal Godot/poop-pal-main-kiro/tools/art')
import numpy as np
from PIL import Image, ImageDraw
from hires import Canvas, height, material, outline, seam, paint, to_image, shrink

PROJ = '/Users/xaviergrau/Documents/PoopPal Godot/poop-pal-main-kiro'
F, W, H, K = 0.5, 55, 50, 20          # = forms_gen: native 55x50 px, 2 design units per px, x20 hi-res
GROUND = 93
INK = (18, 8, 14)
STAGE = {'baby': 1.3, 'kid': 1.45, 'adult': 1.9, 'mutant': 1.9, 'legend': 2.05}   # kids clearly between Sho and Dai
EYE = {'baby': (5.4, 10.5), 'kid': (5.3, 11.0), 'adult': (5.0, 12.5), 'mutant': (5.0, 12.5), 'legend': (5.2, 13.5)}

# ------------------------------------------------------------------ palettes (6-step ramps, dark -> light)
P = {
 # the five families (the Power Rangers colours)
 'green':  [(14, 44, 24), (28, 92, 46), (50, 144, 68), (88, 184, 94), (150, 220, 140), (222, 246, 212)],
 'sweet':  [(22, 30, 52), (40, 58, 96), (72, 100, 150), (106, 136, 186), (150, 178, 216), (214, 228, 246)],
 'greasy': [(110, 54, 6), (196, 108, 16), (240, 158, 30), (252, 196, 70), (255, 226, 140), (255, 248, 222)],
 'spicy':  [(70, 10, 16), (140, 24, 30), (200, 50, 44), (232, 92, 70), (250, 150, 120), (255, 214, 190)],
 'sour':   [(30, 50, 16), (70, 100, 30), (118, 150, 52), (160, 186, 80), (206, 220, 130), (240, 246, 200)],   # Picklet
 # family neighbours
 'lime':   [(40, 70, 10), (90, 140, 20), (150, 196, 40), (196, 228, 80), (230, 248, 150), (250, 255, 225)],
 'lemon':  [(140, 100, 10), (210, 166, 24), (246, 210, 56), (255, 232, 110), (255, 246, 180), (255, 255, 236)],
 'navy':   [(10, 14, 30), (20, 30, 62), (36, 52, 100), (58, 80, 136), (96, 120, 176), (170, 190, 230)],
 'sky':    [(40, 70, 110), (70, 110, 160), (110, 156, 206), (150, 192, 232), (196, 222, 248), (236, 246, 255)],
 'choc':   [(36, 16, 14), (72, 36, 26), (112, 62, 42), (150, 92, 64), (196, 140, 106), (236, 200, 170)],
 'gold':   [(110, 66, 10), (176, 120, 20), (226, 176, 40), (250, 214, 90), (255, 244, 190), (255, 255, 240)],
 'crust':  [(90, 40, 10), (150, 78, 24), (196, 120, 46), (226, 160, 80), (246, 204, 140), (255, 240, 210)],
 'rust':   [(60, 20, 8), (120, 46, 16), (176, 80, 30), (210, 116, 56), (236, 166, 110), (252, 222, 190)],
 'orange': [(96, 30, 8), (176, 70, 16), (232, 116, 30), (248, 160, 60), (255, 204, 130), (255, 238, 210)],
 'coral':  [(90, 24, 30), (170, 60, 60), (226, 108, 92), (244, 148, 120), (252, 194, 166), (255, 236, 222)],
 'olive':  [(36, 40, 12), (76, 82, 24), (120, 124, 44), (160, 160, 70), (200, 196, 120), (238, 236, 200)],
 'moss':   [(20, 40, 20), (46, 74, 34), (80, 110, 50), (116, 146, 72), (164, 188, 112), (222, 232, 190)],
 # mixes
 'purple': [(34, 14, 50), (70, 30, 96), (114, 60, 146), (150, 96, 184), (192, 150, 222), (236, 220, 250)],
 'plum':   [(40, 10, 34), (84, 24, 70), (130, 44, 104), (170, 80, 140), (210, 140, 186), (244, 214, 236)],
 'teal':   [(8, 40, 44), (16, 86, 90), (30, 138, 138), (70, 180, 170), (140, 220, 206), (220, 248, 240)],
 'mint':   [(20, 70, 60), (50, 130, 110), (100, 190, 160), (150, 222, 196), (200, 244, 226), (240, 255, 248)],
 'pink':   [(100, 30, 60), (176, 66, 104), (226, 116, 148), (244, 160, 186), (255, 206, 222), (255, 240, 246)],
 'magenta': [(70, 8, 50), (140, 20, 96), (200, 50, 140), (230, 100, 180), (248, 170, 220), (255, 230, 245)],
 'lilac':  [(60, 50, 90), (110, 96, 150), (156, 142, 196), (190, 178, 224), (220, 212, 242), (248, 244, 255)],
 'cream':  [(120, 96, 70), (190, 166, 132), (226, 210, 180), (244, 234, 212), (252, 248, 236), (255, 255, 252)],
 'white':  [(140, 140, 150), (196, 196, 206), (228, 228, 236), (244, 244, 250), (252, 252, 255), (255, 255, 255)],
 'rice':   [(150, 146, 140), (206, 202, 194), (236, 234, 228), (248, 246, 240), (253, 252, 248), (255, 255, 255)],
 'char':   [(14, 14, 18), (34, 34, 42), (58, 58, 70), (86, 86, 100), (130, 130, 146), (200, 200, 214)],
 'stone':  [(40, 40, 44), (80, 80, 86), (120, 118, 122), (160, 158, 160), (200, 198, 196), (236, 234, 230)],
 'wood':   [(50, 26, 14), (96, 54, 30), (140, 88, 52), (180, 124, 80), (214, 168, 120), (240, 214, 180)],
 'peach':  [(120, 50, 40), (200, 100, 80), (240, 150, 120), (250, 186, 156), (255, 218, 196), (255, 244, 236)],
 'berry':  [(60, 6, 24), (120, 16, 46), (180, 30, 70), (220, 70, 100), (244, 140, 160), (255, 214, 222)],
 'ice':    [(40, 80, 110), (80, 140, 180), (130, 190, 220), (180, 225, 245), (225, 245, 255), (255, 255, 255)],
 'metal':  [(36, 40, 52), (80, 88, 106), (130, 140, 160), (176, 186, 204), (222, 230, 242), (255, 255, 255)],
 'goo':    [(36, 18, 70), (80, 44, 140), (126, 84, 200), (164, 132, 230), (206, 186, 250), (240, 232, 255)],
 'slime':  [(30, 60, 20), (60, 130, 30), (110, 200, 50), (160, 240, 90), (210, 255, 160), (245, 255, 230)],
 'flame':  [(150, 20, 10), (226, 70, 24), (250, 140, 40), (255, 200, 80), (255, 244, 190), (255, 255, 240)],
 'leaf':   [(24, 50, 28), (46, 92, 40), (84, 140, 56), (126, 180, 74), (178, 214, 110), (228, 240, 180)],
 'nori':   [(8, 16, 12), (18, 32, 24), (30, 48, 36), (44, 66, 50), (70, 96, 76), (130, 156, 136)],
}
# how glossy each material is (spec amount, spec power) and its grain
GLOSS = {'greasy': (.75, 16), 'spicy': (.7, 18), 'gold': (.8, 14), 'metal': (.85, 12), 'goo': (.75, 16), 'slime': (.75, 16),
         'sweet': (.6, 18), 'navy': (.6, 18), 'choc': (.65, 18), 'berry': (.7, 18), 'ice': (.75, 14), 'crust': (.4, 20),
         'orange': (.6, 18), 'lemon': (.55, 18), 'magenta': (.6, 18), 'pink': (.5, 20), 'cream': (.35, 22), 'rice': (.25, 24),
         'nori': (.3, 22), 'stone': (.2, 26), 'wood': (.25, 24), 'char': (.4, 20), 'teal': (.5, 20), 'mint': (.5, 20)}
GRAIN = {'crust': .1, 'stone': .11, 'wood': .1, 'rice': .08, 'moss': .1, 'peach': .1, 'cream': .07, 'metal': .04, 'ice': .04}

# ------------------------------------------------------------------ body plans (baby units: x right, y up negative,
# around the ground centre). prim = (x, y, rx, ry[, p superellipse, w weight]); 'face' = (x, y) of the face
PLANS = {
 'gum':     dict(b=[(0, -8, 16, 8.5), (0, -18, 14, 10.5), (0, -27, 10, 7)], face=(0, -15)),        # Picklet's gumdrop
 'mound':   dict(b=[(0, -6.5, 22, 7), (0, -14, 17, 8), (0, -21, 10, 6)], face=(0, -12)),           # the classic pal mound
 'tear':    dict(b=[(0, -7, 18, 7.5), (0, -15, 15, 8.5), (1, -24, 10, 7), (2, -31, 5, 4)], face=(0, -13)),   # Ember
 'bean':    dict(b=[(0, -9, 13, 9), (0, -20, 12, 11), (0, -31, 10, 8)], face=(0, -22)),
 'pear':    dict(b=[(0, -10, 18, 10), (0, -24, 10, 9)], face=(0, -15)),
 'egg':     dict(b=[(0, -12, 15, 12), (0, -22, 11, 10)], face=(0, -17)),
 'mochi':   dict(b=[(0, -9, 22, 9, 3), (0, -15, 16, 9)], face=(0, -12)),
 'puddle':  dict(b=[(0, -5, 27, 5), (0, -10, 19, 6)], face=(0, -8)),
 'peanut':  dict(b=[(0, -9, 15, 9), (0, -26, 11, 9)], face=(0, -26), fs=1.1),
 'onion':   dict(b=[(0, -11, 16, 11), (0, -24, 7, 8), (0, -32, 3, 5)], face=(0, -12)),
 'ball':    dict(b=[(0, -15, 15, 15)], face=(0, -16)),
 'dango':   dict(b=[(0, -8, 10, 7.2), (0, -24, 10, 7.2), (0, -40, 10, 7.2)], face=(0, -24), tiers=True, skewer=True),
 'pod':     dict(b=[(-13, -8, 7.5, 7.6), (0, -9, 8.2, 8.6), (13, -8, 7.5, 7.6), (-19, -7, 3.5, 3), (19, -7, 3.5, 3)], face=(0, -10), segs=True),
 'icecream': dict(b=[(0, -11, 8.5, 11, 1.3), (0, -28, 12.5, 10)], face=(0, -28), tiers=True),
 'lolly':   dict(b=[(0, -24, 13, 13)], face=(0, -24), stick=True),
 'popsicle': dict(b=[(0, -24, 11, 16, 3.2)], face=(0, -24), stick=True),
 'fried':   dict(b=[(0, -4, 26, 4.5, 2.4), (-8, -5, 13, 5), (9, -5, 14, 5)], face=(2, -8), yolk=True, fhw=9),   # a fried egg
 'wedge':   dict(b=[(-6, -9, 12, 9, 1.5), (5, -10, 13, 10, 1.4)], face=(-1, -10)),   # cheese
 'slice':   dict(b=[(0, -22, 15, 9), (0, -12, 9, 8), (0, -4, 4, 4)], face=(0, -18)),    # a pizza slice, point down
 'clam':    dict(b=[(0, -10, 19, 10)], face=(0, -8), cutbottom=True),
 'half':    dict(b=[(0, 0, 19, 19)], face=(0, -8), cutbottom=True),
 'takenoko': dict(b=[(0, -8, 15, 8), (0, -17, 11, 8), (0, -26, 7, 7), (0, -33, 3.5, 4)], face=(0, -12), segs=True),
 'bottle':  dict(b=[(0, -11, 11, 11, 2.8), (0, -24, 8, 5), (0, -31, 4, 5, 3)], face=(0, -12)),
 'bowl':    dict(b=[(0, -12, 21, 12)], face=(0, -6), rim=True),
 'bun':     dict(b=[(0, -6, 22, 6, 3), (0, -13, 19, 9)], face=(0, -11)),
 'bell':    dict(b=[(0, -6, 21, 6), (0, -16, 14, 10), (0, -26, 10, 7)], face=(0, -16)),
 'kiss':    dict(b=[(0, -7, 19, 7), (0, -15, 14, 8), (0, -22, 8, 6), (0, -28, 4, 5), (2, -33, 2, 3)], face=(0, -11)),
 'tri':     dict(b=[(-12, -7, 8, 7), (12, -7, 8, 7), (0, -27, 7, 7), (0, -14, 13, 11)], face=(0, -13)),     # onigiri
 'cube':    dict(b=[(0, -14, 15, 14, 4.2)], face=(0, -15)),
 'tall':    dict(b=[(0, -10, 11, 10), (0, -22, 10, 12), (0, -33, 8, 8)], face=(0, -24)),            # a candle / cucumber
 'squat':   dict(b=[(0, -7, 20, 7), (0, -14, 16, 8)], face=(0, -11)),
 'pebble':  dict(b=[(0, -8, 18, 8), (0, -13, 14, 7)], face=(0, -11)),
 'cloud':   dict(b=[(-12, -8, 8, 7.5, 2, .8), (12, -8, 8, 7.5, 2, .8), (0, -10, 11, 9, 2, .9), (-9, -19, 8, 7.5, 2, .8), (9, -19, 8, 7.5, 2, .8), (0, -26, 8, 7, 2, .8)], face=(0, -15)),
 'star':    dict(b=[(0, -16, 11, 11), (0, -30, 5, 6), (-14, -20, 6, 4.5), (14, -20, 6, 4.5), (-9, -5, 5.5, 5), (9, -5, 5.5, 5)], face=(0, -16)),   # konpeito / starfish
 'lemon':   dict(b=[(0, -11, 17, 11), (-18, -11, 3.5, 2.6), (18, -11, 3.5, 2.6)], face=(0, -12)),
 'chili':   dict(b=[(-4, -6, 9, 6), (-2, -13, 9, 8), (1, -21, 8, 7), (5, -28, 6, 6), (10, -33, 4, 4)], face=(-2, -13)),
 'worm':    dict(b=[(-17, -6, 6.5, 6), (-9, -7, 7, 7), (-1, -8, 7, 7), (7, -10, 7, 7), (13, -16, 7, 7), (15, -25, 8.5, 8.5)], face=(15, -25), fs=1.25, segs=True),
 'slug':    dict(b=[(-14, -4.5, 10, 4.5), (-3, -5.5, 12, 5.5), (9, -10, 8, 8), (11, -17, 9, 8.5)], face=(11, -17), fs=1.2),
 'daruma':  dict(b=[(0, -12, 17, 12), (0, -23, 13, 10)], face=(0, -21)),
 'lantern': dict(b=[(0, -16, 15, 15, 2.6)], face=(0, -17)),
 'doll':    dict(b=[(0, -8, 12, 8, 2.4), (0, -13, 10, 6), (0, -26, 10, 9)], face=(0, -26), fs=1.05),      # kokeshi
 'ghost':   dict(b=[(0, -5, 18, 5), (0, -13, 14, 9), (0, -24, 12, 10)], face=(0, -23)),               # teru teru / a sheet
 'pot':     dict(b=[(0, -9, 17, 9, 2.6), (0, -14, 15, 8, 3)], face=(0, -11)),
 'twin':    dict(b=[(-9, -12, 11, 12), (9, -12, 11, 12), (0, -7, 18, 7)], face=(0, -13)),
 'mush':    dict(b=[(0, -8, 10, 8), (0, -18, 20, 8), (0, -24, 14, 6)], face=(0, -9)),
 'bird':    dict(b=[(0, -13, 14, 13), (0, -24, 11, 9)], face=(0, -21), fs=1.1),
 'fish':    dict(b=[(4, -12, 13.5, 9.5), (-6, -12, 9.5, 7.5)], face=(8, -13), fs=1.05),
 'swirl':   dict(b=[(0, -6, 21, 6.5), (0, -15, 16, 6), (0, -23, 10.5, 5), (1, -30, 5, 4.5)], face=(0, -12), tiers=True),
 'ring':    dict(b=[(0, -14, 20, 13)], face=(0, -8), ring=True),
 'sausage': dict(b=[(-12, -9, 9, 9), (0, -9, 12, 9), (12, -9, 9, 9)], face=(4, -11)),
 'drop':    dict(b=[(0, -8, 18, 8), (0, -16, 15, 9), (0, -24, 9, 7), (0, -31, 4, 4)], face=(0, -13)),
 'blobl':   dict(b=[(-3, -8, 17, 8), (1, -18, 13, 10), (5, -27, 8, 7)], face=(0, -15)),     # a leaning blob
 'stack':   dict(b=[(0, -6, 18, 6, 3), (0, -16, 15, 5, 3), (0, -25, 12, 5, 3)], face=(0, -15), tiers=True),   # pancakes / layers
 'burger':  dict(b=[(0, -4, 17, 4, 3), (0, -10, 18, 2.6, 3), (0, -15, 17, 3.6, 3), (0, -24, 16, 7.5)], face=(0, -23), tiers=True),
 'flat':    dict(b=[(0, -5, 24, 5, 3), (0, -9, 20, 5, 3)], face=(0, -7)),
 'gourd':   dict(b=[(0, -10, 16, 10), (0, -23, 9, 7), (0, -30, 6, 5)], face=(0, -12)),
 'cone':    dict(b=[(0, -8, 16, 8), (0, -18, 11, 10), (0, -28, 6, 7), (0, -35, 3, 4)], face=(0, -14)),
 'tree':    dict(b=[(0, -7, 5.5, 7.5, 3), (-10, -19, 9, 8), (10, -19, 9, 8), (0, -27, 11, 9), (0, -17, 12, 7.5)], face=(0, -21)),
 'corn':    dict(b=[(0, -8, 16, 8.5), (0, -20, 11, 7), (0, -30, 6.5, 6)], face=(0, -11), tiers=True),
}


# ------------------------------------------------------------------ helpers
def sfield(c, prims):
    Fd = np.zeros_like(c.x)
    for b in prims:
        cx, cy, rx, ry = b[:4]
        p = b[4] if len(b) > 4 else 2
        w = b[5] if len(b) > 5 else 1.0
        d = (np.abs((c.x - cx) / rx) ** p + np.abs((c.y - cy) / ry) ** p) ** (2 / p)
        Fd += w / np.maximum(d, 1e-4)
    return Fd


def chain(p0, p1, r0, r1, n=6, bend=0.0, ry=None):
    """balls along a (bent) line, radius r0 -> r1: horns, ears, leaves, tails"""
    (x0, y0), (x1, y1) = p0, p1
    nx, ny = -(y1 - y0), (x1 - x0)
    L = math.hypot(nx, ny) or 1
    out = []
    for j in range(n):
        t = j / (n - 1)
        b = math.sin(t * math.pi) * bend
        r = r0 + (r1 - r0) * t
        out.append((x0 + (x1 - x0) * t + nx / L * b, y0 + (y1 - y0) * t + ny / L * b, r, r if ry is None else ry * r / r0))
    return out


def leafshape(base, tip, wmax, n=9, bend=0.0):
    """a pointed leaf: balls swelling then tapering to a point"""
    (x0, y0), (x1, y1) = base, tip
    nx, ny = -(y1 - y0), (x1 - x0)
    L = math.hypot(nx, ny) or 1
    out = []
    for j in range(n):
        t = j / (n - 1)
        r = max(.5, wmax * math.sin(math.pi * (.15 + .85 * t)) * (1 - t * .25))
        b = math.sin(t * math.pi) * bend
        out.append((x0 + (x1 - x0) * t + nx / L * b, y0 + (y1 - y0) * t + ny / L * b, r, r))
    return out


def draw_on(c, fn):
    im = to_image(c)
    d = ImageDraw.Draw(im, 'RGBA')
    fn(d)
    a = np.asarray(im, np.float32)
    c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


def wd(c, v):
    return max(2, int(v * c.k * c.f))


def tone(pal, i):
    return tuple(int(v) for v in pal[min(max(i, 0), len(pal) - 1)])


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

    def side_at(s, y, sd):
        row = s.mask[min(max(int(y * s.k), 0), s.mask.shape[0] - 1)]
        xs = np.nonzero(row)[0]
        if not len(xs):
            return 55
        return (xs.max() if sd > 0 else xs.min()) / s.k

    def half_w(s, y):
        row = s.mask[min(max(int(y * s.k), 0), s.mask.shape[0] - 1)]
        xs = np.nonzero(row)[0]
        return (xs.max() - xs.min()) / s.k / 2 if len(xs) else 0

    def inside(s, x, y):
        return s.mask[min(max(int(y * s.k), 0), s.mask.shape[0] - 1), min(max(int(x * s.k), 0), s.mask.shape[1] - 1)]


# ------------------------------------------------------------------ the face
EYES = ['none', 'gloss', 'dot', 'lid', 'sleep', 'happy', 'side', 'glance', 'wide', 'stern', 'worried', 'cross', 'line',
        'tiny', 'one', 'three', 'visor', 'star', 'x', 'shades', 'squint', 'spiral', 'heavy']
MOUTHS = ['none', 'flat', 'dot', 'o', 'w', 'v', 'smile', 'frown', 'pout', 'smirk', 'fang', 'fangs', 'teeth', 'wavy',
          'open', 'tongue', 'beak', 'grin']


def face(c, g, fx, fy, eyes, mouth, extras, stage, body_pal, fs=1.0, fhw=None):
    er0, sp0 = EYE[stage]
    hw = max(min(g.half_w(fy), abs(g.side_at(fy, 1) - fx), abs(fx - g.side_at(fy, -1))), 8)
    if fhw:
        hw = fhw
    k = min(1.3, max(.72, hw / (sp0 * 1.95))) * fs
    er = er0 * min(1.2, max(.8, k))
    sp = min(sp0 * k, hw * .5)
    u = er / 3.4
    ink = INK
    lw = wd(c, 1.3)
    P_ = c.P
    look = 0.0
    for ex_ in extras:
        if ex_.startswith('look='):
            look = {'l': -1, 'r': 1}.get(ex_[5:], 0)
    ex = (fx - sp, fx + sp)
    my = fy + 3.0 * u
    skin = tone(body_pal, 3)
    dark = tone(body_pal, 1)

    def glossy(d, x, y, r, hl=True, two=False):
        d.ellipse([*P_(x - r * .92, y - r * 1.08), *P_(x + r * .92, y + r * 1.08)], fill=ink)
        if hl:
            hx = -look * .25 * r
            d.ellipse([*P_(x - r * .58 + hx, y - r * .78), *P_(x + r * .1 + hx, y - r * .08)], fill=(255, 255, 255))
            if two:
                d.ellipse([*P_(x + r * .22, y + r * .28), *P_(x + r * .56, y + r * .62)], fill=(255, 255, 255))

    def dot(d, x, y, r):
        d.ellipse([*P_(x - r, y - r), *P_(x + r, y + r)], fill=ink)

    def line_m(d, w=1.6, y=None):
        y = my + 1.2 * u if y is None else y
        d.line([P_(fx - w * u, y), P_(fx + w * u, y)], fill=ink, width=lw)

    def fn(d):
        e = eyes
        # ---- eyes
        if e == 'gloss':
            for x in ex: glossy(d, x + look * er * .2, fy, er)
        elif e == 'wide':
            for x in ex: glossy(d, x, fy, er * 1.12, two=True)
        elif e == 'tiny':
            for x in ex: glossy(d, x, fy, er * .72)
        elif e == 'dot':
            for x in ex: dot(d, x + look * er * .3, fy, er * .55)
        elif e in ('lid', 'heavy'):      # half-closed: bored / cool
            cut = .05 if e == 'lid' else .3
            for x in ex:
                xx = x + look * er * .2
                d.chord([*P_(xx - er * .95, fy - er * 1.0), *P_(xx + er * .95, fy + er * 1.05)], 0, 180, fill=ink)
                if e == 'heavy':
                    d.rectangle([*P_(xx - er, fy - er * 1.1), *P_(xx + er, fy + er * cut)], fill=skin)
                d.ellipse([*P_(xx + er * .05, fy + er * (cut + .1)), *P_(xx + er * .5, fy + er * (cut + .52))], fill=(255, 255, 255))
                d.line([P_(xx - er * 1.12, fy + er * cut), P_(xx + er * 1.12, fy + er * cut)], fill=ink, width=wd(c, 1.15))
        elif e == 'sleep':
            for x in ex:
                d.arc([*P_(x - er * .9, fy - er * .95), *P_(x + er * .9, fy + er * .6)], 20, 160, fill=ink, width=wd(c, 1.5))
        elif e == 'happy':
            for x in ex:
                d.arc([*P_(x - er * .9, fy - er * .55), *P_(x + er * .9, fy + er * 1.0)], 200, 340, fill=ink, width=wd(c, 1.6))
        elif e == 'line':
            for x in ex:
                d.line([P_(x - er * .85, fy), P_(x + er * .85, fy)], fill=ink, width=wd(c, 1.6))
        elif e == 'squint':
            for i, x in enumerate(ex):
                sd = 1 if i == 0 else -1
                d.line([P_(x - sd * er * .8, fy - er * .6), P_(x + sd * er * .6, fy), P_(x - sd * er * .8, fy + er * .6)], fill=ink, width=wd(c, 1.5), joint='curve')
        elif e in ('side', 'glance'):
            lk = look or 1
            for x in ex:
                if e == 'side':
                    d.ellipse([*P_(x - er * .95, fy - er * 1.05), *P_(x + er * .95, fy + er * 1.05)], fill=(252, 250, 244), outline=ink, width=wd(c, .8))
                    d.ellipse([*P_(x + lk * er * .05 - er * .42 + lk * er * .38, fy - er * .5), *P_(x + lk * er * .05 + er * .42 + lk * er * .38, fy + er * .5)], fill=ink)
                else:                    # glossy eyes under a flat lid, looking aside
                    xx = x + lk * er * .25
                    d.chord([*P_(xx - er * .9, fy - er * 1.0), *P_(xx + er * .9, fy + er * 1.05)], 0, 180, fill=ink)
                    d.ellipse([*P_(xx + lk * er * .05 - er * .18, fy + er * .12), *P_(xx + lk * er * .05 + er * .26, fy + er * .5)], fill=(255, 255, 255))
                    d.line([P_(x - er * 1.1, fy - er * .05), P_(x + er * 1.1, fy + er * .02)], fill=ink, width=wd(c, 1.1))
        elif e in ('stern', 'worried', 'cross'):
            for i, x in enumerate(ex):
                glossy(d, x, fy, er * .95)
                sd = -1 if i == 0 else 1
                inner, outer = x - sd * er * 1.0, x + sd * er * 1.1
                if e == 'stern':
                    d.line([P_(inner, fy - er * 1.45), P_(outer, fy - er * 1.55)], fill=ink, width=wd(c, 1.4 * u))
                elif e == 'worried':
                    d.line([P_(inner, fy - er * 1.95), P_(outer, fy - er * 1.4)], fill=ink, width=wd(c, 1.3 * u))
                else:                     # cross (determined, not evil)
                    d.line([P_(inner, fy - er * 1.2), P_(outer, fy - er * 1.75)], fill=ink, width=wd(c, 1.4 * u))
        elif e == 'one':
            r = er * 1.5
            d.ellipse([*P_(fx - r, fy - r), *P_(fx + r, fy + r)], fill=(252, 250, 244), outline=ink, width=wd(c, .9))
            glossy(d, fx + look * r * .25, fy, r * .58)
        elif e == 'three':
            for x, yy, r in [(ex[0], fy, er * .8), (ex[1], fy, er * .8), (fx, fy - er * 1.95, er * .7)]:
                d.ellipse([*P_(x - r, yy - r * 1.1), *P_(x + r, yy + r * 1.1)], fill=ink)
                d.ellipse([*P_(x - r * .55, yy - r * .75), *P_(x + r * .15, yy - r * .05)], fill=(190, 255, 220))
        elif e == 'visor':
            d.rounded_rectangle([*P_(fx - sp - er * 1.5, fy - er * .95), *P_(fx + sp + er * 1.5, fy + er * .95)], radius=int(er * c.k * c.f), fill=(20, 24, 34))
            for x in ex:
                d.rounded_rectangle([*P_(x - er * .75, fy - er * .32), *P_(x + er * .75, fy + er * .32)], radius=int(er * .3 * c.k * c.f), fill=(120, 255, 210))
        elif e == 'shades':
            for x in ex:
                d.rounded_rectangle([*P_(x - er * 1.15, fy - er * .75), *P_(x + er * 1.15, fy + er * .7)], radius=int(er * .4 * c.k * c.f), fill=(16, 14, 24))
                d.line([P_(x - er * .7, fy - er * .35), P_(x - er * .2, fy - er * .35)], fill=(120, 130, 170), width=wd(c, .8))
            d.line([P_(ex[0] + er * 1.1, fy - er * .3), P_(ex[1] - er * 1.1, fy - er * .3)], fill=(16, 14, 24), width=wd(c, 1.0))
        elif e == 'star':
            for x in ex:
                pts = []
                for i in range(10):
                    r = er * (1.18 if i % 2 == 0 else .5); a = -math.pi / 2 + i * math.pi / 5
                    pts.append(P_(x + r * math.cos(a), fy + r * math.sin(a)))
                d.polygon(pts, fill=ink)
        elif e == 'x':
            for x in ex:
                r = er * .75
                d.line([P_(x - r, fy - r), P_(x + r, fy + r)], fill=ink, width=wd(c, 1.5))
                d.line([P_(x - r, fy + r), P_(x + r, fy - r)], fill=ink, width=wd(c, 1.5))
        elif e == 'spiral':
            for x in ex:
                pts = [P_(x + math.cos(t) * er * t / 9, fy + math.sin(t) * er * t / 9) for t in np.linspace(0, 9, 30)]
                d.line(pts, fill=ink, width=wd(c, 1.0))
        # ---- extras under the mouth
        if 'blush' in extras:
            for sd in (-1, 1):
                x = fx + sd * (sp + er * .55)
                d.ellipse([*P_(x - 2.7 * u, fy + 2.5 * u), *P_(x + 2.7 * u, fy + 4.6 * u)], fill=(236, 120, 140, 165))
        if 'freckles' in extras:
            for sd in (-1, 1):
                for i in range(3):
                    x = fx + sd * (sp + er * .2 + i * 1.3 * u); y = fy + 3.6 * u + (i % 2) * u
                    d.ellipse([*P_(x - .55, y - .55), *P_(x + .55, y + .55)], fill=dark)
        # ---- mouths
        m = mouth
        if m == 'flat':
            line_m(d)
        elif m == 'dot':
            d.ellipse([*P_(fx - .75 * u, my + .5 * u), *P_(fx + .75 * u, my + 1.9 * u)], fill=ink)
        elif m == 'o':
            d.ellipse([*P_(fx - 1.2 * u, my), *P_(fx + 1.2 * u, my + 2.7 * u)], fill=ink)
        elif m == 'w':
            y = my + .7 * u
            d.line([P_(fx - 2.3 * u, y), P_(fx - 1.15 * u, y + 1 * u), P_(fx, y), P_(fx + 1.15 * u, y + 1 * u), P_(fx + 2.3 * u, y)], fill=ink, width=lw, joint='curve')
        elif m == 'v':
            y = my + .6 * u
            d.line([P_(fx - 1.6 * u, y), P_(fx, y + 1.3 * u), P_(fx + 1.6 * u, y)], fill=ink, width=lw, joint='curve')
        elif m == 'smile':
            d.chord([*P_(fx - 2.8 * u, my - 2.4 * u), *P_(fx + 2.8 * u, my + 3.4 * u)], 0, 180, fill=ink)
            d.chord([*P_(fx - 1.7 * u, my + .9 * u), *P_(fx + 1.7 * u, my + 3.6 * u)], 180, 360, fill=(226, 110, 130))
        elif m == 'grin':
            d.chord([*P_(fx - 3.4 * u, my - 2.0 * u), *P_(fx + 3.4 * u, my + 3.2 * u)], 0, 180, fill=ink)
            d.rectangle([*P_(fx - 2.6 * u, my + .5 * u), *P_(fx + 2.6 * u, my + 1.2 * u)], fill=(255, 255, 255))
        elif m == 'frown':
            d.arc([*P_(fx - 2.2 * u, my + .8 * u), *P_(fx + 2.2 * u, my + 4.0 * u)], 200, 340, fill=ink, width=lw)
        elif m == 'pout':
            d.line([P_(fx - 1.5 * u, my + 2 * u), P_(fx, my + 1.1 * u), P_(fx + 1.5 * u, my + 2 * u)], fill=ink, width=lw)
        elif m == 'smirk':
            d.line([P_(fx - 1.6 * u, my + 1.6 * u), P_(fx + 1.0 * u, my + 1.5 * u), P_(fx + 2.0 * u, my + .6 * u)], fill=ink, width=lw)
        elif m in ('fang', 'fangs'):
            line_m(d, 2.1)
            xs_ = [fx + .9 * u] if m == 'fang' else [fx - 1.2 * u, fx + 1.2 * u]
            for x in xs_:
                d.polygon([P_(x - .6 * u, my + 1.2 * u), P_(x + .6 * u, my + 1.2 * u), P_(x, my + 2.7 * u)], fill=(255, 255, 255))
        elif m == 'teeth':
            d.rectangle([*P_(fx - 1.3 * u, my + .9 * u), *P_(fx + 1.3 * u, my + 2.5 * u)], fill=(255, 255, 255), outline=ink, width=wd(c, .6))
            d.line([P_(fx, my + .9 * u), P_(fx, my + 2.5 * u)], fill=ink, width=wd(c, .5))
        elif m == 'wavy':
            pts = [P_(fx - 2.6 * u + i * 1.3 * u, my + 1.2 * u + (1 if i % 2 else -1) * .55 * u) for i in range(5)]
            d.line(pts, fill=ink, width=lw)
        elif m == 'open':
            d.chord([*P_(fx - 1.8 * u, my - .4 * u), *P_(fx + 1.8 * u, my + 3.2 * u)], 0, 180, fill=ink)
        elif m == 'tongue':
            line_m(d, 1.8)
            d.chord([*P_(fx - .2 * u, my + .2 * u), *P_(fx + 2.0 * u, my + 3.4 * u)], 0, 180, fill=(232, 96, 120))
        elif m == 'beak':
            col = (250, 176, 40)
            d.polygon([P_(fx - 2.2 * u, my - .6 * u), P_(fx + 2.2 * u, my - .6 * u), P_(fx, my + 2.6 * u)], fill=col, outline=ink)
        if 'sweat' in extras:
            x = fx + sp + er * 1.4; y = fy - er * 1.2
            d.polygon([P_(x, y - 2.4 * u), P_(x + 1.4 * u, y + .2 * u), P_(x - 1.4 * u, y + .2 * u)], fill=(150, 205, 250))
            d.ellipse([*P_(x - 1.4 * u, y - 1.0 * u), *P_(x + 1.4 * u, y + 1.6 * u)], fill=(150, 205, 250))
        if 'tear' in extras:
            x = ex[1] + er * .2; y = fy + er * 1.2
            d.ellipse([*P_(x - .9 * u, y), *P_(x + .9 * u, y + 2.2 * u)], fill=(140, 200, 250))
        if 'stache' in extras:
            y = my + .2 * u
            for sd in (-1, 1):
                d.chord([*P_(fx + (0 if sd > 0 else -5 * u), y - 1.6 * u), *P_(fx + (5 * u if sd > 0 else 0), y + 1.8 * u)], 180, 360, fill=dark)
    draw_on(c, fn)


# ------------------------------------------------------------------ parts
BACK = {'tails', 'broth', 'bone', 'ears_droop', 'eyestalks', 'lure', 'stinger', 'plate', 'ribbon', 'skirt', 'shroomcap', 'seaweed', 'bunhair',
        'leaf', 'leaf2', 'leaf3', 'bigleaf', 'sprout', 'clover', 'stem', 'stalk', 'twig', 'flame', 'flames', 'ears', 'ears_cat',
        'ears_bear', 'ears_bunny', 'ears_fox', 'ears_mouse', 'horns', 'horn', 'nubs', 'ramhorns', 'antennae', 'antenna',
        'wings', 'wings_bug', 'wings_bat', 'wings_tiny', 'tail', 'tail_fluff', 'tail_fish', 'tail_devil', 'tail_curl', 'tail_lizard',
        'fins', 'fin', 'spikes', 'crest', 'quills', 'petals', 'tentacles', 'legs', 'claws', 'roots', 'bow', 'wrapper', 'cherry',
        'stick', 'mane', 'frills', 'whiskers_b', 'topknot', 'tuft', 'curl', 'umbrella', 'halo_b', 'shell', 'pinwheel', 'feather',
        'cap_leaf', 'vines', 'mushcap', 'flower', 'hat', 'tassel', 'bubbles_b', 'crown_b'}
FRONT = {'arms', 'feet', 'nose', 'snout', 'beak_f', 'cheeks', 'paws', 'bib', 'tie', 'scarf', 'pin', 'mitts', 'longnose', 'longbeak',
         'tusks', 'pawup', 'collar', 'leg'}
REGION = {'cap', 'drip', 'base', 'band', 'belly', 'half', 'diag', 'spots', 'stripes', 'hstripes', 'tip', 'mask', 'nori',
          'crust', 'glaze', 'warts', 'seeds', 'scales', 'socks', 'patch', 'dapple', 'blaze', 'tiers', 'sugar', 'grill',
          'swirlband', 'face_patch', 'rim', 'bottom', 'speckle', 'zigzag', 'checker', 'facets', 'web', 'eyepatches', 'bangs',
          'darumaface', 'lanternbands', 'ribs', 'leafveins', 'ridges', 'holes', 'crustedge', 'grid', 'clamridges'}
OVER = {'sprinkles', 'sesame', 'sparkles', 'steam', 'bubbles', 'drop', 'stars', 'crumbs', 'bolts', 'chip', 'crack',
        'crown', 'halo', 'bandage', 'gem', 'flowerpin', 'sweatband', 'smoke', 'zzz', 'notes', 'plaster', 'bowtie', 'lightning',
        'embers', 'rune', 'mark', 'glow', 'snow', 'heart', 'scar', 'monocle', 'leafpin', 'sticker', 'antenna_bulb', 'whiskers',
        'hachimaki', 'kanji', 'capspots', 'pleats', 'swirltop'}


def render(spec, stage, seed_name='', _lift=0.0, _fit=1.0, _pass=0):
    """spec: dict(plan, mods, pal, acc, acc2, parts[(name, colour)], eyes, mouth, extras)"""
    if 'special' in spec:
        return special(spec['special'])
    ground = GROUND - _lift                    # (lifted when something hangs below the canvas)
    c = Canvas(W, H, K, F, anchor=(55, ground))
    plan = PLANS[spec['plan']]
    mods = spec.get('mods', {})
    s = STAGE[stage] * mods.get('s', 1.0) * _fit
    sx = mods.get('sx', 1.0)
    sy = mods.get('sy', 1.0)
    lean = mods.get('lean', 0.0)
    pal = P[spec['pal']]
    acc = P[spec.get('acc') or spec['pal']]
    acc2 = P[spec.get('acc2') or spec.get('acc') or spec['pal']]
    rr = np.random.default_rng(zlib.crc32((seed_name + stage).encode()))

    def colr(tok, default):
        if not tok:
            return default
        return {'p': pal, 'a': acc, 'b': acc2}.get(tok) or P[tok]

    lift = 7 if plan.get('stick') else 0

    def prims(sx_):
        out = []
        for b in plan['b']:
            x, y, rx, ry = b[:4]
            x = x + lean * (-y)
            out.append((55 + x * s * sx_, ground + (y - lift) * s * sy, rx * s * sx_, ry * s * sy, *b[4:]))
        return out

    wide_parts = {'wings', 'wings_bug', 'wings_bat', 'tail_fish', 'claws', 'wrapper', 'fins', 'tentacles', 'tail', 'tail_fluff',
                  'tail_lizard', 'tail_curl', 'tail_devil', 'frills', 'mane', 'petals', 'tails'}
    has_wide = any(n in wide_parts for n, _ in spec.get('parts', []))
    lim = (62 if has_wide else 76) if stage != 'legend' else (60 if has_wide else 72)
    hlim = {'baby': 48, 'kid': 52, 'adult': 66, 'mutant': 66, 'legend': 70}[stage]
    if any(n in ('leaf3', 'bigleaf', 'flames', 'horns', 'ears_bunny', 'crown', 'halo', 'antennae', 'stalk', 'ramhorns', 'ears_fox') for n, _ in spec.get('parts', [])):
        hlim -= 8
    for _ in range(3):
        bf = sfield(c, prims(sx))
        if plan.get('cut'):
            cx_, cy_, rx_, ry_ = plan['cut']
            bf = bf - 1.4 * sfield(c, [(55 + cx_ * s * sx, ground + cy_ * s * sy, rx_ * s * sx, ry_ * s * sy)])
        if plan.get('cutbottom'):
            bf = np.where(c.y > ground - 1, 0, bf)
        if plan.get('rim'):                    # a bowl: the lower half of an ellipse (round bottom, flat top)
            rx_, ry_ = plan['b'][0][2] * s * sx, plan['b'][0][3] * s * sy
            cy0 = ground - ry_
            bf = sfield(c, [(55, cy0, rx_, ry_)])
            bf = np.where(c.y < cy0, 0, bf)
        bm = bf > 1
        g = Geo(c, bm)
        if g.w > lim + .5:
            sx *= lim / g.w
            continue
        if g.h > hlim + .5:
            sy *= hlim / g.h
            sx *= (hlim / g.h) ** .5
            continue
        break
    if plan.get('ring'):                       # a donut: the hole through it, torus shading
        cx0, cy0 = 55, ground + plan['b'][0][1] * s * sy
        rx0, ry0 = plan['b'][0][2] * s * sx, plan['b'][0][3] * s * sy
        dd = np.hypot((c.x - cx0) / rx0, (c.y - cy0) / ry0)
        tor = 1 - ((dd - .62) / .38) ** 2
        bm = tor > 0
        bf = 1 / np.maximum(1 - np.clip(tor, 0, 1) * .75, 1e-3)
        g = Geo(c, bm)
    u = g.w / 44
    fx0, fy0 = plan['face']
    fx = 55 + (fx0 + lean * (-fy0)) * s * sx + mods.get('fx', 0) * g.w
    fy = ground + (fy0 - lift) * s * sy if 'fy' not in mods else g.top + g.h * mods['fy']
    cxp = 55 + (lean * g.h * .5)               # where the head top is (leaning bodies)
    tt = g.top_at(cxp)
    gl = GLOSS.get(spec['pal'], (.4, 22))
    grain = GRAIN.get(spec['pal'], .08)
    parts = spec.get('parts', [])

    back, front, lines, over, regions = [], [], [], [], []
    blines = []                                # lines BEHIND the body (a skewer through dango)
    deferred = []

    def add_back(fld, p_, **kw):
        back.append((fld, p_, kw))

    # ---------------------------------------------------------- build the parts
    for name, tok in parts:
        fp = colr(tok, acc)
        if name in ('leaf', 'sprout', 'leaf2', 'leaf3', 'bigleaf', 'clover'):
            lp = colr(tok, P['leaf'])
            base = (cxp + .3 * u, tt + 1.2)
            stemtop = (cxp + .6 * u, tt - 3.5 * u)
            lines.append(((cxp, tt + 1.5), stemtop, 2.0 * u ** .5, tone(P['leaf'], 1)))
            if name in ('leaf', 'sprout'):
                add_back(sfield(c, leafshape(stemtop, (stemtop[0] + 10 * u, stemtop[1] - 5.5 * u), 3.1 * u, bend=-1.4 * u)), lp)
            elif name == 'leaf2':
                add_back(sfield(c, leafshape(stemtop, (stemtop[0] - 9 * u, stemtop[1] - 6 * u), 2.9 * u, bend=1.3 * u)), lp)
                add_back(sfield(c, leafshape(stemtop, (stemtop[0] + 9.5 * u, stemtop[1] - 6.5 * u), 3.0 * u, bend=-1.3 * u)), lp)
            elif name == 'leaf3':
                for ang, L in ((-150, 8), (-90, 9), (-30, 8)):
                    a = math.radians(ang)
                    add_back(sfield(c, leafshape(stemtop, (stemtop[0] + math.cos(a) * L * u, stemtop[1] + math.sin(a) * L * u), 2.3 * u)), lp)
            elif name == 'bigleaf':
                add_back(sfield(c, leafshape((cxp - 2 * u, tt + 1), (cxp + 15 * u, tt - 9 * u), 5.2 * u, n=11, bend=-2 * u)), lp)
            else:
                for ang in (-140, -90, -40):
                    a = math.radians(ang)
                    add_back(sfield(c, [(stemtop[0] + math.cos(a) * 3.6 * u, stemtop[1] + math.sin(a) * 3.6 * u, 3.0 * u, 3.0 * u)]), lp)
        elif name in ('stem', 'stalk', 'twig'):
            col = tone(colr(tok, P['wood']), 1)
            if name == 'stem':
                lines.append(((cxp + 1, tt + 1.5), (cxp + 3 * u, tt - 4.5 * u), 2.3 * u ** .5, col))
            elif name == 'stalk':
                lines.append(((cxp, tt + 1.5), (cxp + 4 * u, tt - 11 * u), 1.5 * u ** .5, col))
            else:
                lines.append(((cxp - 1, tt + 1.5), (cxp - 3 * u, tt - 8 * u), 1.8 * u ** .5, col))
                lines.append(((cxp - 2 * u, tt - 4 * u), (cxp - 6 * u, tt - 6 * u), 1.3 * u ** .5, col))
        elif name in ('flame', 'flames'):
            deferred.append(('flame', tok, 1.0 if name == 'flame' else 1.35))
        elif name in ('ears', 'ears_cat', 'ears_fox'):
            y = g.top + g.h * .22; hw = g.half_w(y)
            L = 8 if name != 'ears_fox' else 11
            for sd in (-1, 1):
                add_back(sfield(c, chain((cxp + sd * hw * .55, y + 2), (cxp + sd * (hw * .82 + 2 * u), y - L * u), 4.4 * u, 1.0 * u, 8)), fp)
        elif name == 'ears_bear':
            y = g.top + g.h * .2; hw = g.half_w(y)
            for sd in (-1, 1):
                add_back(sfield(c, [(cxp + sd * hw * .72, y - 1.5 * u, 4.2 * u, 4.0 * u)]), fp)
        elif name == 'ears_mouse':
            y = g.top + g.h * .2; hw = g.half_w(y)
            for sd in (-1, 1):
                add_back(sfield(c, [(cxp + sd * (hw * .8 + 1 * u), y - 2.5 * u, 6.0 * u, 5.6 * u)]), fp)
        elif name == 'ears_bunny':
            y = g.top + g.h * .12
            for sd in (-1, 1):
                add_back(sfield(c, chain((cxp + sd * 4.5 * u, y + 2), (cxp + sd * 7 * u, y - 14 * u), 3.0 * u, 2.3 * u, 8, sd * .8 * u)), fp)
        elif name in ('horns', 'nubs', 'ramhorns', 'horn'):
            y = g.top + g.h * .18; hw = g.half_w(y)
            hp = colr(tok, P['cream'])
            if name == 'horns':
                y = g.top + g.h * .14; hw = g.half_w(y)
                for sd in (-1, 1):
                    x0 = cxp + sd * hw * .5
                    t0 = g.top_at(x0)
                    pts = []
                    for i in range(9):
                        t = i / 8
                        pts.append((x0 + sd * (1.6 * t + .9 * t * t) * u, t0 + 2.2 - t * 8.0 * u, max(.25, 2.5 * (1 - t) ** 1.15) * u, max(.25, 2.5 * (1 - t) ** 1.15) * u))
                    add_back(sfield(c, pts), hp, gloss=(.6, 16))
            elif name == 'nubs':
                for sd in (-1, 1):
                    add_back(sfield(c, [(cxp + sd * hw * .5, y - 1.8 * u, 2.6 * u, 2.6 * u)]), hp)
            elif name == 'horn':
                add_back(sfield(c, chain((cxp, tt + 2), (cxp + 1 * u, tt - 9 * u), 2.8 * u, .7 * u, 7)), hp)
            else:
                for sd in (-1, 1):
                    pts = []
                    for i in range(10):
                        t = i / 9; a = math.pi * (1.1 + 1.25 * t)
                        R = (5.5 - 2 * t) * u
                        pts.append((cxp + sd * (hw * .7 + 3.5 * u - math.cos(a) * R), y + 2 * u - math.sin(a) * R, (2.8 - 1.5 * t) * u, (2.8 - 1.5 * t) * u))
                    add_back(sfield(c, pts), hp)
        elif name in ('antennae', 'antenna'):
            tips = [(cxp + 3 * u, tt - 8.5 * u)] if name == 'antenna' else [(cxp - 6 * u, tt - 7.5 * u), (cxp + 6 * u, tt - 7.5 * u)]
            for (x, y) in tips:
                x0 = cxp + (x - cxp) * .35
                lines.append(((x0, g.top_at(x0) + 1.5), (x, y), 1.1 * u ** .5, (50, 40, 46)))
                front.append((sfield(c, [(x, y - .5 * u, 2.1 * u, 2.1 * u)]), fp, {}))
        elif name in ('wings', 'wings_bug', 'wings_bat', 'wings_tiny'):
            y = g.top + g.h * .42; hw = g.half_w(y)
            for sd in (-1, 1):
                if name == 'wings':
                    for i in range(3):
                        ang = math.radians(-28 + i * 26)
                        x0, y0 = cxp + sd * hw * .72, y + i * 3.6 * u
                        L = (12 + 3 * (2 - i)) * u
                        add_back(sfield(c, chain((x0, y0), (x0 + sd * math.cos(ang) * L, y0 - math.sin(ang) * L), 3.3 * u, 1.5 * u, 6)), fp)
                elif name == 'wings_bug':
                    wp = colr(tok, P['ice'])
                    add_back(sfield(c, [(cxp + sd * (hw * .7 + 6 * u), y - 5 * u, 7.5 * u, 4.2 * u)]), wp, gloss=(.9, 10))
                    add_back(sfield(c, [(cxp + sd * (hw * .7 + 4 * u), y + 2 * u, 5 * u, 3 * u)]), wp, gloss=(.9, 10))
                elif name == 'wings_bat':
                    pts = chain((cxp + sd * hw * .6, y), (cxp + sd * (hw + 12 * u), y - 9 * u), 3.4 * u, 1.0 * u, 7, sd * 2 * u)
                    pts += chain((cxp + sd * (hw + 12 * u), y - 9 * u), (cxp + sd * (hw + 8 * u), y + 3 * u), 1.6 * u, 2.4 * u, 5)
                    add_back(sfield(c, pts), fp)
                else:
                    add_back(sfield(c, chain((cxp + sd * hw * .8, y + 1), (cxp + sd * (hw + 5 * u), y - 3 * u), 3.0 * u, 2.0 * u, 5)), fp)
        elif name in ('tail', 'tail_curl', 'tail_fluff', 'tail_fish', 'tail_devil', 'tail_lizard'):
            sd = 1
            y = g.bot - g.h * .28; x = g.side_at(y, sd) - 2 * u
            if name == 'tail':
                add_back(sfield(c, chain((x, y + 2), (x + 9 * u, y - 7 * u), 3.0 * u, 2.0 * u, 8, -3 * u)), fp)
            elif name == 'tail_curl':
                pts = []
                for i in range(14):
                    t = i / 13; a = math.pi * (1.0 - 1.8 * t)
                    R = (6 - 3 * t) * u
                    pts.append((x + 6 * u + math.cos(a) * R, y - 3 * u - math.sin(a) * R, (2.6 - 1.2 * t) * u, (2.6 - 1.2 * t) * u))
                add_back(sfield(c, pts), fp)
            elif name == 'tail_fluff':
                add_back(sfield(c, chain((x, y + 2), (x + 8 * u, y - 13 * u), 4.0 * u, 6.0 * u, 7, -4 * u)), fp)
            elif name == 'tail_fish':
                y = g.top + g.h * .55; x = g.side_at(y, -1) + 2 * u
                add_back(sfield(c, chain((x, y), (x - 9 * u, y - 6 * u), 2.4 * u, 3.0 * u, 6) + chain((x, y), (x - 9 * u, y + 6 * u), 2.4 * u, 3.0 * u, 6)), fp)
            elif name == 'tail_devil':
                pts = chain((x, y + 2), (x + 11 * u, y - 9 * u), 1.4 * u, 1.1 * u, 9, -3 * u)
                tx, ty = pts[-1][0], pts[-1][1]
                pts += [(tx + 1 * u, ty - 1 * u, 2.6 * u, 2.0 * u, 1.3)]
                add_back(sfield(c, pts), fp)
            else:
                add_back(sfield(c, chain((x - 2 * u, g.bot - 3 * u), (x + 14 * u, g.bot - 1 * u), 3.6 * u, 1.0 * u, 9, 2 * u)), fp)
        elif name in ('fins', 'fin'):
            if name == 'fins':
                y = fy + 3 * u; hw = g.half_w(y)
                for sd in (-1, 1):
                    add_back(sfield(c, chain((cxp + sd * (hw - 3), y), (cxp + sd * (hw + 7 * u), y - 4 * u), 3.4 * u, 1.2 * u, 7, sd * 1.5 * u)), fp)
            else:
                add_back(sfield(c, chain((cxp - 2 * u, tt + 3), (cxp + 4 * u, tt - 7 * u), 4.0 * u, .8 * u, 8, -2.5 * u)), fp)
        elif name in ('spikes', 'crest', 'quills'):
            xs = {'crest': (-5, 0, 5), 'spikes': (-12, -6, 0, 6, 12), 'quills': (-14, -9, -4, 1, 6, 11, 15)}[name]
            for dx in xs:
                x = cxp + dx * u
                if x < g.l + 3 or x > g.r - 3:
                    continue
                t = g.top_at(x)
                hgt = (7.5 if (dx == 0 and name == 'crest') else 5 if name != 'quills' else 6) * u
                lean_ = dx * .3 * u if name != 'crest' else dx * .2 * u
                add_back(sfield(c, chain((x, t + 2.5), (x + lean_, t - hgt), 2.8 * u, .6 * u, 6)), fp)
        elif name == 'petals':
            f_ = np.zeros_like(c.x)
            for i in range(8):
                a = math.pi + i * math.pi / 7
                f_ += sfield(c, [(cxp + math.cos(a) * g.w * .52, g.top + g.h * .5 + math.sin(a) * g.h * .56, 4.8 * u, 4.8 * u)])
            add_back(f_, colr(tok, P['pink']))
        elif name == 'mane':
            f_ = np.zeros_like(c.x)
            for i in range(11):
                a = math.pi * .95 + i * math.pi * 1.1 / 10
                f_ += sfield(c, [(cxp + math.cos(a) * g.w * .5, fy - 1 * u + math.sin(a) * g.h * .55, 5.0 * u, 5.0 * u)])
            add_back(f_, fp)
        elif name == 'tentacles':
            hw = g.half_w(g.bot - 4)
            for sd in (-1, 1):
                for j in range(2):
                    balls = []
                    for i in range(9):
                        t = i / 8
                        x = cxp + sd * (hw * (.45 + j * .3) + t * (10 + j * 3) * u)
                        y = g.bot - 2 - j * 1.5 - math.sin(t * math.pi * 1.2) * (3 + j * 2) * u + t * 2
                        balls.append((x, y, (3.2 - t * 2.0) * u, (2.8 - t * 1.7) * u))
                    add_back(sfield(c, balls), fp)
        elif name == 'legs':
            f_ = np.zeros_like(c.x)
            for dx in (-10, -4, 4, 10):
                f_ += sfield(c, chain((cxp + dx * u, g.bot - 4), (cxp + dx * 1.25 * u, g.bot + 1.5), 1.5 * u, 1.2 * u, 4))
            add_back(f_, colr(tok, P['char']))
        elif name == 'claws':
            y = fy + 2 * u; hw = g.half_w(y)
            for sd in (-1, 1):
                x0 = cxp + sd * (hw - 1)
                arm = chain((x0, y + 2 * u), (x0 + sd * 6 * u, y - 4 * u), 2.0 * u, 2.0 * u, 5)
                tip = (x0 + sd * 7 * u, y - 7 * u)
                claw = [(tip[0] - sd * 1.6 * u, tip[1], 2.6 * u, 3.6 * u), (tip[0] + sd * 1.8 * u, tip[1] - .5 * u, 2.2 * u, 3.4 * u)]
                add_back(sfield(c, arm + claw), fp)
        elif name == 'roots':
            for dx in (-8, -2, 5, 10):
                x = cxp + dx * u
                lines.append(((x, g.bot - 1.5), (x + dx * .35 * u, g.bot + 2.5), 1.2 * u ** .5, tone(colr(tok, P['wood']), 1)))
        elif name in ('bow', 'wrapper'):
            if name == 'bow':
                for sd in (-1, 1):
                    add_back(sfield(c, [(cxp + sd * 4.2 * u, tt - 1.8 * u, 4.0 * u, 2.8 * u)]), fp)
                add_back(sfield(c, [(cxp, tt - 1.2 * u, 1.8 * u, 1.8 * u)]), fp)
            else:                       # a sweet's wrapper twisted on both sides
                y = g.top + g.h * .5; hw = g.half_w(y)
                for sd in (-1, 1):
                    x0 = cxp + sd * (hw - 1)
                    add_back(sfield(c, [(x0 + sd * 2.5 * u, y, 2.0 * u, 2.4 * u), (x0 + sd * 7 * u, y, 2.6 * u, 6 * u, 2.6)]), fp)
        elif name == 'cherry':
            deferred.append(('cherry', tok, 1.0))
        elif name == 'stick':
            blines.append(((cxp, g.bot + 3 * u), (cxp, tt - 7 * u), 2.0 * u ** .5, tone(P['wood'], 3)))
        elif name in ('topknot', 'tuft', 'curl'):
            if name == 'topknot':
                add_back(sfield(c, [(cxp, tt - 2.5 * u, 4 * u, 3.4 * u)]), fp)
            elif name == 'tuft':
                add_back(sfield(c, chain((cxp, tt + 2), (cxp + 6 * u, tt - 5 * u), 2.6 * u, 1.2 * u, 7, -2.5 * u)), fp)
            else:
                pts = []
                for i in range(12):
                    t = i / 11; a = math.pi * (.5 + 1.6 * t)
                    R = (4.2 - 2.4 * t) * u
                    pts.append((cxp + 1.5 * u + math.cos(a) * R, tt - 4 * u - math.sin(a) * R, (1.8 - .9 * t) * u, (1.8 - .9 * t) * u))
                add_back(sfield(c, pts), fp)
        elif name == 'mushcap':
            t = g.top + g.h * .2
            front.append((sfield(c, [(cxp, t, g.w * .55, g.h * .17), (cxp, t - g.h * .07, g.w * .38, g.h * .17)]), fp, {}))
        elif name == 'hat':                 # a little flat hat / lid
            front.append((sfield(c, [(cxp, tt - .5 * u, 10 * u, 2.2 * u, 3), (cxp, tt - 3.5 * u, 6.5 * u, 3.5 * u, 3)]), fp, {}))
        elif name == 'shell':
            hw = g.half_w(g.top + g.h * .5)
            add_back(sfield(c, [(cxp - 3 * u, g.top + g.h * .45, hw * .95, g.h * .5)]), fp)
        elif name == 'umbrella':
            front.append((sfield(c, [(cxp, tt - 5 * u, 15 * u, 3.6 * u), (cxp, tt - 7 * u, 10 * u, 3.6 * u)]), fp, {}))
            lines.append(((cxp, tt - 4 * u), (cxp, tt + 2), 1.2 * u ** .5, (60, 40, 40)))
        elif name == 'flower':
            deferred.append(('flower', tok, 1.0))
        elif name == 'feather':
            add_back(sfield(c, leafshape((cxp - 2 * u, tt + 1), (cxp - 7 * u, tt - 12 * u), 2.4 * u, bend=1.5 * u)), fp)
        elif name == 'tassel':
            lines.append(((cxp, tt + 1), (cxp + 1 * u, tt - 6 * u), 1.0 * u ** .5, tone(fp, 1)))
            front.append((sfield(c, [(cxp + 1 * u, tt - 7 * u, 2.2 * u, 2.2 * u)]), fp, {}))
        elif name == 'frills':
            y = fy; hw = g.half_w(y)
            for sd in (-1, 1):
                for i in range(3):
                    a = math.radians(-35 + i * 35)
                    x0 = cxp + sd * (hw - 1)
                    add_back(sfield(c, chain((x0, y), (x0 + sd * math.cos(a) * 7 * u, y - math.sin(a) * 7 * u), 1.6 * u, 1.0 * u, 5)), fp)
        elif name == 'vines':
            y = g.top + g.h * .3
            for sd in (-1, 1):
                pts = chain((cxp + sd * g.half_w(y) * .8, y), (cxp + sd * (g.half_w(y) + 4 * u), g.bot - 2), 1.4 * u, 1.0 * u, 8, sd * 2.5 * u)
                add_back(sfield(c, pts), colr(tok, P['leaf']))
        elif name == 'crown_b':
            deferred.append(('crown', tok, 1.0))
        elif name == 'pinwheel':
            for i in range(4):
                a = i * math.pi / 2 + .4
                add_back(sfield(c, [(cxp + math.cos(a) * 4 * u, tt - 6 * u + math.sin(a) * 4 * u, 3.6 * u, 2.2 * u)]), [P['spicy'], P['sweet'], P['greasy'], P['green']][i])
            lines.append(((cxp, tt + 1), (cxp, tt - 6 * u), 1.1 * u ** .5, (60, 40, 40)))
        elif name == 'ears_droop':            # floppy dog ears, hanging in front of the head's sides
            y = g.top + g.h * .16; hw = g.half_w(y + 4 * u)
            for sd in (-1, 1):
                front.append((sfield(c, chain((cxp + sd * hw * .78, y), (cxp + sd * (hw + 1.0 * u), y + 9.5 * u), 3.0 * u, 2.8 * u, 7, sd * 1.2 * u)), fp, {}))
        elif name == 'tails':                 # a fan of fluffy tails (kyubi)
            y = g.bot - g.h * .3; x = g.side_at(y, 1) - 3 * u
            for ang in (-70, -40, -10):
                a = math.radians(ang)
                add_back(sfield(c, chain((x, y), (x + math.cos(a) * 13 * u, y + math.sin(a) * 13 * u), 3.2 * u, 4.4 * u, 7, -2 * u)), fp)
        elif name == 'broth':                 # what is in the bowl, seen on top
            front.append((sfield(c, [(cxp, g.top + 1.6 * u, g.w * .45, 2.6 * u)]), fp, {}))
        elif name == 'bone':                  # a drumstick's bone, out of the top
            x0, y0 = cxp + 3 * u, tt + 2
            add_back(sfield(c, chain((x0, y0), (x0 + 4 * u, y0 - 7 * u), 1.6 * u, 1.6 * u, 5) +
                            [(x0 + 3.2 * u, y0 - 8.5 * u, 2.0 * u, 2.0 * u), (x0 + 5.6 * u, y0 - 7.4 * u, 2.0 * u, 2.0 * u)]), P['cream'])
        elif name == 'eyestalks':             # a snail's: stalks with dark tips
            for sd in (-1, 1):
                x = cxp + sd * 4 * u
                lines.append(((x, g.top_at(x) + 1.5), (x + sd * 2.5 * u, tt - 8 * u), 1.4 * u ** .5, tone(pal, 2)))
                front.append((sfield(c, [(x + sd * 2.5 * u, tt - 8.5 * u, 1.9 * u, 1.9 * u)]), pal, {}))
        elif name == 'lure':                  # an anglerfish's light
            pts = chain((cxp - 2 * u, tt + 1), (cxp + 7 * u, tt - 9 * u), .9 * u, .7 * u, 8, -4 * u)
            add_back(sfield(c, pts), pal)
            front.append((sfield(c, [(cxp + 7.5 * u, tt - 9.5 * u, 2.4 * u, 2.4 * u)]), colr(tok, P['lemon']), {'glow': True}))
        elif name == 'stinger':
            y = g.bot - g.h * .2; x = g.side_at(y, 1)
            add_back(sfield(c, chain((x - 2 * u, y), (x + 5 * u, y + 2 * u), 2.2 * u, .4 * u, 6)), colr(tok, P['char']))
        elif name == 'plate':                 # a kappa's dish on top of the head
            front.append((sfield(c, [(cxp, tt + 1.2 * u, 7.5 * u, 2.2 * u)]), colr(tok, P['ice']), {}))
        elif name == 'ribbon':
            x0 = cxp + g.half_w(g.top + g.h * .2) * .55
            y0 = g.top + g.h * .14
            for sd in (-1, 1):
                add_back(sfield(c, [(x0 + sd * 2.8 * u, y0 - 1.5 * u, 2.8 * u, 2.0 * u)]), fp)
            front.append((sfield(c, [(x0, y0 - 1.2 * u, 1.4 * u, 1.4 * u)]), fp, {}))
        elif name == 'skirt':                 # teru teru bozu: the cloth around the bottom
            y = g.bot - g.h * .3
            add_back(sfield(c, [(cxp, y + 3 * u, g.half_w(y) * 1.25, g.h * .28, 2.2)]), colr(tok, P['white']))
        elif name == 'shroomcap':             # a big cap above (a mushroom yokai)
            front.append((sfield(c, [(cxp, g.top + 1 * u, g.w * .62, g.h * .2), (cxp, g.top - 2 * u, g.w * .44, g.h * .2)]), fp, {}))
        elif name == 'seaweed':
            for dx in (-6, 4):
                x = cxp + dx * u
                pts = chain((x, g.top_at(x) + 2), (x + 2 * u, g.top_at(x) - 8 * u), 1.6 * u, 1.0 * u, 8, 2.5 * u)
                add_back(sfield(c, pts), colr(tok, P['teal']))
        elif name == 'bunhair':               # two hair buns
            for sd in (-1, 1):
                add_back(sfield(c, [(cxp + sd * g.half_w(g.top + g.h * .2) * .62, g.top + 1 * u, 3.4 * u, 3.4 * u)]), fp)
        elif name in FRONT:
            if name == 'arms':
                y = g.top + g.h * .72; hw = g.half_w(y)
                for sd in (-1, 1):
                    front.append((sfield(c, [(cxp + sd * (hw - .5), y, 3.2 * u, 2.5 * u)]), fp, {}))
            elif name == 'mitts':
                y = g.top + g.h * .7; hw = g.half_w(y)
                for sd in (-1, 1):
                    front.append((sfield(c, [(cxp + sd * (hw - 1), y - 1 * u, 3.6 * u, 3.4 * u)]), fp, {}))
            elif name == 'feet':
                front.append((sfield(c, [(cxp - 7 * u, g.bot - 1, 4.4 * u, 2.5 * u), (cxp + 7 * u, g.bot - 1, 4.4 * u, 2.5 * u)]), fp, {}))
            elif name == 'paws':
                front.append((sfield(c, [(cxp - 5 * u, g.bot - 2, 3.4 * u, 2.6 * u), (cxp + 5 * u, g.bot - 2, 3.4 * u, 2.6 * u)]), fp, {}))
            elif name in ('nose', 'snout'):
                r = (1.6 if name == 'nose' else 3.4) * u
                front.append((sfield(c, [(fx, fy + 3.2 * u, r * (1 if name == 'nose' else 1.25), r * (.85 if name == 'nose' else .9))]), fp, {'nostrils': name == 'snout'}))
            elif name == 'beak_f':
                front.append((sfield(c, [(fx, fy + 3.6 * u, 2.6 * u, 1.6 * u), (fx, fy + 5 * u, 1.4 * u, 1.4 * u)]), colr(tok, P['gold']), {}))
            elif name == 'cheeks':
                for sd in (-1, 1):
                    front.append((sfield(c, [(fx + sd * (g.half_w(fy + 4 * u) * .62), fy + 4.6 * u, 3.6 * u, 3.0 * u)]), fp, {}))
            elif name == 'bib':
                front.append((sfield(c, [(cxp, g.bot - g.h * .2, g.half_w(g.bot - g.h * .2) * .55, g.h * .16)]), fp, {}))
            elif name == 'scarf':
                y = fy + 7 * u
                front.append((sfield(c, [(cxp, y, g.half_w(y) * 1.02, 2.4 * u, 3)]), fp, {}))
                front.append((sfield(c, [(cxp + g.half_w(y) * .5, y + 4 * u, 2.2 * u, 4 * u)]), fp, {}))
            elif name == 'longnose':          # a tengu's
                front.append((sfield(c, chain((fx, fy + 2 * u), (fx + 7 * u, fy - 1 * u), 1.9 * u, 1.3 * u, 7)), colr(tok, pal), {}))
            elif name == 'longbeak':          # a kiwi's
                front.append((sfield(c, chain((fx + .5 * u, fy + 3 * u), (fx + 5 * u, fy + 13 * u), 1.9 * u, .9 * u, 8, 1.2 * u)), colr(tok, P['wood']), {}))
            elif name == 'tusks':
                for sd in (-1, 1):
                    front.append((sfield(c, chain((fx + sd * 2.2 * u, fy + 5 * u), (fx + sd * 2.8 * u, fy + 10 * u), 1.2 * u, .5 * u, 6)), P['white'], {}))
            elif name == 'pawup':             # a beckoning paw (maneki-neko)
                y = fy - 1 * u; x = g.side_at(y, 1) - 1 * u
                front.append((sfield(c, [(x, y, 3.4 * u, 3.6 * u), (x - 1 * u, y + 4 * u, 2.6 * u, 3 * u)]), fp, {}))
            elif name == 'collar':
                y = fy + 7.5 * u
                front.append((sfield(c, [(cxp, y, g.half_w(y) * .95, 1.6 * u, 3)]), fp, {}))
                front.append((sfield(c, [(cxp, y + 2.2 * u, 2.2 * u, 2.2 * u)]), P['gold'], {}))
            elif name == 'leg':               # one leg (karakasa-obake)
                front.append((sfield(c, chain((cxp, g.bot - 2), (cxp, g.bot + 5 * u), 1.8 * u, 1.6 * u, 5) + [(cxp + 1.5 * u, g.bot + 5.5 * u, 2.8 * u, 1.4 * u)]), fp, {}))
            elif name == 'tie':
                y = fy + 7 * u
                front.append((sfield(c, [(cxp, y + 1.5 * u, 1.6 * u, 1.4 * u), (cxp, y + 5 * u, 2.0 * u, 3.4 * u, 1.6)]), fp, {}))
        elif name in REGION:
            regions.append((name, fp, tok))
        else:
            over.append((name, fp))

    # ---------------------------------------------------------- paint
    if blines:
        def bln(d):
            for p0, p1, w_, colr_ in blines:
                d.line([c.P(*p0), c.P(*p1)], fill=colr_, width=max(2, int(w_ * K * F)))
        draw_on(c, bln)
    for f_, p_, kw in back:
        m = (f_ > 1) & ~bm
        gl_ = kw.get('gloss', (.35, 22))
        material(c, height(f_, .5), m, p_, bump=4, spec_amt=gl_[0], spec_pow=gl_[1], grain=.06)
        seam(c, m, (c.a > .5) & ~m & ~bm, .4)
    bh = height(bf, .55)
    if plan.get('tiers') or ('tiers', None) in [(n, None) for n, _, _ in regions]:
        fs_ = [sfield(c, [b]) for b in prims(sx)]
        idx = np.argmax(np.stack(fs_), 0)
        alt = colr(next((t for n, _, t in regions if n == 'tiers'), None), acc)
        cyc = [pal, alt] if not spec.get('acc2') else [pal, alt, acc2]
        for i in range(len(fs_)):
            m = bm & (idx == i)
            material(c, height(fs_[i], .55), m, cyc[i % len(cyc)], bump=4, spec_amt=gl[0], spec_pow=gl[1], grain=grain)
        for i in range(len(fs_) - 1):
            seam(c, bm & (idx == i + 1), bm & (idx == i), .5)
    else:
        material(c, bh, bm, pal, bump=4, spec_amt=gl[0], spec_pow=gl[1], grain=grain)
        if plan.get('segs'):
            fs_ = [sfield(c, [b]) for b in prims(sx)]
            idx = np.argmax(np.stack(fs_), 0)
            for i in range(len(fs_) - 1):
                seam(c, bm & (idx == i + 1), bm & (idx == i), .35)
    if plan.get('yolk'):                      # a fried egg's yolk, a glossy dome
        yf = sfield(c, [(55 + 2 * s, ground - 7.5 * s * sy, 8.5 * s, 7 * s)])
        material(c, height(yf, .5), yf > 1, colr(spec.get('acc'), P['greasy']) if spec.get('acc') else P['greasy'], bump=4, spec_amt=.85, spec_pow=12, grain=.03)
        seam(c, yf > 1, bm & ~(yf > 1), .35)
        bm = bm | (yf > 1)
    if plan.get('skewer'):
        def skw(d):
            d.line([c.P(55, g.bot + 4 * s), c.P(55, g.top - 6 * s)], fill=tone(P['wood'], 3), width=max(2, int(1.8 * s ** .5 * K * F)))
        im0 = to_image(c)
        lay = Image.new('RGBA', im0.size, (0, 0, 0, 0))
        dd = ImageDraw.Draw(lay)
        skw(dd)
        la = np.asarray(lay, np.float32)
        mk = (la[..., 3] > 0) & ~bm
        c.rgb[mk] = la[..., :3][mk]
        c.a[mk] = 1.0
    if plan.get('stick'):
        def stk(d):
            d.line([c.P(55, g.bot - 2), c.P(55, g.bot + 9 * s * .7)], fill=tone(P['cream'], 2), width=max(2, int(2.2 * s ** .5 * K * F)))
        draw_on(c, stk)
    for f_, p_, kw in back:
        seam(c, bm, (f_ > 1) & ~bm, .5)

    rmask = {}
    for name, fp, tok in regions:
        reg = None
        cx = cxp
        if name == 'cap':
            reg = bm & (c.y < g.top + g.h * .38 + 1.4 * u * np.sin(c.x * .55))
        elif name == 'drip':
            base = g.top + g.h * .34
            dr = base + 1.3 * np.sin(c.x * .5) + 6 * u * np.exp(-((c.x - (cx - 9 * u)) / 2.4) ** 2) + 8 * u * np.exp(-((c.x - (cx + 8 * u)) / 2.6) ** 2)
            reg = bm & (c.y < dr)
        elif name == 'base':
            reg = bm & (c.y > g.bot - g.h * .27 + .8 * np.sin(c.x * .6))
        elif name == 'bottom':
            reg = bm & (c.y > g.bot - g.h * .14)
        elif name == 'band':
            y0 = g.top + g.h * .66
            reg = bm & (c.y > y0) & (c.y < y0 + g.h * .14)
        elif name == 'nori':
            reg = bm & (np.abs(c.x - cx) < g.w * .2) & (c.y > fy + 6.5 * u)
        elif name == 'belly':                  # a tummy patch, low (never right under the mouth)
            reg = bm & (sfield(c, [(cx, g.bot - g.h * .1, min(g.w * .27, 15 * u), g.h * .17)]) > 1) & (c.y > fy + 7 * u)
        elif name == 'face_patch':
            reg = bm & (sfield(c, [(fx, fy + 1.5 * u, g.half_w(fy) * .78, 7.5 * u)]) > 1)
        elif name == 'mask':
            reg = bm & (np.abs(c.y - fy) < 3.6 * u) & (np.abs(c.x - fx) < g.half_w(fy) * .95)
        elif name == 'half':
            reg = bm & (c.x > cx + .8 * np.sin(c.y * .8))
        elif name == 'diag':
            reg = bm & ((c.x - cx) * .7 + (c.y - (g.top + g.h * .5)) < 0)
        elif name == 'tip':
            reg = bm & (c.y < g.top + g.h * .2)
        elif name == 'blaze':
            reg = bm & (np.abs(c.x - cx) < 2.6 * u + (c.y - g.top) * .05) & (c.y < fy - 1 * u)
        elif name == 'socks':
            reg = bm & (c.y > g.bot - g.h * .12) & (np.abs(c.x - cx) > 3 * u)
        elif name == 'rim':
            dist = np.where(bm, 1.0, 0.0)
            from scipy.ndimage import distance_transform_edt
            dd = distance_transform_edt(bm) / (c.k * c.f)
            reg = bm & (dd < 2.2 * u) & (c.y < g.top + g.h * .6)
        elif name in ('spots', 'patch', 'dapple', 'speckle'):
            n, rad = {'spots': (int(6 * s), 2.2), 'patch': (2, 5.5), 'dapple': (int(10 * s), 1.4), 'speckle': (int(22 * s), .7)}[name]
            bl = []
            tries = 0
            while len(bl) < n and tries < 400:
                tries += 1
                x, y = rr.uniform(g.l + 3, g.r - 3), rr.uniform(g.top + 3, g.bot - 3)
                if abs(y - fy) < 5.5 * u and abs(x - fx) < g.half_w(fy) * .72:
                    continue
                if not g.inside(x, y):
                    continue
                bl.append((x, y, rad * u * rr.uniform(.8, 1.2), rad * u * rr.uniform(.7, 1.0)))
            reg = bm & (sfield(c, bl) > 1) if bl else None
        elif name == 'stripes':
            reg = bm & (np.sin((c.x - cx) * 1.0 / u) > .55) & (c.y < g.top + g.h * .45)
        elif name == 'hstripes':
            reg = bm & (np.sin((c.y - g.bot) * 1.05 / u) > .6) & (c.y > fy + 5 * u)
        elif name == 'zigzag':
            yz = g.top + g.h * .55 + 2.0 * u * np.abs(((c.x / (3 * u)) % 2) - 1)
            reg = bm & (c.y > yz)
        elif name == 'checker':
            reg = bm & (((np.floor((c.x - cx) / (5 * u)) + np.floor((c.y - g.top) / (5 * u))) % 2) == 0)
        elif name == 'swirlband':
            reg = bm & (np.sin((c.y - g.top) * .55 / u + (c.x - cx) * .25 / u) > .55)
        elif name == 'grill':
            reg = bm & (np.abs(((c.x - c.y * .6) / (4.5 * u)) % 2 - 1) < .14) & (c.y < g.bot - 2 * u)
        elif name == 'web':
            reg = None
        elif name == 'ridges':
            reg = bm & (np.sin((c.x - cx) * 1.15 / u) > .6) & (c.y > g.top + 1.5 * u)
        elif name == 'holes':
            bl = []
            for (dx, dy, r) in ((-.55, .2, 2.4), (.5, .5, 1.8), (.2, -.3, 1.4), (-.25, .62, 1.3), (.62, -.05, 1.1)):
                x, y = cx + dx * g.w * .5, g.top + g.h * (.5 + dy * .5)
                if abs(y - fy) < 5 * u and abs(x - fx) < g.half_w(fy) * .6:
                    continue
                bl.append((x, y, r * u, r * .85 * u))
            reg = bm & (sfield(c, bl) > 1) if bl else None
        elif name == 'crustedge':           # a pizza slice's crust along the top
            reg = bm & (c.y < g.top + g.h * .2)
        elif name == 'grid':                # a chocolate bar
            gx = np.abs(((c.x - cx) / (6 * u)) % 1 - .5) > .44
            gy = np.abs(((c.y - g.top) / (6 * u)) % 1 - .5) > .44
            reg = bm & (gx | gy) & (np.abs(c.y - fy) > 5 * u)
        elif name == 'clamridges':
            ang = np.arctan2(c.y - (g.bot + 2), c.x - cx)
            reg = bm & (np.abs(np.sin(ang * 9)) < .18)
        elif name == 'eyepatches':
            sp_ = min(EYE[stage][1], g.half_w(fy) * .5)
            reg = bm & (sfield(c, [(fx - sp_, fy + .3 * u, 4.6 * u, 4.0 * u), (fx + sp_, fy + .3 * u, 4.6 * u, 4.0 * u)]) > 1)
        elif name == 'bangs':                  # hair with a straight fringe (kokeshi)
            reg = bm & (c.y < fy - 4.2 * u - .8 * u * np.abs(np.sin((c.x - cx) * .9 / u)))
        elif name == 'darumaface':             # the daruma's white face
            reg = bm & (sfield(c, [(fx, fy + 1 * u, g.half_w(fy) * .62, 7.2 * u)]) > 1)
        elif name == 'lanternbands':           # paper lantern: dark top and bottom caps
            reg = bm & ((c.y < g.top + g.h * .12) | (c.y > g.bot - g.h * .1))
        elif name == 'ribs':                   # paper lantern ribs
            reg = bm & (np.abs(np.sin((c.y - g.top) * 1.3 / u)) > .94) & (c.y > g.top + g.h * .12) & (c.y < g.bot - g.h * .1)
        elif name == 'leafveins':
            reg = bm & ((np.abs(c.x - cx) < .5 * u) | (np.abs(np.abs(c.x - cx) - (g.bot - c.y) * .4 + 2 * u) < .45 * u)) & (c.y < g.bot - 2 * u) & (c.y > g.top + 2 * u)
        if reg is not None and name in ('ribs', 'leafveins', 'grid', 'clamridges'):
            paint(c, reg, np.array(tone(fp, 1), np.float32))
            reg = None
        if reg is not None:
            material(c, bh * 1.03, reg, fp, bump=4, spec_amt=.5, spec_pow=22, grain=.06)
            seam(c, reg, bm & ~reg, .45)
            rmask[name] = reg
        if name == 'warts':                   # Picklet's pickle bumps
            warts = []
            for _ in range(int(9 * s)):
                x, y = rr.uniform(g.l + 3, g.r - 3), rr.uniform(g.top + 3, g.bot - 1)
                if bf[min(int(y * K * F), H * K - 1), min(int(x * K * F), W * K - 1)] > 1.5 and not (abs(y - fy) < 5 and abs(x - fx) < g.half_w(fy) * .7):
                    warts.append((x, y, 1.5 * s ** .5, 1.5 * s ** .5, 2, .25))
            if warts:
                wf = sfield(c, warts)
                material(c, np.clip(bh + height(wf, .5) * .4, 0, 1.3), bm & (wf > .9), colr(tok, pal), bump=6, spec_amt=.3, grain=.08)
        elif name == 'crust':                 # fried: a bumpy golden crust (smooth around the face)
            micro = []
            while len(micro) < int(46 * s):
                x, y = rr.uniform(g.l, g.r), rr.uniform(g.top, g.bot)
                if abs(y - fy - 1.5 * u) < 6 * u and abs(x - fx) < g.half_w(fy) * .62:
                    continue
                micro.append((x, y, 2.3 * u, 2.1 * u, 2, .2))
            mf = sfield(c, micro)
            reg = bm & ~rmask.get('drip', np.zeros_like(bm)) & ~rmask.get('glaze', np.zeros_like(bm))
            material(c, np.clip(bh * .94 + height(mf, .5) * .11, 0, 1.2), reg, colr(tok, pal), bump=4, spec_amt=.32, spec_pow=18, grain=.07)
        elif name == 'scales':
            reg2 = bm & (np.abs(np.sin((c.x - cx) / (2.2 * u) + np.floor((c.y - g.top) / (3.4 * u)) * 1.57)) > .93) & (c.y > fy + 4 * u)
            paint(c, reg2, np.array(tone(colr(tok, pal), 1), np.float32))
        elif name == 'facets':                # a cut gem: stepped shading
            steps = np.floor(bh * 4) / 4
            material(c, np.clip(steps + .1, 0, 1), bm, colr(tok, pal), bump=9, spec_amt=.9, spec_pow=8, grain=.02)
        elif name == 'glaze':
            reg = bm & (c.y < g.top + g.h * .5 + 1.5 * u * np.sin(c.x * .45))
            material(c, bh * 1.04, reg, colr(tok, acc), bump=3, spec_amt=.9, spec_pow=10, grain=.03)
            seam(c, reg, bm & ~reg, .4)
        elif name in ('sugar', 'seeds', 'sesame'):
            pass

    # ---------------------------------------------------------- front parts
    for f_, p_, kw in front:
        m = f_ > 1
        if kw.get('glow'):
            material(c, np.clip(height(f_, .5) * .6 + .5, 0, 1), m, p_, bump=2, spec_amt=.6, spec_pow=10, grain=.02, ao=0)
            continue
        material(c, height(f_, .5), m, p_, bump=4, spec_amt=.4, spec_pow=22, grain=.06)
        seam(c, m, (c.a > .5) & ~m, .45)
        if kw.get('nostrils'):
            def nos(d, f_=f_):
                for sd in (-1, 1):
                    x = fx + sd * 1.1 * u; y = fy + 3.4 * u
                    d.ellipse([*c.P(x - .6 * u, y - .7 * u), *c.P(x + .6 * u, y + .7 * u)], fill=INK)
            deferred.append(('call', nos, 0))
    for kind, tok, sc in deferred:
        if kind == 'flame':
            k_ = s * .85 * sc
            top = tt + 2.5 * u
            fl = [(cxp, top - 2.5 * k_, 4.2 * k_, 7 * k_), (cxp - 4.6 * k_, top - .2 * k_, 3 * k_, 5 * k_), (cxp + 4.8 * k_, top - .4 * k_, 3.2 * k_, 5.2 * k_)]
            f_ = sfield(c, fl)
            m = (f_ > 1) & (c.a < .5)
            material(c, np.clip(1.0 - (c.y - (top - 9 * k_)) / (12 * k_), 0, 1), m, colr(tok, P['flame']), bump=2, spec_amt=.1, grain=.05, ao=0)
        elif kind == 'cherry':
            r = 3.4 * u
            cf = sfield(c, [(cxp + 1 * u, tt - r * .7, r, r)])
            m = (cf > 1)
            material(c, height(cf, .5), m, colr(tok, P['berry']), bump=4, spec_amt=.8, grain=.04)
            lines.append(((cxp + 1.5 * u, tt - r * 1.4), (cxp + 4 * u, tt - r * 3), 1.0 * u ** .5, (80, 56, 30)))
        elif kind == 'flower':
            def fl_(d, tok=tok):
                pc = tone(colr(tok, P['pink']), 3); cc = (250, 214, 80)
                x, y = cxp + 6 * u, tt + 2 * u
                r = 1.9 * u
                for k in range(5):
                    a = k * 2 * math.pi / 5
                    d.ellipse([*c.P(x + math.cos(a) * r - r * .85, y + math.sin(a) * r - r * .85), *c.P(x + math.cos(a) * r + r * .85, y + math.sin(a) * r + r * .85)], fill=pc)
                d.ellipse([*c.P(x - r * .6, y - r * .6), *c.P(x + r * .6, y + r * .6)], fill=cc)
            deferred.append(('call', fl_, 0))
        elif kind == 'crown':
            pass

    def ln(d):
        for p0, p1, w_, colr_ in lines:
            d.line([c.P(*p0), c.P((p0[0] + p1[0]) / 2 + .6, (p0[1] + p1[1]) / 2), c.P(*p1)], fill=colr_, width=max(2, int(w_ * K * F)), joint='curve')
    draw_on(c, ln)
    outline(c, c.a > .5, 1.0)
    outline(c, c.a > .5, 1.0)                 # twice: the solid 2 px line of Picklet

    # ---------------------------------------------------------- painted over (after the outline)
    def deco(d):
        P_ = c.P
        for kind, fn_, _ in deferred:
            if kind == 'call':
                fn_(d)
        for name, fp_ in [(n, fp) for n, fp, _ in regions] + over:
            dk = tone(fp_, 1); lt = tone(fp_, 4)
            if name in ('sprinkles', 'sugar', 'seeds', 'sesame', 'crumbs'):
                rr2 = np.random.default_rng(len(name) * 7 + int(g.w))
                n = {'sprinkles': 14, 'sugar': 22, 'seeds': 16, 'sesame': 12, 'crumbs': 9}[name]
                cols = {'sprinkles': [(255, 250, 220), (100, 185, 235), (250, 120, 150), (255, 205, 60), (160, 110, 225)],
                        'sugar': [(255, 255, 255), (230, 240, 255)], 'seeds': [lt], 'sesame': [(250, 240, 210)], 'crumbs': [dk, tone(fp_, 2)]}[name]
                lim_y = g.top + g.h * (.45 if name == 'sprinkles' else .95)
                placed = 0; tries = 0
                while placed < n * s / 1.3 and tries < 600:
                    tries += 1
                    x, y = rr2.uniform(g.l + 2, g.r - 2), rr2.uniform(g.top + 2, lim_y)
                    if not g.inside(x, y) or (abs(y - fy) < 5.5 * u and abs(x - fx) < g.half_w(fy) * .72):
                        continue
                    col = cols[rr2.integers(len(cols))]
                    if name in ('sprinkles', 'sesame', 'seeds'):
                        t = rr2.uniform(0, math.pi)
                        dx, dy = math.cos(t) * .9 * u, math.sin(t) * .9 * u
                        d.line([P_(x - dx, y - dy), P_(x + dx, y + dy)], fill=col, width=wd(c, .9 * u))
                    else:
                        r = (.45 if name == 'sugar' else .7) * u
                        d.ellipse([*P_(x - r, y - r), *P_(x + r, y + r)], fill=col)
                    placed += 1
            elif name == 'freckles_b':
                pass
            elif name == 'crack':
                y = g.top + g.h * .2; x = cxp + g.w * .2
                d.line([P_(x, y), P_(x - 2 * u, y + 3 * u), P_(x + 1 * u, y + 5 * u), P_(x - 1 * u, y + 8 * u)], fill=INK, width=wd(c, .9))
            elif name == 'bolts':
                y = fy + 4 * u
                for sd in (-1, 1):
                    x = cxp + sd * (g.half_w(y) - .5)
                    d.ellipse([*P_(x - 1.6 * u, y - 1.6 * u), *P_(x + 1.6 * u, y + 1.6 * u)], fill=(200, 208, 222), outline=INK, width=wd(c, .5))
            elif name == 'chip':
                y = g.top + g.h * .26; r = 3 * u
                d.rectangle([*P_(cxp - r, y - r * .8), *P_(cxp + r, y + r * .8)], fill=(40, 46, 56), outline=INK, width=wd(c, .5))
                for i in (-1, 0, 1):
                    for sgn in (-1, 1):
                        d.line([P_(cxp + i * r * .55, y + sgn * r * .8), P_(cxp + i * r * .55, y + sgn * r * 1.3)], fill=(220, 190, 80), width=wd(c, .6))
                d.rectangle([*P_(cxp - r * .4, y - r * .3), *P_(cxp + r * .4, y + r * .3)], fill=(90, 220, 200))
            elif name == 'bubbles':
                for (dx, dy, r) in ((-1.0, -.2, 1.8), (-1.15, -.55, 1.1), (1.05, -.4, 1.4), (1.2, -.75, .9)):
                    x = cxp + dx * g.w * .55; y = g.top + g.h * .5 + dy * g.h
                    d.ellipse([*P_(x - r * u, y - r * u), *P_(x + r * u, y + r * u)], fill=(255, 255, 255, 110), outline=dk, width=wd(c, .5))
            elif name in ('steam', 'smoke'):
                col = (214, 214, 222) if name == 'steam' else (120, 116, 124)
                for dx in (-5, 0, 5):
                    x = cxp + dx * u; t = g.top_at(x) - 3
                    d.line([P_(x, t), P_(x + 1.2, t - 2), P_(x - 1.2, t - 4), P_(x, t - 6)], fill=col, width=wd(c, .9), joint='curve')
            elif name == 'sparkles':
                for (x, y, r) in ((g.l - 2, g.top + 4, 2.6), (g.r + 2, g.top + 10, 2.0), (g.r, g.bot - 6, 1.5)):
                    d.polygon([P_(x, y - r), P_(x + r * .3, y - r * .3), P_(x + r, y), P_(x + r * .3, y + r * .3), P_(x, y + r),
                               P_(x - r * .3, y + r * .3), P_(x - r, y), P_(x - r * .3, y - r * .3)], fill=(255, 236, 140))
            elif name == 'embers':
                for (x, y, r) in ((g.l - 1, g.top + 6, 1.1), (g.r + 1, g.top + 3, 1.3), (g.r - 2, g.top - 3, .9)):
                    d.ellipse([*P_(x - r, y - r), *P_(x + r, y + r)], fill=(255, 170, 60))
            elif name == 'drop':
                x = g.r - 3; y = g.top + g.h * .3
                d.polygon([P_(x, y - 2.8 * u), P_(x + 1.6 * u, y), P_(x - 1.6 * u, y)], fill=(150, 205, 250))
                d.ellipse([*P_(x - 1.6 * u, y - 1.4 * u), *P_(x + 1.6 * u, y + 1.8 * u)], fill=(150, 205, 250))
            elif name == 'gem':
                y = g.top + g.h * .25
                d.polygon([P_(cxp, y - 3 * u), P_(cxp + 2.4 * u, y), P_(cxp, y + 3 * u), P_(cxp - 2.4 * u, y)], fill=tone(fp_, 3), outline=INK)
            elif name == 'stars':
                rr3 = np.random.default_rng(6)
                for _ in range(12):
                    x, y = rr3.uniform(g.l + 3, g.r - 3), rr3.uniform(g.top + 2, g.bot - 2)
                    if not g.inside(x, y) or (abs(y - fy) < 6 * u and abs(x - fx) < g.half_w(fy) * .7):
                        continue
                    r = rr3.uniform(.6, 1.1)
                    d.polygon([P_(x, y - r * 1.8), P_(x + r * .5, y), P_(x, y + r * 1.8), P_(x - r * .5, y)], fill=(255, 250, 220))
                    d.polygon([P_(x - r * 1.8, y), P_(x, y + r * .5), P_(x + r * 1.8, y), P_(x, y - r * .5)], fill=(255, 250, 220))
            elif name == 'crown':
                cx_, y = cxp, tt - .5
                w_, h_ = 7.5 * s * .8, 6.5 * s * .8
                pts = [(cx_ - w_, y), (cx_ - w_, y - h_ * .6), (cx_ - w_ * .5, y - h_ * .25), (cx_, y - h_), (cx_ + w_ * .5, y - h_ * .25), (cx_ + w_, y - h_ * .6), (cx_ + w_, y)]
                d.polygon([P_(*p) for p in pts], fill=(240, 196, 60), outline=INK)
                for p in [(cx_, y - h_ * .55), (cx_ - w_ * .55, y - h_ * .35), (cx_ + w_ * .55, y - h_ * .35)]:
                    d.ellipse([*P_(p[0] - .9, p[1] - .9), *P_(p[0] + .9, p[1] + .9)], fill=(214, 60, 90))
            elif name == 'halo':
                w_, h_ = 9 * s * .55, 2.4 * s * .55
                y = g.top - 6 * s * .55
                d.ellipse([*P_(cxp - w_, y - h_), *P_(cxp + w_, y + h_)], outline=(250, 214, 80), width=wd(c, 1.4 * s ** .5))
            elif name == 'bandage':
                x, y = cxp + 8 * u, g.top + g.h * .25
                L_, Wd_ = 3.4 * u, 1.3 * u
                for ang in (.6, -.6):
                    dx, dy = math.cos(ang) * L_, math.sin(ang) * L_
                    nx, ny = -math.sin(ang) * Wd_, math.cos(ang) * Wd_
                    poly = [(x - dx - nx, y - dy - ny), (x + dx - nx, y + dy - ny), (x + dx + nx, y + dy + ny), (x - dx + nx, y - dy + ny)]
                    d.polygon([P_(*p) for p in poly], fill=(250, 226, 196), outline=INK)
            elif name == 'zzz':
                x, y = g.r + 1, g.top + 2
                for i, r in enumerate((1.6, 2.2)):
                    xx, yy = x + i * 3 * u, y - i * 3.5 * u
                    d.line([P_(xx - r * u, yy - r * u), P_(xx + r * u, yy - r * u), P_(xx - r * u, yy + r * u), P_(xx + r * u, yy + r * u)], fill=(90, 90, 120), width=wd(c, .8))
            elif name == 'notes':
                x, y = g.r + 1, g.top + 4
                d.ellipse([*P_(x - 1.4 * u, y), *P_(x + 1.4 * u, y + 2 * u)], fill=INK)
                d.line([P_(x + 1.2 * u, y + 1 * u), P_(x + 1.2 * u, y - 5 * u), P_(x + 3.5 * u, y - 4 * u)], fill=INK, width=wd(c, .7))
            elif name == 'heart':
                x, y = g.r, g.top + 3
                r = 1.5 * u
                d.ellipse([*P_(x - 2 * r, y - r), *P_(x, y + r)], fill=(240, 90, 120))
                d.ellipse([*P_(x, y - r), *P_(x + 2 * r, y + r)], fill=(240, 90, 120))
                d.polygon([P_(x - 2 * r, y), P_(x + 2 * r, y), P_(x, y + 2.6 * r)], fill=(240, 90, 120))
            elif name == 'mark':                  # a forehead mark (a bindi / gem dot)
                y = fy - 7 * u
                d.ellipse([*P_(fx - 1.3 * u, y - 1.3 * u), *P_(fx + 1.3 * u, y + 1.3 * u)], fill=tone(fp_, 3), outline=INK)
            elif name == 'rune':
                y = fy - 8 * u
                d.line([P_(fx - 2 * u, y + 2 * u), P_(fx, y - 2 * u), P_(fx + 2 * u, y + 2 * u)], fill=tone(fp_, 4), width=wd(c, .9))
            elif name == 'lightning':
                x, y = g.r + 2, g.top + 4
                d.polygon([P_(x, y - 4 * u), P_(x - 2 * u, y + .5 * u), P_(x, y + .3 * u), P_(x - 1 * u, y + 4 * u), P_(x + 2.2 * u, y - 1 * u), P_(x, y - .8 * u)], fill=(255, 220, 60), outline=INK)
            elif name == 'snow':
                rr4 = np.random.default_rng(4)
                for _ in range(8):
                    x, y = rr4.uniform(g.l - 4, g.r + 4), rr4.uniform(g.top - 6, g.bot)
                    if g.inside(x, y):
                        continue
                    d.ellipse([*P_(x - .8, y - .8), *P_(x + .8, y + .8)], fill=(250, 252, 255))
            elif name == 'whiskers':
                for sd in (-1, 1):
                    for k_, dy in enumerate((-.6, .9)):
                        x0 = fx + sd * (g.half_w(fy) * .55); y0 = fy + 3.5 * u + dy * u
                        d.line([P_(x0, y0), P_(x0 + sd * 5 * u, y0 + dy * 1.4 * u)], fill=tone(pal, 0), width=wd(c, .6))
            elif name == 'hachimaki':          # a headband with a knot
                y = fy - 6.2 * u
                hw_ = g.half_w(y)
                d.line([P_(fx - hw_ + .5, y), P_(fx + hw_ - .5, y)], fill=(250, 250, 250), width=wd(c, 2.4 * u))
                d.line([P_(fx - hw_ + .5, y - 1.0 * u), P_(fx + hw_ - .5, y - 1.0 * u)], fill=INK, width=wd(c, .4))
                d.ellipse([*P_(fx + hw_ - 1.5 * u, y - 1.3 * u), *P_(fx + hw_ + 1.3 * u, y + 1.3 * u)], fill=(250, 250, 250), outline=INK)
                d.line([P_(fx + hw_ + 1 * u, y), P_(fx + hw_ + 4 * u, y + 2.5 * u)], fill=(250, 250, 250), width=wd(c, 1.2 * u))
            elif name == 'kanji':              # a little mark on the belly (luck)
                x, y = cxp, g.bot - g.h * .25
                d.ellipse([*P_(x - 3 * u, y - 3 * u), *P_(x + 3 * u, y + 3 * u)], fill=(250, 214, 80), outline=INK)
                d.line([P_(x - 1.6 * u, y - .6 * u), P_(x + 1.6 * u, y - .6 * u)], fill=INK, width=wd(c, .6))
                d.line([P_(x, y - 1.8 * u), P_(x, y + 1.8 * u)], fill=INK, width=wd(c, .6))
            elif name == 'capspots':           # dots on a mushroom cap
                for (dx, dy) in ((-7, -1), (0, -3.5), (7, -1), (-3, 1.5), (4, 1.2)):
                    x, y = cxp + dx * u, g.top + g.h * .14 + dy * u
                    d.ellipse([*P_(x - 1.4 * u, y - 1.2 * u), *P_(x + 1.4 * u, y + 1.2 * u)], fill=(252, 250, 244))
            elif name == 'pleats':
                for i in range(-3, 4):
                    x = cxp + i * g.w * .1
                    t = g.top_at(x)
                    d.line([P_(x, t + .8), P_(x + i * .5 * u, t + 3.2 * u)], fill=tone(pal, 1), width=wd(c, .7))
            elif name == 'swirltop':             # a nikuman's twist on top
                x, y = cxp, g.top + 1.5 * u
                pts = [P_(x + math.cos(t) * t * .55 * u, y + 1.5 * u + math.sin(t) * t * .35 * u) for t in np.linspace(0, 11, 30)]
                d.line(pts, fill=tone(pal, 0), width=wd(c, .9))
            elif name == 'monocle':
                x = fx + 0; y = fy
            elif name == 'glow':
                pass
            elif name == 'leafpin':
                x, y = cxp - g.half_w(g.top + g.h * .3) * .55, g.top + g.h * .28
                d.polygon([P_(x - 2.5 * u, y + 1 * u), P_(x, y - 2.5 * u), P_(x + 2.5 * u, y + 1 * u), P_(x, y + 2 * u)], fill=tone(P['leaf'], 3), outline=INK)
            elif name == 'sticker':
                x, y = cxp + g.half_w(g.bot - g.h * .3) * .5, g.bot - g.h * .3
                d.ellipse([*P_(x - 2.4 * u, y - 2.4 * u), *P_(x + 2.4 * u, y + 2.4 * u)], fill=(255, 250, 236), outline=INK)
                d.ellipse([*P_(x - 1.2 * u, y - 1.2 * u), *P_(x + 1.2 * u, y + 1.2 * u)], fill=tone(fp_, 2))
    draw_on(c, deco)
    face(c, g, fx, fy, spec.get('eyes', 'gloss'), spec.get('mouth', 'flat'), spec.get('extras', []), stage,
         pal if not plan.get('tiers') else pal, fs=mods.get('fs', plan.get('fs', 1.0)),
         fhw=plan['fhw'] * s if plan.get('fhw') else None)
    # mind the screen: nothing may leave the canvas (the game shows exactly this 110 x 100 box).
    # Hanging below -> lift it; too tall or too wide -> shrink it; then draw again.
    ys, xs = np.nonzero(c.a > .5)
    kk = c.k * c.f
    top, bot = ys.min() / kk, (ys.max() + 1) / kk
    left, right = xs.min() / kk, (xs.max() + 1) / kk
    if _pass < 4:
        lift = max(0.0, bot - 98.0)
        top_after = top - lift
        shrinkf = 1.0
        if top_after < 2.0:
            shrinkf = min(shrinkf, (98.0 - 2.5) / max(bot - top, 1))
        if left < 1.5 or right > 108.5:
            shrinkf = min(shrinkf, 105.0 / max(right - left, 1))
        if lift > .25 or shrinkf < .995:
            return render(spec, stage, seed_name, _lift + lift, _fit * min(1.0, shrinkf * .985), _pass + 1)
    _, small = shrink(c)
    return small.resize((W * 2, H * 2), Image.NEAREST)


# ------------------------------------------------------------------ the three babies we keep
def special(name):
    import forms_gen as fg
    if name == 'picklet':                       # kept exactly as it is in the game
        return Image.open(PROJ + '/textures/pet/forms/picklet-1.png').convert('RGBA').crop((60, 60, 170, 160))
    if name.startswith('ember'):                # Ember's own body + stem, calmer face (option A: glossy, no grin)
        c = Canvas(W, H, K, F, anchor=(55, GROUND))
        f, m, top, fy = fg.body(c, 'H', 1.3)
        fg.stem(c, 57.5, top + .5, 1.3)
        outline(c, c.a > .5, 1.0)
        outline(c, c.a > .5, 1.0)
        g = Geo(c, m)
        style = name.partition(':')[2] or 'gloss'
        face(c, g, 55, fy, style, 'flat', [], 'baby', P['spicy'])
        _, small = shrink(c)
        return small.resize((W * 2, H * 2), Image.NEAREST)
    raise KeyError(name)


# ------------------------------------------------------------------ spec lines
def parse(line):
    """'Name | plan k=v | pal/acc/acc2 | parts | eyes mouth extras | note' -> (name, spec, note)"""
    f = [x.strip() for x in line.split('|')]
    name, plan, pal, parts, fc, note = (f + [''] * 6)[:6]
    if plan.startswith('='):
        return name, {'special': plan[1:]}, note
    pw = plan.split()
    mods = {}
    for kv in pw[1:]:
        k_, _, v = kv.partition('=')
        mods[k_] = float(v)
    pals = pal.split('/')
    spec = {'plan': pw[0], 'mods': mods, 'pal': pals[0], 'acc': pals[1] if len(pals) > 1 else None,
            'acc2': pals[2] if len(pals) > 2 else None, 'parts': [], 'eyes': 'gloss', 'mouth': 'flat', 'extras': []}
    for t in parts.split():
        n, _, tok = t.partition(':')
        spec['parts'].append((n, tok or None))
    fw = fc.split()
    if fw:
        spec['eyes'] = fw[0]
    if len(fw) > 1:
        spec['mouth'] = fw[1]
    spec['extras'] = fw[2:]
    return name, spec, note
