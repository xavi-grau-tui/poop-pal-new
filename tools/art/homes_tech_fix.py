"""Our tech pass on a designer's v5 home, when it's quicker than a new round (the user, 2026-10-31):
docs/mockups/hokora_homes/v5/<home>/ -> docs/mockups/hokora_homes/v5_tech/<home>/ (homes_install.py
prefers v5_tech). The designer's files stay untouched.

Tree Hollow:
  - front / inside cut along the hollow's real edge (not a rectangle): the hollow is found by its
    dark red-brown colours, flood-filled from its middle (the outline stops it); everything else
    (trunk, rim, ledges, every root) is front. The inside is the hollow alone, its edge colours
    spread outwards so it can slide with the tilt without showing a gap.
  - the stump table on a log: a short shaded cylinder from under its top to the floor (row 162 of
    220) instead of the thin legs.
Run: .venv/bin/python tools/art/homes_tech_fix.py
"""
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = "docs/mockups/hokora_homes/v5/"
OUT = "docs/mockups/hokora_homes/v5_tech/"


def rgba(p):
    return np.array(Image.open(p).convert("RGBA"))


def tree_hollow():
    d, o = SRC + "tree_hollow/", OUT + "tree_hollow/"
    fr, ins = rgba(d + "front.png"), rgba(d + "inside.png")
    whole = fr.copy()
    m = (ins[..., 3] > 0) & (fr[..., 3] == 0)
    whole[m] = ins[m]
    rgb = whole[..., :3].astype(int)
    lum = rgb.mean(-1)
    r, g = rgb[..., 0], rgb[..., 1]
    hollowish = (whole[..., 3] > 0) & (lum > 18) & (lum < 130) & (r > g * 1.3)
    lab, _ = ndimage.label(hollowish)
    hol = ndimage.binary_fill_holes(ndimage.binary_closing(lab == lab[110, 110], iterations=2))
    front = whole.copy()
    front[hol] = 0
    # the inside: the hollow, its colours carried 16 px past its edge (the tilt's slide)
    idx = ndimage.distance_transform_edt(~hol, return_distances=False, return_indices=True)
    near = whole[idx[0], idx[1]]
    grow = ndimage.binary_dilation(hol, iterations=16)
    inside = np.zeros_like(whole)
    inside[grow] = near[grow]
    inside[grow, 3] = 255
    Image.fromarray(front).save(o + "front.png")
    Image.fromarray(inside).save(o + "inside.png")
    Image.fromarray(np.where(hol[..., None], [255, 255, 255, 255], [0, 0, 0, 0]).astype(np.uint8)).save(o + "hollow_mask.png")
    # the table on a log
    t = rgba(d + "table.png")
    t[155:] = 0                                   # (the thin legs)
    OUTL, LIGHT, MID, DARK = (40, 2, 21), (249, 185, 135), (214, 150, 108), (166, 104, 78)
    log = np.zeros_like(t)
    x0, x1, y0, y1 = 97, 126, 150, 162
    for y in range(y0, y1 + 1):
        flare = 2 if y >= y1 - 2 else (1 if y >= y1 - 4 else 0)
        a, b = x0 - flare, x1 + flare
        for x in range(a, b + 1):
            u = (x - a) / max(1, b - a)
            c = LIGHT if u < 0.3 else (MID if u < 0.72 else DARK)
            if (x - x0) % 7 == 3 and 0.15 < u < 0.85:
                c = DARK if c != DARK else OUTL     # (bark lines)
            log[y, x] = c + (255,)
        for x in (a, a + 1, b - 1, b):
            log[y, x] = OUTL + (255,)
    log[y1 - 1:y1 + 1, x0 - 2:x1 + 3] = OUTL + (255,)
    out = log.copy()
    on = t[..., 3] > 0
    out[on] = t[on]                               # (the top over its log)
    Image.fromarray(out).save(o + "table.png")
    for n in ["guide.png", "icon.png"]:
        Image.open(d + n).save(o + n)


tree_hollow()
print("ok")
