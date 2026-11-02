"""The Arcade's side trays behind the cabinet (the user, 2026-11-02: as if the control panel ran on behind
its sides): the designer's v6.3 trays (the pixels it changed from v6.2), moved down to the panel's
height, with v6.2's whole cabinet drawn over them, so its sides and outline stay complete in front.
-> docs/mockups/hokora_homes/v6_3b/arcade_cabinet/front.png (homes_install.py takes it first).

Run: .venv/bin/python tools/art/arcade_trays_behind.py
"""
import os
import numpy as np
from PIL import Image

SRC = "docs/mockups/hokora_homes/"
DROP = 4                                   # rows: the trays' top (143) a little below the panel's top edge (145)
# thicker, as if nearer (the user: "a bit more in front, to look bigger"): its rows repeated, on the art's
# own grid (the cream top 146-149 -> 6 rows, the red underside 151-152 -> 5 rows)
ROWS = list(range(0, 147)) + [147, 147, 148, 148] + [149, 150] + [151, 151, 152, 152, 152] + list(range(153, 220))

trays = np.array(Image.open(SRC + "v6_3/arcade_cabinet/front.png").convert("RGBA"))
cabinet = Image.open(SRC + "v6_2/arcade_cabinet/front.png").convert("RGBA")
changed = (trays != np.array(cabinet)).any(-1)
layer = np.zeros_like(trays)
layer[changed] = trays[changed]
layer = layer[ROWS][:220]
layer = np.roll(layer, DROP, axis=0)
out = Image.fromarray(layer, "RGBA")
out.alpha_composite(cabinet)
os.makedirs(SRC + "v6_3b/arcade_cabinet", exist_ok=True)
out.save(SRC + "v6_3b/arcade_cabinet/front.png")
out.resize((out.width * 8, out.height * 8), Image.NEAREST).save(SRC + "v6_3b/arcade_cabinet/front_8x.png")
print("ok")
