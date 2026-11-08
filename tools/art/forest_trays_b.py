"""The Forest Hokora with its trays lowered (the designer's final_b, 2026-11-04: the planks' top at row 158,
the table's) and its greens a little paler (the user: "all greens could be slightly paler"):
docs/mockups/hokora_homes/v8/forest_hokora/final_b/ -> v8/forest_hokora/final_c/ (final_b kept as delivered)

  - every green pixel (the moss, ivy and their dark lines; hue GREEN_H, saturation over GREEN_S) of the
    front, trays and inside: its saturation x PALE_S, its value PALE_V of the way to white
  - the front's stray pieces (bits of the old trays' outline left beside the pillars) cleared
  - materials.png for the Colours: final/'s where the front is unchanged; a changed pixel moss if green,
    else stone if grey, else wood, its lines the material beside them, the outline none (as forest_v8.py)
  - bell, beads, icon from final/ as they are

Run: .venv/bin/python tools/art/forest_trays_b.py [--pale-s 0.8] [--pale-v 0.15]
"""
import argparse
import colorsys
import os
import shutil
import numpy as np
from PIL import Image
from scipy import ndimage

D = "docs/mockups/hokora_homes/v8/forest_hokora/"
A, B, OUT = D + "final/", D + "final_b/", D + "final_c/"
GREEN_H, GREEN_S = (50, 170), 0.15
GREY_S = 0.18                          # (a changed pixel this unsaturated: stone)
LINE_L = 48                            # (a pixel this dark (luma): a line, as forest_v8.py)

ap = argparse.ArgumentParser()
ap.add_argument("--pale-s", type=float, default=0.8, help="the greens' saturation x this")
ap.add_argument("--pale-v", type=float, default=0.15, help="the greens' value this far towards white")
args = ap.parse_args()
os.makedirs(OUT, exist_ok=True)


def hsv_of(a):
    return np.array([colorsys.rgb_to_hsv(*p) for p in a[..., :3].reshape(-1, 3) / 255]).reshape(a.shape[:2] + (3,))


def greens(a):
    h = hsv_of(a)
    return (a[..., 3] > 0) & (h[..., 0] * 360 >= GREEN_H[0]) & (h[..., 0] * 360 < GREEN_H[1]) & (h[..., 1] >= GREEN_S), h


def paler(a):
    a = a.copy()
    g, h = greens(a)
    for y, x in zip(*np.where(g)):
        hh, s, v = h[y, x]
        a[y, x, :3] = np.round(np.array(colorsys.hsv_to_rgb(hh, s * args.pale_s, v + (1 - v) * args.pale_v)) * 255)
    return a


old = np.array(Image.open(A + "front.png").convert("RGBA")).astype(int)
new = np.array(Image.open(B + "front.png").convert("RGBA")).astype(int)
op = new[..., 3] > 0
lab, n = ndimage.label(op)
keep = lab == (np.bincount(lab.ravel())[1:].argmax() + 1)
print("stray pixels cleared:", int((op & ~keep).sum()))
new[~keep] = 0
op = keep

ch = (old != new).any(2)
g, h = greens(new)
L = new[..., :3] @ [0.299, 0.587, 0.114]
edge = op & ~ndimage.binary_erosion(op)
m_old = np.array(Image.open(A + "materials.png").convert("RGBA"))
kind = np.where(m_old[..., 3] == 0, 0, np.where(m_old[..., 0] > 0, 3, np.where(m_old[..., 1] > 0, 4,
                np.where(m_old[..., 2] > 0, 1, 2))))   # (1 stone, 2 wood, 3 roof, 4 moss)
line = ch & op & ~edge & (L < LINE_L)
kind[ch] = np.where(g, 4, np.where(h[..., 1] < GREY_S, 1, 2))[ch]
kind[(ch & ~op) | edge | line] = 0
iy, ix = ndimage.distance_transform_edt(kind == 0, return_distances=False, return_indices=True)
kind[line] = kind[iy, ix][line]
mask = np.zeros((220, 220, 4), np.uint8)
mask[kind == 3, 0] = mask[kind == 4, 1] = mask[kind == 1, 2] = 255
mask[..., 3] = np.where(kind > 0, 255, 0)
Image.fromarray(mask).save(OUT + "materials.png")

Image.fromarray(paler(new).astype(np.uint8)).save(OUT + "front.png")
for f, src in (("trays.png", B), ("inside.png", A)):
    Image.fromarray(paler(np.array(Image.open(src + f).convert("RGBA")).astype(int)).astype(np.uint8)).save(OUT + f)
for f in ("bell.png", "bead_1.png", "bead_2.png", "icon.png"):
    shutil.copy(A + f, OUT + f)
print("greens made paler:", int(greens(new)[0].sum()), "front px ->", OUT)
