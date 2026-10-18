"""The device's cases (2026-10-16, -18): each is the Melon Soda case's own layers (textures/cases/
melon_*.png: its carved logos, its holes, its edges) recoloured, its dots traded for its own print
(tools/art/case_prints.py: only on the case's flat parts, never on the carving), from simple to
fancy (the user: the first case simple, then fancier ones):

    the first one, early (Splash Hoops 1-5, or with your first sticker):  taro (plain lilac)
    Melon Soda (100 stars in all): mint, its dots (the original, untouched)
    the Shop's (prints):  sakura (blossoms), lemon (slices), sky (clouds), cocoa (sprinkles)
    the games' (won on each game's 6-9):  maze (Labyrinth: wood, a maze inlaid, marbles), splash
        (Lagoon: the water's depths, waves, bubbles, fish), prix (Grand Prix: a race livery),
        sumo (Dohyo: the ring's clay, its straw rope, the tassels), spin (Koma: lacquer and gold)

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
# outline / body / light: the case's ramp (its carving's shade and light, its side as the device
# turns: Collection.CASES' "tones"); dots: the light for the carving's highlights
CASES = {
    'taro': {'outline': (98, 72, 124), 'body': (198, 176, 226), 'dots': (236, 226, 250)},
    'sakura': {'outline': (130, 70, 90), 'body': (242, 190, 204), 'dots': (255, 246, 248)},
    'lemon': {'outline': (130, 100, 30), 'body': (246, 222, 120), 'dots': (255, 252, 230)},
    'sky': {'outline': (50, 80, 130), 'body': (160, 200, 240), 'dots': (244, 250, 255)},
    'cocoa': {'outline': (70, 42, 30), 'body': (150, 100, 74), 'dots': (236, 210, 186)},
    'maze': {'outline': (98, 62, 36), 'body': (214, 172, 114), 'dots': (246, 224, 182)},
    'splash': {'outline': (28, 78, 100), 'body': (96, 184, 200), 'dots': (220, 248, 250)},
    'prix': {'outline': (110, 34, 34), 'body': (220, 84, 72), 'dots': (252, 240, 230)},
    'sumo': {'outline': (110, 70, 40), 'body': (222, 194, 138), 'dots': (246, 226, 186)},
    'spin': {'outline': (12, 12, 20), 'body': (34, 34, 52), 'dots': (226, 182, 82)},
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


# the menu buttons with a case on (the user, 2026-10-17/18): the button's own face keeps its colours
# (everything inside its dark outline: the face, the icon, the outline itself), and all of its frame
# round it is the case's (the bezel ring and its bevel, the outer outline, the light band below and
# to its right; nothing of the bare device's cream left), each px by its brightness along the bare
# device's ramp onto the case's (outline - body - light), so the bevel keeps its light and shade
BUTTONS = ['buttonfoodnormal', 'buttonfoodpressed', 'padbuttonnormal', 'padbuttonpressed', 'settingsbuttonnormal',
           'settingsbuttonpressed']
DEVICE = {'outline': (54, 36, 31), 'body': (250, 237, 217)}


def button_face(rgb, a):
    """the button's face: the biggest dark ring that isn't the outer outline, filled"""
    from scipy.ndimage import binary_fill_holes, binary_dilation, label
    dark = (a > 0) & (rgb.sum(-1) < 330)
    L, n = label(dark)
    outer = set(np.unique(L[binary_dilation(a == 0, iterations=1) & dark])) - {0}
    best, area = None, 0
    for i in range(1, n + 1):
        if i in outer:
            continue
        f = binary_fill_holes(L == i).sum()
        if f > area:
            best, area = i, f
    return binary_fill_holes(L == best)


def buttons(cid, theme):
    lo, lb = lum(DEVICE['outline']), lum(DEVICE['body'])
    O, B = (np.array(theme[k], np.float32) for k in ('outline', 'body'))
    L_ = np.array(theme.get('light', theme['dots']), np.float32)
    for name in BUTTONS:
        src = np.asarray(Image.open(os.path.join(ROOT, 'textures', 'buttons', f'{name}.png')).convert('RGBA')).copy()
        rgb, a = src[..., :3].astype(np.float32), src[..., 3]
        frame = (a > 0) & ~button_face(src[..., :3].astype(int), a)
        t = ((lum(rgb) - lo) / (lb - lo))[..., None]
        new = np.where(t <= 1.0, O + (B - O) * np.clip(t, 0, 1), B + (L_ - B) * np.clip(t - 1.0, 0, 1))
        rgb[frame] = new[frame]
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
        if layer in ('back', 'front'):
            # its print on the flat parts (the dots off): the console's px x4
            from case_prints import PRINTS
            dots = near(rgb, MELON['dots'], 10) & (a > 0)
            flat = (near(rgb, MELON['body'], 5) | dots) & (a > 0)
            art = PRINTS[cid](layer, theme['body'])
            big = np.repeat(np.repeat(art, PX, 0), PX, 1)[:a.shape[0], :a.shape[1]]
            new[flat] = big[flat]
        im = Image.fromarray(np.dstack([new.astype(np.uint8), a]), 'RGBA')
        im.save(os.path.join(DIR, f'{cid}_{layer}.png'))
        out[layer] = im
    return out


def icon(cid):
    """a small picture of the case for the menus' cards: the back's upper middle (the carved logo
    and the print's heart), square"""
    back = Image.open(os.path.join(DIR, f'{cid}_back.png')).convert('RGBA')
    x0, y0, _, _ = back.getbbox()
    im = back.crop((x0 + 280, y0 + 640, x0 + 280 + 520, y0 + 640 + 520)).resize((96, 96), Image.LANCZOS)
    a = np.asarray(im).copy()
    a[..., 3] = np.where(a[..., 3] > 110, 255, 0)
    os.makedirs(os.path.join(DIR, 'icons'), exist_ok=True)
    Image.fromarray(a, 'RGBA').save(os.path.join(DIR, 'icons', f'{cid}.png'))


if __name__ == '__main__':
    sys.path.insert(0, HERE)
    only = sys.argv[1:] or list(CASES)
    for cid in only:
        make(cid, CASES[cid])
        icon(cid)
        th = CASES[cid]
        print(cid, 'ok  tones:', ['#%02x%02x%02x' % tuple(th[k]) for k in ('outline', 'body', 'dots')], flush=True)
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
