"""Hokora ornaments straight from the designer's ImageGen paintings, at the red lantern's definition
(textures/pet/shrine_new/lantern.png: 108 x 176, the 925 canvas' own pixel; the user, 2026-10-31:
"the definition of all ornaments on screen has to be like the original lanterns"). Round 3's
26 x 42 exports were 4x coarser and were rejected.

Each source (docs/mockups/hokora_decor/round3/<folder>/source_<id>_imagegen.png) is a sheet of
its frames side by side (or stacked); the first one is cut out, shrunk to fit its kind's box
(premultiplied Lanczos) and given hard alpha: a still. Frames at this definition are still to make.

  lantern  fits 108 x 176 (its hook at the top middle)
  shelf    fits 156 x 176 (bigger than the slab's boxes: the user, they read smaller than designed)
  hanging  fits 420 x 112 (shallow: the user, they hung too low; to redo later)
Like the red lantern (the user: "keep the aesthetics exactly like the original lanterns, same
outlines, colour densities"): drawn on a 2 x 2 pixel (shrunk to half, enlarged back with hard
edges), the painting's near-black edges turned into the red lantern's plum (OUTLINE) and a thick
plum outline round it (lanterns and shelf: 2 art pixels, ~6-8 screen pixels with the painting's
own edge, as the red lantern's 6-10), the colours a little richer (SATURATION).

Also round 1's paintings (docs/mockups/hokora_decor/imagegen_sources/): its hanging pieces
(<id>-1.png) and its shelf pairs (one painting with both: the left object is <id>, the right one
<id>_left), where round 3 has no source for them. Round 1's lanterns come in as <id>_drawn: the
recoloured red lanterns keep their ids (the user: don't remove the lanterns).

Run: .venv/bin/python tools/art/ornaments_from_sources.py [out_dir]   (default the game's decor folder)
"""
import glob
import os
import sys
import numpy as np
from PIL import Image

SRC = "docs/mockups/hokora_decor/round3/"
R1 = "docs/mockups/hokora_decor/imagegen_sources/"
OUT = sys.argv[1] if len(sys.argv) > 1 else "textures/pet/shrine_new/decor/"
BOX = {"lantern": (108, 176), "shelf": (156, 176), "hang": (420, 112)}
RING = {"lantern": 2, "shelf": 2, "hang": 1}   # (outline width in art pixels)
SATURATION = 1.15
PX = 2                                   # (screen pixels per art pixel, the red lantern's)
OUTLINE = (31, 10, 27)                   # (the red lantern's outline colour)


def segments(filled):
    """Runs of True in a 1-D mask (the frames along one axis), ignoring thin bits (divider lines)"""
    out, start = [], None
    for i, f in enumerate(list(filled) + [False]):
        if f and start is None:
            start = i
        elif not f and start is not None:
            out.append((start, i))
            start = None
    big = max(b - a for a, b in out)
    return [s for s in out if s[1] - s[0] > big * 0.3]


def first_frame(img):
    a = np.array(img)[..., 3] > 128
    cols, rows = segments(a.any(0)), segments(a.any(1))
    if len(rows) > len(cols):                    # (stacked frames)
        y0, y1 = rows[0]
        sub = a[y0:y1]
        xs = np.where(sub.any(0))[0]
        return img.crop((xs[0], y0, xs[-1] + 1, y1))
    x0, x1 = cols[0]
    ys = np.where(a[:, x0:x1].any(1))[0]
    return img.crop((x0, ys[0], x1, ys[-1] + 1))


def pair(img):
    """A shelf pair's two objects (left, right)"""
    a = np.array(img)[..., 3] > 128
    cols = segments(a.any(0))
    out = []
    for x0, x1 in (cols[0], cols[-1]):
        ys = np.where(a[:, x0:x1].any(1))[0]
        out.append(img.crop((x0, ys[0], x1, ys[-1] + 1)))
    return out


def shrink(img, box, ring=1):
    """Fits the box on the PX grid, `ring` art pixels of outline round it, enlarged with hard edges"""
    k = min((box[0] / PX - 2 * ring) / img.width, (box[1] / PX - 2 * ring) / img.height)
    size = (max(1, round(img.width * k)), max(1, round(img.height * k)))
    small = np.array(img.convert("RGBa").resize(size, Image.LANCZOS).convert("RGBA"))
    small[..., 3] = np.where(small[..., 3] >= 128, 255, 0)
    small[small[..., 3] == 0] = 0
    if ring > 1:                             # (richer colours, near-black edges in the outline's plum)
        hsv = np.array(Image.fromarray(small, "RGBA").convert("RGB").convert("HSV")).astype(float)
        hsv[..., 1] = np.clip(hsv[..., 1] * SATURATION, 0, 255)
        small[..., :3] = np.array(Image.fromarray(hsv.astype(np.uint8), "HSV").convert("RGB"))
        small[(small[..., :3].astype(int).sum(-1) < 150) & (small[..., 3] > 0), :3] = OUTLINE
    out = np.zeros((size[1] + 2 * ring, size[0] + 2 * ring, 4), np.uint8)
    out[ring:-ring, ring:-ring] = small
    for r in range(ring):
        solid = out[..., 3] > 0
        near = np.zeros_like(solid)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if r == 0 or dx == 0 or dy == 0:   # (the outer ring rounded at the corners)
                    near |= np.roll(np.roll(solid, dy, 0), dx, 1)
        out[near & ~solid] = OUTLINE + (255,)
    return Image.fromarray(out, "RGBA").resize((out.shape[1] * PX, out.shape[0] * PX), Image.NEAREST)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    n = 0
    done = set()
    for f in sorted(glob.glob(SRC + "*/source_*_imagegen.png")):
        pid = os.path.basename(f)[len("source_"):-len("_imagegen.png")]
        kind = pid.split("_")[0]
        if kind not in BOX:
            continue
        done.add(pid)
        if kind == "lantern" and "/round1/" in f:
            pid += "_drawn"
        shrink(first_frame(Image.open(f).convert("RGBA")), BOX[kind], RING[kind]).save(OUT + pid + ".png")
        n += 1
    for f in sorted(glob.glob(R1 + "hanging/*-1.png")):
        pid = os.path.basename(f)[:-len("-1.png")]
        if pid not in done:
            shrink(first_frame(Image.open(f).convert("RGBA")), BOX["hang"], RING["hang"]).save(OUT + pid + ".png")
            n += 1
    for f in sorted(glob.glob(R1 + "shelf/*.png")):
        pid = os.path.basename(f)[:-len(".png")]
        if pid not in done:
            left, right = pair(Image.open(f).convert("RGBA"))
            shrink(left, BOX["shelf"], RING["shelf"]).save(OUT + pid + ".png")
            shrink(right, BOX["shelf"], RING["shelf"]).save(OUT + pid + "_left.png")
            n += 2
    print(n, "stills ->", OUT)
