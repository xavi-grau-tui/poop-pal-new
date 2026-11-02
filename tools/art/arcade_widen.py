"""The Arcade v7 (final_c) wider and taller (the user, 2026-11-02: a bigger screen for the spirit,
the sides were empty): no rescaling, its own pixels repeated in plain places. Above the deck, columns
70 and 149 (the sign's plain ends, the open screen) are repeated W/2 times each; the deck and base
stay as they are (wider, the controls would go under the trays; the pillars meet the deck behind
the trays, so the seam doesn't show); then row 90 (the
straight pillars beside the screen) H times; all centred again (the art moved up H/2 rows: it filled
rows 7-211). The trays (their own layer, at the canvas' edges) stay put but for the rows; the inside
gets the same width and height in its plain middle. Writes docs/mockups/hokora_homes/v7/arcade_cabinet/
final_c_wide/ (front, trays, inside, guide, icon), which homes_install.py installs.

    .venv/bin/python tools/art/arcade_widen.py
"""
import os
import shutil
import numpy as np
from PIL import Image

SRC = "docs/mockups/hokora_homes/v7/arcade_cabinet/final_c/"
OUT = "docs/mockups/hokora_homes/v7/arcade_cabinet/final_c_wide/"
W, H = 20, 12                       # (columns and rows added)
DECK = 146                          # (the first row of the deck)
ROW = 90


def rgba(name):
    return np.array(Image.open(SRC + name).convert("RGBA"))


def widen(a, cuts):
    """Repeat each cut column W/2 times, then shift back W/2 columns: the middle stays put."""
    out = a
    for x in sorted(cuts, reverse=True):
        out = np.concatenate([out[:, :x + 1]] + [out[:, x:x + 1]] * (W // 2) + [out[:, x + 1:]], axis=1)
    return out[:, W // 2:W // 2 + a.shape[1]]


def taller(a, row):
    out = np.concatenate([a[:row + 1]] + [a[row:row + 1]] * H + [a[row + 1:]], axis=0)
    return out[H // 2:H // 2 + a.shape[0]]


def shift_rows(a):                  # (what isn't stretched: only the rows)
    return taller(a, ROW)


os.makedirs(OUT, exist_ok=True)
front = rgba("front.png")
front = np.concatenate([widen(front[:DECK], [70, 149]), front[DECK:]], axis=0)
Image.fromarray(taller(front, ROW)).save(OUT + "front.png")
Image.fromarray(shift_rows(rgba("trays.png"))).save(OUT + "trays.png")
inside = rgba("inside.png")
Image.fromarray(taller(widen(inside, [110]), ROW + 16)).save(OUT + "inside.png")
guide = rgba("guide.png")                  # (its marks moved with what they mark)
g = np.zeros_like(guide)
for y, x in zip(*np.where(guide[..., 3] > 0)):
    nx = x if y >= DECK else (x - W // 2 if x < 70 else (x + W // 2 if x > 149 else x))
    ny = y + H // 2 if y > ROW else y - H // 2
    g[ny, nx] = guide[y, x]
Image.fromarray(g).save(OUT + "guide.png")
shutil.copy(SRC + "icon.png", OUT + "icon.png")
print("done")
