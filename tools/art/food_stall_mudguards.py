"""The Food Stall's mudguards and wheels (the user, 2026-11-02): the designer's wide mudguard drawing
(docs/mockups/hokora_homes/v6_6/mudguard_imagegen_source.png) brought down to its own pixel grid
(67 x 24, each cell's median colour), one over each wheel like a hat, its arch down over the wheel's
top by COVER rows; the right one its mirror, both mirrored about the stall's middle line (column 111),
and the wheels the left one and its mirror (the delivered right one is a column wider). The stall is
v6.6's front, the approved one with only its wheels taken out (homes_install.py). Writes, on the 925
canvas: front.png again without the unused iron hook on its left post (that spot copied from the right
post, mirrored: x -> 220 - x for the posts), wheels.png, ledges.png (the mudguards' faces) and ledges_side.png (their outline in a mid tone,
Shrine stacks it for their depth). Prints the two tray tops for HokoraCatalog.HOMES "ledges". Run after
tools/art/homes_install.py:

    .venv/bin/python tools/art/food_stall_mudguards.py
"""
import numpy as np
from PIL import Image

SRC = "docs/mockups/hokora_homes/v6_6/"
OUT = "textures/pet/homes/ramen_stall/"
BOX = (84, 248, 1548, 729)          # (the drawing in the source)
GRID = (67, 24)                     # (its pixels)
AXIS = 111                          # (the stall's middle line: x -> 2 * AXIS - 1 - x)
LEFT = 4                            # (the left mudguard's first column: centred on the left wheel)
COVER = 2                           # (rows of the wheel's top under the arch)
POST_ROWS, POST_IN = (70, 146), 67  # (the window's left post: its rows, the column inside it)


def big(a):
    return Image.fromarray(a, "RGBA").resize((925, 925), Image.NEAREST)


def mirror(a):
    out = np.zeros_like(a)
    for x in range(a.shape[1]):
        if 0 <= 2 * AXIS - 1 - x < a.shape[1]:
            out[:, 2 * AXIS - 1 - x] = a[:, x]
    return out


src = np.array(Image.open(SRC + "mudguard_imagegen_source.png").convert("RGBA")).astype(float)
x0, y0, x1, y1 = BOX
cw, ch = (x1 - x0) / GRID[0], (y1 - y0) / GRID[1]
piece = np.zeros((GRID[1], GRID[0], 4), np.uint8)
for j in range(GRID[1]):
    for i in range(GRID[0]):
        c = src[int(y0 + (j + 0.25) * ch):int(y0 + (j + 0.75) * ch), int(x0 + (i + 0.25) * cw):int(x0 + (i + 0.75) * cw)].reshape(-1, 4)
        if (c[:, 3] > 128).mean() > 0.5 and (c[:, :3].sum(1) > 15).mean() > 0.5:
            piece[j, i, :3] = np.median(c[:, :3], 0)
            piece[j, i, 3] = 255
mid = GRID[0] // 2
top = next(y for y in range(GRID[1]) if piece[y, mid, 3])
apex = next(y for y in range(top + 3, GRID[1]) if not piece[y, mid, 3])   # (under the arch's middle)

wheels = np.array(Image.open(SRC + "ramen_stall/wheels.png").convert("RGBA"))
wheels[:, AXIS:] = 0
wheels = np.maximum(wheels, mirror(wheels))
wheel_top = np.where(wheels[..., 3].any(1))[0].min()

mud = np.zeros((220, 220, 4), np.uint8)
y = wheel_top - apex + COVER
mud[y:y + GRID[1], LEFT:LEFT + GRID[0]] = piece
mud = np.where(mud[..., 3:4] > 0, mud, mirror(mud))
m = mud[..., 3] > 0
body = mud[m][:, :3].astype(float)
bl = body.mean(1)
side = tuple(int(c * 0.47) for c in body[(bl > np.percentile(bl, 30)) & (bl < np.percentile(bl, 80))].mean(0))
flat = np.zeros_like(mud)
flat[m] = side + (255,)

front = np.array(Image.open(SRC + "ramen_stall/front.png").convert("RGBA"))
hook = front.copy()
for yy in range(54, 73):                          # (the hook, rows 54-72 right of the left post)
    for xx in range(25, 46):
        hook[yy, xx] = front[yy, 220 - xx]
for yy in range(*POST_ROWS):                      # (the window's posts alike, outlined both sides (the user): the
    if hook[yy, POST_IN - 4, 3] and not hook[yy, POST_IN, 3]:    # left one's inner side outlined, the right
        hook[yy, POST_IN] = hook[yy, POST_IN - 6]                # one its mirror, the hole cut it thinner)
        for xx in range(220 - POST_IN, 221 - (POST_IN - 7)):
            hook[yy, xx] = hook[yy, 220 - xx]
big(hook).save(OUT + "front.png")
big(wheels).save(OUT + "wheels.png")
big(mud).save(OUT + "ledges.png")
big(flat).save(OUT + "ledges_side.png")
k = 925 / 220
print("ledges", [(round((LEFT + GRID[0] / 2) * k), round((y + top) * k)), (round((2 * AXIS - LEFT - GRID[0] / 2) * k), round((y + top) * k))])
