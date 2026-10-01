"""Bubbles background layers (a LUCKY PINCH prize), drop-in replacements for clouds3.png
(far) and clouds2.png (near): 925x924, transparent, soft cream shapes with hard edges and no
outline, like the clouds and the toilet rolls. Near: big soap bubbles (a ring with a shine);
far: small pinkish ones.

    python3 tools/art/bubbles.py   -> textures/pet-background/bubbles_far.png, bubbles_near.png
"""
from PIL import Image, ImageDraw
import os
HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(HERE, '..', '..', 'textures', 'pet-background')
S = 6   # supersample


def bubble(r, ring, shine, fill_a, col):
    W = int(r * 2 + 8) * S
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = W / 2
    R = r * S
    d.ellipse([c - R, c - R, c + R, c + R], fill=col[:3] + (fill_a,))         # faint soap film
    d.ellipse([c - R, c - R, c + R, c + R], outline=col, width=int(ring * S))
    # shine: a short bright arc top-left and a dot
    d.arc([c - R * 0.72, c - R * 0.72, c + R * 0.72, c + R * 0.72], 200, 250, fill=(255, 255, 250, 255), width=int(shine * S))
    d.ellipse([c - R * 0.62, c - R * 0.12, c - R * 0.42, c + R * 0.08], fill=(255, 255, 250, 255))
    return im.resize((W // S, W // S), Image.LANCZOS)


def layer(items, out):
    canvas = Image.new('RGBA', (925, 924), (0, 0, 0, 0))
    for (x, y, r, ring, shine, fill_a, col) in items:
        b = bubble(r, ring, shine, fill_a, col)
        canvas.alpha_composite(b, (int(x - b.width / 2), int(y - b.height / 2)))
    # hard edges like the clouds, but the soap film stays see-through
    a = canvas.split()[3].point(lambda v: 255 if v > 140 else (70 if v > 22 else 0))
    canvas.putalpha(a)
    canvas.save(os.path.join(DEST, out))
    return canvas


CREAM = (248, 245, 228, 255)
PINKY = (226, 190, 196, 255)
near = [(250, 150, 40, 8, 6, 50, CREAM), (340, 215, 16, 6, 4, 50, CREAM), (700, 85, 32, 8, 6, 50, CREAM),
        (190, 795, 34, 8, 6, 50, CREAM), (790, 785, 42, 8, 6, 50, CREAM), (870, 712, 15, 6, 4, 50, CREAM)]
far = [(320, 52, 11, 4, 3, 40, PINKY), (440, 76, 8, 4, 3, 40, PINKY), (80, 150, 10, 4, 3, 40, PINKY),
       (835, 120, 9, 4, 3, 40, PINKY), (70, 690, 11, 4, 3, 40, PINKY), (860, 660, 8, 4, 3, 40, PINKY),
       (560, 870, 9, 4, 3, 40, PINKY)]
a = layer(far, 'bubbles_far.png')
b = layer(near, 'bubbles_near.png')
prev = Image.new('RGBA', (925, 924), (236, 170, 180, 255))
prev.alpha_composite(a)
prev.alpha_composite(b)
os.makedirs(os.path.join(HERE, 'out'), exist_ok=True)
prev.resize((462, 462), Image.NEAREST).save(os.path.join(HERE, 'out', 'bubbles_preview.png'))
print('ok')
