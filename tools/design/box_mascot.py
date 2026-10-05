"""Box / booklet illustrations of the baby pals (Picklet, Sprig, Ember) in an old-school
manual-art style: wobbly ink outlines heavier at the bottom, flat colour with one shadow
tone, simple eyes with one highlight, a flat ground shadow. No arms or legs. Deliberately
unlike the in-game pixel sprites (like 90s instruction-booklet art vs the game).

    baby(name, size) -> RGBA image (drawn 4x and downsampled for clean lines)"""
import math

from PIL import Image, ImageDraw

SS = 4
INK = (52, 36, 34)


def _shape(cx, cy, w, h, kind, wob=0.012, seed=0.0, n=160):
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x, y = math.cos(t), math.sin(t)
        if kind == "dome":                # Picklet: a wide, soft dome on a flat-ish base
            if y > 0:
                y *= 0.55
                x *= 1 + 0.06 * y
        elif kind == "mound":             # Sprig: a bell, wide at the base, narrower on top
            if y < 0:
                x *= 1 + 0.32 * y
            else:
                y *= 0.5
        elif kind == "drop":              # Ember: a teardrop, its top drawn up to a point
            if y < 0:
                peak = math.exp(-(x * 3.0) ** 2)
                y *= 1 + 0.42 * peak
                x *= 1 + 0.12 * y
            else:
                y *= 0.58
        r = 1 + wob * (math.sin(3 * t + seed) + 0.6 * math.sin(7 * t + seed * 2))   # hand-drawn wobble
        pts.append((cx + x * w / 2 * r, cy + y * h / 2 * r))
    return pts


def _grow(pts, c, k, dx=0.0, dy=0.0):
    return [(c[0] + (x - c[0]) * k + dx, c[1] + (y - c[1]) * k + dy) for x, y in pts]


def _body(img, pts, c, base, shade, light, ow):
    d = ImageDraw.Draw(img)
    # ink: a bit heavier towards the bottom-right, like a brush line
    d.polygon(_grow(pts, c, 1 + ow / 300, ow * 0.25, ow * 0.45), fill=INK)
    d.polygon(_grow(pts, c, 1 + ow / 420), fill=INK)
    d.polygon(pts, fill=base)
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    # one flat shadow tone along the lower right...
    lit = Image.new("L", img.size, 0)
    ImageDraw.Draw(lit).polygon(_grow(pts, c, 0.96, -ow * 1.6, -ow * 1.3), fill=255)
    sh = Image.composite(Image.new("L", img.size, 0), mask, lit)
    img.paste(Image.new("RGBA", img.size, shade + (255,)), (0, 0), sh)
    # ...and one lighter tone on the upper left, like the in-game sprites
    top = Image.new("L", img.size, 0)
    ImageDraw.Draw(top).polygon(_grow(pts, c, 0.80, -ow * 2.2, -ow * 2.6), fill=255)
    low_ = Image.new("L", img.size, 0)
    ImageDraw.Draw(low_).polygon(_grow(pts, c, 0.80, ow * 0.6, ow * 0.4), fill=255)
    hi = Image.composite(Image.new("L", img.size, 0), top, low_)
    hi = Image.composite(hi, Image.new("L", img.size, 0), mask)
    img.paste(Image.new("RGBA", img.size, light + (255,)), (0, 0), hi)


def _shine(d, cx, cy, r):
    """Two small bright blobs: a highlight that survives being printed in big dots."""
    d.ellipse((cx - r, cy - r * 0.7, cx + r, cy + r * 0.7), fill=(255, 255, 255))
    d.ellipse((cx - r * 1.9, cy + r * 1.1, cx - r * 1.3, cy + r * 1.6), fill=(255, 255, 255))


def _eye(d, x, y, w, h, ow, big=True):
    d.ellipse((x - w / 2, y - h / 2, x + w / 2, y + h / 2), fill=INK)
    d.ellipse((x - w * 0.34, y - h * 0.36, x + w * 0.10, y + h * 0.0), fill=(255, 255, 255))
    if big:
        d.ellipse((x + w * 0.06, y + h * 0.12, x + w * 0.30, y + h * 0.30), fill=(255, 255, 255))


def _blush(d, x, y, s):
    d.ellipse((x - s * 0.8, y - s * 0.4, x + s * 0.8, y + s * 0.4), fill=(246, 132, 146))


def baby(name, size, pixel=1):
    S = size * SS
    img = Image.new("RGBA", (int(S * 1.3), int(S * 1.2)), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ow = S * 0.03
    cx, cy = img.width / 2, S * 0.74
    # flat ground shadow
    d.ellipse((cx - S * 0.40, cy + S * 0.21, cx + S * 0.40, cy + S * 0.30), fill=(40, 60, 90, 60))
    if name == "picklet":
        w, h = S * 0.92, S * 0.80
        base = (178, 214, 96)
        pts = _shape(cx, cy, w, h, "dome", seed=1.3)
        _body(img, pts, (cx, cy), base, (128, 170, 66), (212, 236, 140), ow)
        d = ImageDraw.Draw(img)
        _shine(d, cx - w * 0.26, cy - h * 0.20, w * 0.05)
        ey = cy - h * 0.0
        for ex in (cx - w * 0.21, cx + w * 0.21):           # small, half-lidded: unimpressed
            _eye(d, ex, ey, w * 0.09, h * 0.13, ow, big=False)
            d.rectangle((ex - w * 0.07, ey - h * 0.09, ex + w * 0.07, ey - h * 0.0), fill=base)
            d.line([(ex - w * 0.06, ey), (ex + w * 0.06, ey)], fill=INK, width=int(ow * 0.9))
        d.line([(cx - w * 0.05, ey + h * 0.14), (cx + w * 0.05, ey + h * 0.14)], fill=INK, width=int(ow * 0.8))
    elif name == "sprig":
        w, h = S * 0.86, S * 0.82
        pts = _shape(cx, cy + S * 0.04, w, h, "mound", seed=0.4)
        _body(img, pts, (cx, cy), (222, 142, 88), (184, 100, 62), (240, 178, 120), ow)
        d = ImageDraw.Draw(img)
        # the leafy cap: a cluster of round leaves, the back ones darker
        top = cy + S * 0.04 - h * 0.5
        for lx, ly, lr, col in ((-0.17, 0.08, 0.09, (78, 140, 60)), (0.17, 0.08, 0.09, (78, 140, 60)),
                                (-0.09, 0.0, 0.10, (104, 172, 72)), (0.09, -0.01, 0.10, (104, 172, 72)),
                                (0.0, -0.07, 0.10, (124, 190, 84))):
            x, y, r = cx + lx * S, top + ly * S + S * 0.03, lr * S
            d.ellipse((x - r - ow, y - r - ow, x + r + ow, y + r + ow), fill=INK)
            d.ellipse((x - r, y - r, x + r, y + r), fill=col)
            d.ellipse((x - r * 0.55, y - r * 0.55, x - r * 0.05, y - r * 0.15), fill=(180, 228, 130))
        ey = cy + S * 0.08
        for ex in (cx - w * 0.17, cx + w * 0.17):
            _eye(d, ex, ey, w * 0.14, h * 0.21, ow)
            _blush(d, ex + (-1 if ex < cx else 1) * w * 0.12, ey + h * 0.15, w * 0.08)
        d.chord((cx - w * 0.06, ey + h * 0.06, cx + w * 0.06, ey + h * 0.19), 0, 180, fill=(170, 60, 60), outline=INK, width=int(ow * 0.6))
    elif name == "ember":
        w, h = S * 0.80, S * 0.74
        pts = _shape(cx, cy, w, h, "drop", seed=2.1)
        _body(img, pts, (cx, cy), (236, 84, 70), (192, 52, 52), (250, 140, 120), ow)
        d = ImageDraw.Draw(img)
        # the little stem at the tip, with a tiny leaf
        tip = min(pts, key=lambda p: p[1])
        end = (tip[0] + S * 0.04, tip[1] - S * 0.09)
        d.line([tip, end], fill=INK, width=int(ow * 2.0))
        d.line([tip, end], fill=(90, 160, 70), width=int(ow * 0.9))
        lf = (end[0] + S * 0.06, end[1] + S * 0.01)
        d.ellipse((lf[0] - S * 0.06 - ow, lf[1] - S * 0.03 - ow, lf[0] + S * 0.06 + ow, lf[1] + S * 0.03 + ow), fill=INK)
        d.ellipse((lf[0] - S * 0.06, lf[1] - S * 0.03, lf[0] + S * 0.06, lf[1] + S * 0.03), fill=(110, 178, 74))
        ey = cy + h * 0.04
        for ex in (cx - w * 0.17, cx + w * 0.17):
            _eye(d, ex, ey, w * 0.14, h * 0.21, ow)
            _blush(d, ex + (-1 if ex < cx else 1) * w * 0.13, ey + h * 0.15, w * 0.08)
        d.chord((cx - w * 0.07, ey + h * 0.05, cx + w * 0.07, ey + h * 0.21), 0, 180, fill=(150, 30, 40), outline=INK, width=int(ow * 0.6))
    img = img.resize((img.width // SS, img.height // SS), Image.LANCZOS)
    return pixelate(img, pixel, PALETTE[name]) if pixel > 1 else img


WHITE, BLUSH = (255, 255, 255), (246, 132, 146)
PALETTE = {        # every colour each pal is drawn with: its print snaps to exactly these
    "picklet": [INK, WHITE, (178, 214, 96), (128, 170, 66), (212, 236, 140)],
    "sprig": [INK, WHITE, BLUSH, (222, 142, 88), (184, 100, 62), (240, 178, 120), (78, 140, 60),
              (104, 172, 72), (124, 190, 84), (180, 228, 130), (170, 60, 60)],
    "ember": [INK, WHITE, BLUSH, (236, 84, 70), (192, 52, 52), (250, 140, 120), (90, 160, 70),
              (110, 178, 74), (150, 30, 40)],
}


def pixelate(img, p, palette):
    """Printed in chunky p-px dots: each dot takes the nearest of the pal's own colours, with
    hard edges, like the rest of the box's print. (The ground shadow keeps its soft tint.)"""
    import numpy as np
    small = np.array(img.resize((img.width // p, img.height // p), Image.BOX)).astype(int)
    pal = np.array(palette)
    solid = small[..., 3] > 170
    rgb = small[..., :3][solid]
    dist = ((rgb[:, None, :] - pal[None, :, :]) ** 2).sum(2)
    # greys (ink blending into white: the eyes) only become ink or white, never a body colour
    grey = (rgb.max(1) - rgb.min(1)) < 40
    is_bw = np.array([tuple(c) in (INK, WHITE) for c in palette])
    dist[np.ix_(grey, ~is_bw)] = 1 << 30
    nearest = pal[np.argmin(dist, axis=1)]
    out = np.zeros_like(small)
    out[solid, :3] = nearest
    out[solid, 3] = 255
    soft = (small[..., 3] > 20) & ~solid                     # the ground shadow
    out[soft] = (40, 60, 90, 60)
    im = Image.fromarray(out.astype(np.uint8), "RGBA")
    return im.resize((im.width * p, im.height * p), Image.NEAREST)
