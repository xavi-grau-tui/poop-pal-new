"""Check the dress-up items at the spirits' real pixel size, before they go anywhere near the game.

Each item is shrunk by its own cell's scale (the reference spirit's sheet height -> its 56 px sprite),
the same way the spirits were cut, and drawn with that spirit on its 72 x 72 canvas, at 6x on the
shrine wood: if an item doesn't read here, it won't read on the phone.

    .venv/bin/python tools/art/dressup_preview.py docs/mockups/spirits/dressup/dressup_items.png
    .venv/bin/python tools/art/dressup_preview.py <items_v2.png> --v2     # the round 2 sheet (beside rows on S)

Writes <items>_art_scale_6x.png next to the items (and prints every item's size in art px).
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from dressup_template import REF, ROWS, cell_of, ref_key  # noqa: E402
from october_sheet_cut import CELL, SP, latest  # noqa: E402
from spirit_px import shrink  # noqa: E402

ITEMS = Path(sys.argv[1])
V2 = "--v2" in sys.argv
K = 6
items = np.array(Image.open(ITEMS).convert("RGBA"))
sheets = {r: Image.open(latest(r)).convert("RGB") for r in {v[0] for v in REF.values()}}
bg = np.median(np.array(sheets["moon"])[:6].reshape(-1, 3), 0)

# each reference spirit: its bbox on the sheet cell and in its 56 px sprite -> the cell's scale
ref = {}
for k, (realm, sid) in REF.items():
    cell = np.array(cell_of(realm, sid, sheets)).astype(int)
    fg = np.abs(cell - bg).sum(2) > 45
    fg = ndimage.binary_opening(fg, iterations=1)
    lab, n = ndimage.label(fg)
    sizes = ndimage.sum(fg, lab, range(1, n + 1))
    fg = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s >= 40])
    ys, xs = np.nonzero(fg)
    sp = Image.open(SP / f"october_{realm}/px/{sid}.png").convert("RGBA")
    bx = sp.getbbox()
    s = (bx[3] - bx[1]) / (ys.max() - ys.min() + 1)
    ref[k] = dict(sp=sp, sheet_box=(xs.min(), ys.min(), xs.max(), ys.max()), px_box=bx, s=s)
    print(k, sid, "scale", round(s, 4), "-> 1 art px =", round(1 / s, 2), "sheet px")

# item components, each to the cell holding its centre
a = items[..., 3] > 0
lab, n = ndimage.label(ndimage.binary_dilation(a, iterations=2))
comps = {}
for i, sl in enumerate(ndimage.find_objects(lab), 1):
    m = (lab[sl] == i) & a[sl]
    cy, cx = (sl[0].start + sl[0].stop) / 2, (sl[1].start + sl[1].stop) / 2
    comps.setdefault((int(cy // CELL), int(cx // CELL)), []).append((sl, m))


def item_sprite(r, c, k):
    """The cell's items shrunk by the cell's scale; returns (sprite, x, y) on the 56 px canvas."""
    if (r, c) not in comps:
        return None
    R = ref[k]
    y0 = min(sl[0].start for sl, _ in comps[(r, c)])
    x0 = min(sl[1].start for sl, _ in comps[(r, c)])
    y1 = max(sl[0].stop for sl, _ in comps[(r, c)])
    x1 = max(sl[1].stop for sl, _ in comps[(r, c)])
    crop = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
    for sl, m in comps[(r, c)]:
        sub = items[sl]
        dst = crop[sl[0].start - y0:sl[0].stop - y0, sl[1].start - x0:sl[1].stop - x0]
        dst[m] = sub[m]
    im = Image.fromarray(crop)
    w = max(1, round(im.width * R["s"]))
    sm = shrink(im, f"w{w}", 0.4)
    # where it goes: its offset from the spirit's sheet box, scaled, from the sprite's px box
    sx0, sy0 = R["sheet_box"][:2]
    cx0, cy0 = x0 - c * CELL, y0 - r * CELL
    px = R["px_box"][0] + (cx0 - sx0) * R["s"]
    py = R["px_box"][1] + (cy0 - sy0) * R["s"]
    return sm, round(px), round(py)


WOOD = (74, 44, 34, 255)
tiles = []
for r, (label, fam, _) in enumerate(ROWS):
    row = []
    for c in range(3):
        k = ref_key(fam, c, V2)
        R = ref[k]
        can = Image.new("RGBA", (72, 72), WOOD)
        it = item_sprite(r, c, k)
        front = "FRONT" in label
        if it and not front:
            can.alpha_composite(it[0], (it[1] + 8, it[2] + 14))
        if "FRONT" in label:  # the ring: back half behind, front half in front
            b = item_sprite(r - 1, c, k)
            if b:
                can.alpha_composite(b[0], (b[1] + 8, b[2] + 14))
        can.alpha_composite(R["sp"], (8, 14))
        if it and front:
            can.alpha_composite(it[0], (it[1] + 8, it[2] + 14))
        if it:
            row.append(f"{it[0].width}x{it[0].height}")
        tiles.append(can.resize((72 * K, 72 * K), Image.NEAREST))
    print(r + 1, label, row)

W = 72 * K
pad = 30
sheet = Image.new("RGBA", (3 * W + 4 * 6, len(ROWS) * (W + pad)), (30, 26, 34, 255))
d = ImageDraw.Draw(sheet)
for i, t in enumerate(tiles):
    r, c = divmod(i, 3)
    x, y = 6 + c * (W + 6), r * (W + pad) + pad
    if c == 0:
        d.text((8, r * (W + pad) + 8), f"{r + 1}. {ROWS[r][0]}", fill=(235, 225, 245))
    sheet.alpha_composite(t, (x, y))
out = ITEMS.with_name(ITEMS.stem + "_art_scale_6x.png")
sheet.save(out)
print(out)
