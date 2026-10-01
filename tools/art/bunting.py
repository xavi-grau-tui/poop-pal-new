"""Gut decor: party bunting along the colon (a LUCKY PINCH prize). Same canvas as
intestine-front.png (a child sprite at position 0, like the fairy lights); two frames = the
little flags flutter.

A string runs along the outer side of the tube and triangular flags in four colours hang
from it, pointing away from the tube.

    python3 tools/art/bunting.py    -> textures/pet/decor/bunting-1.png, -2.png
"""
import math, os
import numpy as np
from PIL import Image, ImageDraw

from hires import PROJ, SCR
from decor import centre_line, SRC, DEST, BLOCK

STRING = (74, 44, 32)
FLAGS = [(250, 206, 110), (150, 220, 190), (190, 164, 218), (236, 150, 92)]
GAP = 92.0                   # px of tube between flags


def render(line, s, radius, frame, size):
    W, H = size
    k = 3
    im = Image.new('RGBA', (W * k, H * k), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tang = np.gradient(line, axis=0)
    tang /= np.linalg.norm(tang, axis=1, keepdims=True)
    normal = np.stack([-tang[:, 1], tang[:, 0]], 1)
    # the string droops between pins (a scallop every GAP*2 px)
    droop = 10.0 * np.abs(np.sin(math.pi * s / (GAP * 2)))
    side = radius * 0.55
    path = line + normal * (side + droop)[:, None]
    for i in range(len(path) - 1):
        d.line([tuple(path[i] * k), tuple(path[i + 1] * k)], fill=STRING + (255,), width=int(10 * k))
    n = 0
    for i in range(len(s)):
        if (s[i] % GAP) >= 2.0:
            continue
        p = path[i]
        t, nrm = tang[i], normal[i]
        flutter = (0.18 if (n + frame) % 2 == 0 else -0.18)
        ang = math.atan2(nrm[1], nrm[0]) + flutter
        out = np.array([math.cos(ang), math.sin(ang)])
        w, h = 52.0, 70.0
        a = p - t * w / 2
        b = p + t * w / 2
        tip = p + out * h
        col = FLAGS[n % len(FLAGS)]
        d.polygon([tuple(a * k), tuple(b * k), tuple(tip * k)], fill=STRING + (255,))
        inset = lambda q: p + (q - p) * 0.78 + out * 3
        d.polygon([tuple(inset(a) * k), tuple(inset(b) * k), tuple(inset(tip) * k)], fill=col + (255,))
        n += 1
    small = im.resize((W // BLOCK, H // BLOCK), Image.LANCZOS)
    arr = np.asarray(small).copy()
    arr[..., 3] = np.where(arr[..., 3] > 130, 255, 0)
    small = Image.fromarray(arr, 'RGBA').resize(((W // BLOCK) * BLOCK, (H // BLOCK) * BLOCK), Image.NEAREST)
    canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    canvas.alpha_composite(small, (0, 0))
    return canvas


if __name__ == '__main__':
    src = Image.open(SRC)
    line, s, radius = centre_line(np.asarray(src)[..., 3])
    prev = Image.new('RGBA', (src.width * 2, src.height), (236, 170, 170, 255))
    for f in range(2):
        img = render(line, s, radius, f, src.size)
        img.save(os.path.join(DEST, f'bunting-{f + 1}.png'))
        prev.alpha_composite(src, (f * src.width, 0))
        prev.alpha_composite(img, (f * src.width, 0))
    prev.resize((prev.width // 2, prev.height // 2)).save(os.path.join(SCR, 'bunting_preview.png'))
    print('ok')
