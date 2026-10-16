"""Pal Prix: world mockups v2 (2026-10-16), after the user's Retry (Rovio) references.

The rules taken from them:
  - the BACKGROUND has no outlines: soft flat shapes, few colours, steps and a 2x2 dither between
    them; only the gameplay things (the track, the car) are outlined
  - one small palette per world, a time of day for each (mood)
  - depth by haze: what's far is paler, closer to the sky's colour
  - foliage as chunky clusters (3-4 greens and a few light sparkles), never single leaves
  - a foreground that frames the scene (leaves over the corners: a parallax layer in the game)

    <venv>/bin/python docs/mockups/palprix_worlds/palprix_worlds_v2.py
        -> docs/mockups/palprix_worlds/v2_<world>.png and v2_sheet.png
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 240, 170
SHOW = 3
BAYER = np.array([[0, 2], [3, 1]]) / 4.0 + 0.125            # a 2x2 ordered dither

OUTLINE = (40, 34, 44)
ROAD = [(112, 108, 118), (100, 96, 106)]
LINE = (244, 240, 226)
CURB = [(226, 70, 64), (246, 242, 232)]
SIDE = [(236, 150, 64), (198, 110, 44), (150, 78, 34)]
BLOCK = [(246, 214, 92), (206, 168, 60)]
HW = 17
SIDE_H = 6

yy, xx = np.mgrid[0:H, 0:W]


def C(c):
    return np.array(c, float)


def noise(seed, scale, octaves=3):
    """Smooth value noise in 0..1 (bilinear over random grids)"""
    rng = np.random.default_rng(seed)
    out = np.zeros((H, W))
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        s = scale / (2 ** o)
        gw, gh = int(W / s) + 3, int(H / s) + 3
        g = rng.random((gh, gw))
        fx, fy = xx / s, yy / s
        x0, y0 = fx.astype(int), fy.astype(int)
        tx, ty = fx - x0, fy - y0
        tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        v = (g[y0, x0] * (1 - tx) + g[y0, x0 + 1] * tx) * (1 - ty) + (g[y0 + 1, x0] * (1 - tx) + g[y0 + 1, x0 + 1] * tx) * ty
        out += v * amp
        tot += amp
        amp *= 0.5
    return out / tot


def steps(v, palette):
    """Map 0..1 to a palette in steps, dithered at each step's edge"""
    n = len(palette)
    f = np.clip(v, 0, 0.9999) * n
    i = f.astype(int)
    frac = f - i
    dith = BAYER[yy % 2, xx % 2]
    up = (frac > 0.75) & (dith < (frac - 0.75) * 4)          # the edge's last quarter: dithered
    i = np.clip(i + up, 0, n - 1)
    pal = np.array(palette, float)
    return pal[i]


def blend(img, col, amount, mask=None):
    m = np.ones((H, W), bool) if mask is None else mask
    img[m] = img[m] * (1 - amount) + C(col) * amount


def blob(img, cx, cy, r, cols, sparkle=None, seed=0, jag=0.25, mask_out=None):
    """A chunky foliage clump (Retry style): a lumpy disc in 3-4 tones, lit top-left, darker
    bottom-right, a few light sparkles; no outline"""
    rng = np.random.default_rng(seed)
    a = np.arctan2(yy - cy, xx - cx)
    d = np.hypot(xx - cx, yy - cy)
    lump = r * (1 + jag * np.sin(a * 5 + rng.random() * 6) + jag * 0.5 * np.sin(a * 9 + rng.random() * 6))
    inside = d <= lump
    # chunky edge: 2 px blocks
    inside &= ((xx // 2 + yy // 2) % 3 != 0) | (d <= lump - 2)
    light = (-(xx - cx) - (yy - cy)) / (r * 1.6)
    v = np.clip(0.5 + light * 0.6 + (noise(seed + 7, 4, 2) - 0.5) * 0.5, 0, 1)
    shade = steps(v, cols)
    img[inside] = shade[inside]
    if sparkle is not None:
        pick = inside & (rng.random((H, W)) < 0.012) & (light > -0.1)
        img[pick] = C(sparkle)
    if mask_out is not None:
        mask_out |= inside
    return inside


# ------------------------------------------------------------------ the track (gameplay: outlined)

def track_line(kind):
    t = np.linspace(0, 1, 900)
    if kind == 'lagoon':
        a = t * 2 * np.pi
        return np.stack([120 + 94 * np.sin(a), 88 + 58 * np.sin(2 * a)], 1)
    return np.stack([-10 + t * 260, 92 + 38 * np.sin(t * np.pi * 1.6 + 0.4)], 1)


def distance_field(line):
    d = np.full((H, W), 1e9)
    idx = np.zeros((H, W), int)
    for i in range(0, len(line), 2):
        cx, cy = line[i]
        x0, x1 = int(max(0, cx - HW - 6)), int(min(W, cx + HW + 7))
        y0, y1 = int(max(0, cy - HW - 6)), int(min(H, cy + HW + 7))
        if x0 >= x1 or y0 >= y1:
            continue
        sub = np.hypot(xx[y0:y1, x0:x1] + 0.5 - cx, yy[y0:y1, x0:x1] + 0.5 - cy)
        m = sub < d[y0:y1, x0:x1]
        d[y0:y1, x0:x1][m] = sub[m]
        idx[y0:y1, x0:x1][m] = i
    return d, idx


def paint_track(img, d, idx, shadow_tint, shadow_amount=0.45, side_fade=0.0, fade_col=None, rails=False):
    road = d <= HW + 2
    # the shadow on the ground: soft (dithered edge), tinted with the world's shade colour
    sh = np.zeros_like(road)
    off = SIDE_H + 6
    sh[off:, 5:] = road[:-off, :-5]
    soft = np.zeros_like(road)
    soft[off + 2:, 7:] = road[:-(off + 2), :-7]
    edge = soft & ~sh & (BAYER[yy % 2, xx % 2] < 0.5)
    for m in (sh | edge,):
        mm = m & ~road
        img[mm] = img[mm] * (1 - shadow_amount) + C(shadow_tint) * shadow_amount
    # the side face (and the support blocks), fading into the world's haze if far up
    for t in range(SIDE_H + 1, 0, -1):          # (far to near: the nearest step wins)
        below = np.zeros_like(road)
        below[t:, :] = road[:-t, :]
        m = below & ~road
        if t <= SIDE_H:
            col = np.where(((idx[np.clip(yy - t, 0, H - 1), xx] // 18) % 3 == 0)[..., None] & (t > 2),
                           C(BLOCK[0] if t < SIDE_H else BLOCK[1]),
                           C(SIDE[0] if t <= 2 else (SIDE[1] if t < SIDE_H else SIDE[2])))
        else:
            col = np.broadcast_to(C(OUTLINE), (H, W, 3))
        img[m] = col[m]
    dd = d
    roadm = dd <= HW - 3
    img[roadm] = np.where(((xx * 3 + yy * 5) % 7 != 0)[..., None], C(ROAD[0]), C(ROAD[1]))[roadm]
    dash = (dd < 0.8) & ((idx // 12) % 2 == 0)
    img[dash] = C(LINE)
    curb = (dd > HW - 3) & (dd <= HW)
    if rails:
        img[curb] = np.where((((idx // 6) % 2) == 0)[..., None], C((196, 200, 214)), C((150, 156, 174)))[curb]
    else:
        img[curb] = np.where((((idx // 8) % 2) == 0)[..., None], C(CURB[0]), C(CURB[1]))[curb]
    img[(dd > HW) & (dd <= HW + 2)] = C(OUTLINE)


# ------------------------------------------------------------------ the worlds (background: no outlines)

def garden():
    """A bright morning: soft grass patches in 4 greens, clover and flower clusters, foliage
    clumps; leafy branches framing the corners (in front)"""
    img = steps(noise(1, 46) * 0.85 + 0.08, [(116, 172, 82), (130, 186, 90), (146, 200, 98), (162, 212, 110)])
    # mowing stripes, very soft
    stripe = ((xx + yy // 2) // 20) % 2 == 0
    blend(img, (172, 220, 120), 0.10, stripe)
    # flower clusters: soft dots in groups (no outline), white and pink
    rng = np.random.default_rng(4)
    for k in range(18):
        cx, cy = rng.integers(0, W), rng.integers(0, H)
        col = [(250, 246, 232), (248, 196, 206), (252, 226, 140)][k % 3]
        for j in range(9):
            fx, fy = cx + rng.integers(-9, 10), cy + rng.integers(-6, 7)
            if 0 <= fx < W - 1 and 0 <= fy < H - 1:
                img[fy:fy + 2, fx:fx + 2] = C(col)
                if fy + 2 < H:
                    img[fy + 2, fx] = C((92, 150, 70))
    # a few ground clumps (bushes from above)
    for k, (cx, cy, r) in enumerate([(26, 34, 14), (208, 148, 16), (130, 160, 11), (180, 24, 10)]):
        blob(img, cx, cy, r, [(60, 116, 56), (80, 140, 62), (104, 164, 72), (132, 188, 86)], (206, 240, 160), seed=10 + k)
    return img


def garden_light(img):
    blend(img, (255, 236, 190), 0.06)                       # morning warmth
    garden_front(img)


def lagoon_light(img):
    # the sunset over everything: warm at the top, rosy lower down
    warm = np.clip(1 - yy / H, 0, 1)[..., None]
    img[:] = img * (1 - 0.18 * warm) + C((255, 196, 150)) * 0.18 * warm
    blend(img, (200, 120, 160), 0.08)


def grandprix_light(img):
    # night over everything (the track too), then the floodlights' warm pools light it gently
    img[:] = img * 0.42 + C((20, 26, 64)) * 0.58
    for fx, fy, r in [(50, 120, 58), (200, 70, 64)]:
        d = np.hypot(xx - fx, yy - fy) / r
        for ring, amt in [(1.0, 0.07), (0.75, 0.08), (0.5, 0.09), (0.28, 0.08)]:
            m = (d < ring) | ((d < ring + 0.06) & (BAYER[yy % 2, xx % 2] < 0.5))
            img[m] = img[m] * (1 + amt * 1.6) + C((255, 196, 120)) * amt * 0.55
    # the grandstand stays dark, its crowd's lights bright
    img[:26] = grandprix_stand()


def playroom_light(img):
    # the window's light falls across everything, the track included
    s = xx + yy * 0.8
    beam = (s > 60) & (s < 150)
    edge = (((s > 52) & (s <= 60)) | ((s >= 150) & (s < 158))) & (BAYER[yy % 2, xx % 2] < 0.5)
    for k in range(3):
        beam &= ~(np.abs(s - (60 + 30 * (k + 1))) < 2.5)
    m = beam | edge
    img[m] = img[m] * 1.16 + C((255, 226, 170)) * 0.08
    blend(img, (60, 30, 40), 0.06, ~m)                      # the rest of the room in evening shade


def garden_front(img):
    """Leafy branches over the top corners, darker (closer, in shade)"""
    for k, (cx, cy, r) in enumerate([(-6, -8, 34), (28, -14, 26), (226, -10, 30), (250, 18, 24)]):
        blob(img, cx, cy, r, [(34, 78, 44), (48, 98, 50), (66, 120, 58), (88, 142, 66)], (150, 200, 120), seed=40 + k, jag=0.3)


def sky():
    """Noon, high up: far below a hazy patchwork of fields, then soft cloud layers (no outlines)"""
    pal = [(150, 186, 110), (176, 196, 118), (126, 166, 98), (196, 200, 140)]
    fields = steps(noise(21, 40, 2), pal)
    river = np.abs(yy - (60 + 30 * np.sin(xx * 0.03))) < 2.5
    fields[river] = C((150, 196, 220))
    haze = C((178, 214, 240))
    img = fields * 0.32 + haze * 0.68                       # far away: mostly the sky's colour
    img = np.round(img / 6) * 6
    # cloud layers: far (pale, small), near (white, big); flat with a lit top band, no outline
    rng = np.random.default_rng(9)
    for layer, (n, rmin, rmax, top, mid, under) in enumerate([
            (10, 8, 14, (226, 238, 250), (212, 228, 246), (196, 216, 240)),
            (8, 12, 22, (252, 253, 255), (238, 244, 252), (214, 228, 246))]):
        for k in range(n):
            cx, cy = rng.integers(-20, W + 20), rng.integers(10, H + 10)
            for p in range(5):
                px = cx + (p - 2) * rmax * 0.7 + rng.integers(-3, 4)
                py = cy + abs(p - 2) * 3
                r = rng.integers(rmin, rmax)
                d = np.hypot(xx - px, (yy - py) * 1.25)
                m = d <= r
                rel = (yy - py) / r
                col = np.where((rel < -0.35)[..., None], C(top), np.where((rel < 0.3)[..., None], C(mid), C(under)))
                # chunky lower edge
                m &= ~((rel > 0.6) & (BAYER[yy % 2, xx % 2] > 0.5))
                img[m] = col[m]
    return img


def lagoon():
    """Sunset: the water in glowing bands (peach, pink, lavender, deep blue), gold glints, dark
    island silhouettes far up; lily pads as dark teal shapes"""
    bands = [(250, 204, 156), (244, 176, 152), (226, 150, 160), (186, 136, 176), (132, 120, 176), (88, 98, 156), (64, 80, 136)]
    v = yy / H + (noise(2, 30, 2) - 0.5) * 0.08
    img = steps(v, bands)
    # glints: short horizontal gold dashes, more near the top (the sun's path)
    rng = np.random.default_rng(6)
    for k in range(70):
        gx, gy = rng.integers(0, W - 6), int(rng.random() ** 1.6 * H)
        ln = rng.integers(2, 6)
        img[gy, gx:gx + ln] = C((255, 236, 180) if gy < H * 0.5 else (236, 190, 210))
    # far islands: silhouettes on the top edge
    for cx, w2, h2 in [(40, 30, 10), (196, 40, 13)]:
        m = ((xx - cx) / w2) ** 2 + ((yy - 4) / h2) ** 2 <= 1
        img[m] = C((96, 70, 112))
        palm = (np.abs(xx - cx - 6) <= 0) & (yy < 16) & (yy > 2)
        img[palm] = C((96, 70, 112))
    # lily pads: dark teal, a lighter rim on top, no outline
    for k in range(10):
        lx, ly, r = rng.integers(10, W - 10), rng.integers(40, H - 6), rng.integers(4, 7)
        d = np.hypot(xx - lx, yy - ly)
        a = np.arctan2(yy - ly, xx - lx)
        m = (d <= r) & ~((np.abs(a - 0.7) < 0.35) & (d > 1))
        img[m] = C((54, 104, 104))
        img[m & (yy < ly - r * 0.4)] = C((84, 140, 124))
    return img


def grandprix_stand():
    """The grandstand, a dark silhouette with the crowd's lights in rows"""
    rng = np.random.default_rng(12)
    st = np.zeros((26, W, 3))
    st[:] = C((22, 24, 46))
    for row in range(6, 24, 4):
        on = rng.random(W) < 0.35
        cols = np.array([C((255, 214, 140)), C((236, 238, 255)), C((255, 160, 150))])[rng.integers(0, 3, W)]
        st[row, on] = cols[on]
    st[:3] = C((44, 48, 80))                                 # its roof's edge
    return st


def grandprix():
    """Night (the light pass darkens it): grass verges in soft checks, the wall's stripe"""
    img = steps(noise(3, 60) * 0.5 + 0.25, [(70, 128, 92), (78, 138, 98), (86, 148, 104)])
    checks = ((xx // 14) + (yy // 14)) % 2 == 0
    blend(img, (100, 164, 112), 0.25, checks)
    img[26:28, :] = C((90, 96, 130))
    img[26, ::3] = C((240, 240, 250))
    return img


def playroom():
    """Evening indoors: honey floorboards, a soft rug (no outlines), a slanted beam of window light"""
    plank = [(184, 132, 86), (172, 122, 80), (160, 112, 74)]
    row = yy // 14
    off = (row * 37) % 70
    img = np.zeros((H, W, 3))
    which = (row + (xx + off) // 70) % 2
    img[:] = np.where(which[..., None] == 0, C(plank[0]), C(plank[1]))
    seams = (yy % 14 == 0) | ((xx + off) % 70 == 0)
    img[seams] = C(plank[2])
    # the rug: an oval of soft woven bands in dusty blue and cream, no outline
    e = ((xx - 120) / 132) ** 2 + ((yy - 88) / 92) ** 2
    rug = e <= 1
    v = np.clip(e, 0, 1)
    rugcol = steps(1 - v, [(120, 132, 168), (196, 176, 160), (134, 148, 184), (146, 160, 194)])
    img[rug] = rugcol[rug]
    return img


WORLDS = [
    ('playroom', 'Playroom, evening: wood, a soft rug, the window\'s light', playroom, None, (70, 40, 40), playroom_light),
    ('garden', 'Garden, morning: soft grass, flowers, leafy frame', garden, None, (40, 80, 40), garden_light),
    ('sky', 'Sky, noon: high above hazy fields and clouds', sky, None, (110, 150, 200), None),
    ('lagoon', 'Lagoon, sunset: glowing water, a bridge crossing', lagoon, 'lagoon', (60, 40, 90), lagoon_light),
    ('grandprix', 'Grand Prix, night: floodlights and the crowd\'s lights', grandprix, None, (10, 10, 30), grandprix_light),
]


def render(name, ground, kind, shadow_tint, front):
    img = ground().astype(float)
    line = track_line(kind or name)
    d, idx = distance_field(line)
    paint_track(img, d, idx, shadow_tint)
    if kind == 'lagoon':
        n = len(line)
        db, ib = distance_field(line[int(n * 0.40):int(n * 0.60)])
        paint_track(img, db, ib, shadow_tint, shadow_amount=0.5, rails=True)
    if front:
        front(img)
    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), 'RGB')
    return out.resize((W * SHOW, H * SHOW), Image.NEAREST)


if __name__ == '__main__':
    tiles = []
    for name, label, ground, kind, tint, front in WORLDS:
        im = render(name, ground, kind, tint, front)
        im.save(os.path.join(HERE, 'v2_' + name + '.png'))
        tiles.append((label, im))
    pad, cap, cols = 24, 40, 2
    rows = (len(tiles) + 1) // cols
    sheet = Image.new('RGB', (cols * (W * SHOW + pad) + pad, rows * (H * SHOW + cap + pad) + pad), (36, 32, 40))
    dr = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf', 22)
    except OSError:
        font = None
    for i, (label, im) in enumerate(tiles):
        x = pad + (i % cols) * (W * SHOW + pad)
        y = pad + (i // cols) * (H * SHOW + cap + pad)
        dr.text((x, y), label, fill=(240, 232, 214), font=font)
        sheet.paste(im, (x, y + cap))
    sheet.save(os.path.join(HERE, 'v2_sheet.png'))
    print('ok', sheet.size)
