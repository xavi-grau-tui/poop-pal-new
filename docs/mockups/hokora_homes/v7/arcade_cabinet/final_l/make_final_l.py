"""Review-only pixel finish of the approved current_k cabinet.

Run from the repository root with .venv/bin/python. This script writes only
docs/mockups/hokora_homes/v7/arcade_cabinet/final_l/.
"""
from pathlib import Path
import shutil
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont
import numpy as np
from scipy import ndimage

HERE = Path(__file__).resolve().parent
SRC = HERE.parent / "current_k"
FONT_LATIN = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_CJK = "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"
INK = (44, 25, 25, 255)
SHADOW = (117, 75, 55, 255)
CREAM = (255, 239, 216, 255)
CREAM_LIGHT = (255, 248, 233, 255)
CREAM_LOW = (245, 220, 193, 255)
RED_BASE = (223, 43, 56, 255)
RED_DEEP = (113, 26, 40, 255)
RED_LIGHT = (255, 92, 87, 255)
GOLD = (226, 163, 75, 255)


def load(name):
    return Image.open(SRC / name).convert("RGBA")


old_front = load("front.png")
old_trays = load("trays.png")
inside = load("inside.png")
glass = load("glass.png")
front = old_front.copy()
trays = old_trays.copy()
fp, sp = front.load(), old_front.load()
tp, stp = trays.load(), old_trays.load()


def set_opaque(image, x, y, colour):
    if 0 <= x < 220 and 0 <= y < 220 and image.getpixel((x, y))[3] == 255:
        image.putpixel((x, y), colour)


def sign_interior(image, scale):
    """Clean only the letter field, retaining the original gold plate and screws."""
    p = image.load()
    for y in range(22 * scale, 43 * scale):
        for x in range(71 * scale, 153 * scale):
            if p[x, y][3] == 255:
                row = y // scale
                p[x, y] = CREAM_LIGHT if row <= 25 else CREAM_LOW if row >= 40 else CREAM


def hard_text_mask(size, text, font_path, font_size, xy):
    mask = Image.new("L", size)
    d = ImageDraw.Draw(mask)
    d.text(xy, text, font=ImageFont.truetype(font_path, font_size), fill=255)
    return mask.point(lambda v: 255 if v >= 128 else 0)


def draw_latin(image, scale):
    mask = Image.new("L", image.size)
    draw = ImageDraw.Draw(mask)
    font = ImageFont.truetype(FONT_LATIN, 15 * scale)
    cursor = 71 * scale
    for glyph in "KamiTomo":
        draw.text((cursor, 18 * scale), glyph, font=font, fill=255)
        cursor += round(font.getlength(glyph)) + scale
    mask = mask.point(lambda v: 255 if v >= 128 else 0)
    ink_pixels = np.asarray(mask) > 0
    # Outline the *outside* of each glyph, preserving the open counters in
    # a, o and m; a generic dilation would close them at this pixel size.
    outer = ndimage.binary_dilation(ink_pixels, iterations=scale) & ~ndimage.binary_fill_holes(ink_pixels)
    p = image.load(); m = mask.load()
    raw_box = mask.getbbox()
    assert raw_box is not None
    box = (max(0, raw_box[0] - scale), max(0, raw_box[1] - scale),
           min(image.width, raw_box[2] + scale), min(image.height, raw_box[3] + scale))
    for y in range(box[1], box[3]):
        for x in range(box[0], box[2]):
            if p[x, y][3] != 255:
                continue
            if outer[y, x] and not m[x, y]:
                p[x, y] = INK
            if m[x, y]:
                art_y = y // scale
                p[x, y] = (250, 226, 197, 255) if art_y <= 25 else (
                    (159, 112, 82, 255) if art_y >= 33 else (216, 170, 132, 255))
    # A separate single-pixel bottom offset reads as lacquered lettering,
    # without thickening the outline or closing the small counters.
    for y in range(raw_box[3] - scale, raw_box[3]):
        for x in range(box[0], box[2]):
            if m[x, y] and p[x, y][3] == 255:
                p[x, y] = SHADOW


def draw_cjk(image, scale):
    mask = hard_text_mask(image.size, "神友", FONT_CJK, 13 * scale,
                          (124 * scale, 28 * scale))
    # Unicode font strokes stay one art pixel on the standard sign. Double
    # density lets their small counters breathe in the comparison version.
    p = image.load(); m = mask.load()
    box = mask.getbbox()
    assert box is not None
    for y in range(box[1], box[3]):
        for x in range(box[0], box[2]):
            if m[x, y] and p[x, y][3] == 255:
                p[x, y] = INK if y < box[3] - scale else SHADOW


sign_interior(front, 1)
draw_latin(front, 1)
draw_cjk(front, 1)

# Recolour the pixels already forming the left-arm joint. The silhouette,
# arm position and 2-pixel external outline are left untouched.
for y in range(14, 27):
    for x in range(40, 47):
        r, g, b, a = sp[x, y]
        if a != 255:
            continue
        if r > 120 and r > 1.6 * g and r > 1.5 * b:
            fp[x, y] = RED_LIGHT if x <= 42 and y <= 19 else RED_BASE
        elif r < 65 and g < 65 and b < 65:
            fp[x, y] = (32, 0, 16, 255)
for x, y in ((43, 18), (44, 18), (43, 19), (44, 19)):
    set_opaque(front, x, y, GOLD if x == 43 and y == 18 else RED_DEEP)

# Cap shoulders: keep their cut shape and reinforce the existing perimeter.
for x0, x1 in ((42, 54), (166, 178)):
    for y in range(9, 32):
        for x in range(x0, x1):
            r, g, b, a = sp[x, y]
            if a != 255:
                continue
            around = [sp[x + dx, y + dy][3] for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1))]
            if 0 in around and r < 100 and g < 100 and b < 100:
                fp[x, y] = (32, 0, 16, 255)

# Flat deck ends and the four screw heads. Only the face is coloured; no top
# or side surface is painted into the image for the tilt renderer to duplicate.
for y in range(147, 165):
    for x in (39, 40, 179, 180):
        q = sp[x, y]
        if q[3] == 255 and q[0] > 125 and q[1] > 95:
            fp[x, y] = (173, 131, 106, 255) if x in (39, 180) else CREAM_LIGHT
for x, y in ((44, 162), (175, 162)):
    for dx, dy, c in ((0, 0, GOLD), (1, 0, SHADOW), (0, 1, SHADOW)):
        set_opaque(front, x + dx, y + dy, c)

# Remove any leftover dark pixel at the joystick's former foot, using the
# surrounding deck tone of the same row; keep the relocated joystick intact.
for y in range(151, 164):
    for x in range(72, 81):
        r, g, b, a = sp[x, y]
        if a == 255 and (r < 155 or b < 120):
            fp[x, y] = sp[89, y]

# Make the inner ends of the trays read as their flat red front faces.
for y in range(150, 168):
    for x in list(range(35, 42)) + list(range(178, 185)):
        r, g, b, a = stp[x, y]
        if a != 255:
            continue
        if y >= 154 and r > 130:
            tp[x, y] = RED_DEEP if x in (40, 179) else RED_BASE

# Buttons: wipe only the old button footprints back to the local cream deck,
# then paint three equal rounded caps eight pixels to the right.
for y in range(150, 165):
    for x in range(129, 167):
        if fp[x, y][3] == 255:
            fp[x, y] = sp[122, y]

def button(cx, body, light, shade):
    # 11x9, dark rim, one-pixel shadow and a two-pixel top-left shine.
    for y in range(151, 163):
        for x in range(cx - 6, cx + 7):
            if fp[x, y][3] != 255:
                continue
            dx = (x - cx) / 5.2
            dy = (y - 156.5) / 4.2
            d = dx * dx + dy * dy
            if d <= 1.0:
                fp[x, y] = INK if d > .68 else shade if y >= 159 else body
    for x in range(cx - 3, cx + 4):
        set_opaque(front, x, 163, (139, 102, 82, 255))
    for x, y in ((cx - 2, 154), (cx - 1, 154)):
        set_opaque(front, x, y, light)

button(144, (237, 57, 66, 255), (255, 223, 214, 255), (185, 27, 38, 255))
button(156, (22, 168, 237, 255), (217, 247, 255, 255), (8, 95, 180, 255))
button(168, (249, 180, 19, 255), (255, 250, 205, 255), (183, 119, 10, 255))

front.save(HERE / "front.png")
trays.save(HERE / "trays.png")
shutil.copyfile(SRC / "inside.png", HERE / "inside.png")
shutil.copyfile(SRC / "glass.png", HERE / "glass.png")

# Alternative: only the sign plate, aligned on a 440x440 transparent canvas.
# It is not a blurred upscale: lettering is independently rasterized at 2x.
double = old_front.resize((440, 440), Image.Resampling.NEAREST)
sign2 = Image.new("RGBA", (440, 440))
sign2.paste(double.crop((54 * 2, 17 * 2, 166 * 2, 47 * 2)), (54 * 2, 17 * 2))
sign_interior(sign2, 2)
draw_latin(sign2, 2)
draw_cjk(sign2, 2)
sign2.save(HERE / "sign_2x.png")

assembled = Image.new("RGBA", (220, 220))
for layer in (inside, glass, trays, front):
    assembled.alpha_composite(layer)
assembled.resize((1760, 1760), Image.Resampling.NEAREST).save(HERE / "preview_8x.png")
assembled.resize((96, 96), Image.Resampling.NEAREST).save(HERE / "icon.png")

for before, after, name in ((old_front, front, "front"), (old_trays, trays, "trays"),
                            (inside, inside, "inside"), (glass, glass, "glass")):
    assert before.getchannel("A").tobytes() == after.getchannel("A").tobytes(), name
assert ImageChops.difference(load("inside.png"), inside).getbbox() is None
assert ImageChops.difference(load("glass.png"), glass).getbbox() is None

diff = Image.new("RGBA", (880, 220))
dp = diff.load()
changed = []
outside = 0


def allowed_front(x, y):
    return (70 <= x <= 153 and 20 <= y <= 44) or (
        40 <= x <= 54 and 9 <= y <= 31) or (
        166 <= x <= 178 and 9 <= y <= 31) or (
        39 <= x <= 45 and 147 <= y <= 165) or (
        175 <= x <= 180 and 147 <= y <= 165) or (
        72 <= x <= 80 and 151 <= y <= 163) or (
        129 <= x <= 174 and 150 <= y <= 164)


def allowed_trays(x, y):
    return 150 <= y <= 167 and (35 <= x <= 41 or 178 <= x <= 184)


for i, (before, after) in enumerate(((old_front, front), (old_trays, trays),
                                     (inside, inside), (glass, glass))):
    a, b = before.load(), after.load()
    n = 0
    for y in range(220):
        for x in range(220):
            if a[x, y] != b[x, y]:
                dp[i * 220 + x, y] = (255, 25, 225, 255)
                n += 1
                if (i == 0 and not allowed_front(x, y)) or (
                    i == 1 and not allowed_trays(x, y)) or i >= 2:
                    outside += 1
            elif a[x, y][3]:
                r, g, bl, _ = a[x, y]
                dp[i * 220 + x, y] = (r // 3, g // 3, bl // 3, 255)
    changed.append(n)
diff.resize((3520, 880), Image.Resampling.NEAREST).save(HERE / "diff_vs_current_k_4x.png")
assert outside == 0, f"{outside} pixels changed outside the named finish areas"
print("final_l audit: changed front/trays/inside/glass =", changed,
      f"; changed outside allowed areas = {outside}; all alpha masks identical; no game files touched")

comparison = Image.new("RGBA", (111 * 3 * 8, 30 * 8), (32, 25, 29, 255))
old_sign = old_front.crop((55, 17, 166, 47)).resize((888, 240), Image.Resampling.NEAREST)
new_sign = front.crop((55, 17, 166, 47)).resize((888, 240), Image.Resampling.NEAREST)
double_sign = sign2.crop((110, 34, 332, 94)).resize((888, 240), Image.Resampling.NEAREST)
for j, part in enumerate((old_sign, new_sign, double_sign)):
    comparison.alpha_composite(part, (j * 888, 0))
comparison.save(HERE / "sign_comparison.png")
