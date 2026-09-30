"""Hold-to-confirm ring ("doughnut"): a round progress ring + its dark border ring.

Both are white masks (tinted in the game): circle.png is the ring that fills up,
circleborder.png sits behind it, a little wider, so it shows as a thin outline on both
sides. Drawn at 64x64 as real circles (the old 32x32 ones were lumpy and chunky).
    -> textures/menus/circle.png, textures/menus/circleborder.png
"""
import os
import numpy as np
from PIL import Image
from hires import PROJ

N = 64
SS = 8                      # supersampling for clean pixel edges
R_OUT, R_IN = 27.0, 20.5    # the ring that fills up
BORDER = 4.5                # outline thickness on each side (old 32px ring: ~2x this)


def ring(r_in, r_out):
    y, x = np.mgrid[0:N * SS, 0:N * SS].astype(np.float32)
    c = N * SS / 2.0
    d = np.hypot(x + 0.5 - c, y + 0.5 - c) / SS
    m = ((d >= r_in) & (d <= r_out)).astype(np.float32)
    cover = m.reshape(N, SS, N, SS).mean(axis=(1, 3))
    a = np.where(cover >= 0.5, 255, 0).astype(np.uint8)      # crisp pixel edge
    img = np.zeros((N, N, 4), np.uint8)
    img[..., :3] = 255
    img[..., 3] = a
    return Image.fromarray(img, 'RGBA')


if __name__ == '__main__':
    menus = os.path.join(PROJ, 'menus')
    ring(R_IN, R_OUT).save(os.path.join(menus, 'circle.png'))
    ring(R_IN - BORDER, R_OUT + BORDER).save(os.path.join(menus, 'circleborder.png'))
    print('ok')
