"""Turn an approved north grandstand into the other three track orientations.

Run only after the north stand look sample has been reviewed. Geometry is
turned, then wood highlights and shadows are repainted for screen-top-left sun.
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/garden"
DOC = ROOT / "docs/mockups/rcprix_garden"
INK = (40, 30, 40, 255)
WOOD_LIGHT = (235, 178, 111, 255)
WOOD_SHADE = (111, 65, 47, 255)


def relight(im: Image.Image, direction: str, end: bool) -> Image.Image:
    """Screen-space light pass after the structural turn."""
    im = im.copy()
    pix = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pix[x, y]
            if a == 0 or max(r, g, b) < 55:
                continue
            # Keep awning fabric's colours, shade wood and metal by screen
            # position. The top-left always receives more light.
            wood = r > g * 1.18 and r > b * 1.35
            if not wood:
                continue
            delta = round(9 * (1 - x / max(1, w - 1) - y / max(1, h - 1)))
            pix[x, y] = tuple(max(0, min(255, v + delta)) for v in (r, g, b)) + (255,)
    d = ImageDraw.Draw(im)
    if direction == "s":
        x0, x1 = (6, w - 7) if end else (0, w - 1)
        if x0 <= x1:
            for y in range(0, 60, 12):
                d.line((x0, y + 2, x1, y + 2), fill=WOOD_LIGHT)
                d.line((x0, y + 10, x1, y + 10), fill=WOOD_SHADE)
    else:
        y0, y1 = (6, h - 7) if end else (0, h - 1)
        if y0 <= y1:
            first = 8 if direction == "w" else 0
            for x in range(first, first + 60, 12):
                d.line((x + 2, y0, x + 2, y1), fill=WOOD_LIGHT)
                d.line((x + 10, y0, x + 10, y1), fill=WOOD_SHADE)
    return im


def part(name: str, turn: Image.Transpose, direction: str, end: bool) -> Image.Image:
    src = Image.open(OUT / f"stand_n_{name}.png").convert("RGBA")
    return relight(src.transpose(turn), direction, end)


def main():
    mappings = {
        "s": (Image.Transpose.ROTATE_180, ("end_b", "mid", "end_a")),
        "e": (Image.Transpose.ROTATE_270, ("end_a", "mid", "end_b")),
        "w": (Image.Transpose.ROTATE_90, ("end_b", "mid", "end_a")),
    }
    for direction, (turn, sources) in mappings.items():
        for name, source in zip(("end_a", "mid", "end_b"), sources):
            im = part(source, turn, direction, name != "mid")
            im.save(OUT / f"stand_{direction}_{name}.png", optimize=True)
    preview()
    print("Wrote nine turned stand parts")


def preview():
    # Show each assembled 220-pixel stand from the final delivered pieces.
    canvas = Image.new("RGB", (1560, 1560), (239, 233, 216))
    d = ImageDraw.Draw(canvas)
    for i, direction in enumerate("nswe"):
        a = Image.open(OUT / f"stand_{direction}_end_a.png").convert("RGBA")
        mid = Image.open(OUT / f"stand_{direction}_mid.png").convert("RGBA")
        b = Image.open(OUT / f"stand_{direction}_end_b.png").convert("RGBA")
        horizontal = direction in "ns"
        im = Image.new("RGBA", (220, 68) if horizontal else (68, 220))
        im.alpha_composite(a)
        for j in range(4):
            pos = (20 + j * 40, 0) if horizontal else (0, 20 + j * 40)
            im.alpha_composite(mid, pos)
        tail = mid.crop((0, 0, 20, 68)) if horizontal else mid.crop((0, 0, 68, 20))
        im.alpha_composite(tail, (180, 0) if horizontal else (0, 180))
        im.alpha_composite(b, (200, 0) if horizontal else (0, 200))
        x, y = (30, 30) if i == 0 else (800, 30) if i == 1 else (30, 800) if i == 2 else (800, 800)
        d.text((x, y - 18), f"stand_{direction}", fill=INK)
        canvas.paste(im.resize((im.width * 3, im.height * 3), Image.Resampling.NEAREST), (x, y))
    canvas.save(DOC / "round11_stands_all_3x.png")


if __name__ == "__main__":
    main()
