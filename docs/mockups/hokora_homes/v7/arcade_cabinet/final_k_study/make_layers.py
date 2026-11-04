"""Export the approved ImageGen study itself to registered 220-grid review layers.

Run from the repository root with .venv/bin/python. This writes only this folder.
No game textures or install scripts are touched.
"""
from pathlib import Path
from PIL import Image, ImageChops

HERE = Path(__file__).resolve().parent
SOURCE = HERE / "approved_study.png"
GUIDE = HERE.parent / "final_j" / "guide.png"
SIZE = 220


def save(image, name):
    image.save(HERE / name)


study = Image.open(SOURCE).convert("RGBA")
# At alpha >=128 the drawing ends at this precise box. Crop the halo and
# sample each source pixel once onto the fixed home grid; no smooth resampling.
crop = study.crop((43, 31, 1215, 1194))
sample = crop.resize((218, 217), Image.Resampling.NEAREST)
grid = Image.new("RGBA", (SIZE, SIZE))
grid.paste(sample, (1, 1))
grid.putalpha(grid.getchannel("A").point(lambda a: 255 if a >= 128 else 0))
save(grid, "study_on_220_grid.png")

front = grid.copy()
trays = Image.new("RGBA", (SIZE, SIZE))
inside = Image.new("RGBA", (SIZE, SIZE))
glass = Image.new("RGBA", (SIZE, SIZE))
gp = grid.load()
fp, tp, ip = front.load(), trays.load(), inside.load()


def in_tray(x, y):
    # The study's projecting deck wings, including their own cream tops.
    return 145 <= y <= 174 and (x <= 39 or x >= 180)


def in_opening(x, y):
    # Keep the game's 80 x 80 spirit window. The outer screw-mounted bezel
    # remains on the front; the inner bevel can slide with the screen layer.
    if not (70 <= x <= 149 and 64 <= y <= 143):
        return False
    cx = min(x - 70, 149 - x)
    cy = min(y - 64, 143 - y)
    return cx + cy >= 5


for y in range(SIZE):
    for x in range(SIZE):
        if not gp[x, y][3]:
            continue
        if in_tray(x, y):
            tp[x, y] = gp[x, y]
            fp[x, y] = (0, 0, 0, 0)
        elif in_opening(x, y):
            ip[x, y] = gp[x, y]
            fp[x, y] = (0, 0, 0, 0)

# Extra screen image behind its opening gives the tilt renderer room to slide.
# The front masks these pixels at zero tilt; their colour is from the same
# approved image, extended by the nearest edge where necessary.
for y in range(54, 154):
    for x in range(60, 160):
        if ip[x, y][3]:
            continue
        sx = min(149, max(70, x))
        sy = min(143, max(64, y))
        p = gp[sx, sy]
        if p[3]:
            ip[x, y] = p

save(front, "front.png")
save(trays, "trays.png")
save(inside, "inside.png")
save(glass, "glass.png")
save(Image.open(GUIDE).convert("RGBA"), "guide.png")
save(grid.resize((96, 96), Image.Resampling.NEAREST), "icon.png")

assembled = Image.new("RGBA", (SIZE, SIZE))
for layer in (inside, glass, trays, front):
    assembled.alpha_composite(layer)
save(assembled.resize((1760, 1760), Image.Resampling.NEAREST), "preview_8x.png")

# The full-size reference on the left and the exact delivered layers on the
# right; both shown at the same apparent size for a visual source audit.
left = crop.resize((880, 880), Image.Resampling.LANCZOS)
right = assembled.resize((880, 880), Image.Resampling.NEAREST)
comparison = Image.new("RGBA", (1760, 880), (28, 27, 30, 255))
comparison.alpha_composite(left, (0, 0))
comparison.alpha_composite(right, (880, 0))
save(comparison, "source_vs_layers_4x.png")

assert ImageChops.difference(grid, assembled).getbbox() is None, "layers do not reconstruct the study"
assert front.size == trays.size == inside.size == glass.size == (SIZE, SIZE)
assert not any(0 < a < 255 for a in front.getchannel("A").tobytes())
assert not any(0 < a < 255 for a in trays.getchannel("A").tobytes())
assert not any(0 < a < 255 for a in inside.getchannel("A").tobytes())
print("Study layer audit: exact 220-grid reconstruction; hard alpha; 220x220 registration; no game files changed")
