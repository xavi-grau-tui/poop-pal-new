"""Toilet-paper-roll background layers, drop-in replacements for clouds3.png (far) and
clouds2.png (near): 925x924, transparent, soft cream shapes with no outline, like the clouds."""
from PIL import Image, ImageDraw, ImageFilter
import os, math
HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(HERE, '..', '..', 'textures', 'pet-background')
S = 6   # supersample

def roll(w, h, body, shade, hole, sheet_len, angle):
    """one roll: cylinder standing up, seen slightly from above, with a loose sheet hanging."""
    W, H = int(w * 2.2) * S, int((h + sheet_len) * 1.6) * S
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    cx, top = W // 2, int(h * 0.25 * S)
    rx, ry = w / 2 * S, w * 0.22 * S
    bot = top + h * S
    # hanging sheet from the right side
    sx = cx + rx * 0.55
    d.polygon([(sx - 8*S, bot - h*0.4*S), (sx + 10*S, bot - h*0.4*S), (sx + 12*S, bot + sheet_len*S), (sx - 6*S, bot + sheet_len*S)], fill=shade)
    for i in range(3):   # perforation dashes
        yy = bot + (i + 1) * sheet_len * S / 4
        d.line([(sx - 4*S, yy), (sx + 8*S, yy)], fill=body, width=S)
    # body
    d.rectangle([cx - rx, top, cx + rx, bot], fill=body)
    d.ellipse([cx - rx, bot - ry, cx + rx, bot + ry], fill=body)
    d.rectangle([cx + rx * 0.45, top, cx + rx, bot], fill=shade)                  # shaded side
    d.pieslice([cx - rx, bot - ry, cx + rx, bot + ry], -35, 0, fill=shade)
    # top face + hole
    d.ellipse([cx - rx, top - ry, cx + rx, top + ry], fill=(255, 255, 250, 255))
    d.ellipse([cx - rx*0.38, top - ry*0.38, cx + rx*0.38, top + ry*0.38], fill=hole)
    im = im.rotate(angle, resample=Image.BICUBIC, expand=False)
    return im.resize((W // S, H // S), Image.LANCZOS)

def layer(items, out):
    canvas = Image.new('RGBA', (925, 924), (0, 0, 0, 0))
    for (x, y, w, h, sheet, ang, pal) in items:
        r = roll(w, h, *pal, sheet, ang)
        canvas.alpha_composite(r, (int(x - r.width / 2), int(y - r.height / 2)))
    a = canvas.split()[3].point(lambda v: 255 if v > 110 else 0)   # hard edge like the clouds
    canvas.putalpha(a)
    canvas.save(os.path.join(DEST, out)); return canvas

CREAM = ((248, 245, 228, 255), (222, 214, 196, 255), (200, 160, 150, 255))
PINKY = ((222, 184, 182, 255), (210, 168, 166, 255), (190, 140, 140, 255))
near = [(280, 175, 46, 40, 34, 8, CREAM), (690, 70, 40, 34, 26, -10, CREAM),
        (200, 790, 48, 42, 30, -6, CREAM), (800, 800, 44, 38, 30, 12, CREAM)]
far = [(310, 50, 16, 14, 8, 15, PINKY), (450, 70, 14, 12, 8, -20, PINKY), (80, 150, 14, 12, 6, 30, PINKY),
       (835, 115, 12, 10, 6, -15, PINKY), (70, 700, 16, 14, 8, 10, PINKY), (860, 670, 14, 12, 8, -25, PINKY)]
a = layer(far, 'tprolls_far.png')
b = layer(near, 'tprolls_near.png')
prev = Image.new('RGBA', (925, 924), (236, 170, 170, 255)); prev.alpha_composite(a); prev.alpha_composite(b)
os.makedirs(os.path.join(HERE, 'out'), exist_ok=True)
prev.resize((462, 462), Image.NEAREST).save(os.path.join(HERE, 'out', 'tprolls_preview.png'))
prev.crop((200, 100, 400, 280)).resize((600, 540), Image.NEAREST).save(os.path.join(HERE, 'out', 'tprolls_zoom.png'))
print('ok')
