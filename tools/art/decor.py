"""Gut decor: fairy lights wrapped around the colon (Intestine-front).

The output has exactly the size of intestine-front.png so it can sit on top of it as a
child sprite (position 0, scale 1) and inherit its breathing. Two frames = the twinkle.
Needs scipy + scikit-image on top of pillow/numpy (only to find the colon's centre line).
"""
import math, os
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
from skimage.morphology import skeletonize

from hires import PROJ, SCR

SRC = os.path.join(PROJ, 'pet-background', 'intestine-front.png')
DEST = os.path.join(PROJ, 'pet', 'decor')
BLOCK = 8                    # art-pixel size of the intestine art (it's an upscaled pixel image)
WIRE = (46, 30, 34)
BULBS = [(255, 214, 92), (255, 120, 150), (120, 226, 190), (130, 190, 255)]
TURN = 170.0                 # px of tube per wrap turn
BULB_PHASES = (-1.0, 1.0)    # two bulbs per turn, both on the front half (radians)


def centre_line(alpha):
    """Longest path through the skeleton of the colon mask, ordered end to end."""
    mask = ndimage.binary_opening(alpha > 128, iterations=4)
    mask = ndimage.binary_fill_holes(mask)
    dist = ndimage.distance_transform_edt(mask)
    sk = skeletonize(mask)
    pts = {tuple(p) for p in np.argwhere(sk)}
    nb = lambda p: [(p[0] + dy, p[1] + dx) for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                    if (dy or dx) and (p[0] + dy, p[1] + dx) in pts]

    def bfs(start):
        prev = {start: None}; q = [start]
        for p in q:
            for n in nb(p):
                if n not in prev:
                    prev[n] = p; q.append(n)
        return q[-1], prev

    a, _ = bfs(next(iter(pts)))
    b, prev = bfs(a)
    path = [b]
    while prev[path[-1]] is not None:
        path.append(prev[path[-1]])
    path = np.array(path, np.float32)[:, ::-1]          # (x, y)
    # smooth + resample every 2 px
    k = np.ones(25) / 25
    sm = np.stack([np.convolve(np.pad(path[:, i], 12, mode='edge'), k, 'valid') for i in range(2)], 1)
    seg = np.linalg.norm(np.diff(sm, axis=0), axis=1)
    s = np.concatenate([[0], np.cumsum(seg)])
    t = np.arange(0, s[-1], 2.0)
    line = np.stack([np.interp(t, s, sm[:, i]) for i in range(2)], 1)
    radius = np.array([dist[int(y), int(x)] for x, y in line])
    return line, t, ndimage.uniform_filter1d(radius, 31)


def render(line, s, radius, frame, size):
    W, H = size
    k = 3                                               # supersample, then snap to BLOCK grid
    im = Image.new('RGBA', (W * k, H * k), (0, 0, 0, 0))
    glow = Image.new('RGBA', (W * k, H * k), (0, 0, 0, 0))
    d, g = ImageDraw.Draw(im), ImageDraw.Draw(glow)
    tang = np.gradient(line, axis=0)
    tang /= np.linalg.norm(tang, axis=1, keepdims=True)
    normal = np.stack([-tang[:, 1], tang[:, 0]], 1)
    theta = 2 * math.pi * s / TURN
    off = line + normal * (radius * 0.82 * np.sin(theta))[:, None]
    front = np.cos(theta) > -0.15                       # the half of each turn facing us
    # wire: only the front half of every loop, so it reads as wrapped around the tube
    for i in range(len(off) - 1):
        if front[i] and front[i + 1]:
            d.line([tuple(off[i] * k), tuple(off[i + 1] * k)], fill=WIRE + (255,), width=int(7 * k))
    # bulbs sit where the wire crosses the front of the tube
    n = 0
    for i in range(len(s)):
        ph = (theta[i] + math.pi) % (2 * math.pi) - math.pi
        step = 2 * math.pi * 2.0 / TURN
        if any(abs(ph - b) < step / 2 for b in BULB_PHASES):
            x, y = off[i] * k
            col = BULBS[n % len(BULBS)]
            lit = (n + n // len(BULBS) + frame) % 2 == 0   # every colour has lit bulbs in both frames
            r = 15 * k
            if lit:
                g.ellipse([x - r * 3, y - r * 3, x + r * 3, y + r * 3], fill=col + (60,))
                g.ellipse([x - r * 2, y - r * 2, x + r * 2, y + r * 2], fill=col + (110,))
            body = col if lit else tuple(int(c * 0.45) for c in col)
            # socket
            d.rectangle([x - 7 * k, y - r - 8 * k, x + 7 * k, y - r + 4 * k], fill=WIRE + (255,))
            d.ellipse([x - r - 3 * k, y - r - 3 * k, x + r + 3 * k, y + r + 3 * k], fill=WIRE + (255,))
            d.ellipse([x - r, y - r, x + r, y + r], fill=body + (255,))
            if lit:
                d.ellipse([x - r * .6, y - r * .7, x - r * .05, y - r * .15], fill=(255, 255, 240, 255))
            n += 1
    out = Image.alpha_composite(glow, im)
    # snap to the intestine's chunky pixel grid
    small = out.resize((W // BLOCK, H // BLOCK), Image.LANCZOS)
    a = np.asarray(small).copy()
    solid = a[..., 3] > 150
    a[..., 3] = np.where(solid, 255, np.where(a[..., 3] > 25, (a[..., 3] // 40) * 40, 0))
    small = Image.fromarray(a, 'RGBA').resize(((W // BLOCK) * BLOCK, (H // BLOCK) * BLOCK), Image.NEAREST)
    canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    canvas.alpha_composite(small, (0, 0))
    return canvas


if __name__ == '__main__':
    src = Image.open(SRC)
    line, s, radius = centre_line(np.asarray(src)[..., 3])
    os.makedirs(DEST, exist_ok=True)
    prev = Image.new('RGBA', (src.width * 2, src.height), (236, 170, 170, 255))
    for f in range(2):
        img = render(line, s, radius, f, src.size)
        img.save(os.path.join(DEST, f'fairy_lights-{f + 1}.png'))
        prev.alpha_composite(src, (f * src.width, 0))
        prev.alpha_composite(img, (f * src.width, 0))
    # menu icon: a crop of the top-left corner with lights
    prev.resize((prev.width // 2, prev.height // 2)).save(os.path.join(SCR, 'decor_preview.png'))
    print('ok', len(line), 'pts, radius ~', int(np.median(radius)))
