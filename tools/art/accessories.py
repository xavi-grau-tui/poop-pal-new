"""Pal accessories, rendered per form so they sit exactly on each face.

Each output has the same canvas as the form sprites (232x196, same anchor), one file per
animation frame, so in game the accessory is just a child sprite at offset 0 that follows
the pal's frame. Face positions are read by running forms.py with face() patched.
"""
import os
import numpy as np
from PIL import Image, ImageDraw

import forms
from hires import Canvas, PROJ, SCR

FRAMES = [(1.0, 1.0), (1.03, 0.95)]      # same squash as forms.py


def faces():
    """{form: (cx, cy, spread, eye_r)} straight from the form definitions."""
    found = {}
    real = forms.face
    for name, fn in forms.FORMS.items():
        def spy(c, cx, cy, spread=10, style='happy', eye_r=3.4, _n=name):
            found[_n] = (cx, cy, spread, eye_r)
        forms.face = spy
        fn(Canvas(forms.W, forms.H, forms.K, forms.F))   # full run (forms.py assumes K), only to catch the face call
    forms.face = real
    return found


def round_glasses(c, cx, cy, spread, eye_r):
    """Returns (frame, lens) hi-res RGBA images: thick dark rims + a pale tinted lens."""
    k = c.k * c.f
    frame = Image.new('RGBA', (c.w * c.k, c.h * c.k), (0, 0, 0, 0))
    lens = Image.new('RGBA', frame.size, (0, 0, 0, 0))
    fd, ld = ImageDraw.Draw(frame), ImageDraw.Draw(lens)
    P = c.P
    r = eye_r * 1.45 + 1.0
    rim = 2.4                                   # design units (1 unit = 1 screen texel)
    for e in (cx - spread, cx + spread):
        box = [*P(e - r, cy - r), *P(e + r, cy + r)]
        fd.ellipse(box, outline=(30, 18, 22, 255), width=int(rim * k))
        ld.ellipse(box, fill=(190, 225, 255, 255))
        # glint, top-left of each lens
        fd.line([P(e - r * .55, cy - r * .15), P(e - r * .2, cy - r * .55)], fill=(255, 255, 255, 255), width=int(1.3 * k))
    # bridge + short arms
    fd.arc([*P(cx - spread + r - 1, cy - 4.5), *P(cx + spread - r + 1, cy + 2.5)], 200, 340, fill=(30, 18, 22, 255), width=int(rim * k))
    for side in (-1, 1):
        x0 = cx + side * (spread + r - .5)
        fd.line([P(x0, cy - r * .35), P(x0 + side * 4.5, cy - r * .55)], fill=(30, 18, 22, 255), width=int(rim * k))
    return frame, lens


def shrink_layers(c, frame, lens, lens_alpha=85):
    W, H = c.w, c.h
    f = np.asarray(frame.resize((W, H), Image.LANCZOS)).copy()
    l = np.asarray(lens.resize((W, H), Image.LANCZOS)).copy()
    solid = f[..., 3] > 110
    out = np.zeros_like(f)
    glass = (l[..., 3] > 128) & ~solid
    out[glass] = [*l[glass][0][:3], lens_alpha] if glass.any() else 0
    out[solid] = f[solid]
    out[solid, 3] = 255
    return Image.fromarray(out, 'RGBA')


ACCESSORIES = {'round_glasses': round_glasses}

if __name__ == '__main__':
    eyes = faces()
    for acc, draw in ACCESSORIES.items():
        dest = os.path.join(PROJ, 'pet', 'accessories', acc)
        os.makedirs(dest, exist_ok=True)
        prev = Image.new('RGBA', (232 * len(eyes), 196 * 2), (236, 170, 170, 255))
        for col, (form, (cx, cy, spread, eye_r)) in enumerate(eyes.items()):
            for row, sq in enumerate(FRAMES):
                c = Canvas(forms.W, forms.H, forms.K, forms.F, squash=sq, anchor=(55, 93))
                small = shrink_layers(c, *draw(c, cx, cy, spread, eye_r))
                out = Image.new('RGBA', (232, 196), (0, 0, 0, 0))
                out.alpha_composite(small.resize((forms.W * 2, forms.H * 2), Image.NEAREST), (60, 60))
                out.save(os.path.join(dest, f'{form}-{row + 1}.png'))
                body = Image.open(os.path.join(PROJ, 'pet', 'forms', f'{form}-{row + 1}.png'))
                prev.alpha_composite(body, (col * 232, row * 196))
                prev.alpha_composite(out, (col * 232, row * 196))
        prev.save(os.path.join(SCR, f'{acc}_preview.png'))
    print('ok', eyes)
