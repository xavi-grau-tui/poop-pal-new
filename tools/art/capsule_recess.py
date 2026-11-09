"""The Capsule's side windows in depth (the user, 2026-11-08: "the darker gray part of the front is
supposed to be behind the lantern, it's a matter of perspective"): its front split in two, so the
lanterns hang inside the pod, behind the white frame but in front of the windows' grey inner walls.

  textures/pet/homes/capsule_apartment/recess.png       the side windows' inner walls and ceiling
                                                        (with the lanterns' hook rings), drawn behind
                                                        the shelf objects and the lanterns
  textures/pet/homes/capsule_apartment/front_frame.png  the front without them, drawn over the lanterns
                                                        (shrine.gd takes it instead of front.png)

How: from the middle of each side window's hole, a fill over the clear and mid-grey pixels and the dark
lines inside the window (not the white frame's light shades nor its own edge line, the dark pixels
touching it), kept inside a box round the window; the islands it
surrounds (the hook rings and their outlines) join it.
The left window's hook ring is painted out of the recess (RING: its box, filled from the same rows
RING_FROM px to the right; the right window never had one), so the lanterns hang by their own loops
from the top of the windows (the user, 2026-11-09: "higher, getting to the top of the glass").
front.png stays as it is (the cards and homes_install.py use it). Rerun after homes_install.py.

    .venv/bin/python tools/art/capsule_recess.py
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
D = ROOT / "textures/pet/homes/capsule_apartment"
SEEDS = [(185, 400), (740, 400)]       # (x, y) in each side window's hole
BOXES = [(90, 170, 300, 700), (625, 170, 835, 700)]   # (x0, y0, x1, y1): each side window, the fill kept inside
OUTLINE_LUM = 80                       # darker than this (and opaque): the outline, where the fill stops
FRAME_LINE = 5                         # an outline this close to the white frame is its edge; others are the walls'
RING = (165, 241, 206, 290)             # (x0, y0, x1, y1): the left window's hook ring and its outline
RING_FROM = 45                         # filled from the ceiling this far right of it, row by row
WALL_LUM = 180                         # the inner walls' greys are darker than this; the white frame's shades lighter


def main():
    f = np.array(Image.open(D / "front.png").convert("RGBA"))
    lum = f[..., :3].astype(int).sum(-1) / 3
    outline = (f[..., 3] > 0) & (lum < OUTLINE_LUM)
    white = (f[..., 3] > 0) & (lum >= WALL_LUM)
    frame_line = outline & ndimage.binary_dilation(white, iterations=FRAME_LINE)   # (the frame's own edge)
    region = np.zeros(outline.shape, bool)
    for (x, y), (x0, y0, x1, y1) in zip(SEEDS, BOXES):
        assert f[y, x, 3] == 0, f"seed {x, y} is not in a hole"
        box = np.zeros(outline.shape, bool)
        box[y0:y1, x0:x1] = True
        lab, _ = ndimage.label(((f[..., 3] == 0) | ((lum < WALL_LUM) & ~frame_line)) & box)
        region |= lab == lab[y, x]
    region = ndimage.binary_fill_holes(region)
    recess = region & (f[..., 3] > 0)
    back = f.copy()
    back[~recess] = 0
    x0, y0, x1, y1 = RING
    keep = recess[y0:y1, x0:x1].copy()
    back[y0:y1, x0:x1] = back[y0:y1, x0 + RING_FROM:x1 + RING_FROM]
    back[y0:y1, x0:x1][~keep] = 0
    frame = f.copy()
    frame[recess] = 0
    Image.fromarray(back).save(D / "recess.png")
    Image.fromarray(frame).save(D / "front_frame.png")
    ys, xs = np.nonzero(recess)
    print(f"recess: {recess.sum()} px, x {xs.min()}-{xs.max()}, y {ys.min()}-{ys.max()}")


if __name__ == "__main__":
    main()
