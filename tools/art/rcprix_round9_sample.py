"""Draw the approved Round 9 road and tyre set at its final 180 px grid.

The road alpha mask is inherited from the locked geometry renderer. Imagegen's
Round 9 options inform the colours and tyre design; no generated pixels enter
these game PNGs. Run with the project's Pillow environment.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

from rcprix_garden_full import WHITE as SOURCE_WHITE
from rcprix_garden_full import WHITE_SHADE as SOURCE_WHITE_SHADE
from rcprix_garden_full import road_piece, top
from rcprix_garden_pilot import road_coordinates
from rcprix_templates import CURB, ROAD_HALF, ROAD_HALF_WIDE, SIDE, SQ


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/garden"
DOC = ROOT / "docs/mockups/rcprix_garden"

INK = (40, 30, 40, 255)  # #281E28
ASPHALT_EDGE = (76, 82, 94, 255)
ASPHALT = (88, 96, 108, 255)
ASPHALT_WORN = (101, 109, 120, 255)
ASPHALT_STONE = (118, 125, 135, 255)
ASPHALT_TAR = (65, 71, 82, 255)
DASH = (250, 245, 226, 255)
DASH_SHADE = (187, 186, 175, 255)
CURB_ROAD_LINE = (49, 45, 55, 255)
RED_TOP = (255, 123, 88, 255)
RED_FACE = (215, 49, 51, 255)
RED_SHADE = (138, 34, 44, 255)
WHITE_TOP = (255, 255, 240, 255)
WHITE_FACE = (241, 235, 218, 255)
WHITE_SHADE = (172, 168, 162, 255)
SIDE_TOP = (255, 190, 70, 255)
SIDE_MID = (224, 132, 48, 255)
SIDE_LOW = (155, 77, 44, 255)


def _motifs(name: str) -> list[tuple[float, float, int, int, tuple[int, int, int, int]]]:
    """Placed material clusters in road coordinates: progress, offset, width, height."""
    length = SQ * math.pi / 4 if name.startswith("corner_") else SQ
    data = [
        (.08, -25, 2, 2, ASPHALT_STONE), (.14, 24, 3, 2, ASPHALT_TAR),
        (.21, -17, 3, 2, ASPHALT_TAR), (.26, 29, 2, 2, ASPHALT_STONE),
        (.33, 14, 2, 2, ASPHALT_TAR), (.39, -29, 3, 2, ASPHALT_STONE),
        (.46, 23, 3, 2, ASPHALT_TAR), (.53, -19, 2, 2, ASPHALT_STONE),
        (.59, 30, 3, 2, ASPHALT_TAR), (.66, -25, 3, 2, ASPHALT_TAR),
        (.72, 15, 2, 2, ASPHALT_STONE), (.79, -31, 3, 2, ASPHALT_TAR),
        (.86, 25, 2, 2, ASPHALT_STONE), (.92, -15, 3, 2, ASPHALT_TAR),
    ]
    return [(f * length, o, w, h, col) for f, o, w, h, col in data]


def _curb_colour(offset: float, half: int, white: bool, name: str):
    # The band is six pixels including the outside outline. Its upper screen
    # edge receives a one-pixel light lip; its lower edge gets a dark bevel.
    if name.startswith("straight_"):
        from_top = round(offset + half) if offset < 0 else round(offset - (half - CURB))
    else:
        # On this N-E corner the radial band is lit from its north-west side.
        from_top = round(offset + half) if offset < 0 else round(half - offset)
    from_top = max(0, min(CURB - 1, from_top))
    if from_top <= 1:
        return WHITE_TOP if white else RED_TOP
    if from_top >= CURB - 2:
        return WHITE_SHADE if white else RED_SHADE
    return WHITE_FACE if white else RED_FACE


def road(name: str, half: int) -> Image.Image:
    source = road_piece(name, half)
    src = source.load()
    out = Image.new("RGBA", (SQ, SQ), (0, 0, 0, 0))
    dst = out.load()
    motifs = _motifs(name)
    length = SQ * math.pi / 4 if name.startswith("corner_") else SQ
    for y in range(SQ):
        for x in range(SQ):
            old = src[x, y]
            if not old[3]:
                continue
            offset, progress = road_coordinates(name, x, y)
            away = abs(offset)
            if away < half:
                if away >= half - 1:
                    colour = INK
                elif away >= half - CURB:
                    # Preserve the geometry renderer's exact stripe choice.
                    white = old in (SOURCE_WHITE, SOURCE_WHITE_SHADE)
                    colour = _curb_colour(offset, half, white, name)
                elif away >= half - CURB - 1:
                    colour = CURB_ROAD_LINE
                else:
                    # Five flat greys. Slight block-sized changes in the worn
                    # band make it follow the road without an airbrushed halo.
                    block = int(progress // 15)
                    wobble = (0, 1, 0, -1, 1, 0, -1, 0, 1, 0, -1, 0, 0)[block % 13]
                    if away >= half - CURB - 5:
                        colour = ASPHALT_EDGE
                    elif abs(offset - 1) < 11 + wobble:
                        colour = ASPHALT_WORN
                    else:
                        colour = ASPHALT
                    for p0, o0, w, h, motif in motifs:
                        # Enlarge each motif to a visible 3–4 px cluster on
                        # the final grid; no isolated single-pixel grain.
                        if abs(progress - p0) < max(w, 4) / 2 and abs(offset - o0) < max(h, 3) / 2:
                            colour = motif
                            break
                    # The centre line follows the existing renderer's exact
                    # dash position. The lower pixel is a darker edge.
                    dash_period = length / (5 if name.startswith("corner_") else 6)
                    phase = progress % dash_period
                    if away < 1.8 and abs(phase - dash_period / 2) < 5:
                        shade = (phase >= dash_period / 2 + 3.5) if name == "straight_v" else offset >= 0.6
                        colour = DASH_SHADE if shade else DASH
                dst[x, y] = colour
            else:
                depth = next((up for up in range(1, SIDE + 1)
                              if top(name, x, y - up, half)), SIDE)
                dst[x, y] = (SIDE_TOP if depth <= 2 else
                             SIDE_MID if depth <= 7 else
                             SIDE_LOW if depth < SIDE else INK)
    assert source.getchannel("A").tobytes() == out.getchannel("A").tobytes()
    return out


def _tyre(draw: ImageDraw.ImageDraw, x: int, y: int, colour: str):
    if colour == "red":
        face, shadow, light = (211, 56, 57, 255), (133, 35, 48, 255), (255, 120, 97, 255)
    elif colour == "white":
        face, shadow, light = (238, 229, 208, 255), (167, 158, 153, 255), (255, 252, 231, 255)
    elif colour == "blue":
        face, shadow, light = (56, 103, 173, 255), (39, 65, 116, 255), (118, 173, 225, 255)
    else:
        face, shadow, light = (232, 179, 47, 255), (150, 101, 38, 255), (255, 218, 103, 255)
    # A hard 11 px silhouette, 1 px outline, dark centre, and a short lit
    # upper-left rim. Each tyre stays readable where its neighbours overlap.
    draw.ellipse((x - 5, y - 5, x + 5, y + 5), fill=INK)
    draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=shadow)
    draw.ellipse((x - 4, y - 4, x + 3, y + 3), fill=face)
    draw.arc((x - 4, y - 4, x + 3, y + 3), 180, 290, fill=light, width=2)
    draw.ellipse((x - 2, y - 2, x + 2, y + 2), fill=INK)
    draw.point((x - 2, y - 2), fill=light)


def tyres(corner: str, half: int, alt: bool) -> Image.Image:
    im = Image.new("RGBA", (SQ, SQ), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx = SQ if corner[1] == "e" else 0
    cy = 0 if corner[0] == "n" else SQ
    sx = -1 if cx else 1
    sy = 1 if cy == 0 else -1
    colours = ("blue", "yellow") if alt else ("red", "white")
    # Arc geometry matches the existing overlay's outside corner. Centres
    # stop within the tile so the first/last tyre form clean rounded caps.
    extra = 1 if half == ROAD_HALF_WIDE else 0
    for row, radial, n, shift in ((0, 15, 22 + extra, 0.0), (1, 5, 21 + extra, 0.5)):
        for i in range(n):
            theta = .095 + (i + shift) * (math.pi / 2 - .19) / (n - .5)
            r = SQ / 2 + half + radial
            x = round(cx + sx * r * math.cos(theta))
            y = round(cy + sy * r * math.sin(theta))
            _tyre(draw, x, y, colours[(i + row) % 2])
    return im


def preview(assets: dict[str, Image.Image]):
    grass = Image.open(OUT / "grass_a.png").convert("RGBA")
    tree = Image.open(OUT / "tree_top.png").convert("RGBA")
    cells = []
    for name in ("straight_h", "corner_ne", "tyres_ne", "tyres_ne_alt"):
        cell = grass.copy()
        if name.startswith("tyres"):
            cell.alpha_composite(assets["corner_ne"])
        cell.alpha_composite(assets[name])
        cells.append(cell)
    cells.append(grass)
    tree_cell = grass.copy()
    tree_cell.alpha_composite(tree, (-10, 0))
    cells.append(tree_cell)
    board = Image.new("RGBA", (SQ * 3, SQ * 2), (0, 0, 0, 0))
    for i, cell in enumerate(cells):
        board.alpha_composite(cell, ((i % 3) * SQ, (i // 3) * SQ))
    board.resize((board.width * 3, board.height * 3), Image.Resampling.NEAREST).save(
        DOC / "round9_sample_actual_pngs_3x.png")


def full_previews():
    """Nearest-neighbour review sheets built only from the delivered PNGs."""
    grass = Image.open(OUT / "grass_a.png").convert("RGBA")
    tree = Image.open(OUT / "tree_top.png").convert("RGBA")

    def tile(name: str, road_name: str | None = None) -> Image.Image:
        cell = grass.copy()
        if road_name:
            cell.alpha_composite(Image.open(OUT / f"{road_name}.png").convert("RGBA"))
        cell.alpha_composite(Image.open(OUT / f"{name}.png").convert("RGBA"))
        return cell

    def sheet(rows: list[list[Image.Image]], filename: str):
        board = Image.new("RGBA", (SQ * len(rows[0]), SQ * len(rows)), (0, 0, 0, 0))
        for y, row in enumerate(rows):
            for x, cell in enumerate(row):
                board.alpha_composite(cell, (x * SQ, y * SQ))
        board.resize((board.width * 3, board.height * 3), Image.Resampling.NEAREST).save(DOC / filename)

    quick = []
    for suffix in ("", "_wide"):
        quick.append([
            tile("straight_h" + suffix),
            tile("tyres_ne" + suffix, "corner_ne" + suffix),
            tile("tyres_ne_alt" + suffix, "corner_ne" + suffix),
        ])
    sheet(quick, "round9_full_actual_pngs_3x.png")

    road_names = ["straight_h", "straight_v", "corner_ne", "corner_nw", "corner_se", "corner_sw"]
    tree_cell = grass.copy()
    tree_cell.alpha_composite(tree, (-10, 0))
    sheet([[tile(name + suffix) for name in road_names] + [tree_cell if not suffix else grass]
           for suffix in ("", "_wide")], "round9_full_roads_3x.png")

    corners = ("ne", "nw", "se", "sw")
    sheet([[tile(f"tyres_{corner}{'_alt' if alt else ''}{suffix}", f"corner_{corner}{suffix}")
            for corner in corners]
           for suffix in ("", "_wide") for alt in (False, True)],
          "round9_full_tyres_3x.png")


def main():
    assets = {}
    for half, suffix in ((ROAD_HALF, ""), (ROAD_HALF_WIDE, "_wide")):
        horizontal = road("straight_h", half)
        vertical = road("straight_v", half)
        assets["straight_h" + suffix] = horizontal
        assets["straight_v" + suffix] = vertical
        for corner in ("ne", "nw", "se", "sw"):
            name = "corner_" + corner
            image = road(name, half)
            # Align painted bevels as well as alpha at both tangent joins.
            hx, sx = (SQ - 1, 0) if corner[1] == "e" else (0, SQ - 1)
            vy, sy = (0, SQ - 1) if corner[0] == "n" else (SQ - 1, 0)
            for y in range(SQ):
                image.putpixel((hx, y), horizontal.getpixel((sx, y)))
            for x in range(SQ):
                image.putpixel((x, vy), vertical.getpixel((x, sy)))
            assets[name + suffix] = image
            for alt in (False, True):
                tyre_name = f"tyres_{corner}{'_alt' if alt else ''}{suffix}"
                assets[tyre_name] = tyres(corner, half, alt)

    for name, image in assets.items():
        path = OUT / f"{name}.png"
        if name.startswith(("straight_", "corner_")) and path.exists():
            old_alpha = Image.open(path).convert("RGBA").getchannel("A").tobytes()
            assert image.getchannel("A").tobytes() == old_alpha, f"locked mask changed: {name}"
        image.save(path)
    preview(assets)
    full_previews()
    print(f"saved {len(assets)} final-grid game PNGs and 3× review sheets")


if __name__ == "__main__":
    main()
