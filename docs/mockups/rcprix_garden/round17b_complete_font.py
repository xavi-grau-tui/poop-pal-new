"""Complete the approved RC Prix font without rewriting its approved samples."""
from __future__ import annotations

import importlib.util
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[3]
FONT_DIR = ROOT / "textures/minigames/rcprix/font"
SOURCE = Path(__file__).with_name("round17b_make_font_samples.py")

spec = importlib.util.spec_from_file_location("font_samples", SOURCE)
samples = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(samples)

# Widths include the 1 px outline, 2 px shadow, and the face's racing slant.
GLYPHS = {
    "B": ("B", 19), "C": ("C", 20), "D": ("D", 20), "E": ("E", 17),
    "F": ("F", 17), "H": ("H", 20), "I": ("I", 11), "J": ("J", 17),
    "K": ("K", 19), "M": ("M", 23), "N": ("N", 20), "Q": ("Q", 20),
    "R": ("R", 19), "S": ("S", 18), "T": ("T", 18), "U": ("U", 20),
    "V": ("V", 19), "W": ("W", 24), "X": ("X", 19), "Y": ("Y", 19),
    "Z": ("Z", 18),
    "0": ("0", 19), "1": ("1", 15), "3": ("3", 18), "4": ("4", 19),
    "5": ("5", 18), "6": ("6", 19), "7": ("7", 18), "8": ("8", 19),
    "9": ("9", 19),
    "quest": ("?", 18),
}
SYMBOLS = {
    "dot": (".", 8, 5, 17),
    "comma": (",", 9, 7, 15),
    "colon": (":", 8, 13, 4),
    "slash": ("/", 13, 20, 2),
    "dash": ("-", 12, 5, 9),
    "apos": ("'", 8, 8, 1),
}


def render_custom(char: str, width: int, face_h: int, top: int) -> Image.Image:
    """Keep punctuation proportional, but use the same outline, shadow and face."""
    font = ImageFont.truetype(samples.FONT_PATH, 120)
    probe = Image.new("L", (220, 160), 0)
    ImageDraw.Draw(probe).text((12, -2), char, font=font, fill=255)
    box = probe.getbbox()
    assert box
    raw = probe.crop(box)
    body_w = width - 5
    body = raw.resize((body_w, face_h), Image.Resampling.NEAREST)
    body = body.point(lambda a: 255 if a >= 112 else 0)

    mask = Image.new("L", (width, 24), 0)
    px, py = mask.load(), body.load()
    for y in range(face_h):
        shift = round((face_h - 1 - y) * 3 / max(1, face_h - 1))
        for x in range(body_w):
            if py[x, y]:
                px[1 + x + shift, top + y] = 255

    outline = mask.filter(ImageFilter.MaxFilter(3))
    result = Image.new("RGBA", (width, 24), (0, 0, 0, 0))
    shadow_mask = Image.new("L", (width, 24), 0)
    shadow_mask.paste(mask.crop((0, 0, width - 2, 22)), (2, 2))
    shadow = Image.new("RGBA", (width, 24), samples.SHADOW)
    shadow.putalpha(shadow_mask)
    result.alpha_composite(shadow)
    edge = Image.new("RGBA", (width, 24), samples.INK)
    edge.putalpha(outline)
    result.alpha_composite(edge)

    face = Image.new("RGBA", (width, 24), (0, 0, 0, 0))
    fp, mp = face.load(), mask.load()
    for y in range(24):
        fill = samples.CREAM if y < 7 else samples.GOLD if y < 17 else samples.AMBER
        for x in range(width):
            if mp[x, y]:
                fp[x, y] = fill
    result.alpha_composite(face)
    for y in range(max(0, top + 1), min(24, top + 3)):
        xs = [x for x in range(width) if mask.getpixel((x, y))]
        for x in xs[:min(3, len(xs))]:
            result.putpixel((x, y), (255, 255, 237, 255))
    return result


def main() -> None:
    FONT_DIR.mkdir(parents=True, exist_ok=True)
    # Generate only missing glyphs: the seven game-approved samples stay byte-for-byte intact.
    for name, (char, width) in GLYPHS.items():
        path = FONT_DIR / f"{name}.png"
        if path.exists():
            continue
        if name == "quest" or char.isalnum():
            image = samples.draw_glyph(char, width)
        else:
            raise ValueError(f"Unexpected glyph: {name}")
        image.save(path)

    for name, (symbol, width, face_h, top) in SYMBOLS.items():
        path = FONT_DIR / f"{name}.png"
        if not path.exists():
            render_custom(symbol, width, face_h, top).save(path)

    expected = set(GLYPHS) | set(SYMBOLS) | {"L", "A", "P", "2", "G", "O", "excl"}
    for name in sorted(expected):
        image = Image.open(FONT_DIR / f"{name}.png").convert("RGBA")
        assert image.height == 24, (name, image.size)
        assert set(image.getchannel("A").get_flattened_data()) <= {0, 255}, f"soft alpha: {name}"
    print(f"Completed {len(expected)} glyphs in {FONT_DIR}")


if __name__ == "__main__":
    main()
