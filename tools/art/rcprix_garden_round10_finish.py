"""Complete Garden round-10 overlays on the approved final pixel grid.

Keeps the approved start_h and boost_e PNGs; all other directional art is drawn
from the same forms. The long ramp uses the approved imagegen source pixels.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/garden"
DOC = ROOT / "docs/mockups/rcprix_garden"
INK = (40, 30, 40, 255)
CREAM = (245, 239, 218, 255)
CREAM_LIGHT = (255, 251, 236, 255)
DARK_CHECK = (58, 55, 62, 255)
PAD = (31, 48, 61, 255)
CYAN = (48, 204, 218, 255)
CYAN_LIGHT = (143, 245, 232, 255)
CYAN_SHADE = (25, 133, 157, 255)


def blank() -> Image.Image:
    return Image.new("RGBA", (180, 180), (0, 0, 0, 0))


def start_line(vertical: bool, wide: bool) -> Image.Image:
    """Draw in screen coordinates so top-left shading is never rotated."""
    im = blank()
    d = ImageDraw.Draw(im)
    across0 = 46 if wide else 52
    across1 = 134 if wide else 128
    # Three checker rows along travel; one tile every eight pixels across.
    for travel in range(3):
        for across in range(across0, across1, 8):
            a1 = min(across + 8, across1)
            light = (travel + ((across - across0) // 8)) % 2 == 0
            c = CREAM if light else DARK_CHECK
            shade = (173, 169, 159, 255) if light else (35, 33, 41, 255)
            if vertical:
                x0, x1 = across, a1 - 1
                y0, y1 = 78 + travel * 8, 85 + travel * 8
            else:
                x0, x1 = 78 + travel * 8, 85 + travel * 8
                y0, y1 = across, a1 - 1
            d.rectangle((x0, y0, x1, y1), fill=c)
            d.line((x0, y1, x1, y1), fill=shade, width=1)
            if light:
                d.line((x0, y0, x1, y0), fill=CREAM_LIGHT, width=1)
    if vertical:
        d.rectangle((across0 - 1, 77, across1, 102), outline=INK)
        for y in (75, 103):
            d.rectangle((across0, y, across1 - 1, y + 1), fill=CREAM_LIGHT)
            d.line((across0, y + 2, across1 - 1, y + 2), fill=INK)
        # Sparse road scuffs are part of the transparent overlay.
        for box in ((59, 71, 62, 72), (108, 108, 111, 109), (72, 107, 75, 108)):
            d.rectangle(box, fill=(72, 77, 88, 255))
    else:
        d.rectangle((77, across0 - 1, 102, across1), outline=INK)
        for x in (75, 103):
            d.rectangle((x, across0, x + 1, across1 - 1), fill=CREAM_LIGHT)
            d.line((x + 2, across0, x + 2, across1 - 1), fill=INK)
        for box in ((68, across0 + 13, 71, across0 + 14),
                    (108, across1 - 21, 111, across1 - 20)):
            d.rectangle(box, fill=(72, 77, 88, 255))
    return im


def _east_arrows() -> Image.Image:
    arrow = blank()
    d = ImageDraw.Draw(arrow)
    for x in (74, 87, 100):
        d.polygon([(x - 6, 75), (x - 1, 75), (x + 7, 90), (x - 1, 105),
                   (x - 6, 105), (x + 1, 90)], fill=INK)
        d.polygon([(x - 4, 77), (x - 1, 77), (x + 5, 90), (x - 1, 103),
                   (x - 4, 103), (x + 3, 90)], fill=CYAN_SHADE)
        d.polygon([(x - 3, 78), (x - 1, 78), (x + 4, 90), (x - 1, 102),
                   (x - 3, 102), (x + 2, 90)], fill=CYAN)
        d.rectangle((x + 2, 87, x + 4, 92), fill=CYAN_LIGHT)
        d.rectangle((x + 3, 89, x + 5, 91), fill=(244, 253, 230, 255))
    return arrow


def boost(direction: str) -> Image.Image:
    # Plate light remains fixed on the screen's top-left; only the chevrons
    # change direction and their bright tips are repainted accordingly.
    im = blank()
    d = ImageDraw.Draw(im)
    d.rectangle((57, 57, 122, 122), fill=(38, 126, 146, 255))
    d.rectangle((58, 58, 121, 121), fill=(54, 173, 187, 255))
    d.rectangle((60, 60, 119, 119), fill=INK)
    d.rectangle((62, 62, 117, 117), fill=(90, 108, 122, 255))
    d.rectangle((64, 64, 115, 115), fill=(145, 161, 169, 255))
    d.rectangle((66, 66, 113, 113), fill=INK)
    d.rectangle((68, 68, 111, 111), fill=PAD)
    d.rectangle((69, 69, 110, 72), fill=(37, 75, 91, 255))
    d.rectangle((69, 107, 110, 110), fill=(22, 40, 55, 255))
    arrows = _east_arrows()
    if direction == "w":
        arrows = arrows.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    elif direction == "n":
        arrows = arrows.transpose(Image.Transpose.ROTATE_90)
    elif direction == "s":
        arrows = arrows.transpose(Image.Transpose.ROTATE_270)
    im.alpha_composite(arrows)
    for x in (64, 112):
        for y in (64, 112):
            d.rectangle((x - 2, y - 2, x + 2, y + 2), fill=INK)
            d.rectangle((x - 1, y - 1, x + 1, y + 1), fill=CYAN)
            d.point((x - 1, y - 1), fill=CYAN_LIGHT)
    return im


def _source_ramp() -> Image.Image:
    source = Image.open(DOC / "round10_ramp_imagegen_reference.png").convert("RGBA")
    mask = Image.new("L", source.size, 0)
    ImageDraw.Draw(mask).polygon(
        [(304, 524), (318, 511), (924, 381), (975, 380), (991, 387),
         (993, 817), (988, 832), (974, 838), (309, 838), (303, 828)], fill=255,
    )
    source.putalpha(mask)
    return source.crop(mask.getbbox())


def _screen_relight(im: Image.Image) -> Image.Image:
    """Relight transformed wood and metal for the fixed top-left sun."""
    pixels = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if not a or max(r, g, b) < 62:  # preserve transparent and dark outline
                continue
            if r > 215 and g > 205 and b > 180:  # preserve arrow paint
                continue
            exposure = round(10 * (1 - x / max(1, w - 1) - y / max(1, h - 1)))
            if r > g * 1.14 and r > b * 1.22:  # wood
                delta = exposure
            elif abs(r - g) < 30 and abs(g - b) < 30:  # steel brackets
                delta = round(exposure * .7)
            else:
                continue
            pixels[x, y] = (max(0, min(255, r + delta)),
                            max(0, min(255, g + delta)),
                            max(0, min(255, b + delta)), 255)
    return im


def ramp(direction: str, wide: bool) -> Image.Image:
    # Reach stays 97 px in every variant, as RcTiles measures the east asset.
    span = 88 if wide else 76
    art = _source_ramp().resize((97, span), Image.Resampling.NEAREST)
    if direction == "w":
        art = art.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    elif direction == "n":
        art = art.transpose(Image.Transpose.ROTATE_90)
    elif direction == "s":
        art = art.transpose(Image.Transpose.ROTATE_270)
    if direction != "e":
        art = _screen_relight(art)
    im = blank()
    if direction == "e":
        pos = (41, 46 if wide else 52)
    elif direction == "w":
        pos = (42, 46 if wide else 52)
    elif direction == "n":
        pos = (46 if wide else 52, 42)
    else:
        pos = (46 if wide else 52, 41)
    im.alpha_composite(art, pos)
    return im


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    assets = {}
    for wide in (False, True):
        suffix = "_wide" if wide else ""
        for direction in "ewns":
            assets[f"ramp_{direction}{suffix}"] = ramp(direction, wide)
            if direction != "e" or wide:
                assets[f"boost_{direction}{suffix}"] = boost(direction)
        assets[f"start_v{suffix}"] = start_line(True, wide)
        if wide:
            assets["start_h_wide"] = start_line(False, True)
    for name, im in assets.items():
        im.save(OUT / f"{name}.png", optimize=True)
    previews()
    print("Wrote", len(assets), "round-10 overlays")


def previews():
    """Enlarge the delivered files over their matching road pieces."""
    grass = Image.open(OUT / "grass_a.png").convert("RGBA")
    for kind in ("ramp", "boost"):
        sheet = Image.new("RGB", (2220, 1140), (239, 233, 216))
        draw = ImageDraw.Draw(sheet)
        for row, wide in enumerate((False, True)):
            suffix = "_wide" if wide else ""
            for col, direction in enumerate("ewns"):
                road = "straight_h" if direction in "ew" else "straight_v"
                cell = grass.copy()
                cell.alpha_composite(Image.open(OUT / f"{road}{suffix}.png").convert("RGBA"))
                cell.alpha_composite(Image.open(OUT / f"{kind}_{direction}{suffix}.png").convert("RGBA"))
                x, y = 12 + col * 550, 23 + row * 560
                draw.text((x, y - 15), f"{kind}_{direction}{suffix}", fill=INK)
                sheet.paste(cell.resize((540, 540), Image.Resampling.NEAREST).convert("RGB"), (x, y))
        sheet.save(DOC / f"round10_{kind}s_all_3x.png")
    sheet = Image.new("RGB", (2220, 585), (239, 233, 216))
    draw = ImageDraw.Draw(sheet)
    for col, name in enumerate(("start_h", "start_v", "start_h_wide", "start_v_wide")):
        suffix = "_wide" if name.endswith("_wide") else ""
        road = "straight_h" if name.startswith("start_h") else "straight_v"
        cell = grass.copy()
        cell.alpha_composite(Image.open(OUT / f"{road}{suffix}.png").convert("RGBA"))
        cell.alpha_composite(Image.open(OUT / f"{name}.png").convert("RGBA"))
        x = 12 + col * 550
        draw.text((x, 8), name, fill=INK)
        sheet.paste(cell.resize((540, 540), Image.Resampling.NEAREST).convert("RGB"), (x, 28))
    sheet.save(DOC / "round10_starts_all_3x.png")


if __name__ == "__main__":
    main()
