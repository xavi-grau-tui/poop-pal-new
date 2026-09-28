"""Paint-big-then-shrink renderer: builds sprites at high resolution with soft 3D
shading + texture noise, then downsamples, mimicking the existing Poop Pal assets."""
import numpy as np, math
from PIL import Image, ImageDraw, ImageFilter

import os
HERE = os.path.dirname(os.path.abspath(__file__))
SCR = os.path.join(HERE, 'out')          # previews / hi-res masters (gitignored)
os.makedirs(SCR, exist_ok=True)
PROJ = os.path.join(HERE, '..', '..', 'textures')
OUT = np.array([34, 20, 22], np.float32)   # near-black warm outline (sampled from poo1)
L = np.array([-0.55, -0.75, 0.62]); L /= np.linalg.norm(L)
rng = np.random.default_rng(7)


class Canvas:
    def __init__(s, w, h, scale, f=1.0, squash=(1.0, 1.0), anchor=(55, 93)):
        s.w, s.h, s.k, s.f = w, h, scale, f     # f = native px per design unit
        s.sq, s.an = squash, anchor              # squash frame: scale around anchor (bottom-centre)
        y, x = np.mgrid[0:h * scale, 0:w * scale].astype(np.float32)
        x, y = x / scale / f, y / scale / f
        s.x = anchor[0] + (x - anchor[0]) / squash[0]   # design coordinates
        s.y = anchor[1] + (y - anchor[1]) / squash[1]
        s.rgb = np.zeros((h * scale, w * scale, 3), np.float32)
        s.a = np.zeros((h * scale, w * scale), np.float32)

    def P(s, x, y):
        """design coords -> hi-res pixel coords (applies squash)."""
        return ((s.an[0] + (x - s.an[0]) * s.sq[0]) * s.k * s.f,
                (s.an[1] + (y - s.an[1]) * s.sq[1]) * s.k * s.f)

    def noise(s, freq, amp):
        """Blurred value noise, gives the painterly grain that survives downscaling."""
        r = rng.random((s.h * s.k, s.w * s.k)).astype(np.float32)
        im = Image.fromarray((r * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(s.k * freq))
        n = np.asarray(im, np.float32) / 255
        n = (n - n.mean()) / (n.std() + 1e-6)
        return 1 + n * amp


def field(c, balls):
    F = np.zeros_like(c.x)
    for b in balls:
        cx, cy, rx, ry = b[:4]
        w = b[4] if len(b) > 4 else 1.0
        F += w / np.maximum(((c.x - cx) / rx) ** 2 + ((c.y - cy) / ry) ** 2, 1e-4)
    return F


def height(F, sharp=0.5):
    return np.clip(1 - 1 / np.maximum(F, 1e-4), 0, 1) ** sharp


def shade(c, h, bump=6.0, spec_pow=24, spec_amt=0.5):
    gy, gx = np.gradient(h * c.k * bump)
    n = np.stack([-gx, -gy, np.ones_like(gx) * 1.0 * c.k / c.k], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    diff = np.clip(n @ L, 0, 1)
    H = L + np.array([0, 0, 1.0]); H /= np.linalg.norm(H)
    spec = np.clip(n @ H, 0, 1) ** spec_pow * spec_amt
    return diff, spec


def ramp(pal, v):
    pal = np.array(pal, np.float32)
    v = np.clip(v, 0, 1) * (len(pal) - 1)
    i = np.clip(v.astype(int), 0, len(pal) - 2)
    t = (v - i)[..., None]
    return pal[i] * (1 - t) + pal[i + 1] * t


def paint(c, mask, col):
    m = mask.astype(np.float32)[..., None]
    c.rgb = c.rgb * (1 - m) + col * m
    c.a = np.maximum(c.a, mask.astype(np.float32))


def dilate(mask, r):
    m = mask.copy()
    for _ in range(r):
        n = m.copy()
        n[1:] |= m[:-1]; n[:-1] |= m[1:]; n[:, 1:] |= m[:, :-1]; n[:, :-1] |= m[:, 1:]
        m = n
    return m


def outline(c, mask, px=1.0, col=OUT):
    """Paint outline ring *under* current pixels: only where alpha is empty."""
    ring = dilate(mask, int(px * c.k)) & ~mask
    ring &= c.a < 0.5
    paint(c, ring, col)


def seam(c, mask_a, mask_b, px=0.6, col=OUT):
    """Dark line where two materials meet (like burger layers)."""
    edge = dilate(mask_a, max(1, int(px * c.k))) & mask_b
    paint(c, edge, col)


def material(c, h, mask, pal, bump=6, spec_amt=0.45, spec_pow=24, grain=0.07, ao=0.35, extra=None):
    diff, spec = shade(c, h, bump, spec_pow, spec_amt)
    v = 0.18 + 0.78 * diff
    v *= (1 - ao) + ao * np.clip(h * 1.6, 0, 1)          # edge occlusion
    v *= c.noise(0.7, grain)
    col = ramp(pal, v) + spec[..., None] * 255
    if extra is not None:
        col = extra(col)
    paint(c, mask, np.clip(col, 0, 255))


def to_image(c):
    rgba = np.dstack([c.rgb, c.a * 255]).clip(0, 255).astype(np.uint8)
    return Image.fromarray(rgba, 'RGBA')


def shrink(c, alpha_cut=120):
    big = to_image(c)
    small = big.resize((c.w, c.h), Image.LANCZOS)
    a = np.asarray(small).copy()
    a[..., 3] = np.where(a[..., 3] > alpha_cut, 255, 0)
    return big, Image.fromarray(a, 'RGBA')


# ---------------------------------------------------------------- face (brand identity)
def face(c, cx, cy, spread=10, style='happy', eye_r=3.4):
    k = c.k
    im = to_image(c); d = ImageDraw.Draw(im, 'RGBA')
    P = c.P
    ex = [cx - spread, cx + spread]
    for e in ex:
        if style in ('happy', 'sparkle'):
            d.ellipse([*P(e - eye_r, cy - eye_r * 1.1), *P(e + eye_r, cy + eye_r * 1.1)], fill=(18, 8, 14))
            d.ellipse([*P(e - eye_r * .55, cy - eye_r * .75), *P(e + eye_r * .15, cy - eye_r * .05)], fill=(255, 255, 255))
            if style == 'sparkle':
                d.ellipse([*P(e + eye_r * .2, cy + eye_r * .25), *P(e + eye_r * .6, cy + eye_r * .65)], fill=(255, 255, 255))
        elif style == 'sleepy':   # content, half-closed "u" eyes
            d.arc([*P(e - eye_r, cy - eye_r), *P(e + eye_r, cy + eye_r)], 20, 160, fill=(18, 8, 14), width=max(2, int(2.4 * k * c.f * eye_r / 3.4)))
        elif style == 'stars':
            pts = []
            for i in range(10):
                r = eye_r * (1.2 if i % 2 == 0 else .5); a = -math.pi / 2 + i * math.pi / 5
                pts.append(P(e + r * math.cos(a), cy + r * math.sin(a)))
            d.polygon(pts, fill=(18, 8, 14))
        # blush
        u = eye_r / 3.4
        bx = e + (-3.5 * u if e < cx else 3.5 * u)
        d.ellipse([*P(bx - 3 * u, cy + 3.4 * u), *P(bx + 3 * u, cy + 5.8 * u)], fill=(236, 130, 145, 190))
    # mouth
    u = eye_r / 3.4
    my = cy + 3.0 * u
    if style == 'sleepy':
        d.chord([*P(cx - 3.2 * u, my - 2.4 * u), *P(cx + 3.2 * u, my + 3.4 * u)], 0, 180, fill=(18, 8, 14))
        d.chord([*P(cx - 1.9 * u, my + .6 * u), *P(cx + 1.9 * u, my + 3.4 * u)], 180, 360, fill=(226, 110, 130))
    else:
        d.chord([*P(cx - 3.0 * u, my - 2.6 * u), *P(cx + 3.0 * u, my + 3.6 * u)], 0, 180, fill=(18, 8, 14))
        d.chord([*P(cx - 1.8 * u, my + .9 * u), *P(cx + 1.8 * u, my + 3.8 * u)], 180, 360, fill=(226, 110, 130))
    a = np.asarray(im, np.float32)
    c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255


def dots(c, n, region, colors, r=0.9, seed=1, angle=True):
    """sprinkles / seeds painted on top."""
    rr = np.random.default_rng(seed)
    k = c.k * c.f
    im = to_image(c); d = ImageDraw.Draw(im, 'RGBA')
    x0, y0, x1, y1, inside = region
    placed = 0
    while placed < n:
        x, y = rr.uniform(x0, x1), rr.uniform(y0, y1)
        if not (0 <= y < 100 and 0 <= x < 110) or not inside(x, y): continue
        col = colors[rr.integers(len(colors))]
        if angle:
            t = rr.uniform(0, math.pi); dx, dy = math.cos(t) * r * 1.6, math.sin(t) * r * 1.6
            d.line([*c.P(x - dx, y - dy), *c.P(x + dx, y + dy)], fill=col, width=int(r * 1.3 * k))
        else:
            d.ellipse([*c.P(x - r, y - r), *c.P(x + r, y + r)], fill=col)
        placed += 1
    a = np.asarray(im, np.float32)
    c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255
