"""Round 2 Lagoon: crab animation frames and replacement beach decor.

Sprites are authored on their final game-pixel grid, then expanded with nearest
neighbour into 4x paintings in docs/mockups/rcprix_lagoon/round2_paint/.
Approved coconuts and islands are not touched.
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
PAINT = ROOT / "docs/mockups/rcprix_lagoon/round2_paint"
CONVERTED = ROOT / "docs/mockups/rcprix_lagoon/round2_converted"
SCALE = 4


def make(size):
    return Image.new("RGBA", size, (0, 0, 0, 0))


def col(rgb):
    return (*rgb, 255)


def px(im, x, y, rgb):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), col(rgb))


def line(d, points, rgb, width=1):
    d.line(points, fill=col(rgb), width=width)


def polygon(d, points, fill, outline=None):
    d.polygon(points, fill=col(fill))
    if outline:
        d.line(points + [points[0]], fill=col(outline), width=1, joint="curve")


def ellipse(d, box, fill, outline):
    d.ellipse(box, fill=col(fill), outline=col(outline), width=1)


CRAB = {
    "ink": (151, 63, 62),       # shaded coral outline, not black
    "deep": (177, 70, 67),
    "red": (200, 90, 85),       # #c85a55
    "coral": (224, 148, 127),   # #e0947f
    "light": (244, 181, 158),
    "cream": (255, 226, 201),
}


def crab(frame, walking=False):
    im = make((12, 9)); d = ImageDraw.Draw(im)
    ink, deep, red, coral, light, cream = (CRAB[k] for k in ("ink", "deep", "red", "coral", "light", "cream"))
    phase = frame if walking else 0

    # Raised claws and the short arms connecting them to the carapace.
    down = (not walking and frame == 1)
    claw_tip_y = 1 if not down else 2
    for side in (-1, 1):
        if side < 0:
            claw = [(1, claw_tip_y), (2, claw_tip_y-1), (3, claw_tip_y-1), (4, 2), (3, 3), (2, 2), (1, 3), (0, 2)]
            arm = [(3, 3), (4, 4)]
            shine = [(1, claw_tip_y), (2, claw_tip_y)]
        else:
            claw = [(11, claw_tip_y), (10, claw_tip_y-1), (9, claw_tip_y-1), (8, 2), (9, 3), (10, 2), (11, 3), (11, 2)]
            arm = [(8, 3), (7, 4)]
            shine = [(9, claw_tip_y), (10, claw_tip_y)]
        polygon(d, claw, red, ink)
        line(d, arm, ink, 2)
        line(d, shine, light, 1)
        px(im, shine[0][0], shine[0][1], cream)

    # Round, slightly flattened shell; the highlights stay in broad clusters.
    shell = [(3, 3), (4, 2), (7, 2), (8, 3), (9, 4), (9, 5),
             (8, 7), (7, 8), (4, 8), (3, 7), (2, 5), (2, 4)]
    polygon(d, shell, coral, ink)
    polygon(d, [(4, 3), (5, 3), (5, 4), (4, 4)], light)
    px(im, 4, 3, cream)
    line(d, [(4, 6), (6, 7), (8, 6)], red)
    # Three visible little legs on each side. Walk frames alternate the reach
    # so the motion remains legible at the actual 12x9 sprite size.
    step = (-1, 0, 1, 0)[phase % 4] if walking else 0
    left_ends = [(1 + step, 4), (1 + step, 6), (2 + step, 7)]
    right_ends = [(10 - step, 4), (10 - step, 6), (9 - step, 7)]
    left_roots = [(3, 4), (3, 5), (4, 6)]
    right_roots = [(8, 4), (8, 5), (7, 6)]
    for side, roots, ends in ((-1, left_roots, left_ends), (1, right_roots, right_ends)):
        for i, (root, end) in enumerate(zip(roots, ends)):
            # The front pair steps a pixel forward on alternating frames.
            ex, ey = end
            if walking and i == 0:
                ey += step if side < 0 else -step
            line(d, [root, (ex, ey)], ink)
            px(im, ex, ey, red if i == 1 else deep)
            if i == 1:
                px(im, ex, ey-1, light)
    # Tiny warm eyes under the brow line help the overhead face read clearly.
    px(im, 5, 5, ink); px(im, 7, 5, ink)
    px(im, 5, 4, cream)
    return im


def seaweed(big=True):
    w, h = (11, 10) if big else (8, 8)
    im = make((w, h)); d = ImageDraw.Draw(im)
    ink, green, light = (91, 95, 57), (128, 132, 73), (170, 157, 91)
    coral, coral_light = (169, 91, 79), (224, 148, 127)
    # Low tangled fronds; broad curves curl back toward the damp sand.
    if big:
        line(d, [(5, 8), (4, 6), (2, 5), (1, 3)], ink, 2)
        line(d, [(5, 8), (5, 5), (7, 4), (8, 2)], ink, 2)
        line(d, [(5, 8), (6, 6), (9, 6), (10, 4)], ink, 2)
        line(d, [(4, 7), (3, 5), (2, 4)], green)
        line(d, [(5, 6), (7, 5), (8, 3)], light)
        line(d, [(6, 7), (8, 6), (9, 5)], green)
        line(d, [(3, 7), (2, 6)], coral, 2)
        line(d, [(7, 8), (8, 8)], coral_light, 2)
    else:
        line(d, [(4, 6), (2, 4), (1, 2)], ink, 2)
        line(d, [(4, 6), (4, 3), (6, 1)], ink, 2)
        line(d, [(4, 6), (6, 5), (7, 3)], ink, 2)
        line(d, [(3, 5), (2, 3)], light)
        line(d, [(5, 5), (6, 4)], green)
        put = [(3, 6), (4, 6)]
        for x, y in put: px(im, x, y, coral)
    return im


def urchin(big=True):
    size = (11, 10) if big else (8, 8)
    im = make(size); d = ImageDraw.Draw(im)
    ink, shade, base, light, cream = (166, 81, 77), (204, 103, 94), (224, 148, 127), (244, 185, 164), (255, 235, 207)
    if big:
        # Short rounded lobes, with a full warm outline around the silhouette.
        for box in ((4,0,6,3),(7,1,9,4),(8,4,10,6),(6,7,8,9),(2,7,4,9),(0,4,2,6),(1,1,3,4)):
            ellipse(d, box, shade, ink)
        ellipse(d, (2, 2, 8, 8), base, ink)
        ellipse(d, (3, 3, 5, 4), light, ink)
        line(d, [(3,3),(4,3)], cream, 1)
        line(d, [(5,7),(7,7)], shade)
    else:
        for box in ((3,0,5,2),(5,2,7,4),(4,5,6,7),(1,4,3,6),(0,2,2,4)):
            ellipse(d, box, shade, ink)
        ellipse(d, (1, 1, 6, 6), base, ink)
        px(im, 2, 2, cream); px(im, 3, 2, light)
    return im


def pebbles(big=True):
    w, h = (13, 8) if big else (9, 6)
    im = make((w, h)); d = ImageDraw.Draw(im)
    # Three touching but individually outlined stones. Each stone has a
    # compact top-left shine and a darker outline in its own warm hue.
    sand_edge, sand, sand_light = (185, 133, 78), (237, 216, 144), (255, 240, 198)
    coral_edge, coral, coral_light = (175, 91, 77), (224, 148, 127), (246, 190, 167)
    if big:
        ellipse(d, (0, 3, 4, 7), sand, sand_edge)
        ellipse(d, (4, 1, 8, 5), coral, coral_edge)
        ellipse(d, (8, 3, 12, 7), sand, sand_edge)
        line(d, [(1,4),(2,4)], sand_light, 2)
        line(d, [(5,2),(6,2)], coral_light, 2)
        line(d, [(9,4),(10,4)], sand_light, 2)
    else:
        ellipse(d, (0, 2, 4, 5), sand, sand_edge)
        ellipse(d, (4, 0, 8, 3), coral, coral_edge)
        line(d, [(1,3),(2,3)], sand_light)
        px(im, 5, 1, coral_light)
    return im


def bird_tracks(big=True):
    # A quiet diagonal trail of three three-toed impressions; no dark outline.
    w, h = (12, 8) if big else (8, 6)
    im = make((w, h))
    deep, soft = (220, 169, 107), (235, 192, 137)
    steps = [(0, 4), (4, 2), (8, 0)] if big else [(0, 3), (4, 0)]
    for i, (x, y) in enumerate(steps):
        c = soft if i % 2 == 0 else deep
        # Three forward toes and a short heel make a recognizable Y-shaped
        # bird mark. Kept low contrast so it sits quietly in the sand.
        for dx, dy in ((1, 0), (0, 1), (2, 1), (1, 2)):
            px(im, x+dx, y+dy, c)
    return im


def export(name, im):
    im.resize((im.width*SCALE, im.height*SCALE), Image.Resampling.NEAREST).save(PAINT / f"{name}_4x.png")


def create_preview(items):
    cell_w, cell_h, cols = 112, 90, 6
    rows = (len(items)+cols-1)//cols
    board = Image.new("RGBA", (cols*cell_w, rows*cell_h), (55, 48, 47, 255))
    d = ImageDraw.Draw(board)
    for i, (name, im) in enumerate(items.items()):
        scale = min(6, (cell_w-12)//im.width, (cell_h-28)//im.height)
        show = im.resize((im.width*scale, im.height*scale), Image.Resampling.NEAREST)
        x, y = (i%cols)*cell_w, (i//cols)*cell_h
        board.alpha_composite(show, (x+(cell_w-show.width)//2, y+24))
        d.text((x+4, y+5), name, fill=(255,246,234,255))
    board.save(PAINT / "round2_crabs_replacements_preview.png")


def main():
    PAINT.mkdir(parents=True, exist_ok=True)
    sprites = {}
    for i in range(2):
        sprites[f"crab_idle_{i}"] = crab(i, walking=False)
    for i in range(4):
        sprites[f"crab_walk_{i}"] = crab(i, walking=True)
    sprites.update({
        "seaweed": seaweed(True), "seaweed_b": seaweed(False),
        "urchin": urchin(True), "urchin_b": urchin(False),
        "pebbles": pebbles(True), "pebbles_b": pebbles(False),
        "tracks": bird_tracks(True), "tracks_b": bird_tracks(False),
    })
    for name, im in sprites.items():
        export(name, im)
        print(f"{name}: {im.width}x{im.height} -> {im.width*SCALE}x{im.height*SCALE}")

    # Remove the superseded, explicitly rejected decor and previous crab study.
    for stem in ("crab_0", "crab_1", "driftwood", "driftwood_b", "grass_tuft", "grass_tuft_b",
                 "sandcastle", "sandcastle_b", "bucket", "bucket_b"):
        (PAINT / f"{stem}_4x.png").unlink(missing_ok=True)
        (CONVERTED / f"{stem}.png").unlink(missing_ok=True)
    (PAINT / "round2_decor_islands_preview.png").unlink(missing_ok=True)

    preview_items = dict(sprites)
    for name in ("coconut", "coconut_b"):
        p = CONVERTED / f"{name}.png"
        if p.exists():
            preview_items[name + " (kept)"] = Image.open(p).convert("RGBA")
    create_preview(preview_items)


if __name__ == "__main__":
    main()
