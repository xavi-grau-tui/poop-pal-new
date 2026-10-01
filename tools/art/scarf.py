"""Scarf accessory (a LUCKY PINCH prize): one image per form and frame, on the same 232x196
canvas as the form sprites (like sunglasses/headphones).

A knitted band wraps the body just under the mouth (it curves down a little in the middle,
like it goes round a round body) and a fringed tail hangs from the right.

    python3 tools/art/scarf.py      -> textures/pet/accessories/scarf/<form>-<n>.png
"""
import os
import numpy as np
from PIL import Image, ImageDraw

import forms
from hires import Canvas, PROJ, SCR
from accessories import FRAMES, faces

INK = (46, 26, 30, 255)
RED = (214, 92, 96, 255)
RED_LO = (170, 62, 72, 255)
CREAM = (250, 236, 210, 255)


def body_mask(form, row):
    return np.asarray(Image.open(os.path.join(PROJ, 'pet', 'forms', f'{form}-{row + 1}.png')))[..., 3] > 40


def body_row(a, y):
    cols = np.nonzero(a[int(round(60 + y))])[0]
    return cols.min() - 60, cols.max() - 60


def scarf(c, left, right, y, th):
    k = c.k * c.f
    im = Image.new('RGBA', (c.w * c.k, c.h * c.k), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    P = c.P
    sag = 2.0
    # the band: a curved strip from edge to edge, slightly wider than the body there
    l, r = left - 2.5, right + 2.5
    top = [P(l + (r - l) * t, y - th / 2 + sag * 4 * t * (1 - t)) for t in np.linspace(0, 1, 24)]
    bot = [P(l + (r - l) * t, y + th / 2 + sag * 4 * t * (1 - t)) for t in np.linspace(1, 0, 24)]
    d.polygon(top + bot, fill=INK)
    inner_t = [(x, yy + 1.4 * k) for (x, yy) in top[1:-1]]
    inner_b = [(x, yy - 1.4 * k) for (x, yy) in bot[1:-1]]
    d.polygon(inner_t + inner_b, fill=RED)
    # knit stripes
    for t in np.linspace(0.12, 0.88, 6):
        x = l + (r - l) * t
        yc = y + sag * 4 * t * (1 - t)
        d.line([P(x, yc - th / 2 + 1.5), P(x - 0.8, yc + th / 2 - 1.5)], fill=CREAM, width=int(1.3 * k))
    # the tail, hanging from the right
    tx = right - 4.0
    ty = y + th / 2 - 1
    tail = [P(tx - 3, ty - 2), P(tx + 3.6, ty - 2), P(tx + 5.2, ty + 11), P(tx - 1.2, ty + 11.5)]
    d.polygon(tail, fill=INK)
    d.polygon([P(tx - 1.7, ty - 0.5), P(tx + 2.5, ty - 0.5), P(tx + 3.8, ty + 10), P(tx - 0.3, ty + 10.3)], fill=RED_LO)
    d.line([P(tx - 0.8, ty + 4.5), P(tx + 3.2, ty + 4.3)], fill=CREAM, width=int(1.3 * k))
    for i in range(3):                        # fringe
        fx = tx - 0.6 + i * 1.7
        d.line([P(fx, ty + 11), P(fx + 0.4, ty + 13.5)], fill=INK, width=int(1.2 * k))
    return im


def shrink(c, im):
    f = np.asarray(im.resize((c.w, c.h), Image.LANCZOS)).copy()
    solid = f[..., 3] > 110
    out = np.zeros_like(f)
    out[solid] = f[solid]
    out[solid, 3] = 255
    return Image.fromarray(out, 'RGBA')


if __name__ == '__main__':
    eyes = faces()
    dest = os.path.join(PROJ, 'pet', 'accessories', 'scarf')
    os.makedirs(dest, exist_ok=True)
    prev = Image.new('RGBA', (232 * len(eyes), 196 * 2), (236, 170, 180, 255))
    for col, (form, (cx, cy, spread, eye_r)) in enumerate(eyes.items()):
        u = eye_r / 3.4
        mouth_bottom = cy + 3.0 * u + 3.8 * u
        for row, sq in enumerate(FRAMES):
            a = body_mask(form, row)
            bottom = np.nonzero(a.any(1))[0].max() - 60
            y = min(mouth_bottom + 3.4, bottom - 6.5)
            left, right = body_row(a, y)
            c = Canvas(forms.W, forms.H, forms.K, forms.F, squash=(1.0, 1.0), anchor=(55, 93))
            small = shrink(c, scarf(c, left, right, y, 7.5))
            out = Image.new('RGBA', (232, 196), (0, 0, 0, 0))
            out.alpha_composite(small.resize((forms.W * 2, forms.H * 2), Image.NEAREST), (60, 60))
            out.save(os.path.join(dest, f'{form}-{row + 1}.png'))
            body = Image.open(os.path.join(PROJ, 'pet', 'forms', f'{form}-{row + 1}.png'))
            prev.alpha_composite(body, (col * 232, row * 196))
            prev.alpha_composite(out, (col * 232, row * 196))
    prev.crop((0, 0, prev.width, 196)).resize((prev.width * 2, 392), Image.NEAREST).save(os.path.join(SCR, 'scarf_preview.png'))
    prev.crop((50, 60, 232 * 2 - 50, 180)).resize(((232 * 2 - 100) * 4, 120 * 4), Image.NEAREST).save(os.path.join(SCR, 'scarf_zoom.png'))
    print('ok')
