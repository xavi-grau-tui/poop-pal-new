"""Build the crisp, slanted RC Prix racing alphabet on its 24 px grid."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONT_DIR = ROOT / "textures/minigames/rcprix/font"
PREVIEW = ROOT / "docs/mockups/rcprix_garden/round23_font_before_after_4x.png"
FONT_PATH = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

INK = (40, 30, 40, 255)          # #281E28: outline and extrusion
CREAM = (255, 241, 193, 255)   # 2 px top shine
GOLD = (245, 185, 62, 255)
AMBER = (208, 117, 34, 255)
PALETTE = {INK, CREAM, GOLD, AMBER}
CAP_H = 16
CAP_Y = 3
SHEAR = 4                    # exactly one pixel every four rows
OUTLINE = 2
DROP = 2

EXPECTED = {*"0123456789", *"ABCDEFGHIJKLMNOPQRSTUVWXYZ", "apos", "colon", "comma", "dash", "dot", "excl", "quest", "slash"}
PUNCT = {"!": "excl", "?": "quest", ".": "dot", ",": "comma", ":": "colon", "/": "slash", "-": "dash", "'": "apos"}


def source_mask(char: str, width: int | None = None) -> Image.Image:
    """Rasterize Impact at large size, then snap to a clean 16 px cap grid."""
    font = ImageFont.truetype(FONT_PATH, 192)
    probe = Image.new("L", (320, 240), 0)
    draw = ImageDraw.Draw(probe)
    draw.text((12, -8), char, font=font, fill=255, stroke_width=0)
    box = probe.getbbox()
    if not box:
        raise ValueError(f"No glyph for {char!r}")
    raw = probe.crop(box)
    natural_w = max(5, round(raw.width * CAP_H / raw.height * 1.08))
    target_w = width or natural_w
    snapped = raw.resize((target_w, CAP_H), Image.Resampling.NEAREST)
    return snapped.point(lambda p: 255 if p >= 128 else 0)


def punctuation_mask(name: str) -> tuple[Image.Image, int]:
    """Draw punctuation with the same bold, stepped strokes as the caps."""
    masks: dict[str, tuple[int, int, list[tuple[int, int, int, int]]]] = {
        "excl": (5, 16, [(1, 0, 3, 10), (1, 13, 3, 15)]),
        "quest": (10, 16, [(1, 0, 7, 2), (6, 2, 8, 5), (4, 5, 6, 8), (4, 11, 6, 11), (4, 14, 6, 15)]),
        "dot": (4, 4, [(1, 1, 2, 2)]),
        "comma": (6, 7, [(2, 1, 3, 3), (1, 4, 2, 6)]),
        "colon": (4, 12, [(1, 1, 2, 3), (1, 8, 2, 10)]),
        "dash": (10, 4, [(1, 1, 8, 2)]),
        "apos": (4, 6, [(1, 0, 2, 4)]),
        "slash": (9, 16, [(6, 0, 8, 2), (5, 3, 7, 5), (4, 6, 6, 8), (2, 9, 4, 11), (1, 12, 3, 15)]),
    }
    width, height, rects = masks[name]
    mask = Image.new("L", (width, height), 0)
    d = ImageDraw.Draw(mask)
    for rect in rects:
        d.rectangle(rect, fill=255)
    return mask, height


def row_mask(rows: tuple[str, ...]) -> Image.Image:
    width = len(rows[0])
    mask = Image.new("L", (width, len(rows)), 0)
    px = mask.load()
    for y, row in enumerate(rows):
        for x, value in enumerate(row):
            if value == "#":
                px[x, y] = 255
    return mask


def body_for(name: str) -> tuple[Image.Image, int]:
    if name in PUNCT.values():
        return punctuation_mask(name)
    if name == "I":
        # Racing I with broad top and foot serifs.
        mask = Image.new("L", (7, CAP_H), 0)
        d = ImageDraw.Draw(mask)
        d.rectangle((0, 0, 6, 2), fill=255)
        d.rectangle((2, 3, 4, 12), fill=255)
        d.rectangle((0, 13, 6, 15), fill=255)
        return mask, CAP_H
    if name == "L":
        mask = source_mask("L", 11)
        ImageDraw.Draw(mask).rectangle((0, CAP_H - 3, 10, CAP_H - 1), fill=255)
        return mask, CAP_H
    if name == "A":
        # A clean 3×4 counter survives the 4× in-game scale.
        return row_mask((
            "      ###      ", "     #####     ", "    #######    ",
            "   ###   ###   ", "   ###   ###   ", "   ###   ###   ", "   ###   ###   ",
            "  ###     ###  ", "  ###     ###  ", " ###       ### ",
            " ############# ", " ############# ", " ############# ",
            "###         ###", "###         ###", "###         ###",
        )), CAP_H
    if name == "0":
        # Slightly narrower and more squared than O, still with a roomy hole.
        return source_mask("0", 11), CAP_H
    if name == "B":
        # Four-row counters stay open at the game's 4× display scale.
        return row_mask((
            "  ###########  ", " ############# ", "###############",
            "####      #### ", "####      #### ", "####      #### ", "####      #### ",
            "############## ", "############## ", "############## ",
            "####      #### ", "####      #### ", "####      #### ", "####      #### ",
            "###############", " ############# ",
        )), CAP_H
    if name == "8":
        return row_mask((
            "  #########  ", "  #########  ", "#############",
            "#####   #####", "#####   #####", "#####   #####", "#####   #####",
            "#############", "#############", "#############",
            "#####   #####", "#####   #####", "#####   #####", "#####   #####",
            "  #########  ", "  #########  ",
        )), CAP_H
    if name.isdigit():
        return source_mask(name), CAP_H
    if name == "O":
        return source_mask("O", 15), CAP_H
    return source_mask(name), CAP_H


def render_glyph(name: str, digit_width: int | None = None) -> Image.Image:
    body, body_h = body_for(name)
    bw, _ = body.size
    # Caps sit on a common baseline. Punctuation is positioned by its visual role.
    if name in ("dot", "comma"):
        y = 16 if name == "dot" else 14
    elif name in ("colon", "dash", "apos"):
        y = 6 if name == "colon" else (9 if name == "dash" else 3)
    else:
        y = CAP_Y if body_h == CAP_H else CAP_Y + CAP_H - body_h

    # Shape width includes the exact 4 px slant plus outline and drop clearance.
    slanted = Image.new("L", (bw + SHEAR, 24), 0)
    bp = body.load()
    sp = slanted.load()
    for row in range(body_h):
        shift = (CAP_H - 1 - row) // 4 if body_h == CAP_H else 0
        for x in range(bw):
            if bp[x, row]:
                sp[x + shift, y + row] = 255

    face_bbox = slanted.getbbox()
    if not face_bbox:
        return Image.new("RGBA", (8, 24), (0, 0, 0, 0))
    # Add room for outline on left/top and the 2 px down-right extrusion.
    body_x = OUTLINE
    base = Image.new("L", (slanted.width + OUTLINE * 2 + DROP, 24), 0)
    base.paste(slanted, (body_x, 0))
    outline = base.filter(ImageFilter.MaxFilter(OUTLINE * 2 + 1))
    shifted = Image.new("L", base.size, 0)
    shifted.paste(outline.crop((0, 0, base.width - DROP, 24 - DROP)), (DROP, DROP))

    rgba = Image.new("RGBA", base.size, (0, 0, 0, 0))
    dark = Image.new("RGBA", base.size, INK)
    dark.putalpha(shifted)
    rgba.alpha_composite(dark)
    edge = Image.new("RGBA", base.size, INK)
    edge.putalpha(outline)
    rgba.alpha_composite(edge)

    # The lit edge and lower band are clipped to the letter mask; the face uses
    # only three solid colours and no subpixel or dithered marks.
    face = Image.new("RGBA", base.size, (0, 0, 0, 0))
    fp = face.load()
    bpix = base.load()
    ys = [yy for yy in range(24) for xx in range(base.width) if bpix[xx, yy]]
    top, bottom = min(ys), max(ys)
    for yy in range(top, bottom + 1):
        color = CREAM if yy < top + 2 else AMBER if yy >= bottom - 3 else GOLD
        for xx in range(base.width):
            if bpix[xx, yy]:
                fp[xx, yy] = color
    rgba.alpha_composite(face)

    # Crop to the full visible glyph; pad digits equally so timer columns do not jump.
    bbox = rgba.getbbox()
    assert bbox
    rgba = rgba.crop((bbox[0], 0, bbox[2], 24))
    if digit_width is not None:
        if rgba.width < digit_width:
            padded = Image.new("RGBA", (digit_width, 24), (0, 0, 0, 0))
            padded.alpha_composite(rgba, ((digit_width - rgba.width) // 2, 0))
            rgba = padded
        elif rgba.width > digit_width:
            digit_width = rgba.width
    return rgba


def compose_text(text: str, glyphs: dict[str, Image.Image], scale: int = 4) -> Image.Image:
    items: list[Image.Image | None] = []
    for char in text:
        items.append(None if char == " " else glyphs[PUNCT.get(char, char)])
    gap, space = 2, 10
    width = sum(space if item is None else item.width for item in items) + gap * max(0, len(items) - 1)
    line = Image.new("RGBA", (width, 24), (0, 0, 0, 0))
    x = 0
    for item in items:
        if item is not None:
            line.alpha_composite(item, (x, 0))
            x += item.width
        else:
            x += space
        x += gap
    return line.resize((line.width * scale, line.height * scale), Image.Resampling.NEAREST)


def make_preview(glyphs: dict[str, Image.Image]) -> None:
    examples = ("LAP 2", "GO!", "FINAL LAP", "FINISH!")
    w, row_h = 1480, 200
    board = Image.new("RGB", (w, row_h * len(examples)), (48, 75, 57))
    d = ImageDraw.Draw(board)
    for i, phrase in enumerate(examples):
        y = i * row_h
        d.rectangle((0, y, w, y + row_h - 1), fill=(57, 89, 63) if i % 2 == 0 else (48, 75, 57))
        d.text((20, y + 8), phrase, fill=(218, 211, 181))
        sample = compose_text(phrase, glyphs, scale=4)
        board.paste(sample, ((w - sample.width) // 2, y + 46), sample)
    board.save(PREVIEW)


def main() -> None:
    FONT_DIR.mkdir(parents=True, exist_ok=True)
    # Render once to determine a fixed digit cell width.
    digit_width = max(render_glyph(d).width for d in "0123456789")
    glyphs = {name: render_glyph(name, digit_width if name.isdigit() else None) for name in sorted(EXPECTED)}
    make_preview(glyphs)
    for name, image in glyphs.items():
        image.save(FONT_DIR / f"{name}.png")

    assert {p.stem for p in FONT_DIR.glob("*.png")} == EXPECTED
    assert len({glyphs[d].width for d in "0123456789"}) == 1
    for name, image in glyphs.items():
        arr = np.asarray(image)
        assert image.height == 24 and set(np.unique(arr[..., 3])) <= {0, 255}, name
        assert {tuple(c) for c in arr[arr[..., 3] > 0]} <= PALETTE, name
    print(f"Rebuilt {len(glyphs)} glyphs; digit width {digit_width}px; preview: {PREVIEW}")


if __name__ == "__main__":
    main()
