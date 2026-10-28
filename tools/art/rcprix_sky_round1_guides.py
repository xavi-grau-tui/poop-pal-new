"""RC Prix Sky, round 1: the designer's paint guides and the style canvas. Run from the repo root:

    <python with Pillow + numpy> tools/art/rcprix_sky_round1_guides.py

The sizes come from rc_racer.gd (one game px = 2 world px, the Garden's):
  view      VIEW 896x830 screen px at ZOOM 1.5: 299x277 game px on the phone
  ring      Ring: radius r (world) across the course, its depth r * 0.42, the tube TUBE 14 world each side of
            its centre line: 7 game px. Rings sit on straights only, so they face 4 ways: a course going up or
            down the screen sees the wide ring (painted), one going sideways the tall one (the wide one
            flipped over its diagonal, which keeps the light top left). The game cuts it along the course's
            crossing line: the half the plane flies in by over it, the other under it.
            Sizes: ring_r 124 .. 96 (Sky), 104 .. 86 (Grand Prix): painted at 124, 112, 100, 88
  pad       SkyDock: back 20 * STEP (160 world), ahead 6 * STEP (48), half half_w * 0.72 (94): 104 x 94 game px,
            its side face 10 game px under it; a rotor at each corner, its arm 15 game px out at 45 degrees,
            its disc 16 x 9 game px (radius); the start line 12 game px wide, 24 from the front
  stand     the Garden's stand pieces (end_a, mid, end_b, under + over), its canopy turned light blue,
            assembled with two middles; the cloud it sits on is marked round its foot
Writes docs/mockups/rcprix_sky/guides/*_guide_4x.png (pink corner marks: keep them) and previews."""
import colorsys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/mockups/rcprix_sky/guides"
GARDEN = ROOT / "textures/minigames/rcprix/garden"
K = 4
SKY = (200, 224, 244, 255)
INK = (40, 30, 40, 255)
PINK = (255, 0, 255, 255)
RING_SIZES = (124, 112, 100, 88)
TUBE = 7                                       # game px each side of the tube's centre line
DEPTH = 0.42


def corners(im):
    px = im.load()
    for x, y in ((0, 0), (im.width - 1, 0), (0, im.height - 1), (im.width - 1, im.height - 1)):
        px[x, y] = PINK
    return im


def big(im):
    return corners(im.resize((im.width * K, im.height * K), Image.NEAREST))


def ring(r_world):
    """The wide ring (a course going up or down the screen), r_world across: the tube's band pale red, its
    centre line (where it counts as flown through) darker, the cut across the middle in ink"""
    R = r_world / 2.0
    W = int(2 * (R + TUBE)) + 6
    H = int(2 * (R * DEPTH + TUBE)) + 6
    a = np.zeros((H, W, 4), np.uint8)
    a[:] = SKY
    cx, cy = W / 2.0, H / 2.0
    for y in range(H):
        for x in range(W):
            qx, qy = x + 0.5 - cx, y + 0.5 - cy
            u, v = qx / R, qy / (R * DEPTH)
            rho = np.hypot(u, v)
            g = np.hypot(qx / (R * R), qy / (R * R * DEPTH * DEPTH))
            across = (rho - 1.0) / max(1e-4, g / max(1e-4, rho))
            if abs(across) <= TUBE:
                a[y, x] = (236, 150, 150, 255) if abs(across) > 0.6 else (190, 80, 90, 255)
    a[int(cy), :] = np.where(a[int(cy), :, :1] == SKY[0], np.array(SKY), np.array(INK))
    return Image.fromarray(a)


def pad(vertical):
    """The start pad for a course going east (vertical: north): its top, side face, the start line's place,
    the rotors' arms and discs"""
    L, Wd, side, arm, rx, ry = 104, 94, 10, 15, 16, 9
    m = arm + rx + 2
    tw, th = (Wd, L) if vertical else (L, Wd)
    W, H = tw + 2 * m, th + 2 * m + side
    im = Image.new("RGBA", (W, H), SKY)
    d = ImageDraw.Draw(im)
    x0, y0 = m, m
    d.rectangle((x0, y0 + side, x0 + tw - 1, y0 + th - 1 + side), fill=(96, 100, 124, 255))      # the side face
    d.rectangle((x0, y0, x0 + tw - 1, y0 + th - 1), fill=(150, 160, 184, 255))                   # the top
    if vertical:                                                                                 # the start line
        d.rectangle((x0, y0 + 24 - 6, x0 + tw - 1, y0 + 24 + 5), fill=(244, 240, 226, 255))
    else:
        d.rectangle((x0 + tw - 24 - 6, y0, x0 + tw - 24 + 5, y0 + th - 1), fill=(244, 240, 226, 255))
    for cxp in (x0, x0 + tw - 1):
        for cyp in (y0, y0 + th - 1):
            sx = -1 if cxp == x0 else 1
            sy = -1 if cyp == y0 else 1
            hx, hy = cxp + sx * arm * 0.71, cyp + sy * arm * 0.71
            d.line((cxp, cyp, hx, hy), fill=INK, width=2)
            d.ellipse((hx - rx, hy - ry, hx + rx, hy + ry), outline=(255, 255, 255, 255), fill=(226, 236, 248, 255))
            d.rectangle((hx - 1, hy - 1, hx + 1, hy + 1), fill=INK)
    return im


def blue_canopy(im):
    """The stand's green canopy and seats turned light blue (as the Lagoon turned them warm)"""
    a = np.array(im.convert("RGBA")).astype(float) / 255.0
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            r, g, b, al = a[y, x]
            if al <= 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r, g, b)
            if s > 0.25 and 0.2 < h < 0.5:
                a[y, x, :3] = colorsys.hsv_to_rgb(0.56, min(1.0, s * 0.55), min(1.0, v * 1.35))
    return Image.fromarray((a * 255).astype(np.uint8))


def stand(view, mids=2):
    """The Garden's stand in one view, assembled (under then over), on a sky with the cloud's place round its foot"""
    names = ("end_a", *("mid",) * mids, "end_b")
    layers = []
    for layer in ("under", "over"):
        layers.append([blue_canopy(Image.open(GARDEN / f"stand_{view}_{layer}_{n}.png")) for n in names])
    along_x = view in ("front", "back")
    pieces = layers[0]
    long = sum(p.width if along_x else p.height for p in pieces)
    thick = pieces[0].height if along_x else pieces[0].width
    cloud = 22
    W = (long if along_x else thick) + 2 * cloud
    H = (thick if along_x else long) + 2 * cloud
    im = Image.new("RGBA", (W, H), SKY)
    d = ImageDraw.Draw(im)
    # where the cloud goes: round its foot (the bottom of a front / back view, the whole of a side view's
    # lower end and its sides), drawn as a pale band to paint over
    if along_x:
        d.rounded_rectangle((4, H - cloud - 34, W - 5, H - 5), 18, fill=(246, 250, 255, 255))
    else:
        d.rounded_rectangle((4, 4, W - 5, H - 5), 18, outline=(246, 250, 255, 255), width=cloud - 4)
    for row in layers:
        at = 0
        for p in row:
            im.alpha_composite(p, (cloud + at, cloud) if along_x else (cloud, cloud + at))
            at += p.width if along_x else p.height
    # pink ticks on the edge where the pieces meet (end_a | mid | mid | end_b): the cloud is cut there, and
    # its two middles must be the same, so the game can repeat one for a longer stand
    px = im.load()
    at = cloud
    for p in pieces[:-1]:
        at += p.width if along_x else p.height
        for k in range(4):
            if along_x:
                px[at, k] = PINK
            else:
                px[k, at] = PINK
    return im


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for r in RING_SIZES:
        big(ring(r)).save(OUT / f"ring_{r}_guide_4x.png")
    # the scale: today's plane (52 game px) by the biggest ring, both ways round
    wide = ring(124)
    tall = wide.transpose(Image.TRANSPOSE)
    plane = Image.new("RGBA", (52, 52), (0, 0, 0, 0))            # (its silhouette, nose up: wings, body, tail)
    pd = ImageDraw.Draw(plane)
    pd.rectangle((0, 16, 51, 27), fill=(226, 70, 64, 255))
    pd.rectangle((20, 2, 31, 49), fill=(250, 210, 84, 255))
    pd.rectangle((12, 40, 39, 47), fill=(226, 70, 64, 255))
    prev = Image.new("RGBA", (wide.width + tall.width + 30, max(wide.height, tall.height) + 20), SKY)
    prev.alpha_composite(wide, (10, 10))
    prev.alpha_composite(tall, (wide.width + 20, 10))
    prev.alpha_composite(plane, (10 + wide.width // 2 - 26, 10 + wide.height // 2 - 26))
    prev.alpha_composite(plane.rotate(-90), (wide.width + 20 + tall.width // 2 - 26, 10 + tall.height // 2 - 26))
    prev.resize((prev.width * K, prev.height * K), Image.NEAREST).save(OUT / "ring_both_ways_preview.png")
    big(pad(False)).save(OUT / "pad_east_guide_4x.png")
    big(pad(True)).save(OUT / "pad_north_guide_4x.png")
    for view in ("front", "back", "side_l", "side_r"):
        big(stand(view)).save(OUT / f"stand_cloud_{view}_guide_4x.png")
    big(Image.new("RGBA", (299, 277), SKY)).save(OUT / "style_canvas_4x.png")
    print("written to", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
