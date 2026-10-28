"""Round 20 look samples: paint the approved glossy finish on locked 3D block-outs.

The block-out renderer supplies the exact silhouettes, top faces, wall faces,
depth order and positions. This pass changes RGB only; every alpha pixel is
identical to the corresponding block-out.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import rcprix_barrier_blockout as model

ROOT = Path(__file__).resolve().parents[2]
GARDEN = ROOT / "textures/minigames/rcprix/garden"
MOCK = ROOT / "docs/mockups/rcprix_garden"
BLOCKOUT = MOCK / "round20_barrier_blockout"
STUDY_DIR = MOCK / "round20_approved_studies"
PREVIEW = MOCK / "round20_look_sample_3x.png"
INK = np.array((40, 30, 40), dtype=np.uint8)

# top, top shine, specular, side lit, side mid, side dark, top lower bevel
PAINT = {
    "red": ((250, 66, 78), (255, 127, 132), (255, 246, 234),
            (215, 20, 43), (174, 13, 36), (118, 9, 27), (220, 29, 51)),
    "white": ((255, 247, 232), (255, 255, 247), (255, 255, 255),
              (220, 211, 201), (184, 175, 170), (139, 129, 133), (238, 229, 218)),
    "blue": ((21, 122, 229), (76, 177, 255), (245, 254, 255),
             (11, 87, 180), (8, 57, 135), (8, 36, 84), (13, 102, 205)),
    "yellow": ((255, 207, 20), (255, 234, 83), (255, 255, 242),
               (224, 157, 13), (176, 110, 6), (116, 67, 8), (238, 179, 15)),
}


def paint_piece(piece: tuple) -> Image.Image:
    inside, normal, height, colour, extra = piece
    raw = np.asarray(model.render([piece])).copy()
    rgb = raw[..., :3]
    visible = raw[..., 3] > 0
    yy, xx = np.mgrid[0:180, 0:180].astype(float) + 0.5
    top = inside(xx, yy + height)
    if "hole" in extra:
        hole = extra["hole"](xx, yy + height)
        top &= ~hole
    else:
        hole = np.zeros_like(top)

    outline = visible & np.all(rgb == INK, axis=2)
    top &= visible & ~outline
    wall = visible & ~top & ~hole & ~outline
    top_base, top_light, specular, side_lit, side_mid, side_dark, bevel = [
        np.array(c, dtype=np.uint8) for c in PAINT[colour]
    ]
    rgb[top] = top_base

    # Preserve the block-out's wall orientation. The brighter wall is always
    # the one facing the screen's top-left light, regardless of corner.
    original = np.asarray(model.render([piece]))[..., :3]
    sh = model.SHADES[colour]
    for old, new in ((sh[2], side_lit), (sh[3], side_mid), (sh[4], side_dark)):
        rgb[wall & np.all(original == old, axis=2)] = new
    rgb[wall & np.all(original == sh[0], axis=2)] = top_light
    rgb[wall & np.all(original == sh[1], axis=2)] = side_lit

    if colour in ("red", "white"):
        # A rounded-looking upper bevel and white flash, copied from the
        # imagegen material studies but painted within the locked top face.
        up = np.pad(top[:-1, :], ((1, 0), (0, 0)))
        left = np.pad(top[:, :-1], ((0, 0), (1, 0)))
        lit_edge = top & (~up | ~left)
        band = top & ndimage.binary_dilation(lit_edge, iterations=2)
        rgb[band] = top_light
        yx = np.argwhere(top)
        if len(yx):
            min_sum = int(np.min(yx[:, 0] + yx[:, 1]))
            white_flash = band & ((xx + yy) <= min_sum + 17)
            rgb[white_flash] = specular
        # The lower/right rim is a second red or cream tone, giving the top
        # its rounded molded edge while retaining the exact top boundary.
        down = np.pad(top[1:, :], ((0, 1), (0, 0)))
        right = np.pad(top[:, 1:], ((0, 0), (0, 1)))
        lower_edge = top & (~down | ~right) & ~band
        rgb[lower_edge] = bevel
    else:
        # Chunky donut top: broad colored shoulder, deep bore, and two bright
        # pixel arcs on its top-left. Both arcs are built on the final grid.
        px, py = extra["centre"]
        dx, dy = xx - px, yy - (py - height)
        dist = np.hypot(dx, dy)
        radius = model.TYRE["r"]
        outer_shine = top & (dx < -1) & (dy < 1) & (dist > radius - 6) & (dist < radius - 1)
        inner_shine = top & (dx < -1) & (dy > 0) & (dist > model.TYRE["hole"] + 1) & (dist < model.TYRE["hole"] + 4)
        rgb[top & (dx + dy < -6)] = top_light
        rgb[outer_shine | inner_shine] = specular
        lower = top & (dx + dy > 12) & ~(outer_shine | inner_shine)
        rgb[lower] = bevel
        rgb[hole & visible] = np.array((29, 22, 32), dtype=np.uint8)
        hole_edge = top & ndimage.binary_dilation(hole, iterations=2)
        rgb[hole_edge & ~(outer_shine | inner_shine)] = side_dark

    rgb[outline] = INK
    return Image.fromarray(raw, "RGBA")


def paint(name: str) -> None:
    corner = name.split("_")[1]
    alternate = "_alt" in name
    radius = model.road_radius(corner, "")
    pieces = model.tyres(corner, radius) if alternate else model.blocks(corner, radius)
    pieces = sorted(pieces, key=lambda p: p[4]["y"])
    if alternate:
        # The first visible tyre at the top of each corner is blue, then
        # yellow, matching the approved study's reading direction.
        pieces = [(*piece[:3], "blue" if index % 2 == 0 else "yellow", piece[4])
                  for index, piece in enumerate(pieces)]
    image = Image.new("RGBA", (180, 180), (0, 0, 0, 0))
    for piece in pieces:
        image.alpha_composite(paint_piece(piece))
    locked = Image.open(BLOCKOUT / f"{name}.png").convert("RGBA")
    if not np.array_equal(np.asarray(image)[..., 3], np.asarray(locked)[..., 3]):
        raise AssertionError(f"{name}: changed the block-out silhouette")
    image.save(GARDEN / f"{name}.png")


def make_preview(names: list[str]):
    # Four actual delivered PNGs on their road pieces; two approved imagegen
    # studies accompany them for the material comparison.
    cell = 540
    board = Image.new("RGB", (3 * cell, 2 * cell), (33, 29, 35))
    for row, pair in enumerate((names[:2], names[2:])):
        for col, name in enumerate(pair):
            corner = name.split("_")[1]
            tile = Image.open(GARDEN / "grass_a.png").convert("RGBA")
            tile.alpha_composite(Image.open(GARDEN / f"corner_{corner}.png").convert("RGBA"))
            tile.alpha_composite(Image.open(GARDEN / f"{name}.png").convert("RGBA"))
            tile = tile.resize((cell, cell), Image.Resampling.NEAREST).convert("RGB")
            board.paste(tile, (col * cell, row * cell))
        study = Image.open(STUDY_DIR / ("blocks.png" if row == 0 else "tyres.png")).convert("RGBA")
        box = study.getchannel("A").getbbox()
        study = study.crop(box)
        study.thumbnail((cell - 30, cell - 30), Image.Resampling.NEAREST)
        backing = Image.new("RGB", (cell, cell), (33, 29, 35))
        backing.paste(study, ((cell - study.width) // 2, (cell - study.height) // 2), study)
        board.paste(backing, (2 * cell, row * cell))
    pen = ImageDraw.Draw(board)
    for row, row_names in enumerate((names[:2] + ["approved block study"], names[2:] + ["approved tyre study"])):
        for col, name in enumerate(row_names):
            pen.rectangle((col * cell, row * cell, col * cell + 235, row * cell + 22), fill=(33, 29, 35))
            pen.text((col * cell + 8, row * cell + 5), name, fill=(255, 255, 255))
    board.save(PREVIEW)


def main():
    names = ["tyres_ne", "tyres_se", "tyres_ne_alt", "tyres_se_alt"]
    for name in names:
        paint(name)
    make_preview(names)
    print(f"Painted {', '.join(names)} and {PREVIEW}")


if __name__ == "__main__":
    main()
