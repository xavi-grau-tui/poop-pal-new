"""Paints the HaraTomo logo (textures/console/logo2.png) in the style of the Poop Pal one
(textures/console/logomain.png): reuses its small "a" and "o" and its 便友 kanji, and draws
H, T, r and m by the same rules (4 px outline plus a shadow 3 px right / 2 px down, cream
highlights top-left, a shaded bottom band, cream inside the holes).

    <python with Pillow + numpy> tools/design/haratomo_logo.py"""
import numpy as np
from collections import deque
from PIL import Image

from pathlib import Path

ROOT = str(Path(__file__).resolve().parents[2]) + "/"
DARK, SH, TAN, LT, WH = (65, 46, 33), (156, 124, 92), (209, 171, 124), (224, 191, 144), (244, 227, 197)
orig = Image.open(ROOT + "textures/console/logomain.png").convert("RGBA")
PAD = 9
SMALL_H = 42          # small letters' bodies end 2 rows below the capitals', as in the original "o"
GAP = 3
KANJI_STRETCH = 1.25
BIG_TOP, SMALL_TOP, BASE = 10, 22, 63
ST, BAR = 17, 10               # stem and bar thickness, as in the original letters

def sh(a, dy, dx):
    return np.roll(np.roll(a, dy, 0), dx, 1)

def chamfer(m, n=4):
    """Step off each convex outer corner, like the original's chunky rounding."""
    out = m.copy()
    p = np.pad(m, 1)
    h, w = m.shape
    for y in range(h):
        for x in range(w):
            if not m[y, x]:
                continue
            for dx, dy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
                if not p[y + 1, x + 1 + dx] and not p[y + 1 + dy, x + 1]:
                    for k in range(n):
                        for l in range(n - 1 - k):
                            yy, xx = y - dy * k, x - dx * l
                            if 0 <= yy < h and 0 <= xx < w:
                                out[yy, xx] = False
    return out

def render(fill):
    g = np.pad(fill, PAD)
    dil = np.zeros_like(g)
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            dil |= sh(g, dy, dx)
    dark = dil | sh(dil, 2, 3)                       # outline + drop shadow down-right
    H, W = g.shape
    outside = np.zeros_like(g)
    q = deque([(0, 0)]); outside[0, 0] = True
    while q:
        y, x = q.popleft()
        for yy, xx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= yy < H and 0 <= xx < W and not outside[yy, xx] and not dark[yy, xx] and not g[yy, xx]:
                outside[yy, xx] = True; q.append((yy, xx))
    img = np.zeros((H, W, 4), np.uint8)
    img[dark] = DARK + (255,)
    img[~outside & ~dark & ~g] = WH + (255,)          # holes show cream
    img[g] = TAN + (255,)
    right = g & ~(sh(g, 0, -1) & sh(g, 0, -2))
    bottom = g & ~(sh(g, -1, 0) & sh(g, -2, 0))
    img[right | bottom] = SH + (255,)
    img[g & ~bottom & sh(bottom, 1, 0) & ~right] = LT + (255,)
    left = g & ~(sh(g, 0, 1) & sh(g, 0, 2) & sh(g, 0, 3))
    top = g & ~(sh(g, 1, 0) & sh(g, 2, 0))
    img[left | top] = WH + (255,)
    return Image.fromarray(img, "RGBA")

def glyph(w, h, rects, holes=()):
    m = np.zeros((h, w), bool)
    for x0, y0, x1, y1 in rects:
        m[y0:y1 + 1, x0:x1 + 1] = True
    for x0, y0, x1, y1 in holes:
        m[y0:y1 + 1, x0:x1 + 1] = False
    return render(chamfer(m))

BH, SHT = BASE - BIG_TOP + 1, BASE - SMALL_TOP + 1          # 52, 40
H_ = glyph(52, BH, [(0, 0, ST - 1, BH - 1), (52 - ST, 0, 51, BH - 1), (ST, 19, 52 - ST, 19 + BAR + 2)])
T_ = glyph(54, BH, [(0, 0, 53, BAR + 3), (27 - ST // 2 - 1, 0, 27 + ST // 2 - 1, BH - 1)])
# r: lowercase, the stem with an arm reaching right along the top, its tip turning down
R_ = glyph(40, SMALL_H, [(0, 0, ST - 1, SMALL_H - 1), (0, 0, 39, BAR + 1), (39 - 11, 0, 39, BAR + 7)])
# m: lowercase, three legs under one top
M_ = glyph(64, SMALL_H, [(0, 0, 63, SMALL_H - 1)], holes=[(ST, 14, 24, SMALL_H - 1), (39, 14, 63 - ST, SMALL_H - 1)])

def flood(free, seeds):
    seen = np.zeros_like(free)
    q = deque()
    for y, x in seeds:
        if free[y, x] and not seen[y, x]:
            seen[y, x] = True; q.append((y, x))
    h, w = free.shape
    while q:
        y, x = q.popleft()
        for yy, xx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= yy < h and 0 <= xx < w and free[yy, xx] and not seen[yy, xx]:
                seen[yy, xx] = True; q.append((yy, xx))
    return seen

def letter(x0, x1, seed):
    """A reused letter: only its own connected shape (and the hole it encloses), its
    outline and shadow redrawn by the same rule as the new letters."""
    im = np.pad(np.array(orig.crop((x0, 0, x1 + 1, 70))), ((0, 0), (8, 8), (0, 0)))
    seed = (seed[0], seed[1] + 8)
    op = im[..., 3] > 0
    dark = op & (im[..., 0] < 100)
    light = op & (im[..., 0] >= 195)
    soft = op & ~dark & ~light
    light[:SMALL_TOP] = False           # every small letter's body starts on the same row
    shape = flood(light, [seed])
    for _ in range(3):                    # its own shading bands, touching the light body
        near = sh(shape, 0, 1) | sh(shape, 0, -1) | sh(shape, 1, 0) | sh(shape, -1, 0)
        shape |= soft & near
    shape[:SMALL_TOP] = False
    h, w = shape.shape
    border = [(y, x) for y in range(h) for x in (0, w - 1)] + [(y, x) for x in range(w) for y in (0, h - 1)]
    outside = flood(~shape, border)
    hole = ~outside & ~shape
    dil = np.zeros_like(shape)
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            dil |= sh(shape, dy, dx)
    out = np.zeros_like(im)
    out[(dil | sh(dil, 2, 3)) & ~shape] = DARK + (255,)
    out[shape] = im[shape]
    out[hole] = im[hole]
    out[hole & ~op] = DARK + (255,)
    # the same shaded bottom band as every other letter (the original "o" had none)
    band = shape.copy(); band[:BASE - 1] = False
    band &= out[..., 0] >= 195
    band[:, :np.argmax(shape.any(0)) + 3] = False          # (its left highlight edge stays)
    out[band] = SH + (255,)
    return Image.fromarray(out, "RGBA")

O_ = letter(60, 122, (45, 12))         # small "o" from POOP
A_ = letter(296, 358, (55, 15))        # small "a" from PAL
YOU = orig.crop((352, 70, 425, 135))   # 友
_y = np.array(YOU); _y[~((_y[..., 3] > 0) & (_y[..., 0] < 100))] = 0; YOU = Image.fromarray(_y, "RGBA")

def word(parts):
    """parts: (image, top) pasted left to right, outlines overlapping like the original."""
    x, canvas = 4, Image.new("RGBA", (800, 150), (0, 0, 0, 0))
    for im, top in parts:
        l, _, r, _ = im.getbbox()
        canvas.alpha_composite(im, (x - l, top))
        x += r - l + GAP                 # each letter keeps its own outline, a small gap between
    return canvas, x - GAP

def place(im, small):
    return (im, (SMALL_TOP if small else BIG_TOP) - PAD)

parts = [place(H_, False), (A_, 0), place(R_, True), (A_, 0), place(T_, False), (O_, 0), place(M_, True), (O_, 0)]
logo, right = word(parts)
# the original 便友, right-aligned under the word as now
kan = orig.crop((280, 68, 425, 135))    # copied as drawn, its soft edge pixels included
l, t, r, btm = kan.getbbox()
kan = kan.crop((l, t, r, btm))
# x1.25: Logo2 is shown at 0.74 width vs the old logo's 0.93, so on screen they keep the
# original's width (and each ~4 px dot becomes an even 5 px)
kan = kan.resize((round(kan.width * KANJI_STRETCH), kan.height), Image.NEAREST)
logo.alpha_composite(kan, (right - kan.width + 1, 72 + t))   # (right edge where it was)
logo = logo.crop(logo.getbbox())
logo.save(ROOT + "textures/console/logo2.png")
print("wrote textures/console/logo2.png", logo.size)
