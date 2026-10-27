"""RC Prix · Garden: bushes made from the approved tree's own pixels, so they have exactly its pixel
density (the user, 2026-10-27: the designer's bushes, shrunk from big pictures, looked denser, as if
farther from the camera). A bush's outline is a few round lobes; inside it, the tree's leaves (cut
from the canopy's dense middle), a little darker towards the bottom right for volume; round it the
tree's own dark outline.

    <python with Pillow + numpy + scipy> tools/art/rcprix_bush_from_tree.py [out_dir]
        -> bush_a.png (60×52), bush_b.png (46×40)   (default: textures/minigames/rcprix/garden/)"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
GARDEN = ROOT / "textures" / "minigames" / "rcprix" / "garden"

# each bush: its size, its lobes (centre x, y, radius, px) and where in the tree its leaves come from
BUSHES = {
    "bush_a": ((60, 52), [(19, 21, 14), (38, 17, 14), (46, 33, 12), (28, 35, 14), (14, 36, 9)], (40, 6)),
    "bush_b": ((46, 40), [(15, 18, 12), (31, 15, 11), (33, 28, 10), (17, 29, 10)], (110, 10)),
}


def outline_colour(tree):
    a = tree[..., 3] > 0
    edge = a & ~ndimage.binary_erosion(a)
    cols, n = np.unique(tree[edge][:, :3], axis=0, return_counts=True)
    return cols[n.argmax()]


def bush(tree, size, lobes, at):
    w, h = size
    yy, xx = np.mgrid[0:h, 0:w]
    patch = tree[at[1]:at[1] + h, at[0]:at[0] + w].astype(float)
    lum = patch[..., :3] @ [0.3, 0.59, 0.11]
    blob = np.zeros((h, w), bool)
    for cx, cy, r in lobes:
        blob |= (xx - cx) ** 2 + (yy - cy) ** 2 <= r * r
    blob &= (xx >= 2) & (yy >= 2) & (xx < w - 2) & (yy < h - 2)
    # a leafy edge, as the tree's: near the blob's rim only the lit leaves stay (the dark gaps
    # between them are cut away), deep inside everything stays
    depth = ndimage.distance_transform_edt(blob)
    lit = lum > np.percentile(lum[blob], 45)
    leaves = blob & ((depth > 4) | lit)
    leaves = ndimage.binary_opening(leaves, np.ones((2, 2)))          # (no single stray pixels on the edge)
    leaves = ndimage.binary_fill_holes(leaves)
    lab, n = ndimage.label(leaves)
    if n > 1:                                                         # (one bush: its biggest piece)
        sizes = ndimage.sum(leaves, lab, range(1, n + 1))
        leaves = lab == (int(np.argmax(sizes)) + 1)
    out = np.zeros((h, w, 4), np.uint8)
    out[leaves] = patch[leaves].astype(np.uint8)
    out[leaves, 3] = 255
    # volume: the bottom-right part a step darker, as the tree's shaded side
    shade = leaves & ((xx / w + yy / h) > 1.15)
    out[shade, :3] = (out[shade, :3] * 0.82).astype(np.uint8)
    ring = ndimage.binary_dilation(leaves) & ~leaves
    out[ring, :3] = outline_colour(tree)
    out[ring, 3] = 255
    return Image.fromarray(out, "RGBA")


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else GARDEN
    tree = np.asarray(Image.open(GARDEN / "tree_top.png").convert("RGBA"))
    for name, (size, lobes, at) in BUSHES.items():
        bush(tree, size, lobes, at).save(out / f"{name}.png")
        print("saved", out / f"{name}.png")


if __name__ == "__main__":
    main()
