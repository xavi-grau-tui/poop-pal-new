"""Paints the back of the Poop Pal console (same 1080x1920 size as the front).

    <python with Pillow + numpy> tools/design/console_back.py [preview.png]

Writes textures/console/back.png (the shell: carved Kobaya Tech logo, ID sticker,
4 corner screws, empty battery bay) and textures/console/back_lid.png (the battery
lid with its single screw, drawn separately so it can be animated off later).
Painted at 2x and LANCZOS-downscaled to match the soft look of the front art."""
import math
import random
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "textures" / "console"
LOGO = ROOT / "textures" / "boot" / "kobaya_logo.png"

K = 2                      # supersample factor
W, H = 1080, 1920

# Palette sampled from the front of the console
OUTLINE = (72, 49, 37)
EDGE = (116, 96, 82)
BODY = (250, 237, 217)
INSET = (234, 219, 194)
SHADE = (215, 181, 141)
SHADE_DARK = (200, 166, 130)
SCREW_BROWN = (122, 73, 45)
HILITE = (255, 249, 238)

# Battery lid rectangle (final px)
LID = (200, 1170, 880, 1740)

random.seed(721)

FONT_DIR = Path("/System/Library/Fonts/Supplemental")


def font(name, size):
    return ImageFont.truetype(str(FONT_DIR / name), int(size * K))


def cjk_font(size):
    return ImageFont.truetype("/System/Library/Fonts/Hiragino Sans GB.ttc", int(size * K))


def s(*v):
    """Scale final-px coordinates to the supersampled canvas."""
    return [int(round(x * K)) for x in v]


def mask_new():
    return Image.new("L", (W * K, H * K), 0)


def shift(mask, dx, dy):
    return ImageChops.offset(mask, int(dx * K), int(dy * K))


def paint(img, mask, color, alpha=1.0):
    layer = Image.new("RGBA", img.size, color + (255,))
    m = mask if alpha >= 1.0 else mask.point(lambda v: int(v * alpha))
    img.paste(layer, (0, 0), m)


def carve(img, mask, depth=2.0, floor=INSET, dark=SHADE_DARK, light=HILITE):
    """Recess the mask into the plastic, light from the top-left: the upper-left
    inner walls fall in shadow, the lower-right ones catch the light."""
    paint(img, mask, floor)
    paint(img, ImageChops.subtract(mask, shift(mask, depth, depth)), dark)
    paint(img, ImageChops.subtract(mask, shift(mask, -depth * 0.6, -depth * 0.6)), light, 0.8)


def emboss(img, mask, depth=2.0, top=BODY, dark=SHADE, light=HILITE):
    """Raise the mask out of the plastic (molded text / ridges)."""
    paint(img, ImageChops.subtract(shift(mask, depth, depth), mask), dark)
    paint(img, mask, top)
    paint(img, ImageChops.subtract(mask, shift(mask, depth * 0.6, depth * 0.6)), light, 0.9)


def text_mask(text, fnt, cx, cy, anchor="mm", spacing=0):
    m = mask_new()
    d = ImageDraw.Draw(m)
    if spacing:
        # manual letter spacing
        widths = [d.textlength(c, font=fnt) for c in text]
        total = sum(widths) + spacing * K * (len(text) - 1)
        x = cx * K - total / 2 if anchor[0] == "m" else cx * K
        for c, w in zip(text, widths):
            d.text((x, cy * K), c, font=fnt, fill=255, anchor="l" + anchor[1])
            x += w + spacing * K
    else:
        d.text((cx * K, cy * K), text, font=fnt, fill=255, anchor=anchor)
    return m


# ---------------------------------------------------------------- shell

def shell(img):
    d = ImageDraw.Draw(img)
    # dark rim, then a softer edge ring, then the body (mirrored front: the
    # shaded side strip is now on the left)
    d.rounded_rectangle(s(0, 0, W - 1, H - 1), radius=34 * K, fill=OUTLINE)
    d.rounded_rectangle(s(10, 10, W - 11, H - 11), radius=26 * K, fill=EDGE)
    d.rounded_rectangle(s(13, 13, W - 14, H - 14), radius=23 * K, fill=BODY)
    d.rectangle(s(13, 40, 26, H - 40), fill=SHADE_DARK)
    d.rectangle(s(19, 40, 31, H - 40), fill=SHADE)
    # faint grain so the big flat back reads as plastic
    rng = np.random.default_rng(7)
    a = np.asarray(img).astype(np.int16)
    n = rng.normal(0, 1.6, a.shape[:2])[..., None]
    a[..., :3] = np.clip(a[..., :3] + n, 0, 255)
    img.paste(Image.fromarray(a.astype(np.uint8), "RGBA"))


def screw(img, cx, cy, r=13, angle=None):
    d = ImageDraw.Draw(img)
    angle = random.uniform(0, 90) if angle is None else angle
    # recessed boss
    boss = mask_new()
    ImageDraw.Draw(boss).ellipse(s(cx - r - 8, cy - r - 8, cx + r + 8, cy + r + 8), fill=255)
    carve(img, boss, depth=3)
    # head: brown like the front screws, with a soft top-left shine
    d.ellipse(s(cx - r - 2, cy - r - 2, cx + r + 2, cy + r + 2), fill=OUTLINE)
    d.ellipse(s(cx - r, cy - r, cx + r, cy + r), fill=SCREW_BROWN)
    d.ellipse(s(cx - r * 0.75, cy - r * 0.8, cx + r * 0.3, cy + r * 0.2), fill=(150, 98, 64))
    # phillips cross
    for a in (angle, angle + 90):
        dx, dy = math.cos(math.radians(a)) * r * 0.72, math.sin(math.radians(a)) * r * 0.72
        d.line(s(cx - dx, cy - dy, cx + dx, cy + dy), fill=OUTLINE, width=int(3.4 * K))


def kobaya_logo(img, cx, cy, width):
    logo = Image.open(LOGO).convert("RGBA")
    w = int(width * K)
    h = int(logo.height * w / logo.width)
    a = logo.getchannel("A").resize((w, h), Image.LANCZOS).point(lambda v: 255 if v > 90 else 0)
    # thicken the hair-thin line art a little so the carving holds up
    a = a.filter(ImageFilter.MaxFilter(5))
    m = mask_new()
    m.paste(a, (int(cx * K - w / 2), int(cy * K - h / 2)))
    carve(img, m, depth=2.6)


def grip(img, cy):
    """Row of raised pill ridges between the sticker and the battery bay."""
    m = mask_new()
    d = ImageDraw.Draw(m)
    for i in range(5):
        y = cy - 48 + i * 24
        d.rounded_rectangle(s(330, y, 750, y + 10), radius=5 * K, fill=255)
    emboss(img, m, depth=3)


def molded_text(img):
    f = font("Arial Bold.ttf", 21)
    carve(img, text_mask("© 1997 KOBAYA TECH CO., LTD.   MADE IN JAPAN", f, W / 2, 1808, spacing=1.5), depth=1.4, floor=SHADE)
    f2 = font("Arial Bold.ttf", 17)
    carve(img, text_mask("KBT-0721   NOT A TOY FOR CHILDREN UNDER 3 · CONTAINS SMALL POOPS", f2, W / 2, 1842, spacing=1),
          depth=1.2, floor=SHADE)


def battery_bay(img):
    """What sits under the lid: the cavity and two AAA cells."""
    x0, y0, x1, y1 = LID
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(s(x0 - 4, y0 - 4, x1 + 4, y1 + 4), radius=22 * K, fill=OUTLINE)
    d.rounded_rectangle(s(x0 + 6, y0 + 6, x1 - 6, y1 - 6), radius=16 * K, fill=(92, 70, 56))
    for i, (bx, flip) in enumerate(((x0 + 150, False), (x0 + 390, True))):
        top, bot = y0 + 120, y1 - 70
        d.rounded_rectangle(s(bx, top, bx + 140, bot), radius=14 * K, fill=(40, 40, 46))
        d.rounded_rectangle(s(bx + 8, top + 8, bx + 132, bot - 8), radius=10 * K, fill=(70, 72, 82))
        band_y = bot - 90 if not flip else top + 30
        d.rectangle(s(bx + 8, band_y, bx + 132, band_y + 60), fill=(196, 150, 60))
        nub_y = top - 14 if not flip else bot
        d.rounded_rectangle(s(bx + 50, nub_y, bx + 90, nub_y + 14), radius=4 * K, fill=(170, 170, 176))


# ---------------------------------------------------------------- sticker

def sticker():
    sw, sh = 860, 440
    st = Image.new("RGBA", (sw * K, sh * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(st)
    # brushed-silver base: vertical gradient + horizontal streaks
    grad = np.linspace(222, 196, sh * K)[:, None].repeat(sw * K, 1)
    streak = np.random.default_rng(3).normal(0, 5, (sh * K, 1)).repeat(sw * K, 1)
    speck = np.random.default_rng(4).normal(0, 3, (sh * K, sw * K))
    base = np.clip(grad + streak + speck, 0, 255)
    rgb = np.stack([base - 2, base, base + 3], -1).clip(0, 255).astype(np.uint8)
    body = Image.fromarray(rgb, "RGB").convert("RGBA")
    shape = Image.new("L", st.size, 0)
    ImageDraw.Draw(shape).rounded_rectangle((0, 0, sw * K - 1, sh * K - 1), radius=18 * K, fill=255)
    st.paste(body, (0, 0), shape)
    d.rounded_rectangle((0, 0, sw * K - 1, sh * K - 1), radius=18 * K, outline=(150, 150, 152), width=2 * K)
    d.rounded_rectangle((4 * K, 4 * K, sw * K - 5, sh * K - 5), radius=15 * K, outline=(238, 238, 240), width=K)

    ink = (34, 32, 34)
    soft = (60, 58, 60)

    def t(x, y, txt, f, fill=ink, anchor="la"):
        d.text((x * K, y * K), txt, font=f, fill=fill, anchor=anchor)

    # brand pill (top left)
    fb = font("Arial Black.ttf", 26)
    pw = d.textlength("Kobaya Tech", font=fb) / K + 36
    d.rounded_rectangle(s(32, 30, 32 + pw, 76), radius=23 * K, outline=ink, width=int(3.5 * K))
    t(32 + pw / 2, 53, "Kobaya Tech", fb, anchor="mm")

    big = font("Arial Bold.ttf", 34)
    mid = font("Arial Bold.ttf", 25)
    t(sw - 32, 34, "MODEL NO. KBT-0721", big, anchor="ra")
    t(sw - 32, 84, "POOP PAL", mid, anchor="ra")
    pp_w = d.textlength("POOP PAL", font=mid) / K
    t(sw - 44 - pp_w, 81, "便友", cjk_font(26), anchor="ra")

    t(32, 96, "© 1996-1997 Kobaya Tech", mid)
    t(32, 128, "RATING: DC3V 0.3W", mid)
    t(sw - 32, 128, "BATTERY: LR03(AAA)x2", mid, anchor="ra")

    small = font("Arial.ttf", 17)
    para = [
        ("This device complies with Part 15 of the Pal Hygiene Rules. Operation is subject to the "
         "following two conditions: (1) this device may not cause harmful odours, and (2) this device "
         "must accept any snack received, including snacks that may cause undesired operation."),
        ("This Class P digital companion meets all requirements of the Interstellar "
         "Digestion-Causing Equipment Regulations."),
        ("Cet appareil numérique de la classe P respecte toutes les exigences du Règlement sur "
         "le matériel digestif du Canada."),
    ]
    y = 178
    for p in para:
        words, line = p.split(), ""
        for w_ in words:
            trial = (line + " " + w_).strip()
            if d.textlength(trial, font=small) / K > sw - 64:
                t(32, y, line, small, fill=soft)
                y += 21
                line = w_
            else:
                line = trial
        t(32, y, line, small, fill=soft)
        y += 29

    # barcode + serial
    bx, by = 32, sh - 92
    x = bx
    rng = random.Random(1997)
    while x < bx + 250:
        bw = rng.choice((1.5, 1.5, 3, 4.5))
        d.rectangle(s(x, by, x + bw - 0.5, by + 40), fill=ink)
        x += bw + rng.choice((1.5, 3, 3))
    t(bx, by + 46, "SER. NO. KB4071298", font("Arial Bold.ttf", 15))
    t(32 + 270, sh - 52, "C/KBT-JPN", font("Arial Bold.ttf", 18))

    t(sw - 112, sh - 40, "MADE IN JAPAN", font("Arial Bold.ttf", 26), anchor="rm")
    # little approval mark: double box with the Kobaya rabbit initials
    d.rounded_rectangle(s(sw - 96, sh - 70, sw - 34, sh - 12), radius=6 * K, outline=ink, width=int(2.5 * K))
    d.rounded_rectangle(s(sw - 89, sh - 63, sw - 41, sh - 19), radius=4 * K, outline=ink, width=int(1.5 * K))
    t(sw - 65, sh - 41, "KT", font("Arial Black.ttf", 18), anchor="mm")
    return st


def place_sticker(img, st, x, y, tilt=-0.6):
    st = st.rotate(tilt, resample=Image.BICUBIC, expand=True)
    shadow = Image.new("RGBA", st.size, OUTLINE + (0,))
    shadow.putalpha(st.getchannel("A").point(lambda v: int(v * 0.35)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(4 * K))
    img.alpha_composite(shadow, (int((x + 3) * K), int((y + 5) * K)))
    img.alpha_composite(st, (int(x * K), int(y * K)))


# ---------------------------------------------------------------- lid

def lid():
    x0, y0, x1, y1 = LID
    pad = 10
    lw, lh = x1 - x0 + pad * 2, y1 - y0 + pad * 2
    img = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # seam: dark gap, then the lid plate slightly raised
    d.rounded_rectangle(s(x0 - 4, y0 - 4, x1 + 4, y1 + 4), radius=22 * K, fill=OUTLINE)
    d.rounded_rectangle(s(x0, y0, x1, y1), radius=18 * K, fill=BODY)
    d.rounded_rectangle(s(x0, y0, x1, y0 + 4), radius=2 * K, fill=HILITE)
    d.rounded_rectangle(s(x0 + 2, y1 - 6, x1 - 2, y1), radius=3 * K, fill=SHADE)
    d.rectangle(s(x1 - 6, y0 + 12, x1, y1 - 12), fill=SHADE)

    # recessed battery diagram
    for bx, flip in ((x0 + 170, False), (x0 + 400, True)):
        top, bot = y0 + 135, y1 - 160
        m = mask_new()
        md = ImageDraw.Draw(m)
        md.rounded_rectangle(s(bx, top, bx + 110, bot), radius=14 * K, fill=255)
        md.rounded_rectangle(s(bx + 6, top + 6, bx + 104, bot - 6), radius=10 * K, fill=0)
        nub_y = top - 14 if not flip else bot
        md.rounded_rectangle(s(bx + 38, nub_y, bx + 72, nub_y + 14), radius=4 * K, fill=255)
        f = font("Arial Black.ttf", 46)
        md.text(((bx + 55) * K, (top + 50 if not flip else bot - 50) * K), "+", font=f, fill=255, anchor="mm")
        md.text(((bx + 55) * K, (bot - 50 if not flip else top + 50) * K), "–", font=f, fill=255, anchor="mm")
        carve(img, m, depth=2)
    f = font("Arial Bold.ttf", 22)
    carve(img, text_mask("LR03 (AAA) × 2   1.5V", f, (x0 + x1) / 2, y1 - 120, spacing=1.5), depth=1.4, floor=SHADE)

    # finger grip ridges + OPEN arrow, near the bottom edge
    m = mask_new()
    md = ImageDraw.Draw(m)
    cx = (x0 + x1) / 2
    for i in range(4):
        yy = y1 - 82 + i * 16
        md.rounded_rectangle(s(cx - 150 + i * 12, yy, cx + 150 - i * 12, yy + 7), radius=3 * K, fill=255)
    carve(img, m, depth=2)
    m = mask_new()
    md = ImageDraw.Draw(m)
    md.polygon(s(x1 - 120, y1 - 70, x1 - 80, y1 - 70, x1 - 100, y1 - 40), fill=255)
    md.text(((x1 - 100) * K, (y1 - 88) * K), "OPEN", font=font("Arial Bold.ttf", 17), fill=255, anchor="mm")
    carve(img, m, depth=1.4, floor=SHADE)

    # the one screw holding it shut
    screw(img, cx, y0 + 58, r=15, angle=33)
    return img


# ---------------------------------------------------------------- main

def down(img):
    return img.resize((W, H), Image.LANCZOS)


def main():
    back = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    shell(back)
    kobaya_logo(back, W / 2, 205, 560)
    place_sticker(back, sticker(), 110, 380)
    grip(back, 990)
    battery_bay(back)
    molded_text(back)
    for (x, y) in ((48, 46), (1031, 48), (48, 1871), (1031, 1871)):
        screw(back, x, y)

    lid_img = lid()
    down(back).save(OUT_DIR / "back.png")
    down(lid_img).save(OUT_DIR / "back_lid.png")
    preview = back.copy()
    preview.alpha_composite(lid_img)
    if len(sys.argv) > 1:
        down(preview).save(sys.argv[1])
    print("wrote back.png + back_lid.png")


if __name__ == "__main__":
    main()
