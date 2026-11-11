"""The designer's table supports and the forest's own table (round of 2026-11-09, approved by the
user) into the game, at the tables' definition (each pixel 2 x 2, like tables_install.py):

  tree_hollow  the stump's trunk and roots under its stump top (it floated), tucked TUCK px up behind it
  golden       a low black and gold step under its table's feet
  forest       its own wooden bench instead of the River Shrine's stone table (same middle, same foot)

A support goes into table.png behind the table (the table's top doesn't move, so neither do the
offering and the spirit: Shrine._table_top) and table_side.png is rebuilt from the whole, so it gets
the same built sides. Rerunning is harmless. Run after tables_install.py:

    .venv/bin/python tools/art/supports_install.py
"""
import numpy as np
from PIL import Image

H = "textures/pet/homes/"
D = "docs/mockups/hokora_homes/"
PX = 2
SUPPORTS = {   # home: (game-size picture, px it tucks up behind the table)
    "tree_hollow": (D + "supports/tree_hollow/tree_hollow_base_game_size_preview.png", 6),
    "golden": (D + "supports/golden_temple/golden_temple_base_game_size_preview.png", 2),
}
FOREST = D + "forest_table/forest_table_front_116x44_preview.png"


def big(path):
    im = Image.open(path).convert("RGBA")
    im = im.crop(im.getbbox())
    return im.resize((im.width * PX, im.height * PX), Image.NEAREST)


def mid_tone(img):                       # (as tables_install.py)
    a = np.array(img)
    body = a[a[..., 3] > 0][:, :3].astype(float)
    bl = body.mean(axis=1)
    mid = body[(bl > np.percentile(bl, 30)) & (bl < np.percentile(bl, 80))].mean(axis=0)
    return tuple(int(c * 0.47) for c in mid)


def save(home, canvas):
    canvas.save(H + home + "/table.png")
    a = np.array(canvas)
    side = np.zeros_like(a)
    side[a[..., 3] > 0] = mid_tone(canvas) + (255,)
    Image.fromarray(side, "RGBA").save(H + home + "/table_side.png")


for home, (path, tuck) in SUPPORTS.items():
    table = Image.open(H + home + "/table.png").convert("RGBA")
    x0, y0, x1, y1 = table.getbbox()
    base = big(path)
    bx = (x0 + x1) // 2 - base.width // 2
    k = base.height // 2                            # (its lower half: the table covers the tucked top)
    here = np.array(table)[y1 - k:y1, bx:bx + base.width]
    want = np.array(base)[-k:]
    solid = want[..., 3] == 255
    if here.shape[:2] == (k, base.width) and (here[solid] == want[solid]).all():
        print(home, "already has its support")     # (a rerun: its bottom is the support)
        continue
    canvas = Image.new("RGBA", table.size)
    canvas.alpha_composite(base, (bx, y1 - tuck))
    canvas.alpha_composite(table)
    save(home, canvas)
    print(home, "table", (x0, y0, x1, y1), "support", base.size, "top at", y1 - tuck)

old = Image.open(H + "forest/table.png").convert("RGBA").getbbox()
bench = big(FOREST)
mid, foot = (old[0] + old[2]) // 2, old[3]
canvas = Image.new("RGBA", (925, 925))
canvas.alpha_composite(bench, (mid - bench.width // 2, foot - bench.height))
save("forest", canvas)
print("forest bench", bench.size, "foot", foot)
