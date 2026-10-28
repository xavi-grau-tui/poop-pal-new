"""RC Prix Lagoon, round 1b: the designer's 4x paintings into the game. Run from the repo root:

    <python with Pillow + numpy> tools/art/rcprix_lagoon_from_paint.py [round1c] [--game]

Each docs/mockups/rcprix_lagoon/<round>_paint/<name>_4x.png (painted on a 4x4 grid, NOTES_ROUND_1B.md)
comes down to the game's grid: one pixel per 4x4 block, its most common opaque colour, opaque where most
of the block is. Then each is checked:
  - size: a multiple of 4; the squares (water, channel, shallows, sand) exactly 190x190
  - hard pixels (by construction) and how many colours
  - detail: how often a pixel differs from its neighbour, in a range per material (round 1c: the
    round-1b squares at the Garden grass's 19% read as static; sand has ripples and patches, not speckle)
  - speckle: lone pixels unlike all four neighbours (single-pixel noise reads as static at phone size)
  - blocks painted as one colour (mixed 4x4 blocks mean soft brushes or a misaligned grid)
  - squares: seamless (the edges match when tiled) and the outer 3 px ring the same in A, B and C
Results go to docs/mockups/rcprix_lagoon/<round>_converted/; with --game the files that pass are written
into textures/minigames/rcprix/lagoon/."""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ROUND = next((a for a in sys.argv[1:] if not a.startswith("--")), "round1c")   # which round's paintings (default: 1c)
PAINT = ROOT / f"docs/mockups/rcprix_lagoon/{ROUND}_paint"
OUT = ROOT / f"docs/mockups/rcprix_lagoon/{ROUND}_converted"
GAME = ROOT / "textures/minigames/rcprix/lagoon"
K = 4
SQ = 190
SQUARES = ("water", "channel", "shallows", "sand")
DETAIL = {"sand": (0.05, 0.16)}   # a square's detail range per material (the water is drawn by the game since round 1c)
SPECKLE_MAX = 0.03         # at most this share of lone pixels in a square
MIXED_MAX = 0.25           # at most this share of blocks may mix colours
COLOURS_MAX = {"island": 14, "palm": 10, "rock": 8, "jump": 24}   # a sprite's colours at most (the Garden's bush_a: 6); others 6


def down(path):
    a = np.asarray(Image.open(path).convert("RGBA"))
    h, w = a.shape[:2]
    assert h % K == 0 and w % K == 0, f"{path.name}: {w}x{h} is not a multiple of {K}"
    H, W = h // K, w // K
    blocks = a.reshape(H, K, W, K, 4).transpose(0, 2, 1, 3, 4).reshape(H, W, K * K, 4)
    op = blocks[..., 3] > 127
    out = np.zeros((H, W, 4), np.uint8)
    mixed = 0
    for y, x in zip(*np.nonzero(op.sum(-1) > K * K // 2)):
        px = blocks[y, x][op[y, x], :3]
        cols, counts = np.unique(px, axis=0, return_counts=True)
        out[y, x, :3] = cols[counts.argmax()]
        out[y, x, 3] = 255
        mixed += counts.max() < len(px)
    n = max(1, int((op.sum(-1) > K * K // 2).sum()))
    return out, mixed / n


def detail(a):
    op = a[..., 3] > 0
    b = a[..., :3].astype(int)
    ch = (np.abs(b[:, 1:] - b[:, :-1]).sum(-1) > 0) & op[:, 1:] & op[:, :-1]
    return ch.sum() / max(1, (op[:, 1:] & op[:, :-1]).sum())


def speckle(a):
    """Share of pixels unlike all four of their neighbours"""
    b = a[..., :3].astype(int)
    c = b[1:-1, 1:-1]
    lone = np.ones(c.shape[:2], bool)
    for n in (b[:-2, 1:-1], b[2:, 1:-1], b[1:-1, :-2], b[1:-1, 2:]):
        lone &= np.abs(c - n).sum(-1) > 0
    return lone.mean()


def seam(a):
    """Share of edge pixels whose wrap-around neighbour differs a lot (0: tiles cleanly)"""
    b = a[..., :3].astype(int)
    lr = np.abs(b[:, 0] - b[:, -1]).sum(-1) > 60
    tb = np.abs(b[0] - b[-1]).sum(-1) > 60
    return (lr.sum() + tb.sum()) / (2 * SQ)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    game = "--game" in sys.argv
    rings = {}
    bad = 0
    for path in sorted(PAINT.glob("*_4x.png")):
        name = path.name[: -len("_4x.png")]
        a, mixed = down(path)
        problems = []
        kind = name.rsplit("_", 1)[0]
        if kind in SQUARES:
            if a.shape[:2] != (SQ, SQ):
                problems.append(f"{a.shape[1]}x{a.shape[0]}, not {SQ}x{SQ}")
            elif (a[..., 3] < 255).any():
                problems.append("transparent pixels in a square")
            else:
                lo, hi = DETAIL.get(kind, (0.0, 1.0))
                if not lo <= detail(a) <= hi:
                    problems.append(f"{100 * detail(a):.0f}% detail, want {100 * lo:.0f}-{100 * hi:.0f}%")
                if speckle(a) > SPECKLE_MAX:
                    problems.append(f"{100 * speckle(a):.0f}% lone pixels (speckle), want under {100 * SPECKLE_MAX:.0f}%")
                if seam(a) > 0.1:
                    problems.append(f"doesn't tile ({100 * seam(a):.0f}% of the edge jumps)")
                ring = np.concatenate([a[:3].reshape(-1, 4), a[-3:].reshape(-1, 4), a[:, :3].reshape(-1, 4), a[:, -3:].reshape(-1, 4)])
                if kind in rings and not np.array_equal(rings[kind][1], ring):
                    problems.append(f"outer 3 px differ from {rings[kind][0]}")
                rings.setdefault(kind, (name, ring))
        if mixed > MIXED_MAX:
            problems.append(f"{100 * mixed:.0f}% of 4x4 blocks mix colours (soft brush or off the grid)")
        colours = len(np.unique(a[a[..., 3] > 0][:, :3], axis=0))
        cap = COLOURS_MAX.get(kind.split("_")[0], 6 if kind not in SQUARES else 12)
        if colours > cap:
            problems.append(f"{colours} colours, want {cap} or fewer (flat pixel-art colours, like the Garden's)")
        ok = not problems
        bad += not ok
        print(f"{'ok ' if ok else 'BAD'} {name}: {a.shape[1]}x{a.shape[0]}, {colours} colours, {100 * detail(a):.0f}% detail"
              + ("" if ok else "  <- " + "; ".join(problems)))
        Image.fromarray(a).save(OUT / f"{name}.png")
        if game and ok:
            Image.fromarray(a).save(GAME / f"{name}.png")
    print("all fit" if not bad else f"{bad} don't fit (not written to the game)")


if __name__ == "__main__":
    main()
