"""Polish the 14x14 Lagoon buoy slices on their final pixel grid.

Only writes buoy PNGs into docs/mockups/rcprix_lagoon/round2_paint; the
approved pier assets are deliberately left untouched.
"""
from pathlib import Path
import runpy

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
PAINT = ROOT / "docs/mockups/rcprix_lagoon/round2_paint"
GUIDES = ROOT / "docs/mockups/rcprix_lagoon/round2_buoy_guides"
read_png = runpy.run_path(str(ROOT / "tools/art/lagoon_round2_export.py"))["read_png"]

SCALE = 4
SIZE = 14
MARK = (255, 0, 255, 255)

# A symmetric 14 px ball silhouette: rounded shoulders and base, without the
# one-pixel notches produced by enlarging the old 7 px guide.
ROW_WIDTHS = (6, 10, 12, 14, 14, 14, 14, 14, 14, 14, 14, 12, 10, 6)

PALETTES = {
    "red": {
        "outline": (133, 43, 42),
        "shadow": (182, 48, 47),
        "base": (231, 63, 57),
        "light": (250, 111, 88),
        "shine": (255, 190, 143),
    },
    "yellow": {
        "outline": (141, 91, 22),
        "shadow": (191, 127, 27),
        "base": (249, 190, 48),
        "light": (255, 218, 99),
        "shine": (255, 241, 169),
    },
}


def disk_mask(radius=SIZE):
    mask = [[False] * SIZE for _ in range(SIZE)]
    if radius == SIZE:
        for y, width in enumerate(ROW_WIDTHS):
            x0 = (SIZE - width) // 2
            for x in range(x0, x0 + width):
                mask[y][x] = True
    else:
        # The small cap uses the same rounded pixel language, at 6x6 px.
        widths = (2, 4, 6, 6, 4, 2)
        for y, width in enumerate(widths):
            x0 = (SIZE - width) // 2
            for x in range(x0, x0 + width):
                mask[y + 2][x] = True
    return mask


def edge_of(mask, x, y):
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dx == dy == 0:
                continue
            xx, yy = x + dx, y + dy
            if not (0 <= xx < SIZE and 0 <= yy < SIZE and mask[yy][xx]):
                return True
    return False


def sphere_pixel(x, y, palette, lift=0):
    """Discrete curved shading with a broad upper-left plastic highlight."""
    p = PALETTES[palette]
    # Rounded light patch, broad enough to read at actual size; the pale center
    # fades through one light tone rather than forming a star or cross.
    dx, dy = x - 4.1, y - 4.1
    d2 = (dx * dx) / 6.5 + (dy * dy) / 8.0
    direction = (6.5 - x) + (6.5 - y)
    if d2 <= 0.80 and direction >= 3.0:
        shade = "shine"
    elif d2 <= 2.45 and direction >= 1.3:
        shade = "light"
    elif x + y >= 16 - lift:
        shade = "shadow"
    elif direction >= 4.2:
        shade = "light"
    else:
        shade = "base"
    return p[shade]


def paint_slice(colour, kind):
    p = PALETTES[colour]
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = im.load()

    if kind == 4:
        # A small rounded cap, colored like the buoy itself; no star-shaped
        # glint. A compact two-step highlight keeps the cap attached visually.
        mask = disk_mask(radius=6)
        for y in range(SIZE):
            for x in range(SIZE):
                if not mask[y][x]:
                    continue
                if edge_of(mask, x, y):
                    color = p["outline"]
                elif (x, y) in ((5, 4), (6, 4)):
                    color = p["shine"]
                elif x + y < 12:
                    color = p["light"]
                else:
                    color = p["base"]
                px[x, y] = (*color, 255)
        return im

    mask = disk_mask()
    for y in range(SIZE):
        for x in range(SIZE):
            if not mask[y][x]:
                continue
            if kind == 0:
                # Opaque warm charcoal float base. The lower inner arc is the
                # thin waterline ring; no slate-blue tint or translucent fill.
                if edge_of(mask, x, y):
                    color = (47, 37, 40)
                elif y >= 10:
                    color = (63, 47, 47)
                elif x + y < 9:
                    color = (103, 76, 68)
                else:
                    color = (78, 56, 55)
            else:
                if edge_of(mask, x, y):
                    color = p["outline"]
                else:
                    # The former grey-white band is intentionally omitted;
                    # these middle slices continue the same glossy sphere.
                    color = sphere_pixel(x, y, colour, lift=(kind - 2) * 2)
            px[x, y] = (*color, 255)
    return im


def save_4x(image, colour, kind):
    guide = GUIDES / f"buoy_{colour}_{kind}_guide_4x.png"
    gw, gh, _ = read_png(guide)
    if (gw, gh) != (56, 56):
        raise ValueError(f"unexpected guide size: {guide.name} is {gw}x{gh}")
    out = image.resize((56, 56), Image.Resampling.NEAREST)
    # Keep the four single-pixel alignment marks exactly where the guide has
    # them; the converter drops these isolated marks at game resolution.
    draw = ImageDraw.Draw(out)
    for xy in ((0, 0), (55, 0), (0, 55), (55, 55)):
        draw.point(xy, fill=MARK)
    out.save(PAINT / f"buoy_{colour}_{kind}_4x.png")


def make_stack(colour):
    # Same slice spacing and layout as the guide preview and in-game stack.
    stack = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    for kind in range(5):
        s = paint_slice(colour, kind)
        stack.alpha_composite(s, (5, round(8 - kind * 1.5)))
    return stack.resize((192, 192), Image.Resampling.NEAREST)


def main():
    PAINT.mkdir(parents=True, exist_ok=True)
    for colour in ("red", "yellow"):
        for kind in range(5):
            image = paint_slice(colour, kind)
            save_4x(image, colour, kind)

    # Proof image uses the exact final pixel-grid sprites, enlarged only with
    # nearest-neighbour scaling, beside the original guide stack for comparison.
    preview = Image.new("RGBA", (500, 236), (222, 148, 127, 255))
    preview.alpha_composite(make_stack("red"), (18, 12))
    preview.alpha_composite(make_stack("yellow"), (270, 12))
    preview.save(PAINT / "buoy_polish_preview.png")
    print("painted buoy_red_0..4 and buoy_yellow_0..4 at 14x14; saved 4x exports and preview")


if __name__ == "__main__":
    main()
