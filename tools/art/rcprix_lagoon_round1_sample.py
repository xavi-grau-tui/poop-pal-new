"""Paint the first RC Prix Lagoon art sample directly on the final pixel grid."""
from __future__ import annotations

from pathlib import Path
import random

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ASSET = ROOT / "textures/minigames/rcprix/lagoon"
MOCK = ROOT / "docs/mockups/rcprix_lagoon"
TILE = 190
INK = (40, 30, 40, 255)  # #281E28

PALETTES = {
    "water": {
        "base": (195, 112, 128), "shade": (158, 83, 113), "mid": (208, 125, 132),
        "light": (228, 151, 137), "shine": (245, 187, 145),
    },
    "channel": {
        "base": (139, 80, 111), "shade": (99, 57, 97), "mid": (158, 91, 116),
        "light": (190, 116, 125), "shine": (222, 151, 139),
    },
    "shallows": {
        "base": (218, 145, 135), "shade": (191, 112, 123), "mid": (231, 160, 139),
        "light": (244, 190, 145), "shine": (250, 216, 166),
    },
    "sand": {
        "base": (239, 207, 148), "shade": (195, 145, 102), "mid": (231, 190, 126),
        "light": (248, 224, 170), "shine": (255, 239, 194),
    },
}


def polygon_periodic(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], fill, outline=None) -> None:
    for ox in (0, -TILE, TILE):
        for oy in (0, -TILE, TILE):
            shifted = [(x + ox + TILE, y + oy + TILE) for x, y in points]
            draw.polygon(shifted, fill=fill, outline=outline)


def rect_periodic(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill) -> None:
    x0, y0, x1, y1 = box
    for ox in (0, -TILE, TILE):
        for oy in (0, -TILE, TILE):
            draw.rectangle((x0 + ox + TILE, y0 + oy + TILE, x1 + ox + TILE, y1 + oy + TILE), fill=fill)


def get_torus_canvas(base: tuple[int, int, int, int]) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    im = Image.new("RGBA", (TILE * 3, TILE * 3), base)
    return im, ImageDraw.Draw(im)


def wave_shape(x: int, y: int, w: int, lean: int, main, glint, shadow) -> list[tuple[int, int]]:
    # Low, stepped crests with a broad body and a short top-left shine.
    pts = [(x, y + 3), (x + 3, y + 3), (x + 3 + lean, y + 1),
           (x + w - 3 + lean, y + 1), (x + w - 3 + lean, y),
           (x + w, y), (x + w, y + 3), (x + w - 4, y + 3),
           (x + w - 4, y + 4), (x + 4, y + 4), (x + 4, y + 5),
           (x, y + 5)]
    return pts


def build_texture(kind: str) -> Image.Image:
    p = PALETTES[kind]
    seed = {"water": 401, "channel": 821, "shallows": 301, "sand": 774}[kind]
    rng = random.Random(seed)
    canvas, d = get_torus_canvas((*p["base"], 255))
    # Low-contrast, flat large patches form a calm substrate. Every shape wraps.
    if kind in ("water", "channel"):
        for _ in range(12 if kind == "water" else 15):
            x, y = rng.randrange(TILE), rng.randrange(TILE)
            w, h = rng.randrange(14, 31), rng.randrange(3, 8)
            points = [(x, y + h // 2), (x + 3, y), (x + w - 5, y),
                      (x + w, y + h // 2), (x + w - 4, y + h),
                      (x + 4, y + h)]
            polygon_periodic(d, points, (*p["mid"], 255))
    elif kind == "shallows":
        for _ in range(22):
            x, y = rng.randrange(TILE), rng.randrange(TILE)
            w, h = rng.randrange(6, 16), rng.randrange(4, 9)
            pts = [(x, y + 2), (x + 3, y), (x + w - 2, y),
                   (x + w, y + 3), (x + w - 3, y + h), (x + 2, y + h - 1)]
            polygon_periodic(d, pts, (*rng.choice((p["mid"], p["light"])), 255))
    else:
        for _ in range(20):
            x, y = rng.randrange(TILE), rng.randrange(TILE)
            w, h = rng.randrange(7, 18), rng.randrange(4, 10)
            pts = [(x, y + 2), (x + 3, y), (x + w - 3, y),
                   (x + w, y + 3), (x + w - 2, y + h), (x + 2, y + h - 1)]
            polygon_periodic(d, pts, (*rng.choice((p["mid"], p["light"])), 255))

    # Shared edge texture for all A/B/C variants of a material. Crests and grain
    # wrap across all four sides, so repeats continue instead of forming a seam.
    if kind in ("water", "channel"):
        for _ in range(18 if kind == "water" else 20):
            x, y = rng.randrange(TILE), rng.randrange(TILE)
            w = rng.randrange(8, 19)
            lean = rng.choice((-2, -1, 0, 1, 2))
            crest = wave_shape(x, y, w, lean, p["light"], p["shine"], p["shade"])
            polygon_periodic(d, [(a, b + 2) for a, b in crest], (*p["shade"], 255))
            polygon_periodic(d, crest, (*p["light"], 255))
            # Keep highlights as solid 2×2 or wider clusters.
            rect_periodic(d, (x + 4, y, x + min(w - 3, 8), y + 1), (*p["shine"], 255))
    elif kind == "shallows":
        for _ in range(17):
            x, y = rng.randrange(TILE), rng.randrange(TILE)
            w, h = rng.randrange(3, 8), rng.randrange(2, 5)
            rect_periodic(d, (x, y, x + w, y + h), (*rng.choice((p["shine"], p["light"])), 255))
    else:
        # Fine sand grains are small clusters rather than scattered single dots.
        for _ in range(74):
            x, y = rng.randrange(TILE), rng.randrange(TILE)
            w, h = rng.choice((2, 2, 3, 4)), rng.choice((2, 2, 3))
            rect_periodic(d, (x, y, x + w - 1, y + h - 1), (*rng.choice((p["shade"], p["shine"])), 255))

    # Remove the torus padding and retain a deterministic 3 px ring that future
    # variants can share exactly without changing this sample's pixel language.
    im = canvas.crop((TILE, TILE, TILE * 2, TILE * 2))
    ring, rd = get_torus_canvas((*p["base"], 255))
    r = random.Random(seed + 1000)
    if kind in ("water", "channel"):
        for _ in range(12):
            x, y = r.randrange(TILE), r.randrange(TILE)
            w = r.randrange(8, 15)
            pts = [(x, y + 3), (x + 3, y + 1), (x + w - 3, y + 1),
                   (x + w, y + 3), (x + w - 2, y + 4), (x + 2, y + 4)]
            polygon_periodic(rd, pts, (*p["mid"], 255))
    elif kind == "sand":
        for _ in range(22):
            x, y = r.randrange(TILE), r.randrange(TILE)
            rect_periodic(rd, (x, y, x + 2, y + 1), (*p["mid"], 255))
    else:
        for _ in range(11):
            x, y = r.randrange(TILE), r.randrange(TILE)
            rect_periodic(rd, (x, y, x + 2, y + 1), (*p["mid"], 255))
    edge = ring.crop((TILE, TILE, TILE * 2, TILE * 2))
    src, dst = im.load(), edge.load()
    for y in range(TILE):
        for x in range(TILE):
            if x < 3 or y < 3 or x >= TILE - 3 or y >= TILE - 3:
                src[x, y] = dst[x, y]

    # No alpha in the four full-square materials.
    return im.convert("RGB")


def draw_decor() -> dict[str, Image.Image]:
    sprites: dict[str, Image.Image] = {}
    # Starfish: chunky, five-lobed coral form with a few large lit clusters.
    im = Image.new("RGBA", (16, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    shape = [(7, 0), (9, 0), (10, 4), (14, 3), (16, 5), (13, 7),
             (15, 11), (13, 13), (9, 10), (7, 14), (5, 14), (5, 10),
             (1, 12), (0, 10), (3, 7), (0, 5), (1, 3), (6, 5)]
    d.polygon(shape, fill=(213, 91, 72, 255), outline=INK)
    d.line([(6, 3), (7, 2), (8, 5), (11, 5)], fill=(247, 160, 111, 255), width=2)
    d.rectangle((5, 7, 6, 8), fill=(246, 164, 111, 255))
    d.rectangle((9, 8, 10, 9), fill=(167, 66, 74, 255))
    sprites["starfish"] = im

    # A ridged scallop shell, deliberately broader than the old 6×6 stand-in.
    im = Image.new("RGBA", (16, 13), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    shell = [(1, 7), (2, 4), (5, 2), (8, 1), (11, 2), (14, 5), (15, 8),
             (13, 11), (10, 12), (6, 12), (3, 10)]
    d.polygon(shell, fill=(241, 192, 148, 255), outline=INK)
    d.polygon([(3, 7), (5, 4), (8, 3), (11, 4), (13, 7), (12, 10), (6, 10)], fill=(255, 222, 177, 255))
    for x in (4, 7, 10, 12):
        d.line([(x, 4), (x, 7), (x + (1 if x < 9 else -1), 10)], fill=(183, 112, 110, 255), width=2)
    d.line([(4, 4), (7, 2), (9, 2)], fill=(255, 240, 200, 255), width=2)
    sprites["shell"] = im

    # Smooth rounded shore pebble with a flat shadow side.
    im = Image.new("RGBA", (12, 9), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(2, 3), (4, 1), (8, 1), (11, 4), (10, 7), (7, 8), (2, 7), (0, 5)],
              fill=(126, 94, 101, 255), outline=INK)
    d.polygon([(3, 3), (5, 2), (8, 2), (9, 4), (6, 5), (2, 5)], fill=(184, 132, 126, 255))
    d.rectangle((4, 2, 6, 2), fill=(220, 169, 145, 255))
    sprites["pebble"] = im

    # Three broad fronds, each made of 2–3 px leaf clusters.
    im = Image.new("RGBA", (8, 10), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.line([(4, 9), (4, 5), (2, 2)], fill=INK, width=3)
    d.line([(4, 9), (4, 5), (6, 1)], fill=INK, width=3)
    d.line([(4, 9), (4, 4), (4, 0)], fill=INK, width=3)
    d.line([(4, 8), (4, 5), (2, 2)], fill=(71, 111, 61, 255), width=2)
    d.line([(4, 8), (4, 5), (6, 1)], fill=(86, 139, 67, 255), width=2)
    d.line([(4, 8), (4, 4), (4, 0)], fill=(111, 160, 76, 255), width=2)
    d.rectangle((3, 7, 5, 9), fill=(112, 77, 57, 255), outline=INK)
    sprites["seagrass"] = im
    return sprites


def draw_palm() -> Image.Image:
    im = Image.new("RGBA", (30, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    center = (15, 20)
    fronds = [
        ([(15, 19), (13, 12), (8, 8), (5, 3), (9, 4), (13, 7), (16, 13)], (75, 131, 65, 255)),
        ([(15, 19), (18, 12), (23, 8), (27, 3), (23, 4), (19, 7), (14, 13)], (69, 119, 60, 255)),
        ([(15, 19), (10, 16), (5, 15), (1, 12), (6, 12), (11, 13), (16, 16)], (90, 145, 68, 255)),
        ([(15, 19), (20, 16), (25, 15), (29, 12), (24, 12), (19, 13), (14, 16)], (76, 131, 62, 255)),
        ([(15, 19), (12, 24), (8, 28), (5, 35), (10, 33), (14, 28), (17, 22)], (64, 112, 58, 255)),
        ([(15, 19), (18, 24), (22, 28), (26, 35), (21, 33), (17, 28), (13, 22)], (78, 133, 62, 255)),
        ([(15, 19), (14, 12), (14, 6), (15, 1), (17, 6), (17, 12), (16, 19)], (101, 151, 70, 255)),
    ]
    # Draw fronds separately to retain the overlap and the top-left light.
    for points, color in fronds:
        d.polygon(points, fill=color, outline=INK)
        # Broad stepped highlight patches, never isolated pixel noise.
        x0, y0 = min(x for x, _ in points), min(y for _, y in points)
        d.rectangle((x0 + 2, y0 + 2, min(x0 + 4, 28), min(y0 + 3, 37)), fill=(134, 173, 79, 255))
    # Small crown and trunk mark make the top-down orientation legible.
    d.polygon([(12, 17), (14, 14), (17, 14), (19, 17), (18, 21), (15, 23), (12, 21)],
              fill=(110, 72, 53, 255), outline=INK)
    d.rectangle((14, 16, 16, 17), fill=(194, 132, 78, 255))
    d.rectangle((14, 19, 16, 20), fill=(82, 53, 48, 255))
    return im


def draw_island_b() -> Image.Image:
    im = Image.new("RGBA", (120, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    outline = [(5, 28), (9, 21), (17, 18), (23, 13), (34, 14), (42, 9),
               (53, 10), (61, 6), (72, 9), (82, 7), (91, 11), (102, 10),
               (111, 16), (116, 23), (112, 29), (118, 36), (112, 43),
               (104, 46), (97, 52), (83, 54), (74, 59), (59, 56), (47, 60),
               (34, 55), (22, 55), (16, 49), (9, 45), (8, 37), (3, 33)]
    d.polygon(outline, fill=(122, 76, 58, 255), outline=INK)
    # The lower, darker lip reads as the island's earthy raised side.
    side = [(8, 39), (19, 45), (34, 47), (48, 51), (61, 48), (76, 52),
            (91, 48), (105, 43), (112, 39), (112, 46), (103, 51), (96, 55),
            (82, 57), (74, 61), (59, 58), (47, 62), (34, 57), (22, 57),
            (16, 51), (10, 47)]
    d.polygon(side, fill=(149, 92, 64, 255), outline=(74, 49, 50, 255))
    # Creamy dry beach over the upper face, with a darker wet-sand lower edge.
    beach = [(9, 29), (14, 22), (22, 20), (28, 16), (39, 17), (48, 13),
             (58, 14), (66, 11), (77, 14), (88, 12), (97, 16), (106, 15),
             (112, 22), (108, 29), (113, 35), (107, 41), (97, 44), (87, 49),
             (74, 51), (61, 53), (49, 54), (37, 51), (25, 51), (18, 46),
             (12, 42), (12, 35)]
    d.polygon(beach, fill=(231, 190, 126, 255), outline=(103, 66, 57, 255))
    dry = [(16, 28), (21, 23), (30, 22), (37, 18), (48, 19), (58, 16),
           (69, 17), (78, 15), (89, 17), (99, 18), (106, 23), (103, 30),
           (108, 35), (101, 39), (94, 42), (82, 45), (70, 46), (58, 48),
           (45, 47), (34, 45), (24, 45), (19, 40), (15, 36)]
    d.polygon(dry, fill=(249, 220, 163, 255))
    # Grass island crown. Its lower contour leaves enough visible beach.
    grass = [(27, 31), (31, 26), (39, 24), (45, 20), (55, 21), (62, 18),
             (73, 20), (80, 18), (89, 22), (96, 24), (100, 29), (97, 34),
             (101, 38), (93, 41), (82, 42), (72, 45), (62, 43), (52, 46),
             (42, 43), (34, 42), (29, 38)]
    d.polygon(grass, fill=(48, 82, 57, 255), outline=INK)
    d.polygon([(34, 31), (39, 27), (47, 26), (52, 23), (61, 24), (68, 21),
               (77, 23), (84, 21), (92, 26), (94, 31), (87, 34), (81, 34),
               (76, 38), (66, 37), (58, 40), (49, 38), (41, 40), (35, 36)],
              fill=(76, 125, 65, 255))
    d.polygon([(40, 30), (45, 27), (52, 27), (56, 25), (61, 27), (58, 30), (50, 31), (44, 33)],
              fill=(125, 163, 78, 255))
    d.polygon([(68, 25), (73, 24), (78, 26), (75, 29), (70, 29)], fill=(105, 149, 73, 255))
    # A couple of beach stones for scale and finish; no contact shadow.
    d.polygon([(23, 35), (26, 33), (29, 34), (29, 37), (25, 38)], fill=(153, 93, 78, 255), outline=INK)
    d.rectangle((25, 34, 26, 34), fill=(210, 146, 115, 255))
    d.polygon([(91, 47), (94, 45), (97, 46), (98, 48), (95, 49)], fill=(141, 89, 73, 255), outline=INK)
    return im


def build_bank_sample(textures: dict[str, Image.Image]) -> Image.Image:
    guide_path = MOCK / "templates/2_bank_guide_4x.png"
    guide = Image.open(guide_path).convert("RGB")
    labels = {
        (212, 142, 143): "water",
        (150, 90, 130): "channel",
        (232, 170, 150): "shallows",
        (244, 220, 166): "sand",
    }
    bank = guide.copy()
    px = bank.load()
    originals = guide.load()
    mats = {k: v.load() for k, v in textures.items()}
    w, h = guide.size
    # Every 4×4 guide block is one final-grid pixel. Preserve the exact region
    # geometry/ink and replace only its flat fill with the real delivered tiles.
    for y in range(h):
        for x in range(w):
            label = labels.get(originals[x, y])
            if label:
                tx, ty = (x // 4) % TILE, (y // 4) % TILE
                px[x, y] = mats[label][tx, ty]

    # Add broken, warm foam and a darker wet-sand glint on the actual shore edge.
    low = Image.new("RGB", (w // 4, h // 4), (0, 0, 0))
    lp = low.load()
    for y in range(low.height):
        for x in range(low.width):
            lp[x, y] = originals[x * 4, y * 4]
    lp = low.load()
    foam = (255, 228, 182)
    wet = (183, 123, 91)
    offshore = (237, 173, 146)
    def nearest_direction(x: int, y: int, target: tuple[int, int, int]):
        for radius in (1, 2, 3):
            for dx, dy in ((-radius, 0), (radius, 0), (0, -radius), (0, radius),
                           (-radius, -radius), (radius, -radius), (-radius, radius), (radius, radius)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < low.width and 0 <= ny < low.height and lp[nx, ny] == target:
                    return dx, dy
        return None
    for y in range(1, low.height - 1):
        for x in range(1, low.width - 1):
            here = lp[x, y]
            if here not in labels:
                continue
            if here == (232, 170, 150) and (direction := nearest_direction(x, y, (244, 220, 166))):
                dx, dy = direction
                tangent = y if dx else x
                if tangent % 17 in (3, 4, 5, 6):
                    for oy in range(4):
                        for ox in range(4):
                            px[x * 4 + ox, y * 4 + oy] = foam
            elif here == (244, 220, 166) and (direction := nearest_direction(x, y, (232, 170, 150))):
                dx, dy = direction
                tangent = y if dx else x
                if tangent % 19 in (8, 9, 10):
                    # Restrict wet tint to the bank's inside edge with a clipped 2×2 game-pixel patch.
                    for oy in range(4):
                        for ox in range(4):
                            if (ox + oy) % 3 != 0:
                                px[x * 4 + ox, y * 4 + oy] = wet
            elif here == (212, 142, 143) and (direction := nearest_direction(x, y, (244, 220, 166))):
                dx, dy = direction
                tangent = y if dx else x
                if tangent % 23 in (4, 5):
                    for oy in range(4):
                        for ox in range(4):
                            px[x * 4 + ox, y * 4 + oy] = offshore
    return bank


def build_preview(textures: dict[str, Image.Image], sprites: dict[str, Image.Image], island: Image.Image, palm: Image.Image, bank: Image.Image) -> Image.Image:
    # A clean review sheet: texture scale 2×, small sprites at 6×, island/palm at 3×.
    w, h = 1420, 1180
    sheet = Image.new("RGB", (w, h), (46, 36, 48))
    d = ImageDraw.Draw(sheet)
    labels = ["WATER", "CHANNEL", "SHALLOWS", "SAND"]
    for i, name in enumerate(("water", "channel", "shallows", "sand")):
        x, y = 26 + (i % 2) * 405, 36 + (i // 2) * 405
        d.text((x, y - 22), f"{labels[i]} A - 190x190", fill=(250, 224, 178))
        tile = textures[name].resize((380, 380), Image.Resampling.NEAREST)
        sheet.paste(tile, (x, y))
        # Show one repeat in each direction to reveal seams at a glance.
        d.rectangle((x - 2, y - 2, x + 381, y + 381), outline=(247, 224, 194), width=2)

    # Island + separate palm shown composited at 3×, matching the actual files.
    ix, iy = 860, 58
    d.text((ix, iy - 22), "ISLAND B + PALM A - 3x", fill=(250, 224, 178))
    comp = Image.new("RGBA", (360, 192), (0, 0, 0, 0))
    island3 = island.resize((360, 192), Image.Resampling.NEAREST)
    palm3 = palm.resize((90, 120), Image.Resampling.NEAREST)
    comp.alpha_composite(island3, (0, 0))
    comp.alpha_composite(palm3, (135, 20))
    comp = comp.resize((450, 270), Image.Resampling.NEAREST)
    # Dark neutral inset makes transparency visible around the island.
    d.rounded_rectangle((ix - 10, iy - 8, ix + 462, iy + 282), radius=12, fill=(32, 31, 37))
    sheet.paste(comp, (ix, iy), comp)

    dx, dy = 880, 390
    d.text((dx, dy - 22), "SAND DECOR • 6×", fill=(250, 224, 178))
    x = dx
    for name in ("starfish", "shell", "pebble", "seagrass"):
        icon = sprites[name]
        size = (icon.width * 6, icon.height * 6)
        scaled = icon.resize(size, Image.Resampling.NEAREST)
        sheet.paste(scaled, (x, dy + 16), scaled)
        d.text((x, dy + 16 + size[1] + 8), name.upper(), fill=(230, 204, 169))
        x += max(size[0] + 34, 126)

    # Bank sample appears at half scale, still with crisp nearest-neighbour blocks.
    bx, by = 870, 590
    d.text((bx, by - 22), "BANK SAMPLE - FINAL 4x GRID", fill=(250, 224, 178))
    bank_preview = bank.resize((456, 528), Image.Resampling.NEAREST)
    sheet.paste(bank_preview, (bx, by))
    d.rectangle((bx - 2, by - 2, bx + 457, by + 529), outline=(247, 224, 194), width=2)
    return sheet


def main() -> None:
    ASSET.mkdir(parents=True, exist_ok=True)
    bank_out = MOCK / "round1_bank/bank_paint_4x.png"
    bank_out.parent.mkdir(parents=True, exist_ok=True)
    textures = {kind: build_texture(kind) for kind in ("water", "channel", "shallows", "sand")}
    for kind, image in textures.items():
        image.save(ASSET / f"{kind}_a.png")
    sprites = draw_decor()
    for name, image in sprites.items():
        image.save(ASSET / f"{name}.png")
    island = draw_island_b()
    palm = draw_palm()
    island.save(ASSET / "island_b.png")
    palm.save(ASSET / "palm_a.png")
    bank = build_bank_sample(textures)
    bank.save(bank_out)
    preview = build_preview(textures, sprites, island, palm, bank)
    preview.save(MOCK / "round1_sample_preview.png")

    # Delivery checks: final sizes, hard alpha, opaque tile fills, and 4× guide geometry.
    for name, image in textures.items():
        assert image.size == (190, 190) and image.mode == "RGB", name
    assert island.size == (120, 64) and palm.size == (30, 40)
    for name, image in sprites.items():
        assert set(image.getchannel("A").tobytes()) <= {0, 255}, name
    assert bank.size == (1520, 1760)
    print(f"Wrote Lagoon round-1 sample to {ASSET}")
    print(f"Bank paint: {bank_out}")
    print(f"Preview: {MOCK / 'round1_sample_preview.png'}")


if __name__ == "__main__":
    main()
