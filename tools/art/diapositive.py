"""Softer menu frames ("diapositives"): same frame, finer edges.

The original frames are drawn with ~5-texel art pixels (about 12 screen px at their x2.2
scale), chunkier than the rest of the console. This keeps everything that matters (outer
size, panel position and its wood texture, colours) and only redraws the outlines and
rounded corners on a finer grid, with thinner lines.

    python3 diapositive.py        # textures/menus/diapositive{1,2,3}.png (originals kept
                                  # the first time as out/diapositive{n}_orig.png)
"""
import os, shutil
import numpy as np
from PIL import Image

from hires import PROJ, SCR

GRID = 3           # texels per new art pixel (was ~5)
LINE = 6           # outline thickness in texels (was ~10)
R_OUT = 44         # outer corner radius (as the original)
R_PANEL = 26       # panel corner radius


def runs(line):
    """[(start, length, rgba)] of colour runs along a 1D pixel line."""
    out, start = [], 0
    for i in range(1, len(line) + 1):
        if i == len(line) or np.abs(line[i].astype(int) - line[i - 1].astype(int)).sum() > 40:
            out.append((start, i - start, tuple(int(v) for v in line[start])))
            start = i
    return out


def geometry(a):
    """Outer box, panel box and the three colours, read from the original frame."""
    H, W = a.shape[:2]
    ys, xs = np.nonzero(a[..., 3] > 128)
    outer = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    mid = runs(a[H // 2])
    solid = [r for r in mid if r[2][3] > 128]
    outline, body, inner = solid[0], solid[1], solid[2]
    px0 = inner[0] + inner[1]
    right = runs(a[H // 2][::-1])
    rs = [r for r in right if r[2][3] > 128]
    px1 = W - (rs[2][0] + rs[2][1])
    col = runs(a[:, W // 2])
    cs = [r for r in col if r[2][3] > 128]
    py0 = cs[2][0] + cs[2][1]
    colb = runs(a[::-1, W // 2])
    cbs = [r for r in colb if r[2][3] > 128]
    py1 = H - (cbs[2][0] + cbs[2][1])
    return outer, (px0, py0, px1, py1), outline[2], body[2], inner[2]


def depth(x, y, box, r, g):
    """How far (texels) a point is inside a rounded box, measured on a g-texel grid so the
    curves step in g-sized pixels while straight edges stay exactly on the box."""
    x0, y0, x1, y1 = box
    ex = np.minimum(x - x0, x1 - 1 - x)
    ey = np.minimum(y - y0, y1 - 1 - y)
    ex = np.floor(ex / g) * g + g / 2.0
    ey = np.floor(ey / g) * g + g / 2.0
    corner = (ex < r) & (ey < r)
    d = np.minimum(ex, ey)
    dc = r - np.hypot(r - ex, r - ey)
    return np.where(corner, dc, d)


def soften(src, dst):
    a = np.asarray(Image.open(src).convert('RGBA')).copy()
    H, W = a.shape[:2]
    outer, panel, c_out, c_body, c_in = geometry(a)
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    d_outer = depth(x, y, outer, R_OUT, GRID)
    ring = (panel[0] - LINE, panel[1] - LINE, panel[2] + LINE, panel[3] + LINE)
    d_ring = depth(x, y, ring, R_PANEL + LINE, GRID)
    d_panel = depth(x, y, panel, R_PANEL, GRID)

    out = np.zeros_like(a)
    inside = d_outer >= 0
    out[inside] = c_body
    out[inside & (d_outer < LINE)] = c_out
    out[(d_ring >= 0) & (d_panel < 0)] = c_in
    # panel: the original pixels; where the new rounder corner reaches into the old
    # outline, borrow the texture from a little further in
    pm = d_panel >= 0
    old = a.copy()
    cx0, cy0, cx1, cy1 = panel
    xi = np.clip(x, cx0 + 14, cx1 - 15).astype(int)
    yi = np.clip(y, cy0 + 1, cy1 - 2).astype(int)
    orig_panel = np.abs(old[..., :3].astype(int) - np.array(c_in[:3])).sum(-1) > 60
    use_old = pm & orig_panel & (x >= cx0) & (x < cx1) & (y >= cy0) & (y < cy1)
    out[use_old] = old[use_old]
    fill = pm & ~use_old
    out[fill] = old[yi[fill], xi[fill]]
    out[..., 3] = np.where(inside, 255, 0)
    Image.fromarray(out, 'RGBA').save(dst)
    return a, out


if __name__ == '__main__':
    prev = []
    for n in (1, 2, 3):
        path = os.path.join(PROJ, 'menus', f'diapositive{n}.png')
        orig = os.path.join(SCR, f'diapositive{n}_orig.png')
        if not os.path.exists(orig):
            shutil.copy(path, orig)                 # keep the hand-made original
        a, b = soften(orig, path)
        prev.append((a, b))
    # preview: original vs soft, full frames + zoomed corners
    W = 402
    sheet = Image.new('RGBA', (W * 3 * 2 + 40, 394 + 340), (200, 200, 200, 255))
    for i, (a, b) in enumerate(prev):
        sheet.alpha_composite(Image.fromarray(a), (i * (2 * W + 20), 0))
        sheet.alpha_composite(Image.fromarray(b), (i * (2 * W + 20) + W, 0))
        sheet.alpha_composite(Image.fromarray(a).crop((0, 0, 110, 110)).resize((330, 330), Image.NEAREST), (i * (2 * W + 20), 400))
        sheet.alpha_composite(Image.fromarray(b).crop((0, 0, 110, 110)).resize((330, 330), Image.NEAREST), (i * (2 * W + 20) + W, 400))
    sheet.save(os.path.join(SCR, 'diapositive_preview.png'))
    print('ok')
