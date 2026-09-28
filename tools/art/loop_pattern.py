"""Menu-card scrolling pattern: reuses the poop pattern's grid and stamps another glyph."""
from PIL import Image
import numpy as np, sys
from collections import deque
GLYPHS = {
 'cloud': ["....###.........",
           "..#.#####.......",
           ".###########.##.",
           ".##############.",
           "################",
           ".##############."],
}
glyph = GLYPHS[sys.argv[1]]; out_path = sys.argv[2]
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
    y0 = bottom + 1 - len(glyph); x0 = int(round(cx)) - len(glyph[0]) // 2
    for j, row in enumerate(glyph):
        for i, c in enumerate(row):
            if c == '#':
                out[(y0 + j) % H, (x0 + i) % W] = (141, 109, 79, 255)
Image.fromarray(out, 'RGBA').save(out_path)
