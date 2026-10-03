"""The LUCKY PINCH claw that visits the pet cam, painted like the pals (paint big + shrink:
soft 3D shading, glossy highlights, the pals' warm near-black outline), on the pals' own
pixel grid (shown at the pal's scale, so its pixels match the pal's).

    python3 tools/art/claw_visit_art.py
        -> textures/minigames/pinch/visit_claw.png      (hub + prongs, closed round a capsule)
        -> textures/minigames/pinch/visit_capsule.png   (the glowing prize capsule it carries)

The capsule's centre sits at CAP_AT in the claw's canvas.
"""
import os
import numpy as np
from hires import Canvas, material, outline, height, field, shrink, seam, PROJ, SCR

K = 20
W, H = 26, 28
DY = 1.6                                 # (everything sits this much lower in the canvas)
CAP_AT = (13, 17.5 + DY)
CAP_R = 4.6
GOLD = [(110, 62, 26), (176, 120, 44), (226, 176, 78), (250, 214, 120), (255, 244, 200)]
STEEL = [(62, 58, 78), (118, 114, 138), (178, 176, 198), (224, 224, 238), (255, 255, 255)]
YELLOW = [(150, 96, 20), (222, 160, 44), (250, 204, 96), (255, 230, 150), (255, 250, 220)]
CREAM = [(150, 132, 128), (206, 196, 192), (238, 232, 226), (250, 248, 244), (255, 255, 255)]


def tube(c, pts, r):
    """A round tube along a polyline: a field that is 1 at distance r from the line."""
    d = np.full(c.x.shape, 1e9, np.float32)
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        vx, vy = x1 - x0, y1 - y0
        t = np.clip(((c.x - x0) * vx + (c.y - y0) * vy) / (vx * vx + vy * vy), 0, 1)
        dd = np.hypot(c.x - (x0 + t * vx), c.y - (y0 + t * vy))
        d = np.minimum(d, dd)
    return (r / np.maximum(d, 1e-3)) ** 2


def claw():
    c = Canvas(W, H, K, 1.0, anchor=(13, 26))
    c.y = c.y - DY
    left = [(10.5, 9.5), (6.5, 12.5), (4.6, 16.5), (5.2, 20.5), (8.2, 23.2)]
    right = [(W - x, y) for (x, y) in left]
    # the back prong (behind the capsule: it's left out where the capsule will be)
    back = tube(c, [(13, 9), (13, 12.6)], 1.15)
    m = back > 1
    material(c, height(back, .5), m, STEEL, bump=5, spec_amt=.35, grain=.04)
    # hub: a gold dome with a steel collar under it
    hub = field(c, [(13, 5.6, 5.6, 4.4)])
    hm = (hub > 1) & (c.y < 8.6)
    material(c, height(hub, .5), hm, GOLD, bump=5, spec_amt=.6, spec_pow=18, grain=.05)
    col = field(c, [(13, 9.3, 5.8, 1.5)])
    cm = col > 1
    material(c, height(col, .6), cm, STEEL, bump=4, spec_amt=.5, grain=.04)
    seam(c, cm, hm, .5)
    # cable socket on top
    sock = field(c, [(13, 1.0, 1.4, 1.6)])
    sm = (sock > 1) & ~hm
    material(c, height(sock, .5), sm, STEEL, bump=4, spec_amt=.4, grain=.03)
    # the two front prongs, with round gold tips
    for pts in (left, right):
        f = tube(c, pts, 1.0)
        pm = (f > 1) & (c.a < .5)
        material(c, height(f, .5), pm, STEEL, bump=5, spec_amt=.55, spec_pow=20, grain=.04)
        tip = field(c, [(pts[-1][0], pts[-1][1], 1.4, 1.4)])
        tm = tip > 1
        material(c, height(tip, .5), tm, GOLD, bump=5, spec_amt=.6, grain=.04)
        knuckle = field(c, [(pts[2][0], pts[2][1], 1.3, 1.3)])
        km = knuckle > 1
        material(c, height(knuckle, .5), km, GOLD, bump=5, spec_amt=.6, grain=.04)
    # a little mint light on the hub
    lt = field(c, [(13, 5.2, 1.05, 1.0)])
    lm = lt > 1
    material(c, height(lt, .5), lm, [(30, 90, 80), (60, 160, 140), (120, 220, 190), (200, 250, 230), (255, 255, 255)], bump=4, spec_amt=.9, grain=.02)
    outline(c, c.a > .5, 1.0)
    return c


def capsule():
    n = 12
    c = Canvas(n, n, K, 1.0, anchor=(6, 12))
    f = field(c, [(6, 6, CAP_R, CAP_R)])
    top = (f > 1) & (c.y < 6)
    bot = (f > 1) & (c.y >= 6)
    material(c, height(f, .55), top, YELLOW, bump=4, spec_amt=.7, spec_pow=16, grain=.04)
    material(c, height(f, .55), bot, CREAM, bump=4, spec_amt=.5, grain=.03)
    band = (f > 1) & (np.abs(c.y - 6) < .55)
    material(c, height(f, .55), band, [(110, 70, 16), (170, 116, 30), (210, 150, 50), (240, 190, 90), (255, 230, 160)], bump=3, spec_amt=.2)
    outline(c, c.a > .5, 1.0)
    return c


if __name__ == '__main__':
    dest = os.path.join(PROJ, 'minigames', 'pinch')
    big, small = shrink(claw())
    small.save(os.path.join(dest, 'visit_claw.png'))
    big2, cap = shrink(capsule())
    cap.save(os.path.join(dest, 'visit_capsule.png'))
    from PIL import Image
    prev = Image.new('RGBA', (W, H), (236, 170, 180, 255))
    prev.alpha_composite(cap, (int(CAP_AT[0] - 6), int(CAP_AT[1] - 6)))
    prev.alpha_composite(small)
    prev.resize((W * 12, H * 12), Image.NEAREST).save(os.path.join(SCR, 'visit_claw_preview.png'))
    print('ok')
