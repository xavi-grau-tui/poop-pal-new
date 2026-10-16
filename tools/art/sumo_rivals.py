"""Paper Sumo's rivals (2026-10-16), drawn by the pal renderer (docs/mockups/pal_brainstorm/v3/palgen3.py)
so they look like they live in the pals' world: the same soft shading, solid 2 px outline, glossy
eyes and canvas (55x50 native, shown x2: 110x100), at the pals' stage sizes. Not pals: critters,
toys and wrestlers, one family per world (scripts/paper_sumo.gd FAMILIES):

    1 Wooden Box: frogs (the old Choju-giga scrolls have frogs wrestling hares)
    2 Pond Garden: turtles (heavy)          3 Autumn Stream: otters (the tricksters: pull-downs)
    4 Moon Base: wind-up tin robots         5 Tree Stump: beetles (mushi-zumo)
    6 Shrine Festival: the sumo ranks

    textures/minigames/sumo/rivals/<family>_<look>.png    a rival (look = its colours / kind)
                                   <family>_champ.png     the world's champion (bigger)
                                   <family>_shadow.png    the mystery challenger (in shadow, eyes aglow)
    textures/minigames/sumo/key.png, key_gold.png         a robot's wind-up key (it turns in the game)

    <venv>/bin/python tools/art/sumo_rivals.py            all, and a preview sheet: tools/art/out/sumo_rivals.png
"""
import os, sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'docs', 'mockups', 'pal_brainstorm', 'v3'))
import palgen3 as G
from hires import Canvas, height, material, outline, shrink

DEST = os.path.join(ROOT, 'textures', 'minigames', 'sumo', 'rivals')
KEYS = os.path.join(ROOT, 'textures', 'minigames', 'sumo')
PREVIEW = os.path.join(HERE, 'out', 'sumo_rivals.png')

# family -> [(look, stage, spec line)]; look 'champ' = the world's champion
FAMILIES = {
 'frog': [
  (0, 'kid', 'Kero | squat fy=.24 | lime/cream | frogeyes:lime belly:cream feet:lime | gloss w blush'),
  (1, 'kid', 'Pyon | mochi fy=.24 | green/lemon | frogeyes:green spots:lemon feet:green | wide smile'),
  (2, 'kid', 'Ama | squat fy=.24 sy=1.1 | teal/cream | frogeyes:teal belly:cream feet:teal | dot flat'),
  (3, 'kid', 'Kajika | pebble fy=.24 | lemon/cream | frogeyes:lemon belly:cream feet:lemon | glance w'),
  (4, 'kid', 'Gero | squat fy=.24 | sky/navy | frogeyes:sky dapple:navy feet:sky | lid flat'),
  (5, 'kid', 'Tono | mochi fy=.24 | leaf/char | frogeyes:leaf dapple:char belly:cream feet:leaf | stern flat'),
  ('champ', 'adult', 'Gama | squat fy=.26 | olive/cream | frogeyes:olive warts belly:cream feet:olive | heavy wavy'),
 ],
 'turtle': [
  (0, 'adult', 'Kame | turtle | wood/sour | hexes:wood shellrim:crust turtlehead:sour feet:sour | dot flat'),
  (1, 'adult', 'Nonbiri | turtle | moss/olive | hexes:moss shellrim:olive turtlehead:olive feet:olive | sleep w'),
  (2, 'adult', 'Ishi | turtle | stone/olive | hexes:stone shellrim:stone turtlehead:olive feet:olive | lid flat'),
  (3, 'adult', 'Midori | turtle | leaf/lime | hexes:leaf shellrim:lime turtlehead:lime feet:lime | gloss smile'),
  (4, 'adult', 'Suppon | turtle sy=.8 | olive/cream | shellrim:olive turtlehead:cream feet:cream | glance pout'),
  ('champ', 'legend', 'Minogame | turtle | moss/cream | hexes:moss shellrim:olive turtlehead:cream feet:cream sprout | heavy flat stache'),
 ],
 'otter': [
  (0, 'kid', 'Kawa | bean | choc/cream | ears_bear:choc muzzle:cream belly:cream clamshell:peach whiskers tail:choc | gloss w'),
  (1, 'kid', 'Uso | egg | wood/cream | ears_bear:wood muzzle:cream belly:cream clamshell:peach whiskers tail:wood | glance smirk'),
  (2, 'kid', 'Nuru | bean | rust/cream | ears_bear:rust muzzle:cream belly:cream whiskers tail:rust | lid w'),
  (3, 'kid', 'Sube | bean | stone/white | ears_bear:stone muzzle:white belly:white clamshell:pink whiskers tail:stone | dot w'),
  (4, 'kid', 'Choro | egg | crust/cream | ears_bear:crust muzzle:cream belly:cream whiskers tail:crust | happy w'),
  ('champ', 'adult', 'Kawauso | bean | choc/cream | ears_bear:choc muzzle:cream belly:cream clamshell:gold whiskers tail:choc hat:crust | glance smirk'),
 ],
 'robot': [
  (0, 'adult', 'Robo | cube | metal/spicy | antenna:spicy bolts mitts:metal | visor flat'),
  (1, 'adult', 'Tin | lantern | sky/lemon | antenna:lemon bolts mitts:metal | wide teeth'),
  (2, 'adult', 'Bolt | cube | lemon/char | antenna:spicy bolts mitts:char | gloss grin'),
  (3, 'adult', 'Gear | ball | stone/lime | antennae:lime bolts mitts:metal | visor w'),
  (4, 'adult', 'Spring | lantern | coral/metal | antenna:metal bolts mitts:metal | dot o'),
  (5, 'adult', 'Sparky | cube | teal/lemon | antenna:lemon bolts mitts:metal lightning | wide flat'),
  ('champ', 'legend', 'Big Robo | cube | spicy/metal | antenna:lemon bolts mitts:metal chip | visor teeth'),
 ],
 'beetle': [
  (0, 'kid', 'Kabuto | egg fy=.3 | rust/choc | kabuto:choc pronotum:choc split buglegs:char | side flat'),
  (1, 'kid', 'Kuwagata | egg fy=.3 | choc/wood | pincers:wood pronotum:char split buglegs:char | side flat'),
  (2, 'kid', 'Kanabun | ball fy=.32 | teal/lime | pronotum:teal split buglegs:char antennae:char | gloss flat'),
  (3, 'kid', 'Atlas | egg fy=.3 | stone/char | atlashorns:char pronotum:char split buglegs:char | side flat'),
  (4, 'kid', 'Hercules | egg fy=.3 | olive/char | herculeshorn:char pronotum:char dapple:char split buglegs:char | side flat'),
  ('champ', 'adult', 'Beetle King | egg fy=.3 | gold/char | herculeshorn:char pronotum:char split buglegs:char sparkles | side flat'),
 ],
 'sumo': [
  (0, 'adult', 'Jonidan | bun | peach/char | topknot:char band:char arms:peach feet:peach | gloss flat blush'),
  (1, 'adult', 'Makushita | mound | peach/navy | topknot:char band:navy arms:peach feet:peach | stern flat'),
  (2, 'adult', 'Juryo | bun | peach/teal | topknot:char band:teal arms:peach feet:peach | lid flat'),
  (3, 'adult', 'Maegashira | daruma | peach/purple | topknot:char band:purple arms:peach feet:peach | cross frown'),
  (4, 'adult', 'Komusubi | bun | peach/sky | topknot:char band:sky arms:peach feet:peach | glance smirk'),
  (5, 'adult', 'Sekiwake | mound | peach/leaf | topknot:char band:leaf arms:peach feet:peach | stern pout'),
  (6, 'adult', 'Ozeki | daruma | peach/berry | topknot:char band:berry arms:peach feet:peach | heavy flat'),
  (7, 'adult', 'Yokozuna | daruma | peach/char | topknot:char band:char tsuna shide arms:peach feet:peach | cross flat'),
  ('champ', 'legend', 'Harvest Yokozuna | daruma | peach/gold | topknot:char band:gold tsuna shide arms:peach feet:peach sparkles | stern flat'),
 ],
}

SHADOW_DARK = np.array([30, 22, 48], np.float32)
SHADOW_LIGHT = np.array([104, 84, 146], np.float32)
EYE_GLOW = (236, 96, 210, 255)


def shadow(im, face):
    """the mystery challenger: the figure in shadow (dark violet, its light parts a little lighter),
    the outline kept, two glowing eyes where its eyes are"""
    a = np.asarray(im, np.float32).copy()
    lum = (a[..., 0] * .3 + a[..., 1] * .59 + a[..., 2] * .11) / 255
    ink = lum < .16                                      # (the outline and the eyes stay dark)
    body = (a[..., 3] > 0) & ~ink
    a[..., :3][body] = (SHADOW_DARK + (SHADOW_LIGHT - SHADOW_DARK) * (lum[body] ** 1.3)[:, None])
    a[..., :3][ink & (a[..., 3] > 0)] = (14, 8, 24)
    out = Image.fromarray(a.astype(np.uint8), 'RGBA').copy()
    fx, fy, sp, er = face
    px = out.load()
    for ex in (fx - sp, fx + sp):
        for dy in range(-2, 2):
            for dx in range(-2, 2):
                x, y = int(ex) + dx, int(fy) + dy
                if 0 <= x < out.width and 0 <= y < out.height:
                    px[x, y] = (255, 236, 252, 255) if (dx in (-1, 0) and dy in (-1, 0)) else EYE_GLOW
    return out


def key(gold):
    """a wind-up key seen side on: the stem (left, into the robot) and the two-lobed bow"""
    c = Canvas(G.W, G.H, G.K, G.F, anchor=(55, 93))
    pal = G.P['gold'] if gold else G.P['metal']
    f_ = G.sfield(c, G.chain((36, 50), (58, 50), 2.6, 2.6, 6) + [(62, 50, 3.4, 3.4), (70, 41, 7.5, 6.5), (70, 59, 7.5, 6.5)])
    m = f_ > 1
    material(c, height(f_, .5), m, pal, bump=4, spec_amt=.8, spec_pow=14, grain=.03)
    outline(c, c.a > .5, 1.0)
    outline(c, c.a > .5, 1.0)
    _, small = shrink(c)
    im = small.resize((G.W * 2, G.H * 2), Image.NEAREST)
    return im.crop(im.getbbox())


def main():
    os.makedirs(DEST, exist_ok=True)
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    cells = []
    for fam, looks in FAMILIES.items():
        row = []
        for look, stage, line in looks:
            name, spec, _ = G.parse(line)
            G.LAST_FACE = None
            im = G.render(spec, stage, name)
            im.save(os.path.join(DEST, f'{fam}_{look}.png'))
            row.append(im)
            if look == 0:                                # the mystery challenger: the family's first, bigger
                G.LAST_FACE = None
                big = G.render(spec, 'adult', name)
                sh = shadow(big, G.LAST_FACE)
                sh.save(os.path.join(DEST, f'{fam}_shadow.png'))
                row.append(sh)
            print(fam, look, stage, im.getbbox(), flush=True)
        cells.append(row)
    for gold in (False, True):
        key(gold).save(os.path.join(KEYS, 'key_gold.png' if gold else 'key.png'))
    cw, ch = 116, 104
    sheet = Image.new('RGBA', (cw * max(len(r) for r in cells), ch * len(cells)), (236, 220, 192, 255))
    for j, row in enumerate(cells):
        for i, im in enumerate(row):
            sheet.alpha_composite(im, (i * cw + 3, j * ch + 2))
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(PREVIEW)
    print('ok', PREVIEW)


if __name__ == '__main__':
    main()
