"""Extract and size the New Shrine title logos from their approved proof sheet."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs/mockups/new_shrine_titles_side_by_side.png"
OUT = ROOT / "textures/menus/new_shrine_titles"

# Per-word alpha bounds in the horizontal reference wordmarks.
# The first four titles are stacked in the app; the last two stay on one line.
TITLES = {
    # bounds, native logo envelope (the original hub logo texture size)
    "coin_shop.png": ([(47, 293, 220, 400), (307, 576, 220, 400)], (205, 106)),
    "tomo_pedia.png": ([(647, 930, 220, 400), (943, 1205, 220, 400)], (200, 106)),
    "dress_up.png": ([(1280, 1587, 220, 400), (1601, 1737, 220, 400)], (205, 106)),
    "home_decor.png": ([(48, 302, 480, 660), (314, 621, 480, 660)], (205, 106)),
    "backgrounds.png": ([(682, 1299, 480, 660)], (228, 86)),
    "cases.png": ([(1363, 1726, 480, 660)], (205, 56)),
}

sheet = Image.open(SOURCE).convert("RGBA")
line_gap = 4
for filename, (word_bounds, canvas_size) in TITLES.items():
    line_height = (canvas_size[1] - line_gap) // 2 if len(word_bounds) == 2 else canvas_size[1]
    lines = []
    for x0, x1, y0, y1 in word_bounds:
        art = sheet.crop((x0, y0, x1, y1))
        alpha = art.getchannel("A").point(lambda a: 255 if a > 12 else 0)
        art.putalpha(alpha)
        art = art.crop(alpha.getbbox())
        # Preserve letter proportions while sizing the stacked words to their logo slot.
        if len(word_bounds) == 1 and filename == "cases.png":
            size = canvas_size
        elif len(word_bounds) == 1:
            scale = min(canvas_size[0] / art.width, canvas_size[1] / art.height)
            size = (round(art.width * scale), round(art.height * scale))
        else:
            width = round(art.width * line_height / art.height)
            size = (width, line_height)
        lines.append(art.resize(size, Image.Resampling.NEAREST))
    if len(lines) == 2:
        target_width = round(canvas_size[0] * 0.88)
        widest = max(line.width for line in lines)
        x_scale = target_width / widest
        lines = [line.resize((round(line.width * x_scale), line.height), Image.Resampling.NEAREST) for line in lines]
    block_height = len(lines) * line_height + (len(lines) - 1) * line_gap
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    y = (canvas_size[1] - block_height) // 2
    if filename == "backgrounds.png":
        y += 8
    for line in lines:
        canvas.alpha_composite(line, ((canvas_size[0] - line.width) // 2, y))
        y += line_height + line_gap
    canvas.save(OUT / filename)
    print(filename, 'canvas', canvas_size, 'lines', len(lines), 'capital height', line_height)
