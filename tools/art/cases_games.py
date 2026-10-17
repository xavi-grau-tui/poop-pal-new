"""The device's cases (2026-10-16): each is the Melon Soda case's own layers (textures/cases/
melon_*.png: its carved logos, its holes, its edges) recoloured; a game's case trades the dots for
the game's own pattern (only on the case's flat parts, never on the carving).

    the games' cases (won on each game's 6-9):  maze (Labyrinth: wood, a maze inlaid), splash
        (Lagoon: teal, waves), prix (Grand Prix: red, little checkered tiles), sumo (Dohyo: the
        ring's clay, vermilion crests), spin (Koma: slate, spirals)
    the Shop's plain ones (dots, like Melon Soda):  sakura, lemon, sky, cocoa

    <venv>/bin/python tools/art/cases_games.py [ids]  -> textures/cases/<id>_<layer>.png
                                                         textures/cases/icons/<id>.png (and melon's)
"""
import os, sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
DIR = os.path.join(ROOT, 'textures', 'cases')
LAYERS = ['back', 'front', 'front_top', 'frame3', 'buttonfoodnormal', 'buttonfoodpressed', 'padbuttonnormal',
          'padbuttonpressed', 'settingsbuttonnormal', 'settingsbuttonpressed']
MELON = {'outline': (70, 104, 88), 'body': (176, 222, 196), 'dots': (240, 250, 236)}
CASES = {
    'maze': {'outline': (98, 62, 36), 'body': (214, 172, 114), 'dots': (246, 224, 182), 'pattern': 'maze'},
    'splash': {'outline': (36, 94, 108), 'body': (126, 200, 204), 'dots': (236, 250, 250), 'pattern': 'waves'},
    'prix': {'outline': (110, 34, 34), 'body': (220, 84, 72), 'dots': (252, 240, 230), 'pattern': 'checks'},
    'sumo': {'outline': (110, 70, 40), 'body': (222, 194, 138), 'dots': (204, 72, 56), 'pattern': 'crests'},
    'spin': {'outline': (40, 50, 72), 'body': (118, 134, 160), 'dots': (210, 220, 236), 'pattern': 'swirls'},
    'sakura': {'outline': (130, 70, 90), 'body': (242, 190, 204), 'dots': (255, 246, 248)},
    'lemon': {'outline': (130, 100, 30), 'body': (246, 222, 120), 'dots': (255, 252, 230)},
    'sky': {'outline': (50, 80, 130), 'body': (160, 200, 240), 'dots': (244, 250, 255)},
    'cocoa': {'outline': (70, 42, 30), 'body': (160, 112, 84), 'dots': (236, 210, 186)},
}
PX = 4                                                  # the console's pixel


def lum(c):
    c = np.asarray(c, np.float32)
    return c[..., 0] * .3 + c[..., 1] * .59 + c[..., 2] * .11


def recolour(rgb, theme):
    """every case colour mapped by its brightness along Melon Soda's ramp (outline - body - dots)
    onto the theme's: the carving's light and shade stay, in the new colours"""
    lo, lb, ld = lum(MELON['outline']), lum(MELON['body']), lum(MELON['dots'])
    O, B, D = (np.array(theme[k], np.float32) for k in ('outline', 'body', 'dots'))
    L = lum(rgb)
    t1 = np.clip((L - lo) / (lb - lo), -0.6, 1.0)[..., None]
    t2 = np.clip((L - lb) / (ld - lb), 0.0, 1.4)[..., None]
    out = np.where(L[..., None] <= lb, O + (B - O) * t1, B + (D - B) * t2)
    return np.clip(out, 0, 255)


def near(rgb, col, tol):
    return np.abs(rgb.astype(np.int32) - np.array(col)).max(-1) <= tol


def pattern(kind, h, w):
    """the pattern's pixels (True = drawn) on the console's 4 px grid"""
    gy, gx = np.mgrid[0:h, 0:w]
    if kind == 'waves':
        y = (gy + 6 * np.sin(gx * 2 * np.pi / 96)) % 64
        m = (y < PX) & ((gx // 48 + gy // 64) % 2 == 0) | ((y >= 32) & (y < 32 + PX) & ((gx // 48 + gy // 64) % 2 == 1))
    elif kind == 'checks':
        cx, cy = (gx + (gy // 96 % 2) * 48) % 96, gy % 96
        inside = (cx >= 36) & (cx < 60) & (cy >= 36) & (cy < 60)
        m = inside & (((cx - 36) // 12 + (cy - 36) // 12) % 2 == 0)
    elif kind == 'crests':
        cx, cy = (gx + (gy // 112 % 2) * 56) % 112 - 56, gy % 112 - 56
        r = np.hypot(cx, cy)
        m = ((r > 11) & (r < 16)) | (r < 4)
    elif kind == 'swirls':
        cx, cy = (gx + (gy // 96 % 2) * 48) % 96 - 48, gy % 96 - 48
        r = np.hypot(cx, cy)
        a = np.arctan2(cy, cx)
        m = (r < 19) & (np.abs(((r - a * 19 / (2 * np.pi)) % 9.5) - 4.75) < 2.2)
    elif kind == 'maze':
        cell = 48
        rows, cols = h // cell + 1, w // cell + 1
        rng = np.random.default_rng(3)
        right = np.ones((rows, cols), bool)            # a wall on each cell's right / bottom, carved by a walk
        down = np.ones((rows, cols), bool)
        seen = np.zeros((rows, cols), bool)
        stack = [(0, 0)]
        seen[0, 0] = True
        while stack:
            r_, c_ = stack[-1]
            nb = [(r_ + dr, c_ + dc) for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1))
                  if 0 <= r_ + dr < rows and 0 <= c_ + dc < cols and not seen[r_ + dr, c_ + dc]]
            if not nb:
                stack.pop()
                continue
            nr, nc = nb[rng.integers(len(nb))]
            if nr != r_:
                down[min(r_, nr), c_] = False
            else:
                right[r_, min(c_, nc)] = False
            seen[nr, nc] = True
            stack.append((nr, nc))
        ry, rx = gy // cell, gx // cell
        m = ((gx % cell >= cell - PX) & right[ry, rx]) | ((gy % cell >= cell - PX) & down[ry, rx])
    else:
        m = np.zeros((h, w), bool)
    return m


# the menu buttons keep their own colours whatever the case (the user, 2026-10-17): only the case's
# edge round each one, the light band below and to its right outside its dark outline (textures/
# buttons/<name>.png), takes the case's colours, by its brightness along the bare device's ramp
BUTTONS = ['buttonfoodnormal', 'buttonfoodpressed', 'padbuttonnormal', 'padbuttonpressed', 'settingsbuttonnormal',
           'settingsbuttonpressed']
DEVICE = {'outline': (54, 36, 31), 'body': (250, 237, 217)}


def buttons(cid, theme):
    from scipy.ndimage import binary_fill_holes
    lo, lb = lum(DEVICE['outline']), lum(DEVICE['body'])
    O, B = (np.array(theme[k], np.float32) for k in ('outline', 'body'))
    L_ = np.array(theme.get('light', theme['dots']), np.float32)
    for name in BUTTONS:
        src = np.asarray(Image.open(os.path.join(ROOT, 'textures', 'buttons', f'{name}.png')).convert('RGBA')).copy()
        rgb, a = src[..., :3].astype(np.float32), src[..., 3]
        dark = (a > 0) & (rgb.sum(-1) < 330)
        stripe = (a > 0) & ~binary_fill_holes(dark)            # (outside the button's outer outline)
        t = ((lum(rgb) - lo) / (lb - lo))[..., None]
        new = np.where(t <= 1.0, O + (B - O) * np.clip(t, 0, 1), B + (L_ - B) * np.clip(t - 1.0, 0, 1))
        rgb[stripe] = new[stripe]
        src[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
        Image.fromarray(src, 'RGBA').save(os.path.join(DIR, f'{cid}_{name}.png'))


def make(cid, theme):
    out = {}
    buttons(cid, theme)
    for layer in LAYERS:
        if layer in BUTTONS:
            continue
        src = np.asarray(Image.open(os.path.join(DIR, f'melon_{layer}.png')).convert('RGBA'))
        rgb, a = src[..., :3], src[..., 3]
        new = recolour(rgb.astype(np.float32), theme)
        if theme.get('pattern') and layer in ('back', 'front'):
            dots = near(rgb, MELON['dots'], 10) & (a > 0)
            flat = (near(rgb, MELON['body'], 5) | dots) & (a > 0)
            B = np.array(theme['body'], np.float32)
            new[dots] = B                               # (the dots off)
            pm = pattern(theme['pattern'], *a.shape) & flat
            col = np.array(theme['dots'], np.float32) if theme['pattern'] != 'maze' else B + (np.array(theme['outline'], np.float32) - B) * .3
            new[pm] = col
        im = Image.fromarray(np.dstack([new.astype(np.uint8), a]), 'RGBA')
        im.save(os.path.join(DIR, f'{cid}_{layer}.png'))
        out[layer] = im
    return out


def icon(cid):
    """a small picture of the case for the menus' cards: its top-left corner (the rounded edge, the
    carved logo, the pattern), square"""
    back = Image.open(os.path.join(DIR, f'{cid}_back.png')).convert('RGBA')
    x0, y0, _, _ = back.getbbox()
    im = back.crop((x0, y0, x0 + 520, y0 + 520)).resize((96, 96), Image.LANCZOS)
    a = np.asarray(im).copy()
    a[..., 3] = np.where(a[..., 3] > 110, 255, 0)
    os.makedirs(os.path.join(DIR, 'icons'), exist_ok=True)
    Image.fromarray(a, 'RGBA').save(os.path.join(DIR, 'icons', f'{cid}.png'))


if __name__ == '__main__':
    only = sys.argv[1:] or list(CASES)
    for cid in only:
        make(cid, CASES[cid])
        icon(cid)
        print(cid, 'ok', flush=True)
    icon('melon')
    buttons('melon', MELON)
    out = os.path.join(HERE, 'out')
    os.makedirs(out, exist_ok=True)
    ids = ['melon'] + list(CASES)
    sheet = Image.new('RGBA', (270 * len(ids), 480), (60, 60, 60, 255))
    for i, cid in enumerate(ids):
        b = Image.open(os.path.join(DIR, f'{cid}_back.png')).convert('RGBA').resize((270, 480), Image.LANCZOS)
        sheet.alpha_composite(b, (i * 270, 0))
    sheet.save(os.path.join(out, 'cases_preview.png'))
    print('ok')
