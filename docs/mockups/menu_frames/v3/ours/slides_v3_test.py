# test: the menu slide as one carved wooden board and as a washi card (from the v3 studies), on the exact template
import sys
import numpy as np
from PIL import Image
from scipy import ndimage
SP = sys.argv[1]
B = 'docs/mockups/menu_frames/v2_brief/'
outer = np.array(Image.open(B + 'mask_outer.png')) > 0
ring = np.array(Image.open(B + 'mask_window_border.png')) > 0
opening = np.array(Image.open(B + 'mask_opening.png')) > 0
Hh, Ww = outer.shape
yy, xx = np.mgrid[0:Hh, 0:Ww]
cx, cy = (xx - 3) // 4, (yy - 1) // 4           # (the art grid: 1 art pixel = 4 x 4 file px)
ART = 4
d_out = ndimage.distance_transform_edt(outer)   # (file px in from the outer edge)
win = ring | opening
d_win = ndimage.distance_transform_edt(~win)    # (file px out from the window border)
d_open = ndimage.distance_transform_edt(~opening)
mount = outer & ~win
# which side of a band faces the light (top left): the outward normal's direction
def facing(dist):
    gy, gx = np.gradient(ndimage.gaussian_filter(dist.astype(float), 2))
    return gx + gy          # (>0: the edge faces down-right of the inside... sign per use)
f_out = facing(d_out)      # (inside the mount near its edge: >0 top/left edge, <0 bottom/right)
f_ring = facing(d_open)    # (in the ring: >0 its bottom/right side ... see below)

def cellnoise(seed, sx, sy):
    r = np.random.default_rng(seed)
    g = r.random((Hh // (4 * sy) + 3, Ww // (4 * sx) + 3))
    g = ndimage.zoom(g, (4 * sy, 4 * sx), order=1)[:Hh, :Ww]
    return g

def blockify(img):          # (each art cell its own colour: its middle pixel's)
    out = img.copy()
    my = np.clip(cy * 4 + 1 + 2, 0, Hh - 1); mx = np.clip(cx * 4 + 3 + 2, 0, Ww - 1)
    return img[my, mx]

def wood():
    BASE, LIGHT, HI, MID, DARK, SHADE, LINE = (226,162,101), (238,182,121), (252,214,164), (204,140,86), (176,110,70), (156,90,58), (34,10,20)
    c = np.zeros((Hh, Ww, 3)); c[:] = BASE
    # one board: grain lines drawn as continuous pixel lines on the art grid, flowing right across
    AW, AH = Ww // 4 + 2, Hh // 4 + 2
    g = np.zeros((AH, AW), int)                       # (0 base, 1 light streak, 2 grain, 3 dark grain)
    rng = np.random.default_rng(5)
    xs = np.arange(AW)
    def line(ys, val, x0=0, x1=AW):
        prev = None
        for x in range(x0, x1):
            y = int(round(ys[x]))
            lo, hi = (y, y) if prev is None else (min(prev, y), max(prev, y))
            for yy_ in range(max(lo, 0), min(hi, AH - 1) + 1):
                if g[yy_, x] < val or val == 1 and g[yy_, x] == 0:
                    g[yy_, x] = val
            prev = y
    k = 0
    for y0 in np.arange(-6, AH + 6, 4.6):
        k += 1
        wv = 2.6 * np.sin(xs / 21.0 + y0 / 9.0) + 1.1 * np.sin(xs / 8.5 + y0 / 5.0)
        if y0 > 78:                                     # (the wide bottom: nested arches, a cathedral figure)
            wv -= (y0 - 78) * 0.55 * np.exp(-((xs - 55) / (10 + (y0 - 78) * 1.4)) ** 2)
        if 60 < y0 < 80:                                # (bending round a knot on the left)
            wv += np.sign(y0 - 70) * 3.0 * np.exp(-((xs - 17) / 4.0) ** 2)
        ys = y0 + wv
        val = 3 if k % 3 == 0 else 2
        # a line runs most of the way, with a gap or two
        gaps = sorted(rng.integers(0, AW, 2))
        line(ys, val, 0, gaps[0])
        line(ys, val, gaps[0] + int(rng.integers(3, 9)), AW)
        if k % 2:
            line(ys + 2, 1, int(rng.integers(0, 30)), int(rng.integers(55, AW)))
    yk, xk = 70, 17
    for (dy, dx, v) in [(0, 0, 3), (0, 1, 3), (-1, 0, 2), (1, 0, 2), (0, -1, 2), (0, 2, 2), (-1, 1, 2), (1, 1, 2)]:
        g[yk + dy, xk + dx] = max(g[yk + dy, xk + dx], v)
    pal = np.array([BASE, LIGHT, MID, DARK], float)
    c = pal[g[np.clip(cy, 0, AH - 1), np.clip(cx, 0, AW - 1)]]
    c = blockify(c)
    # bevel: the board's edge (1 art px light lip top/left, 1 shade bottom/right), the outline
    edge = mount & (d_out <= 2 * ART) & (d_out > ART)
    tl = (yy < 197) & (xx < 201)
    c[edge & (f_out > 0)] = HI
    c[edge & (f_out <= 0)] = SHADE
    # the window routed in: a dark groove round it, a light lip (ring outer px), the lip's shade (ring inner px)
    band = outer & ~opening
    groove = band & (d_open > 2 * ART) & (d_open <= 3 * ART)
    c[groove] = DARK
    ring_out = band & (d_open > ART) & (d_open <= 2 * ART)
    ring_in = band & (d_open <= ART)
    c[ring_out] = HI
    c[ring_in & (f_ring > 0)] = SHADE
    c[ring_in & (f_ring <= 0)] = MID
    c[outer & (d_out <= ART)] = LINE
    return c

def paper():
    BASE, CLOUD, CORE, BEVEL, LINE, RED, INK = (250,231,198), (238,214,178), (255,246,226), (226,196,156), (34,10,20), (196,74,46), (92,52,48)
    c = np.zeros((Hh, Ww, 3)); c[:] = BASE
    s = np.array(Image.open('docs/mockups/menu_frames/v3/studies/paper_2_vermilion.png').convert('RGB')).astype(int)
    # the study's clouds (its darker cream), mapped from its mount box to ours
    sx0, sy0, sx1, sy1 = 25, 5, 1582, 1553
    ox0, oy0, ox1, oy1 = 11, 5, 391, 389
    mx = np.clip(((cx * 4 + 5 - ox0) / (ox1 - ox0) * (sx1 - sx0) + sx0).astype(int), 0, s.shape[1] - 1)
    my = np.clip(((cy * 4 + 3 - oy0) / (oy1 - oy0) * (sy1 - sy0) + sy0).astype(int), 0, s.shape[0] - 1)
    sp = s[my, mx]
    lum = sp @ [0.299, 0.587, 0.114]
    red = (sp[..., 0] - sp[..., 2] > 90) & (sp[..., 1] < 150)
    cloud = (lum < 222) & (lum > 160) & ~red & (sp.sum(2) > 500)
    cloud = ndimage.binary_opening(cloud, np.ones((9, 9)))   # (no specks)
    c[cloud & mount] = CLOUD
    # the window cut in: a thin ink line round it, the cut's light core (ring outer px), its shade (ring inner)
    band = outer & ~opening
    c[band & (d_open > 2 * ART) & (d_open <= 3 * ART)] = INK
    ring_out = band & (d_open > ART) & (d_open <= 2 * ART); ring_in = band & (d_open <= ART)
    c[ring_out] = CORE
    c[ring_in & (f_ring > 0)] = BEVEL
    c[ring_in & (f_ring <= 0)] = CORE
    # the edge: the card's thin vermilion edge inside the outline
    c[outer & (d_out <= 2 * ART) & (d_out > ART)] = RED
    c[outer & (d_out <= ART)] = LINE
    return c

for name, fn in (('wood', wood), ('paper', paper)):
    c = fn()
    im = np.zeros((Hh, Ww, 4), np.uint8)
    im[..., :3] = np.clip(c, 0, 255).astype(np.uint8)
    im[..., 3] = (outer & ~opening) * 255
    Image.fromarray(im).save(SP + '/slide_%s.png' % name)
print('ok')
