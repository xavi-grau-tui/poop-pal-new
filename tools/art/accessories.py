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


def sunglasses(c, cx, cy, spread, eye_r):
    """Cool wayfarer-ish shades: dark lenses, a bold brow bar, two white shine streaks.
    Sized to the face: lenses a bit bigger than the eyes and pushed apart so there is always
    a nose gap between them (on small pals the lenses sit a little outside the eyes)."""
    k = c.k * c.f
    frame = Image.new('RGBA', (c.w * c.k, c.h * c.k), (0, 0, 0, 0))
    lens = Image.new('RGBA', frame.size, (0, 0, 0, 0))
    fd, ld = ImageDraw.Draw(frame), ImageDraw.Draw(lens)
    P = c.P
    ink = (26, 16, 22, 255)
    r = eye_r * 1.45 + 1.3                   # lens half-width
    rw, rh = r * 1.05, r * 0.72
    # keep clear of the mouth: the lenses' inner edges stay outside the mouth's width
    # (face() draws the mouth about 3.2 * eye_r / 3.4 to each side of the centre)
    mouth_half = 3.2 * eye_r / 3.4
    off = max(spread, rw + mouth_half + 1.5)  # lens centre distance from the face centre
    for side in (-1, 1):
        e = cx + side * off
        box = [*P(e - rw, cy - rh), *P(e + rw, cy + rh)]
        ld.rounded_rectangle(box, radius=int(r * 0.5 * k), fill=(44, 34, 58, 255))
        fd.rounded_rectangle(box, radius=int(r * 0.5 * k), outline=ink, width=int(1.8 * k))
        # shine: two short diagonal streaks
        fd.line([P(e - r * .55, cy + r * .1), P(e - r * .1, cy - r * .45)], fill=(255, 255, 255, 255), width=int(1.4 * k))
        fd.line([P(e - r * .05, cy + r * .15), P(e + r * .2, cy - r * .2)], fill=(255, 255, 255, 255), width=int(0.9 * k))
    # brow bar across both lenses (the bridge), and short arms
    fd.line([P(cx - off - rw, cy - rh * .85), P(cx + off + rw, cy - rh * .85)], fill=ink, width=int(2.6 * k))
    for side in (-1, 1):
        x0 = cx + side * (off + rw)
        fd.line([P(x0, cy - rh * .75), P(x0 + side * 4.0, cy - rh * 1.05)], fill=ink, width=int(2.0 * k))
    return frame, lens


def shrink_layers(c, frame, lens, lens_alpha=85):
    W, H = c.w, c.h
    f = np.asarray(frame.resize((W, H), Image.LANCZOS)).copy()
    l = np.asarray(lens.resize((W, H), Image.LANCZOS)).copy()
    solid = f[..., 3] > 110
    out = np.zeros_like(f)
    glass = (l[..., 3] > 128) & ~solid
    if glass.any():
        out[glass] = [*l[glass][0][:3], lens_alpha]
    out[solid] = f[solid]
    out[solid, 3] = 255
    return Image.fromarray(out, 'RGBA')


ACCESSORIES = {
    'sunglasses': (sunglasses, 240),      # (drawing, lens opacity)
}

if __name__ == '__main__':
    eyes = faces()
    for acc, (draw, lens_alpha) in ACCESSORIES.items():
        dest = os.path.join(PROJ, 'pet', 'accessories', acc)
        os.makedirs(dest, exist_ok=True)
        prev = Image.new('RGBA', (232 * len(eyes), 196 * 2), (236, 170, 170, 255))
        for col, (form, (cx, cy, spread, eye_r)) in enumerate(eyes.items()):
            for row, sq in enumerate(FRAMES):
                c = Canvas(forms.W, forms.H, forms.K, forms.F, squash=sq, anchor=(55, 93))
                small = shrink_layers(c, *draw(c, cx, cy, spread, eye_r), lens_alpha)
                out = Image.new('RGBA', (232, 196), (0, 0, 0, 0))
                out.alpha_composite(small.resize((forms.W * 2, forms.H * 2), Image.NEAREST), (60, 60))
                out.save(os.path.join(dest, f'{form}-{row + 1}.png'))
                body = Image.open(os.path.join(PROJ, 'pet', 'forms', f'{form}-{row + 1}.png'))
                prev.alpha_composite(body, (col * 232, row * 196))
                prev.alpha_composite(out, (col * 232, row * 196))
        prev.save(os.path.join(SCR, f'{acc}_preview.png'))
    print('ok', eyes)
