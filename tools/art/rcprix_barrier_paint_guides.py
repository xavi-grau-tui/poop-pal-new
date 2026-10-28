"""Round 22: 4x paint-over guides for the corner barriers (the user, 2026-10-27: the designer paints the look of
samples A and B big over the exact layout, we bring it down onto the game's pixel grid). Run from the repo root
after rcprix_barrier_blockout.py:

    <python with Pillow + numpy> tools/art/rcprix_barrier_paint_guides.py

For each of the 16 files: docs/mockups/rcprix_garden/round22_paint_guides/<name>_guide_4x.png, the corner and
the straights it runs into, the block-out's pieces at half strength (where each piece goes and which walls
show), the square and run-on strips outlined, and four corner marks the painting must keep (to line it up)."""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

import rcprix_barrier_blockout as bo

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/mockups/rcprix_garden/round22_paint_guides"
K = 4


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    W, RUN, SQ = bo.W, bo.RUN, bo.SQ
    offs = {"n": (0, -1), "s": (0, 1), "e": (1, 0), "w": (-1, 0)}
    for wide in ("", "_wide"):
        for corner in bo.CENTRES:
            for alt in ("", "_alt"):
                name = f"tyres_{corner}{alt}{wide}"
                t = Image.new("RGBA", (W, W), (112, 170, 76, 255))
                t.alpha_composite(Image.open(bo.TILES / f"corner_{corner}{wide}.png").convert("RGBA"), (RUN, RUN))
                for e in bo.ENDS[corner]:
                    dx, dy = offs[e]
                    road = Image.open(bo.TILES / f"{'straight_v' if dy else 'straight_h'}{wide}.png").convert("RGBA")
                    box = (0 if dx > 0 else (SQ - RUN if dx < 0 else 0), 0 if dy > 0 else (SQ - RUN if dy < 0 else 0),
                           RUN if dx > 0 else SQ, RUN if dy > 0 else SQ)
                    t.alpha_composite(road.crop(box), (RUN + SQ if dx > 0 else 0 if dx < 0 else RUN, RUN + SQ if dy > 0 else 0 if dy < 0 else RUN))
                pieces = np.asarray(Image.open(bo.OUT / f"{name}.png").convert("RGBA")).copy()
                pieces[..., 3] = pieces[..., 3] // 2
                t.alpha_composite(Image.fromarray(pieces))
                big = t.resize((W * K, W * K), Image.NEAREST)
                dr = ImageDraw.Draw(big)
                dr.rectangle((RUN * K, RUN * K, (RUN + SQ) * K - 1, (RUN + SQ) * K - 1), outline=(255, 255, 255, 255), width=2)
                for e in bo.ENDS[corner]:
                    dx, dy = offs[e]
                    x0 = (RUN + SQ if dx > 0 else 0 if dx < 0 else RUN) * K
                    y0 = (RUN + SQ if dy > 0 else 0 if dy < 0 else RUN) * K
                    w = (RUN if dx else SQ) * K
                    h = (RUN if dy else SQ) * K
                    dr.rectangle((x0, y0, x0 + w - 1, y0 + h - 1), outline=(255, 230, 60, 255), width=2)
                for cx, cy in ((0, 0), (W * K - 1, 0), (0, W * K - 1), (W * K - 1, W * K - 1)):      # the marks to keep
                    sx = 1 if cx == 0 else -1
                    sy = 1 if cy == 0 else -1
                    dr.rectangle((min(cx, cx + sx * 23), min(cy, cy + sy * 23), max(cx, cx + sx * 23), max(cy, cy + sy * 23)), fill=(255, 0, 255, 255))
                big.save(OUT / f"{name}_guide_4x.png")
    print("16 guides at", W * K, "px")


if __name__ == "__main__":
    main()
