"""The cases' prints (tools/art/cases_games.py lays them on a case's flat parts, never on its carving):
each one a picture on the console's pixel grid (1 px here = 4 on screen), the back's 270 x 480 and
the front's too (the front only shows round the screens). From simple to fancy (the user, 2026-10-17:
the first case simple, then fancier ones):

    taro     plain: the first case, nothing on it
    sakura   blossoms and loose petals            lemon   lemon slices, a leaf here and there
    sky      little clouds                        cocoa   sprinkles on chocolate
    maze     wood grain, a maze inlaid in a darker wood, steel marbles in its grooves
    splash   the lagoon from the light at the top to the deep at the bottom: waves, bubbles, fish
    prix     a race livery: two white stripes with pinstripes, a number roundel, a checkered band
    sumo     the ring's clay: its straw rope ring, the lines in the middle, the four corner tassels,
             the purple curtain along the top
    spin     black lacquer with gold: rings round a spiral (a top seen from above), gold flecks,
             a band of waves along the bottom
"""
import numpy as np

H, W = 480, 270                                   # a layer on the console's grid


def _rng(seed):
    return np.random.default_rng(seed)


def _base(body):
    return np.ones((H, W, 3), np.float32) * np.array(body, np.float32)


def _paint(img, mask, col):
    img[mask] = np.array(col, np.float32)


def _disc(img, cy, cx, r, cols, ink=None):
    """a round blob lit top left: cols = (light, mid, shade); a dark rim if ink"""
    y0, y1 = int(max(0, cy - r - 1)), int(min(H, cy + r + 2))
    x0, x1 = int(max(0, cx - r - 1)), int(min(W, cx + r + 2))
    if y0 >= y1 or x0 >= x1:
        return
    yy, xx = np.mgrid[y0:y1, x0:x1]
    oy, ox = yy + .5 - cy, xx + .5 - cx
    d = np.hypot(oy, ox)
    inside = d <= r
    sub = img[y0:y1, x0:x1]
    col = np.where(((ox + oy) < -r * .5)[..., None], np.array(cols[0], np.float32),
                   np.where(((ox + oy) > r * .45)[..., None], np.array(cols[2], np.float32), np.array(cols[1], np.float32)))
    sub[inside] = col[inside]
    if ink is not None:
        rim = inside & (d > r - .9)
        sub[rim] = np.array(ink, np.float32)


def _scatter(seed, n, margin=6, min_gap=0.0):
    """n points spread over the layer (a jittered grid, then shuffled), at least min_gap apart"""
    r = _rng(seed)
    pts = []
    tries = 0
    while len(pts) < n and tries < n * 40:
        tries += 1
        p = (r.uniform(margin, H - margin), r.uniform(margin, W - margin))
        if min_gap and any((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 < min_gap ** 2 for q in pts):
            continue
        pts.append(p)
    return pts, r


# ------------------------------------------------------------------ simple ones

def taro(layer, body):
    return _base(body)


def sakura(layer, body):
    img = _base(body)
    pts, r = _scatter(11 if layer == 'back' else 12, 130 if layer == 'back' else 70, min_gap=14)
    petal = [(255, 246, 250), (255, 226, 236), (236, 170, 192)]
    for (cy, cx) in pts:
        if r.random() < .25:
            # a loose petal, drifting
            _disc(img, cy, cx, 1.6, petal)
            continue
        size = r.uniform(.8, 1.25)
        turn = r.uniform(0, 2 * np.pi)
        for k in range(5):
            a = turn + k * 2 * np.pi / 5
            _disc(img, cy + np.sin(a) * 2.3 * size, cx + np.cos(a) * 2.3 * size, 1.8 * size, petal)
        _disc(img, cy, cx, 1.1, [(250, 200, 120), (240, 150, 170), (214, 110, 140)])
    return img


def lemon(layer, body):
    img = _base(body)
    pts, r = _scatter(21 if layer == 'back' else 22, 120 if layer == 'back' else 60, min_gap=17)
    for (cy, cx) in pts:
        rad = r.uniform(5.0, 7.0)
        yy, xx = np.mgrid[0:H, 0:W]
        y0, y1 = int(max(0, cy - rad - 1)), int(min(H, cy + rad + 2))
        x0, x1 = int(max(0, cx - rad - 1)), int(min(W, cx + rad + 2))
        yy, xx = np.mgrid[y0:y1, x0:x1]
        oy, ox = yy + .5 - cy, xx + .5 - cx
        d = np.hypot(oy, ox)
        ang = (np.arctan2(oy, ox) + np.pi) / (2 * np.pi) * 8
        sub = img[y0:y1, x0:x1]
        flesh = d <= rad - 1.6
        seg = flesh & (np.abs(ang - np.round(ang)) < .12 * (rad / np.maximum(d, .5))) & (d > .8)
        sub[(d <= rad) & (d > rad - .9)] = (226, 176, 40)           # the rind
        sub[(d <= rad - .9) & (d > rad - 1.6)] = (255, 250, 222)      # the pith
        sub[flesh] = (252, 226, 92)
        sub[flesh & ((ox + oy) < -rad * .5)] = (255, 240, 150)        # its shine
        sub[seg] = (255, 246, 200)                                  # the segments
        sub[d < .9] = (255, 250, 222)
        if r.random() < .35:
            # a leaf at its rim: two lumps, a vein
            a = r.uniform(0, 2 * np.pi)
            for k, rr in ((1.6, 2.2), (3.6, 1.7)):
                ly, lx = cy + np.sin(a) * (rad + k), cx + np.cos(a) * (rad + k)
                _disc(img, ly, lx, rr, [(160, 216, 116), (112, 178, 82), (80, 140, 60)])
    return img


def sky(layer, body):
    img = _base(body)
    pts, r = _scatter(31 if layer == 'back' else 32, 34 if layer == 'back' else 18, min_gap=30)
    for (cy, cx) in pts:
        sc = r.uniform(.8, 1.4)
        lumps = [(0, 0, 4.0), (-1.5, -4.5, 3.0), (-.5, 4.6, 3.2), (1.6, -8.2, 2.2), (1.2, 8.4, 2.4)]
        for (dy, dx, rr) in lumps:
            _disc(img, cy + dy * sc, cx + dx * sc, rr * sc, [(255, 255, 255), (246, 250, 255), (206, 224, 244)])
        # its flat bottom, in shade
        y = int(cy + 2.6 * sc)
        if 0 <= y < H:
            x0, x1 = int(max(0, cx - 9 * sc)), int(min(W, cx + 9 * sc))
            img[y, x0:x1] = np.where((img[y, x0:x1] != np.array(body, np.float32)).any(-1)[..., None], np.array((206, 224, 244), np.float32), img[y, x0:x1])
    # a few sparkles
    for k in range(int(30 if layer == 'back' else 14)):
        y, x = int(r.uniform(4, H - 4)), int(r.uniform(4, W - 4))
        if (img[y, x] == np.array(body, np.float32)).all():
            img[y, x] = (255, 255, 255)
            for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                img[y + dy, x + dx] = (226, 238, 252)
    return img


def cocoa(layer, body):
    img = _base(body)
    r = _rng(41 if layer == 'back' else 42)
    cols = [(250, 160, 190), (250, 246, 236), (150, 220, 190), (250, 214, 90), (130, 180, 236)]
    n = 1700 if layer == 'back' else 900
    for k in range(n):
        y, x = r.uniform(2, H - 3), r.uniform(2, W - 3)
        c = cols[r.integers(len(cols))]
        dy, dx = [(0, 1), (1, 0), (1, 1), (1, -1)][r.integers(4)]
        for t in range(3):
            yy, xx = int(y + dy * t), int(x + dx * t)
            if 0 <= yy < H and 0 <= xx < W:
                img[yy, xx] = c
        yy, xx = int(y + dy * 2) + 1, int(x + dx * 2)
        if 0 <= yy < H and 0 <= xx < W and (img[yy, xx] == np.array(body, np.float32)).all():
            img[yy, xx] = np.array(body, np.float32) * .82              # its little shadow
    return img


# ------------------------------------------------------------------ fancy ones

def _noise(seed, sy, sx):
    from scipy.ndimage import zoom
    r = _rng(seed).random((int(H / sy) + 3, int(W / sx) + 3))
    z = zoom(r, (sy, sx), order=3)[:H, :W]
    return (z - z.min()) / (z.max() - z.min())


def maze(layer, body):
    """the wooden labyrinth: grain, a maze inlaid (dark grooves, a lit lip below them), marbles"""
    B = np.array(body, np.float32)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    n = _noise(51, 40, 18)
    grain = np.sin((xx + n * 22) * .55 + np.sin(yy * .03) * 2.0)
    img = B * (1.0 + .05 * grain[..., None])
    img[grain > .93] = B * 1.1                                        # light grain lines
    img[grain < -.95] = B * .86                                       # dark grain lines
    # the maze: walls on a 12 px grid (a depth-first walk), drawn as grooves
    cell = 12
    rows, cols = H // cell + 1, W // cell + 1
    r = _rng(53 if layer == 'back' else 54)
    right = np.ones((rows, cols), bool)
    down = np.ones((rows, cols), bool)
    seen = np.zeros((rows, cols), bool)
    stack = [(0, 0)]
    seen[0, 0] = True
    while stack:
        a, b = stack[-1]
        nb = [(a + da, b + db) for da, db in ((1, 0), (-1, 0), (0, 1), (0, -1))
              if 0 <= a + da < rows and 0 <= b + db < cols and not seen[a + da, b + db]]
        if not nb:
            stack.pop()
            continue
        na, nb2 = nb[r.integers(len(nb))]
        if na != a:
            down[min(a, na), b] = False
        else:
            right[a, min(b, nb2)] = False
        seen[na, nb2] = True
        stack.append((na, nb2))
    ry, rx = (yy // cell).astype(int), (xx // cell).astype(int)
    my, mx = (yy % cell).astype(int), (xx % cell).astype(int)
    groove = ((mx == cell - 1) & right[ry, rx]) | ((my == cell - 1) & down[ry, rx])
    lip = ((mx == 0) & right[ry, np.maximum(rx - 1, 0)] & (rx > 0)) | ((my == 0) & down[np.maximum(ry - 1, 0), rx] & (ry > 0))
    img[groove] = B * .62
    img[lip & ~groove] = B * 1.14
    # a few steel marbles resting in the corridors
    for k in range(9 if layer == 'back' else 4):
        cy = (r.integers(1, rows - 1) + .5) * cell - .5
        cx = (r.integers(1, cols - 1) + .5) * cell - .5
        _disc(img, cy, cx, 3.6, [(236, 240, 248), (170, 176, 190), (110, 114, 130)], ink=(60, 50, 50))
        img[int(cy - 1.5), int(cx - 1.5)] = (255, 255, 255)
    return img


def splash(layer, body):
    """the lagoon: light at the top to the deep at the bottom, wave bands, bubbles rising, fish"""
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    top, deep = np.array((156, 228, 230), np.float32), np.array((34, 122, 162), np.float32)
    t = (yy / H)[..., None]
    img = top + (deep - top) * t
    # dithered steps instead of a smooth fade
    D = np.array([[.125, .625], [.875, .375]])
    steps = 7
    q = np.floor(yy / H * steps + D[(yy % 2).astype(int), (xx % 2).astype(int)])
    img = top + (deep - top) * np.clip(q / steps, 0, 1)[..., None]
    # waves: a wavy band every 46 px, a foam crest on it
    for k in range(H // 46 + 1):
        y0 = 30 + k * 46
        wy = y0 + 3.2 * np.sin(xx * .11 + k * 1.7) + 1.5 * np.sin(xx * .27 + k)
        crest = np.abs(yy - wy) < .8
        under = (yy - wy > .8) & (yy - wy < 3.0)
        img[crest] = img[crest] * .25 + np.array((255, 255, 255), np.float32) * .75
        img[under] = img[under] * .9
    r = _rng(61 if layer == 'back' else 62)
    # bubbles in little rising columns
    for c in range(16 if layer == 'back' else 8):
        cx = r.uniform(6, W - 6)
        cy = r.uniform(20, H - 10)
        for b in range(r.integers(2, 5)):
            rr = r.uniform(1.2, 2.6)
            by, bx = cy - b * 9 - r.uniform(0, 3), cx + r.uniform(-2, 2)
            yy0, xx0 = np.mgrid[max(0, int(by - 4)):min(H, int(by + 5)), max(0, int(bx - 4)):min(W, int(bx + 5))]
            d = np.hypot(yy0 + .5 - by, xx0 + .5 - bx)
            ring = (d <= rr) & (d > rr - .9)
            sub = img[max(0, int(by - 4)):min(H, int(by + 5)), max(0, int(bx - 4)):min(W, int(bx + 5))]
            sub[ring] = sub[ring] * .3 + np.array((240, 252, 255), np.float32) * .7
    # little fish, darker, going left or right
    for f in range(7 if layer == 'back' else 3):
        cy, cx = r.uniform(H * .35, H - 12), r.uniform(10, W - 10)
        way = 1 if r.random() < .5 else -1
        for dy in range(-2, 3):
            for dx in range(-4, 5):
                if (dx / 4.5) ** 2 + (dy / 2.3) ** 2 <= 1:
                    y, x = int(cy + dy), int(cx + dx * way)
                    if 0 <= y < H and 0 <= x < W:
                        img[y, x] = img[y, x] * .72
        for dy in range(-2, 3):
            y, x = int(cy + dy), int(cx - (5 + abs(dy)) * way)
            if 0 <= y < H and 0 <= x < W:
                img[y, x] = img[y, x] * .72
    return img


def _digit_one(img, cy, cx, s, col):
    """a chunky "1" for the race number, s px per cell"""
    rows = ["..##.", ".###.", "..##.", "..##.", "..##.", "..##.", ".####"]
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch == '#':
                img[int(cy + (j - 3.5) * s):int(cy + (j - 2.5) * s), int(cx + (i - 2.5) * s):int(cx + (i - 1.5) * s)] = col


def prix(layer, body):
    """the race livery"""
    img = _base(body)
    B = np.array(body, np.float32)
    white, ink = np.array((250, 246, 236), np.float32), np.array((70, 26, 28), np.float32)
    # two white stripes down it, just right of the middle, a dark pinstripe on their outer edges
    for x0 in (148, 172):
        img[:, x0:x0 + 18] = white
        img[:, x0 - 2:x0 - 1] = ink
        img[:, x0 + 19:x0 + 20] = ink
    yy, xx = np.mgrid[0:H, 0:W]
    if layer == 'back':
        # a checkered band across, low down (the back only: the front's bottom has its buttons and
        # the speaker)
        y0 = 404
        band = (yy >= y0) & (yy < y0 + 16)
        chk = ((yy - y0) // 8 + xx // 8) % 2 == 0
        img[band & chk] = (36, 30, 36)
        img[band & ~chk] = white
        img[(yy == y0 - 1) | (yy == y0 + 16)] = ink
        # the number roundel: a white disc with a dark rim, a big 1
        cy, cx, rr = 286, 76, 32
        d = np.hypot(yy + .5 - cy, xx + .5 - cx)
        img[d <= rr + 1.5] = ink
        img[d <= rr] = white
        _digit_one(img, cy, cx, 6, ink)
        # small stars
        r = _rng(71)
        for k in range(10):
            y, x = int(r.uniform(150, 380)), int(r.uniform(205, 262))
            for dy, dx in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)):
                img[y + dy, x + dx] = white
    return img


def sumo(layer, body):
    """the dohyo's clay"""
    B = np.array(body, np.float32)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    r = _rng(81 if layer == 'back' else 82)
    img = B * (1.0 + (r.random((H, W)) < .06)[..., None] * .06 - (r.random((H, W)) < .05)[..., None] * .07)
    straw, straw_d = np.array((232, 208, 140), np.float32), np.array((180, 150, 86), np.float32)
    if layer == 'back':
        # the straw rope ring (tawara): a braided band
        cy, cx, rr = 256, 135, 96
        d = np.hypot(yy + .5 - cy, xx + .5 - cx)
        a = np.arctan2(yy - cy, xx - cx)
        band = np.abs(d - rr) < 4.5
        braid = np.sin(a * 60 + (d - rr) * 1.4) > .2
        img[band] = np.where(braid[band][..., None], straw, straw_d)
        img[np.abs(d - rr) >= 4.5] = img[np.abs(d - rr) >= 4.5]
        img[np.abs(np.abs(d - rr) - 5.0) < .6] = B * .62                 # its outline
        # the two white lines in the middle
        for dx in (-14, 10):
            img[int(cy - 8):int(cy + 8), int(cx + dx):int(cx + dx + 4)] = (250, 246, 236)
    # the purple curtain along the top, white crests on it
    top = yy < 22
    img[top] = (112, 64, 140)
    img[(yy >= 22) & (yy < 24)] = (80, 44, 104)
    for k in range(W // 30 + 1):
        cx = 15 + k * 30
        d = np.hypot(yy + .5 - 11, xx + .5 - cx)
        img[(d <= 5.5) & (d > 4.4)] = (250, 246, 236)
        img[d <= 1.6] = (250, 246, 236)
    # the swags of the curtain's bottom edge
    for k in range(W // 30 + 1):
        cx = 15 + k * 30
        swag = (np.abs(xx - cx) < 15) & (yy >= 22) & (yy < 22 + 5 * np.cos((xx - cx) / 15 * np.pi / 2))
        img[swag] = (112, 64, 140)
    # the four tassels at the corners: blue-green, red, white, black (the four directions)
    for (cy, cx, col) in ((60, 22, (70, 150, 130)), (60, W - 22, (210, 64, 56)), (H - 50, W - 22, (246, 242, 232)), (H - 50, 22, (52, 46, 56))):
        c = np.array(col, np.float32)
        _disc(img, cy, cx, 6, [c * 1.15, c, c * .78], ink=(60, 40, 30))
        fringe = (yy > cy + 5) & (yy < cy + 30) & (np.abs(xx - cx) < 5 + (yy - cy - 5) * .12)
        img[fringe] = np.where(((xx.astype(int) % 2) == 0)[fringe][..., None], c, c * .82)
        img[(yy == int(cy + 30)) & (np.abs(xx - cx) < 8)] = c * .7
    return np.clip(img, 0, 255)


def spin(layer, body):
    """black lacquer and gold"""
    B = np.array(body, np.float32)
    gold, gold_l, red = np.array((226, 182, 82), np.float32), np.array((252, 226, 140), np.float32), np.array((178, 40, 52), np.float32)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    img = _base(body)
    r = _rng(91 if layer == 'back' else 92)
    # gold flecks
    fl = r.random((H, W)) < .012
    img[fl] = gold
    if layer == 'back':
        cy, cx = 250, 135
        d = np.hypot(yy + .5 - cy, xx + .5 - cx)
        for rr in (34, 54, 74, 96):
            img[np.abs(d - rr) < .8] = gold
        img[(d > 56) & (d < 72)] = red
        img[np.abs(d - 64) < .6] = gold_l
        a = np.arctan2(yy - cy, xx - cx)
        spiral = np.abs(((d - a * 30 / (2 * np.pi)) % 15) - 7.5) < 1.2
        img[(d < 32) & spiral] = gold
        img[d < 3.5] = gold_l
    # a band of gold waves (seigaiha) along the bottom (the back only: the front's bottom has its
    # buttons and the speaker)
    if layer != 'back':
        return img
    y0 = H - 46
    for row in range(3):
        for k in range(-1, W // 16 + 2):
            cx = k * 16 + (8 if row % 2 else 0)
            cy = y0 + row * 8 + 10
            d = np.hypot(yy + .5 - cy, xx + .5 - cx)
            upper = (yy <= cy) & (yy >= y0 + row * 8)
            for rr in (8, 5, 2):
                img[upper & (np.abs(d - rr) < .6)] = gold
    return img


PRINTS = {'taro': taro, 'sakura': sakura, 'lemon': lemon, 'sky': sky, 'cocoa': cocoa,
          'maze': maze, 'splash': splash, 'prix': prix, 'sumo': sumo, 'spin': spin}
