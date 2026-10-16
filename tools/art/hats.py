"""Head-worn dress-ups won in the games (2026-10-16): one image per form and frame, on the same
232x196 canvas as the form sprites (in game a child sprite at offset 0, like the headphones), and a
32x32 icon for the menus. Each one is fitted to the pal it's on: the body's outline is read from
the form sprite's alpha, the face from tools/art/pal_faces.json.

    hard_hat      a builder's helmet on top                    (Tilt Maze 5-8)
    headlamp      an elastic band with a lamp, over the eyes   (Tilt Maze 4-8)
    snorkel       a diving mask round the eyes, a snorkel      (Tilt Maze 2-8)
    hachimaki     a white headband with the red sun, knotted   (Top Spin 5-6)
    sumo_topknot  oiled hair and a topknot (a chonmage)        (Paper Sumo 6-6)

    <venv>/bin/python tools/art/hats.py [ids]   -> textures/pet/accessories/<id>/<form>-<n>.png
                                                   textures/pet/accessories/icons/<id>.png
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw

from scipy.ndimage import binary_opening

import forms
from hires import Canvas, PROJ, SCR
from accessories import FRAMES, faces

INK = (34, 20, 22, 255)
K = forms.K * forms.F                                  # hi-res px per design unit


def body_mask(form, row):
    """the body (design units: 110 x 100) from the form sprite's alpha, without its thin parts
    (leaves, stalks, antennae: what a hat sits on is the head)"""
    a = np.asarray(Image.open(os.path.join(PROJ, 'pet', 'forms', f'{form}-{row + 1}.png')))[..., 3] > 40
    m = a[60:160, 60:170]
    o = binary_opening(m, iterations=4)
    return o if o.sum() > m.sum() * .6 else m


def span(m, y):
    """(left, right) of the body at design height y"""
    yy = int(np.clip(round(y), 0, m.shape[0] - 1))
    xs = np.nonzero(m[yy])[0]
    if not len(xs):
        return 40.0, 70.0
    return float(xs.min()), float(xs.max() + 1)


def tops(m):
    """the body's top edge at every x (design units; 999 where there's no body)"""
    t = np.full(m.shape[1], 999.0)
    for x in range(m.shape[1]):
        ys = np.nonzero(m[:, x])[0]
        if len(ys):
            t[x] = ys.min()
    return t


def head(m):
    """the head: the body from the first row that's at least half its widest down (a leaf, a stalk,
    antennae above it are cut off: a hat sits on the head, over them)"""
    widths = m.sum(1)
    ht = int(np.nonzero(widths >= widths.max() * .5)[0].min())
    hm = m.copy()
    hm[:max(0, ht - 1)] = False
    return hm


def geo(m):
    ys, xs = np.nonzero(m)
    left, right = float(xs.min()), float(xs.max() + 1)
    mid = (left + right) / 2
    near = np.abs(xs - mid) < (right - left) * 0.3     # the head's top, not a side sprout
    return left, right, float(ys[near].min()), mid


def layer(c):
    im = Image.new('RGBA', (c.w * c.k, c.h * c.k), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def band_pts(c, m, y, sag=1.4):
    """a band across the head at y, from edge to edge, curving down a little at its ends"""
    l, r = span(m, y)
    return [c.P(l - .5, y + sag), c.P((l * 2 + r) / 3, y + sag * .25), c.P((l + r * 2) / 3, y + sag * .25), c.P(r + .5, y + sag)], l, r


def hard_hat(c, m, f):
    cx, cy, sp, er = f
    left, right, top, mid = geo(head(m))
    hw = max(13.0, (right - left) * .4)
    brim = min(top + 10.0, cy - er * 1.35 - 2.5)
    dh = min(max(12.0, hw * .82), brim - 1.0)               # the dome's height above the brim
    im, d = layer(c)
    yellow, shade, light = (246, 196, 52, 255), (214, 152, 34, 255), (255, 236, 150, 255)
    dome = [*c.P(mid - hw, brim - dh), *c.P(mid + hw, brim + dh)]
    d.chord(dome, 180, 360, fill=yellow, outline=INK, width=int(2.0 * K))
    d.rounded_rectangle([*c.P(mid - 2.6, brim - dh + 1.5), *c.P(mid + 2.6, brim - .6)], radius=int(2 * K), fill=light)
    d.arc([*c.P(mid - hw + 3, brim - dh + 2.5), *c.P(mid + hw - 3, brim + dh - 2)], 200, 245, fill=(255, 250, 220, 255), width=int(1.6 * K))
    d.rounded_rectangle([*c.P(mid - hw * 1.22, brim - 2.2), *c.P(mid + hw * 1.22, brim + 2.6)], radius=int(2.4 * K), fill=shade, outline=INK, width=int(2.0 * K))
    return im


def headlamp(c, m, f):
    cx, cy, sp, er = f
    y = cy - er * 1.3 - 3.5
    im, d = layer(c)
    pts, l, r = band_pts(c, m, y)
    d.line(pts, fill=INK, width=int(5.6 * K), joint='curve')
    d.line(pts, fill=(72, 74, 90, 255), width=int(3.2 * K), joint='curve')
    lx = cx
    d.rounded_rectangle([*c.P(lx - 6.5, y - 4.6), *c.P(lx + 6.5, y + 4.2)], radius=int(2.6 * K), fill=(150, 156, 172, 255), outline=INK, width=int(2.0 * K))
    d.ellipse([*c.P(lx - 3.4, y - 3.2), *c.P(lx + 3.4, y + 3.0)], fill=(255, 238, 160, 255), outline=INK, width=int(1.2 * K))
    d.ellipse([*c.P(lx - 1.6, y - 1.8), *c.P(lx + .6, y + .2)], fill=(255, 255, 255, 255))
    return im


def snorkel(c, m, f):
    cx, cy, sp, er = f
    im, d = layer(c)
    x0, x1 = cx - sp - er * 1.9, cx + sp + er * 1.9
    y0, y1 = cy - er * 1.75, cy + er * 1.5
    l, r = span(m, cy - er * .2)
    for (a_, b_) in ((l - .5, x0 + 1.0), (x1 - 1.0, r + .5)):                    # the strap, out from the mask
        if b_ > a_:
            d.line([c.P(a_, cy - er * .2 + .4), c.P(b_, cy - er * .2)], fill=INK, width=int(4.6 * K))
            d.line([c.P(a_, cy - er * .2 + .4), c.P(b_, cy - er * .2)], fill=(60, 64, 80, 255), width=int(2.4 * K))
    box = [*c.P(x0, y0), *c.P(x1, y1)]
    d.rounded_rectangle(box, radius=int(4.2 * K), outline=INK, width=int(5.4 * K))   # the mask's frame
    d.rounded_rectangle(box, radius=int(4.2 * K), outline=(240, 112, 92, 255), width=int(2.8 * K))
    d.line([c.P(cx, y0 + .5), c.P(cx, y0 + 2.6)], fill=INK, width=int(1.6 * K))
    d.line([c.P(x0 + 2.6, y0 + 2.4), c.P(x0 + 5.2, y0 + 1.6)], fill=(255, 255, 255, 255), width=int(1.3 * K))   # glints
    d.line([c.P(cx + 2.2, y0 + 2.4), c.P(cx + 4.8, y0 + 1.6)], fill=(255, 255, 255, 255), width=int(1.3 * K))
    _, _, top, _ = geo(m)
    tx = min(r - 1.5, x1 + 2.5)
    tube = [c.P(x1 - .5, cy + er * .3), c.P(tx + 1.0, cy - er * .2), c.P(tx + 3.0, top + 4.0), c.P(tx + 2.0, top - 9.0)]
    d.line(tube, fill=INK, width=int(7.4 * K), joint='curve')                     # the snorkel
    d.line(tube, fill=(132, 214, 96, 255), width=int(4.4 * K), joint='curve')
    d.line([c.P(tx + 1.6, cy - er * .2), c.P(tx + 3.2, top + 4.0)], fill=(196, 244, 160, 255), width=int(1.2 * K))
    d.ellipse([*c.P(tx - .4, top - 13.0), *c.P(tx + 4.6, top - 8.0)], fill=(250, 150, 60, 255), outline=INK, width=int(1.6 * K))
    return im


def hachimaki(c, m, f):
    cx, cy, sp, er = f
    y = cy - er * 1.35 - 4.0
    im, d = layer(c)
    pts, l, r = band_pts(c, m, y)
    d.line(pts, fill=INK, width=int(7.6 * K), joint='curve')
    d.line(pts, fill=(250, 248, 240, 255), width=int(5.0 * K), joint='curve')
    d.ellipse([*c.P(cx - 3.0, y - 2.7), *c.P(cx + 3.0, y + 2.9)], fill=(222, 54, 52, 255))      # the red sun
    kx = r - 1.0
    for ang, ln in ((25, 9.5), (55, 8.0)):                               # the knot's two tails
        a = np.radians(ang)
        tip = (kx + np.cos(a) * ln, y + 1 + np.sin(a) * ln)
        poly = [c.P(kx, y - 1.2), c.P(tip[0] + .8, tip[1] - 1.6), c.P(tip[0] - .6, tip[1] + 1.4), c.P(kx, y + 1.6)]
        d.polygon(poly, fill=(250, 248, 240, 255), outline=INK, width=int(1.6 * K))
    d.ellipse([*c.P(kx - 2.6, y - 2.4), *c.P(kx + 2.6, y + 2.6)], fill=(250, 248, 240, 255), outline=INK, width=int(1.8 * K))
    return im


def sumo_topknot(c, m, f):
    """the hair: a cap of oiled black hair over the head's top (following its curve, down to a line
    above the eyes, thinner at the sides), a sheen; the topknot folded on top, tied with white paper"""
    cx, cy, sp, er = f
    hm = head(m)
    left, right, top, mid = geo(hm)
    t = tops(hm)
    hw = (right - left) * .5
    floor_y = cy - er * 1.45                                 # (never over the eyes)
    hi = Image.new('L', (c.w * c.k, c.h * c.k), 0)
    hd = ImageDraw.Draw(hi)
    edge = []
    for x in range(m.shape[1]):
        if t[x] > 900:
            continue
        u = (x + .5 - mid) / hw
        if abs(u) > .97:
            continue
        y_end = min(t[x] + 8.0 * (1 - .55 * u * u), floor_y)
        if y_end > t[x] + .5:
            hd.rectangle([*c.P(x, t[x] - .5), *c.P(x + 1, y_end)], fill=255)
            edge.append(c.P(x + .5, y_end))
    im, d = layer(c)
    im.paste(Image.new('RGBA', im.size, (44, 34, 44, 255)), (0, 0), hi)
    d = ImageDraw.Draw(im)
    if len(edge) > 1:
        d.line(edge, fill=INK, width=int(1.6 * K), joint='curve')             # the hair's edge
    d.arc([*c.P(mid - hw * .7, top + 1.2), *c.P(mid + hw * .4, top + 12.0)], 200, 255, fill=(124, 114, 136, 255), width=int(1.5 * K))   # sheen
    d.ellipse([*c.P(mid - 7.0, top - 6.0), *c.P(mid + 7.0, top + .2)], fill=(44, 34, 44, 255), outline=INK, width=int(1.8 * K))
    d.ellipse([*c.P(mid - 4.5, top - 5.0), *c.P(mid + 1.0, top - 3.0)], fill=(110, 100, 120, 255))
    d.line([c.P(mid, top - .6), c.P(mid, top + 2.0)], fill=(250, 248, 240, 255), width=int(1.6 * K))
    return im


ITEMS = {'hard_hat': hard_hat, 'headlamp': headlamp, 'snorkel': snorkel, 'hachimaki': hachimaki, 'sumo_topknot': sumo_topknot}
ICON_PAL = 'bud'                                         # (the icon: the item as it sits on Bud)


def shrink(c, im):
    f = np.asarray(im.resize((c.w, c.h), Image.LANCZOS)).copy()
    solid = f[..., 3] > 110
    out = np.zeros_like(f)
    out[solid] = f[solid]
    out[solid, 3] = 255
    return Image.fromarray(out, 'RGBA')


def framed_face(face, sq):
    cx, cy, sp, er = face
    return (55 + (cx - 55) * sq[0], 93 - (93 - cy) * sq[1], sp * sq[0], er)


if __name__ == '__main__':
    only = sys.argv[1:] or list(ITEMS)
    eyes = faces()
    for item in only:
        fn = ITEMS[item]
        dest = os.path.join(PROJ, 'pet', 'accessories', item)
        os.makedirs(dest, exist_ok=True)
        sample = [k for k in eyes][:: max(1, len(eyes) // 14)][:14]
        prev = Image.new('RGBA', (232 * len(sample), 196), (120, 70, 110, 255))
        for form, face in eyes.items():
            for row, sq in enumerate(FRAMES):
                m = body_mask(form, row)
                c = Canvas(forms.W, forms.H, forms.K, forms.F, squash=(1.0, 1.0), anchor=(55, 93))
                small = shrink(c, fn(c, m, framed_face(face, sq)))
                out = Image.new('RGBA', (232, 196), (0, 0, 0, 0))
                out.alpha_composite(small.resize((forms.W * 2, forms.H * 2), Image.NEAREST), (60, 60))
                out.save(os.path.join(dest, f'{form}-{row + 1}.png'))
                if row == 0 and form in sample:
                    i = sample.index(form)
                    prev.alpha_composite(Image.open(os.path.join(PROJ, 'pet', 'forms', f'{form}-1.png')), (i * 232, 0))
                    prev.alpha_composite(out, (i * 232, 0))
                if row == 0 and form == ICON_PAL:
                    bb = out.getbbox()
                    ic = out.crop(bb)
                    k = 28 / max(ic.size)
                    ic = ic.resize((max(1, round(ic.width * k)), max(1, round(ic.height * k))), Image.LANCZOS)
                    a = np.asarray(ic).copy()
                    a[..., 3] = np.where(a[..., 3] > 110, 255, 0)
                    icon = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
                    icon.alpha_composite(Image.fromarray(a, 'RGBA'), ((32 - ic.width) // 2, (32 - ic.height) // 2))
                    icon.save(os.path.join(PROJ, 'pet', 'accessories', 'icons', f'{item}.png'))
        os.makedirs(SCR, exist_ok=True)
        prev.save(os.path.join(SCR, f'{item}_preview.png'))
        print(item, 'ok', flush=True)
