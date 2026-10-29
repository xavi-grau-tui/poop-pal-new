"""RC Prix Sky, round 2: the designer's ImageGen paintings (docs/mockups/rcprix_sky/round2_imagegen_sources/) put on
the game's pixel grid. Run from the repo root:

    <python with Pillow + numpy> tools/art/rcprix_sky_from_sources.py

Writes into textures/minigames/rcprix/sky/:
  ring_<r>, ring_gold_<r>, ring_grey_<r>   every ring size the levels use (ring_r, world px, 86 .. 124 by 2), each
            scaled from the painting itself (never a resized ring): the tube's outside r + 14 game px across (its
            centre line, where it counts, r / 2 from the middle), on a canvas 3 px bigger all round
  stand_cloud_<view>_<under|over>_<long>   the cloud under a stand <long> art px long (the stand's three lengths,
            rc_racer STAND_LONGS / 2), whole (no repeated middle), CLOUD_MARGIN 22 past the stand all round:
            front / back banks at the canvas's foot, the side views' towers on the stand's far side; the over
            layer placed as the painter placed it against its under layer"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from rcprix_pixelate import opaque_box, pixelate  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs/mockups/rcprix_sky/round2_imagegen_sources"
OUT = ROOT / "textures/minigames/rcprix/sky"
RINGS = range(86, 126, 2)
LONGS = (248, 328, 408)                # the stand's lengths, art px (end_a 41 + 2 / 3 / 4 middles of 80 + end_b 47)
DEEP = 107                             # the stand's depth, art px
MARGIN = 22
FRONT_MAX_H = 90                       # a front / back bank no taller than this (past it, it's widened instead)


def grey(a):
    out = a.copy().astype(float)
    lum = out[..., :3] @ np.array([0.3, 0.59, 0.11])
    g = 70 + lum * 0.55
    ink = a[..., :3].max(-1) < 90                        # (the outline stays dark; the red doesn't count)
    out[..., 0], out[..., 1], out[..., 2] = g * 0.98, g * 0.96, g * 1.04
    out[ink] = a[ink]
    return np.clip(out, 0, 255).astype(np.uint8)


def save(name, a):
    Image.fromarray(a).save(OUT / f"{name}.png")


def rings():
    for look, file in (("", "ring_red_source.png"), ("gold_", "ring_gold_source.png")):
        im = Image.open(SRC / file).convert("RGBA")
        im = im.crop(opaque_box(im))
        for r in RINGS:
            w = r + 14
            h = round(im.height * w / im.width)
            a = pixelate(im, (w, h), 10)
            canvas = np.zeros((h + 6, w + 6, 4), np.uint8)
            canvas[3:3 + h, 3:3 + w] = a
            save(f"ring_{look}{r}", canvas)
            if look == "":
                save(f"ring_grey_{r}", grey(canvas))
    print("  rings", list(RINGS)[0], "..", list(RINGS)[-1])


def cloud(view):
    along_x = view in ("front", "back")
    under = Image.open(SRC / f"stand_cloud_{view}_under_source.png").convert("RGBA")
    over = Image.open(SRC / f"stand_cloud_{view}_over_source.png").convert("RGBA")
    ub = opaque_box(under)
    ob = opaque_box(over)
    k_canvas = under.width / over.width                  # (the over painting's canvas onto the under's)
    for long in LONGS:
        L = long + 2 * MARGIN                            # the canvas along the stand
        T = DEEP + 2 * MARGIN                            # ...and across it
        uw, uh = ub[2] - ub[0], ub[3] - ub[1]
        if along_x:
            w = L
            h = min(round(uh * w / uw), FRONT_MAX_H)
            sx, sy = w / uw, h / uh
        else:
            h = L
            w = min(round(uw * h / uh), T)
            sx, sy = w / uw, h / uh
        canvas_w, canvas_h = (L, T) if along_x else (T, L)
        # the under bank: at the canvas's foot (front / back), on the stand's far side (side views)
        ux = 0 if along_x or view == "side_l" else canvas_w - w
        uy = canvas_h - h
        for layer, im, box in (("under", under, ub), ("over", over, ob)):
            if layer == "over":
                # its box in the under painting's px, then the same scale and place
                bx0, by0 = box[0] * k_canvas, box[1] * k_canvas
                bw, bh = (box[2] - box[0]) * k_canvas, (box[3] - box[1]) * k_canvas
                ox = ux + (bx0 - ub[0]) * sx
                oy = uy + (by0 - ub[1]) * sy
                pw, ph = max(1, round(bw * sx)), max(1, round(bh * sy))
            else:
                ox, oy, pw, ph = ux, uy, w, h
            a = pixelate(im.crop(box), (pw, ph), 7)
            canvas = np.zeros((canvas_h, canvas_w, 4), np.uint8)
            # (nudged inside the canvas, never cut: a puff past its edge showed a straight line, the user)
            ox = min(max(ox, 0), canvas_w - pw)
            oy = min(max(oy, 0), canvas_h - ph)
            x0, y0 = int(round(ox)), int(round(oy))
            x1, y1 = min(canvas_w, x0 + pw), min(canvas_h, y0 + ph)
            x0c, y0c = max(0, x0), max(0, y0)
            canvas[y0c:y1, x0c:x1] = a[y0c - y0:y1 - y0, x0c - x0:x1 - x0]
            save(f"stand_cloud_{view}_{layer}_{long}", canvas)
    print("  stand clouds", view)


## The ground's fields (ground_sources/field_<kind>_source.png): rows painted horizontal, turned here to the grid's
## long edges (rc_racer _sky_floor: v = y * 0.9 - x * 0.24 -> lines atan(0.24 / 0.9) = 14.9 degrees down to the
## right) while still big, then cut to a square that covers any one field (a field's box is about 125 x 105 art px)
FIELD_SRC = ROOT / "docs/mockups/rcprix_sky/ground_sources"
FIELD_SQUARE = 165                     # a painting's square in game px (its ~31 rows about 5 px apart)
FIELD_PATCH = 132                      # the square cut from it once turned (fits inside: 165 / (cos + sin))
FIELD_ANGLE = float(np.degrees(np.arctan2(0.24, 0.9)))


def fields():
    for p in sorted(FIELD_SRC.glob("field_*_source.png")):
        kind = p.name[len("field_"):-len("_source.png")]
        im = Image.open(p).convert("RGBA")
        k = im.width / FIELD_SQUARE                       # source px per game px
        turned = im.rotate(-FIELD_ANGLE, resample=Image.BICUBIC, expand=False)
        c = turned.width / 2.0
        half = FIELD_PATCH * k / 2.0
        patch = turned.crop((round(c - half), round(c - half), round(c + half), round(c + half)))
        save(f"field_{kind}", pixelate(patch, (FIELD_PATCH, FIELD_PATCH), 12))
    print("  fields")


## The ground's other pieces: hedges cut to a field edge's length and turned to each edge (a: the long edges, along
## (0.9, 0.24), b: the short ones, along (-0.32, 0.86); RcSky.ground strings them centred on each edge), the river
## strip (the game repeats it along its winding path), the decor at its size in game px (1.4x the brief's: specks
## next to a 100 px field otherwise), the bridge turned upright to cross the river (which runs left to right)
EDGE_A = 92.0 * float(np.hypot(0.9, 0.24)) / (0.86 * 0.9 + 0.32 * 0.24)     # 100.7 art px
EDGE_B = 76.0 * float(np.hypot(0.32, 0.86)) / (0.86 * 0.9 + 0.32 * 0.24)    # 82.0
ANGLE_B = float(np.degrees(np.arctan2(0.86, 0.32)))                          # 69.6 (up to the right)
HEDGES = {"hedge_low": 4, "hedge_tree_line": 6}                             # their thickness, art px
RIVER_H = 22                                                                 # the river strip, banks and all
DECOR = {"farmhouse_barn": 17, "village": 45, "church": 14, "windmill_tower": 11, "windmill_sails": 22,
         "pond": 22, "haystacks": 14, "copse": 34, "stone_bridge": 32}       # width, game px (the bridge: its length,
                                                                             # across the river's 22)


def strip(name, thick, length):
    """A horizontal strip painting scaled to `thick` art px and repeated (every other copy mirrored) to `length`"""
    im = Image.open(FIELD_SRC / f"{name}_source.png").convert("RGBA")
    im = im.crop(opaque_box(im))
    k = im.height / thick                                 # source px per art px
    if length is None:
        length = 2 * im.width / k
    n = int(np.ceil(length * k / im.width)) + 1
    long = Image.new("RGBA", (im.width * n, im.height), (0, 0, 0, 0))
    for i in range(n):
        long.paste(im.transpose(Image.FLIP_LEFT_RIGHT) if i % 2 else im, (i * im.width, 0))
    return long.crop((0, 0, round(length * k), im.height)), k


def ground_pieces():
    for name, thick in HEDGES.items():
        for tag, length, angle in (("a", EDGE_A + 2, -FIELD_ANGLE), ("b", EDGE_B + 2, ANGLE_B)):
            im, k = strip(name, thick, length)
            turned = im.rotate(angle, resample=Image.BICUBIC, expand=True)
            save(f"{name}_{tag}", pixelate(turned, (max(1, round(turned.width / k)), max(1, round(turned.height / k))), 8))
    im, k = strip("river", RIVER_H, None)                # (exactly two copies, the second mirrored: it wraps round)
    save("river", pixelate(im, (round(im.width / k), RIVER_H), 10))
    for name, w in DECOR.items():
        im = Image.open(FIELD_SRC / f"{name}_source.png").convert("RGBA")
        if name == "windmill_sails":
            im = im.crop((0, 0, im.width, im.height))      # (the hub stays in the middle: it turns round it)
        else:
            im = im.crop(opaque_box(im))
        h = max(1, round(im.height * w / im.width))
        a = pixelate(im, (w, h), 10)
        if name == "stone_bridge":
            a = np.rot90(a).copy()                       # (upright, after: its length across the river)
        save(f"decor_{name}", a)
    print("  hedges, river, decor")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    if "--fields" in sys.argv:
        fields()
        ground_pieces()
        return
    rings()
    for view in ("front", "back", "side_l", "side_r"):
        cloud(view)
    fields()
    ground_pieces()
    print("written to", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
