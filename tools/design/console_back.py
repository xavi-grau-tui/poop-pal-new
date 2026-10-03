"""Paints the back of the Poop Pal console (same 1080x1920 size as the front).

    <python with Pillow + numpy> tools/design/console_back.py [preview.png]

Writes textures/console/back.png (the shell: carved Kobaya Tech logo, ID sticker,
4 corner screws, empty button-cell bay) and textures/console/back_lid.png (the battery
lid with its single screw, drawn separately so it can be animated off later).

Two looks, like the front: the plastic shell, screws and seams are smooth (painted at
2x and LANCZOS-downscaled, as the front frame), while everything printed or carved on
it (logo, sticker, moulded text, lid markings, the cells) is pixel art drawn on a
coarse grid and NEAREST-upscaled, matching the front's pixel buttons and logo."""
import math
import random
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "textures" / "console"
LOGO = ROOT / "textures" / "boot" / "kobaya_logo.png"
PIXELLARI = str(ROOT / "fonts" / "Pixellari.ttf")
PIXCHICAGO = str(ROOT / "fonts" / "pixChicago.ttf")

K = 2                      # supersample factor for the smooth plastic
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

# Battery lid rectangle (final px, multiples of 4 so the pixel markings sit on the grid)
LID = (336, 1316, 744, 1680)

random.seed(721)


# ---------------------------------------------------------------- 3x5 pixel font
# for print too small for the project's pixel fonts (sticker fine print, moulding)

GLYPHS = {k: v.replace(" ", "") for k, v in {
    "A": ".#. #.# ### #.# #.#", "B": "##. #.# ##. #.# ##.", "C": ".## #.. #.. #.. .##",
    "D": "##. #.# #.# #.# ##.", "E": "### #.. ##. #.. ###", "F": "### #.. ##. #.. #..",
    "G": ".## #.. #.# #.# .##", "H": "#.# #.# ### #.# #.#", "I": "### .#. .#. .#. ###",
    "J": "..# ..# ..# #.# .#.", "K": "#.# #.# ##. #.# #.#", "L": "#.. #.. #.. #.. ###",
    "M": "#.# ### ### #.# #.#", "N": "##. #.# #.# #.# #.#", "O": ".#. #.# #.# #.# .#.",
    "P": "##. #.# ##. #.. #..", "Q": ".#. #.# #.# ##. .##", "R": "##. #.# ##. #.# #.#",
    "S": ".## #.. .#. ..# ##.", "T": "### .#. .#. .#. .#.", "U": "#.# #.# #.# #.# ###",
    "V": "#.# #.# #.# #.# .#.", "W": "#.# #.# ### ### #.#", "X": "#.# #.# .#. #.# #.#",
    "Y": "#.# #.# .#. .#. .#.", "Z": "### ..# .#. #.. ###",
    "0": "### #.# #.# #.# ###", "1": ".#. ##. .#. .#. ###", "2": "##. ..# .#. #.. ###",
    "3": "##. ..# .#. ..# ##.", "4": "#.# #.# ### ..# ..#", "5": "### #.. ##. ..# ##.",
    "6": ".## #.. ### #.# ###", "7": "### ..# .#. .#. .#.", "8": "### #.# ### #.# ###",
    "9": "### #.# ### ..# ##.",
    ".": "... ... ... ... .#.", ",": "... ... ... .#. #..", ":": "... .#. ... .#. ...",
    "-": "... ... ### ... ...", "/": "..# ..# .#. #.. #..", "(": ".#. #.. #.. #.. .#.",
    ")": ".#. ..# ..# ..# .#.", "'": ".#. .#. ... ... ...", "+": "... .#. ### .#. ...",
    " ": "... ... ... ... ...",
}.items()}
assert all(len(v) == 15 for v in GLYPHS.values())


def tiny_width(text):
    return len(text) * 4 - 1


def tiny(arr, x, y, text, value=True):
    """Stamp 3x5 text into a 2D numpy mask/array at (x, y) top-left."""
    for i, ch in enumerate(text.upper()):
        g = GLYPHS.get(ch, GLYPHS[" "])
        for r in range(5):
            for c in range(3):
                if g[r * 3 + c] == "#":
                    yy, xx = y + r, x + i * 4 + c
                    if 0 <= yy < arr.shape[0] and 0 <= xx < arr.shape[1]:
                        arr[yy, xx] = value


def tiny_wrap(text, max_chars):
    lines, line = [], ""
    for w in text.split():
        trial = (line + " " + w).strip()
        if len(trial) > max_chars:
            lines.append(line)
            line = w
        else:
            line = trial
    return lines + [line]


# ---------------------------------------------------------------- smooth helpers

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
    """Raise the mask out of the plastic (ridges)."""
    paint(img, ImageChops.subtract(shift(mask, depth, depth), mask), dark)
    paint(img, mask, top)
    paint(img, ImageChops.subtract(mask, shift(mask, depth * 0.6, depth * 0.6)), light, 0.9)


# ---------------------------------------------------------------- pixel helpers

class Pix:
    """A low-res RGBA layer covering the whole back at P final px per pixel."""

    def __init__(self, p):
        self.p = p
        self.w, self.h = W // p, H // p
        self.a = np.zeros((self.h, self.w, 4), np.uint8)

    def mask(self):
        return np.zeros((self.h, self.w), bool)

    def set(self, m, color):
        self.a[m] = color + (255,)

    def carve(self, m, floor=SHADE, dark=SHADE_DARK, light=HILITE):
        """1-pixel-deep carving, lit from the top-left: the cells right under the
        cut's top/left edge are shadow, the lip just past its bottom/right catches light."""
        ul = np.zeros_like(m)
        ul[1:, 1:] = m[:-1, :-1]
        self.set(m, floor)
        self.set(m & ~ul, dark)
        self.set(~m & ul, light)

    def image(self):
        return Image.fromarray(self.a, "RGBA").resize((self.w * self.p, self.h * self.p), Image.NEAREST)


def draw_mask(pix, fn):
    """Run fn(ImageDraw) on a 1-bit image the size of the layer, return a bool mask."""
    im = Image.new("1", (pix.w, pix.h), 0)
    d = ImageDraw.Draw(im)
    d.fontmode = "1"
    fn(d)
    return np.array(im, bool)


# ---------------------------------------------------------------- shell (smooth)

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


def grip(img, cy):
    """Row of raised pill ridges between the sticker and the battery bay."""
    m = mask_new()
    d = ImageDraw.Draw(m)
    for i in range(5):
        y = cy - 48 + i * 24
        d.rounded_rectangle(s(330, y, 750, y + 10), radius=5 * K, fill=255)
    emboss(img, m, depth=3)


def bay(img):
    """The cavity under the lid (the cells themselves are pixel art, see cells())."""
    x0, y0, x1, y1 = LID
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(s(x0 - 4, y0 - 4, x1 + 4, y1 + 4), radius=22 * K, fill=OUTLINE)
    d.rounded_rectangle(s(x0 + 6, y0 + 6, x1 - 6, y1 - 6), radius=16 * K, fill=(92, 70, 56))


# ---------------------------------------------------------------- pixel art

COIN_CENTRES = ((116, LID[1] // 4 + 41), (154, LID[1] // 4 + 41))   # P=4 grid, the two LR44 cells
COIN_R = 15


def kobaya_logo(pix, cx, cy, width):
    """The boot-screen rabbit + wordmark, carved on the pixel grid."""
    logo = Image.open(LOGO).convert("RGBA")
    w = int(width / pix.p)
    h = int(logo.height * w / logo.width)
    a = np.array(logo.getchannel("A").resize((w, h), Image.BOX)) > 40
    m = pix.mask()
    x, y = int(cx / pix.p - w / 2), int(cy / pix.p - h / 2)
    m[y:y + h, x:x + w] = a
    pix.carve(m, floor=INSET)


def sticker(pix, x, y):
    """Silver ID plate, like the photo's, at P=3."""
    sw, sh = 286, 150
    ink = (34, 32, 34)
    soft = (66, 64, 68)
    img = Image.new("RGBA", (sw + 1, sh + 1), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.fontmode = "1"
    # hard drop shadow, then the plate in four brushed bands
    d.rounded_rectangle((1, 1, sw, sh), radius=4, fill=SHADE_DARK)
    d.rounded_rectangle((0, 0, sw - 1, sh - 1), radius=4, fill=(150, 150, 154))
    tones = ((226, 227, 231), (216, 217, 221), (206, 207, 211), (197, 198, 202))
    band = (sh - 2) / len(tones)
    for i, t in enumerate(tones):
        d.rectangle((1, 1 + int(i * band), sw - 2, int((i + 1) * band)), fill=t)
    rng = random.Random(4)
    for _ in range(14):   # brushed streaks
        yy = rng.randrange(3, sh - 3)
        x0 = rng.randrange(2, sw // 2)
        base = img.getpixel((x0, yy))[0]
        c = base + rng.choice((-6, 6))
        d.line((x0, yy, x0 + rng.randrange(30, 120), yy), fill=(c, c + 1, c + 4))
    d.line((2, 1, sw - 3, 1), fill=(240, 240, 244))
    d.line((1, 2, 1, sh - 3), fill=(236, 236, 240))
    for cx_, cy_ in ((0, 0), (sw - 1, 0), (0, sh - 1), (sw - 1, sh - 1)):   # crisp corners
        d.point((cx_, cy_), fill=(0, 0, 0, 0))

    bold = ImageFont.truetype(PIXCHICAGO, 8)
    big = ImageFont.truetype(PIXELLARI, 16)

    # row 1: brand pill + model number
    tw = d.textlength("Kobaya Tech", font=bold)
    d.rounded_rectangle((7, 6, 7 + tw + 11, 20), radius=6, outline=ink)
    d.text((13, 13), "Kobaya Tech", font=bold, fill=ink, anchor="lm")
    d.text((sw - 7, 13), "MODEL NO. KBT-0721", font=big, fill=ink, anchor="rm")
    # rows 2-3
    d.text((7, 30), "© 2025-2026 Kobaya Tech", font=bold, fill=ink, anchor="lm")
    d.text((sw - 7, 30), "POOP PAL", font=bold, fill=ink, anchor="rm")
    d.text((7, 42), "RATING: DC3V 0.1W", font=bold, fill=ink, anchor="lm")
    d.text((sw - 7, 42), "BATTERY: LR44 x2", font=bold, fill=ink, anchor="rm")

    # fine print
    fine = np.zeros((sh + 1, sw + 1), bool)
    paras = [
        "THIS DEVICE COMPLIES WITH PART 15 OF THE PAL HYGIENE RULES. OPERATION IS SUBJECT TO THE "
        "FOLLOWING TWO CONDITIONS: (1) THIS DEVICE MAY NOT CAUSE HARMFUL ODOURS, AND (2) THIS DEVICE "
        "MUST ACCEPT ANY SNACK RECEIVED, INCLUDING SNACKS THAT MAY CAUSE UNDESIRED OPERATION.",
        "THIS CLASS P DIGITAL COMPANION MEETS ALL REQUIREMENTS OF THE INTERSTELLAR "
        "DIGESTION-CAUSING EQUIPMENT REGULATIONS.",
        "CET APPAREIL NUMERIQUE DE LA CLASSE P RESPECTE TOUTES LES EXIGENCES DU REGLEMENT SUR "
        "LE MATERIEL DIGESTIF DU CANADA.",
    ]
    yy = 53
    for p in paras:
        for line in tiny_wrap(p, (sw - 14) // 4):
            tiny(fine, 7, yy, line)
            yy += 7
        yy += 2

    # bottom row: barcode + serial, origin code, made in, approval box
    rng = random.Random(2026)
    bx = 7
    while bx < 92:
        bw = rng.choice((1, 1, 2, 3))
        d.rectangle((bx, sh - 25, bx + bw - 1, sh - 15), fill=ink)
        bx += bw + rng.choice((1, 1, 2))
    tiny(fine, 7, sh - 12, "SER. NO. KB0721826")
    tiny(fine, 104, sh - 12, "C/KBT-JPN")
    d.text((sw - 36, sh - 17), "MADE IN JAPAN", font=bold, fill=ink, anchor="rm")
    d.rectangle((sw - 30, sh - 27, sw - 8, sh - 8), outline=ink)
    d.rectangle((sw - 28, sh - 25, sw - 10, sh - 10), outline=ink)
    tiny(fine, sw - 22, sh - 19, "KT")

    a = np.array(img)
    a[fine] = soft + (255,)
    a[fine & (np.arange(sw + 1)[None, :] >= sw - 30)] = ink + (255,)
    region = pix.a[y:y + sh + 1, x:x + sw + 1]
    keep = a[..., 3] > 0
    region[keep] = a[keep]


def molded_text(pix):
    m = pix.mask()
    for row, text in ((449, "(C) 2026 KOBAYA TECH CO., LTD.  MADE IN JAPAN"),
                      (457, "KBT-0721  CONTAINS SMALL POOPS. NOT FOR AGES 0-3")):
        tiny(m, (pix.w - tiny_width(text)) // 2, row, text)
    pix.carve(m)


def lid_markings(pix):
    """Coin-cell diagram, rating, finger ridges and OPEN arrow on the lid (P=4)."""
    x0, y0, x1, y1 = (v // pix.p for v in LID)
    cx = (x0 + x1) // 2

    def draw(d):
        for ccx, ccy in COIN_CENTRES:
            d.ellipse((ccx - COIN_R, ccy - COIN_R, ccx + COIN_R, ccy + COIN_R), outline=1)
        for i in range(4):
            yy = y1 - 18 + i * 3
            d.line((cx - 18 + i * 3, yy, cx + 18 - i * 3, yy), fill=1)
        d.polygon(((x1 - 19, y1 - 12), (x1 - 9, y1 - 12), (x1 - 14, y1 - 7)), fill=1)

    m = draw_mask(pix, draw)
    for ccx, ccy in COIN_CENTRES:
        tiny(m, ccx - 1, ccy - 2, "+")
    label = "LR44 X2  1.5V"
    tiny(m, cx - tiny_width(label) // 2, y1 - 28, label)
    tiny(m, x1 - 21, y1 - 19, "OPEN")
    pix.carve(m)


def cells(pix):
    """Two LR44 button cells sitting in the bay."""
    def draw(d):
        for ccx, ccy in COIN_CENTRES:
            d.ellipse((ccx - COIN_R, ccy - COIN_R, ccx + COIN_R, ccy + COIN_R), fill=1)
    outer = draw_mask(pix, draw)

    def draw_in(d):
        for ccx, ccy in COIN_CENTRES:
            r = COIN_R - 1
            d.ellipse((ccx - r, ccy - r, ccx + r, ccy + r), fill=1)
    face = draw_mask(pix, draw_in)

    def draw_ring(d):
        for ccx, ccy in COIN_CENTRES:
            r = COIN_R - 4
            d.ellipse((ccx - r, ccy - r, ccx + r, ccy + r), outline=1)
    ring = draw_mask(pix, draw_ring)

    pix.set(outer, (40, 40, 46))
    pix.set(face, (176, 178, 186))
    # brighter top-left half, darker bottom-right half
    yy, xx = np.mgrid[0:pix.h, 0:pix.w]
    for ccx, ccy in COIN_CENTRES:
        own = face & (abs(xx - ccx) <= COIN_R) & (abs(yy - ccy) <= COIN_R)
        upper = own & ((xx - ccx) + (yy - ccy) < -4)
        lower = own & ((xx - ccx) + (yy - ccy) > 6)
        pix.set(upper, (214, 216, 222))
        pix.set(lower, (140, 142, 152))
    pix.set(ring, (120, 122, 132))
    plus = pix.mask()
    for ccx, ccy in COIN_CENTRES:
        tiny(plus, ccx - 1, ccy - 2, "+")
    pix.set(plus, (70, 72, 82))


# ---------------------------------------------------------------- lid (smooth plate)

def lid_plate():
    x0, y0, x1, y1 = LID
    img = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # seam: dark gap, then the lid plate slightly raised
    d.rounded_rectangle(s(x0 - 4, y0 - 4, x1 + 4, y1 + 4), radius=22 * K, fill=OUTLINE)
    d.rounded_rectangle(s(x0, y0, x1, y1), radius=18 * K, fill=BODY)
    d.rounded_rectangle(s(x0, y0, x1, y0 + 4), radius=2 * K, fill=HILITE)
    d.rounded_rectangle(s(x0 + 2, y1 - 6, x1 - 2, y1), radius=3 * K, fill=SHADE)
    d.rectangle(s(x1 - 6, y0 + 12, x1, y1 - 12), fill=SHADE)
    screw(img, (x0 + x1) / 2, y0 + 50, r=15, angle=33)
    return img


# ---------------------------------------------------------------- main

def down(img):
    return img.resize((W, H), Image.LANCZOS)


def main():
    hi = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    shell(hi)
    grip(hi, 1075)
    bay(hi)
    for (x, y) in ((48, 46), (1031, 48), (48, 1871), (1031, 1871)):
        screw(hi, x, y)
    back = down(hi)

    p4 = Pix(4)
    kobaya_logo(p4, W / 2, 205, 560)
    molded_text(p4)
    cells(p4)
    back.alpha_composite(p4.image())
    p3 = Pix(3)
    sticker(p3, 37, 127)
    back.alpha_composite(p3.image())

    lid = down(lid_plate())
    marks = Pix(4)
    lid_markings(marks)
    lid.alpha_composite(marks.image())

    back.save(OUT_DIR / "back.png")
    lid.save(OUT_DIR / "back_lid.png")
    if len(sys.argv) > 1:
        preview = back.copy()
        preview.alpha_composite(lid)
        preview.save(sys.argv[1])
        open_lid = Path(sys.argv[1]).with_name(Path(sys.argv[1]).stem + "_open.png")
        back.save(open_lid)
    print("wrote back.png + back_lid.png")


if __name__ == "__main__":
    main()
