"""LUCKY PINCH sprites (claw machine), drawn pixel by pixel at 1x (shown x3 in game).

    python3 tools/art/pinch_art.py   -> textures/minigames/pinch/*.png

claw_open / claw_closed: the grabber (hub on top, three prongs), same canvas so they swap
in place; the cable attaches at the top centre. carriage: the block that rides the rail.
capsule_<colour>: a prize capsule (coloured top, clear-ish bottom, a band, a shine).
"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(HERE, '..', '..', 'textures', 'minigames', 'pinch')
os.makedirs(DEST, exist_ok=True)

INK = (46, 30, 34, 255)
GOLD = (232, 184, 84, 255)
GOLD_HI = (255, 228, 150, 255)
GOLD_LO = (176, 124, 46, 255)
STEEL = (196, 196, 210, 255)
STEEL_HI = (240, 240, 250, 255)
STEEL_LO = (128, 126, 146, 255)


def canvas(w, h):
    return Image.new('RGBA', (w, h), (0, 0, 0, 0))


def put(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def rect(im, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(im, x, y, c)


def outline(im):
    """Dark 1px outline around everything opaque (4-neighbours)."""
    src = im.copy()
    for y in range(im.height):
        for x in range(im.width):
            if src.getpixel((x, y))[3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < im.width and 0 <= ny < im.height and src.getpixel((nx, ny))[3] > 0 and src.getpixel((nx, ny)) != INK:
                        im.putpixel((x, y), INK)
                        break
    return im


def prong(im, pts, col=STEEL, hi=STEEL_HI):
    """A 2px-wide prong along a list of pixel points (light on the left pixel)."""
    for (x, y) in pts:
        put(im, x, y, hi)
        put(im, x + 1, y, col)


W, H = 31, 23
CX = W // 2                              # 15: the claw is symmetric around this column


def hub(im):
    rect(im, CX - 4, 1, CX + 4, 6, GOLD)
    rect(im, CX - 4, 1, CX + 4, 1, GOLD_HI)
    rect(im, CX - 4, 6, CX + 4, 6, GOLD_LO)
    put(im, CX, 3, GOLD_LO)                      # a bolt
    put(im, CX, 4, GOLD_LO)
    rect(im, CX - 1, 0, CX + 1, 0, STEEL_LO)     # where the cable goes in


def claw(open_):
    """Closed, the prongs wrap a 15px capsule (inner gap 17px) centred on row 14."""
    im = canvas(W, H)
    hub(im)
    if open_:
        left = [(CX - 4, 7), (CX - 5, 8), (CX - 6, 9), (CX - 7, 10), (CX - 8, 11), (CX - 9, 12), (CX - 10, 13), (CX - 11, 14),
                (CX - 12, 15), (CX - 13, 16), (CX - 13, 17), (CX - 13, 18), (CX - 13, 19), (CX - 12, 20), (CX - 11, 21)]
        mid = [(CX - 1, y) for y in range(7, 13)]
    else:
        left = [(CX - 4, 7), (CX - 5, 8), (CX - 6, 8), (CX - 7, 9), (CX - 8, 10), (CX - 9, 11), (CX - 10, 12), (CX - 10, 13),
                (CX - 10, 14), (CX - 10, 15), (CX - 10, 16), (CX - 9, 17), (CX - 9, 18), (CX - 8, 19), (CX - 7, 20), (CX - 6, 21)]
        mid = [(CX - 1, y) for y in range(7, 12)]
    prong(im, left)
    prong(im, [(2 * CX - x - 1, y) for (x, y) in left], STEEL, STEEL)   # mirrored (no highlight)
    prong(im, mid, STEEL_LO, STEEL)
    return outline(im)


def carriage():
    im = canvas(23, 8)
    rect(im, 1, 1, 21, 6, GOLD)
    rect(im, 1, 1, 21, 1, GOLD_HI)
    rect(im, 1, 6, 21, 6, GOLD_LO)
    for x in (4, 18):                          # wheels on the rail
        rect(im, x - 1, 0, x + 1, 0, STEEL_LO)
    rect(im, 10, 3, 12, 4, (90, 60, 40, 255))   # the light
    return outline(im)


CAPSULES = {
    'pink': ((246, 150, 180), (255, 206, 220), (196, 92, 128)),
    'mint': ((150, 220, 190), (210, 246, 228), (88, 160, 132)),
    'yellow': ((250, 206, 110), (255, 236, 170), (196, 146, 54)),
    'lilac': ((190, 164, 218), (226, 210, 242), (132, 104, 168)),
    'orange': ((236, 150, 92), (252, 200, 150), (180, 96, 50)),
}


def capsule(col, hi, lo):
    n = 15
    im = canvas(n, n)
    c = (n - 1) / 2
    for y in range(n):
        for x in range(n):
            d = ((x - c) ** 2 + (y - c) ** 2) ** 0.5
            if d <= 6.6:
                if y < c:                             # coloured top half
                    p = hi if (x + y) < c + 1 else col
                    if y >= c - 1:
                        p = lo
                else:                                 # clear bottom half
                    p = (238, 232, 226) if d < 5.2 else (206, 198, 196)
                im.putpixel((x, y), (*p, 255))
    rect(im, 2, int(c), n - 3, int(c), (*lo, 255))      # the band
    put(im, 4, 3, (255, 255, 255, 255))
    put(im, 5, 3, (255, 255, 255, 255))
    put(im, 4, 4, (255, 255, 255, 255))
    return outline(im)


# ---------------------------------------------------------------- detailed claw (2x)
# The claw and the carriage are drawn on a grid twice as fine (shown at half scale in the
# game, so they keep the same size and grab point): shaded prongs with knuckles and rubber
# tips, a domed hub with rivets and a little light, a steel joint ring.
W2, H2 = 62, 46
RUBBER = (170, 70, 84, 255)
RUBBER_HI = (214, 112, 120, 255)
LIGHT = (255, 110, 96, 255)


def mirror(x):
    return W2 - 1 - x


def stamp_path(mask, pts, r):
    """Every pixel within r of the polyline through pts."""
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 3) + 1
        for i in range(n + 1):
            t = i / n
            cx, cy = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            for y in range(int(cy - r - 1), int(cy + r + 2)):
                for x in range(int(cx - r - 1), int(cx + r + 2)):
                    if (x + 0.5 - cx - 0.5) ** 2 + (y + 0.5 - cy - 0.5) ** 2 <= r * r:
                        mask.add((x, y))


def paint_prong(im, pts, base, hi, lo, tip_from):
    """A shaded prong: lit on its left edge, shaded on its right, a rubber tip."""
    mask = set()
    stamp_path(mask, pts, 2.1)
    tip = set()
    stamp_path(tip, pts[tip_from:], 2.1)
    for (x, y) in mask:
        rubber = (x, y) in tip
        c = RUBBER if rubber else base
        if (x - 1, y) not in mask or (x, y - 1) not in mask:
            c = RUBBER_HI if rubber else hi
        elif (x + 1, y) not in mask or (x, y + 1) not in mask:
            c = (120, 44, 58, 255) if rubber else lo
        put(im, x, y, c)
    return mask


def knuckle(im, x, y):
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            if dx * dx + dy * dy <= 5:
                put(im, x + dx, y + dy, STEEL_LO if dx + dy > 0 else STEEL_HI)
    put(im, x, y, GOLD_LO)


def hub2(im):
    # cable socket
    rect(im, 28, 0, 33, 3, STEEL_LO)
    rect(im, 29, 0, 30, 3, STEEL)
    # domed gold hub
    for y in range(3, 14):
        half = 9 if y > 5 else (7 if y == 4 else (5 if y == 3 else 8))
        for x in range(31 - half, 31 + half):
            c = GOLD
            if y <= 5 or x <= 31 - half:
                c = GOLD_HI
            elif y >= 12 or x >= 31 + half - 1:
                c = GOLD_LO
            put(im, x, y, c)
    for x in (24, 37):                            # rivets
        put(im, x, 9, GOLD_LO)
        put(im, x, 8, GOLD_HI)
    rect(im, 29, 7, 32, 9, (110, 40, 40, 255))    # the little light
    rect(im, 29, 7, 30, 8, LIGHT)
    put(im, 29, 7, (255, 220, 200, 255))
    # steel joint ring under the hub
    rect(im, 23, 14, 38, 16, STEEL)
    rect(im, 23, 14, 38, 14, STEEL_HI)
    rect(im, 23, 16, 38, 16, STEEL_LO)
    for x in range(25, 38, 4):
        put(im, x, 15, STEEL_LO)


def claw2(open_):
    im = canvas(W2, H2)
    if open_:
        left = [(24, 16), (17, 21), (10, 27), (6, 33), (6, 39), (9, 43)]
        mid = [(30, 16), (30, 27)]
    else:
        left = [(24, 16), (18, 20), (13, 25), (11, 31), (13, 37), (17, 42)]
        mid = [(30, 16), (30, 24)]
    paint_prong(im, mid, STEEL_LO, STEEL, (96, 94, 114, 255), 1)       # the back prong
    paint_prong(im, left, STEEL, STEEL_HI, STEEL_LO, 4)
    paint_prong(im, [(mirror(x) - 1, y) for (x, y) in left], STEEL, STEEL, STEEL_LO, 4)
    knuckle(im, left[2][0], left[2][1])
    knuckle(im, mirror(left[2][0]) - 1, left[2][1])
    hub2(im)
    return outline(im)


def carriage2():
    im = canvas(46, 16)
    rect(im, 2, 3, 43, 13, GOLD)
    rect(im, 2, 3, 43, 4, GOLD_HI)
    rect(im, 2, 12, 43, 13, GOLD_LO)
    rect(im, 2, 3, 2, 13, GOLD_HI)
    rect(im, 43, 3, 43, 13, GOLD_LO)
    rect(im, 4, 8, 41, 8, GOLD_LO)                 # a groove
    for x in (8, 37):                            # wheels riding the rail
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                if dx * dx + dy * dy <= 5:
                    put(im, x + dx, 2 + dy, STEEL_LO if dy > 0 else STEEL)
        put(im, x, 2, STEEL_HI)
    for x in (5, 40):                            # rivets
        put(im, x, 10, GOLD_LO)
        put(im, x, 6, GOLD_LO)
    rect(im, 19, 5, 26, 11, INK)                   # the light window
    rect(im, 20, 6, 25, 10, (120, 40, 40, 255))
    rect(im, 20, 6, 22, 7, LIGHT)
    return outline(im)


if __name__ == '__main__':
    claw2(True).save(os.path.join(DEST, 'claw_open.png'))
    claw2(False).save(os.path.join(DEST, 'claw_closed.png'))
    carriage2().save(os.path.join(DEST, 'carriage.png'))
    for name, (col, hi, lo) in CAPSULES.items():
        capsule(col, hi, lo).save(os.path.join(DEST, f'capsule_{name}.png'))
    # preview
    files = ['claw_open', 'claw_closed', 'carriage'] + [f'capsule_{k}' for k in CAPSULES]
    ims = [Image.open(os.path.join(DEST, f + '.png')) for f in files]
    prev = Image.new('RGBA', (sum(i.width + 4 for i in ims), 48), (120, 70, 110, 255))
    x = 0
    for i in ims:
        prev.alpha_composite(i, (x, 1))
        x += i.width + 4
    prev.resize((prev.width * 8, prev.height * 8), Image.NEAREST).save(os.path.join(HERE, 'out', 'pinch_preview.png'))
    print('ok')
