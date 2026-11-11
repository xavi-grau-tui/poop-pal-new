"""The desk fan's spin (the user, 2026-11-11: "leave everything as polished as possible"): the
designer's v2 loop mixed today's still (grey quadrants, a ghost blade) with dark frames and jagged
blades. This builds it from the designer's own clean rotor painting instead:

  rotor_imagegen_v2.png   turned 0, 30 and 60 degrees (four blades: 90 degrees is a full turn),
                          squashed to the cage's oval, reduced to the fan's pixels, snapped to its colours
  shelf_desk_fan_1_v2.png the body, the cage ring and bars (kept exactly), its inside painted dark

Out: docs/mockups/hokora_decor/anim/shelf_desk_fan/shelf_desk_fan_{0,1,2}_ours.png (frame 0 = the new still).

    .venv/bin/python tools/art/fan_spin.py
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
D = ROOT / "docs/mockups/hokora_decor/anim/shelf_desk_fan"
HUB = (106.5, 69.5)          # the hub's centre in the fan's pixels
SIZE = (71, 80)              # the blades' span (w, h) in frame 1: the cage is an upright oval
INSIDE = (31, 10, 27)        # the cage's dark inside
ANGLES = (0, 30, 60)
HUB_R = 11                   # the hub's radius: inside it the rotor's own mint hub, in front of the bars
CAGE = (102, 66, 42, 52)     # the cage's oval (cx, cy, rx, ry), round its inside only
DARK = 90                    # the rotor's outline is darker: dropped (it can't show on the dark inside)


def palette(img, n=12):
    px = img[img[..., 3] > 200][:, :3]
    q, counts = np.unique((px // 6) * 6, axis=0, return_counts=True)
    return q[np.argsort(-counts)[:n]]


def main():
    base = np.array(Image.open(D / "shelf_desk_fan_1_v2.png").convert("RGBA")).astype(int)
    r, g, b = base[..., 0], base[..., 1], base[..., 2]
    mx = base[..., :3].max(-1); mn = base[..., :3].min(-1)
    cream = (base[..., 3] > 0) & (mn > 140) & (mx - mn < 30)      # the ring, the bars and their grey shading
    inside = ndimage.binary_fill_holes(cream) & ~cream
    yy, xx_ = np.mgrid[:base.shape[0], :base.shape[1]]
    inside &= ((xx_ - CAGE[0]) / CAGE[2]) ** 2 + ((yy - CAGE[1]) / CAGE[3]) ** 2 < 1   # not the body's own holes
    hub = (((yy - HUB[1]) ** 2 + (xx_ - HUB[0]) ** 2) <= HUB_R ** 2) & ~((r > g + 60) & (r > 150)) \
        & (base[..., :3].max(-1) > DARK)   # frame 1's mint hub and its highlight, not its blades
    rotor = Image.open(D / "rotor_imagegen_v2.png").convert("RGBA")
    big = np.array(rotor)
    big[big[..., :3].max(-1) < DARK, 3] = 0          # the blades' outline off: clean edges once reduced
    rotor = Image.fromarray(big)
    pal = palette(big)
    ys, xs = np.nonzero(big[..., 3] > 128)
    cx, cy = (xs.min() + xs.max()) / 2, (ys.min() + ys.max()) / 2
    span = max(xs.max() - xs.min(), ys.max() - ys.min())
    for i, ang in enumerate(ANGLES):
        turned = rotor.rotate(-ang, Image.NEAREST, center=(cx, cy))
        w = int(round(turned.width * SIZE[0] / span)); h = int(round(turned.height * SIZE[1] / span))
        small = np.array(turned.resize((w, h), Image.BOX)).astype(int)
        a = small[..., 3] > 128
        a = ndimage.binary_closing(ndimage.binary_opening(a, np.ones((2, 2))), np.ones((2, 2)))   # no hairs, no notches
        rgb = small[..., :3]
        d = ((rgb[:, :, None, :] - pal[None, None]) ** 2).sum(-1)
        idx = ndimage.generic_filter(d.argmin(-1), lambda v: np.bincount(v.astype(int)).argmax(), size=3)  # majority colour
        rgb = pal[idx]
        hy, hx = np.mgrid[:h, :w]
        far = (hx - cx * w / turned.width) ** 2 + (hy - cy * h / turned.height) ** 2 > HUB_R ** 2
        minty = (rgb[..., 1] > rgb[..., 0] + 20)
        pinks = pal[pal[..., 0] > pal[..., 1] + 60]
        dp = ((rgb[:, :, None, :] - pinks[None, None]) ** 2).sum(-1)
        rgb = np.where((minty & far)[..., None], pinks[dp.argmin(-1)], rgb)   # mint only on the hub
        out = base.copy()
        out[inside, :3] = INSIDE
        ox = int(round(HUB[0] - cx * w / turned.width)); oy = int(round(HUB[1] - cy * h / turned.height))
        py, px = np.nonzero(a)
        ty, tx = py + oy, px + ox
        ok = (ty >= 0) & (tx >= 0) & (ty < out.shape[0]) & (tx < out.shape[1])
        ty, tx, py, px = ty[ok], tx[ok], py[ok], px[ok]
        keep = inside[ty, tx] | ((ty - HUB[1]) ** 2 + (tx - HUB[0]) ** 2 <= HUB_R ** 2)
        out[ty[keep], tx[keep], :3] = rgb[py[keep], px[keep]]
        front = cream & (((yy - HUB[1]) ** 2 + (xx_ - HUB[0]) ** 2) > HUB_R ** 2)
        out[front] = base[front]           # the ring and the bars stay in front
        out[hub] = base[hub]               # the hub doesn't turn: the designer's own, from frame 1
        Image.fromarray(out.astype(np.uint8)).save(D / f"shelf_desk_fan_{i}_ours.png")
    print("inside px", inside.sum(), "palette", len(pal))


if __name__ == "__main__":
    main()
