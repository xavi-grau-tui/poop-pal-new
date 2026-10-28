"""RC Prix Lagoon: the pixel-density reference for the designer. Run from the repo root:

    <python with Pillow> tools/art/rcprix_lagoon_density_sheet.py

Writes docs/mockups/rcprix_lagoon/reference/pixel_density.png: the Garden's delivered art (the target
density) next to the Lagoon's sizes and today's Lagoon (twice as chunky), at the game's scale and at 4x."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
GARDEN = ROOT / "textures/minigames/rcprix/garden"
OLD = ROOT / "docs/mockups/rcprix_lagoon/current/level_9.png"
OUT = ROOT / "docs/mockups/rcprix_lagoon/reference/pixel_density.png"
BG = (250, 246, 238)
INK = (40, 30, 40)
RED = (200, 40, 60)
GREEN = (40, 140, 70)


def font(size):
    for f in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf"):
        if Path(f).exists():
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def g(name):
    return Image.open(GARDEN / f"{name}.png").convert("RGBA")


def zoom(im, k):
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def main():
    old = Image.open(OLD).convert("RGBA")
    # today's Lagoon: one of its pixels is 2x2 of the new grid; this crop (95 old px) is one 190 square
    old_sq = zoom(old.crop((300, 230, 395, 325)), 2)
    old_isle = zoom(old.crop((118, 10, 182, 46)), 2)

    W, H = 1660, 1480
    sheet = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(sheet)
    T, t, s = font(30), font(20), font(16)

    d.text((30, 20), "RC Prix Lagoon: pixel density = the Garden's", font=T, fill=INK)
    d.text((30, 60), "One game pixel = 2 world px. A course square: Garden 180 px, Lagoon 190 px. Draw at this density, "
                     "on the real grid.", font=t, fill=INK)

    # 1. at the game's scale (x2 here so it's readable; everything on this row is the same scale)
    y = 110
    d.text((30, y), "1. Same scale, side by side (all shown x2)", font=t, fill=INK)
    y += 34
    x = 30
    row = [("Garden grass_a 180x180", zoom(g("grass_a"), 2), GREEN),
           ("Garden road corner 180x180", zoom(g("corner_ne"), 2), GREEN),
           ("Lagoon today: 190 px of it", zoom(old_sq, 2), RED)]
    for label, im, col in row:
        sheet.paste(im, (x, y), im)
        d.text((x, y + im.height + 6), label, font=s, fill=col)
        x += im.width + 30
    d.rectangle([x, y, x + 379, y + 379], outline=INK, width=2)
    d.text((x + 20, y + 170), "your Lagoon square\n190x190 px", font=t, fill=INK)
    d.text((x, y + 386), "same size as the Garden's", font=s, fill=GREEN)

    # 2. zoomed: one game pixel = a 4x4 block
    y += 380 + 60
    d.text((30, y), "2. Zoomed x4 (one game pixel = one 4x4 block): the Garden's detail is the target", font=t, fill=INK)
    y += 34
    x = 30
    for label, im, col in [("Garden bush_a (96x82)", zoom(g("bush_a"), 4), GREEN),
                           ("flowers", zoom(g("flowers_a"), 4), GREEN),
                           ("Garden grass, 60x60 of it", zoom(g("grass_a").crop((0, 0, 60, 60)), 4), GREEN)]:
        sheet.paste(im, (x, y), im)
        d.text((x, y + im.height + 6), label, font=s, fill=col)
        x += im.width + 30
    y2 = y
    for label, im in [("Lagoon today: an island, too chunky", zoom(old_isle, 4)),
                      ("Lagoon today: bank and starfish", zoom(old.crop((588, 14, 624, 44)), 8))]:
        sheet.paste(im, (x, y2), im)
        d.text((x, y2 + im.height + 6), label, font=s, fill=RED)
        y2 += im.height + 40
    # 3. the rules in short
    y = H - 210
    d.text((30, y), "3. In short", font=t, fill=INK)
    rules = [
        "- The Garden's files are the density target: count the pixels in a bush, a flower, a grass blade; match it.",
        "- Today's Lagoon is twice as chunky (each of its pixels = 2x2 of yours): don't copy its pixel size.",
        "- Draw on the real grid at the final size (190x190 for a square). Never shrink a bigger painting.",
        "- Every pixel fully opaque or fully transparent, no soft edges, nearest-neighbour export.",
        "- Light from the top left, outline #281E28 (or a warm dark brown on sand), like the Garden.",
    ]
    for i, r in enumerate(rules):
        d.text((30, y + 34 + i * 30), r, font=s, fill=INK)
    sheet.save(OUT)
    print("written", OUT.relative_to(ROOT), sheet.size)


if __name__ == "__main__":
    main()
