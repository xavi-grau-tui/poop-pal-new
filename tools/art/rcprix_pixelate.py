"""RC Prix: a painting or a generated study put on the game's pixel grid. Run from the repo root:

    <python with Pillow + numpy> tools/art/rcprix_pixelate.py <in.png> <out.png> <width in game px> [colours]

Crops to what's opaque, scales to <width> game px with each game px the average of the area it covers (light
and shade kept, no blur past it), cuts the soft edge (alpha < 50% goes, the rest opaque), reduces to a small
palette (default 8) and drops lone pixels (one game px unlike all four neighbours takes their most common
colour). Writes <out.png> at 1x and <out>_4x.png next to it. pixelate() does the same for other tools."""
import sys
from collections import Counter

import numpy as np
from PIL import Image


def opaque_box(im):
    return im.getchannel("A").point(lambda v: 255 if v > 128 else 0).getbbox()


def pixelate(im, size, colours=8):
    """An RGBA picture (already cropped as wanted) -> an RGBA array of `size` (w, h) game px"""
    w, h = size
    a = np.array(im.convert("RGBA")).astype(float) / 255.0
    a[..., :3] *= a[..., 3:4]                             # (premultiplied: the surround doesn't darken the edge)
    small = np.array(Image.fromarray((a * 255).astype(np.uint8)).resize((w, h), Image.BOX)).astype(float) / 255.0
    alpha = small[..., 3]
    rgb = np.where(alpha[..., None] > 0, small[..., :3] / np.maximum(alpha[..., None], 1e-4), 0)
    keep = alpha >= 0.5
    flat = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8))
    q = np.array(flat.quantize(colors=colours, method=Image.Quantize.MEDIANCUT, kmeans=3).convert("RGB"))
    for _ in range(2):                                    # (lone pixels)
        r = q.copy()
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if not keep[y, x]:
                    continue
                nb = [tuple(q[y + dy, x + dx]) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)) if keep[y + dy, x + dx]]
                if len(nb) == 4 and tuple(q[y, x]) not in nb:
                    r[y, x] = Counter(nb).most_common(1)[0][0]
        q = r
    res = np.zeros((h, w, 4), np.uint8)
    res[..., :3] = q
    res[..., 3] = np.where(keep, 255, 0)
    return res


def main():
    src, out, width = sys.argv[1], sys.argv[2], int(sys.argv[3])
    colours = int(sys.argv[4]) if len(sys.argv) > 4 else 8
    im = Image.open(src).convert("RGBA")
    im = im.crop(opaque_box(im))
    o = Image.fromarray(pixelate(im, (width, round(im.height * width / im.width)), colours))
    o.save(out)
    o.resize((o.width * 4, o.height * 4), Image.NEAREST).save(out.replace(".png", "_4x.png"))
    print(out, o.size)


if __name__ == "__main__":
    main()
