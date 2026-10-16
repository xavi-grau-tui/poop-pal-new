"""Sky backgrounds won in the games (2026-10-16), drop-in replacements for clouds3.png (far) and
clouds2.png (near) like the toilet rolls: 925x924, transparent, soft cream shapes with no
outline, a few at the top and the bottom of the sky.

    sewer_pipes   pipes: elbows with flanges, straight runs with a valve wheel   (Tilt Maze 4-6)
    starfield     stars, twinkles, a ringed planet, a crescent moon              (Tilt Maze 6-6)

    <venv>/bin/python tools/art/bg_games.py   -> textures/pet-background/<id>_far.png, <id>_near.png
                                                 textures/pet-background/icons/<id>.png (the prize card)
"""
import math, os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(HERE, '..', '..', 'textures', 'pet-background')
S = 6                                                   # supersample
CREAM = ((248, 245, 228, 255), (222, 214, 196, 255), (200, 160, 150, 255))
PINKY = ((222, 184, 182, 255), (210, 168, 166, 255), (190, 140, 140, 255))
STAR = ((252, 238, 182, 255), (232, 210, 150, 255), (200, 160, 150, 255))


def canvas(w, h):
    im = Image.new('RGBA', (int(w * S), int(h * S)), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def done(im, angle=0.0):
    if angle:
        im = im.rotate(angle, resample=Image.BICUBIC, expand=False)
    return im.resize((max(1, im.width // S), max(1, im.height // S)), Image.LANCZOS)


def elbow(r, w, pal):
    """a pipe bent a quarter turn, a flange at each end"""
    body, shade, dark = pal
    size = r + w * 1.6
    im, d = canvas(size * 1.3, size * 1.3)
    o = w * .9 * S
    box = [o, o, o + 2 * r * S, o + 2 * r * S]
    d.arc(box, 180, 270, fill=body, width=int(w * S))
    inner = [box[0] + w * S * .55, box[1] + w * S * .55, box[2] - w * S * .55, box[3] - w * S * .55]
    d.arc(inner, 180, 270, fill=shade, width=int(w * S * .35))
    cx, cy = o + r * S, o + r * S
    for (x, y, horiz) in ((o + w * S * .05, cy, False), (cx, o + w * S * .05, True)):
        fw, fh = (w * 1.45 * S, w * .5 * S) if not horiz else (w * .5 * S, w * 1.45 * S)
        if horiz:
            d.rounded_rectangle([x - fw / 2, y - fh / 2 + w * S * .5, x + fw / 2, y + fh / 2 + w * S * .5], radius=int(w * S * .15), fill=body)
        else:
            d.rounded_rectangle([x - fw / 2 + w * S * .5, y - fh / 2, x + fw / 2 + w * S * .5, y + fh / 2], radius=int(w * S * .15), fill=body)
    return done(im)


def straight(ln, w, pal, wheel=True):
    """a straight run of pipe with a flange at each end and a valve wheel on top"""
    body, shade, dark = pal
    im, d = canvas(ln + w * 2, w * 4.2)
    y = w * 2.6 * S
    d.rectangle([w * S, y - w * S / 2, (ln + w) * S, y + w * S / 2], fill=body)
    d.rectangle([w * S, y + w * S * .12, (ln + w) * S, y + w * S / 2], fill=shade)
    for x in (w * S, (ln + w) * S):
        d.rounded_rectangle([x - w * S * .3, y - w * S * .78, x + w * S * .3, y + w * S * .78], radius=int(w * S * .12), fill=body)
    if wheel:
        cx = (ln / 2 + w) * S
        d.rectangle([cx - w * S * .12, y - w * S * 1.6, cx + w * S * .12, y - w * S * .5], fill=shade)
        r = w * S * .95
        d.ellipse([cx - r, y - w * S * 1.6 - r * .45, cx + r, y - w * S * 1.6 + r * .45], outline=body, width=int(w * S * .28))
    return done(im)


def star(r, pal, points=5, inner=.45):
    body, shade, dark = pal
    im, d = canvas(r * 2.4, r * 2.4)
    c = r * 1.2 * S
    pts = []
    for i in range(points * 2):
        rr = (r if i % 2 == 0 else r * inner) * S
        a = -math.pi / 2 + i * math.pi / points
        pts.append((c + math.cos(a) * rr, c + math.sin(a) * rr))
    d.polygon(pts, fill=body)
    half = [(c, c)] + [p for i, p in enumerate(pts) if pts[i][0] >= c - 1][:points]
    d.polygon([(c + (x - c) * .55 + r * S * .1, c + (y - c) * .55 + r * S * .1) for x, y in pts], fill=shade)
    d.polygon([(c + (x - c) * .45, c + (y - c) * .45) for x, y in pts], fill=body)
    return done(im)


def planet(r, pal, ring=True):
    body, shade, dark = pal
    im, d = canvas(r * 4.0, r * 3.0)
    cx, cy = r * 2.0 * S, r * 1.5 * S
    if ring:
        d.ellipse([cx - r * 1.9 * S, cy - r * .55 * S, cx + r * 1.9 * S, cy + r * .55 * S], outline=shade, width=int(r * .28 * S))
    d.ellipse([cx - r * S, cy - r * S, cx + r * S, cy + r * S], fill=body)
    d.chord([cx - r * S, cy - r * S, cx + r * S, cy + r * S], 300, 120, fill=shade)
    d.ellipse([cx - r * .82 * S, cy - r * .82 * S, cx + r * .62 * S, cy + r * .62 * S], fill=body)
    if ring:                                             # (the ring passes in front, below)
        d.arc([cx - r * 1.9 * S, cy - r * .55 * S, cx + r * 1.9 * S, cy + r * .55 * S], 20, 160, fill=body, width=int(r * .28 * S))
    return done(im)


def moon(r, pal):
    body, shade, dark = pal
    im, d = canvas(r * 2.4, r * 2.4)
    c = r * 1.2 * S
    d.ellipse([c - r * S, c - r * S, c + r * S, c + r * S], fill=body)
    d.ellipse([c - r * .35 * S, c - r * 1.15 * S, c + r * 1.45 * S, c + r * .75 * S], fill=(0, 0, 0, 0))
    return done(im)


def sparkle(r, pal):
    body, shade, dark = pal
    im, d = canvas(r * 2.4, r * 2.4)
    c = r * 1.2 * S
    pts = []
    for i in range(8):
        rr = (r if i % 2 == 0 else r * .26) * S
        a = i * math.pi / 4
        pts.append((c + math.cos(a) * rr, c + math.sin(a) * rr))
    d.polygon(pts, fill=body)
    return done(im)


def layer(items, out):
    cv = Image.new('RGBA', (925, 924), (0, 0, 0, 0))
    for (x, y, im, ang) in items:
        im = im.rotate(ang, resample=Image.BICUBIC, expand=True) if ang else im
        cv.alpha_composite(im, (int(x - im.width / 2), int(y - im.height / 2)))
    a = cv.split()[3].point(lambda v: 255 if v > 110 else 0)   # hard edge like the clouds
    cv.putalpha(a)
    cv.save(os.path.join(DEST, out))
    return cv


def icon(far, near, out):
    sky = Image.new('RGBA', (925, 924), (229, 165, 166, 255))
    sky.alpha_composite(far)
    sky.alpha_composite(near)
    sky.crop((120, 0, 520, 380)).resize((96, 91), Image.LANCZOS).save(out)


if __name__ == '__main__':
    os.makedirs(os.path.join(DEST, 'icons'), exist_ok=True)
    # sewer pipes
    far = [(300, 60, elbow(14, 7, PINKY), 0), (470, 120, straight(40, 6, PINKY, False), 12), (90, 170, elbow(12, 6, PINKY), 90),
           (840, 110, straight(34, 6, PINKY), -8), (80, 690, straight(36, 6, PINKY), 6), (860, 680, elbow(14, 7, PINKY), 180)]
    near = [(270, 170, straight(70, 14, CREAM), 6), (700, 70, elbow(26, 13, CREAM), 270), (200, 800, elbow(26, 13, CREAM), 0),
            (790, 800, straight(64, 13, CREAM), -10)]
    a = layer(far, 'sewer_pipes_far.png')
    b = layer(near, 'sewer_pipes_near.png')
    icon(a, b, os.path.join(DEST, 'icons', 'sewer_pipes.png'))
    # the starfield
    far = [(310, 50, sparkle(9, PINKY), 0), (450, 80, star(7, PINKY), 15), (80, 150, sparkle(8, PINKY), 0), (620, 160, star(6, PINKY), -10),
           (835, 115, sparkle(9, PINKY), 0), (70, 700, star(7, PINKY), 10), (860, 670, sparkle(10, PINKY), 0), (520, 860, star(6, PINKY), 20)]
    near = [(280, 175, star(24, STAR), 8), (700, 80, planet(26, CREAM), -14), (200, 790, moon(30, CREAM), 0),
            (800, 800, star(22, STAR), -12), (520, 40, sparkle(14, STAR), 0), (90, 60, sparkle(12, STAR), 0)]
    a = layer(far, 'starfield_far.png')
    b = layer(near, 'starfield_near.png')
    icon(a, b, os.path.join(DEST, 'icons', 'starfield.png'))
    out = os.path.join(HERE, 'out')
    os.makedirs(out, exist_ok=True)
    prev = Image.new('RGBA', (925 * 2, 924), (229, 165, 166, 255))
    for i, n in enumerate(['sewer_pipes', 'starfield']):
        prev.alpha_composite(Image.open(os.path.join(DEST, n + '_far.png')), (i * 925, 0))
        prev.alpha_composite(Image.open(os.path.join(DEST, n + '_near.png')), (i * 925, 0))
    prev.resize((925, 462)).save(os.path.join(out, 'bg_games_preview.png'))
    print('ok')
