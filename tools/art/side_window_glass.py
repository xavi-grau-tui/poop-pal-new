"""A home's side-window glass over the whole window inside its frame (the user, 2026-11-02: the glass
should cover all of the Capsule's side windows, the ceiling band and the lanterns' hooks too, not just
the cut): each row's run between the frame's white (the outer frame, the middle opening's arch) through
the window's middle, from the frame above the band to the frame below the shelf, holes filled, over the front. Its tint and highlight lines are the designer's
glass.png's: its pane colour fills the rest. Writes textures/pet/homes/<home>/glass.png on the 925
canvas (Shrine draws it over the front and the lanterns for a home with side windows). Run after
tools/art/homes_install.py:

    .venv/bin/python tools/art/side_window_glass.py
"""
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = "docs/mockups/hokora_homes/"
HOMES = {"capsule_apartment": ("v6_5b/", [50, 170])}     # (its delivery, a column through each window)


for home, (ver, cols) in HOMES.items():
    d = SRC + ver + home + "/"
    front = np.array(Image.open(d + "front.png").convert("RGBA")).astype(int)
    glass = np.array(Image.open(d + "glass.png").convert("RGBA"))
    a = front[..., 3] > 0
    white = a & (front[..., :3].mean(-1) > 185)
    pane = np.zeros(a.shape, bool)
    for x in cols:
        rows = np.where(glass[:, x, 3] > 0)[0]
        y = rows.min()
        while y > 0 and not white[y - 1, x]:          # (up through the band to the frame)
            y -= 1
        yb = rows.max()
        while yb < a.shape[0] - 1 and not white[yb + 1, x]:   # (down past the shelf to the frame)
            yb += 1
        for yy in range(y, yb + 1):
            if white[yy, x]:
                continue
            x0 = x
            while x0 > 0 and not white[yy, x0 - 1]:
                x0 -= 1
            x1 = x
            while x1 < a.shape[1] - 1 and not white[yy, x1 + 1]:
                x1 += 1
            if x1 - x0 >= 40:                           # (a seam in the white: the row above's edges)
                x0, x1 = last
            last = (x0, x1)
            pane[yy, x0:x1 + 1] = True
    pane = ndimage.binary_fill_holes(pane)
    tint = glass[(glass[..., 3] > 0)]
    base = np.median(tint, axis=0).astype(np.uint8)          # (the pane's own colour)
    out = np.zeros_like(glass)
    out[pane] = base
    lines = (glass[..., 3] > 0) & (np.abs(glass.astype(int) - base.astype(int)).sum(-1) > 12)
    out[lines] = glass[lines]                               # (its highlight lines as drawn)
    Image.fromarray(out, "RGBA").resize((925, 925), Image.NEAREST).save("textures/pet/homes/%s/glass.png" % home)
    ys, xs = np.where(pane)
    print(home, "pane", pane.sum(), "px, rows", ys.min(), ys.max(), "base", base)
