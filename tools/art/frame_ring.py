"""The inner border ring of a menu frame (diapositive*.png): the frame's own pixels within RING px
of its orange panel (and in the panel's box, corners included), everything else transparent. Laid over things that slide inside the panel
(the food menu's countdown shutter) so they look like they're behind the frame.

    <python with Pillow + numpy> tools/art/frame_ring.py textures/menus/diapositive1.png textures/menus/diapositive1_ring.png
"""
import sys
import numpy as np
from PIL import Image

RING = 8
BOX = 6
src, dst = sys.argv[1], sys.argv[2]
a = np.asarray(Image.open(src).convert("RGBA")).copy()
r, g, b, al = (a[..., i].astype(int) for i in range(4))
panel = (al > 200) & (r > 150) & (r - b > 60)
near = panel.copy()
for _ in range(RING):                       # grow the panel by RING px (8-neighbour steps)
    n = near.copy()
    n[1:] |= near[:-1]; n[:-1] |= near[1:]; n[:, 1:] |= near[:, :-1]; n[:, :-1] |= near[:, 1:]
    n[1:, 1:] |= near[:-1, :-1]; n[:-1, :-1] |= near[1:, 1:]; n[1:, :-1] |= near[:-1, 1:]; n[:-1, 1:] |= near[1:, :-1]
    near = n
keep = near & ~panel
# and the panel's whole box (grown BOX px), minus the panel: so a rectangle sliding inside it
# (the shutter) never pokes its square tips out past the rounded corners
ys, xs = np.where(panel)
box = np.zeros_like(panel)
box[ys.min() - BOX:ys.max() + BOX + 1, xs.min() - BOX:xs.max() + BOX + 1] = True
keep |= box & ~panel & (al > 0)
a[~keep] = (0, 0, 0, 0)
Image.fromarray(a, "RGBA").save(dst)
print(dst, int(keep.sum()), "px kept")
