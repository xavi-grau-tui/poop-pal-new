"""The designer's spirit paintings -> 56 x 56 game sprites at the old pals' pixel.

Each painting (big, transparent, smooth) is cut from its faint background haze, shrunk to the
stage's size, given hard transparency and a 1 px dark plum outline (its own outer ring), and set
centred on the 56 canvas with its lowest point on row 54. The shading is kept (no palette
reduction); a light unsharp mask keeps the faces crisp after the shrink.

    .venv/bin/python tools/art/spirit_px.py docs/mockups/spirits/round5 out_dir \
        paprika:h34 daruma:h34 salamander:w42 ...

A size is h<N> (height) or w<N> (width) in art px, or x<N> for a painting made at N times the
sprite's scale (round 7 on: 1120 canvas = x20); the default is h34. A source is <id>_source.png,
or <id>.png when there is no _source file.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

OUTLINE = (34, 16, 26)  # #22101A, the briefs' dark plum
CANVAS = 56
BASELINE = 54  # the lowest row the spirit stands on
MIN_PART = 0.002  # keep loose parts (steam puffs) above this share of the body's area


def cut(src: Image.Image) -> Image.Image:
    a = np.array(src.convert("RGBA"))
    solid = a[..., 3] > 128
    solid = ndimage.binary_fill_holes(solid)
    lab, n = ndimage.label(solid)
    sizes = ndimage.sum(solid, lab, range(1, n + 1))
    keep = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s >= sizes.max() * MIN_PART])
    a[..., 3] = np.where(keep, 255, 0)
    im = Image.fromarray(a)
    return im.crop(im.getbbox())


def shrink(im: Image.Image, size: str, sharpen: float) -> Image.Image:
    n = int(size[1:])
    if size[0] == "x":  # a fixed scale: the painting is n times the sprite (round 7 on: x20)
        w, h = max(1, round(im.width / n)), max(1, round(im.height / n))
    elif size[0] == "w":
        w, h = n, max(1, round(im.height * n / im.width))
    else:
        w, h = max(1, round(im.width * n / im.height)), n
    a = np.array(im).astype(float)
    al = a[..., 3:] / 255.0
    pre = np.concatenate([a[..., :3] * al, a[..., 3:]], 2)  # premultiplied, so no dark fringe
    small = np.array(Image.fromarray(pre.astype(np.uint8)).resize((w, h), Image.LANCZOS)).astype(float)
    alpha = small[..., 3] / 255.0
    rgb = small[..., :3] / np.maximum(alpha[..., None], 1e-3)
    out = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8))
    if sharpen:
        out = out.filter(ImageFilter.UnsharpMask(radius=1, percent=int(sharpen * 100), threshold=2))
    rgb = np.array(out).astype(int)
    op = np.pad(alpha > 0.5, 1)
    op = ndimage.binary_fill_holes(op)
    rgb = np.pad(rgb, ((1, 1), (1, 1), (0, 0)))
    edge = op & ~ndimage.binary_erosion(op)
    rgb[edge] = OUTLINE
    res = np.zeros(op.shape + (4,), np.uint8)
    res[..., :3] = np.clip(rgb, 0, 255)
    res[..., 3] = np.where(op, 255, 0)
    sp = Image.fromarray(res)
    return sp.crop(sp.getbbox())


def place(sp: Image.Image) -> Image.Image:
    c = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    c.alpha_composite(sp, ((CANVAS - sp.width) // 2, BASELINE + 1 - sp.height))
    return c


def main(argv):
    src_dir, out_dir = Path(argv[0]), Path(argv[1])
    sharpen = 0.6
    out_dir.mkdir(parents=True, exist_ok=True)
    for arg in argv[2:]:
        if arg.startswith("--sharpen="):
            sharpen = float(arg.split("=")[1])
            continue
        sid, _, size = arg.partition(":")
        src = src_dir / f"{sid}_source.png"
        if not src.exists():
            src = src_dir / f"{sid}.png"
        sp = shrink(cut(Image.open(src)), size or "h34", sharpen)
        place(sp).save(out_dir / f"{sid}.png")
        print(sid, sp.size)


if __name__ == "__main__":
    main(sys.argv[1:])
