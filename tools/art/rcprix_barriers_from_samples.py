"""The corner barriers made from the two approved samples themselves (the user, 2026-10-27: the delivered set
didn't look like options A and B). Run from the repo root:

    <python with Pillow + numpy + scipy> tools/art/rcprix_barriers_from_samples.py

Each block / tyre is cut out of its sample pixel for pixel (by its fill colour; the outline goes to the nearest
one) and set down again outside the road, its curb and its side face, round the corner's arc, never turned:
  tyres_<corner>[_wide]      the toy blocks of option B (red / white); a block at each place is the sample's
                             block lying that way, or its mirror image (the light still from the left)
  tyres_<corner>_alt[_wide]  the tyres of option A, recoloured blue / yellow
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
SAMPLES = ROOT / "docs/mockups/rcprix_garden/round18_samples"
OUT = ROOT / "textures/minigames/rcprix/garden"
SQ = 180
CENTRES = {"ne": (180, 0), "nw": (0, 0), "se": (180, 180), "sw": (0, 180)}   # each corner's arc round this point
GAP = 3                      # px of grass between the road's outer edge and a barrier
ANGLES = 88                  # the arc used, degrees of its 90 (the ends kept off the square's edges)


def elements(path):
    """The sample's pieces: [(rgba image, centroid x, y, colour 0/1)], in the sample's ne corner"""
    a = np.asarray(Image.open(path).convert("RGBA")).astype(int)
    op = a[..., 3] > 0
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    red = op & (r > g + 50)
    white = op & (r > 150) & (g > 150) & (b > 140) & ~red
    labels = np.zeros(op.shape, int)
    seeds = []
    n = 0
    for kind, mask in ((0, red), (1, white)):
        lab, k = ndimage.label(mask, np.ones((3, 3)))
        for i in range(1, k + 1):
            m = lab == i
            if m.sum() < 25:
                continue
            n += 1
            labels[m] = n
            seeds.append(kind)
    _, (iy, ix) = ndimage.distance_transform_edt(labels == 0, return_indices=True)
    labels = np.where(op, labels[iy, ix], 0)
    out = []
    for i in range(1, n + 1):
        m = labels == i
        ys, xs = np.nonzero(m)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        px = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
        px[m[y0:y1, x0:x1]] = a[y0:y1, x0:x1][m[y0:y1, x0:x1]]
        out.append((Image.fromarray(px), xs.mean() - x0, ys.mean() - y0, xs.mean(), ys.mean(), seeds[i - 1]))
    return out


def recolour_blue_yellow(im):
    """Option A's red / white tyres as blue / yellow (the same shading)"""
    a = np.asarray(im).astype(float)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    red = (r > g + 50) & (a[..., 3] > 0)
    white = (r > 150) & (g > 150) & (b > 140) & ~red & (a[..., 3] > 0)
    out = a.copy()
    lum = r * 0.3 + g * 0.59 + b * 0.11
    k = np.clip(r / 230.0, 0, 1.2)
    out[..., :3][red] = np.stack([60 * k, 110 * k, 210 * k], -1)[red]
    kw = np.clip(lum / 235.0, 0, 1.1)
    out[..., :3][white] = np.stack([250 * kw, 200 * kw, 70 * kw], -1)[white]
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))


def build(pieces, road, corner, turnable):
    """The barrier for one corner: pieces along the arc just outside the road (its opaque pixels)"""
    cx, cy = CENTRES[corner]
    ys, xs = np.nonzero(np.asarray(road)[..., 3] > 0)
    r_out = np.hypot(xs - cx, ys - cy).max()
    base = {"ne": 90, "nw": 0, "se": 180, "sw": 270}[corner]     # the arc's angles (image y down)
    # the pool: each piece with the way it lies (its tangent, mod 180); mirrored ones too for blocks
    pool = []
    for im, ox, oy, sx, sy, kind in pieces:
        phi = np.degrees(np.arctan2(sy - 180, sx - 0))     # (the samples' arc is round the bottom-left corner)
        lie = (phi + 90) % 180
        pool.append((im, ox, oy, kind, lie))
        if turnable:
            pool.append((im.transpose(Image.FLIP_LEFT_RIGHT), im.width - 1 - ox, oy, kind, (180 - lie) % 180))
    size = np.mean([max(p[0].size) for p in pieces])
    r_mid = r_out + GAP + size / 2.0
    pitch = np.mean([p[0].width if turnable else p[0].width for p in pieces]) * 0.98
    count = max(3, int(round(np.radians(ANGLES) * r_mid / pitch)))
    canvas = Image.new("RGBA", (SQ, SQ))
    for i in range(count):
        phi = base + (90 - ANGLES) / 2 + ANGLES * (i + 0.5) / count
        want_lie = (phi + 90) % 180
        kind = i % 2
        cands = [p for p in pool if p[3] == kind] or pool
        im, ox, oy, _, lie = min(cands, key=lambda p: min(abs(p[4] - want_lie), 180 - abs(p[4] - want_lie)))
        # the piece's inner edge just past the road: push it out until no pixel is within r_out + GAP
        a = np.asarray(im)[..., 3] > 0
        pys, pxs = np.nonzero(a)
        u = np.array([np.cos(np.radians(phi)), np.sin(np.radians(phi))])
        rad = (pxs - ox) * u[0] + (pys - oy) * u[1]
        r_c = r_out + GAP - rad.min() + 0.5
        x = cx + u[0] * r_c - ox
        y = cy + u[1] * r_c - oy
        canvas.alpha_composite(im, (int(round(x)), int(round(y))))
    return canvas


def main():
    blocks = elements(SAMPLES / "tyres_ne_option_b.png")
    tyres = [(recolour_blue_yellow(im), ox, oy, sx, sy, k) for im, ox, oy, sx, sy, k in elements(SAMPLES / "tyres_ne_option_a.png")]
    for wide in ("", "_wide"):
        for corner in CENTRES:
            road = Image.open(OUT / f"corner_{corner}{wide}.png").convert("RGBA")
            build(blocks, road, corner, True).save(OUT / f"tyres_{corner}{wide}.png")
            build(tyres, road, corner, False).save(OUT / f"tyres_{corner}_alt{wide}.png")
    print("16 barriers made:", len(blocks), "blocks,", len(tyres), "tyres cut from the samples")


if __name__ == "__main__":
    main()
