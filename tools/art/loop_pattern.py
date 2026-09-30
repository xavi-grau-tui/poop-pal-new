"""Menu-card scrolling pattern: reuses the poop pattern's grid and stamps another glyph."""
from PIL import Image
import numpy as np, sys
from collections import deque
# Glyphs are drawn in blocks of BLOCK x BLOCK pixels, like the SUPER PUFF poops (22x13 px)
BLOCK = 3
GLYPHS = {
 'ball': ["..###..",            # a marble with a little shine (one empty pixel)
          ".#####.",
          "##.####",
          "#######",
          "#######",
          ".#####.",
          "..###.."],
 'drop': ["..#..",
          "..#..",
          ".###.",
          "#.###",
          "#.###",
          "#####",
          ".###."],
 'germ': ["#..#..#",            # spiky germ with two eyes
          ".#####.",
          "##.#.##",
          "#######",
          ".#####.",
          "#..#..#"],
 'corn': [".###.",
          "#.###",
          "#####",
          "#####",
          ".###.",
          "..#.."],
 'brick': ["######",            # a shiny bathroom tile
           "#..###",
           "#.####",
           "######",
           "######"],
 'glasses': [".##..##.",
             "#..##..#",
             ".##..##."],
 'bulb': [".###.",
          "#.###",
          "#####",
          ".###.",
          "..#..",
          ".###."],
 'cloud': ["...##...",
           ".######.",
           "########",
           ".######."],
}
glyph = GLYPHS[sys.argv[1]]; out_path = sys.argv[2]
# optional colour: "r,g,b" (default: the original warm brown)
COLOR = tuple(int(v) for v in sys.argv[3].split(',')) + (255,) if len(sys.argv) > 3 else (141, 109, 79, 255)
src = np.asarray(Image.open('../../textures/menus/pooploopbackground.png').convert('RGBA'))
m = src[..., 3] > 0; H, W = m.shape; seen = np.zeros_like(m); centers = []
for y in range(H):
    for x in range(W):
        if m[y, x] and not seen[y, x]:
            q = deque([(y, x)]); seen[y, x] = 1; pts = []
            while q:
                cy, cx = q.popleft(); pts.append((cy, cx))
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < H and 0 <= nx < W and m[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = 1; q.append((ny, nx))
            if len(pts) > 6:
                ys, xs = zip(*pts); centers.append((max(ys), (min(xs) + max(xs)) / 2))
out = np.zeros_like(src)
for (bottom, cx) in centers:
    y0 = bottom + 1 - len(glyph) * BLOCK; x0 = int(round(cx)) - len(glyph[0]) * BLOCK // 2
    for j, row in enumerate(glyph):
        for i, c in enumerate(row):
            if c == '#':
                for by in range(BLOCK):
                    for bx in range(BLOCK):
                        out[(y0 + j * BLOCK + by) % H, (x0 + i * BLOCK + bx) % W] = COLOR
Image.fromarray(out, 'RGBA').save(out_path)
