"""RC Prix Lagoon: the buoys' paint guides for the designer. Run from the repo root:

    <python with Pillow + numpy> tools/art/rcprix_lagoon_buoy_guides.py

The buoys float in 3D as 5 stacked slices (PalPrixArt.buoy_slices: the waterline, the body, the white band,
the top, the cap; 7x7 old px each, drawn 3 world px apart). The game keeps their behaviour; only the look is
redrawn, at the Garden's detail: each slice 14x14 game px. This draws today's slices at the new size as the
guide (the shape to keep), at 4x for painting, plus the stack as the game shows it.

Writes docs/mockups/rcprix_lagoon/round2_buoy_guides/:
  buoy_red_<k>_guide_4x.png, buoy_yellow_<k>_guide_4x.png   one per slice (56x56: 14x14 game px at 4x)
  buoy_stack_preview.png                                    the stacks, as the game draws them, 8x
The designer paints over each guide and delivers buoy_red_<k>_4x.png / buoy_yellow_<k>_4x.png into
docs/mockups/rcprix_lagoon/round2_paint/ (converted by rcprix_lagoon_from_paint.py round2)."""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/mockups/rcprix_lagoon/round2_buoy_guides"
OUTLINE = (40, 34, 44, 255)
UP = 1.5                               # each slice this many game px higher (3 world px)


def slices(red):
    """Today's buoy (pal_prix_art.gd buoy_slices), 7x7 each"""
    c = np.array((226, 70, 64) if red else (250, 196, 60))
    w = (255, 252, 244)
    out = []
    for kind in range(5):
        im = np.zeros((7, 7, 4), np.uint8)
        rr = 3.6 if kind < 4 else 1.7
        cen = np.array((3.5, 3.5) if kind < 4 else (3.0, 3.0))
        for y in range(7):
            for x in range(7):
                o = np.array((x + 0.5, y + 0.5)) - cen
                d = np.hypot(*o)
                if d > rr:
                    continue
                rim = d > rr - 1.0
                lit = o[0] + o[1] < -1.2
                shade = o[0] + o[1] > 1.6
                if kind == 0:
                    col = (30, 40, 60, 140)
                elif kind == 1:
                    col = OUTLINE if rim else (*(c * 0.75).astype(int), 255)
                elif kind == 2:
                    col = OUTLINE if rim else ((*w, 255) if lit else ((214, 208, 204, 255) if shade else (236, 232, 226, 255)))
                elif kind == 3:
                    col = OUTLINE if rim else ((*(c + (255 - c) * 0.45).astype(int), 255) if lit else
                                              ((*(c * 0.8).astype(int), 255) if shade else (*c, 255)))
                else:
                    col = (255, 255, 255, 255) if o[0] + o[1] < 0 else (*(c + (255 - c) * 0.3).astype(int), 255)
                im[y, x] = col
        out.append(Image.fromarray(im))
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    stacks = []
    for colour, red in (("red", True), ("yellow", False)):
        sl = [s.resize((14, 14), Image.NEAREST) for s in slices(red)]
        for k, s in enumerate(sl):
            g = s.resize((56, 56), Image.NEAREST)
            canvas = Image.new("RGBA", (56, 56), (0, 0, 0, 0))
            canvas.alpha_composite(g)
            px = canvas.load()
            for x, y in ((0, 0), (55, 0), (0, 55), (55, 55)):
                px[x, y] = (255, 0, 255, 255)              # corner marks: keep them
            canvas.save(OUT / f"buoy_{colour}_{k}_guide_4x.png")
        stack = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
        for k, s in enumerate(sl):
            stack.alpha_composite(s, (5, int(round(8 - k * UP))))
        stacks.append(stack.resize((192, 192), Image.NEAREST))
    prev = Image.new("RGBA", (420, 200), (224, 148, 127, 255))
    for i, st in enumerate(stacks):
        prev.alpha_composite(st, (10 + i * 210, 4))
    prev.save(OUT / "buoy_stack_preview.png")
    print("written to", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
