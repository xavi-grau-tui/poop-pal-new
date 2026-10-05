"""The HaraTomo retail box (first launch, before the films): MOCKUPS for now.

    <python with Pillow + numpy> tools/design/box_art.py [mockup_dir]

Writes the game's layers into textures/unboxing/box/ (lid.png with a see-through window,
insert.png, booklet.png, seal.png, device_tray.png; device.png is the device's first frame,
films on) and
the launch splash (textures/boot/splash.png = the closed box, built from those layers).
With a mockup_dir it also writes, at 1080x1920:
  box_closed.png  the lid seen from above: its print, a round seal across the bottom edge,
                  and a window whose clear plastic shows exactly what is inside
  box_open.png    the lid off: the cardboard insert with the device in its tray (same place
                  and size as through the window, so nothing jumps when the lid comes off)
  box_empty.png   the device lifted out: the instruction booklet lies under it
Print and type are drawn on a 3 px grid like the rest of the pixel art; the three baby
pals are drawn in old instruction-booklet style (tools/design/box_mascot.py), pixelated."""
import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from box_mascot import baby

ROOT = Path(__file__).resolve().parents[2]
BOX_DIR = ROOT / "textures" / "unboxing" / "box"
W, H, P = 1080, 1920, 3
LW, LH = W // P, H // P
PIXELLARI = str(ROOT / "fonts" / "Pixellari.ttf")
CHICAGO = str(ROOT / "fonts" / "pixChicago.ttf")
JP = "/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc"

SKY, SKY_LT, SKY_DK = (110, 196, 232), (150, 216, 242), (52, 120, 170)
NAVY = (34, 58, 100)
INK = (64, 46, 33)
CREAM = (250, 240, 222)
YELLOW, ORANGE = (255, 214, 72), (240, 140, 52)
WHITE = (255, 255, 255)
INSERT, DOTS, TRAY, TRAY_EDGE = (232, 236, 240), (196, 222, 238), (196, 202, 210), (160, 168, 178)

# the device in the box: the same rect through the lid's window and with the lid off
DEV_S = 0.6
DEV_W, DEV_H = round(W * DEV_S), round(H * DEV_S)
DEV_X, DEV_Y = (W - DEV_W) // 2, 500
HOLE_M = 34                                          # window margin around the device
HOLE = (DEV_X - HOLE_M, DEV_Y - HOLE_M, DEV_X + DEV_W + HOLE_M, DEV_Y + DEV_H + HOLE_M)
HOLE_R = 28


def up(img):
    return img.resize((img.width * P, img.height * P), Image.NEAREST)


def low():
    return Image.new("RGBA", (LW, LH), (0, 0, 0, 0))


def text(d, xy, s, size, fill, font=PIXELLARI, anchor="mm", outline=None, ow=1):
    f = ImageFont.truetype(font, size)
    if outline:
        for dx in range(-ow, ow + 1):
            for dy in range(-ow, ow + 1):
                if dx or dy:
                    d.text((xy[0] + dx, xy[1] + dy), s, font=f, fill=outline, anchor=anchor)
    d.text(xy, s, font=f, fill=fill, anchor=anchor)


def sunburst(img, cx, cy, rays=18, a=SKY, b=SKY_LT):
    yy, xx = np.mgrid[0:img.height, 0:img.width]
    ang = np.arctan2(yy - cy, xx - cx)
    band = ((ang + np.pi) / (2 * np.pi) * rays * 2).astype(int) % 2
    arr = np.zeros((img.height, img.width, 4), np.uint8)
    arr[band == 0] = a + (255,)
    arr[band == 1] = b + (255,)
    img.alpha_composite(Image.fromarray(arr, "RGBA"))


def starburst(d, cx, cy, r1, r2, n, fill, outline):
    pts = []
    for i in range(n * 2):
        r = r1 if i % 2 == 0 else r2
        t = np.pi * i / n - np.pi / 2
        pts.append((cx + r * np.cos(t), cy + r * np.sin(t)))
    d.polygon(pts, fill=fill, outline=outline)


def print_logo():
    """logo2.png for printing: the cream inside the letters' holes and the kanji is the
    device's beige, so on the box it is left unprinted (the box shows through)."""
    a = np.array(Image.open(ROOT / "textures" / "console" / "logo2.png").convert("RGBA"))
    h, w = a.shape[:2]
    op = a[..., 3] > 0
    light = op & (a[..., 0] >= 100)
    tan = light & (np.abs(a[..., 0].astype(int) - 209) < 12) & (np.abs(a[..., 1].astype(int) - 171) < 12)
    seen = np.zeros_like(light)
    for y0 in range(h):
        for x0 in range(w):
            if not light[y0, x0] or seen[y0, x0]:
                continue
            comp, q, body = [], deque([(y0, x0)]), False
            seen[y0, x0] = True
            while q:
                y, x = q.popleft()
                comp.append((y, x))
                body |= bool(tan[y, x])
                for yy, xx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                    if 0 <= yy < h and 0 <= xx < w and light[yy, xx] and not seen[yy, xx]:
                        seen[yy, xx] = True
                        q.append((yy, xx))
            if not body:                                  # a hole (or a kanji's inner patch)
                for y, x in comp:
                    a[y, x, 3] = 0
    return Image.fromarray(a, "RGBA")


# a big clear tape: from near the top of the bottom band down over the lid's edge
SEAL_W, SEAL_H = 420, 216
SEAL_C = (W // 2, H - 186 + SEAL_H // 2)


def seal_layer():
    """The clear tape seal across the lid's bottom edge, on its own (it is peeled off). The
    band's print shows through it; REMOVE SEAL is printed below the slogan."""
    w, h, r = SEAL_W, SEAL_H, 30
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=r, fill=(255, 255, 255, 44), outline=(255, 255, 255, 150), width=5)
    d.rounded_rectangle((22, 14, 96, 26), radius=6, fill=(255, 255, 255, 140))           # glare
    d.text((w // 2, 142), "REMOVE SEAL", font=ImageFont.truetype(PIXELLARI, 44), fill=(255, 255, 255, 235), anchor="mm")
    return im


# ------------------------------------------------------------------ inside the box

BOOK = (W // 2 - 285, DEV_Y + DEV_H // 2 - 360, 570, 720)      # x, y, w, h: under the device


def insert_base():
    """The cardboard insert and the device's tray (the device and the booklet are separate)."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    art = low()
    d = ImageDraw.Draw(art)
    d.rectangle((0, 0, LW, LH), fill=(36, 62, 104))                 # the box's walls
    d.rectangle((6, 6, LW - 7, LH - 7), fill=INSERT)
    for y in range(14, LH - 10, 12):                                # printed dots
        for x in range(12 + (y // 12 % 2) * 6, LW - 10, 12):
            d.point((x, y), fill=DOTS)
    img.alpha_composite(up(art))
    rd = ImageDraw.Draw(img)
    tray = (DEV_X - 14, DEV_Y - 14, DEV_X + DEV_W + 14, DEV_Y + DEV_H + 14)
    rd.rounded_rectangle(tray, radius=26, fill=TRAY, outline=TRAY_EDGE, width=4)
    for nx in (tray[0], tray[2]):                                   # finger notches
        rd.ellipse((nx - 40, DEV_Y + DEV_H // 2 - 60, nx + 40, DEV_Y + DEV_H // 2 + 60), fill=(170, 178, 188))
    return img


def booklet_layer():
    bx, by, bw, bh = BOOK
    im = Image.new("RGBA", (bw + 8, bh + 8), (0, 0, 0, 0))
    im.alpha_composite(Image.new("RGBA", (bw, bh), (40, 50, 60, 70)), (8, 8))
    im.alpha_composite(booklet_cover(bw, bh), (0, 0))
    return im


def cut_corners():
    """device.png is a game capture: outside the device's rounded brown frame its corners
    showed the screen's background. Make them transparent (the frame's soft edge pixels keep
    their share as alpha), so in the tray the box shows around the corners. Idempotent."""
    path = BOX_DIR / "device.png"
    a = np.array(Image.open(path).convert("RGBA")).astype(float)
    h, w = a.shape[:2]
    frame = np.array([72, 49, 37], float)
    bg = a[0, 0, :3].copy()
    if a[0, 0, 3] == 0:
        return
    outside = np.zeros((h, w), bool)
    q = deque([(0, 0), (0, w - 1), (h - 1, 0), (h - 1, w - 1)])
    for y, x in q:
        outside[y, x] = True
    near_bg = np.abs(a[..., :3] - bg).sum(2) < 6
    while q:
        y, x = q.popleft()
        for yy, xx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= yy < h and 0 <= xx < w and not outside[yy, xx] and near_bg[yy, xx]:
                outside[yy, xx] = True
                q.append((yy, xx))
    a[outside, 3] = 0
    # the soft edge: pixels touching the cut that blend background into the frame
    edge = ~outside & (np.roll(outside, 1, 0) | np.roll(outside, -1, 0) | np.roll(outside, 1, 1) | np.roll(outside, -1, 1))
    t = np.clip((a[..., 1] - bg[1]) / (frame[1] - bg[1]), 0, 1)        # how much frame is in it
    a[edge, :3] = frame
    a[edge, 3] = 255 * t[edge]
    Image.fromarray(a.astype(np.uint8), "RGBA").save(path)


def device_layer():
    dev = Image.open(BOX_DIR / "device.png").convert("RGBA")
    return dev.resize((DEV_W, DEV_H), Image.LANCZOS)


def insert(with_device=True):
    """The insert as it lies under the lid: the device in its tray, or (lifted out) the
    booklet that was lying underneath."""
    img = insert_base()
    img.alpha_composite(booklet_layer(), (BOOK[0], BOOK[1]))
    if with_device:
        img.alpha_composite(device_layer(), (DEV_X, DEV_Y))
    return img


def booklet_cover(w, h):
    art = Image.new("RGBA", (w // P, h // P), CREAM + (255,))
    d = ImageDraw.Draw(art)
    bw, bh = art.size
    d.rectangle((0, 0, bw - 1, bh - 1), outline=INK)
    d.rectangle((0, 0, bw - 1, 22), fill=SKY_DK)
    text(d, (bw // 2, 11), "INSTRUCTION MANUAL", 8, WHITE, font=CHICAGO)
    jp = ImageFont.truetype(JP, 12)
    t = Image.new("L", (bw, 16), 0)
    ImageDraw.Draw(t).text((bw // 2, 8), "取扱説明書", font=jp, fill=255, anchor="mm")
    art.paste(INK + (255,), (0, bh - 30), t.point(lambda v: 255 if v > 110 else 0))
    text(d, (bw // 2, bh - 8), "Kobaya Tech", 8, SKY_DK, font=CHICAGO)
    cov = up(art).resize((w, h), Image.NEAREST)
    logo = Image.open(ROOT / "textures" / "console" / "logo2.png").convert("RGBA")
    k = (w - 60) / logo.width
    logo = logo.resize((round(logo.width * k), round(logo.height * k * 1.1)), Image.NEAREST)
    cov.alpha_composite(logo, (w // 2 - logo.width // 2, 96))
    p = baby("sprig", int(w * 0.40), pixel=P)
    cov.alpha_composite(p, (w // 2 - p.width // 2, 96 + logo.height - 6))
    sd = ImageDraw.Draw(cov)
    for yy in (h // 4, 3 * h // 4):                                 # staples on the spine
        sd.rectangle((10, yy - 14, 15, yy + 14), fill=(170, 170, 178))
    return cov


# ------------------------------------------------------------------ the lid

def window(img):
    """The die-cut hole, left see-through: only the lid's edge shadow on what lies beneath,
    and the clear plastic over it all (a faint sheen, diagonal glare, bright edges)."""
    x0, y0, x1, y1 = HOLE
    w, h = x1 - x0, y1 - y0
    hole = Image.new("L", (W, H), 0)
    ImageDraw.Draw(hole).rounded_rectangle(HOLE, radius=HOLE_R, fill=255)
    a = np.array(img)
    a[np.array(hole) > 0] = 0                                       # cut out
    inner = Image.new("L", (W, H), 0)
    ImageDraw.Draw(inner).rounded_rectangle((x0 + 14, y0 + 16, x1 + 30, y1 + 30), radius=HOLE_R, fill=255)
    shade = (np.array(hole) > 0) & ~(np.array(inner) > 0)
    a[shade] = (0, 0, 0, 72)                                        # the lid's thickness
    img.paste(Image.fromarray(a, "RGBA"))
    film = Image.new("RGBA", (w, h), (255, 255, 255, 22))
    g = ImageDraw.Draw(film)
    for off, wd, al in ((60, 120, 56), (230, 40, 44), (320, 18, 38), (620, 70, 30)):
        g.polygon(((off, 0), (off + wd, 0), (off + wd - h * 0.5, h), (off - h * 0.5, h)), fill=(255, 255, 255, al))
    g.rounded_rectangle((0, 0, w - 1, h - 1), radius=HOLE_R, outline=(255, 255, 255, 150), width=4)
    g.rounded_rectangle((6, 6, w - 7, h - 7), radius=HOLE_R - 4, outline=(255, 255, 255, 50), width=2)
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, w - 1, h - 1), radius=HOLE_R, fill=255)
    clip = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    clip.paste(film, (0, 0), m)
    img.alpha_composite(clip, (x0, y0))
    ImageDraw.Draw(img).rounded_rectangle((x0 - 3, y0 - 3, x1 + 3, y1 + 3), radius=HOLE_R + 3,
                                          outline=(214, 236, 248), width=3)


def lid_layer():
    img = Image.new("RGBA", (W, H), NAVY + (255,))
    art = low()
    sunburst(art, LW // 2, 300, rays=16)
    d = ImageDraw.Draw(art)
    d.rectangle((0, 0, LW, 30), fill=NAVY)                          # top band
    d.rounded_rectangle((8, 7, 92, 23), radius=7, fill=WHITE)
    text(d, (50, 15), "Kobaya Tech", 8, NAVY, font=CHICAGO)
    text(d, (LW - 10, 15), "KBT-0721", 8, WHITE, font=CHICAGO, anchor="rm")
    jp = ImageFont.truetype(JP, 13)                                 # tagline
    tag = Image.new("L", (200, 20), 0)
    ImageDraw.Draw(tag).text((100, 10), "おなかのともだち", font=jp, fill=255, anchor="mm")
    tag = tag.point(lambda v: 255 if v > 110 else 0)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            art.paste(NAVY + (255,), (LW // 2 - 100 + dx, 112 + dy), tag)
    art.paste(WHITE + (255,), (LW // 2 - 100, 112), tag)
    text(d, (LW // 2, 140), "YOUR TUMMY FRIEND!", 16, YELLOW, outline=NAVY)
    d.rectangle((0, LH - 62, LW, LH), fill=NAVY)                    # bottom band
    text(d, (LW // 2, LH - 46), "FEED  -  PLAY  -  EVOLVE", 16, WHITE)
    text(d, (LW // 2, LH - 28), "120+ PALS TO DISCOVER!", 16, YELLOW)
    d.rounded_rectangle((8, LH - 52, 56, LH - 26), radius=4, fill=WHITE)
    text(d, (32, LH - 44), "AGES", 8, NAVY, font=CHICAGO)
    text(d, (32, LH - 34), "4+", 16, NAVY)
    text(d, (LW - 8, LH - 46), "BATTERIES", 8, WHITE, font=CHICAGO, anchor="rm")
    text(d, (LW - 8, LH - 35), "INCLUDED", 8, WHITE, font=CHICAGO, anchor="rm")
    img.alpha_composite(up(art))
    logo = print_logo()
    k = 820 / logo.width
    logo = logo.resize((round(logo.width * k), round(logo.height * k * 1.12)), Image.NEAREST)
    img.alpha_composite(logo, (W // 2 - logo.width // 2, 118))
    window(img)
    # the three babies beside the window
    for name, x, y in (("picklet", -14, 640), ("ember", 880, 990), ("sprig", -14, 1320)):
        img.alpha_composite(baby(name, 165, pixel=P), (x, y))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, W - 1, H - 1), outline=(30, 50, 86), width=9)    # the lid's rim
    d.line((9, 9, W - 10, 9), fill=(180, 228, 248), width=3)
    d.line((9, 9, 9, H - 10), fill=(160, 220, 245), width=3)
    return img


def closed_box():
    """What the game shows first (and the launch splash): every layer in place."""
    img = insert(True)
    img.alpha_composite(lid_layer())
    sl = seal_layer()
    img.alpha_composite(sl, (SEAL_C[0] - sl.width // 2, SEAL_C[1] - sl.height // 2))
    return img


def main():
    BOX_DIR.mkdir(exist_ok=True)
    cut_corners()
    lid_layer().save(BOX_DIR / "lid.png")
    insert_base().save(BOX_DIR / "insert.png")
    booklet_layer().save(BOX_DIR / "booklet.png")
    seal_layer().save(BOX_DIR / "seal.png")
    device_layer().save(BOX_DIR / "device_tray.png")    # the device as it sits in the tray
    closed = closed_box()
    closed.convert("RGB").save(ROOT / "textures" / "boot" / "splash.png", optimize=True)
    print("wrote textures/unboxing/box/{lid,insert,booklet,seal}.png and the splash")
    if len(sys.argv) > 1:
        out = Path(sys.argv[1])
        closed.convert("RGB").save(out / "box_closed.png")
        insert(True).convert("RGB").save(out / "box_open.png")
        insert(False).convert("RGB").save(out / "box_empty.png")
        print("mockups in", out)


if __name__ == "__main__":
    main()
