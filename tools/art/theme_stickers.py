"""The games' themed stickers (2026-10-16: won in the games' secrets, never sold), drawn by the pal
renderer (docs/mockups/pal_brainstorm/v3/palgen3.py) so they look like the pals' world, then cut
out like the pal stickers (case_stickers.sticker: a white die-cut border):

    textures/cases/stickers/<id>.png        stuck size (x3 the art's pixels, like a pal sticker)
    textures/cases/stickers/book/<id>.png   as the sticker book shows it (x2)
    textures/cases/book/tab_games.png       the sticker book's page for them: its tab (the gold cup)

    <venv>/bin/python tools/art/theme_stickers.py     (Collection.STICKERS lists them)
"""
import os, sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'docs', 'mockups', 'pal_brainstorm', 'v3'))
import palgen3 as G
from hires import Canvas, height, material, outline, seam, shrink
from case_stickers import sticker, page_tab, DEST, BOOK, FAM_COL

# id -> (stage, spec line) or a picture already drawn (a rival, the robots' key)
THEMED = {
 # Splash Hoops
 'starfish': ('kid', 'Starfish | star | coral/lemon | speckle:lemon | happy w blush'),
 'pufferfish': ('kid', 'Puffer | ball | lemon/cream | spikes:lemon belly:cream fins:lemon | wide o'),
 'seashell': ('kid', 'Seashell | clam | peach/coral | clamridges | dot w blush'),
 'anglerfish': ('kid', 'Angler | ball sx=1.2 | navy/lemon | lure:lemon tail_fish:navy fins:navy | wide fangs'),
 # Pal Prix
 'traffic_cone': ('kid', 'Cone | cone | orange/white | hstripes:white | dot flat'),
 'rubber_duck': ('kid', 'Duck | bird | lemon/orange | beak_f:orange wings_tiny:lemon | gloss flat'),
 'gold_cup': 'trophy',
 # Top Spin
 'koma': ('kid', 'Koma | slice | spicy/lemon | hstripes:lemon stem | gloss w'),
 'soap': ('kid', 'Soap | cube | pink/white | bubbles | happy w blush'),
 'dragon': ('kid', 'Dragon | bean | spicy/gold | horns:gold fins:gold spikes:gold whiskers | stern fang'),
 # Paper Sumo
 'koi': ('kid', 'Koi | fish | white/orange | spots:orange fins:orange tail_fish:orange | gloss o'),
 'wind_up_key': os.path.join(ROOT, 'textures', 'minigames', 'sumo', 'key_gold.png'),
 'kabuto': os.path.join(ROOT, 'textures', 'minigames', 'sumo', 'rivals', 'beetle_0.png'),
 # each game's gift track at 150 stars: a gold sticker
 'gold_shell': ('kid', 'Gold Shell | clam | gold | clamridges sparkles | happy w'),
 'gold_marble': ('kid', 'Gold Marble | ball | gold | swirlband:lemon sparkles | gloss w'),
 'gold_car': ('kid', 'Gold Car | bun sx=1.25 | gold/char | wheels:char mask:sky | dot w sparkles'),
 'gold_yokozuna': os.path.join(ROOT, 'textures', 'minigames', 'sumo', 'rivals', 'sumo_champ.png'),
 'gold_top': ('kid', 'Gold Top | slice | gold/lemon | hstripes:lemon stem sparkles | gloss w'),
}


def trophy():
    """the Grand Prix's gold cup: a bowl with a rim, two ring handles, a stem and a stepped base
    (each its own shape, shaded on its own, seams between them), a star on the bowl"""
    c = Canvas(G.W, G.H, G.K, G.F, anchor=(55, 93))
    gold = G.P['gold']
    x, y = c.x, c.y
    shapes = []                                          # (field, mask) per part, drawn in order
    cup = G.sfield(c, [(55, 44, 20, 17)])
    shapes.append((cup, (cup > 1) & (y > 30)))
    for sd in (-1, 1):                                   # the handles: rings on the bowl's sides
        hx = 55 + sd * 21
        d = np.hypot(x - hx, (y - 40) * 1.1)
        ring = (d > 4.2) & (d < 8.6) & ((x - 55) * sd > 17)
        shapes.append((np.clip(1 - np.abs(d - 6.4) / 2.2, 0, 1) * 2 + 1, ring))
    stem = G.sfield(c, G.chain((55, 60), (55, 74), 4.2, 3.0, 6))
    shapes.append((stem, (stem > 1) & (y > 58)))
    for (cy, rx, ry) in ((77, 14, 4.2), (84, 18, 4.0)):
        f_ = G.sfield(c, [(55, cy, rx, ry, 3)])
        shapes.append((f_, f_ > 1))
    rim = G.sfield(c, [(55, 30, 21.5, 3.4, 3)])
    shapes.append((rim, rim > 1))
    done = np.zeros_like(x, bool)
    for f_, m in shapes:
        m = m & ~done
        material(c, height(f_, .5), m, gold, bump=4, spec_amt=.85, spec_pow=12, grain=.03)
        if done.any():
            seam(c, m, done, .5)
        done |= m
    outline(c, c.a > .5, 1.0)
    outline(c, c.a > .5, 1.0)

    def star(d):
        pts = []
        for i in range(10):
            r = 6.5 if i % 2 == 0 else 2.8
            a = -np.pi / 2 + i * np.pi / 5
            pts.append(c.P(55 + r * np.cos(a), 45 + r * np.sin(a)))
        d.polygon(pts, fill=(255, 250, 220))
    G.draw_on(c, star)
    _, small = shrink(c)
    return small.resize((G.W * 2, G.H * 2), Image.NEAREST)


def art(item):
    if item == 'trophy':
        im = trophy()
    elif isinstance(item, str):
        im = Image.open(item).convert('RGBA')
    else:
        stage, line = item
        name, spec, _ = G.parse(line)
        im = G.render(spec, stage, name)
    a = np.asarray(im).astype(int)
    ys, xs = np.nonzero(a[..., 3] > 0)
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


if __name__ == '__main__':
    os.makedirs(os.path.join(DEST, 'book'), exist_ok=True)
    for sid, item in THEMED.items():
        a = art(item)
        sticker(a, outline=False, px=3).save(os.path.join(DEST, sid + '.png'))
        sticker(a, outline=False, px=2).save(os.path.join(DEST, 'book', sid + '.png'))
        print(sid, a.shape[1], 'x', a.shape[0], flush=True)
    cup = Image.fromarray(art('trophy').astype(np.uint8), 'RGBA')
    k = 14 / max(cup.size)
    cup = np.asarray(cup.resize((max(1, round(cup.width * k)), max(1, round(cup.height * k))), Image.LANCZOS)).astype(int)
    cup[..., 3] = np.where(cup[..., 3] > 110, 255, 0)
    FAM_COL['games'] = (240, 200, 92)
    page_tab('games', cup).save(os.path.join(BOOK, 'tab_games.png'))
    print('ok', len(THEMED))
