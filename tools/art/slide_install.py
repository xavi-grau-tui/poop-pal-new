"""The menus' new wooden slides into the game (the user, 2026-11-04: the menu slides as previewed in
docs/mockups/menu_frames/v5/option_E/in_app.png; "extend the inner texture of the diapositives, where
the actual menus are, until the very edge of the diapositives we agreed").

Each menu's slide is one opaque texture, as today's textures/menus/diapositive1-3.png: the window's
fill (the Food grid, the Games and Decor wood bands) is painted in it, the menu drawn on top. For each:

  1. today's texture as the game shows it (402 x 394, nearest, at the sprite's scale: 883 x 908)
  2. its window's fill carried on out to the new slide's stepped corners, today's round ring off
     (slide_preview.fill_corners: along the nearer side by whole repeats of its pattern, the corners'
     last CORNER_SQ px rebuilt from the sides beside them)
  3. the new wooden slide over it (slide_wood.py's, at 883 x 908, 1:1 on the phone)

Writes textures/menus/slide_<tone>.png (food: clear, games: mid, settings / decor: brown) and
slide_clear_ring.png (the clear slide's frame round its window, RING_W px: the Food menu's shutter
slides in behind it, as diapositive1_ring.png; the band's dots and arrow stay above). The old textures stay as they were. The sprites in
scenes/main.tscn use the new ones at scale 1.

Run: .venv/bin/python tools/art/slide_install.py [--slides <dir>] [--brown <dir>]
"""
import argparse
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
from slide_preview import fill_corners, SCALE     # noqa: E402

M = "docs/mockups/menu_frames/"
OUT = "textures/menus/"
MENUS = [("clear", 1), ("mid", 2), ("brown", 3)]   # (food, games, settings / decor: today's tints)
RING_W = 40                                       # (the Food shutter's overlay: the frame this far round the window)
RING_OFF = 6                                      # (today's ring and this many px round it: off)

ap = argparse.ArgumentParser()
ap.add_argument("--slides", default=M + "v5/option_E/", help="slide_<tone>.png for clear and mid")
ap.add_argument("--brown", default=M + "v5/option_E_brown_lines0.5/", help="slide_brown.png from here")
args = ap.parse_args()

ring_tex = np.array(Image.open(OUT + "diapositive1_ring.png").convert("RGBA"))[..., 3] > 0
for tone, tint in MENUS:
    new = Image.open((args.brown if tone == "brown" else args.slides) + "slide_%s.png" % tone).convert("RGBA")
    w, h = new.size
    assert (w, h) == (round(402 * SCALE[0]), round(394 * SCALE[1])), (w, h)
    old = np.array(Image.open(OUT + "diapositive%d.png" % tint).convert("RGBA").resize((w, h), Image.NEAREST))
    ring = np.array(Image.fromarray(ring_tex).resize((w, h), Image.NEAREST))
    inside = ndimage.binary_fill_holes(ring) & ~ndimage.binary_dilation(ring, iterations=RING_OFF)
    na = np.array(new)
    fill = fill_corners(old, inside, na[..., 3] > 128)
    win = ndimage.binary_fill_holes(na[..., 3] > 128) & ~(na[..., 3] > 128)
    base = np.zeros_like(fill)
    base[win | (na[..., 3] > 0)] = fill[win | (na[..., 3] > 0)]
    base[..., 3] = np.where(win | (na[..., 3] > 0), 255, 0)
    al = na[..., 3:4].astype(float) / 255
    outp = base.astype(float)
    outp[..., :3] = na[..., :3] * al + base[..., :3] * (1 - al)
    outp[..., 3] = np.where(win, 255, na[..., 3])            # (the window opaque, the edge as the slide's)
    Image.fromarray(np.round(outp).astype(np.uint8)).save(OUT + "slide_%s.png" % tone)
    if tone == "clear":                        # (only round the window: the shutter's edges hide under
        ring_px = ndimage.distance_transform_edt(~win) <= RING_W   # it; the band's dots, arrow and
        r = np.array(new)                                            # legend stay on top, as before)
        r[..., 3] = np.where(ring_px, r[..., 3], 0)
        Image.fromarray(r).save(OUT + "slide_clear_ring.png")
    print(tone, "->", OUT + "slide_%s.png" % tone)
