"""Makes the console front symmetric: its left edge becomes the mirror image of its right.

    <python with Pillow + numpy> tools/design/console_symmetry.py <console_only.png>

The front's art (frame3 / mid / top / bottom) has a shaded side strip and a slightly
thicker screen frame on the right only, so the screen sat ~1 px left of centre with less
beige on the right. Instead of repainting those textures, this mirrors the rendered right
edge onto the left as an overlay (textures/console/front_left_mirror.png, screen-space,
placed by MenuManager): the outer case edge for the full height, and the beige panel +
brown screen frame for the rows of the panel only.

Input: a 1080x1920 capture of the Console node alone on a transparent background."""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
W = 1080
EDGE = 37                 # outer columns mirrored for the full height (case edge + shaded strip)
PANEL = 80                # columns mirrored within the screen panel's rows (beige panel + frame)
PANEL_ROWS = (570, 1601)  # the beige panel around the screen spans ~584..1587
CLEAR = (77, 77, 77)      # the default clear colour behind the device


def main(capture):
    a = np.array(Image.open(capture).convert("RGBA"))
    out = np.zeros((a.shape[0], PANEL, 4), np.uint8)
    for x in range(PANEL):
        src = W - 1 - x
        if x < EDGE:
            out[:, x] = a[:, src]
        else:
            out[PANEL_ROWS[0]:PANEL_ROWS[1], x] = a[PANEL_ROWS[0]:PANEL_ROWS[1], src]
    # the device sits 1 px left in the scene, so the right's last column is half background:
    # flatten that column over the clear colour so the left's outermost pixel matches it
    col = out[:, 0].astype(float)
    alpha = col[:, 3:4] / 255.0
    out[:, 0, :3] = (col[:, :3] * alpha + np.array(CLEAR) * (1 - alpha)).astype(np.uint8)
    out[:, 0, 3] = 255
    Image.fromarray(out, "RGBA").save(ROOT / "textures" / "console" / "front_left_mirror.png")
    print("wrote front_left_mirror.png")


if __name__ == "__main__":
    main(sys.argv[1])
