"""Each home's menu card picture: a corner of it (its top left: roof, pillar, materials), like the
Colours cards show a corner of the forest hokora (the user, 2026-11-01: the whole home in that tiny
card can't be seen). textures/pet/homes/<home>/card.png, 110 x 110 (nearest, as the colour cards).

Run: .venv/bin/python tools/art/homes_cards.py
"""
import os
import numpy as np
from PIL import Image

DIR = "textures/pet/homes/"
SIZE = 330                       # the crop on the 925 canvas (as HokoraCatalog._colour_preview)
NUDGE = {"moon": (70, 130)}      # (where the top-left corner alone is mostly sky)

for home in sorted(os.listdir(DIR)):
    if not os.path.exists(DIR + home + "/front.png"):
        continue
    front = Image.open(DIR + home + "/front.png").convert("RGBA")
    ys, xs = np.where(np.array(front)[..., 3] > 0)
    dx, dy = NUDGE.get(home, (0, 60))
    x, y = xs.min() + dx, ys.min() + dy
    front.crop((x, y, x + SIZE, y + SIZE)).resize((110, 110), Image.NEAREST).save(DIR + home + "/card.png")
    print(home)
