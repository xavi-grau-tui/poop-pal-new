"""Our finishing pass on the designer's round-9 v2 ornament loops (the user, 2026-11-11: "leave
everything as polished as possible"), before they go into the game. The originals stay as they are;
the results are written next to them as <id>_N_ours.png.

  lucky cats (shelf_maneki, shelf_maneki_left, shelf_neon_cat_left), and the shishi-odoshi from
  the first pass (its frames 1-3 have the same stray lines above the bamboo)
      Around the new arm the thick dark sticker border (8 px, #1F0A1B) was cut away, leaving a notch,
      and lines of the old border stuck out. Here: the thin lines go (whatever the opaque mask loses
      to an opening, in pieces of 3+ px), then the border is grown back round the arm and the body
      (everything within 8 px of a coloured pixel, near the changed area only).
  koma tops (shelf_koma, shelf_koma_left)
      Frame 0 (today's, tilted) and frames 1-2 (upright) are different drawings, so the loop jumped.
      Frames 1 and 2 become the whole loop (frame 1 = the new still), without their stray dark
      dash and dots (STRAYS: boxes picked by eye at 6x, the dark pixels in them filled with the
      nearest colours round them; the thin band lines stay).

    .venv/bin/python tools/art/ornament_cleanup.py
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
A = ROOT / "docs/mockups/hokora_decor/anim"
CATS = {"shelf_maneki": "_v2", "shelf_maneki_left": "_v2", "shelf_neon_cat_left": "_v2",
        "shelf_shishi_odoshi": ""}          # (id: the delivery's file suffix)
TOPS = ["shelf_koma", "shelf_koma_left"]
BORDER = 8
BORDER_RGB = (31, 10, 27)
DARK = 70          # darker than this (max channel): outline/border
NEAR = 12          # the border is rebuilt this far round the changed area
STRAYS = {         # (x, y, w, h) in both frames 1 and 2
    "shelf_koma": [(46, 88, 12, 2), (60, 86, 2, 2), (90, 96, 2, 2)],
    "shelf_koma_left": [(104, 88, 6, 2), (54, 106, 2, 2), (58, 108, 2, 2), (118, 106, 2, 2)],
}


def disk(r):
    y, x = np.mgrid[-r:r + 1, -r:r + 1]
    return x * x + y * y <= r * r + 0.5


def load(d, i, v="_v2"):
    return np.array(Image.open(A / d / f"{d}_{i}{v}.png").convert("RGBA")).astype(int)


def save(img, d, i):
    Image.fromarray(img.astype(np.uint8)).save(A / d / f"{d}_{i}_ours.png")


def cat(d, v):
    f0 = load(d, 0, v)
    frames = [f0]
    i = 1
    while (A / d / f"{d}_{i}{v}.png").exists():
        frames.append(load(d, i, v)); i += 1
    save(f0, d, 0)
    for i, f in enumerate(frames[1:], 1):
        near = ndimage.binary_dilation((f != f0).any(-1), disk(NEAR))
        op = f[..., 3] > 0
        thin = op & ~ndimage.binary_opening(op, disk(2)) & near
        lab, n = ndimage.label(thin, np.ones((3, 3)))
        sizes = ndimage.sum(thin, lab, range(1, n + 1))
        for k, s in enumerate(sizes, 1):
            if s >= 3:
                f[lab == k] = 0
        op = f[..., 3] > 0
        col = op & (f[..., :3].max(-1) >= DARK)
        grow = ndimage.binary_dilation(col, disk(BORDER)) & ~op & near
        f[grow] = (*BORDER_RGB, 255)
        save(f, d, i)
        print(d, i, "lines off", int(sum(s for s in sizes if s >= 3)), "border back", int(grow.sum()))


def top(d):
    for out_i, i in enumerate((1, 2)):
        f = load(d, i)
        op = f[..., 3] > 0
        dark = op & (f[..., :3].max(-1) < DARK)
        islands = np.zeros_like(dark)
        for x, y, w, h in STRAYS[d]:
            islands[y:y + h, x:x + w] = dark[y:y + h, x:x + w]
        fixed = f.copy()
        good = op & ~islands & ~dark
        _, (iy, ix) = ndimage.distance_transform_edt(~good, return_indices=True)
        fixed[islands] = f[iy[islands], ix[islands]]
        save(fixed, d, out_i)
        print(d, i, "->", out_i, "dark islands filled", int(islands.sum()))


if __name__ == "__main__":
    for d, v in CATS.items():
        cat(d, v)
    for d in TOPS:
        top(d)
