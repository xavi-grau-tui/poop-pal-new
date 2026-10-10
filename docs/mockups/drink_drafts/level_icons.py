"""Pixel level icons for the drink types (hand-placed pixels, 1 char = 1 px).
# = outline, a = colour, b = highlight, c = shade."""
from PIL import Image

GRIDS = {
 'watery': [            # a blue drop
  "....#....",
  "...#b#...",
  "...#a#...",
  "..#bac#..",
  ".#bbaac#.",
  ".#baaac#.",
  "#baaaacc#",
  "#aaaaacc#",
  ".#aaacc#.",
  "..#ccc#..",
  "...###...",
 ],
 'fizzy': [             # a bubble
  "..#####..",
  ".#aaaaa#.",
  "#abbaaaa#",
  "#abaaaaa#",
  "#aaaaaac#",
  "#aaaaaac#",
  "#aaaaacc#",
  ".#acccc#.",
  "..#####..",
 ],
 'caffeinated': [       # a lightning bolt
  "....####",
  "...#bba#",
  "...#ba#.",
  "..#ba#..",
  "..#ba###",
  ".#bbaaa#",
  ".###aac#",
  "...#ac#.",
  "..#ac#..",
  "..#c#...",
  "..##....",
 ],
 'milky': [             # a white drop
  "....#....",
  "...#b#...",
  "...#a#...",
  "..#bac#..",
  ".#bbaac#.",
  ".#baaac#.",
  "#baaaacc#",
  "#aaaaacc#",
  ".#aaacc#.",
  "..#ccc#..",
  "...###...",
 ],
 'fruity': [            # a star
  ".....#.....",
  "....#b#....",
  "....#a#....",
  "#####a#####",
  "#bbbaaaaac#",
  ".#baaaaac#.",
  "..#aaaaa#..",
  "..#aa#ac#..",
  ".#ac#.#cc#.",
  ".###...###.",
 ],
}
COLS = {
 'watery':      {'a': (96, 156, 222), 'b': (196, 228, 250), 'c': (54, 100, 170)},
 'fizzy':       {'a': (236, 120, 110), 'b': (255, 222, 212), 'c': (186, 66, 66)},
 'caffeinated': {'a': (250, 204, 60), 'b': (255, 244, 172), 'c': (206, 146, 30)},
 'milky':       {'a': (240, 240, 234), 'b': (255, 255, 255), 'c': (192, 194, 202)},
 'fruity':      {'a': (250, 168, 58), 'b': (255, 228, 150), 'c': (214, 116, 30)},
}
OUT = (60, 40, 32)


def icon(kind):
    g = GRIDS[kind]
    w = max(len(r) for r in g)
    im = Image.new('RGBA', (w, len(g)), (0, 0, 0, 0))
    for y, row in enumerate(g):
        for x, ch in enumerate(row):
            if ch == '#': im.putpixel((x, y), OUT + (255,))
            elif ch in 'abc': im.putpixel((x, y), COLS[kind][ch] + (255,))
    return im


def row(kind, n, gap=1):
    """n icons side by side (the level)"""
    ic = icon(kind)
    im = Image.new('RGBA', (ic.width * n + gap * (n - 1), ic.height), (0, 0, 0, 0))
    for i in range(n):
        im.alpha_composite(ic, (i * (ic.width + gap), 0))
    return im


if __name__ == '__main__':
    import os
    os.makedirs('out/level_icons', exist_ok=True)
    for k in GRIDS:
        icon(k).save(f'out/level_icons/{k}.png')
    print('ok')
