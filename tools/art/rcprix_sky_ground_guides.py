"""RC Prix Sky: the guide for the ground far below (the designer's ImageGen paintings, converted by us). Run from
the repo root:

    <python with Pillow + numpy> tools/art/rcprix_sky_ground_guides.py

Today's ground (rc_racer.gd _sky_floor), in board px (4 world px): fields on a skewed grid, u = x * 0.86 + y * 0.32
in steps of 46 and v = y * 0.9 - x * 0.24 in steps of 38. In game px (2 world px) that's fields about 100 x 82,
their long edges running about 15 degrees down from horizontal and their short edges about 70 degrees (a lattice a
little off square). Writes docs/mockups/rcprix_sky/ground_guides/:
  ground_grid_4x.png     one phone screen (299 x 277 game px) of today's field grid at 4x: field edges, today's
                         colours, the scale marks (a farmhouse, a village, a tree, the plane)
  ground_today_4x.png    the same screen as the game paints it today (colours, hedges, river; no haze or clouds)"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/mockups/rcprix_sky/ground_guides"
W, H = 299, 277                        # the phone's view, game px
K = 4
FIELDS = [(196, 214, 150), (170, 200, 140), (222, 210, 150), (188, 180, 140), (150, 190, 132)]
INK = (40, 30, 40)
PINK = (255, 0, 255)


def field_of(x, y):
    """A game px -> (its field's ids, distance to the field's edge in board px), as _sky_floor (board px = 2 game px)"""
    bx, by = x / 2.0, y / 2.0
    u = bx * 0.86 + by * 0.32
    v = by * 0.9 - bx * 0.24
    fx, fy = int(np.floor(u / 46.0)), int(np.floor(v / 38.0))
    eu, ev = u % 46.0, v % 38.0
    return fx, fy, min(eu, 46.0 - eu, ev, 38.0 - ev)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    grid = np.zeros((H, W, 3), np.uint8)
    today = np.zeros((H, W, 3), np.uint8)
    for y in range(H):
        for x in range(W):
            fx, fy, edge = field_of(x, y)
            h = ((fx * 73856093) ^ (fy * 19349663)) & 0xFFFF
            c = FIELDS[h % len(FIELDS)]
            grid[y, x] = INK if edge < 0.7 else c
            t = c
            bx, by = x / 2.0, y / 2.0
            u = bx * 0.86 + by * 0.32
            if (h // 7) % 3 == 0 and int(u) % 6 < 2:
                t = tuple(int(v * 0.94) for v in c)                  # (furrows in some fields)
            if edge < 1.4:
                t = (120, 160, 110)                                  # (a hedge)
            if abs(by + 60.0 * np.sin(bx * 0.012) - H * 0.3) < 4.0:
                t = (176, 210, 230)                                  # (the river)
            today[y, x] = t
    g = Image.fromarray(grid).convert("RGBA")
    d = ImageDraw.Draw(g)
    # scale marks, game px: a farmhouse 7 x 6, a village 30 x 22, a tree 4 x 4, the plane 52 x 52
    for (x0, y0, w, h, col) in ((12, 12, 7, 6, (226, 70, 64)), (30, 10, 30, 22, (226, 120, 64)),
                                (70, 12, 4, 4, (40, 110, 60)), (236, 214, 52, 52, (250, 210, 84))):
        d.rectangle((x0, y0, x0 + w - 1, y0 + h - 1), outline=col)
    for im, name in ((g, "ground_grid_4x.png"), (Image.fromarray(today).convert("RGBA"), "ground_today_4x.png")):
        big = im.resize((W * K, H * K), Image.NEAREST)
        px = big.load()
        for cx, cy in ((0, 0), (W * K - 1, 0), (0, H * K - 1), (W * K - 1, H * K - 1)):
            px[cx, cy] = PINK + (255,)
        big.save(OUT / name)
    print("written to", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
