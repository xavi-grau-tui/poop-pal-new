"""Pal Prix: world mockups (2026-10-15). A stretch of the raised toy track over each world's ground,
in the game's pixel rules: a 4 px grid (drawn here 1 px = 1 board px, shown x3), a 2 px dark
outline, light from the top-left, the track's side face and support blocks seen from the south,
shadows cast down-right. No gradients: flat colours in steps, patterns from the grid.

    <venv>/bin/python docs/mockups/palprix_worlds/palprix_worlds.py
        -> docs/mockups/palprix_worlds/<world>.png and sheet.png
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 240, 170                      # board px
SHOW = 3

OUTLINE = (40, 34, 44)
ROAD = [(112, 108, 118), (100, 96, 106)]
LINE = (244, 240, 226)
CURB = [(226, 70, 64), (246, 242, 232)]
SIDE = [(236, 150, 64), (198, 110, 44), (150, 78, 34)]
BLOCK = [(246, 214, 92), (206, 168, 60)]
HW = 17                              # road half-width, board px
SIDE_H = 6


def hashn(x, y, s=0):
    return ((x * 73856093) ^ (y * 19349663) ^ (s * 83492791)) & 0xFFFF


def track_line(kind):
    """A stretch of centre line (board px): an S through the picture; the lagoon's crosses itself"""
    t = np.linspace(0, 1, 900)
    if kind == 'lagoon':
        # a figure-8 lobe: down-right, loops round, crosses back over on a bridge
        a = t * 2 * np.pi
        x = 120 + 94 * np.sin(a)
        y = 88 + 58 * np.sin(2 * a)
        return np.stack([x, y], 1)
    x = -10 + t * 260
    y = 92 + 38 * np.sin(t * np.pi * 1.6 + 0.4)
    return np.stack([x, y], 1)


def distance_field(line):
    d = np.full((H, W), 1e9)
    idx = np.zeros((H, W), int)
    yy, xx = np.mgrid[0:H, 0:W]
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


def paint_track(img, d, idx, under_bridge=None, shadow_col=None, side=True):
    """The toy track (road, curbs, outline) and its side face below it; shadow on the ground"""
    h, w = d.shape
    road = d <= HW + 2
    # shadow down-right, on the ground only
    sh = np.zeros_like(road)
    sh[SIDE_H + 3:, 3:] = road[:-(SIDE_H + 3), :-3]
    for y in range(h):
        for x in range(w):
            if sh[y, x] and not road[y, x]:
                c = img[y, x]
                img[y, x] = (c * 0.74).astype(int) if shadow_col is None else shadow_col
    # side face
    if side:
        for x in range(w):
            for y in range(h):
                if road[y, x]:
                    continue
                for t in range(1, SIDE_H + 2):
                    if y - t >= 0 and road[y - t, x]:
                        if t <= SIDE_H:
                            col = SIDE[0] if t <= 2 else (SIDE[1] if t < SIDE_H else SIDE[2])
                            if t > 2 and (idx[y - t, x] // 18) % 3 == 0:
                                col = BLOCK[0] if t < SIDE_H else BLOCK[1]
                        else:
                            col = OUTLINE
                        img[y, x] = col
                        break
    for y in range(h):
        for x in range(w):
            dd = d[y, x]
            if dd > HW + 2:
                continue
            if dd <= HW - 3:
                col = ROAD[0] if (x * 3 + y * 5) % 7 else ROAD[1]
                if dd < 0.8 and (idx[y, x] // 12) % 2 == 0:
                    col = LINE
            elif dd <= HW:
                col = CURB[(idx[y, x] // 8) % 2]
            else:
                col = OUTLINE
            img[y, x] = col


# ------------------------------------------------------------------ the worlds' grounds

def playroom():
    """A round woven rug with a patterned border on a honey wooden floor"""
    img = np.zeros((H, W, 3), int)
    plank = [(206, 156, 102), (192, 142, 90), (176, 128, 80)]
    for y in range(H):
        for x in range(W):
            row = y // 12
            off = (row * 37) % 60
            c = plank[(row + (x + off) // 60) % 2]
            if y % 12 == 0 or (x + off) % 60 == 0:
                c = plank[2]                                # the boards' seams
            elif (x * 7 + y * 13) % 41 == 0:
                c = tuple(v - 10 for v in c)                # grain
            img[y, x] = c
    cx, cy, rx, ry = 120, 86, 140, 96
    for y in range(H):
        for x in range(W):
            e = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if e > 1.0:
                continue
            if e > 0.93:
                c = (70, 92, 140)                            # the rug's edge binding
            elif e > 0.82:
                # the border: a band of little diamonds
                u = int(np.arctan2(y - cy, x - cx) * 40)
                c = (238, 220, 186) if (abs((u % 8) - 4) + abs(int((e - 0.82) * 90) - 4)) < 3 else (196, 92, 84)
            elif e > 0.78:
                c = (70, 92, 140)
            else:
                # the middle: a soft woven check in two blues
                c = (118, 146, 186) if ((x // 3) + (y // 3)) % 2 else (108, 136, 176)
                if (x // 3) % 7 == 0 or (y // 3) % 7 == 0:
                    c = (132, 160, 198)
            img[y, x] = c
    return img


def garden():
    """Mown grass in stripes, clover patches, flower clusters, a stepping-stone path"""
    img = np.zeros((H, W, 3), int)
    for y in range(H):
        for x in range(W):
            stripe = ((x + y // 2) // 16) % 2
            c = (126, 186, 92) if stripe else (114, 172, 84)
            h = hashn(x, y)
            if h % 29 == 0:
                c = (150, 206, 108)                         # a blade catching the light
            elif h % 31 == 0:
                c = (96, 150, 72)
            img[y, x] = c
    rng = np.random.default_rng(3)
    # a winding gravel path, then bushes: round, dark, lit top-left, outlined
    for x in range(W):
        py = 26 + 8 * np.sin(x * 0.045) + 4 * np.sin(x * 0.11)
        for y in range(int(py) - 5, int(py) + 6):
            if 0 <= y < H:
                c = (216, 200, 160) if hashn(x, y, 4) % 4 else (196, 180, 140)
                if abs(y - py) > 4.2:
                    c = (150, 140, 110)
                img[y, x] = c
    for bx, by, r in [(30, 52, 11), (46, 58, 8), (206, 142, 12), (222, 132, 8), (120, 160, 10), (14, 150, 9)]:
        for y in range(by - r - 1, by + r + 2):
            for x in range(bx - r - 1, bx + r + 2):
                if 0 <= x < W and 0 <= y < H:
                    dd = np.hypot(x - bx, y - by)
                    lump = r + 1.2 * np.sin(np.arctan2(y - by, x - bx) * 5)
                    if dd <= lump:
                        c = (76, 138, 64)
                        if np.hypot(x - bx + r * 0.35, y - by + r * 0.35) < r * 0.55:
                            c = (104, 168, 80)                       # the lit side
                        if dd > lump - 1.0:
                            c = (44, 82, 44)
                        img[y, x] = c
                    elif dd <= lump + 2 and y > by and x > bx - r * 0.3:
                        img[y, x] = (np.array(img[y, x]) * 0.75).astype(int)   # its shadow
    # flower clusters: 5-petal pixel flowers
    petals = [(250, 246, 240), (250, 200, 214), (252, 222, 110), (196, 168, 236)]
    for k in range(40):
        fx, fy = rng.integers(8, W - 8), rng.integers(40, H - 6)
        col = petals[k % len(petals)]
        for dx, dy in [(0, -2), (-2, 0), (2, 0), (-1, 2), (1, 2)]:
            for ex in range(2):
                for ey in range(2):
                    x, y = fx + dx + ex - 1, fy + dy + ey - 1
                    if 0 <= x < W and 0 <= y < H:
                        img[y, x] = col
        for ex in range(2):
            for ey in range(2):
                if 0 <= fx + ex - 1 < W and 0 <= fy + ey < H:
                    img[fy + ey, fx + ex - 1] = (236, 170, 60)
        if 0 <= fy + 4 < H:
            img[fy + 4, fx] = (76, 128, 60)
    return img


def sky():
    """Over the clouds: a pale sky in steps, round cloud puffs in layers (lit tops, blue undersides)"""
    img = np.zeros((H, W, 3), int)
    bands = [(150, 200, 236), (160, 208, 240), (172, 216, 244), (184, 224, 246)]
    for y in range(H):
        img[y, :] = bands[min(3, y * 4 // H)]
    rng = np.random.default_rng(8)
    for layer, (n, rmin, rmax, top, under) in enumerate([
            (9, 10, 18, (236, 244, 252), (198, 216, 236)), (12, 12, 22, (250, 252, 255), (210, 226, 242))]):
        for k in range(n):
            cx, cy = rng.integers(-10, W + 10), rng.integers(20 + layer * 30, H)
            for p in range(4):
                px, py = cx + (p - 1.5) * rmax * 0.8, cy + (abs(p - 1.5) * 4)
                r = rng.integers(rmin, rmax)
                for y in range(int(py - r), int(py + r) + 1):
                    for x in range(int(px - r), int(px + r) + 1):
                        if 0 <= x < W and 0 <= y < H:
                            dd = np.hypot(x - px, y - py)
                            if dd <= r:
                                c = top if (y - py) < r * 0.25 else under
                                if dd > r - 1.2 and (y - py) < 0:
                                    c = tuple(min(255, v + 6) for v in top)
                                img[y, x] = c
    # a few birds (two-pixel Vs)
    for bx, by in [(40, 18), (52, 24), (190, 30)]:
        for dx, dy in [(-2, -1), (-1, 0), (0, 1), (1, 0), (2, -1)]:
            img[by + dy, bx + dx] = (90, 110, 140)
    return img


def lagoon():
    """Shallow turquoise water with ripple rings, lily pads, a sandy shore along the top"""
    img = np.zeros((H, W, 3), int)
    for y in range(H):
        for x in range(W):
            shore = 14 + int(5 * np.sin(x * 0.05) + 3 * np.sin(x * 0.13))
            if y < shore:
                c = (240, 220, 168) if hashn(x, y) % 11 else (226, 204, 150)
            elif y < shore + 3:
                c = (250, 250, 236)                          # surf
            else:
                deep = min(1.0, (y - shore) / 120)
                c = tuple(int(a + (b - a) * deep) for a, b in zip((96, 206, 206), (60, 160, 186)))
                c = tuple(int(v) // 8 * 8 for v in c)        # in steps
                w = np.sin(x * 0.18 + y * 0.09) + np.sin(y * 0.31 - x * 0.07)
                if w > 1.55:
                    c = (176, 236, 230)                      # ripples catching the light
            img[y, x] = c
    rng = np.random.default_rng(5)
    for k in range(9):
        lx, ly = rng.integers(10, W - 10), rng.integers(40, H - 8)
        r = rng.integers(5, 8)
        for y in range(ly - r, ly + r + 1):
            for x in range(lx - r, lx + r + 1):
                if 0 <= x < W and 0 <= y < H:
                    dd = np.hypot(x - lx, y - ly)
                    ang = np.arctan2(y - ly, x - lx)
                    if dd <= r and not (abs(ang - 0.6) < 0.35 and dd > 1):      # a notch
                        img[y, x] = (96, 170, 86) if dd < r - 1 else (64, 120, 62)
        if k % 3 == 0:                                     # a pink flower on some
            img[ly - 1:ly + 1, lx - 1:lx + 1] = (246, 160, 190)
    return img


def grandprix():
    """The stadium: grass verges with mowing checks, a gravel trap, grandstands with a crowd,
    tyre stacks and flags"""
    img = np.zeros((H, W, 3), int)
    for y in range(H):
        for x in range(W):
            c = (106, 176, 84) if ((x // 10) + (y // 10)) % 2 else (98, 166, 78)
            img[y, x] = c
    # grandstand along the top: rows of seats, the crowd as coloured dots
    crowd = [(236, 96, 84), (250, 220, 110), (110, 160, 236), (250, 250, 240), (180, 120, 220)]
    for y in range(0, 30):
        for x in range(W):
            if y < 4:
                c = (70, 74, 90)                             # its roof's edge
            elif y % 5 == 4:
                c = (150, 150, 166)                          # a step
            else:
                c = (120, 122, 140)
                if hashn(x // 2, y // 2, 1) % 3 == 0 and y % 5 in (1, 2):
                    c = crowd[hashn(x // 2, y // 2, 2) % len(crowd)]
            img[y, x] = c
    img[30:33, :] = (60, 62, 76)                             # the wall in front
    for x in range(0, W, 2):
        img[30, x] = (240, 240, 244)                         # its painted stripe
    # a gravel trap on the outside of the bend
    for y in range(H):
        for x in range(W):
            if ((x - 200) / 46) ** 2 + ((y - 150) / 26) ** 2 < 1:
                img[y, x] = (220, 200, 160) if hashn(x, y) % 5 else (196, 176, 136)
    # tyre stacks (black rings, white rims) and little flags
    for tx, ty in [(14, 46), (22, 46), (30, 46), (210, 60), (218, 60)]:
        for y in range(ty - 3, ty + 4):
            for x in range(tx - 3, tx + 4):
                dd = np.hypot(x - tx, y - ty)
                if dd <= 3.5:
                    img[y, x] = (40, 38, 44) if dd > 1.5 else (90, 90, 96)
                    if dd > 3.0 and y < ty:
                        img[y, x] = (230, 230, 236)
    for fx in range(10, W, 46):
        for y in range(36, 44):
            img[y, fx] = (60, 50, 50)                        # the pole
        for y in range(36, 40):
            for x in range(fx + 1, fx + 6):
                img[y, x] = (30, 30, 34) if ((x + y) % 2) else (250, 250, 250)
    return img


WORLDS = [
    ('playroom', 'Playroom (redo): a woven rug on a wooden floor', playroom, None),
    ('garden', 'Garden: mown grass, a gravel path, bushes, flowers', garden, None),
    ('sky', 'Sky: the track floats over the clouds', sky, None),
    ('lagoon', 'Lagoon: water and lily pads, a bridge where the road crosses itself', lagoon, 'lagoon'),
    ('grandprix', 'Grand Prix: grandstands, tyre stacks, flags', grandprix, None),
]


def render(name, ground, kind):
    img = ground()
    line = track_line(kind or name)
    if kind == 'lagoon':
        # the whole figure-8 on the water, then the bridge: the stretch of one lobe round the
        # crossing drawn again over the other, with its own side face and a shadow on the road below
        d, idx = distance_field(line)
        paint_track(img, d, idx)
        n = len(line)
        bridge = np.concatenate([line[int(n * 0.40):int(n * 0.60)]])
        db, ib = distance_field(bridge)
        deck = db <= HW + 2
        shadow = np.zeros_like(deck)
        shadow[SIDE_H + 4:, 4:] = deck[:-(SIDE_H + 4), :-4]
        for y in range(H):
            for x in range(W):
                if shadow[y, x] and not deck[y, x] and d[y, x] <= HW + 2:
                    img[y, x] = (np.array(img[y, x]) * 0.62).astype(int)     # on the road below
        for x in range(W):
            for y in range(H):
                if deck[y, x]:
                    continue
                for t in range(1, SIDE_H + 3):
                    if y - t >= 0 and deck[y - t, x]:
                        if t <= SIDE_H + 1:
                            img[y, x] = SIDE[0] if t <= 2 else (SIDE[1] if t < SIDE_H else SIDE[2])
                            if t > 2 and (ib[y - t, x] // 10) % 4 == 0:
                                img[y, x] = (176, 180, 196)                   # the bridge's steel posts
                        else:
                            img[y, x] = OUTLINE
                        break
        for y in range(H):
            for x in range(W):
                dd = db[y, x]
                if dd > HW + 2:
                    continue
                if dd <= HW - 3:
                    col = ROAD[0] if (x * 3 + y * 5) % 7 else ROAD[1]
                    if dd < 0.8 and (ib[y, x] // 12) % 2 == 0:
                        col = LINE
                elif dd <= HW:
                    col = (196, 200, 214) if (ib[y, x] // 6) % 2 else (150, 156, 174)   # rails, not curbs
                else:
                    col = OUTLINE
                img[y, x] = col
    else:
        d, idx = distance_field(line)
        paint_track(img, d, idx)
    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), 'RGB')
    return out.resize((W * SHOW, H * SHOW), Image.NEAREST)


if __name__ == '__main__':
    tiles = []
    for name, label, ground, kind in WORLDS:
        im = render(name, ground, kind)
        im.save(os.path.join(HERE, name + '.png'))
        tiles.append((label, im))
    pad, cap = 24, 40
    cols = 2
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
    sheet.save(os.path.join(HERE, 'sheet.png'))
    print('ok', sheet.size)
