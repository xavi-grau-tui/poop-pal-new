"""RC Prix Lagoon, round 1 templates for the designer. Run from the repo root:

    <python with Pillow + numpy> tools/art/rcprix_lagoon_templates.py

Writes docs/mockups/rcprix_lagoon/templates/:
  1_textures.png         the 12 seamless squares (4 kinds x 3 variants), 190x190 each, the 3 px border marked
  2_bank_guide.png       a straight and a curve of the channel with the game's exact bands (both widths)
  2_bank_guide_4x.png    the same at 4x, to paint over on a 4x4 grid
The band widths come from scripts/rc_lagoon.gd and rc_racer.gd (art px = 2 world px)."""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/mockups/rcprix_lagoon/templates"
SQ = 190
HALF = {"narrow": 53, "wide": 58}     # the channel's half width, art px (106 / 116 world px)
SHORE = 26                             # the shallows past it (52 world px)
BANK = 20                              # the sand bank (40 world px)
KINDS = ["water", "channel", "shallows", "sand"]
ZONE = {"channel": (150, 90, 130), "shallows": (232, 170, 150), "bank": (244, 220, 166), "water": (212, 142, 143)}
INK = (40, 30, 40)
PINK = (255, 0, 255)


def textures():
    pad, lab = 16, 18
    W = 3 * SQ + 4 * pad
    H = 4 * (SQ + lab) + 5 * pad
    im = Image.new("RGB", (W, H), (250, 246, 238))
    d = ImageDraw.Draw(im)
    for r, kind in enumerate(KINDS):
        for c, v in enumerate("abc"):
            x = pad + c * (SQ + pad)
            y = pad + r * (SQ + lab + pad)
            d.text((x, y), f"{kind}_{v}.png  190x190", fill=INK)
            y += lab
            d.rectangle([x, y, x + SQ - 1, y + SQ - 1], fill=ZONE.get(kind, ZONE["bank"] if kind == "sand" else (200, 200, 200)))
            d.rectangle([x + 3, y + 3, x + SQ - 4, y + SQ - 4], outline=(255, 255, 255))
            d.rectangle([x, y, x + SQ - 1, y + SQ - 1], outline=INK)
    im.save(OUT / "1_textures.png")


def bands(width):
    """Two squares side by side: a straight (left) and a quarter curve (right), the channel's bands"""
    hw = HALF[width]
    M = 12                                                   # (a margin: the wide bank runs 9 px past the square)
    W, H = 2 * SQ, SQ + 2 * M
    yy, xx = np.mgrid[0:H, 0:W] + 0.5
    yy = yy - M
    # the straight: the centre line across the middle of the left square
    d_straight = np.abs(yy - SQ / 2)
    # the curve: on from the straight, turning south round the right square's bottom-left corner, radius
    # half a square (the game's corners)
    d_curve = np.abs(np.hypot(xx - SQ, yy - SQ) - SQ / 2)
    d = np.where(xx < SQ, d_straight, d_curve)
    im = np.zeros((H, W, 3), np.uint8)
    im[:] = ZONE["water"]
    im[d < hw + SHORE + BANK] = ZONE["bank"]
    im[d < hw + SHORE] = ZONE["shallows"]
    im[d < hw] = ZONE["channel"]
    for edge in (hw, hw + SHORE, hw + SHORE + BANK):        # the band edges, one px lines
        im[np.floor(d) == edge] = INK
    im[:, SQ - 1:SQ + 1] = (255, 255, 255)                   # the squares' borders
    im[M - 1, :] = im[M + SQ, :] = (255, 255, 255)
    for x, y in ((0, 0), (W - 2, 0), (0, H - 2), (W - 2, H - 2)):
        im[y:y + 2, x:x + 2] = PINK                          # corner marks (keep them when painting)
    return im


def bank_guide():
    rows = [bands("wide"), bands("narrow")]
    gap = 12
    H = sum(r.shape[0] for r in rows) + gap
    im = np.full((H, rows[0].shape[1], 3), 250, np.uint8)
    im[:rows[0].shape[0]] = rows[0]
    im[rows[0].shape[0] + gap:] = rows[1]
    Image.fromarray(im).save(OUT / "2_bank_guide.png")
    Image.fromarray(im).resize((im.shape[1] * 4, im.shape[0] * 4), Image.NEAREST).save(OUT / "2_bank_guide_4x.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    textures()
    bank_guide()
    print("written to", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
