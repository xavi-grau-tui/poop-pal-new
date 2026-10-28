"""Paint the Round 22 barriers on the fixed 308px block-outs, then export at 4x."""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import rcprix_barrier_blockout as model

ROOT = Path(__file__).resolve().parents[2]
MOCK = ROOT / "docs/mockups/rcprix_garden"
GUIDES = MOCK / "round22_paint_guides"
BLOCKOUT = MOCK / "round21_barrier_blockout"
STUDIES = MOCK / "round20_approved_studies"
OUT = MOCK / "round22_paint"
PREVIEW = MOCK / "round22_look_sample_3x.png"
SHEET = MOCK / "round22_full_set_on_guides_2x.png"
K = 4
SIZE = model.W
INK = np.asarray(model.INK, dtype=np.uint8)

# Glossy study finish: top fill, broad lit tone, specular shine, three wall
# tones, and the dark foot. The original game masks still define every edge.
SURFACE = {
    "red": {
        "top": (235, 39, 55), "light": (255, 110, 120), "shine": (255, 251, 241),
        "wall_lit": (213, 29, 46), "wall": (176, 15, 36),
        "wall_dark": (120, 8, 26), "foot": (91, 9, 25),
    },
    "white": {
        "top": (255, 248, 234), "light": (255, 255, 248), "shine": (255, 255, 255),
        "wall_lit": (221, 213, 204), "wall": (184, 174, 170),
        "wall_dark": (139, 129, 132), "foot": (105, 99, 106),
    },
    "blue": {
        "top": (12, 119, 230), "light": (79, 180, 255), "shine": (250, 255, 255),
        "wall_lit": (9, 91, 190), "wall": (7, 60, 143),
        "wall_dark": (5, 36, 91), "foot": (4, 25, 66),
    },
    "yellow": {
        "top": (255, 199, 18), "light": (255, 230, 73), "shine": (255, 255, 245),
        "wall_lit": (223, 153, 10), "wall": (176, 108, 5),
        "wall_dark": (116, 65, 5), "foot": (84, 47, 5),
    },
}


def paint_piece(piece: tuple) -> Image.Image:
    inside, _normal, height, colour, extra = piece
    raw = np.asarray(model.render([piece])).copy()
    original = raw[..., :3].copy()
    rgb = raw[..., :3]
    visible = raw[..., 3] > 0
    yy, xx = np.mgrid[0:SIZE, 0:SIZE].astype(float) + 0.5
    top = inside(xx, yy + height) & visible
    hole = np.zeros_like(top)
    if "centre" in extra:
        px, py = extra["centre"]
        dx, dy = xx - px, yy + height - py
        radius = np.hypot(dx, dy)
        hole = radius <= model.TYRE["hole"]
        top &= ~hole

    outline = visible & np.all(original == INK, axis=2)
    top &= ~outline
    wall = visible & ~top & ~hole & ~outline
    p = SURFACE[colour]
    sh = model.SHADES[colour]
    rgb[top] = p["top"]
    for old, new in (
        (sh[2], p["wall_lit"]), (sh[3], p["wall"]),
        (sh[4], p["wall_dark"]), (sh[5], p["foot"]),
    ):
        rgb[wall & np.all(original == old, axis=2)] = new
    # The block-out already places its top-left rim and wall-facing rim. Give
    # those pixels the brighter study tones while keeping its exact footprint.
    rgb[wall & np.all(original == sh[0], axis=2)] = p["light"]
    rgb[wall & np.all(original == sh[1], axis=2)] = p["wall_lit"]

    if "centre" in extra:
        # Broad doughnut shoulder, shaded lower-right arc, deep bore, and a
        # bright two-pixel crescent at upper-left. Pixel size is still one
        # game pixel here; export below makes each pixel a hard 4x4 block.
        px, py = extra["centre"]
        dx, dy = xx - px, yy + height - py
        dist = np.hypot(dx, dy)
        direction = -(0.6 * dx + 0.8 * dy) / np.maximum(dist, 0.001)
        inner = model.TYRE["hole"]
        outer = model.TYRE["r"]
        upper_left = top & (direction > 0.38)
        rgb[upper_left & (dist < (inner + outer) / 2)] = p["light"]
        shine = upper_left & (np.abs(dist - (inner + outer) / 2) <= 1.0)
        rgb[shine] = p["shine"]
        rgb[top & (direction < -0.3)] = p["wall_lit"]
        rgb[hole & visible] = (27, 19, 31)
        # A small shaded inner lip adds depth without changing the hole mask.
        inner_lip = top & (dist <= inner + 1.2)
        rgb[inner_lip & ~shine] = p["wall_dark"]
        # Give the tyre a visible body below its ring. The geometry already
        # contains this narrow side face; use a confident dark lower band so
        # the tyre reads upright without changing its guide silhouette.
        side = wall
        lower_band = side & (yy >= py - height + 1)
        rgb[lower_band] = p["wall_dark"]
        bottom_edge = side & (yy >= py - 1)
        rgb[bottom_edge] = p["foot"]
    else:
        # Gloss across each brick's upper-left edge, with a short white flash.
        up = np.pad(top[:-1, :], ((1, 0), (0, 0)))
        left = np.pad(top[:, :-1], ((0, 0), (1, 0)))
        edge = top & (~up | ~left)
        broad = top & ndimage.binary_dilation(edge, iterations=1)
        rgb[broad] = p["light"]
        coords = np.argwhere(top)
        if len(coords):
            # Each brick gets its own highlight, at its screen-space upper-left.
            score = xx + yy
            lo = float(np.min(score[top]))
            white = broad & top & (score <= lo + 4)
            rgb[white] = p["shine"]
        down = np.pad(top[1:, :], ((0, 1), (0, 0)))
        right = np.pad(top[:, 1:], ((0, 0), (0, 1)))
        lower_bevel = top & (~down | ~right) & ~broad
        rgb[lower_bevel] = p["wall_lit"]

    rgb[outline] = INK
    return Image.fromarray(raw, "RGBA")


def paint_native(name: str) -> Image.Image:
    corner = name.split("_")[1]
    suffix = "_wide" if name.endswith("_wide") else ""
    edge = model.road_edge(corner, suffix)
    pieces = model.tyres(corner, edge) if "_alt" in name else model.blocks(corner, edge)
    result = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    for piece in sorted(pieces, key=lambda item: item[4]["y"]):
        result.alpha_composite(paint_piece(piece))
    original = Image.open(BLOCKOUT / f"{name}.png").convert("RGBA")
    if not np.array_equal(np.asarray(result)[..., 3], np.asarray(original)[..., 3]):
        raise AssertionError(f"{name}: paint changed the block-out silhouette")
    return result


def pink_marks(guide: Image.Image) -> np.ndarray:
    rgb = np.asarray(guide.convert("RGB"))
    return np.all(rgb == (255, 0, 255), axis=2)


def export_4x(name: str) -> Image.Image:
    native = paint_native(name)
    enlarged = native.resize((SIZE * K, SIZE * K), Image.Resampling.NEAREST)
    guide = Image.open(GUIDES / f"{name}_guide_4x.png").convert("RGBA")
    if guide.size != enlarged.size:
        raise AssertionError(f"{name}: guide size is {guide.size}, expected {enlarged.size}")
    pixels = np.asarray(enlarged).copy()
    # Keep only the guide's four registration marks outside the transparent art.
    marks = pink_marks(guide)
    pixels[marks] = (255, 0, 255, 255)
    out = Image.fromarray(pixels, "RGBA")
    # Every game-grid sample must be a single exact 4x4 color block.
    arr = np.asarray(out)
    cells = arr.reshape(SIZE, K, SIZE, K, 4)
    if not (cells == cells[:, :1, :, :1, :]).all():
        raise AssertionError(f"{name}: output is not aligned to the 4x4 grid")
    OUT.mkdir(parents=True, exist_ok=True)
    out.save(OUT / f"{name}_paint_4x.png")
    return out


def road_canvas(corner: str) -> Image.Image:
    # Rebuild the unmarked road background used by the guides.
    t = Image.new("RGBA", (SIZE, SIZE), (112, 170, 76, 255))
    t.alpha_composite(Image.open(model.TILES / f"corner_{corner}.png").convert("RGBA"), (model.RUN, model.RUN))
    offsets = {"n": (0, -1), "s": (0, 1), "e": (1, 0), "w": (-1, 0)}
    for edge in model.ENDS[corner]:
        dx, dy = offsets[edge]
        road = Image.open(model.TILES / ("straight_v.png" if dy else "straight_h.png")).convert("RGBA")
        box = (
            0 if dx > 0 else (model.SQ - model.RUN if dx < 0 else 0),
            0 if dy > 0 else (model.SQ - model.RUN if dy < 0 else 0),
            model.RUN if dx > 0 else model.SQ if dx < 0 else model.SQ,
            model.RUN if dy > 0 else model.SQ if dy < 0 else model.SQ,
        )
        at = (
            model.RUN + model.SQ if dx > 0 else 0 if dx < 0 else model.RUN,
            model.RUN + model.SQ if dy > 0 else 0 if dy < 0 else model.RUN,
        )
        t.alpha_composite(road.crop(box), at)
    return t


def make_preview(painted: dict[str, Image.Image]) -> None:
    names = ("tyres_ne", "tyres_se_alt")
    studies = ("round18_samples/tyres_ne_option_b.png", "round18_samples/tyres_ne_option_a.png")
    glossy = ("round20_approved_studies/blocks.png", "round20_approved_studies/tyres.png")
    cells = []
    for i, name in enumerate(names):
        game = road_canvas(name.split("_")[1])
        game.alpha_composite(painted[name].resize((SIZE, SIZE), Image.Resampling.NEAREST))
        cells.append(game.convert("RGB"))
        for ref in (studies[i], glossy[i]):
            source = Image.open(MOCK / ref).convert("RGBA")
            crop = source.crop(source.getchannel("A").getbbox())
            crop.thumbnail((SIZE - 24, SIZE - 24), Image.Resampling.NEAREST)
            cell = Image.new("RGB", (SIZE, SIZE), (33, 29, 35))
            cell.paste(crop, ((SIZE - crop.width) // 2, (SIZE - crop.height) // 2), crop)
            cells.append(cell)
    board = Image.new("RGB", (SIZE * 3, SIZE * 2), (33, 29, 35))
    for i, cell in enumerate(cells):
        board.paste(cell, ((i % 3) * SIZE, (i // 3) * SIZE))
    labels = ("tyres_ne on road", "approved B", "glossy block study",
              "tyres_se_alt on road", "approved A", "glossy tyre study")
    draw = ImageDraw.Draw(board)
    for i, label in enumerate(labels):
        x, y = (i % 3) * SIZE, (i // 3) * SIZE
        draw.rectangle((x, y, x + 190, y + 20), fill=(33, 29, 35))
        draw.text((x + 5, y + 4), label, fill=(255, 255, 255))
    board.resize((board.width * 3, board.height * 3), Image.Resampling.NEAREST).save(PREVIEW)


def make_full_guide_sheet(names: list[str]) -> None:
    """Composite the exact delivered exports onto each current guide."""
    cell_size = 616  # 2x game-pixel preview; source remains the full 4x PNG.
    cols = 4
    rows = (len(names) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell_size, rows * cell_size), (35, 31, 38))
    for i, name in enumerate(names):
        guide = Image.open(GUIDES / f"{name}_guide_4x.png").convert("RGBA")
        art = Image.open(OUT / f"{name}_paint_4x.png").convert("RGBA")
        if guide.size != art.size:
            raise AssertionError(f"{name}: guide and paint dimensions differ")
        guide.alpha_composite(art)
        # Nearest-neighbour preserves the 4x paint grid while fitting the set
        # into a legible 4-by-4 contact sheet.
        tile = guide.resize((cell_size, cell_size), Image.Resampling.NEAREST).convert("RGB")
        sheet.paste(tile, ((i % cols) * cell_size, (i // cols) * cell_size))
        draw = ImageDraw.Draw(sheet)
        x, y = (i % cols) * cell_size, (i // cols) * cell_size
        draw.rectangle((x, y, x + 155, y + 25), fill=(35, 31, 38))
        draw.text((x + 6, y + 6), name, fill=(255, 255, 255))
    sheet.save(SHEET)


def main():
    names = [
        f"tyres_{corner}{alt}{wide}"
        for wide in ("", "_wide")
        for corner in ("ne", "nw", "se", "sw")
        for alt in ("", "_alt")
    ]
    painted = {name: export_4x(name) for name in names}
    make_preview({name: painted[name] for name in ("tyres_ne", "tyres_se_alt")})
    make_full_guide_sheet(names)
    print(f"Created {len(names)} 4x barriers in {OUT}; guide sheet: {SHEET}")


if __name__ == "__main__":
    main()
