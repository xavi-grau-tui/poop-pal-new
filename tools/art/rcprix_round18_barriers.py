"""Build Round 18's approved corner barriers on the final 180 px grid.

The approved samples define two looks: painted donut tyres and chunky toy
blocks. This script lays those shapes outside the road's locked orange side
face and redraws every orientation with the screen's top-left light source.
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

from rcprix_templates import ROAD_HALF, ROAD_HALF_WIDE, SIDE, SQ

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/garden"
INK = (40, 30, 40, 255)  # #281E28

TYRE_PALETTES = {
    "red": ((224, 57, 57, 255), (163, 39, 48, 255), (255, 131, 97, 255)),
    "white": ((241, 235, 218, 255), (178, 171, 164, 255), (255, 253, 235, 255)),
    "blue": ((66, 125, 197, 255), (42, 78, 135, 255), (135, 190, 239, 255)),
    "yellow": ((238, 187, 58, 255), (171, 120, 42, 255), (255, 224, 110, 255)),
}
BLOCK_PALETTES = {
    "red": ((222, 57, 59, 255), (155, 38, 47, 255), (255, 132, 103, 255)),
    "white": ((242, 235, 217, 255), (174, 168, 161, 255), (255, 252, 235, 255)),
    "blue": ((67, 126, 194, 255), (43, 77, 132, 255), (137, 190, 237, 255)),
    "yellow": ((239, 188, 59, 255), (171, 120, 42, 255), (255, 224, 111, 255)),
}


def basis(corner: str, theta: float, radius: float):
    """Position and tangent/radial axes for a quarter-circle corner."""
    cx = SQ if corner[1] == "e" else 0
    cy = 0 if corner[0] == "n" else SQ
    sx = -1 if cx else 1
    sy = 1 if cy == 0 else -1
    center = (cx + sx * radius * math.cos(theta),
              cy + sy * radius * math.sin(theta))
    tangent = (sx * -math.sin(theta), sy * math.cos(theta))
    radial = (sx * math.cos(theta), sy * math.sin(theta))
    return center, tangent, radial


def arc_centers(corner: str, half: int, count: int = 7):
    # Outer road edge is radius 90+half. The orange side face extends another
    # 12 px; leave a small grass gap after the barrier's inner edge.
    # Wider roads move the whole barrier out by the same six pixels.
    radius = SQ / 2 + half + SIDE + 12 + 2
    # Trim the tangencies slightly so the largest pieces stay completely in
    # the 180x180 tile while still following the road's outer corner.
    t0, t1 = 0.20, math.pi / 2 - 0.20
    for i in range(count):
        theta = t0 + (t1 - t0) * i / (count - 1)
        yield theta, basis(corner, theta, radius)


def tyre(draw: ImageDraw.ImageDraw, center: tuple[float, float], colour: str):
    x, y = (round(v) for v in center)
    face, shade, light = TYRE_PALETTES[colour]
    # 25 px outer diameter; a solid painted casing, simple deep hub, and
    # broad top-left catchlight keep the ring readable at native scale.
    draw.ellipse((x - 12, y - 12, x + 12, y + 12), fill=INK)
    draw.ellipse((x - 11, y - 11, x + 11, y + 11), fill=face)
    draw.arc((x - 10, y - 10, x + 10, y + 10), 15, 150, fill=shade, width=3)
    draw.arc((x - 10, y - 10, x + 10, y + 10), 196, 268, fill=light, width=3)
    draw.ellipse((x - 5, y - 5, x + 5, y + 5), fill=INK)
    draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(54, 47, 57, 255))


def block(draw: ImageDraw.ImageDraw, center, tangent, radial, colour: str):
    face, shade, light = BLOCK_PALETTES[colour]
    x, y = center
    tx, ty = tangent
    rx, ry = radial
    half_len, half_depth = 10, 7

    def p(along, outward, offset=(0, 0)):
        return (round(x + tx * along + rx * outward + offset[0]),
                round(y + ty * along + ry * outward + offset[1]))

    # The outward face has a small down-right thickness. Draw it first so the
    # lit top plane remains crisp and the shadow never falls onto the road.
    a, b = p(-half_len, -half_depth), p(half_len, -half_depth)
    c, d = p(half_len, half_depth), p(-half_len, half_depth)
    drop = (1, 2)
    draw.polygon([d, c, (c[0] + drop[0], c[1] + drop[1]),
                  (d[0] + drop[0], d[1] + drop[1])], fill=INK)
    draw.polygon([d, c, (c[0] + drop[0], c[1] + drop[1]),
                  (d[0] + drop[0], d[1] + drop[1])], fill=shade)
    # Rounded pixel corners on the molded block.
    draw.polygon([a, b, c, d], fill=INK)
    inset = [p(-half_len + 1, -half_depth + 1),
             p(half_len - 1, -half_depth + 1),
             p(half_len - 1, half_depth - 1),
             p(-half_len + 1, half_depth - 1)]
    draw.polygon(inset, fill=face)
    # Choose the screen-space upper-left corner, so every orientation receives
    # light from the same direction rather than inheriting a mirrored bevel.
    corners = [a, b, c, d]
    lit = min(range(4), key=lambda i: corners[i][0] + corners[i][1])
    draw.line((corners[lit], corners[(lit - 1) % 4]), fill=light, width=1)
    draw.line((corners[lit], corners[(lit + 1) % 4]), fill=light, width=1)
    hx, hy = corners[lit]
    draw.rectangle((hx + 1, hy + 1, hx + 2, hy + 2), fill=light)
    # Keep the extrusion's lower edge outlined after the top face is painted.
    draw.line([c, (c[0] + drop[0], c[1] + drop[1]),
               (d[0] + drop[0], d[1] + drop[1]), d], fill=INK, width=1)


def make(corner: str, half: int, kind: str, alternate: bool) -> Image.Image:
    im = Image.new("RGBA", (SQ, SQ), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    pair = ("blue", "yellow") if alternate else ("red", "white")
    for i, (_, (center, tangent, radial)) in enumerate(arc_centers(corner, half)):
        colour = pair[i % 2]
        if kind == "tyres":
            tyre(d, center, colour)
        else:
            block(d, center, tangent, radial, colour)
    return im


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for half, suffix in ((ROAD_HALF, ""), (ROAD_HALF_WIDE, "_wide")):
        for corner in ("ne", "nw", "se", "sw"):
            for alt, kind in ((False, "blocks"), (True, "tyres")):
                name = f"tyres_{corner}{'_alt' if alt else ''}{suffix}"
                sprite = make(corner, half, kind, alt)
                road = Image.open(OUT / f"corner_{corner}{suffix}.png").convert("RGBA")
                if alpha_overlap(sprite, road):
                    raise AssertionError(f"{name} overlaps the road, curb, or side face")
                sprite.save(OUT / f"{name}.png")
    print("Wrote 16 Round 18 corner barrier sprites to", OUT)


def alpha_overlap(a: Image.Image, b: Image.Image) -> bool:
    """True when any barrier pixel covers any road/curb/side-face pixel."""
    aa = a.getchannel("A").get_flattened_data()
    ba = b.getchannel("A").get_flattened_data()
    return any(x and y for x, y in zip(aa, ba))


if __name__ == "__main__":
    main()
