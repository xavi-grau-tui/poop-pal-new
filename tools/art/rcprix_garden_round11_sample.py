"""Draw the Garden grandstand look sample, flags, and butterfly frames."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/garden"
DOC = ROOT / "docs/mockups/rcprix_garden"
INK = (40, 30, 40, 255)
DEEP = (84, 46, 38, 255)
WOOD_SHADOW = (121, 68, 44, 255)
WOOD_MID = (173, 104, 60, 255)
WOOD_LIT = (211, 142, 83, 255)
WOOD_HI = (245, 190, 116, 255)
GREEN = (70, 132, 69, 255)
GREEN_DARK = (43, 91, 57, 255)
CREAM = (243, 230, 193, 255)
CREAM_SHADE = (199, 186, 158, 255)


def shade(col, amount):
    return tuple(max(0, min(255, v + amount)) for v in col[:3]) + (255,)


def stand_part(width: int, side: str) -> Image.Image:
    """A 68 px deep stand; the 40 px middle can repeat with no seam."""
    im = Image.new("RGBA", (width, 68), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # Garden-green and cream fabric, period 20 so the middle repeats cleanly.
    d.rectangle((0, 0, width - 1, 7), fill=INK)
    d.line((0, 1, width - 1, 1), fill=WOOD_SHADOW)
    for x in range(width):
        is_green = x % 20 < 10
        d.line((x, 2, x, 5), fill=GREEN if is_green else CREAM)
        d.point((x, 2), fill=shade(GREEN, 26) if is_green else (255, 251, 226, 255))
        d.point((x, 6), fill=GREEN_DARK if is_green else CREAM_SHADE)
        # One-pixel scallops alternate at the awning's front edge.
        if (x % 10) not in (0, 9):
            d.point((x, 7), fill=GREEN_DARK if is_green else CREAM_SHADE)
    # Five full 12 px seating steps. The back/top rows receive more light.
    for row in range(5):
        y = 8 + row * 12
        falloff = -row * 5
        d.rectangle((0, y, width - 1, y + 1), fill=DEEP)
        d.line((0, y + 2, width - 1, y + 2), fill=shade(WOOD_HI, falloff))
        d.rectangle((0, y + 3, width - 1, y + 7), fill=shade(WOOD_LIT, falloff))
        d.line((0, y + 4, width - 1, y + 4), fill=shade(WOOD_HI, falloff - 8))
        d.rectangle((0, y + 8, width - 1, y + 9), fill=shade(WOOD_MID, falloff))
        d.line((0, y + 10, width - 1, y + 10), fill=WOOD_SHADOW)
        d.line((0, y + 11, width - 1, y + 11), fill=INK)
        # Broad 2px grain and pair of iron nails, away from repeat seams.
        for x in range(8, width - 5, 20):
            d.rectangle((x, y + 6, x + 5, y + 6), fill=shade(WOOD_MID, falloff - 2))
            d.rectangle((x + 4, y + 3, x + 5, y + 4), fill=WOOD_SHADOW)
    # End posts only at the outer ends; the middle has no artificial edge.
    if side in ("a", "b"):
        x0 = 0 if side == "a" else width - 6
        x1 = x0 + 5
        d.rectangle((x0, 0, x1, 67), fill=INK)
        d.rectangle((x0 + 1, 2, x1 - 1, 65), fill=WOOD_SHADOW)
        d.rectangle((x0 + 1, 3, x0 + 2, 62), fill=WOOD_HI)
        d.line((x1 - 1, 7, x1 - 1, 63), fill=DEEP, width=1)
        for y in (8, 31, 55):
            d.rectangle((x0 + 1, y, x1 - 1, y + 2), fill=INK)
            d.rectangle((x0 + 2, y, x1 - 2, y + 1), fill=WOOD_LIT)
        d.rectangle((x0, 64, x1, 67), fill=INK)
        d.rectangle((x0 + 1, 64, x1 - 1, 65), fill=WOOD_MID)
    return im


def flag(frame: int) -> Image.Image:
    im = Image.new("RGBA", (12, 20), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((1, 1, 3, 19), fill=INK)
    d.rectangle((2, 2, 2, 18), fill=WOOD_LIT)
    d.rectangle((2, 1, 3, 2), fill=WOOD_HI)
    if frame == 0:
        outer = [(3, 3), (7, 3), (11, 6), (9, 9), (11, 11), (3, 10)]
        inside = [(4, 4), (7, 4), (10, 6), (8, 9), (9, 10), (4, 9)]
        fold = [(6, 7), (8, 7), (8, 9), (6, 8)]
    else:
        outer = [(3, 4), (7, 4), (11, 3), (9, 7), (11, 10), (6, 11), (3, 9)]
        inside = [(4, 5), (7, 5), (10, 4), (8, 7), (10, 9), (6, 10), (4, 8)]
        fold = [(7, 5), (9, 5), (7, 8), (6, 8)]
    d.polygon(outer, fill=INK)
    d.polygon(inside, fill=CREAM)
    d.polygon(fold, fill=(174, 177, 177, 255))
    d.line((4, 5, 6, 5), fill=(255, 255, 242, 255), width=1)
    return im


def butterfly(frame: int) -> Image.Image:
    im = Image.new("RGBA", (12, 10), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if frame == 0:
        d.polygon([(4, 3), (2, 1), (0, 2), (0, 5), (3, 7), (5, 6)], fill=INK)
        d.polygon([(7, 3), (9, 1), (11, 2), (11, 5), (8, 7), (6, 6)], fill=INK)
        d.polygon([(3, 2), (1, 3), (1, 5), (4, 6), (5, 5)], fill=(253, 251, 231, 255))
        d.polygon([(8, 2), (10, 3), (10, 5), (7, 6), (6, 5)], fill=(219, 222, 218, 255))
        d.rectangle((2, 4, 3, 4), fill=(166, 171, 170, 255))
        d.rectangle((8, 4, 9, 4), fill=(151, 157, 158, 255))
    elif frame == 1:
        d.polygon([(4, 3), (2, 1), (1, 3), (2, 6), (5, 7)], fill=INK)
        d.polygon([(7, 3), (9, 1), (10, 3), (9, 6), (6, 7)], fill=INK)
        d.polygon([(4, 3), (3, 2), (2, 4), (4, 6)], fill=(250, 250, 232, 255))
        d.polygon([(7, 3), (8, 2), (9, 4), (7, 6)], fill=(214, 218, 218, 255))
    else:
        d.polygon([(5, 2), (4, 1), (3, 3), (4, 7), (5, 7)], fill=INK)
        d.polygon([(6, 2), (7, 1), (8, 3), (7, 7), (6, 7)], fill=INK)
        d.line((4, 3, 4, 6), fill=(239, 240, 228, 255), width=1)
        d.line((7, 3, 7, 6), fill=(187, 191, 191, 255), width=1)
    d.rectangle((5, 3, 6, 7), fill=INK)
    d.point((5, 2), fill=(91, 86, 89, 255))
    d.line((4, 1, 5, 2), fill=INK)
    d.line((6, 2, 7, 1), fill=INK)
    return im


def stand_preview():
    a = Image.open(OUT / "stand_n_end_a.png").convert("RGBA")
    mid = Image.open(OUT / "stand_n_mid.png").convert("RGBA")
    b = Image.open(OUT / "stand_n_end_b.png").convert("RGBA")
    full = Image.new("RGBA", (220, 68), (0, 0, 0, 0))
    full.alpha_composite(a, (0, 0))
    for x in (20, 60, 100, 140):
        full.alpha_composite(mid, (x, 0))
    full.alpha_composite(mid.crop((0, 0, 20, 68)), (180, 0))
    full.alpha_composite(b, (200, 0))
    # The stand is placed beside a real delivered road tile.
    scene = Image.new("RGBA", (260, 240), (0, 0, 0, 0))
    grass = Image.open(OUT / "grass_a.png").convert("RGBA")
    for y in (0, 180):
        for x in (0, 180):
            scene.alpha_composite(grass, (x, y))
    road = Image.open(OUT / "straight_h.png").convert("RGBA")
    scene.alpha_composite(road, (40, 60))
    scene.alpha_composite(full, (20, 20))
    scene.resize((780, 720), Image.Resampling.NEAREST).save(DOC / "round11_stand_n_sample_3x.png")
    flags = Image.open(OUT / "grass_a.png").convert("RGBA").crop((0, 0, 40, 23))
    flags = flags.resize((160, 92), Image.Resampling.NEAREST).crop((0, 0, 160, 90))
    for i in (0, 1):
        sprite = Image.open(OUT / f"flag_{i}.png").convert("RGBA")
        flags.alpha_composite(sprite.resize((48, 80), Image.Resampling.NEAREST), (12 + i * 80, 5))
    flags.save(DOC / "round11_flags_sample_4x.png")


def butterfly_preview():
    board = Image.open(OUT / "grass_a.png").convert("RGBA").crop((0, 0, 42, 15))
    board = board.resize((252, 90), Image.Resampling.NEAREST).crop((0, 0, 252, 86))
    for i in range(3):
        sprite = Image.open(OUT / f"butterfly_{i}.png").convert("RGBA")
        board.alpha_composite(sprite.resize((72, 60), Image.Resampling.NEAREST), (6 + i * 84, 8))
    board.save(DOC / "round12_butterflies_6x.png")


def main():
    assets = {
        "stand_n_end_a": stand_part(20, "a"),
        "stand_n_mid": stand_part(40, "mid"),
        "stand_n_end_b": stand_part(20, "b"),
        "flag_0": flag(0), "flag_1": flag(1),
        **{f"butterfly_{i}": butterfly(i) for i in range(3)},
    }
    OUT.mkdir(parents=True, exist_ok=True)
    for name, im in assets.items():
        im.save(OUT / f"{name}.png", optimize=True)
    stand_preview()
    butterfly_preview()
    print("Wrote", len(assets), "stand sample, flags, butterflies")


if __name__ == "__main__":
    main()
