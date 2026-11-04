# a v3 study fitted to the exact slide template: mapped piecewise (outer edge / window edge) so its
# window lands on the template's, each art cell (4 x 4 file px) its study block's commonest colour
import sys
import numpy as np
from PIL import Image
from scipy import ndimage
study, out_path = sys.argv[1], sys.argv[2]
SX = [float(v) for v in sys.argv[3].split(',')]   # (study x: outer left, window left, window right, outer right)
SY = [float(v) for v in sys.argv[4].split(',')]
REMOVE = [tuple(int(v) for v in b.split(',')) for b in sys.argv[5:]]   # (study boxes to paint out)
B = 'docs/mockups/menu_frames/v2_brief/'
outer = np.array(Image.open(B + 'mask_outer.png')) > 0
opening = np.array(Image.open(B + 'mask_opening.png')) > 0
TX, TY = [11, 51, 352, 392], [5, 43, 322, 390]     # (the template's: the mount's edges, the opening's)
s = np.array(Image.open(study).convert('RGBA')).astype(int)
for (x0, y0, x1, y1) in REMOVE:                     # (painted out with the paper round it)
    ringpx = np.concatenate([s[y0 - 12:y0 - 4, x0:x1].reshape(-1, 4), s[y1 + 4:y1 + 12, x0:x1].reshape(-1, 4),
                             s[y0:y1, x0 - 12:x0 - 4].reshape(-1, 4), s[y0:y1, x1 + 4:x1 + 12].reshape(-1, 4)])
    s[y0:y1, x0:x1] = np.median(ringpx, 0).astype(int)
H, W = outer.shape
res = np.zeros((H, W, 4), int)
def m(v, T, S):
    return np.interp(v, T, S)
for cy0 in range(1, H, 4):
    for cx0 in range(3 - 4, W, 4):
        ys, xs = slice(max(cy0, 0), min(cy0 + 4, H)), slice(max(cx0, 0), min(cx0 + 4, W))
        if not (outer[ys, xs] & ~opening[ys, xs]).any():
            continue
        a, b = m(max(cx0, 0), TX, SX), m(min(cx0 + 4, W), TX, SX)
        c, d = m(max(cy0, 0), TY, SY), m(min(cy0 + 4, H), TY, SY)
        blk = s[int(c):max(int(d), int(c) + 1), int(a):max(int(b), int(a) + 1)].reshape(-1, 4)
        op = blk[blk[:, 3] > 128]
        if not len(op):
            continue
        L = op[:, :3] @ [0.299, 0.587, 0.114]
        if (L < 70).mean() >= 0.4:                  # (mostly line: its line colour)
            col = np.median(op[L < 70][:, :3], 0)
        else:
            q = op[:, :3] // 12
            k = q[:, 0] * 10000 + q[:, 1] * 100 + q[:, 2]
            u, n = np.unique(k, return_counts=True)
            col = op[k == u[n.argmax()]][:, :3].mean(0)
        res[ys, xs, :3] = col
        res[ys, xs, 3] = 255
need = outer & ~opening
gap = need & (res[..., 3] == 0)                     # (cells the study left empty: their nearest neighbour's colour)
if gap.any():
    idx = ndimage.distance_transform_edt(~(res[..., 3] > 0), return_distances=False, return_indices=True)
    res[gap] = res[idx[0][gap], idx[1][gap]]
res[..., 3] = need * 255
res[~need] = 0
Image.fromarray(res.astype(np.uint8)).save(out_path)
print('ok', out_path)
