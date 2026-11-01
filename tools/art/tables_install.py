"""The v6 offering tables (docs/mockups/hokora_homes/v6/tables/: front faces only, the user 2026-11-01)
into the game: textures/pet/homes/<home>/table.png on the 925 canvas, each table pixel 2 x 2 (the
lanterns' definition), standing where the home's v5 table stood (its middle and its foot); a two-part
table's tray sits on its base. table_side.png is its outline in a dark mid tone (Shrine stacks copies
of it for the depth, the face last). Run after tools/art/homes_install.py:

    .venv/bin/python tools/art/tables_install.py
"""
import os
import numpy as np
from PIL import Image

SRC = "docs/mockups/hokora_homes/v6/tables/"
OUT = "textures/pet/homes/"
CANVAS = 925
PX = 2                                   # (screen pixels per table pixel, the lanterns')


def part(name):
    path = SRC + name + "_116.png"
    if not os.path.exists(path):
        return None
    im = Image.open(path).convert("RGBA")
    im = im.crop(im.getbbox())
    return im.resize((im.width * PX, im.height * PX), Image.NEAREST)


def mid_tone(img):
    a = np.array(img)
    body = a[a[..., 3] > 0][:, :3].astype(float)
    bl = body.mean(axis=1)
    mid = body[(bl > np.percentile(bl, 30)) & (bl < np.percentile(bl, 80))].mean(axis=0)
    return tuple(int(c * 0.47) for c in mid)


for home in sorted(os.listdir(OUT)):
    one = part(home + "_table_front")
    base, tray = part(home + "_base_front"), part(home + "_tray_front")
    if one is None and base is None:
        continue
    old = Image.open(OUT + home + "/table.png").getbbox()      # (where the v5 table stood)
    mid, foot = (old[0] + old[2]) // 2, old[3]
    canvas = Image.new("RGBA", (CANVAS, CANVAS))
    if one is not None:
        canvas.alpha_composite(one, (mid - one.width // 2, foot - one.height))
    else:
        canvas.alpha_composite(base, (mid - base.width // 2, foot - base.height))
        canvas.alpha_composite(tray, (mid - tray.width // 2, foot - base.height - tray.height + PX))
    canvas.save(OUT + home + "/table.png")
    a = np.array(canvas)
    side = np.zeros_like(a)
    side[a[..., 3] > 0] = mid_tone(canvas) + (255,)
    Image.fromarray(side, "RGBA").save(OUT + home + "/table_side.png")
    print(home)
