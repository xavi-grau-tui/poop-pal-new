"""Round 2 Lagoon: small beach decor and island beach palette touch-up.

Draws small sprites directly on their final pixel grid and exports hard-edged
4x paintings. Island silhouettes, grass, outlines and side faces are retained;
only the three original sand colours are remapped to the approved warm palette.
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
PAINT = ROOT / "docs/mockups/rcprix_lagoon/round2_paint"
CONVERTED = ROOT / "docs/mockups/rcprix_lagoon/round2_converted"
GARDEN = ROOT / "textures/minigames/rcprix/garden"
SCALE = 4


def rgba(color):
    return (*color, 255)


def canvas(size):
    return Image.new("RGBA", size, (0, 0, 0, 0))


def put(im, xy, color):
    im.putpixel(xy, rgba(color))


def line(draw, pts, color, width=1):
    draw.line(pts, fill=rgba(color), width=width, joint="curve")


def ellipse(draw, box, color, outline=None):
    draw.ellipse(box, fill=rgba(color), outline=rgba(outline) if outline else None)


def polygon(draw, pts, color, outline=None):
    draw.polygon(pts, fill=rgba(color))
    if outline:
        draw.line(pts + [pts[0]], fill=rgba(outline), width=1, joint="curve")


def crab(frame=0):
    # Front-facing tiny shore crab, two claw positions for a simple idle motion.
    im = canvas((13, 10)); d = ImageDraw.Draw(im)
    ink, deep, coral, mid, light, cream = (
        (146, 75, 66), (195, 91, 76), (224, 119, 96),
        (239, 151, 122), (250, 190, 154), (255, 229, 190))
    shift = frame
    # legs sit behind the shell
    for x in (2, 4, 8, 10):
        side = -1 if x < 6 else 1
        line(d, [(x, 6), (x + side, 7), (x + side * (1 + (x % 2)), 8)], deep)
        put(im, (x + side * (1 + (x % 2)), 8), ink)
    # claws, slightly raised/lowered between frames
    claw_y = 1 + shift
    for side in (-1, 1):
        x = 6 + side * 4
        line(d, [(6 + side * 3, 4), (x, 3), (x + side, claw_y + 1)], ink, 2)
        put(im, (x + side, claw_y), light)
        put(im, (x + side, claw_y + 1), coral)
        put(im, (x, 2 + shift), mid)
    # rounded shell, with a coral shaded lower rim and one broad light patch
    ellipse(d, (2, 2, 10, 8), coral, ink)
    ellipse(d, (3, 3, 9, 7), mid)
    line(d, [(4, 6), (6, 7), (8, 6)], deep)
    line(d, [(4, 4), (5, 3), (6, 3)], light, 2)
    put(im, (5, 4), cream)
    # eyes are warm dark points, not black specks
    put(im, (5, 5), ink); put(im, (8, 5), ink)
    return im


def driftwood(long=True):
    w, h = (14, 7) if long else (10, 6)
    im = canvas((w, h)); d = ImageDraw.Draw(im)
    ink, shade, wood, light, glint = (119, 78, 57), (162, 111, 70), (193, 145, 91), (222, 181, 119), (241, 211, 157)
    if long:
        polygon(d, [(1, 4), (3, 2), (7, 3), (10, 1), (12, 2), (13, 4), (11, 6), (4, 6)], wood, ink)
        polygon(d, [(3, 3), (7, 4), (11, 2), (12, 3), (10, 4), (5, 5)], shade)
        line(d, [(4, 3), (7, 4), (10, 2)], light)
        line(d, [(2, 4), (4, 5)], glint)
        line(d, [(7, 3), (6, 1), (7, 0)], ink)
        put(im, (7, 1), light)
        put(im, (11, 5), ink)
    else:
        polygon(d, [(1, 4), (2, 2), (4, 3), (7, 1), (9, 3), (8, 5), (4, 5)], wood, ink)
        line(d, [(2, 3), (4, 4), (7, 2)], light)
        line(d, [(5, 3), (5, 1)], ink)
        put(im, (4, 1), shade); put(im, (8, 4), ink)
    return im


def grass_tuft(tall=False):
    w, h = (10, 14) if tall else (8, 11)
    im = canvas((w, h)); d = ImageDraw.Draw(im)
    ink, shade, green, light = (88, 91, 55), (123, 124, 66), (157, 151, 82), (195, 177, 105)
    cx = w // 2
    # Several broad blades, each outlined in its own shaded olive tone.
    paths = [
        ([(cx, h-2), (1, h-5), (1, h-8), (3, h-6), (cx, h-2)], shade, green),
        ([(cx, h-2), (cx-1, 2), (cx+1, 0), (cx+2, 2), (cx+1, h-2)], green, light),
        ([(cx+1, h-2), (w-2, h-7), (w-1, h-10), (w-1, h-6), (cx+1, h-2)], shade, green),
    ]
    if tall:
        paths.append(([(cx, h-2), (2, 4), (3, 2), (4, 5), (cx, h-2)], green, light))
    for pts, fill, edge in paths:
        polygon(d, pts, fill, ink)
        # Short top-left light strokes make 2 px+ clusters rather than specks.
        if len(pts) >= 4:
            line(d, [pts[1], pts[2]], edge)
    polygon(d, [(2, h-3), (cx, h-3), (w-2, h-3), (cx+1, h-1), (3, h-1)], shade, ink)
    line(d, [(3, h-2), (cx, h-2)], light)
    return im


def coconut(half=False):
    size = (10, 8) if half else (10, 10)
    im = canvas(size); d = ImageDraw.Draw(im)
    ink, dark, husk, mid, light, flesh = (
        (112, 69, 48), (139, 81, 49), (171, 105, 58),
        (202, 139, 78), (229, 178, 113), (255, 235, 193))
    if half:
        ellipse(d, (0, 2, 9, 7), ink)
        ellipse(d, (1, 2, 8, 6), husk)
        ellipse(d, (2, 2, 7, 5), flesh)
        line(d, [(2, 3), (4, 2), (6, 3)], light, 2)
        line(d, [(1, 6), (4, 7), (8, 6)], dark)
    else:
        ellipse(d, (1, 1, 8, 8), ink)
        ellipse(d, (2, 1, 8, 7), husk)
        # husk fibers are broad, calm blocks in a few warm tones
        line(d, [(3, 2), (3, 5), (5, 7)], light, 2)
        line(d, [(6, 2), (5, 4), (7, 6)], mid, 2)
        line(d, [(2, 4), (4, 6)], dark)
        put(im, (3, 2), flesh)
        put(im, (7, 3), dark)
    return im


def sandcastle(small=False):
    size = (11, 10) if small else (13, 12)
    im = canvas(size); d = ImageDraw.Draw(im)
    ink, shade, sand, light, cream = (161, 99, 56), (207, 142, 71), (238, 187, 100), (253, 216, 123), (255, 239, 180)
    # broad base with two crenellated towers and a small central gate
    if small:
        polygon(d, [(1,8),(2,5),(4,5),(4,3),(6,3),(6,5),(8,5),(9,8),(9,9),(1,9)], sand, ink)
        line(d, [(2,6),(4,6),(5,4),(6,4),(7,6),(8,6)], light)
        polygon(d, [(4,9),(4,7),(5,6),(6,7),(6,9)], shade)
        put(im,(3,7),cream)
    else:
        polygon(d, [(1,9),(2,6),(3,6),(3,4),(5,4),(5,6),(7,6),(7,3),(9,3),(9,6),(11,6),(12,9),(12,10),(1,10)], sand, ink)
        line(d, [(2,7),(4,7),(4,5),(5,5),(6,7),(8,7),(8,4),(9,4),(10,7),(11,7)], light)
        polygon(d, [(5,10),(5,8),(6,7),(7,8),(7,10)], shade)
        line(d, [(2,9),(4,9)], cream, 2)
        put(im,(10,8),shade)
    return im


def bucket(small=False):
    size = (9, 10) if small else (12, 12)
    im = canvas(size); d = ImageDraw.Draw(im)
    ink, shade, coral, mid, light, sand = (
        (151, 73, 65), (190, 82, 68), (222, 111, 89),
        (241, 151, 120), (255, 197, 155), (253, 216, 123))
    if small:
        line(d, [(2,5),(2,3),(3,2),(6,2),(7,3),(7,5)], shade)
        polygon(d, [(1,4),(7,4),(6,9),(2,9)], coral, ink)
        line(d, [(2,4),(6,4)], sand, 2)
        line(d, [(2,6),(3,8)], light)
        line(d, [(3,9),(6,9)], ink)
    else:
        line(d, [(2,5),(2,2),(3,1),(8,1),(9,2),(9,5)], shade)
        polygon(d, [(1,4),(10,4),(8,10),(3,10)], coral, ink)
        line(d, [(2,4),(9,4)], sand, 2)
        line(d, [(3,6),(4,9)], light, 2)
        line(d, [(4,10),(8,10)], ink)
        put(im,(7,7),mid)
    return im


def export_sprite(name, im):
    out = im.resize((im.width * SCALE, im.height * SCALE), Image.Resampling.NEAREST)
    out.save(PAINT / f"{name}_4x.png")


def recolor_islands():
    # Existing 4x paintings are exact 4x expansions of the final game grid.
    # Replace only the three sand tones; leave grass, side face and outlines.
    palette = {
        (247, 221, 160): (253, 216, 123),  # sunlit sand #fdd87b
        (238, 208, 138): (237, 216, 144),  # base sand #edd890
        (221, 183, 111): (252, 201, 110),  # warm shaded sand #fcc96e
    }
    for key in "abcd":
        path = PAINT / f"island_{key}_4x.png"
        im = Image.open(path).convert("RGBA")
        px = im.load()
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, a = px[x, y]
                if a == 255 and (r, g, b) in palette:
                    px[x, y] = (*palette[(r, g, b)], 255)
        im.save(path)


def main():
    PAINT.mkdir(parents=True, exist_ok=True)
    sprites = {
        "crab_0": crab(0), "crab_1": crab(1),
        "driftwood": driftwood(True), "driftwood_b": driftwood(False),
        "grass_tuft": grass_tuft(False), "grass_tuft_b": grass_tuft(True),
        "coconut": coconut(False), "coconut_b": coconut(True),
        "sandcastle": sandcastle(False), "sandcastle_b": sandcastle(True),
        "bucket": bucket(False), "bucket_b": bucket(True),
    }
    for name, im in sprites.items():
        export_sprite(name, im)
        print(f"{name}: {im.width}x{im.height} game px -> {im.width*SCALE}x{im.height*SCALE}")
    recolor_islands()
    make_preview(sprites)


def make_preview(sprites):
    # A labeled overview at 4x zoom. Garden flowers are included at their native
    # size for a direct style/density check; islands use the converted files.
    cell_w, cell_h = 145, 112
    names = list(sprites)
    cols = 6
    rows = (len(names) + cols - 1) // cols
    board = Image.new("RGBA", (1400, rows * cell_h + 190), (55, 48, 47, 255))
    d = ImageDraw.Draw(board)
    for i, name in enumerate(names):
        im = sprites[name].resize((sprites[name].width * 6, sprites[name].height * 6), Image.Resampling.NEAREST)
        x, y = (i % cols) * cell_w, (i // cols) * cell_h
        board.alpha_composite(im, (x + (cell_w-im.width)//2, y + 26))
        d.text((x+5, y+6), name, fill=(255, 246, 234, 255))
    y0 = rows * cell_h + 12
    d.text((8, y0), "Island recolours  |  sand fdd87b / fcc96e / edd890", fill=(255,246,234,255))
    for i, name in enumerate(("island_a", "island_b", "island_c", "island_d")):
        p = PAINT / f"{name}_4x.png"
        im = Image.open(p).convert("RGBA").resize((Image.open(p).width//4, Image.open(p).height//4), Image.Resampling.NEAREST)
        im = im.resize((im.width*2, im.height*2), Image.Resampling.NEAREST)
        x = 15 + i * 238
        board.alpha_composite(im, (x, y0+24))
        d.text((x, y0+8), name, fill=(255,246,234,255))
    # Garden's flowers at their actual pixel density as visual references.
    for i, name in enumerate(("flowers_a", "flowers_b")):
        ref = Image.open(GARDEN / f"{name}.png").convert("RGBA")
        ref = ref.resize((ref.width*6, ref.height*6), Image.Resampling.NEAREST)
        x = 1120 + i * 120
        board.alpha_composite(ref, (x, y0+25))
        d.text((x, y0+8), f"Garden {name}", fill=(255,246,234,255))
    board.save(PAINT / "round2_decor_islands_preview.png")


if __name__ == "__main__":
    main()
