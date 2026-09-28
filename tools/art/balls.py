from hires import *
from forms import BROWN, PINK, VAN, CHOC, GREEN, ORANGE, CHEESE, SPRINK, SEAM, split
import os
# 48x48 texture, ball radius ~20px; design space 96x96 (F=0.5)
F, W, H, K = 0.5, 48, 48, 20
C, R = (48, 50), 38          # ball centre / radius in design units
BALL = [(C[0], C[1], R, R)]

def ball_field(c):
    return field(c, BALL)

def sphere(c, pal, **kw):
    f = ball_field(c); m = f > 1
    material(c, height(f, .5), m, pal, bump=5, **kw)
    return f, m

def bands(c, pals, cuts):
    """horizontal bands on the sphere (soft-serve layers)."""
    f = ball_field(c); m = f > 1
    h = height(f, .5)
    edges = [-1e9] + cuts + [1e9]
    parts = []
    for i, pal in enumerate(pals):
        wave = 2.2 * np.sin(c.x * .22 + i)
        band = m & (c.y + wave >= edges[i]) & (c.y + wave < edges[i + 1])
        material(c, h, band, pal, bump=5, spec_amt=.5, spec_pow=22, grain=.07)
        parts.append(band)
    for i in range(len(parts) - 1):
        seam(c, parts[i], parts[i + 1], .5, SEAM(90, 30, 50))
    return m

def finish(c, face_y=60, style='happy', eye_r=6.5, spread=13):
    outline(c, c.a > .5, 1.0)
    face(c, C[0], face_y, spread=spread, style=style, eye_r=eye_r)

def classic(c):
    f = field(c, BALL + [(52, 14, 7, 9, .5)])            # the classic poop tip on top
    m = f > 1
    material(c, height(f, .5), m, BROWN, bump=5, spec_amt=.35, grain=.08)
    finish(c)

def sprig(c):
    sphere(c, BROWN, spec_amt=.3, grain=.08)
    fl = [(40, 16, 9, 8), (57, 14, 10, 9), (48, 7, 7, 6)]
    fs = [field(c, [x]) for x in fl]
    for f in fs:
        m = f > 1
        material(c, height(f, .5), m, GREEN, bump=6, spec_amt=.2, grain=.15, ao=.5)
        outline(c, m, .5, SEAM(22, 46, 24))
    finish(c)

def broccolump(c):
    # brown ball whose whole upper half has turned into a head of florets
    f, m = sphere(c, BROWN, spec_amt=.3, grain=.08)
    fl = [(48, 20, 13, 11), (30, 28, 12, 10), (66, 28, 12, 10), (40, 38, 11, 8), (57, 38, 11, 8), (22, 40, 8, 7), (74, 40, 8, 7)]
    ffs = [field(c, [x]) for x in fl]
    idx = np.argmax(np.stack(ffs), 0)
    crown = (sum(ffs) > 1) & m
    rr = np.random.default_rng(2)
    for i, (ff, x) in enumerate(zip(ffs, fl)):
        part = crown & (idx == i)
        micro = [(x[0] + rr.uniform(-.6, .6)*x[2], x[1] + rr.uniform(-.6, .6)*x[3], 3.2, 3.2, .4) for _ in range(6)]
        h = np.clip(height(ff, .5) * .7 + height(field(c, micro), .6) * .45, 0, 1.3)
        material(c, h, part, GREEN, bump=7, spec_amt=.2, grain=.16, ao=.5)
        seam(c, part, crown & ~part, .35, SEAM(22, 46, 24))
    seam(c, crown, m & ~crown, .6, SEAM(30, 36, 18))
    finish(c, face_y=64)

def swirlet(c):
    bands(c, [VAN, PINK], [40])
    dots(c, 5, (18, 14, 78, 40, lambda x, y: (x-48)**2 + (y-50)**2 < 30**2), SPRINK, r=2.2, seed=4)
    finish(c, face_y=64)

def neapoolitan(c):
    bands(c, [CHOC, PINK, VAN, PINK], [30, 42, 52])
    dots(c, 7, (16, 30, 80, 50, lambda x, y: (x-48)**2 + (y-50)**2 < 32**2), SPRINK, r=2.2, seed=9)
    outline(c, c.a > .5, 1.0)
    ch = field(c, [(56, 11, 8, 8)]); cm = ch > 1
    material(c, height(ch, .5), cm, [(70, 8, 20), (150, 20, 36), (214, 44, 54), (244, 110, 110), (255, 220, 220)], bump=4, spec_amt=.8, grain=.04)
    im = to_image(c); d = ImageDraw.Draw(im)
    d.line([*c.P(58, 4), *c.P(61, -2), *c.P(67, -4)], fill=(80, 56, 30), width=int(3 * K * F), joint='curve')
    a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255
    finish(c, face_y=66)

def nugget(c):
    sphere(c, ORANGE, spec_amt=.9, spec_pow=14, grain=.06)
    finish(c)

def greasy_chonk(c):
    f, m = sphere(c, ORANGE, spec_amt=.9, spec_pow=14, grain=.06)
    drip = 34 + 2*np.sin(c.x*.4) + 9*np.exp(-((c.x-28)/3)**2) + 13*np.exp(-((c.x-66)/3.2)**2) + 5*np.exp(-((c.x-47)/2.5)**2)
    cheese = m & (c.y < drip)
    material(c, height(f, .5) * 1.04, cheese, CHEESE, bump=5, spec_amt=.55, spec_pow=22, grain=.05)
    seam(c, cheese, m & ~cheese, .5, SEAM(120, 56, 16))
    finish(c, face_y=64, style='sleepy')

DEST = os.path.join(PROJ, 'minigames', 'balls')
os.makedirs(DEST, exist_ok=True)
names = ['classic', 'sprig', 'swirlet', 'nugget', 'broccolump', 'neapoolitan', 'greasy_chonk']
sheet = Image.new('RGBA', (W * len(names) * 4, H * 4), (232, 200, 152, 255))
for i, n in enumerate(names):
    c = Canvas(W, H, K, F, anchor=C)
    globals()[n](c)
    _, small = shrink(c)
    small.save(os.path.join(DEST, n + '.png'))
    sheet.alpha_composite(small.resize((W * 4, H * 4), Image.NEAREST), (i * W * 4, 0))
sheet.save(SCR + '/balls_sheet.png')
print('ok')
