# Block-letter title in the SUPER PUFF construction: 2-unit strokes on a 7x9 unit grid,
# chamfered corners, one merged dark backdrop, light upper band, darker base row.
from PIL import Image
import numpy as np, sys
G = {
'P': ["######.","#######","##...##","##...##","#######","######.","##.....","##.....","##....."],
'O': [".#####.","#######","##...##","##...##","##...##","##...##","##...##","#######",".#####."],
'M': ["##.....##","###...###","####.####","##.###.##","##..#..##","##.....##","##.....##","##.....##","##.....##"],
'A': [".#####.","#######","##...##","##...##","#######","#######","##...##","##...##","##...##"],
'Z': ["#######","#######","....###","...###.","..###..",".###...","###....","#######","#######"],
'E': ["#######","#######","##.....","##.....","######.","######.","##.....","#######","#######"],
'D': ["######.","#######","##...##","##...##","##...##","##...##","##...##","#######","######."],
'I': ["######","######","..##..","..##..","..##..","..##..","..##..","######","######"],
'B': ["######.","#######","##...##","##..##.","######.","##...##","##...##","#######","######."],
'C': [".######","#######","##.....","##.....","##.....","##.....","##.....","#######",".######"],
'K': ["##...##","##..###","##.###.","#####..","####...","#####..","##.###.","##..###","##...##"],
'G': [".######","#######","##.....","##.....","##..###","##..###","##...##","#######",".#####."],
'R': ["######.","#######","##...##","##...##","#######","######.","##.###.","##..###","##...##"],
'U': ["##...##","##...##","##...##","##...##","##...##","##...##","##...##","#######",".#####."],
'N': ["##...##","###..##","####.##","##.####","##..###","##...##","##...##","##...##","##...##"],
'S': [".######","#######","##.....","######.",".######",".....##",".....##","#######","######."],
}
lines = sys.argv[1].split('|')
out_path = sys.argv[2]
U = int(sys.argv[3]) if len(sys.argv) > 3 else 5   # px per unit (SUPER PUFF strokes are ~10px = 2 units)

def word_mask(w):
    cols = sum(len(G[ch][0]) for ch in w) + (len(w) - 1)
    m = np.zeros((9, cols), bool); x = 0
    for ch in w:
        g = np.array([[c == '#' for c in row] for row in G[ch]]); m[:, x:x+g.shape[1]] = g; x += g.shape[1] + 1
    return m

words = [word_mask(w) for w in lines]
Wu = max(m.shape[1] for m in words); Hu = 9 * len(words) + (len(words) - 1)
unit = np.zeros((Hu, Wu), bool)
for i, m in enumerate(words):
    x0 = (Wu - m.shape[1]) // 2; unit[i*10:i*10+9, x0:x0+m.shape[1]] = m
fill = np.kron(unit, np.ones((U, U), bool))
# row-within-letter (0..9*U) for shading
rowpos = np.tile(np.arange(9*U + U)[:, None], (len(words), fill.shape[1]))[:fill.shape[0]] % (10*U)

pad = 6
H, W = fill.shape[0] + 2*pad, fill.shape[1] + 2*pad
F = np.zeros((H, W), bool); F[pad:-pad, pad:-pad] = fill
R = np.zeros((H, W), int); R[pad:-pad, pad:-pad] = rowpos
def dil(m, r):
    o = m.copy()
    for _ in range(r):
        n = o.copy(); n[1:] |= o[:-1]; n[:-1] |= o[1:]; n[:, 1:] |= o[:, :-1]; n[:, :-1] |= o[:, 1:]
        n[1:, 1:] |= o[:-1, :-1]; n[:-1, :-1] |= o[1:, 1:]; n[1:, :-1] |= o[:-1, 1:]; n[:-1, 1:] |= o[1:, :-1]
        o = n
    return o
back = dil(F, U)                                  # merged dark backdrop (SUPER PUFF's thick outline)
shadow = np.zeros_like(back); shadow[2:, :] = back[:-2, :]
img = np.zeros((H, W, 4), np.uint8)
img[shadow & ~back] = (150, 120, 110, 255)        # faint lighter drop line under the blob
img[back] = (98, 69, 62, 255)
base = np.array([180, 114, 100]); light = np.array([196, 128, 112]); dark = np.array([156, 96, 84])
rng = np.random.default_rng(1)
col = np.where((R < 4*U)[..., None], light, base)
col = np.where((R >= 8*U + 2)[..., None], dark, col)
col = col + rng.integers(-3, 4, (H, W, 1))
img[F, :3] = np.clip(col[F], 0, 255); img[F, 3] = 255
o = Image.fromarray(img, 'RGBA'); o = o.crop(o.getbbox()); o.save(out_path); print(o.size)
