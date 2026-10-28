"""RC Prix: a painting or a generated study put on the game's pixel grid, for review. Run from the repo root:

    <python with Pillow + numpy> tools/art/rcprix_pixelate.py <in.png> <out.png> <width in game px> [colours]

Crops to what's opaque, scales to <width> game px with each game px the average of the area it covers (light
and shade kept, no blur past it), cuts the soft edge (alpha < 50% goes, the rest opaque), reduces to a small
palette (default 8) and drops lone pixels (one game px unlike all four neighbours takes their most common
colour). Writes <out.png> at 1x and <out>_4x.png next to it."""
import sys
from collections import Counter

import numpy as np
from PIL import Image


def main():
    src, out, width = sys.argv[1], sys.argv[2], int(sys.argv[3])
    colours = int(sys.argv[4]) if len(sys.argv) > 4 else 8
    im = Image.open(src).convert("RGBA")
    im = im.crop(im.getchannel("A").point(lambda v: 255 if v > 128 else 0).getbbox())
    h = round(im.height * width / im.width)
    # premultiplied, so the transparent surround doesn't darken the edge
    a = np.array(im).astype(float) / 255.0
    a[..., :3] *= a[..., 3:4]
    small = np.array(Image.fromarray((a * 255).astype(np.uint8)).resize((width, h), Image.BOX)).astype(float) / 255.0
    alpha = small[..., 3]
    rgb = np.where(alpha[..., None] > 0, small[..., :3] / np.maximum(alpha[..., None], 1e-4), 0)
    keep = alpha >= 0.5
    flat = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8))
    pal = flat.quantize(colors=colours, method=Image.Quantize.MEDIANCUT, kmeans=3)
    q = np.array(pal.convert("RGB"))
    for _ in range(2):                                    # (lone pixels)
        r = q.copy()
        for y in range(1, h - 1):
            for x in range(1, width - 1):
                if not keep[y, x]:
                    continue
                nb = [tuple(q[y + dy, x + dx]) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)) if keep[y + dy, x + dx]]
                if len(nb) == 4 and tuple(q[y, x]) not in nb:
                    r[y, x] = Counter(nb).most_common(1)[0][0]
        q = r
    res = np.zeros((h, width, 4), np.uint8)
    res[..., :3] = q
    res[..., 3] = np.where(keep, 255, 0)
    o = Image.fromarray(res)
    o.save(out)
    o.resize((width * 4, h * 4), Image.NEAREST).save(out.replace(".png", "_4x.png"))
    print(out, o.size)


if __name__ == "__main__":
    main()
