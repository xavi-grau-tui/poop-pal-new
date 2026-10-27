"""Make the round-two RC Prix Garden approval sample, without replacing pilot art.

Only one straight and one corner are delivered here. Their road masks use the
approved template geometry; the new stripe/dash phases and material treatment
can be reviewed before the full 76-file set is drawn.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

from rcprix_templates import CURB, ROAD_HALF, SIDE, SQ
from rcprix_garden_pilot import road_coordinates, is_top


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/mockups/rcprix_garden/round2_sample"

PLUM = (40, 30, 40, 255)
ASPHALT = (105, 104, 114, 255)
ASPHALT_LIT = (113, 111, 120, 255)
ASPHALT_SHADE = (96, 95, 106, 255)
GRAIN_LIT = (119, 117, 125, 255)
GRAIN_DARK = (92, 91, 102, 255)
CURB_LINE = (72, 65, 75, 255)
RED = (220, 47, 52, 255)
RED_LIT = (250, 84, 67, 255)
WHITE = (249, 242, 226, 255)
WHITE_SHADE = (222, 217, 207, 255)
DASH = (248, 244, 233, 255)
SIDE_LIT = (255, 181, 60, 255)
SIDE_DARK = (188, 101, 45, 255)
GRASS = (125, 191, 71, 255)
GRASS_LIT = (151, 207, 79, 255)
GRASS_MID = (109, 174, 70, 255)
GRASS_SHADE = (83, 145, 65, 255)


def arc_length(radius: float) -> float:
    return radius * math.pi / 2


def road_color(name: str, offset: float, progress: float) -> tuple[int, int, int, int]:
    away = abs(offset)
    corner = name.startswith("corner_")
    length = arc_length(SQ / 2) if corner else SQ
    if away >= ROAD_HALF - 1:
        return PLUM
    if away >= ROAD_HALF - CURB:
        # A whole number of 10px-ish red/white blocks ends with white and the
        # next piece starts red. Each curb arc uses its own actual radius.
        outer = offset > 0
        radius = SQ / 2 + (ROAD_HALF - CURB / 2) * (1 if outer else -1)
        stripe_length = (arc_length(radius) / (20 if outer else 8)) if corner else 10.0
        curb_progress = min(progress, length - 1e-6) * radius / (SQ / 2) if corner else progress
        white = int(curb_progress // stripe_length) % 2 == 1
        if white:
            return WHITE_SHADE if away >= ROAD_HALF - 2 else WHITE
        return RED if away >= ROAD_HALF - 2 else RED_LIT
    if away >= ROAD_HALF - CURB - 1:
        return CURB_LINE  # raised curb's 1px road-side lip
    if away >= ROAD_HALF - CURB - 5:
        return ASPHALT_SHADE
    dash_period = length / (5 if corner else 6)
    if away < 1.8 and abs(progress % dash_period - dash_period / 2) < 5:
        return DASH
    # These distance bands run parallel to a straight and become concentric
    # arcs in a corner. They have no progress-based ends or angular patches.
    if away < 17:
        return ASPHALT_LIT
    if away < 29:
        return ASPHALT_SHADE
    return ASPHALT


def side_color(name: str, x: int, y: int):
    if not is_top(name, x, y - SIDE):
        return None
    depth = next((up for up in range(1, SIDE + 1) if is_top(name, x, y - up)), 0)
    if depth == SIDE:
        return PLUM
    return SIDE_LIT if depth <= 5 else SIDE_DARK


def local_xy(name: str, progress: float, offset: float) -> tuple[int, int]:
    if name == "straight_h":
        return round(progress), round(SQ / 2 + offset)
    # Sample corner_se: south exit (start) to east exit (end).
    radius = SQ / 2 + offset
    angle = -math.pi + progress / (SQ / 2)
    return round(SQ + radius * math.cos(angle)), round(SQ + radius * math.sin(angle))


def draw_piece(name: str) -> Image.Image:
    image = Image.new("RGBA", (SQ, SQ), (0, 0, 0, 0))
    pixels = image.load()
    corner = name.startswith("corner_")
    for y in range(SQ):
        for x in range(SQ):
            side = side_color(name, x, y)
            if corner and y == SQ - 1:
                side = None  # vertical straight joins the south exit
            if side is not None:
                pixels[x, y] = side
            offset, progress = road_coordinates(name, x, y)
            if abs(offset) < ROAD_HALF:
                pixels[x, y] = road_color(name, offset, progress)
    # Sparse placed single-pixel grain in two near-asphalt tones; no dither.
    length = arc_length(SQ / 2) if corner else SQ
    for i in range(2, 14):
        progress = length * i / 15
        for j, offset in enumerate((-28, -8, 23)):
            if (i + j) % 3 == 0:
                continue
            x, y = local_xy(name, progress + j * 1.7, offset)
            if 0 <= x < SQ and 0 <= y < SQ and pixels[x, y] in (ASPHALT, ASPHALT_LIT, ASPHALT_SHADE):
                pixels[x, y] = GRAIN_LIT if (i + j) % 2 else GRAIN_DARK
    return image


def draw_grass() -> Image.Image:
    image = Image.new("RGBA", (SQ, SQ), GRASS)
    d = ImageDraw.Draw(image)
    d.polygon([(17, 32), (35, 27), (44, 35), (39, 46), (19, 42)], fill=GRASS_LIT)
    d.polygon([(121, 104), (145, 99), (153, 112), (145, 123), (124, 118)], fill=GRASS_MID)
    for x, y in ((65, 60), (104, 35), (39, 128), (148, 53)):
        d.rectangle((x + 2, y + 2, x + 5, y + 3), fill=GRASS_SHADE)
        d.rectangle((x, y, x + 2, y + 1), fill=GRASS_LIT)
        d.point((x, y), fill=(173, 219, 91, 255))
    for x, y in ((43, 74), (116, 145)):
        d.rectangle((x - 3, y + 3, x + 4, y + 4), fill=GRASS_MID)
        for dx, dy, color in ((-3, 0, WHITE), (3, -2, WHITE), (0, 3, RED_LIT)):
            d.rectangle((x + dx, y + dy, x + dx + 2, y + dy + 2), fill=color)
    return image


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    corner = draw_piece("corner_se")
    straight = draw_piece("straight_h")
    corner.save(OUT / "corner_se.png")
    straight.save(OUT / "straight_h.png")
    grass = draw_grass()
    board = Image.new("RGBA", (SQ * 2, SQ), (0, 0, 0, 0))
    board.alpha_composite(grass, (0, 0))
    board.alpha_composite(grass, (SQ, 0))
    board.alpha_composite(corner, (0, 0))
    board.alpha_composite(straight, (SQ, 0))
    board.resize((SQ * 4, SQ * 2), Image.Resampling.NEAREST).save(OUT / "joined_preview_2x.png")
    print("saved round-two sample:", OUT)


if __name__ == "__main__":
    main()
