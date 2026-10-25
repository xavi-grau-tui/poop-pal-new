"""Draft text-only pixel titles for the settings menu carousel.

Run with the project's Pillow environment:
  PYTHONPATH=/private/tmp/haratomo-python-deps python3 tools/design/settings_titles_draft.py
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/mockups/settings_title_drafts"
OUT.mkdir(parents=True, exist_ok=True)

W, H = 260, 141
SCALE = 2
FONT_PATH = ROOT / "fonts/Pixellari.ttf"
DARK = (54, 31, 35, 255)
PAPER = (232, 222, 204, 255)

PALETTES = [
    ("COIN SHOP", ("COIN", "SHOP"), (179, 112, 54), (220, 157, 80), (248, 207, 129)),
    ("TOMO PEDIA", ("TOMO", "PEDIA"), (75, 120, 91), (121, 163, 117), (190, 211, 151)),
    ("DRESS UP", ("DRESS", "UP"), (133, 72, 90), (184, 103, 114), (233, 158, 148)),
    ("HOME DECOR", ("HOME", "DECOR"), (81, 105, 77), (132, 145, 89), (206, 194, 130)),
    ("BACKGROUNDS", ("BACK", "GROUNDS"), (67, 91, 124), (102, 134, 163), (174, 194, 201)),
    ("CASES", ("CASES",), (113, 72, 93), (160, 98, 116), (220, 155, 142)),
]

def title_art(lines, base, mid, light):
    # Shared round, chunky letterforms with layered pixel shading, like the game
    # title logos. Draw at half resolution for crisp 2 px pixel clusters.
    canvas = Image.new("RGBA", (W // SCALE, H // SCALE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    # Fit each phrase on one line; all labels share a baseline and visual height.
    size = 38 if len(lines) > 1 else 50
    while size > 20:
        font = ImageFont.truetype(str(FONT_PATH), size)
        widths = [draw.textbbox((0, 0), line, font=font, stroke_width=2)[2] - draw.textbbox((0, 0), line, font=font, stroke_width=2)[0] for line in lines]
        if max(widths) <= canvas.width - 10:
            break
        size -= 1
    font = ImageFont.truetype(str(FONT_PATH), size)
    line_boxes = [draw.textbbox((0, 0), line, font=font, stroke_width=2) for line in lines]
    line_h = max(b[3] - b[1] for b in line_boxes)
    line_step = line_h + 2
    total_h = line_h + (len(lines) - 1) * line_step
    y0 = (canvas.height - total_h) // 2

    mask = Image.new("L", canvas.size, 0)
    md = ImageDraw.Draw(mask)
    for i, (line, box) in enumerate(zip(lines, line_boxes)):
        x = (canvas.width - (box[2] - box[0])) // 2 - box[0]
        y = y0 + i * line_step - box[1]
        md.text((x, y), line, font=font, fill=255)
    # Add one pixel of body weight so these read as custom logo lettering rather
    # than the thin default font cut.
    mask = mask.filter(ImageFilterMax(3))
    # Offset extrusion and a heavy dark outline, without any surrounding icons.
    shadow = Image.new("L", canvas.size, 0)
    shadow.paste(mask, (2, 3))
    shadow = shadow.filter(ImageFilterMax(5))
    rgba = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    rgba.paste(DARK, (0, 0, *canvas.size), shadow)

    outline = Image.new("L", canvas.size, 0)
    od = ImageDraw.Draw(outline)
    for i, (line, box) in enumerate(zip(lines, line_boxes)):
        x = (canvas.width - (box[2] - box[0])) // 2 - box[0]
        y = y0 + i * line_step - box[1]
        od.text((x, y), line, font=font, fill=255, stroke_width=2, stroke_fill=255)
    # The face uses a warm top bevel and a shaded lower edge; all detail stays
    # inside the letterforms so the titles remain pure typography.
    arr = np.zeros((canvas.height, canvas.width, 4), dtype="uint8")
    m = np.asarray(mask) > 0
    yy = np.indices(m.shape)[0]
    arr[np.asarray(outline) > 0] = DARK
    height = max(1, int(yy[m].max() - yy[m].min() + 1))
    top = int(yy[m].min())
    arr[m & (yy < top + height // 3)] = (*light, 255)
    arr[m & (yy >= top + height // 3) & (yy < top + 2 * height // 3)] = (*mid, 255)
    arr[m & (yy >= top + 2 * height // 3)] = (*base, 255)
    top_edge = m & ~np.roll(m, 1, axis=0)
    bottom_edge = m & ~np.roll(m, -1, axis=0)
    arr[top_edge] = (255, 229, 178, 255)
    arr[bottom_edge] = (*base, 255)
    face = Image.fromarray(arr, "RGBA")
    rgba.alpha_composite(face)
    return rgba.resize((W, H), Image.Resampling.NEAREST)

def ImageFilterMax(size=5):
    from PIL import ImageFilter
    return ImageFilter.MaxFilter(size)

sheet = Image.new("RGBA", (684, 644), PAPER)
sd = ImageDraw.Draw(sheet)
for i, (name, lines, base, mid, light) in enumerate(PALETTES):
    col, row = i % 2, i // 2
    x, y = 12 + col * 340, 12 + row * 220
    panel = Image.new("RGBA", (320, 180), (0, 0, 0, 0))
    art = title_art(lines, base, mid, light)
    panel.alpha_composite(art, (30, 19))
    sheet.alpha_composite(panel, (x, y))
    sd.rectangle((x, y, x + 319, y + 179), outline=(184, 164, 139, 255), width=1)
    art.save(OUT / (name.lower().replace(" ", "_") + ".png"))

sheet.convert("RGB").save(OUT / "settings_titles_sheet.png")
print(OUT / "settings_titles_sheet.png")
