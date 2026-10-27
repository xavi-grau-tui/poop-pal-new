"""Checks the designer's RC Prix art before it goes in (docs/mockups/rcprix_garden/BRIEF.md): every file
there, at its exact size, every pixel fully opaque or fully clear, and no stray files.

    <python with Pillow + numpy> tools/art/check_rcprix_art.py [folder] [--pilot]

Prints one line per problem and exits 1 if there are any."""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from rcprix_templates import SIZES, SQ, WIDE  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SEAMLESS = ("grass_a", "grass_b", "grass_c")
PILOT = ("straight_h", "straight_v", "corner_ne", "corner_nw", "corner_se", "corner_sw", "grass_a")
JOINS = (
    ("corner_ne", "e", "straight_h", "w"), ("corner_nw", "w", "straight_h", "e"),
    ("corner_se", "e", "straight_h", "w"), ("corner_sw", "w", "straight_h", "e"),
    ("corner_ne", "n", "straight_v", "s"), ("corner_nw", "n", "straight_v", "s"),
    ("corner_se", "s", "straight_v", "n"), ("corner_sw", "s", "straight_v", "n"),
)
JOINS += tuple((a + WIDE, ae, b + WIDE, be) for a, ae, b, be in JOINS)     # (the wide set joins the same way)


def edge_pixels(image, side):
    """Which pixels along a piece's edge the road covers (two pieces join when these match; their colours
    may differ, as a curb stripe can change colour exactly at a join)"""
    return {"n": image[0], "s": image[-1], "w": image[:, 0], "e": image[:, -1]}[side][:, 3] > 0


def main():
    args = [arg for arg in sys.argv[1:] if arg != "--pilot"]
    pilot = "--pilot" in sys.argv[1:]
    folder = Path(args[0]) if args else ROOT / "textures" / "minigames" / "rcprix" / "garden"
    problems = []
    required = {n: SIZES[n] for n in PILOT} if pilot else SIZES
    images = {}
    for name, (w, h) in required.items():
        p = folder / f"{name}.png"
        if not p.exists():
            problems.append(f"missing   {p.name}")
            continue
        im = Image.open(p)
        if im.size != (w, h):
            problems.append(f"size      {p.name}: {im.size[0]}×{im.size[1]}, should be {w}×{h}")
        a = np.asarray(im.convert("RGBA"))
        images[name] = a
        soft = int(((a[..., 3] > 0) & (a[..., 3] < 255)).sum())
        if soft:
            problems.append(f"soft edge {p.name}: {soft} half-transparent pixels (every pixel fully opaque or fully clear)")
        if name in SEAMLESS and a.shape[:2] == (SQ, SQ):
            if (a[..., 3] < 255).any():
                problems.append(f"holes     {p.name}: ground must be fully opaque")
            # (seamless means the right edge carries on into the left, not that they're the same column;
            # that can't be checked by machine: look at course_preview.png, tools/art/rcprix_preview.py)
    for left, le, right, re in JOINS:
        if left in images and right in images:
            if not np.array_equal(edge_pixels(images[left], le), edge_pixels(images[right], re)):
                problems.append(f"join      {left}.{le} does not match {right}.{re}")
    for p in sorted(folder.glob("*.png")):
        if p.stem not in SIZES:
            problems.append(f"unknown   {p.name} (not in the brief's list)")
    for line in problems:
        print(line)
    print(f"{len(required) - sum(l.startswith('missing') for l in problems)}/{len(required)} files present, {len(problems)} problems")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
