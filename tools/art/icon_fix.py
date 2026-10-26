"""Menu icons: close a cut outline and re-centre the drawing on its 32 x 32 canvas (the user,
2026-10-26: some icons came cut on one side - the drawing ran off the canvas, its outline missing there).

    <python with Pillow + numpy> tools/art/icon_fix.py drinks/milk food/kimchi ...

For each name, in textures/<cat>/ and textures/<cat>/new_shrine/: on every side of the drawing where
light pixels touch its edge (a cut), a 1 px outline is added just outside them, in the icon's own outline
colour (its most common dark colour); then the drawing is centred on the canvas (ties: up and left)."""
import sys
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
LIGHT = 300                     # (r + g + b) above this, a pixel isn't outline


def fix(path: Path) -> str:
    a = np.asarray(Image.open(path).convert("RGBA")).astype(int)
    al = a[..., 3] > 0
    lum = a[..., :3].sum(-1)
    dark = al & (lum < 200)
    ink = Counter(map(tuple, a[dark][:, :3])).most_common(1)[0][0] if dark.any() else (40, 24, 30)
    ys, xs = np.where(al)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    big = np.zeros((a.shape[0] + 2, a.shape[1] + 2, 4), int)
    big[1:-1, 1:-1] = a
    added = []
    for side, cells, step in (("top", [(y0, x) for x in range(32)], (-1, 0)), ("bottom", [(y1, x) for x in range(32)], (1, 0)),
                              ("left", [(y, x0) for y in range(32)], (0, -1)), ("right", [(y, x1) for y in range(32)], (0, 1))):
        light = [(y, x) for (y, x) in cells if al[y, x] and lum[y, x] > LIGHT]
        if not light:
            continue
        added.append(side)
        for (y, x) in cells:
            if al[y, x]:
                big[y + 1 + step[0], x + 1 + step[1]] = (*ink, 255)
    m = big[..., 3] > 0
    ys, xs = np.where(m)
    crop = big[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    h, w = crop.shape[:2]
    out = np.zeros((32, 32, 4), int)
    oy, ox = (32 - h) // 2, (32 - w) // 2
    out[oy:oy + h, ox:ox + w] = crop[:32, :32]
    Image.fromarray(out.astype(np.uint8), "RGBA").save(path)
    return f"{path.relative_to(ROOT)}: closed {added or 'nothing'}, {w}x{h} centred"


if __name__ == "__main__":
    for name in sys.argv[1:]:
        cat, n = name.split("/")
        for p in (ROOT / "textures" / cat / f"{n}.png", ROOT / "textures" / cat / "new_shrine" / f"{n}.png"):
            if p.exists():
                print(fix(p))
