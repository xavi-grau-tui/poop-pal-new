"""Paints the out-of-the-box pieces (first launch): the screen protector films, their
peel tab, the battery pull strip on the back and the unpowered main screen.

    <python with Pillow + numpy> tools/design/unboxing_art.py

Writes into textures/unboxing/. Sizes match the front at 1080x1920 (screen coords):
the films cover only the screens' glass, leaving the brown frames bare."""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures" / "unboxing"
FONT_BIG = str(ROOT / "fonts" / "Pixellari.ttf")
FONT_BOLD = str(ROOT / "fonts" / "pixChicago.ttf")

# Screen-space rects on the front (x0, y0, x1, y1), exclusive ends
SCREEN = (76, 623, 1002, 1549)          # the big screen itself
SCREEN_FILM = (77, 623, 1003, 1549)     # the screen glass only (inside its brown frame)
LCD_FILM = (101, 85, 526, 270)          # the small LCD's glass only (inside its frame)
FRAME_R = 3                             # the glass corners are nearly square

INK = (236, 238, 242)                   # white print: readable over the dark, unlit screen
P = 3                                   # print pixel size


def film(rect, print_fn=None):
    w, h = rect[2] - rect[0], rect[3] - rect[1]
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shape = Image.new("L", (w, h), 0)
    ImageDraw.Draw(shape).rounded_rectangle((0, 0, w - 1, h - 1), radius=FRAME_R, fill=255)
    # faint white sheen
    sheen = Image.new("RGBA", (w, h), (255, 255, 255, 22))
    # diagonal glare streaks
    glare = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    g = ImageDraw.Draw(glare)
    k = h / 1000.0
    for off, wd, al in ((0, 120, 46), (170, 40, 34), (260, 18, 30)):
        x = 100 + off * max(k, 0.4)
        g.polygon(((x, 0), (x + wd * max(k, 0.4), 0), (x + wd * max(k, 0.4) - h * 0.45, h), (x - h * 0.45, h)),
                  fill=(255, 255, 255, al))
    glare = glare.filter(ImageFilter.GaussianBlur(6))
    sheen.alpha_composite(glare)
    if print_fn:
        sheen.alpha_composite(print_fn(w, h))
    # bright edge + a faint inner line, the cut edge of the plastic
    e = ImageDraw.Draw(sheen)
    e.rounded_rectangle((0, 0, w - 1, h - 1), radius=FRAME_R, outline=(255, 255, 255, 130), width=3)
    e.rounded_rectangle((3, 3, w - 4, h - 4), radius=FRAME_R - 2, outline=(120, 140, 160, 60), width=2)
    img.paste(sheen, (0, 0), shape)
    return img


def screen_print(w, h):
    """The instructions, printed on a P-px grid like the rest of the pixel art."""
    lw, lh = w // P, h // P
    txt = Image.new("RGBA", (lw, lh), (0, 0, 0, 0))
    t = ImageDraw.Draw(txt)
    t.fontmode = "1"
    big = ImageFont.truetype(FONT_BIG, 16)
    bold = ImageFont.truetype(FONT_BOLD, 8)
    ox = (SCREEN[0] - SCREEN_FILM[0]) // P          # screen offset inside the film
    oy = (SCREEN[1] - SCREEN_FILM[1]) // P
    sw = (SCREEN[2] - SCREEN[0]) // P
    sh = (SCREEN[3] - SCREEN[1]) // P
    cx = ox + sw // 2
    y = oy + 26
    t.text((cx, y), "WELCOME TO POOP PAL!", font=big, fill=INK + (255,), anchor="mm")
    y += 22
    t.text((cx, y), "Before you start:", font=bold, fill=INK + (255,), anchor="mm")
    y += 30
    steps = [
        ("1", "Peel off this film", "from the corner tab"),
        ("2", "Double-tap the logo", "to turn your Poop Pal over"),
        ("3", "Pull the battery tab", "out of the back to power on"),
    ]
    x0 = ox + 30
    for n, a, b in steps:
        t.ellipse((x0, y - 8, x0 + 17, y + 9), outline=INK + (255,), width=2)
        t.text((x0 + 9, y + 1), n, font=bold, fill=INK + (255,), anchor="mm")
        t.text((x0 + 28, y - 5), a, font=bold, fill=INK + (255,), anchor="lm")
        t.text((x0 + 28, y + 7), b, font=bold, fill=INK + (200,), anchor="lm")
        y += 44
    # the Kobaya Tech mark low on the film
    logo = Image.open(ROOT / "textures" / "boot" / "kobaya_logo.png").convert("RGBA")
    lg = logo.resize((logo.width // 8, logo.height // 8), Image.BOX)
    a = np.array(lg)[..., 3] > 60
    mark = np.zeros(a.shape + (4,), np.uint8)
    mark[a] = INK + (230,)
    mk = Image.fromarray(mark, "RGBA")
    txt.alpha_composite(mk, (cx - mk.width // 2, oy + sh - mk.height - 26))
    return txt.resize((lw * P, lh * P), Image.NEAREST).crop((0, 0, w, h))


def pull_tab():
    """Red tab printed 'PULL', stuck to the film's corner (drawn unrotated)."""
    tab = Image.new("RGBA", (150, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(tab)
    d.rounded_rectangle((0, 0, 149, 55), radius=12, fill=(206, 62, 62, 255), outline=(120, 30, 30, 255), width=3)
    tl = Image.new("RGBA", (50, 19), (0, 0, 0, 0))
    tld = ImageDraw.Draw(tl)
    tld.fontmode = "1"
    tld.text((25, 10), "PULL", font=ImageFont.truetype(FONT_BOLD, 8), fill=(255, 255, 255, 255), anchor="mm")
    tab.alpha_composite(tl.resize((150, 57), Image.NEAREST).crop((0, 0, 150, 56)))
    return tab


def battery_strip():
    """The clear plastic strip that keeps the cells from touching: most of it sits under
    the battery lid, the end (top of the image) pokes out above it, printed with 3 red arrows."""
    w, h = 84, 520
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=16, fill=(242, 236, 228, 235), outline=(150, 120, 100, 255), width=3)
    d.line((10, 6, 10, h - 12), fill=(255, 255, 255, 200), width=3)          # plastic shine
    # three red arrows on the end that sticks out, pointing the way to pull (up)
    cx = w // 2
    for y in (26, 72, 118):
        d.polygon(((cx - 22, y + 26), (cx, y), (cx + 22, y + 26), (cx + 22, y + 38), (cx, y + 14), (cx - 22, y + 38)),
                  fill=(206, 62, 62, 255))
    return img


def screen_off():
    """The big screen without power: an unlit reflective colour screen (original-GBA
    style), unlike the small Casio-style LCD. Dark cool grey with a gentle shading, a
    whisper of grain and its pixel grid just showing. No reflections: only the films shine."""
    w, h = SCREEN[2] - SCREEN[0], SCREEN[3] - SCREEN[1]
    yy, xx = np.mgrid[0:h, 0:w]
    t = xx / w * 0.45 + yy / h * 0.55
    base = np.array([96, 103, 104]) * (1 - t[..., None]) + np.array([70, 76, 79]) * t[..., None]
    base += np.random.default_rng(2).normal(0, 1.4, (h, w))[..., None]
    # the pixel grid: thin, slightly darker lines every 5 px
    grid = (xx % 5 == 0) | (yy % 5 == 0)
    base[grid] *= 0.94
    return Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGB").convert("RGBA")


def main():
    OUT.mkdir(exist_ok=True)
    film(SCREEN_FILM, screen_print).save(OUT / "film_screen.png")
    film(LCD_FILM).save(OUT / "film_lcd.png")
    pull_tab().save(OUT / "pull_tab.png")
    battery_strip().save(OUT / "battery_strip.png")
    screen_off().save(OUT / "screen_off.png")
    print("wrote", ", ".join(sorted(p.name for p in OUT.glob("*.png"))))


if __name__ == "__main__":
    main()
