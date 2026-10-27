"""Draw the RC Prix Garden road pilot and its three lawn variants on the exact tile grid.

The imagegen concept in the conversation guides the palette. Geometry is drawn
here so the straights and four quarter-circle corners share exact join pixels.
Run with the project's .venv Python (Pillow).
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

from rcprix_templates import CURB, ROAD_HALF, SIDE, SQ


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/garden"

PLUM = (40, 30, 40, 255)
ROAD = (104, 103, 112, 255)
ROAD_LIGHT = (111, 109, 117, 255)
ROAD_SHADE = (85, 85, 98, 255)
LINE = (240, 233, 218, 255)
RED = (223, 50, 53, 255)
RED_LIGHT = (248, 81, 67, 255)
WHITE = (248, 240, 221, 255)
WHITE_SHADE = (222, 215, 204, 255)
ORANGE_LIGHT = (255, 187, 64, 255)
ORANGE = (226, 136, 50, 255)
ORANGE_SHADE = (151, 76, 43, 255)

GRASS = (125, 191, 71, 255)
GRASS_LIGHT = (149, 207, 80, 255)
GRASS_SHADE = (111, 177, 73, 255)
FLOWER_PINK = (235, 169, 176, 255)
FLOWER_CREAM = (251, 231, 177, 255)


def road_coordinates(name: str, x: int, y: int) -> tuple[float, float]:
    """Signed distance from the 90px centre arc and length along its travel."""
    if name == "straight_h":
        return y + 0.5 - SQ / 2, x + 0.5
    if name == "straight_v":
        return x + 0.5 - SQ / 2, y + 0.5
    corner = name[-2:]
    cx = SQ if corner[1] == "e" else 0
    cy = 0 if corner[0] == "n" else SQ
    # Snap the two exit edges to the analytic join line. Sampling at pixel
    # centres there makes a circle differ from its tangent straight by 1px.
    xx = cx if x == (SQ - 1 if cx else 0) else x + 0.5
    yy = cy if y == (0 if cy == 0 else SQ - 1) else y + 0.5
    dx, dy = xx - cx, yy - cy
    radius = math.hypot(dx, dy)
    angle = math.atan2(dy, dx)
    if corner == "ne":
        progress = math.pi - angle  # north to east
    elif corner == "nw":
        progress = angle  # east to north
    elif corner == "se":
        progress = math.pi - abs(angle)  # west to south
    else:
        progress = abs(angle)  # south to east
    return radius - SQ / 2, progress * SQ / 2


def is_top(name: str, x: int, y: int) -> bool:
    offset, _ = road_coordinates(name, x, y)
    return abs(offset) < ROAD_HALF


def paint_top(offset: float, progress: float, corner: bool) -> tuple[int, int, int, int]:
    away = abs(offset)
    length = SQ * math.pi / 4 if corner else SQ
    # The 1px plum contour is identical at every join.
    if away >= ROAD_HALF - 1:
        return PLUM
    if away >= ROAD_HALF - CURB:
        # Half a red block at each exit: joining two pieces makes one complete
        # stripe. 16 blocks fit a straight, 12 fit a 90px-radius quarter arc.
        stripe_length = length / (12 if corner else 16)
        stripe = int((progress + stripe_length / 2) // stripe_length) % 2
        if stripe:
            return WHITE_SHADE if away >= ROAD_HALF - 2 else WHITE
        return RED_LIGHT if away < ROAD_HALF - 2 else RED
    if away >= ROAD_HALF - CURB - 1:
        return ROAD_SHADE
    if away >= ROAD_HALF - CURB - 5:
        return ROAD_SHADE
    dash_period = length / (5 if corner else 6)
    dash_phase = progress % dash_period
    if away < 1.8 and abs(dash_phase - dash_period / 2) < 5.5:
        return LINE
    # Symmetric bands keep the four quarter arcs identical at their tangent
    # joins with straights; the old speckled asphalt is deliberately gone.
    if away < 17:
        return ROAD_LIGHT
    return ROAD


def paint_side(name: str, x: int, y: int) -> tuple[int, int, int, int] | None:
    # A vertically shifted copy of the road top supplies only its south-facing
    # exposed side. This is the same depth on straight and corner pieces.
    if not is_top(name, x, y - SIDE):
        return None
    depth = 0
    for up in range(1, SIDE + 1):
        if is_top(name, x, y - up):
            depth = up
            break
    if depth <= 1 or depth >= SIDE:
        return PLUM
    if depth <= 4:
        return ORANGE_LIGHT
    if depth <= 9:
        return ORANGE
    return ORANGE_SHADE


def draw_road(name: str) -> Image.Image:
    im = Image.new("RGBA", (SQ, SQ), (0, 0, 0, 0))
    pixels = im.load()
    for y in range(SQ):
        for x in range(SQ):
            side = paint_side(name, x, y)
            if name.startswith("corner_") and y == (0 if name[-2] == "n" else SQ - 1):
                side = None  # the north/south join is tangent to a vertical straight
            if side is not None:
                pixels[x, y] = side
            offset, progress = road_coordinates(name, x, y)
            if abs(offset) < ROAD_HALF:
                pixels[x, y] = paint_top(offset, progress, name.startswith("corner_"))
    return im


def draw_grass(variant: int) -> Image.Image:
    im = Image.new("RGBA", (SQ, SQ), GRASS)
    d = ImageDraw.Draw(im)
    # Small irregular planes leave most of the lawn quiet. The large leafy
    # silhouettes in the imagegen concept belong to later decor sprites.
    patches = (
        (
            ([(20, 27), (34, 24), (41, 28), (48, 28), (52, 37), (39, 39), (31, 44), (19, 39)], GRASS_LIGHT),
            ([(115, 24), (136, 20), (142, 27), (149, 31), (145, 42), (124, 43), (113, 36)], GRASS_SHADE),
            ([(41, 99), (55, 93), (67, 95), (72, 104), (62, 110), (47, 108)], GRASS_LIGHT),
            ([(123, 124), (143, 119), (152, 129), (148, 139), (132, 142), (119, 133)], GRASS_SHADE),
        ),
        (
            ([(24, 58), (35, 52), (48, 57), (52, 68), (39, 72), (23, 67)], GRASS_SHADE),
            ([(100, 25), (118, 20), (126, 29), (118, 38), (103, 36)], GRASS_LIGHT),
            ([(89, 112), (105, 106), (121, 115), (116, 126), (98, 129), (85, 122)], GRASS_LIGHT),
        ),
        (
            ([(46, 20), (62, 17), (70, 24), (66, 34), (51, 36), (42, 29)], GRASS_LIGHT),
            ([(128, 72), (143, 68), (152, 77), (144, 87), (130, 84)], GRASS_SHADE),
            ([(28, 127), (43, 120), (56, 126), (52, 136), (36, 139), (25, 134)], GRASS_SHADE),
        ),
    )
    for points, col in patches[variant]:
        d.polygon(points, fill=col)
    flowers = (
        ((28, 34, FLOWER_CREAM), (135, 54, FLOWER_PINK), (62, 140, FLOWER_CREAM)),
        ((54, 26, FLOWER_PINK), (142, 139, FLOWER_CREAM)),
        ((25, 82, FLOWER_CREAM), (106, 48, FLOWER_PINK), (127, 137, FLOWER_CREAM)),
    )
    for x, y, flower in flowers[variant]:
        for dx, dy in ((-4, 0), (3, -3), (5, 5), (-2, 6)):
            fx, fy = x + dx, y + dy
            d.rectangle((fx - 2, fy + 2, fx + 3, fy + 4), fill=GRASS_SHADE)
            d.rectangle((fx, fy, fx + 2, fy + 2), fill=flower)
            d.point((fx + 1, fy + 1), fill=WHITE)
    return im


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    names = ("straight_h", "straight_v", "corner_ne", "corner_nw", "corner_se", "corner_sw")
    for name in names:
        draw_road(name).save(OUT / f"{name}.png")
    for i, letter in enumerate("abc"):
        draw_grass(i).save(OUT / f"grass_{letter}.png")
    print("wrote 6 road and 3 grass files to", OUT)


if __name__ == "__main__":
    main()
