"""Render Round 17's three review samples directly on their delivery grids."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "docs/mockups/rcprix_garden/round17_sample"
GAME = ROOT / "textures/minigames/rcprix/garden"
INK = (40, 30, 40, 255)  # #281E28
TRANSPARENT = (0, 0, 0, 0)


def wheel(colour: str) -> Image.Image:
    """An 18 px top-down kart tyre, flat-shaded with a painted sidewall ring."""
    palettes = {
        "red": ((203, 55, 58, 255), (145, 39, 48, 255), (255, 134, 105, 255)),
        "white": ((237, 229, 211, 255), (170, 161, 151, 255), (255, 251, 232, 255)),
        "blue": ((67, 115, 177, 255), (43, 75, 125, 255), (139, 188, 229, 255)),
        "yellow": ((231, 179, 55, 255), (163, 118, 47, 255), (255, 224, 117, 255)),
    }
    face, shade, light = palettes[colour]
    im = Image.new("RGBA", (18, 18), TRANSPARENT)
    d = ImageDraw.Draw(im)
    # Fully painted casing: the colour fills the body, not just its inner ring.
    # The 1 px plum outline, upper-left rim light and lower-right shade remain.
    d.ellipse((0, 0, 17, 17), fill=INK)
    d.ellipse((1, 1, 16, 16), fill=face)
    d.pieslice((1, 1, 16, 16), 190, 275, fill=light)
    d.arc((1, 1, 16, 16), 190, 258, fill=(255, 255, 237, 255), width=1)
    d.arc((1, 1, 16, 16), 22, 72, fill=shade, width=2)
    # Chunky darker tread marks; they break the color into tyre-sized clusters.
    for box in ((2, 4, 4, 5), (4, 2, 5, 3), (12, 2, 13, 3),
                (14, 4, 15, 5), (14, 12, 15, 13), (12, 14, 13, 15),
                (4, 14, 5, 15), (2, 12, 3, 13)):
        d.rectangle(box, fill=shade)
    # Dark inner bevel and bore, with the same painted body around the hole.
    d.ellipse((3, 3, 14, 14), fill=INK)
    d.ellipse((4, 4, 13, 13), fill=shade)
    d.ellipse((4, 4, 12, 12), fill=face)
    # Low-poly light and lower-right shade make the tyre read as a raised ring.
    d.arc((4, 4, 12, 12), 196, 257, fill=light, width=2)
    d.arc((4, 4, 12, 12), 22, 75, fill=shade, width=2)
    # Deep central bore and its narrow rim.
    d.ellipse((5, 5, 12, 12), fill=INK)
    d.ellipse((6, 6, 11, 11), fill=(25, 22, 31, 255))
    d.point((6, 6), fill=(88, 82, 87, 255))
    return im


def corner_tyres(alt: bool = False) -> Image.Image:
    """Two staggered arcs, with front tyres layered over the back row."""
    sq, half = 180, 44
    cx, cy = 180, 0
    start, stop = 0.16, math.pi / 2 - 0.16
    result = Image.new("RGBA", (sq, sq), TRANSPARENT)
    redwhite = ("red", "white")
    blueyellow = ("blue", "yellow")
    pair = blueyellow if alt else redwhite

    # Set the inner tread one pixel clear of the curb. The back row overlaps
    # by roughly half a tyre and is painted first so it sits behind the front.
    rows = (("back", 19, 14, 0.5),
            ("front", 10, 16, 0.0))
    back_centres: list[tuple[float, float, int]] = []
    for row_name, radial, count, offset in rows:
        interval = (stop - start) / (count if offset else count - 1)
        for i in range(count):
            theta = start + (i + offset) * interval
            # The orange side face drops 12 px below the road. Follow its
            # south-facing projection so tyres never sit on top of that band.
            radius = sq / 2 + half + radial + 12 * math.sin(theta)
            x = round(cx - radius * math.cos(theta))
            y = round(cy + radius * math.sin(theta))
            if row_name == "back":
                back_centres.append((x, y, i))
            col = pair[(i + (row_name == "back")) % 2]
            result.alpha_composite(wheel(col), (x - 9, y - 9))

    # A few tyres sit on top of the seam as small stacks; their offset shadow
    # gives the overlap a clear top-down depth cue without crossing the curb.
    d = ImageDraw.Draw(result)
    for j in (3, 7, 11):
        x, y, i = back_centres[j]
        col = pair[(i + 1) % 2]
        d.ellipse((x - 6, y + 2, x + 7, y + 8), fill=(30, 27, 36, 255))
        result.alpha_composite(wheel(col), (x - 8, y - 12))
    return result


def preview() -> Image.Image:
    grass = Image.open(GAME / "grass_a.png").convert("RGBA")
    corner = Image.open(GAME / "corner_ne.png").convert("RGBA")
    labels = ("RED / WHITE", "BLUE / YELLOW")
    walls = (Image.open(OUT / "tyres_ne.png"), Image.open(OUT / "tyres_ne_alt.png"))
    panel_w, panel_h = 540, 580
    sheet = Image.new("RGBA", (panel_w * 2 + 30, panel_h), (31, 29, 33, 255))
    d = ImageDraw.Draw(sheet)
    for i, (label, wall) in enumerate(zip(labels, walls)):
        x = 10 + i * (panel_w + 30)
        base = grass.copy()
        base.alpha_composite(corner)
        base.alpha_composite(wall)
        sheet.alpha_composite(base.resize((540, 540), Image.Resampling.NEAREST), (x, 38))
        d.text((x + 12, 8), label, fill=(244, 234, 205, 255))
    return sheet.convert("RGB")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    corner_tyres(False).save(OUT / "tyres_ne.png")
    corner_tyres(True).save(OUT / "tyres_ne_alt.png")
    (OUT / "banner_lap2.png").unlink(missing_ok=True)
    preview().save(OUT / "round17_samples_preview.png")
    # Validate the delivery grid and hard transparency on the actual outputs.
    for name, size in (("tyres_ne.png", (180, 180)), ("tyres_ne_alt.png", (180, 180))):
        im = Image.open(OUT / name).convert("RGBA")
        assert im.size == size, (name, im.size)
        assert set(im.getchannel("A").get_flattened_data()) <= {0, 255}, f"soft alpha in {name}"
    # No tyre pixel may overlap the approved road-and-curb image.
    road = Image.open(GAME / "corner_ne.png").convert("RGBA").getchannel("A")
    for name in ("tyres_ne.png", "tyres_ne_alt.png"):
        a = Image.open(OUT / name).convert("RGBA").getchannel("A")
        overlap = sum(1 for aa, rr in zip(a.get_flattened_data(), road.get_flattened_data()) if aa and rr)
        if overlap:
            raise AssertionError(f"{name} overlaps {overlap} road/curb pixels")
    print(f"Wrote review samples to {OUT}")


if __name__ == "__main__":
    main()
