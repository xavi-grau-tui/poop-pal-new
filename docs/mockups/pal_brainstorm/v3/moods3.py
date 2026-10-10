"""The hunger ladder (the user's idea, 2026-10-10): Ember's face options become moods as time goes
by without food: current -> B -> D -> A -> C. A snack of the pal's own size brings it back to
"just fed" (no evolution); food of the next size makes it grow.
    python moods3.py -> moods.png"""
import os, sys
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import palgen3 as G
from hires import Canvas, outline, shrink
import forms_gen as fg

PROJ = G.PROJ
# (eyes, mouth, extras): the Ember options sheet, in the user's order
MOODS = [('Just fed', 'current', ('gloss', 'smile', ['blush']), '0 - 30 min'),
         ('Fine', 'B', ('tiny', 'v', []), '30 min - 2 h'),
         ('Peckish', 'D', ('dot', 'flat', []), '2 - 6 h'),
         ('Hungry', 'A', ('gloss', 'flat', []), '6 - 12 h'),
         ('Grumpy', 'C', ('lid', 'flat', []), '12 h +')]
PALS = [('Ember', 'H', None), ('Picklet', 'U', None),
        ('Bud', None, 'Bud | bean | green | leaf2 | gloss flat | x'),
        ('Daruma', None, 'Daruma | daruma | spicy | darumaface:white | dot flat | x'),
        ('Kappa', None, 'Kappa | gum | green/teal | plate:ice beak_f shell:moss | gloss flat | x'),
        ('Fried Egg', None, 'Fried Egg | fried | white/greasy | | dot flat | x'),
        ('Swirl', None, 'Swirl | swirl | sweet/navy | | dot flat | x')]


def original(fam, face):
    """Ember / Picklet: their own in-game body (forms_gen), with a mood face"""
    c = Canvas(G.W, G.H, G.K, G.F, anchor=(55, G.GROUND))
    f, m, top, fy = fg.body(c, fam, 1.3, pal=fg.PICKLE if fam == 'U' else None)
    if fam == 'H':
        fg.stem(c, 57.5, top + .5, 1.3)
    outline(c, c.a > .5, 1.0)
    outline(c, c.a > .5, 1.0)
    g = G.Geo(c, m)
    G.face(c, g, 55, fy, face[0], face[1], face[2], 'baby', G.P['spicy' if fam == 'H' else 'sour'])
    _, small = shrink(c)
    return small.resize((G.W * 2, G.H * 2), Image.NEAREST)


def mood(line, face, stage):
    n, spec, _ = G.parse(line)
    spec['eyes'], spec['mouth'], spec['extras'] = face[0], face[1], list(face[2])
    return G.render(spec, stage, n)


font = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 16)
fontb = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 30)
fonts = ImageFont.truetype(PROJ + '/fonts/Pixellari.ttf', 20)
CW, CH, LW, M = 190, 180, 130, 30
W_ = M * 2 + LW + CW * 5
H_ = 170 + CH * len(PALS) + 70
sh = Image.new('RGBA', (W_, H_), (244, 240, 230, 255))
d = ImageDraw.Draw(sh)
d.text((M, 22), 'Moods: the longer without food, the grumpier', fill=(40, 30, 30), font=fontb)
d.text((M, 62), 'Your idea, with Ember\'s face options in your order: current -> B -> D -> A -> C. The face style is the pal\'s', fill=(120, 110, 100), font=font)
d.text((M, 82), 'own; the mood changes it. A snack of its own size brings it back to "Just fed" (no change); food of the', fill=(120, 110, 100), font=font)
d.text((M, 102), 'next size makes it grow. Times are a first guess (the meal countdown is 30 min).', fill=(120, 110, 100), font=font)
for j, (name, opt, face, t) in enumerate(MOODS):
    x = M + LW + j * CW
    d.text((x + (CW - d.textlength(name, font=fonts)) / 2, 132), name, fill=(70, 60, 55), font=fonts)
    tt = f'{t}  ({opt})'
    d.text((x + (CW - d.textlength(tt, font=font)) / 2, 154), tt, fill=(150, 140, 130), font=font)
for i, (name, fam, line) in enumerate(PALS):
    y = 176 + i * CH
    d.rounded_rectangle([M - 8, y, W_ - M + 8, y + CH - 10], radius=12, fill=(255, 252, 244), outline=(214, 204, 188), width=2)
    d.text((M + 6, y + CH / 2 - 10), name, fill=(70, 60, 55), font=fonts)
    stage = 'baby' if name in ('Ember', 'Picklet', 'Bud') else 'kid'
    for j, (_, _, face, _) in enumerate(MOODS):
        im = original(fam, face) if fam else mood(line, face, stage)
        big = im.resize((110 * 2 * 3 // 4 * 1, 100 * 2 * 3 // 4), Image.NEAREST) if False else im.resize((165, 150), Image.NEAREST)
        sh.alpha_composite(big, (M + LW + j * CW + (CW - 165) // 2, y + 6))
d.text((M, H_ - 40), 'Later, a sick face and "back one stage" can follow Grumpy (roadmap: care consequences).', fill=(120, 110, 100), font=font)
sh.save(os.path.join(HERE, 'moods.png'))
print(sh.size)
