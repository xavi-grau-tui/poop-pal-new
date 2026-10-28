"""Build the first RC Prix racing-font glyphs on a crisp 24 px grid."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[3]
FONT_DIR = ROOT / "textures/minigames/rcprix/font"
PREVIEW_DIR = ROOT / "docs/mockups/rcprix_garden/round17b_font_sample"
INK = (40, 30, 40, 255)          # #281E28
SHADOW = (70, 39, 47, 255)
CREAM = (255, 244, 203, 255)
GOLD = (255, 213, 78, 255)
AMBER = (238, 157, 48, 255)
FONT_PATH = "/System/Library/Fonts/Supplemental/Impact.ttf"

# Final image widths include the outline and the slight rightward slant.
WIDTHS = {"L": 17, "A": 19, "P": 18, "2": 18, "G": 20, "O": 20, "excl": 9}
GLYPHS = {"L": "L", "A": "A", "P": "P", "2": "2", "G": "G", "O": "O", "excl": "!"}


def make_mask(char: str, target_width: int) -> Image.Image:
    """Rasterize a heavy italic face then snap it to 1-bit pixels at native size."""
    font = ImageFont.truetype(FONT_PATH, 120)
    probe = Image.new("L", (220, 160), 0)
    ImageDraw.Draw(probe).text((12, -2), char, font=font, fill=255, stroke_width=0)
    box = probe.getbbox()
    if not box:
        raise ValueError(f"empty glyph: {char}")
    raw = probe.crop(box)
    body_w = target_width - 5  # 3 px shear and 1 px outline on each side
    body = raw.resize((body_w, 22), Image.Resampling.NEAREST)
    # Strip any gray antialiasing left by the source font before it reaches PNG.
    body = body.point(lambda a: 255 if a >= 112 else 0)
    slanted = Image.new("L", (body_w + 3, 22), 0)
    src = body.load()
    dst = slanted.load()
    for y in range(22):
        shift = round((21 - y) * 3 / 21)
        for x in range(body_w):
            if src[x, y]:
                dst[x + shift, y] = 255
    return slanted


def draw_glyph(char: str, target_width: int) -> Image.Image:
    mask = make_mask(char, target_width)
    # The sprite's cap height is exactly 24 px, with one pixel of outline above
    # and below the 22 px letter face.
    outline_seed = Image.new("L", (target_width, 24), 0)
    outline_seed.paste(mask, (1, 1))
    outline = outline_seed.filter(ImageFilter.MaxFilter(3))
    if outline.size != (target_width, 24):
        raise AssertionError((char, outline.size, target_width))
    result = Image.new("RGBA", outline.size, (0, 0, 0, 0))

    shadow = Image.new("RGBA", outline.size, SHADOW)
    shadow.putalpha(Image.new("L", outline.size, 0))
    shadow_mask = Image.new("L", outline.size, 0)
    shadow_mask.paste(mask, (2, 2))
    shadow.putalpha(shadow_mask)
    result.alpha_composite(shadow)

    edge = Image.new("RGBA", outline.size, INK)
    edge.putalpha(outline)
    result.alpha_composite(edge)

    face_mask = Image.new("L", outline.size, 0)
    face_mask.paste(mask, (1, 1))
    face = Image.new("RGBA", outline.size, (0, 0, 0, 0))
    fp = face.load()
    mp = face_mask.load()
    for y in range(24):
        fill = CREAM if y < 7 else GOLD if y < 17 else AMBER
        for x in range(target_width):
            if mp[x, y]:
                fp[x, y] = fill
    result.alpha_composite(face)

    # A short 1 px shine on the upper-left stroke; it stays inside the face.
    shine = (255, 255, 237, 255)
    for y in (3, 4):
        xs = [x for x in range(target_width) if face_mask.getpixel((x, y))]
        if xs:
            for x in xs[: min(3, len(xs))]:
                result.putpixel((x, y), shine)
    return result


def compose_word(text: str, spacing: int = 2, scale: int = 4) -> Image.Image:
    names = {"!": "excl", " ": " "}
    glyphs = []
    for char in text:
        if char == " ":
            glyphs.append(None)
        else:
            name = names.get(char, char)
            glyphs.append(Image.open(FONT_DIR / f"{name}.png").convert("RGBA"))
    width = 0
    for i, glyph in enumerate(glyphs):
        width += 7 if glyph is None else glyph.width
        if i + 1 < len(glyphs):
            width += spacing
    word = Image.new("RGBA", (width, 24), (0, 0, 0, 0))
    x = 0
    for i, glyph in enumerate(glyphs):
        if glyph is None:
            x += 7 + spacing
            continue
        word.alpha_composite(glyph, (x, 0))
        x += glyph.width + spacing
    return word.resize((word.width * scale, word.height * scale), Image.Resampling.NEAREST)


def build_preview() -> Image.Image:
    w, h = 800, 850
    sheet = Image.new("RGBA", (w, h), (35, 36, 43, 255))
    d = ImageDraw.Draw(sheet)
    # Put the actual game tile under both samples to check contrast on asphalt
    # and lawn, not just on flat swatches.
    root = ROOT / "textures/minigames/rcprix/garden"
    scene = Image.open(root / "grass_a.png").convert("RGBA")
    scene.alpha_composite(Image.open(root / "corner_ne.png").convert("RGBA"))
    lap = compose_word("LAP 2", scale=4)
    go = compose_word("GO!", scale=4)
    compose_word("LAP 2", scale=1).save(PREVIEW_DIR / "lap_2.png")
    compose_word("GO!", scale=1).save(PREVIEW_DIR / "go.png")
    scene.alpha_composite(Image.open(PREVIEW_DIR / "lap_2.png").convert("RGBA"), (70, 40))
    scene.alpha_composite(Image.open(PREVIEW_DIR / "go.png").convert("RGBA"), (14, 143))
    d.rounded_rectangle((38, 26, 762, 750), radius=12, outline=INK, width=4)
    sheet.alpha_composite(scene.resize((720, 720), Image.Resampling.NEAREST), (40, 28))
    # Native-size glyph strip below each phrase, to show widths and 24 px height.
    strip_y = 764
    x = 194
    for name in ("L", "A", "P", "2", "G", "O", "excl"):
        g = Image.open(FONT_DIR / f"{name}.png").convert("RGBA")
        sheet.alpha_composite(g.resize((g.width * 3, g.height * 3), Image.Resampling.NEAREST), (x, strip_y))
        x += g.width * 3 + 8
    return sheet.convert("RGB")


def main() -> None:
    FONT_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    for name, char in GLYPHS.items():
        image = draw_glyph(char, WIDTHS[name])
        image.save(FONT_DIR / f"{name}.png")
    # Compose two native-alpha samples from the actual character files.
    compose_word("LAP 2", scale=1).save(PREVIEW_DIR / "lap_2.png")
    compose_word("GO!", scale=1).save(PREVIEW_DIR / "go.png")
    build_preview().save(PREVIEW_DIR / "round17b_font_preview.png")
    for name, width in WIDTHS.items():
        image = Image.open(FONT_DIR / f"{name}.png").convert("RGBA")
        assert image.size == (width, 24), (name, image.size)
        assert set(image.getchannel("A").get_flattened_data()) <= {0, 255}, f"soft alpha: {name}"
    print(f"Sample glyphs: {FONT_DIR}")
    print(f"Preview: {PREVIEW_DIR / 'round17b_font_preview.png'}")


if __name__ == "__main__":
    main()
