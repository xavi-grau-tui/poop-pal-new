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
    # ...and every pal made by forms_gen.py (the evolution tree)
    import forms_gen
    found.update(forms_gen.faces())
    return found


def _lens_centres(cx, spread, half_w, u):
    """Lens centres: over the eyes, but never closer than a nose-bridge gap apart."""
    off = max(spread, half_w + 1.3 * u)
    return (cx - off, cx + off), off


def round_glasses(c, cx, cy, spread, eye_r):
    """Round specs: thin dark rims, a pale blue tint you can see the eyes through, a glint,
    an arched bridge over the nose and short arms."""
    k = c.k * c.f
    frame = Image.new('RGBA', (c.w * c.k, c.h * c.k), (0, 0, 0, 0))
    lens = Image.new('RGBA', frame.size, (0, 0, 0, 0))
    fd, ld = ImageDraw.Draw(frame), ImageDraw.Draw(lens)
    P = c.P
    ink = (30, 18, 22, 255)
    u = eye_r / 3.4
    r = 4.7 * u + 0.6
    lcy = cy - 0.3 * u
    (e0, e1), off = _lens_centres(cx, spread, r, u)
    for e in (e0, e1):
        box = [*P(e - r, lcy - r), *P(e + r, lcy + r)]
        ld.ellipse(box, fill=(196, 228, 255, 255))
        fd.ellipse(box, outline=ink, width=int(1.7 * k))
        fd.line([P(e - r * .6, lcy - r * .05), P(e - r * .2, lcy - r * .5)], fill=(255, 255, 255, 255), width=int(1.2 * k))
    # bridge: a little arch over the nose
    fd.arc([*P(e0 + r - .6, lcy - 2.6 * u), *P(e1 - r + .6, lcy + 1.6 * u)], 200, 340, fill=ink, width=int(1.7 * k))
    for side, e in ((-1, e0), (1, e1)):
        x0 = e + side * (r - .3)
        fd.line([P(x0, lcy - r * .3), P(x0 + side * 2.6, lcy - r * .5)], fill=ink, width=int(1.7 * k))
    return frame, lens


def sunglasses(c, cx, cy, spread, eye_r):
    """Classic shades: two big lenses with a flat top and a round bottom (wider than the
    eyes, covering them), a bold top rim joined over the nose by a slim bridge, a dark plum
    tint fading lighter towards the bottom, a white glint on each lens. They sit on the eyes
    and stop above the mouth; the inner bottom corners curve away from it."""
    k = c.k * c.f
    frame = Image.new('RGBA', (c.w * c.k, c.h * c.k), (0, 0, 0, 0))
    lens = Image.new('RGBA', frame.size, (0, 0, 0, 0))
    fd, ld = ImageDraw.Draw(frame), ImageDraw.Draw(lens)
    P = c.P
    ink = (26, 16, 22, 255)
    u = eye_r / 3.4
    hw = 4.9 * u + 0.5                         # lens half-width
    top = cy - 4.1 * u                         # flat top edge
    bot = cy + 3.3 * u                         # round bottom (the mouth starts lower)
    (e0, e1), off = _lens_centres(cx, spread, hw, u)

    def lens_shape(d, e, grow, fill=None, outline=None, width=0):
        # flat top + a half-ellipse bottom, as one polygon
        pts = [P(e - hw - grow, top - grow), P(e + hw + grow, top - grow)]
        ry = bot - top - hw * 0.35
        for a in np.linspace(0, np.pi, 24):
            pts.append(P(e + (hw + grow) * np.cos(a), top + hw * 0.35 + (ry + grow) * np.sin(a)))
        d.polygon(pts, fill=fill, outline=outline, width=width)

    for e in (e0, e1):
        lens_shape(fd, e, 1.5, fill=ink)              # the rim (lens drawn on top of it)
    for e in (e0, e1):
        # tint: darker at the top, a touch lighter at the bottom
        for i, col in enumerate([(40, 30, 58), (54, 42, 76), (72, 56, 98)]):
            band = Image.new('RGBA', frame.size, (0, 0, 0, 0))
            lens_shape(ImageDraw.Draw(band), e, 0, fill=(*col, 255))
            y0 = P(0, top + (bot - top) * i / 3.0)[1]
            band_a = np.asarray(band).copy()
            band_a[: int(y0)] = 0
            fd.bitmap((0, 0), Image.fromarray(band_a[..., 3]), fill=(*col, 255))
        # glint
        fd.line([P(e - hw * .55, top + (bot - top) * .62), P(e - hw * .05, top + (bot - top) * .12)], fill=(255, 255, 255, 255), width=int(1.4 * k))
        fd.line([P(e + hw * .1, top + (bot - top) * .55), P(e + hw * .35, top + (bot - top) * .25)], fill=(255, 255, 255, 255), width=int(0.9 * k))
    # bold top rim across, the bridge, short arms
    fd.line([P(e0 - hw - 1.2, top - .4), P(e1 + hw + 1.2, top - .4)], fill=ink, width=int(2.6 * k))
    for side, e in ((-1, e0), (1, e1)):
        x0 = e + side * (hw + 1.0)
        fd.line([P(x0, top + .2), P(x0 + side * 2.4, top - 1.2)], fill=ink, width=int(2.0 * k))
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
    'sunglasses': (sunglasses, 255),      # (drawing, lens opacity)
    'round_glasses': (round_glasses, 90),
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
