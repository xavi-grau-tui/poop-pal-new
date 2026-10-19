"""Pal Prix 2177's Games-menu card (the Turbo League): its logo and its pattern, from Pal Prix's.

    python3 tools/art/palprix2_card.py     -> textures/menus/palprix2.png, pattern_rocket_navy.png

The logo is Pal Prix's own lettering (textures/menus/palprix.png) recoloured from terracotta to a
night blue with neon light, the year "2177" added after PAL in the same blocky letters (dark outline,
light upper half, darker lower half, a darker foot, the same faint grain). The pattern keeps
Pal Prix's trophy pattern's layout (pattern_trophy_terracotta.png: 7 x 7 px glyphs at x3 on a
staggered grid, so it tiles the same) with a little rocket in each place.
"""
import os
import random
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
MENUS = os.path.join(HERE, '..', '..', 'textures', 'menus')

# Pal Prix's letters: outline, the light upper half, the darker lower half, the foot, a glint
OLD_OUT = (100, 54, 42)
NEW = {
    'out': (26, 30, 66),
    'light': (126, 226, 250),
    'dark': (74, 168, 226),
    'foot': (48, 112, 186),
    'glint': (190, 246, 255),
}


def classify(p):
    r, g, b, a = p
    if a == 0:
        return None
    if (r, g, b) == OLD_OUT:
        return 'out'
    if (r, g, b) == (156, 116, 104):
        return 'glint'
    if r >= 208:
        return 'light'
    if r >= 185:
        return 'dark'
    return 'foot'


def jitter(c, rng, k=3):
    return tuple(max(0, min(255, v + rng.randint(-k, k))) for v in c)


# "2177" in chunky digits (each px x3: 18 x 24 px, strokes 6 px) beside PAL's L
DIGITS = {
    "2": [".####.", "##..##", "....##", "...##.", "..##..", ".##...", "##....", "######"],
    "1": ["..##..", ".###..", "..##..", "..##..", "..##..", "..##..", "..##..", ".####."],
    "7": ["######", "....##", "...##.", "..##..", "..##..", ".##...", ".##...", ".##..."],
}
YEAR = "2177"


def logo():
    src = Image.open(os.path.join(MENUS, 'palprix.png')).convert('RGBA')
    rng = random.Random(7)
    # (wider than Pal Prix's: the year goes after PAL's L; the card centres the logo)
    out = Image.new('RGBA', (src.width + 48, src.height), (0, 0, 0, 0))
    for y in range(src.height):
        for x in range(src.width):
            k = classify(src.getpixel((x, y)))
            if k:
                out.putpixel((x, y), jitter(NEW[k], rng, 2 if k != 'out' else 0) + (255,))
    k3, o, gap = 3, 3, 3
    dw, dh = 6 * k3, 8 * k3
    gx, gy = 121, 8
    rows = []
    for ch in YEAR:
        rows.append(DIGITS[ch])
    def inside(x, y):
        if y < 0 or y >= dh or x < 0:
            return False
        d, lx = divmod(x, dw + gap)
        if d >= len(rows) or lx >= dw:
            return False
        return rows[d][y // k3][lx // k3] == '#'
    tw = len(rows) * (dw + gap) - gap
    for y in range(-o, dh + o):
        for x in range(-o, tw + o):
            px, py = gx + x, gy + y
            if not (0 <= px < out.width and 0 <= py < out.height):
                continue
            if inside(x, y):
                k = 'light' if y < dh * 0.45 else ('foot' if y >= dh - 3 else 'dark')
                out.putpixel((px, py), jitter(NEW[k], rng, 2) + (255,))
            elif any(inside(x + dx, y + dy) for dy in range(-o, o + 1) for dx in range(-o, o + 1)):
                out.putpixel((px, py), NEW['out'] + (255,))
    out.save(os.path.join(MENUS, 'palprix2.png'))
    print('palprix2.png', out.size)


ROCKET = [
    "...#...",
    "..###..",
    "..#.#..",
    "..###..",
    ".#####.",
    "#.###.#",
    "..#.#..",
]


def pattern():
    src = Image.open(os.path.join(MENUS, 'pattern_trophy_terracotta.png')).convert('RGBA')
    w, h = src.size
    seen = [[False] * w for _ in range(h)]
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    col = (88, 110, 196, 255)
    k = 3
    for y in range(h):
        for x in range(w):
            if seen[y][x] or src.getpixel((x, y))[3] == 0:
                continue
            # a glyph: its connected pixels (8-way) -> its box
            stack = [(x, y)]
            seen[y][x] = True
            xs, ys = [], []
            while stack:
                cx, cy = stack.pop()
                xs.append(cx)
                ys.append(cy)
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and src.getpixel((nx, ny))[3] > 0:
                            seen[ny][nx] = True
                            stack.append((nx, ny))
            x0, y0, x1, y1 = min(xs), min(ys), max(xs), max(ys)
            # (a glyph cut by the tile's edge: anchor it on the side that's whole)
            gx = x0 if x1 - x0 >= 20 or x0 > 0 else x1 - 20
            gy = y0 if y1 - y0 >= 20 or y0 > 0 else y1 - 20
            for ry, row in enumerate(ROCKET):
                for rx, ch in enumerate(row):
                    if ch != '#':
                        continue
                    for sy in range(k):
                        for sx in range(k):
                            px, py = (gx + rx * k + sx) % w, (gy + ry * k + sy) % h
                            out.putpixel((px, py), col)
    out.save(os.path.join(MENUS, 'pattern_rocket_navy.png'))
    print('pattern_rocket_navy.png', out.size)


if __name__ == '__main__':
    logo()
    pattern()
