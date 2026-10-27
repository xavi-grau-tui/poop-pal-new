"""RC Prix · Garden: a test course assembled from the designer's files (docs/mockups/rcprix_garden/BRIEF.md),
to review the set as a whole before it goes in the game: every road piece and overlay used at least once,
the three grasses mixed, decor, trees and the wooden frame round the board. Files not drawn yet are left out
(listed at the end).

    <python with Pillow> tools/art/rcprix_preview.py [folder] [--wide]   -> docs/mockups/rcprix_garden/course_preview.png (+ _2x)
    (--wide: the wide road set instead, -> course_preview_wide.png)

This is a review picture, not the game: the game lays the same pieces the same way, but the car, its shadow
and the track's shadow on the lawn come from the game."""
import random
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from rcprix_templates import FRAME, SQ  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "mockups" / "rcprix_garden"
W, H = 8, 6                                     # the board, in course squares
# the loop's corners (grid squares), driven in this order: east along the top, down, back west, an S-bend
LOOP = [(1, 1), (6, 1), (6, 4), (4, 4), (4, 3), (1, 3)]
OVERLAYS = {(2, 1): ["start_h"], (4, 1): ["boost_e"], (6, 2): ["boost_s"], (3, 3): ["ramp_w"]}
GAPS = {(2, 3): "gap_h"}
DIRS = {(1, 0): "e", (-1, 0): "w", (0, 1): "s", (0, -1): "n"}


def course():
    path = []
    for i, a in enumerate(LOOP):
        b = LOOP[(i + 1) % len(LOOP)]
        step = ((b[0] > a[0]) - (b[0] < a[0]), (b[1] > a[1]) - (b[1] < a[1]))
        p = a
        while p != b:
            path.append(p)
            p = (p[0] + step[0], p[1] + step[1])
    tiles = {}
    for i, p in enumerate(path):
        q, r = path[i - 1], path[(i + 1) % len(path)]
        ends = {DIRS[(q[0] - p[0], q[1] - p[1])], DIRS[(r[0] - p[0], r[1] - p[1])]}
        if ends == {"e", "w"}:
            tiles[p] = "straight_h"
        elif ends == {"n", "s"}:
            tiles[p] = "straight_v"
        else:
            tiles[p] = "corner_" + ("n" if "n" in ends else "s") + ("e" if "e" in ends else "w")
    tiles.update(GAPS)
    return tiles


def main():
    args = [a for a in sys.argv[1:] if a != "--wide"]
    wide = "_wide" if "--wide" in sys.argv[1:] else ""
    folder = Path(args[0]) if args else ROOT / "textures" / "minigames" / "rcprix" / "garden"
    missing = set()

    def art(name):
        p = folder / f"{name}.png"
        if not p.exists():
            missing.add(name)
            return None
        return Image.open(p).convert("RGBA")

    board = Image.new("RGBA", (W * SQ + 2 * FRAME, H * SQ + 2 * FRAME), (90, 150, 70, 255))
    at = lambda x, y: (FRAME + x * SQ, FRAME + y * SQ)
    rnd = random.Random(7)
    grass = [g for g in (art("grass_a"), art("grass_b"), art("grass_c")) if g]
    for y in range(H):
        for x in range(W):
            if grass:
                board.alpha_composite(rnd.choice(grass), at(x, y))
    tiles = course()
    # decor on the lawn, away from the road
    for name, n in (("bush_a", 3), ("bush_b", 3), ("bush_c", 3), ("bush_d", 3), ("flowers_a", 10), ("flowers_b", 10)):
        im = art(name)
        for _ in range(n if im else 0):
            for _try in range(40):
                gx, gy = rnd.randrange(W), rnd.randrange(H)
                if (gx, gy) not in tiles:
                    x0, y0 = at(gx, gy)
                    board.alpha_composite(im, (x0 + rnd.randrange(SQ - im.width), y0 + rnd.randrange(SQ - im.height)))
                    break
    for p, name in tiles.items():
        im = art(name + wide)
        if im:
            board.alpha_composite(im, at(*p))
        if name.startswith("corner_"):
            ty = art("tyres_" + name[-2:] + wide)
            if ty:
                board.alpha_composite(ty, at(*p))
    for p, names in OVERLAYS.items():
        for name in names:
            im = art(name + wide)
            if im:
                board.alpha_composite(im, at(*p))
    # trees hanging over the board's edges, then the frame over everything at the rim
    for name, pos in (("tree_top", (2 * SQ, 0)), ("tree_bottom", (5 * SQ, H * SQ + 2 * FRAME - 110)),
                      ("tree_left", (0, 3 * SQ)), ("tree_right", (W * SQ + 2 * FRAME - 110, 1 * SQ))):
        im = art(name)
        if im:
            board.alpha_composite(im, pos)
    for name, xs, y in (("frame_top", range(W), 0), ("frame_bottom", range(W), H * SQ + FRAME)):
        im = art(name)
        for x in xs if im else ():
            board.alpha_composite(im, (FRAME + x * SQ, y))
    for name, x, ys in (("frame_left", 0, range(H)), ("frame_right", W * SQ + FRAME, range(H))):
        im = art(name)
        for y in ys if im else ():
            board.alpha_composite(im, (x, FRAME + y * SQ))
    for name, pos in (("frame_corner_tl", (0, 0)), ("frame_corner_tr", (W * SQ + FRAME, 0)),
                      ("frame_corner_bl", (0, H * SQ + FRAME)), ("frame_corner_br", (W * SQ + FRAME, H * SQ + FRAME))):
        im = art(name)
        if im:
            board.alpha_composite(im, pos)
    board.save(OUT / f"course_preview{wide}.png")
    board.crop((FRAME + 1 * SQ, FRAME + 2 * SQ, FRAME + 5 * SQ, FRAME + 5 * SQ)).resize((8 * SQ, 6 * SQ), Image.NEAREST).save(OUT / f"course_preview{wide}_2x.png")
    print("saved", OUT / f"course_preview{wide}.png", "and _2x (a close-up)")
    if missing:
        print("not drawn yet:", ", ".join(sorted(missing)))


if __name__ == "__main__":
    main()
