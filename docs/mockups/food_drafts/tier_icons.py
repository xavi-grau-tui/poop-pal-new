"""Pixel size icons for the food types (hand-placed pixels, 1 char = 1 px), the foods' version of
the drinks' level icons (../drink_drafts/level_icons.py): the type's icon once = baby food, twice =
kid food, three times = adult food. Colours: the types' colours from the pal brainstorm
(../pal_brainstorm/palgen.py ramps: sour yellow-green, spicy red, green, greasy yellow-orange,
sweet = the Top Spin letters' blue).
# = outline, a = colour, b = highlight, c = shade, other letters per icon (COLS)."""
from PIL import Image

GRIDS = {
 'green': [             # a leaf (with its vein and stem)
  ".....#####",
  "...##bbbb#",
  "..#bbaaaa#",
  ".#baaaa#a#",
  ".#baa#aac#",
  "#baa#aaac#",
  "#aa#aaacc#",
  "#a#cccc##.",
  "##.####...",
  "#.........",
 ],
 'sweet': [             # a wrapped sweet: a round middle, the wrapper twisted at both ends
  "#...#####...#",
  "##.#bbbaa#.##",
  "#b##bbaaa##b#",
  "#aa#baaac#aa#",
  "#a##aaacc##c#",
  "##.#aaccc#.##",
  "#...#####...#",
 ],
 'greasy': [            # a burger
  "..######..",
  ".#bbbaaa#.",
  "#bbaaaaac#",
  "#aaaaaacc#",
  "##########",
  "#gggggggg#",
  "#pppppppp#",
  "##########",
  "#aaaaaaac#",
  ".########.",
 ],
 'spicy': [             # a flame
  "...#.....",
  "..#a#....",
  "..#aa#.#.",
  ".#aaa##a#",
  ".#aabaaa#",
  "#aabbbaa#",
  "#abbybba#",
  "#abyyyba#",
  ".#abyba#.",
  "..#####..",
 ],
 'sour': [              # a lemon (pointed at both ends)
  "....#####....",
  "..##bbbaa##..",
  ".#bbaaaaaac#.",
  "#bbaaaaaaacc#",
  ".#aaaaaaacc#.",
  "..##acccc##..",
  "....#####....",
 ],
}
COLS = {
 'green':  {'a': (88, 184, 94), 'b': (150, 220, 140), 'c': (50, 144, 68)},
 'sweet':  {'a': (112, 140, 178), 'b': (170, 196, 226), 'c': (82, 106, 144)},
 'greasy': {'a': (240, 158, 30), 'b': (255, 214, 120), 'c': (196, 108, 16), 'g': (120, 186, 70), 'p': (126, 66, 34)},
 'spicy':  {'a': (200, 50, 44), 'b': (240, 120, 60), 'c': (140, 24, 30), 'y': (255, 214, 96)},
 'sour':   {'a': (192, 214, 72), 'b': (232, 242, 160), 'c': (152, 182, 40)},
}
OUT = (60, 40, 32)
TIERS = ['baby', 'kid', 'adult']


def icon(kind):
    g = GRIDS[kind]
    w = max(len(r) for r in g)
    im = Image.new('RGBA', (w, len(g)), (0, 0, 0, 0))
    for y, row in enumerate(g):
        for x, ch in enumerate(row):
            if ch == '#':
                im.putpixel((x, y), OUT + (255,))
            elif ch in COLS[kind]:
                im.putpixel((x, y), COLS[kind][ch] + (255,))
    return im


def row(kind, n, gap=1):
    """n icons side by side, on one baseline (1 = baby food, 2 = kid, 3 = adult)"""
    ic = icon(kind)
    im = Image.new('RGBA', (ic.width * n + gap * (n - 1), ic.height), (0, 0, 0, 0))
    for i in range(n):
        im.alpha_composite(ic, (i * (ic.width + gap), 0))
    return im


if __name__ == '__main__':
    import os
    here = os.path.dirname(os.path.abspath(__file__))
    os.makedirs(os.path.join(here, 'tier_icons'), exist_ok=True)
    for k in GRIDS:
        icon(k).save(os.path.join(here, 'tier_icons', f'{k}.png'))
    print('ok')
