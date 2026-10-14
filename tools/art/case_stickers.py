"""Case stickers and the sticker book (CASE mode: stuck on the case's back, see case_stickers.gd).

Painted big and shrunk to art size (the soft look of the console's art), then x4 nearest, the
console's own pixel size, so a sticker sits on the same grid as the case's dots and edges.
A sticker: its art, (a dark warm outline,) then the white die-cut border. The stickers are pals
(their game sprites, x2 like in the game); star() / heart() / onigiri() / strawberry() are kept
for other sticker sets.

    <venv>/bin/python tools/art/case_stickers.py
        -> textures/cases/stickers/<pal id>.png   every Sho and Chu, stuck size (x3 the pal's pixels)
           textures/cases/stickers/book/<id>.png   ...and as the book shows them (x2)
           textures/cases/book/book.png           the open book (page + cover + its pull tab)
           textures/cases/book/tab_<family>.png   the page tabs on its top
"""
import json
import os
import numpy as np
from PIL import Image
from scipy.ndimage import binary_dilation, gaussian_filter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
DEST = os.path.join(ROOT, 'textures', 'cases', 'stickers')
PX = 4                      # screen px per art px (the console's)
HI = 8                      # painted this many times bigger than the art
INK = np.array([62, 40, 36])
WHITE = np.array([255, 252, 246])
EDGE = np.array([214, 206, 196])     # the die-cut's thin edge (reads on a light case too)
BLUSH = np.array([240, 130, 140])


def grid(n):
    """Hi-res coordinates (-1..1) for an art canvas n px square."""
    v = (np.arange(n * HI) + 0.5) / (n * HI) * 2 - 1
    return np.meshgrid(v, v)


def shade(mask, col, light=0.22, dark=0.28):
    """Soft 3D shading on a shape: light from the top-left, a darker rim bottom-right."""
    m = gaussian_filter(mask.astype(float), mask.shape[0] / 14)
    gy, gx = np.gradient(m)
    k = -(gx + gy) * mask.shape[0] / 3
    k = np.clip(k, -1, 1)
    c = np.asarray(col, float)[None, None] * np.ones(mask.shape + (3,))
    c = np.where(k[..., None] > 0, c + (255 - c) * k[..., None] * light, c * (1 + k[..., None] * dark))
    rgba = np.zeros(mask.shape + (4,))
    rgba[..., :3] = c
    rgba[..., 3] = mask * 255
    return rgba


def put(rgba, mask, col):
    rgba[mask, :3] = col
    rgba[mask, 3] = 255


def face(rgba, x, y, s, n):
    """Two dot eyes with a gleam, blush, a small smile (hi-res units: -1..1 around the canvas)."""
    X, Y = grid(n)
    for ex in (-s, s):
        put(rgba, (X - x - ex) ** 2 + (Y - y) ** 2 < (0.09 * s / 0.22) ** 2, INK)
        put(rgba, (X - x - ex + 0.03) ** 2 + (Y - y + 0.035) ** 2 < 0.03 ** 2, WHITE)
        put(rgba, ((X - x - ex * 1.55) / 1.6) ** 2 + (Y - y - 0.14) ** 2 < 0.05 ** 2, BLUSH)
    r = np.hypot(X - x, Y - y - 0.06)
    put(rgba, (np.abs(r - 0.08) < 0.022) & (Y > y + 0.08), INK)


def star(n=34):
    X, Y = grid(n)
    a = np.arctan2(X, -Y)
    r = np.hypot(X, Y + 0.06)
    edge = 0.52 + 0.4 * (np.cos(a * 5) * 0.5 + 0.5) ** 1.6
    m = r < edge * 0.98
    m = gaussian_filter(m.astype(float), n * HI / 60) > 0.5          # (round tips)
    rgba = shade(m, (252, 206, 72))
    face(rgba, 0, 0.02, 0.2, n)
    return rgba


def heart(n=32):
    X, Y = grid(n)
    x, y = X * 1.25, -(Y * 1.25 - 0.15)
    m = (x ** 2 + y ** 2 - 1) ** 3 - x ** 2 * y ** 3 < 0
    rgba = shade(m, (240, 96, 120))
    face(rgba, 0, -0.08, 0.22, n)
    return rgba


def onigiri(n=34):
    X, Y = grid(n)
    # a rounded triangle: three half-planes, then softened
    corners = [(0, -0.82), (-0.9, 0.78), (0.9, 0.78)]
    tri = np.ones_like(X, bool)
    for i in range(3):
        (x1, y1), (x2, y2) = corners[i], corners[(i + 1) % 3]
        nx, ny = y2 - y1, -(x2 - x1)
        tri &= (X - x1) * nx + (Y - y1) * ny >= 0
    m = gaussian_filter(tri.astype(float), n * HI / 12) > 0.5
    rgba = shade(m, (250, 248, 240), light=0.1, dark=0.18)
    nori = m & (np.abs(X) < 0.34) & (Y > 0.36)
    rgba[nori, :3] = shade(nori, (44, 60, 52))[nori, :3]
    face(rgba, 0, 0.06, 0.2, n)
    return rgba


def strawberry(n=34):
    X, Y = grid(n)
    x, y = X, Y - 0.08
    w = 0.78 - 0.5 * np.clip(y, 0, 1) ** 1.2
    m = (x / np.maximum(w, 0.05)) ** 2 + ((y + 0.05) / 0.82) ** 2 < 1
    m = gaussian_filter(m.astype(float), n * HI / 50) > 0.5
    rgba = shade(m, (232, 64, 72))
    for sx, sy in [(-0.45, -0.1), (0.42, -0.12), (-0.18, 0.32), (0.22, 0.34), (0, 0.6), (-0.5, 0.22), (0.5, 0.2)]:
        put(rgba, m & ((X - sx) ** 2 / 0.5 + (Y - sy) ** 2 < 0.035 ** 2), (252, 222, 120))
    leaf = np.zeros_like(m)
    for la in (-0.9, -0.3, 0.3, 0.9):
        cx, cy = np.sin(la) * 0.34, -0.66 - np.cos(la) * 0.12
        leaf |= ((X - cx) * np.cos(la) + (Y - cy) * np.sin(la)) ** 2 / 0.12 ** 2 + \
                ((Y - cy) * np.cos(la) - (X - cx) * np.sin(la)) ** 2 / 0.3 ** 2 < 1
    leaf &= Y < -0.5
    lg = shade(leaf, (96, 176, 84))
    rgba[leaf] = lg[leaf]
    face(rgba, 0, 0.0, 0.2, n)
    return rgba


def to_art(rgba, n):
    """Hi-res -> art size (soft), alpha cut."""
    im = Image.fromarray(np.clip(rgba, 0, 255).astype(np.uint8), 'RGBA').resize((n, n), Image.LANCZOS)
    a = np.asarray(im).astype(int)
    a[..., 3] = np.where(a[..., 3] > 110, 255, 0)
    return a


def pal(fid):
    im = np.asarray(Image.open(os.path.join(ROOT, 'textures', 'pet', 'forms', fid + '-1.png')).convert('RGBA')).astype(int)
    ys, xs = np.nonzero(im[..., 3] > 0)
    return im[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def sticker(art, outline=True, px=PX):
    """Art -> a die-cut sticker: (outline), white border, a thin edge; then x PX."""
    pad = 5
    h, w = art.shape[:2]
    a = np.zeros((h + pad * 2, w + pad * 2, 4), int)
    a[pad:pad + h, pad:pad + w] = art
    body = a[..., 3] > 0
    out = a.copy()
    if outline:
        ring = binary_dilation(body) & ~body
        out[ring, :3], out[ring, 3] = INK, 255
        body = body | ring
    white = binary_dilation(body, iterations=2) & ~body
    out[white, :3], out[white, 3] = WHITE, 255
    edge = binary_dilation(body | white) & ~(body | white)
    out[edge, :3], out[edge, 3] = EDGE, 255
    im = Image.fromarray(out.astype(np.uint8), 'RGBA')
    bb = im.getbbox()
    im = im.crop(bb)
    return im.resize((im.width * px, im.height * px), Image.NEAREST)


FAMILIES = ['green', 'sweet', 'greasy', 'spicy', 'sour']
FAM_COL = {'green': (128, 198, 104), 'sweet': (244, 162, 192), 'greasy': (232, 176, 98),
           'spicy': (232, 98, 82), 'sour': (238, 214, 92)}
COVER = np.array([176, 166, 152])          # the book's cover: a neutral warm grey (goes with any case)
PAGE = np.array([252, 249, 242])
BOOK = os.path.join(ROOT, 'textures', 'cases', 'book')


def rrect(xx, yy, x0, y0, x1, y1, r):
    cx = np.clip(xx, x0 + r, x1 - r)
    cy = np.clip(yy, y0 + r, y1 - r)
    return (xx - cx) ** 2 + (yy - cy) ** 2 <= r * r


OUT = 2                                    # the book's outline, art px


def outlined(a, shp, col):
    """Art (h, w, 4) with its shape outlined OUT art px (the canvas grows by OUT all round), x PX."""
    full = np.zeros((a.shape[0] + OUT * 2, a.shape[1] + OUT * 2, 4), int)
    full[OUT:-OUT, OUT:-OUT] = a
    ring = binary_dilation(np.pad(shp, OUT), iterations=OUT) & ~np.pad(shp, OUT)
    full[ring, :3], full[ring, 3] = col, 255
    im = Image.fromarray(full.astype(np.uint8), 'RGBA')
    return im.resize((im.width * PX, im.height * PX), Image.NEAREST)


def icon(fid, n):
    """A pal shrunk to n art px (soft), for the tabs."""
    im = Image.fromarray(pal(fid).astype(np.uint8), 'RGBA')
    k = n / max(im.size)
    im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
    a = np.asarray(im).astype(int)
    a[..., 3] = np.where(a[..., 3] > 110, 255, 0)
    return a


def paste(a, art, x, y):
    m = art[..., 3] > 0
    a[y:y + art.shape[0], x:x + art.shape[1]][m] = art[m]


def book(mark):
    """The open book: a lilac cover round a sheet of sticker paper, its spine on the left and a
    pull tab on its right (the part that peeks in at the case's left edge)."""
    W, H, TW, TH = 150, 222, 22, 70
    yy, xx = np.mgrid[0:H, 0:W + TW]
    a = np.zeros((H, W + TW, 4), int)
    cover = rrect(xx, yy, 0, 0, W - 1, H - 1, 6)
    ty0 = (H - TH) // 2
    tab = rrect(xx, yy, W - 10, ty0, W + TW - 1, ty0 + TH - 1, 6)
    shp = cover | tab
    k = ((1 - xx / (W + TW)) * 0.5 + (1 - yy / H) * 0.5 - 0.5)
    a[shp, :3] = np.clip(COVER + k[shp, None] * 36, 0, 255)
    a[shp, 3] = 255
    spine = cover & (xx < 8)
    a[spine, :3] = COVER * 0.82
    a[cover & (xx == 8), :3] = COVER * 0.7
    page = rrect(xx, yy, 12, 6, W - 7, H - 7, 3)
    a[page, :3] = PAGE
    a[page & (yy == H - 8), :3] = PAGE * 0.92                    # (the page's thickness)
    a[page & (xx == 12), :3] = PAGE * 0.9
    paste(a, mark, W + TW - 4 - mark.shape[1], ty0 + (TH - mark.shape[0]) // 2)
    return outlined(a, shp, INK + 20), (W, H, ty0, TH, 12, 6, W - 7, H - 7)


def page_tab(fam, mark):
    """A page tab: a rounded top in the family's colour, its Sho on it."""
    W, H = 24, 18
    yy, xx = np.mgrid[0:H, 0:W]
    a = np.zeros((H, W, 4), int)
    shp = rrect(xx, yy, 0, 0, W - 1, H + 6, 6)
    col = np.array(FAM_COL[fam])
    k = (1 - yy / H) * 0.5 - 0.25
    a[shp, :3] = np.clip(col + k[shp, None] * 50, 0, 255)
    a[shp, 3] = 255
    paste(a, mark, (W - mark.shape[1]) // 2, 2)
    return outlined(a, shp, INK + 20)


if __name__ == '__main__':
    os.makedirs(DEST, exist_ok=True)
    os.makedirs(BOOK, exist_ok=True)
    forms = json.load(open(os.path.join(ROOT, 'data', 'evolution_tree.json')))['forms']
    ids = [k for k, v in forms.items() if v['stage'] <= 2]
    os.makedirs(os.path.join(DEST, 'book'), exist_ok=True)
    for d in (DEST, os.path.join(DEST, 'book')):
        for f in os.listdir(d):
            if f.endswith('.png') and f[:-4] not in ids:
                os.remove(os.path.join(d, f))
    for fid in ids:
        # (the pal sprites are drawn finer than the console: whole multiples of their own pixels)
        sticker(pal(fid), outline=False, px=3).save(os.path.join(DEST, fid + '.png'))
        sticker(pal(fid), outline=False, px=2).save(os.path.join(DEST, 'book', fid + '.png'))
    starters = json.load(open(os.path.join(ROOT, 'data', 'evolution_tree.json')))['starters']
    im, geo = book(icon('picklet', 16))
    im.save(os.path.join(BOOK, 'book.png'))
    for fam in FAMILIES:
        page_tab(fam, icon(starters[fam], 14)).save(os.path.join(BOOK, 'tab_%s.png' % fam))
    sizes = [Image.open(os.path.join(DEST, f + '.png')).size for f in ids]
    print(len(ids), 'stickers, biggest', max(s[0] for s in sizes), max(s[1] for s in sizes))
    print('book', im.size, 'geometry (art px, before the outline)', geo)
