"""RC Prix Lagoon, round 3: paint guides for the currents and the sandbar jumps. Run from the repo root:

    <python with Pillow + numpy> tools/art/rcprix_lagoon_round3_guides.py

The sizes come from rc_racer.gd (one game px = 2 world px):
  current   PAD_LEN 64 world each side of its middle: 64 game px along the flow; its arrows flow within
            half_w - 30 of the centre: 86 game px across on the wide channel (levels 1-4), 76 on the narrow
  jump      RAMP_LEN 72 world of floating ramp, then GAP_LEN 120 world of sandbar: 36 + 60 game px along;
            the ramp spans the channel (half_w: 116 / 106 game px across), the sandbar the channel and its
            shallows (+ SHORE_PAINT 52 world each side: 168 / 158 game px)
Writes docs/mockups/rcprix_lagoon/round3_guides/<piece>_<dir>_guide_4x.png for dir e, n, w, s (the flow /
the boat's way), each with the wide (outer line) and narrow (inner line) channel marked, and pink corner marks."""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/mockups/rcprix_lagoon/round3_guides"
K = 4
WATER = (193, 118, 128)
SHALLOW = (233, 168, 143)
INK = (40, 30, 40)
PINK = (255, 0, 255)
RAMP_C = (176, 122, 74)
SAND_C = (253, 216, 123)


def current():
    """Flowing east: 64 along x, 86 across y (the narrow 76 marked inside)"""
    W, H = 64, 86
    im = np.zeros((H, W, 3), np.uint8)
    im[:] = WATER
    im[(H - 76) // 2:(H + 76) // 2, :] = (205, 128, 136)       # the narrow channel's reach
    for x in range(8, W, 16):                                    # a hint of the flow, east
        for d in range(6):
            im[H // 2 - 6 + d, x + d] = INK
            im[H // 2 + 6 - d, x + d] = INK
    return im


def jump():
    """The boat going east: 36 of ramp then 60 of sandbar along x; across y the sandbar spans 168
    (wide) / 158 (narrow), the ramp the channel 116 / 106"""
    W, H = 96, 168
    im = np.zeros((H, W, 3), np.uint8)
    im[:] = WATER
    im[:26, :] = SHALLOW                                         # the shallows (wide channel)
    im[H - 26:, :] = SHALLOW
    cy = H // 2
    im[cy - 58:cy + 58, :36] = RAMP_C                            # the ramp, wide
    im[cy - 53:cy + 53, :36] = (196, 140, 90)                    # ...narrow
    im[:, 36:] = SAND_C                                          # the sandbar, wide
    im[5:H - 5, 36:] = (240, 204, 120)                           # ...narrow
    im[:, 35] = INK                                              # where the ramp meets the sandbar
    return im


def write(name, im):
    for d, rot in (("e", 0), ("n", 1), ("w", 2), ("s", 3)):
        a = np.rot90(im, rot).copy()
        a[0, 0] = a[0, -1] = a[-1, 0] = a[-1, -1] = PINK
        Image.fromarray(a).resize((a.shape[1] * K, a.shape[0] * K), Image.NEAREST).save(OUT / f"{name}_{d}_guide_4x.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    write("current", current())
    write("jump", jump())
    print("written to", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
