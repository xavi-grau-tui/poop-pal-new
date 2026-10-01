"""Headphones for TUMMY TUNES: one image per form and frame, on the same 232x196 canvas as
the form sprites (so in game it's a sprite with the same position/scale as the pal).

The cups sit on the body's edges at eye height and the band arcs over the top of the body
(both read from the form sprite's alpha), so every pal shape gets a pair that fits.

    python3 tools/art/headphones.py     -> textures/pet/accessories/headphones/<form>-<n>.png
"""
import os
import numpy as np
from PIL import Image, ImageDraw

import forms
from hires import Canvas, PROJ, SCR
from accessories import FRAMES, faces

INK = (34, 20, 22, 255)
SHELL = (236, 150, 92, 255)       # the main button's orange
SHELL_HI = (252, 206, 150, 255)
PAD = (120, 70, 110, 255)         # plum cushion (the stage colour)
BAND = (74, 44, 32, 255)
BAND_HI = (150, 96, 70, 255)


def body_extents(form, row, cy):
    """(left, right, top, centre) of the body in design units (1 unit = 1 canvas px, origin 60,60)."""
    a = np.asarray(Image.open(os.path.join(PROJ, 'pet', 'forms', f'{form}-{row + 1}.png')))[..., 3] > 40
    ys, xs = np.nonzero(a)
    y = int(round(60 + cy))
    cols = np.nonzero(a[y])[0]
    left, right = cols.min() - 60, cols.max() - 60
    mid = (left + right) / 2
    near = np.abs(xs - 60 - mid) < (right - left) * 0.3        # the head's top, not a side sprout
    top = ys[near].min() - 60
    return left, right, top, mid


def headphones(c, left, right, top, cy):
    k = c.k * c.f
    im = Image.new('RGBA', (c.w * c.k, c.h * c.k), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    P = c.P
    cw, ch = 11.0, 17.0                        # cup size (design units)
    cup_y = cy + 1.0
    xs = (left + 1.0, right - 1.0)            # cups straddle the body's edges
    # band: a thick arc from cup to cup over the head
    pad = 5.0
    box = [*P(xs[0], top - pad), *P(xs[1], cup_y + (cup_y - top + pad))]
    d.arc(box, 180, 360, fill=INK, width=int(7.0 * k))
    inner = [box[0] + 1.8 * k, box[1] + 1.8 * k, box[2] - 1.8 * k, box[3] - 1.8 * k]
    d.arc(inner, 182, 358, fill=BAND, width=int(3.4 * k))
    d.arc([inner[0] + 0.8 * k, inner[1] + 0.8 * k, inner[2] - 0.8 * k, inner[3] - 0.8 * k], 215, 262, fill=BAND_HI, width=int(1.4 * k))
    for side, x in zip((-1, 1), xs):
        # cushion towards the head, shell outside
        sx = x + side * 3.0
        shell = [*P(sx - cw / 2, cup_y - ch / 2), *P(sx + cw / 2, cup_y + ch / 2)]
        cush = [*P(x - side * 2.0 - 3.0, cup_y - ch / 2 + 2.0), *P(x - side * 2.0 + 3.0, cup_y + ch / 2 - 2.0)]
        d.rounded_rectangle(cush, radius=int(2.4 * k), fill=PAD, outline=INK, width=int(2.0 * k))
        d.rounded_rectangle(shell, radius=int(4.0 * k), fill=SHELL, outline=INK, width=int(2.2 * k))
        d.line([P(sx - 2.2, cup_y - ch / 2 + 3.5), P(sx - 2.2, cup_y + 1.0)], fill=SHELL_HI, width=int(2.0 * k))
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
    dest = os.path.join(PROJ, 'pet', 'accessories', 'headphones')
    os.makedirs(dest, exist_ok=True)
    prev = Image.new('RGBA', (232 * len(eyes), 196 * 2), (120, 70, 110, 255))
    for col, (form, (cx, cy, spread, eye_r)) in enumerate(eyes.items()):
        for row, sq in enumerate(FRAMES):
            left, right, top, mid = body_extents(form, row, cy)
            c = Canvas(forms.W, forms.H, forms.K, forms.F, squash=(1.0, 1.0), anchor=(55, 93))
            small = shrink(c, headphones(c, left, right, top, cy))
            out = Image.new('RGBA', (232, 196), (0, 0, 0, 0))
            out.alpha_composite(small.resize((forms.W * 2, forms.H * 2), Image.NEAREST), (60, 60))
            out.save(os.path.join(dest, f'{form}-{row + 1}.png'))
            body = Image.open(os.path.join(PROJ, 'pet', 'forms', f'{form}-{row + 1}.png'))
            prev.alpha_composite(body, (col * 232, row * 196))
            prev.alpha_composite(out, (col * 232, row * 196))
    prev.resize((prev.width * 2, prev.height * 2), Image.NEAREST).save(os.path.join(SCR, 'headphones_preview.png'))
    print('ok')
