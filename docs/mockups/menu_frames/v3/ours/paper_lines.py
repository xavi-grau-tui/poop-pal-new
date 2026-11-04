# the paper study on the template: its washi and clouds sampled (slide_paperstudy.png), its lines redrawn
# 1 art pixel wide where the study has them (the vermilion edge, the window's ink line, light core, bevel)
import sys
import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.cluster.vq import kmeans2
SP = sys.argv[1]
B = 'docs/mockups/menu_frames/v2_brief/'
outer = np.array(Image.open(B + 'mask_outer.png')) > 0
opening = np.array(Image.open(B + 'mask_opening.png')) > 0
a = np.array(Image.open(SP + '/slide_paperstudy.png')).astype(int)
ART = 4
d_out = ndimage.distance_transform_edt(outer)
d_open = ndimage.distance_transform_edt(~opening)
d_cut = ndimage.distance_transform_cdt(~opening, metric='taxicab').astype(float)   # (the cut's corners at 45 degrees, as the study)
card = outer & ~opening
H, W = outer.shape
yy, xx = np.mgrid[0:H, 0:W]
# the washi: the sampled fill in its three tones (no in-between specks)
fill = card & (d_out > ART) & (ndimage.distance_transform_cdt(~opening, metric='taxicab') > 3 * ART + 2)
BASE, CLOUD = np.array((252, 232, 198)), np.array((240, 213, 177))   # (the study's washi and its clouds)
px = a[fill][:, :3]
paperish = (px[:, 0] - px[:, 2] < 90)                 # (the red edge's pieces: washi)
L = px @ [0.299, 0.587, 0.114]
tone = np.where(paperish & (L < (BASE @ [0.299, 0.587, 0.114] + CLOUD @ [0.299, 0.587, 0.114]) / 2), 1, 0)
cb = np.array([BASE, CLOUD], float)
out = a.copy()
out[fill, :3] = cb[tone].astype(int)
cy, cx = (yy - 1) // 4, (xx - 3) // 4
# each art cell one tone (its middle pixel's)
my = np.clip(cy * 4 + 3, 0, H - 1); mx = np.clip(cx * 4 + 5, 0, W - 1)
ok = fill[my, mx]
out[fill & ok] = out[my, mx][fill & ok]
out[fill & ~ok, :3] = np.round(BASE).astype(int)
# which way a window side faces: top/left sides get the light core, bottom/right the bevel's shade
gy, gx = np.gradient(ndimage.gaussian_filter(d_open, 3))
lit = (gx + gy) < 0          # (outward normal pointing up-left: the top and left sides)
VERMILION, INK, CORE, LIGHT, TAN = (192, 64, 42), (122, 74, 66), (255, 248, 230), (247, 232, 205), (221, 188, 148)
cutband = card & (d_open > ART)
out[cutband & (d_cut > 2 * ART + 2) & (d_cut <= 3 * ART + 2), :3] = INK
out[cutband & (d_cut <= 2 * ART + 2), :3] = CORE
inner = card & (d_open <= ART)
out[inner & lit, :3] = LIGHT
out[inner & ~lit, :3] = TAN
out[card & (d_out <= ART), :3] = VERMILION
out[..., 3] = card * 255
out[~card] = 0
Image.fromarray(out.astype(np.uint8)).save(SP + '/slide_paperlines.png')
print('tones', np.round(cb).astype(int).tolist())
