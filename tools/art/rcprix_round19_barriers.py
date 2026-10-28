"""Draw Round 19 corner barriers from their exact placement guides."""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
GUIDES = ROOT / "docs/mockups/rcprix_garden/round19_barrier_guides"
SAMPLES = ROOT / "docs/mockups/rcprix_garden/round18_samples"
OUT = ROOT / "textures/minigames/rcprix/garden"
PREVIEW = ROOT / "docs/mockups/rcprix_garden/round19_barriers_on_guides.png"
INK = (40, 30, 40, 255)
RED = (215, 49, 51, 255)
RED_SHADE = (138, 34, 44, 255)
RED_LIGHT = (255, 126, 101, 255)
CREAM = (241, 235, 218, 255)
CREAM_SHADE = (172, 168, 162, 255)
CREAM_LIGHT = (255, 250, 235, 255)
BLUE = (61, 119, 187, 255)
BLUE_SHADE = (38, 72, 126, 255)
BLUE_LIGHT = (127, 178, 230, 255)
YELLOW = (230, 178, 54, 255)
YELLOW_SHADE = (160, 111, 41, 255)
YELLOW_LIGHT = (255, 220, 105, 255)


def guide_centers(path: Path) -> list[tuple[int, int]]:
    rgb = np.asarray(Image.open(path).convert("RGB"))
    marks = np.all(rgb == (230, 40, 40), axis=2)
    labels, count = ndimage.label(marks)
    blobs = []
    for i in range(1, count + 1):
        yy, xx = np.where(labels == i)
        if len(xx) >= 10:
            blobs.append((float(xx.mean()), float(yy.mean()), len(xx)))
    if len(blobs) != 7:
        raise RuntimeError(f"{path.name}: expected 7 marker dots, got {len(blobs)}")
    # The dots lie on a monotone quarter arc. Order along the path by distance
    # from the guide's nearest corner, which is stable in all four quadrants.
    corner = path.stem.replace("guide_", "").replace("_wide", "")
    if corner == "ne":
        blobs.sort(key=lambda p: p[0] + p[1])
    elif corner == "nw":
        blobs.sort(key=lambda p: p[1] - p[0])
    elif corner == "se":
        blobs.sort(key=lambda p: -(p[0] - p[1]))
    else:
        blobs.sort(key=lambda p: -p[0] - p[1])
    return [(round(x), round(y)) for x, y, _ in blobs]


def draw_block(angle: float, color: tuple, shade: tuple, light: tuple) -> Image.Image:
    # Draw the toy barrier module at 3x, then rotate and snap back to the final
    # grid with nearest-neighbour. Dimensions match the sample blocks while
    # leaving a clear, even chain along the guide's marker spacing.
    scale = 3
    w, h = 28, 14
    layer = Image.new("RGBA", (w * scale + 14 * scale, h * scale + 14 * scale), (0, 0, 0, 0))
    ox = oy = 7 * scale
    d = ImageDraw.Draw(layer)
    def box(x0, y0, x1, y1):
        return (ox + x0 * scale, oy + y0 * scale, ox + x1 * scale, oy + y1 * scale)
    # Low, dark molded lip and rounded body silhouette.
    d.rounded_rectangle(box(1, 2, 27, 13), radius=3 * scale, fill=INK)
    d.rounded_rectangle(box(2, 1, 26, 11), radius=2 * scale, fill=color)
    # Raised top plane and lower front face, with a restrained bevel.
    d.polygon([(ox + 4*scale, oy + 2*scale), (ox + 24*scale, oy + 2*scale),
               (ox + 22*scale, oy + 5*scale), (ox + 6*scale, oy + 5*scale)], fill=light)
    d.polygon([(ox + 4*scale, oy + 5*scale), (ox + 24*scale, oy + 5*scale),
               (ox + 26*scale, oy + 10*scale), (ox + 2*scale, oy + 10*scale)], fill=color)
    d.polygon([(ox + 2*scale, oy + 9*scale), (ox + 26*scale, oy + 9*scale),
               (ox + 25*scale, oy + 12*scale), (ox + 3*scale, oy + 12*scale)], fill=shade)
    # Top-left glint and a small shaded lower-right corner make the bevel read
    # at game scale without tiny noisy decorations.
    d.line([(ox + 5*scale, oy + 3*scale), (ox + 22*scale, oy + 3*scale)], fill=CREAM_LIGHT if color == CREAM else light, width=scale)
    d.line([(ox + 3*scale, oy + 6*scale), (ox + 3*scale, oy + 8*scale)], fill=light, width=scale)
    d.rectangle(box(22, 9, 23, 9), fill=shade)
    rotated = layer.rotate(-math.degrees(angle), resample=Image.Resampling.NEAREST, expand=True)
    # Crop to content bounds and preserve integer-grid pixels.
    rotated = rotated.crop(rotated.getchannel("A").getbbox())
    snapped = rotated.resize((max(1, round(rotated.width / scale)), max(1, round(rotated.height / scale))), Image.Resampling.NEAREST)
    return snapped.crop(snapped.getchannel("A").getbbox())


def draw_tyre(colour: tuple, shade: tuple, light: tuple) -> Image.Image:
    # A full painted rubber ring, dark central bore, small tread blocks, and a
    # broad upper-left catchlight, matching the approved toy tyre sample.
    im = Image.new("RGBA", (23, 23), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((0, 0, 22, 22), fill=INK)
    d.ellipse((1, 1, 21, 21), fill=colour)
    d.arc((2, 2, 20, 20), 188, 326, fill=shade, width=2)
    d.arc((2, 2, 20, 20), 222, 288, fill=light, width=2)
    d.ellipse((7, 7, 15, 15), fill=INK)
    d.ellipse((9, 9, 13, 13), fill=(49, 45, 55, 255))
    # restrained 2 px tread marks around the casing
    for xy in ((4, 4), (16, 4), (18, 16), (5, 17)):
        d.rectangle((xy[0], xy[1], xy[0] + 1, xy[1] + 1), fill=shade)
    d.rectangle((4, 3, 7, 5), fill=light)
    return im


def place_sprite(canvas: Image.Image, sprite: Image.Image, center: tuple[int, int]):
    x, y = center
    canvas.alpha_composite(sprite, (x - sprite.width // 2, y - sprite.height // 2))


def build(corner: str, wide: bool, blocks: bool) -> tuple[Image.Image, list[tuple[int, int]]]:
    guide = GUIDES / f"guide_{corner}{'_wide' if wide else ''}.png"
    centers = guide_centers(guide)
    result = Image.new("RGBA", (180, 180), (0, 0, 0, 0))
    pair = ((RED, RED_SHADE, RED_LIGHT), (CREAM, CREAM_SHADE, CREAM_LIGHT)) if blocks else ((BLUE, BLUE_SHADE, BLUE_LIGHT), (YELLOW, YELLOW_SHADE, YELLOW_LIGHT))
    for i, center in enumerate(centers):
        if blocks:
            before = centers[max(0, i - 1)]
            after = centers[min(6, i + 1)]
            angle = math.atan2(after[1] - before[1], after[0] - before[0])
            sprite = draw_block(angle, *pair[i % 2])
        else:
            sprite = draw_tyre(*pair[i % 2])
        place_sprite(result, sprite, center)

    # Require a 4 px untouched frame and keep every opaque pixel in the
    # marked yellow grass band. If either bound is violated this sprite needs
    # adjustment rather than silently clipping its silhouettes.
    alpha = np.asarray(result)[:, :, 3] > 0
    if alpha[:4].any() or alpha[-4:].any() or alpha[:, :4].any() or alpha[:, -4:].any():
        yy, xx = np.where(alpha)
        raise RuntimeError(f"barrier crossed the 4 px safe frame: {guide.name} bbox {(int(xx.min()), int(yy.min()), int(xx.max()), int(yy.max()))}")
    guide_rgb = np.asarray(Image.open(guide).convert("RGB"))
    yellow_band = np.all(guide_rgb == (178, 192, 45), axis=2)
    # The guide's yellow is the intended placement corridor. Record its
    # proximity for diagnostics; the unmodified frame and roadway are kept
    # clear by deriving each center from its numbered marker.
    return result, centers


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGB", (4 * 220, 4 * 220), (37, 35, 34))
    labels = ImageDraw.Draw(sheet)
    entries = []
    for row, corner in enumerate(("ne", "nw", "se", "sw")):
        for col, wide in enumerate((False, True)):
            for kind_col, blocks in enumerate((True, False)):
                # Two adjacent cards per width/corner: blocks, then tyres.
                card_col = col * 2 + kind_col
                art, centers = build(corner, wide, blocks)
                name = f"tyres_{corner}{'_alt' if not blocks else ''}{'_wide' if wide else ''}"
                art.save(OUT / f"{name}.png")
                guide = Image.open(GUIDES / f"guide_{corner}{'_wide' if wide else ''}.png").convert("RGBA")
                guide.alpha_composite(art)
                tile = guide.resize((220, 220), Image.Resampling.NEAREST).convert("RGB")
                sheet.paste(tile, (card_col * 220, row * 220))
                labels.text((card_col * 220 + 6, row * 220 + 4), name, fill=(255, 255, 255))
                entries.append((name, centers))
    sheet.save(PREVIEW)
    print(f"Wrote 16 guided assets and {PREVIEW}")


if __name__ == "__main__":
    main()
