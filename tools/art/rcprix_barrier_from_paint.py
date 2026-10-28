"""Round 22: the designer's barrier paintings into the game. Run from the repo root:

    <python with Pillow + numpy + scipy> tools/art/rcprix_barrier_from_paint.py [--game]

Each docs/mockups/rcprix_garden/round22_paint/<name>_paint_4x.png (1232x1232, painted on a 4x4 grid over its
guide, the pink corner marks kept) comes down to the game's grid: one pixel per 4x4 block, its most common
opaque colour, opaque where most of the block is. The pink marks go. Then each is checked against the layout
(rcprix_barrier_blockout.py): how much of the silhouette matches, and nothing outside the square and its
run-on strips or touching the file's edge. With --game the files are written into the game's folder."""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

import rcprix_barrier_blockout as bo

ROOT = Path(__file__).resolve().parents[2]
PAINT = ROOT / "docs/mockups/rcprix_garden/round22_paint"
OUT = ROOT / "docs/mockups/rcprix_garden/round22_converted"
K = 4


def down(path):
    a = np.asarray(Image.open(path).convert("RGBA"))
    assert a.shape[:2] == (bo.W * K, bo.W * K), f"{path.name}: {a.shape[1]}x{a.shape[0]}"
    pink = (a[..., 0] > 230) & (a[..., 1] < 40) & (a[..., 2] > 230)
    op = (a[..., 3] > 127) & ~pink
    blocks = a.reshape(bo.W, K, bo.W, K, 4).transpose(0, 2, 1, 3, 4).reshape(bo.W, bo.W, K * K, 4)
    opb = op.reshape(bo.W, K, bo.W, K).transpose(0, 2, 1, 3).reshape(bo.W, bo.W, K * K)
    out = np.zeros((bo.W, bo.W, 4), np.uint8)
    for y, x in zip(*np.nonzero(opb.sum(-1) > K * K // 2)):
        px = blocks[y, x][opb[y, x], :3]
        cols, counts = np.unique(px, axis=0, return_counts=True)
        out[y, x, :3] = cols[counts.argmax()]
        out[y, x, 3] = 255
    return Image.fromarray(out)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    game = "--game" in sys.argv
    bad = 0
    for path in sorted(PAINT.glob("*_paint_4x.png")):
        name = path.name.replace("_paint_4x.png", "")
        corner = name.split("_")[1]
        wide = "_wide" if name.endswith("_wide") else ""
        im = down(path)
        mine = np.asarray(im)[..., 3] > 0
        ghost = np.asarray(Image.open(bo.OUT / f"{name}.png"))[..., 3] > 0
        match = (mine & ghost).sum() / max(1, (mine | ghost).sum())
        near, stray = bo.check(im, corner, bo.road_edge(corner, wide))
        colours = len(np.unique(np.asarray(im)[mine], axis=0))
        ok = match >= 0.85 and stray == 0
        bad += not ok
        print(f"{'ok ' if ok else 'BAD'} {name}: {100 * match:.0f}% of the layout, {stray} px out of place, {colours} colours")
        im.save(OUT / f"{name}.png")
        if game and ok:
            im.save(bo.TILES / f"{name}.png")
    print("all fit" if not bad else f"{bad} don't fit (not written to the game)")


if __name__ == "__main__":
    main()
