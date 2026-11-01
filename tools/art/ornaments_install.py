"""SUPERSEDED (2026-10-31, rejected by the user: too coarse): use tools/art/ornaments_from_sources.py.
The designer's round-3 ornaments (docs/mockups/hokora_decor/round3/<folder>/, drawn on the 220
homes' pixel) into the game: textures/pet/shrine_new/decor/ at the 925 canvas' scale (x 925/220,
nearest, like the homes), icons copied as they are.

  lantern  <id>.png or <id>_0.png, _1 ... (26 x 42 art px -> 109 x 177), its hook at the top middle
  hanging  <id>.png or frames (up to 90 x 37), hung from its top middle at the beam
  shelf    <id>.png or frames (up to 30 x 36), facing right, its foot at the bottom middle; the
           right-hand ledge mirrors it, or uses <id>_left.png / <id>_left_0.png ... when drawn
  icons    icons/<id>.png (96 x 96)

Run: .venv/bin/python tools/art/ornaments_install.py
"""
import glob
import os
import shutil
from PIL import Image

SRC = "docs/mockups/hokora_decor/round3/"
OUT = "textures/pet/shrine_new/decor/"
K = 925 / 220
SKIP = ("source_", "set_preview", "tree_gap", "inside_before")

os.makedirs(OUT + "icons", exist_ok=True)
n = 0
for f in sorted(glob.glob(SRC + "*/*.png")):
    name = os.path.basename(f)
    if name.startswith(SKIP) or name.endswith("_8x.png") or "animation_review" in f:
        continue
    im = Image.open(f).convert("RGBA")
    im.resize((round(im.width * K), round(im.height * K)), Image.NEAREST).save(OUT + name)
    n += 1
for f in sorted(glob.glob(SRC + "*/icons/*.png")):
    shutil.copy(f, OUT + "icons/" + os.path.basename(f))
print(n, "pieces,", len(os.listdir(OUT + "icons")), "icons")
