"""A ball for every pal (Tilt Maze, Tile Break, Top Spin, Paper Sumo, Flipper Belly...): the pal
rolled up into the games' 16 px ball (a 24 x 24 texture, shown x3; PalBall loads it). The 4 px
around the ball leave room for ears, leaves and candy wrappers.

The ball is painted by the pal renderer (palgen3: paint big, shrink) as a sphere in the pal's own
colours, with its surface (glaze, spots, stripes, masks, crust...) and its small top bits (leaves,
ears, horns, a cherry...) at ball size. Parts that hang off a body (wings, tails, legs, claws...)
stay off: a ball is round. The face is then stamped pixel by pixel in the pal's own style
(deadpan, sleepy, side-eye, visor...) so it reads at 16 px.

    <venv>/bin/python tools/art/pal_balls.py            all 120 -> textures/minigames/balls/<id>.png
    <venv>/bin/python tools/art/pal_balls.py bud usagi  only these
"""
import json, os, sys
from multiprocessing import Pool
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'docs', 'mockups', 'pal_brainstorm', 'v3'))
import palgen3 as G
from hires import to_image

DATA = os.path.join(ROOT, 'data', 'evolution_tree.json')
DEST = os.path.join(ROOT, 'textures', 'minigames', 'balls')
N = 24                      # texture size; the ball: 14 px of colour + a 1 px outline = 16 px
O = (N - 20) // 2           # (the face stamps below are drawn for a 20 px box: shifted by O)
CX, CY = 55, 79             # the ball's centre on the renderer's canvas (design units)
FACE_Y = 81                 # where the eyes are (design units): a touch below the middle

KEEP = {   # what a ball keeps (painted by the renderer); everything else hangs off a body
    'cap', 'drip', 'base', 'band', 'belly', 'half', 'diag', 'spots', 'stripes', 'hstripes', 'tip', 'mask', 'nori',
    'crust', 'glaze', 'warts', 'seeds', 'scales', 'socks', 'patch', 'dapple', 'blaze', 'tiers', 'sugar', 'grill',
    'swirlband', 'face_patch', 'speckle', 'zigzag', 'checker', 'facets', 'eyepatches', 'bangs', 'darumaface',
    'lanternbands', 'ribs', 'leafveins', 'ridges', 'crustedge', 'grid', 'clamridges', 'broth',
    'sprinkles', 'sesame', 'bolts', 'chip', 'crown', 'mark', 'leafpin', 'kanji', 'capspots', 'stars', 'rune', 'gem',
    'leaf', 'leaf2', 'sprout', 'stem', 'ears', 'ears_cat', 'ears_bear', 'ears_fox', 'ears_mouse', 'ears_bunny', 'nubs',
    'horns', 'horn', 'antennae', 'antenna', 'curl', 'feather', 'topknot', 'tuft', 'crest', 'cherry', 'hat', 'plate',
    'flame', 'collar', 'wrapper', 'frills', 'quills'}

# pals whose look is their body's shape (a yolk on top, the colours in layers...) get it back on
# the ball with surface parts: {id: (palette or None, parts to add)}
BALL_LOOK = {
    'fried_egg': (None, [('cap', 'greasy')]),                      # the yolk
    'candy_corn': ('orange', [('cap', 'white'), ('base', 'lemon')]),   # white / orange / yellow
    'pistachio': ('lime', [('base', 'crust')]),                    # the scoop on its cone
    'burger': (None, [('band', 'choc')]),                          # the patty
    'ningyo': (None, [('scales', 'teal')]),
}

INK = (18, 8, 14)
WHITE = (255, 255, 255)
PINK = (236, 128, 150)
CYAN = (110, 236, 226)
GOLD = (250, 200, 60)
GOLD_D = (196, 128, 30)

# eyes: (left grid, right grid, top row, left x, right x); grids: K ink, W white, L eyelid, Y gold
EYES = {
    'gloss':   (['WK', 'KK'], None, 10, 7, 11),
    'wide':    (['WK', 'KK', 'KK'], None, 9, 7, 11),
    'tiny':    (['K'], None, 11, 8, 11),
    'dot':     (['K', 'K'], None, 10, 8, 11),
    'lid':     (['LL', 'KK'], None, 10, 7, 11),
    'heavy':   (['LL', 'KK'], None, 10, 7, 11),
    'sleep':   (['K.K', '.K.'], None, 10, 6, 11),
    'happy':   (['.K.', 'K.K'], None, 10, 6, 11),
    'line':    (['KK'], None, 11, 7, 11),
    'glance':  (['WK', 'WK'], None, 10, 7, 11),
    'side':    (['WK', 'WK'], None, 10, 7, 11),
    'stern':   (['.K', 'KK', 'KK'], ['K.', 'KK', 'KK'], 9, 7, 11),
    'worried': (['K.', 'KK', 'KK'], ['.K', 'KK', 'KK'], 9, 7, 11),
    'cross':   (['K.', '.K', 'K.'], ['.K', 'K.', '.K'], 9, 7, 11),
    'squint':  (['K.', '.K', 'K.'], ['.K', 'K.', '.K'], 9, 7, 11),
    'x':       (['K.K', '.K.', 'K.K'], None, 9, 6, 11),
    'spiral':  (['K.K', '.K.', 'K.K'], None, 9, 6, 11),
    'star':    (['.W.', 'WKW', '.W.'], None, 9, 6, 11),
}
SPECIAL_EYES = {   # stamped as one piece: (grid, top row, left x)
    'one':    (['WK', 'KK', 'KK'], 9, 9),
    'three':  (['WK...WK...WK', 'KK...KK...KK'], 10, 4),
    'visor':  (['KKKKKKKKKK', 'KCCCCCCCCK'], 10, 5),
    'shades': (['WKKKKKWKK', 'KKK...KKK'], 10, 6),
}
MOUTHS = {   # (grid, top row, left x); P = pink
    'flat':  (['KK'], 13, 9), 'dot': (['KK'], 13, 9), 'pout': (['KK'], 13, 9),
    'o':     (['KK', 'KK'], 13, 9), 'open': (['KK', 'KK'], 13, 9),
    'w':     (['K..K', '.KK.'], 13, 8), 'smile': (['K..K', '.KK.'], 13, 8), 'v': (['K..K', '.KK.'], 13, 8),
    'frown': (['.KK.', 'K..K'], 13, 8),
    'smirk': (['...K', '.KK.'], 13, 8),
    'fang':  (['KK', '.W'], 13, 9), 'fangs': (['KKKK', 'W..W'], 13, 8), 'teeth': (['KKKK', '.WW.'], 13, 8),
    'grin':  (['KKKK', '.KK.'], 13, 8),
    'wavy':  (['K.K.', '.K.K'], 13, 8),
    'tongue': (['KK', '.P'], 13, 9),
    'beak':  (['YY', 'DD'], 12, 9),
}


def ball_spec(fm):
    name, spec, _ = G.parse(fm['line'])
    sp = spec.get('special', '')
    if sp.startswith('ember'):
        spec = {'plan': 'ball', 'pal': 'spicy', 'acc': None, 'acc2': None, 'parts': [('stem', 'green')],
                'eyes': 'gloss', 'mouth': 'flat', 'extras': []}
    elif sp == 'picklet':
        spec = {'plan': 'ball', 'pal': 'sour', 'acc': None, 'acc2': None, 'parts': [],
                'eyes': 'dot', 'mouth': 'flat', 'extras': []}
    face = (spec.get('eyes', 'gloss'), spec.get('mouth', 'flat'), list(spec.get('extras', [])),
            [n for n, _ in spec.get('parts', [])], spec)
    s = dict(spec)
    pal, more = BALL_LOOK.get(fm['id'], (None, []))
    if pal:
        s['pal'] = pal
    s['parts'] = list(spec.get('parts', [])) + more
    s['plan'] = 'ball'
    s['mods'] = {'s': 14 / (15 * G.STAGE['baby']), 'pu': 1.0, 'thin': 1, 'fy': (FACE_Y - (CY - 14)) / 28}
    s['parts'] = [(n, t) for n, t in s['parts'] if n in KEEP]
    s['eyes'], s['mouth'], s['extras'] = 'none', 'none', []
    return name, s, face


def stamp(img, grid, top, left, cols):
    px = img.load()
    top, left = top + O, left + O
    for j, row in enumerate(grid):
        for i, ch in enumerate(row):
            if ch in cols and 0 <= left + i < N and 0 <= top + j < N and px[left + i, top + j][3] > 0:
                px[left + i, top + j] = (*cols[ch], 255)


def paint_face(img, face):
    eyes, mouth, extras, parts, spec = face
    pal = G.P[spec['pal']]
    acc = G.P[spec.get('acc') or spec['pal']]
    cols = {'K': INK, 'W': WHITE, 'L': G.tone(pal, 1), 'Y': GOLD, 'D': GOLD_D, 'C': CYAN, 'P': PINK}
    if 'blush' in extras:
        stamp(img, ['P'], 12, 5, cols)
        stamp(img, ['P'], 12, 14, cols)
    if eyes in SPECIAL_EYES:
        g, top, left = SPECIAL_EYES[eyes]
        stamp(img, g, top, left, cols)
    elif eyes != 'none':
        lg, rg, top, lx, rx = EYES.get(eyes, EYES['gloss'])
        stamp(img, lg, top, lx, cols)
        stamp(img, rg or lg, top, rx, cols)
    if 'stache' in extras:
        stamp(img, ['KKKK'], 12, 8, {'K': (60, 34, 24)})
    if 'beak_f' in parts:
        stamp(img, ['YY', 'DD'], 12, 9, cols)
    elif 'longbeak' in parts:
        stamp(img, ['K.', 'K.', '.K', '.K'], 12, 10, {'K': G.tone(G.P['wood'], 2)})
    elif 'longnose' in parts:
        stamp(img, ['...K', 'KKK.'], 11, 10, {'K': G.tone(acc, 2)})
    if mouth in MOUTHS and 'beak_f' not in parts:
        g, top, left = MOUTHS[mouth]
        stamp(img, g, top + (1 if 'longnose' in parts else 0), left, cols)
    if 'tusks' in parts:
        stamp(img, ['W..W'], 14, 8, cols)


def make(item):
    fid, fm = item
    name, spec, face = ball_spec(dict(fm, id=fid))
    G.render(spec, 'baby', name)
    big = to_image(G.LAST_CANVAS)
    k = G.LAST_CANVAS.k * G.LAST_CANVAS.f            # hi-res px per design unit
    half = N / 2 / G.LAST_CANVAS.f                    # half the texture, in design units
    box = tuple(int(round(v * k)) for v in (CX - half, CY - half, CX + half, CY + half))
    small = big.crop(box).resize((N, N), Image.LANCZOS)
    a = np.asarray(small).copy()
    a[..., 3] = np.where(a[..., 3] > 120, 255, 0)
    img = Image.fromarray(a, 'RGBA').copy()
    paint_face(img, face)
    img.save(os.path.join(DEST, fid + '.png'))
    return fid


if __name__ == '__main__':
    forms = json.load(open(DATA))['forms']
    only = sys.argv[1:]
    todo = [(k, v) for k, v in forms.items() if not only or k in only]
    with Pool(min(10, os.cpu_count() or 4)) as pool:
        for fid in pool.imap_unordered(make, todo):
            print(fid, flush=True)
    print('ok', len(todo))
