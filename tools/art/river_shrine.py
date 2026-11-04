"""The River Shrine (the 12th home, the designer's v8, the user 2026-11-03) made ready for the game, on
its own 220 grid (docs/mockups/hokora_homes/v8/river_shrine/ -> v8/river_shrine/final/):

  - the shimenawa and shide off the front (the beam's hanging piece is a slot: the user), the inner
    gold brackets behind them again from the outer ones (mirrored round each pillar: x -> 114 - x)
  - the lantern stubs off the pillars (the lanterns hang high under the lower beam, like the other
    homes: the user), the pillar under them from its inner side (the same mirror)
  - the inside (the waterfall wall) and the socket up to the beam, the opening's top (the rope hid it)
  - the pillars' inner edge, delivered with the trays, back in the front
  - the trays as trays.png, for tools/art/homes_install.py (it gives them their depth, ledges_side.png,
    from their own outline: the delivered one was a flat grey strip)

The other layers are the designer's. Prints the tray tops for HokoraCatalog.HOMES "ledges". Run before
tools/art/homes_install.py:

    .venv/bin/python tools/art/river_shrine.py
"""
import os
import numpy as np
from PIL import Image

SRC = "docs/mockups/hokora_homes/v8/river_shrine/"
OUT = SRC + "final/"
AXIS = 219                     # (the torii's middle: x -> 219 - x)
PILLAR = 114                   # (the left pillar's middle: x -> 114 - x)
ROPE_ROWS = (60, 95)           # (the rope and shide, under the lower beam)
ROPE_COLS = (78, 142)
BRACKET_ROWS, BRACKET_COLS = (56, 83), (64, 78)   # (the inner brackets the rope hung from)
STUB_ROWS, STUB_COLS = (82, 102), (36, 57)        # (the left lantern stub, its plate on the pillar)
TOP = 60                       # (the opening's top: under the lower beam)
STONE_DY = 16                  # (rows down the wall to fill its top from)
PILLAR_EDGE = range(62, 66)    # (the left pillar's inner edge in the delivered ledges; the right's mirrored)

os.makedirs(OUT, exist_ok=True)
front = np.array(Image.open(SRC + "front.png").convert("RGBA"))
f = front.copy()
f[slice(*ROPE_ROWS), slice(*ROPE_COLS)] = 0
for y in range(*BRACKET_ROWS):
    for x in range(*BRACKET_COLS):
        f[y, x] = front[y, PILLAR - x]
        f[y, AXIS - x] = front[y, PILLAR - x]
for y in range(*STUB_ROWS):
    for x in range(*STUB_COLS):
        f[y, x] = f[y, PILLAR - x]
        f[y, AXIS - x] = f[y, PILLAR - x]
ledges = np.array(Image.open(SRC + "ledges.png").convert("RGBA"))
for x in PILLAR_EDGE:                              # (the pillars' inner edge, cut with the trays: back in the front)
    for xx in (x, AXIS - x):
        on = ledges[:, xx, 3] > 0
        f[on, xx] = ledges[on, xx]
        ledges[on, xx] = 0
Image.fromarray(f).save(OUT + "front.png")

socket = np.array(Image.open(SRC + "socket.png").convert("RGBA"))
s0 = np.where(socket[..., 3].any(1))[0].min()
s = socket.copy()
lift = s0 - TOP
s[TOP:s0] = socket[s0:s0 + lift]                   # (its rounded top corners, higher)
s[s0:s0 + lift] = socket[s0 + lift]
Image.fromarray(s).save(OUT + "socket.png")

inside = np.array(Image.open(SRC + "inside.png").convert("RGBA"))
i = inside.copy()
for y in range(219, TOP - 1, -1):                 # (its holes too: the shide's shapes were cut out of it)
    for x in range(220):
        if s[y, x, 3] and not i[y, x, 3]:
            below = [i[yy, x] for yy in (y + STONE_DY, y + 2 * STONE_DY, y - STONE_DY) if 0 <= yy < 220 and i[yy, x, 3]]
            if below:
                i[y, x] = below[0]
Image.fromarray(i).save(OUT + "inside.png")

m = ledges[..., 3] > 0
Image.fromarray(ledges).save(OUT + "trays.png")

for name in ("table.png", "icon.png", "bell.png", "bead_1.png", "bead_2.png", "river_shrine_table_front_116.png"):
    Image.open(SRC + name).save(OUT + name)

k = 925 / 220
tops = []
for half in (slice(0, 110), slice(110, 220)):
    cols = np.where(m[:, half].any(0))[0] + half.start
    rows = np.where(m[:, half].any(1))[0]
    tops.append((round((cols.min() + cols.max() + 1) / 2 * k), round(rows.min() * k)))
dark = s[s[..., 3] > 0][:, :3].mean(0).astype(int)
print("ledges", tops, "socket #%02x%02x%02x" % tuple(dark))
