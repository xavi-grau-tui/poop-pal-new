"""The Forest Hokora's v8 front from the designer's high-resolution ImageGen study (the user, 2026-11-03:
its roots, perspective and look, brought down to the pixels of the other homes), on the 220 grid:
docs/mockups/hokora_homes/v8/forest_hokora/front_study_imagegen.png -> v8/forest_hokora/final/front.png

  - the study's drawing (BOX) over the homes' frame (GRID), each pixel its block's commonest colour
    (in steps of BIN), or its dark line's colour where the block is mostly line (LINE)
  - lone pixels unlike all four neighbours (the study's soft texture as speckle) as their likest neighbour
  - the silhouette's edge in the outline colour, closed all round
  - the plaque's 森 from round 1 (front_220.png), which survives the pixels, over the smeared one
  (saved as final/front_unpolished.png), then polished to the approved homes' finish (the user,
  2026-11-04: Fire, Bathhouse, Neon; the designer's own recolour, final_b, melted the drawing):
  - a calm wood base (pillars, beams, trays, gable, roots: less saturated, a little darker), the
    terracotta roof the accent (a touch calmer), the stone a touch greyer, the moss cooler and
    calmer, the roof's moss its own colour (a touch calmer: the user)
  - the grain as soft gradients: each pixel the mean of its same-material 3 x 3 neighbours that are
    close to it (TOL; the stone's wider), so edges stay
  - the inner lines half way to their material's own dark (not near-black); the outline and 森 kept
  - trays.png re-cut from the polished front (its trays' pixels, the designer's cut)

Run: .venv/bin/python tools/art/forest_v8.py
"""
import colorsys
import os
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = "docs/mockups/hokora_homes/v8/forest_hokora/"
OUT = SRC + "final/"
BOX = (24, 5, 1228, 1214)              # (the drawing in the study, its alpha over half)
GRID = (9, 9, 202, 203)                # (where it goes on the 220 grid: x, y, width, height)
BIN = 16                               # (colour steps the commonest colour is counted in)
LINE, DARK = 0.34, 130                 # (a block this much line, darker than this: a line pixel)
SPECKLE = 70                           # (a pixel this far from all four neighbours: speckle)
OUTLINE = (34, 12, 20)
PLAQUE = (100, 61, 119, 73)            # (inside the plaque's frame)
KANJI_SRC, KANJI_BOX, KANJI_DY = SRC + "front_220.png", (100, 55, 119, 69), 5   # (round 1's, 5 rows higher)
INK = 420                              # (darker than the plaque's wood: the kanji and its soft edge)
WOOD_S, WOOD_V = 0.63, 0.84            # (the wood's saturation and value, x)
ROOF_S, ROOF_MOSS_S, STONE_S = 0.76, 0.92, 0.8
MOSS_H, MOSS_TO, MOSS_S = 105, 0.6, 0.7   # (the other moss: this far towards this hue, this saturation)
LINE_K = 0.38                          # (an inner line: half way to its material's colour x this)
SMOOTH, TOL, STONE_TOL = 3, 60, 96     # (passes; how close a neighbour is to be averaged in)
LINE_L = 48                            # (a pixel this dark (luma): a line)
ROOF_GR = 0.43                         # (terracotta: green / red under this)

os.makedirs(OUT, exist_ok=True)
s = np.array(Image.open(SRC + "front_study_imagegen.png").convert("RGBA")).astype(int)
x0, y0, x1, y1 = BOX
gx, gy, w, h = GRID
cw, ch = (x1 - x0) / w, (y1 - y0) / h
f = np.zeros((220, 220, 4), int)
for j in range(h):
    for i in range(w):
        b = s[int(y0 + j * ch):int(y0 + (j + 1) * ch), int(x0 + i * cw):int(x0 + (i + 1) * cw)].reshape(-1, 4)
        op = b[b[:, 3] > 128]
        if len(op) < 0.5 * len(b):
            continue
        dark = op[op[:, :3].sum(1) < DARK]
        if len(dark) >= LINE * len(op):
            col = np.median(dark[:, :3], 0)
        else:
            q = op[:, :3] // BIN
            keys = q[:, 0] * 10000 + q[:, 1] * 100 + q[:, 2]
            u, c = np.unique(keys, return_counts=True)
            col = op[keys == u[c.argmax()]][:, :3].mean(0)
        f[gy + j, gx + i] = list(col) + [255]

op = f[..., 3] > 0
rgb = f[..., :3].copy()
for y in range(1, 219):
    for x in range(1, 219):
        nb = [(y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)]
        if op[y, x] and all(op[p] for p in nb):
            d = [np.abs(f[y, x, :3] - f[p][:3]).sum() for p in nb]
            if min(d) > SPECKLE:
                rgb[y, x] = f[nb[int(np.argmin(d))]][:3]
f[..., :3] = rgb
f[op & ~ndimage.binary_erosion(op)] = list(OUTLINE) + [255]

px0, py0, px1, py1 = PLAQUE
box = f[py0:py1, px0:px1]
ink = box[..., :3].sum(2) < INK
box[ink] = list(np.median(box[~ink][:, :3], 0).astype(int)) + [255]
r1 = np.array(Image.open(KANJI_SRC).convert("RGBA")).astype(int)
kx0, ky0, kx1, ky1 = KANJI_BOX
for y in range(ky0, ky1):
    for x in range(kx0, kx1):
        if py0 <= y + KANJI_DY < py1 and px0 <= x < px1 and r1[y, x, 3] and r1[y, x, :3].sum() < INK:
            f[y + KANJI_DY, x] = r1[y, x]

Image.fromarray(f.astype(np.uint8)).save(OUT + "front_unpolished.png")


def to_hsv(x):
    return np.array([colorsys.rgb_to_hsv(*p) for p in x.reshape(-1, 3)]).reshape(x.shape)


def to_rgb(x):
    return np.array([colorsys.hsv_to_rgb(*p) for p in x.reshape(-1, 3)]).reshape(x.shape)


a = f.astype(float)
op = a[..., 3] > 0
hsv = to_hsv(a[..., :3] / 255)
H, S = hsv[..., 0] * 360, hsv[..., 1]
L = a[..., :3] @ [0.299, 0.587, 0.114]
yy, xx = np.mgrid[0:220, 0:220]
edge = op & ~ndimage.binary_erosion(op)
line = op & (L < LINE_L) & ~edge
plaque = np.zeros(op.shape, bool)
plaque[PLAQUE[1] - 2:PLAQUE[3] + 2, PLAQUE[0] - 2:PLAQUE[2] + 2] = True
body = op & ~line & ~edge
green = body & (H >= 50) & (H < 170) & (S >= 0.22)
stone = body & ~green & (S < 0.45)
warm = body & ~green & ~stone
gr = a[..., 1] / np.maximum(a[..., 0], 1)
k = np.ones((5, 5))                    # (a warm pixel joins the kind most of its warm neighbours are)
roof = warm & (ndimage.convolve((warm & (gr < ROOF_GR)).astype(float), k, mode="constant")
               > 0.5 * ndimage.convolve(warm.astype(float), k, mode="constant"))
gable = (yy >= 36) & (yy < 62) & (np.abs(xx - 109.5) < (yy - 30) * 0.9)   # (the wooden gable under the ridge)
roof |= warm & (yy < 58) & ~(gable & (gr >= 0.45))                     # (above the beam: the tiles, their light tops too)
roof &= ~(gable & (gr >= 0.45))
wood = warm & ~roof
kind = np.zeros(op.shape, int)
kind[stone], kind[wood], kind[roof], kind[green], kind[line], kind[edge] = 1, 2, 3, 4, 5, 6

h = hsv.copy()
h[wood, 1] *= WOOD_S
h[wood, 2] *= WOOD_V
h[roof, 1] *= ROOF_S
h[green, 0] = (H[green] + (MOSS_H - H[green]) * MOSS_TO) / 360
h[green, 1] *= MOSS_S
h[stone, 1] *= STONE_S
roof_moss = green & (yy < 62)
h[roof_moss] = hsv[roof_moss]
h[roof_moss, 1] *= ROOF_MOSS_S
h[line, 1] *= WOOD_S
out = to_rgb(np.clip(h, 0, 1)) * 255

for _ in range(SMOOTH):
    n = out.copy()
    for y in range(1, 219):
        for x in range(1, 219):
            c = kind[y, x]
            if c in (0, 5, 6) or plaque[y, x]:
                continue
            blk = out[y - 1:y + 2, x - 1:x + 2].reshape(-1, 3)
            same = (kind[y - 1:y + 2, x - 1:x + 2].ravel() == c) & \
                (np.abs(blk - out[y, x]).sum(1) < (STONE_TOL if c == 1 else TOL))
            n[y, x] = blk[same].mean(0)
    out = n

src = out.copy()
mat = (kind >= 1) & (kind <= 4)
for y, x in zip(*np.where(line & ~plaque)):
    y0, x0 = max(y - 2, 0), max(x - 2, 0)
    m = mat[y0:y + 3, x0:x + 3]
    if m.sum() >= 3:
        out[y, x] = 0.5 * np.median(src[y0:y + 3, x0:x + 3][m], 0) * LINE_K + 0.5 * a[y, x, :3]
f[..., :3] = np.clip(np.round(out), 0, 255).astype(int)
Image.fromarray(f.astype(np.uint8)).save(OUT + "front.png")

trays = np.array(Image.open(OUT + "trays.png").convert("RGBA"))   # (the designer's cut, from the new front)
on = trays[..., 3] > 0
trays[on] = f[on]
Image.fromarray(trays).save(OUT + "trays.png")
