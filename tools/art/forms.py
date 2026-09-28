from hires import *
import os
F, W, H, K = 0.5, 55, 50, 20
BROWN = [(70, 22, 30), (132, 48, 48), (190, 96, 62), (218, 126, 80), (236, 160, 104), (252, 220, 170)]
PINK  = [(110, 36, 70), (184, 74, 112), (230, 122, 152), (246, 166, 190), (255, 214, 226)]
VAN   = [(150, 100, 80), (220, 184, 150), (246, 226, 196), (255, 244, 224), (255, 255, 248)]
CHOC  = [(50, 20, 20), (100, 50, 36), (150, 84, 56), (196, 128, 90), (236, 190, 150)]
GREEN = [(24, 50, 28), (46, 92, 40), (84, 140, 56), (126, 180, 74), (178, 214, 110), (228, 240, 180)]
ORANGE = [(84, 26, 20), (156, 60, 30), (210, 104, 46), (234, 140, 64), (248, 184, 104), (255, 236, 196)]
CHEESE = [(160, 96, 10), (226, 156, 26), (250, 200, 56), (255, 226, 110), (255, 248, 200)]
SPRINK = [(255, 250, 220), (100, 185, 235), (120, 200, 100), (255, 205, 60), (160, 110, 225)]
SEAM = lambda r, g, b: np.array([r, g, b], np.float32)

def split(c, fields):
    tot = sum(fields); mask = tot > 1
    idx = np.argmax(np.stack(fields), 0)
    return mask, [mask & (idx == i) for i in range(len(fields))], tot

def swirl(c, tiers, pals, n_sprinkles, face_y, eye_r, spread, cherry=None):
    fs = [field(c, t) for t in tiers]
    mask, parts, tot = split(c, fs)
    for f, m, pal in zip(fs, parts, pals):
        material(c, height(f, .55), m, pal, bump=4, spec_amt=.45, spec_pow=22, grain=.08)
    for i in range(len(parts) - 1):
        seam(c, parts[i + 1], parts[i], .5, SEAM(90, 30, 50))
    if n_sprinkles:
        top = min(t[0][1] for t in tiers)
        dots(c, n_sprinkles, (25, top - 6, 85, face_y - 5,
             lambda x, y: tot[min(int(y*K*F), H*K-1), min(int(x*K*F), W*K-1)] > 1.3), SPRINK, r=1.5, seed=9)
    outline(c, c.a > .5, 1.0)
    if cherry:
        cx, cy, r = cherry
        ch = field(c, [(cx, cy, r, r)]); cm = ch > 1
        material(c, height(ch, .5), cm, [(70, 8, 20), (150, 20, 36), (214, 44, 54), (244, 110, 110), (255, 220, 220)], bump=4, spec_amt=.8, grain=.04)
        im = to_image(c); d = ImageDraw.Draw(im)
        d.line([*c.P(cx + 1, cy - 5), *c.P(cx + 3, cy - 11), *c.P(cx + 8, cy - 14)], fill=(80, 56, 30), width=int(2.2 * K * F), joint='curve')
        a = np.asarray(im, np.float32); c.rgb, c.a = a[..., :3].copy(), a[..., 3] / 255
        outline(c, c.a > .5, 1.0)
    face(c, 55, face_y, spread=spread, style='sparkle', eye_r=eye_r)

def brocco(c, body_balls, florets, face_y, eye_r, spread, seed=3):
    body = field(c, body_balls)
    ffs = [field(c, [fl]) for fl in florets]
    mask, parts, tot = split(c, [body] + [f * .95 for f in ffs])
    material(c, height(body, .55), parts[0], BROWN, bump=4, spec_amt=.3, grain=.08)
    rr = np.random.default_rng(seed)
    for f, m, (fx, fy, rx, ry) in zip(ffs, parts[1:], florets):
        micro = [(fx + rr.uniform(-.7, .7)*rx, fy + rr.uniform(-.7, .6)*ry, 2.6, 2.6, .4) for _ in range(7)]
        h = np.clip(height(f, .5) * .75 + height(field(c, micro), .6) * .45, 0, 1.3)
        material(c, h, m, GREEN, bump=6, spec_amt=.2, grain=.16, ao=.5)
    for i in range(1, len(parts)):
        seam(c, parts[i], mask & ~parts[i] & ~parts[0], .35, SEAM(22, 46, 24))
        seam(c, parts[i], parts[0], .55, SEAM(30, 36, 18))
    outline(c, c.a > .5, 1.0)
    face(c, 55, face_y, spread=spread, style='happy', eye_r=eye_r)

def greasy(c, balls, drip_fn, face_y, eye_r, spread, style):
    f = field(c, balls); m = f > 1
    material(c, height(f, .5), m, ORANGE, bump=4, spec_amt=.75, spec_pow=16, grain=.07)
    if drip_fn is not None:
        cheese = m & (c.y < drip_fn(c.x))
        material(c, height(f, .5) * 1.05, cheese, CHEESE, bump=4, spec_amt=.55, spec_pow=22, grain=.05)
        seam(c, cheese, m & ~cheese, .5, SEAM(120, 56, 16))
    outline(c, c.a > .5, 1.0)
    face(c, 55, face_y, spread=spread, style=style, eye_r=eye_r)

def S(balls, s=1.3, a=(55, 93)):
    """scale a list of (x,y,rx,ry[,w]) around the bottom anchor."""
    return [(a[0] + (b[0]-a[0])*s, a[1] + (b[1]-a[1])*s, b[2]*s, b[3]*s, *b[4:]) for b in balls]
Y = lambda y, s=1.3: 93 + (y - 93) * s

FORMS = {
  # ---- stage 1 babies
  'sprig':    lambda c: brocco(c, S([(55, 86, 21, 7.5), (55, 78, 16, 9)]),
                               S([(49, 66, 6, 5.5), (61, 65, 6.5, 6), (55, 60, 5, 4.5)]), Y(80), 5.6, 10.5, seed=5),
  'swirlet':  lambda c: swirl(c, [S([(55, 86, 22, 7.5)]), S([(55, 75, 16, 6.5)]), S([(56, 66, 8.5, 5.5), (59, 61, 3.2, 3, .6)])],
                              [PINK, VAN, PINK], 4, Y(84.5), 5.2, 10.5),
  'nugget':   lambda c: greasy(c, S([(55, 87, 27, 6.5), (55, 80, 21, 7.5), (56, 72, 10, 5.5)]), None, Y(80.5), 5.4, 11, 'happy'),
  # ---- stage 2 evolutions
  'broccolump':  lambda c: brocco(c, [(55, 80, 30, 11.5), (55, 69, 24, 13)],
                     [(55, 38, 10, 9), (40, 45, 9, 8), (70, 45, 9, 8), (30, 56, 7.5, 7), (80, 56, 7.5, 7), (55, 52, 10, 7)], 72, 4.6, 11),
  'neapoolitan': lambda c: swirl(c, [[(55, 80, 32, 12)], [(55, 65, 25, 10)], [(56, 52, 17, 8.5)], [(58, 42, 8, 6.5), (63, 37, 4, 3.5, .6)]],
                     [PINK, VAN, PINK, CHOC], 11, 79, 5.8, 12.5, cherry=(66, 31, 5.5)),
  'greasy_chonk': lambda c: greasy(c, [(55, 82, 42, 10.5), (55, 71, 35, 11.5), (55, 59, 22, 9), (57, 50, 9, 6)],
                     lambda x: 58 + 1.5*np.sin(x*.5) + 7*np.exp(-((x-30)/2.4)**2) + 10*np.exp(-((x-80)/2.6)**2) + 4*np.exp(-((x-55)/2.0)**2),
                     77, 5.6, 13, 'sleepy'),
}

if __name__ == "__main__":
    DEST = os.path.join(PROJ, 'pet', 'forms')
    os.makedirs(DEST, exist_ok=True)
    preview = Image.new('RGBA', (232 * 6, 196 * 2), (236, 170, 170, 255))
    for col, (name, fn) in enumerate(FORMS.items()):
        for row, sq in enumerate([(1.0, 1.0), (1.03, 0.95)]):
            c = Canvas(W, H, K, F, squash=sq, anchor=(55, 93))
            fn(c)
            _, small = shrink(c)
            up2 = small.resize((W * 2, H * 2), Image.NEAREST)       # match poo1's chunky art-pixel size
            out = Image.new('RGBA', (232, 196), (0, 0, 0, 0))
            out.alpha_composite(up2, (60, 60))                      # design anchor (55,93) -> poo1 bottom-centre (115,153)
            out.save(os.path.join(DEST, f'{name}-{row + 1}.png'))
            preview.alpha_composite(out, (col * 232, row * 196))
    preview.resize((preview.width * 2 // 2, preview.height)).save(SCR + '/forms_preview.png')
    print('ok')
