"""The designer's nine new homes (docs/mockups/hokora_homes/<home>/, 110 x 110 art) into the game:
textures/pet/homes/<home>/ on the forest hokora's 925 x 925 canvas (nearest, the same grid).

  front.png      the home minus its recess: in front of the spirit
  inside.png     the recess behind the spirit (the designer's inside layer), slides deeper with the tilt
  socket.png     the recess's outline in its darkest colour: the window the inside is seen through
                 (Shrine clips the inside to it) and what shows behind it when it slides
  side.png       the whole home's outline in a dark mid colour: stacked copies make its 3D sides
  side_back.png  the same with a dark rim (the back copy)
  table.png      (v5) the home's own offering table, in place; table_side.png its outline in a dark
                 mid colour (stacked copies make its 3D)
  icon.png       the designer's 96 x 96 menu icon

v5 (docs/mockups/hokora_homes/v5/<home>/: front, inside, table, guide, icon) replaces v4 when it exists;
v6 and v6_1 (docs/mockups/hokora_homes/v6/, v6_1/<home>/, the same files, 2026-11-01) replace it in
turn when they exist (a v6_1 folder with only a bell and a guide keeps v6's home); the home's bell and
beads (bell.png, bead_1.png, bead_2.png) are redrawn at the red lantern's look (2 x 2 pixels, its thick
plum outline: ornaments_from_sources.shrink; the user, 2026-11-02). The v6
tables (front faces) are placed by tools/art/tables_install.py, run after this.

Prints each home's socket colour for HokoraCatalog.HOMES. Run: .venv/bin/python tools/art/homes_install.py
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage
from ornaments_from_sources import shrink     # (the bells: the red lantern's 2 x 2 pixel and thick plum outline)

SRC = "docs/mockups/hokora_homes/"
OUT = "textures/pet/homes/"
HOMES = ["neon_cyber", "moon", "golden", "ruined_night", "tree_hollow", "ramen_stall",
         "capsule_apartment", "arcade_cabinet", "bathhouse", "fire"]
CANVAS = 925
RIM = (54, 35, 45)
V6_HOMES = []                                   # (v6's Ruined Night: a hard cut in its opening, back to the designer)
V61_HOMES = ["golden", "ramen_stall", "moon"]
CUT_BELLS = ["capsule_apartment"]              # (its delivered bell is cut off on one side)
V_FRONT_ONLY = ["v6_3b/", "v6_3/"]                      # (deliveries with only a new front: the Arcade's side trays, 2026-11-02)
V62_HOMES = ["arcade_cabinet", "capsule_apartment", "ruined_night"]   # (v6.2, 2026-11-02)   # (v6.1's approved fronts, 2026-11-01; its Capsule and Arcade
                                         # go round again, its other fronts are re-exports of the approved ones)                       # (the forest side_back's rim colour)


def rgba(path):
    return np.array(Image.open(path).convert("RGBA"))


def save(arr, path):
    Image.fromarray(arr.astype(np.uint8), "RGBA").resize((CANVAS, CANVAS), Image.NEAREST).save(path)


def flat(mask, colour):
    out = np.zeros(mask.shape + (4,), np.uint8)
    out[mask] = colour + (255,)
    return out


def mid_tone(img, mask):
    """The picture's middle tones (no outline, no highlights) at ~47%: its 3D sides' colour."""
    body = img[mask][:, :3].astype(float)
    bl = body.mean(axis=1)
    mid = body[(bl > np.percentile(bl, 30)) & (bl < np.percentile(bl, 80))].mean(axis=0)
    return tuple(int(c * 0.47) for c in mid)


for home in HOMES:
    d = SRC + home + "/"
    v5 = SRC + next(v for v in ("v6_2/", "v6_1/", "v6/", "v5_tech/", "v5/") if os.path.exists(SRC + v + home + "/front.png")
                    and (v != "v6_2/" or home in V62_HOMES) and (v != "v6_1/" or home in V61_HOMES)
                    and (v != "v6/" or home in V6_HOMES)) + home + "/"
    for f in ("bell.png", "bead_1.png", "bead_2.png"):   # (the newest delivery's, at the lanterns' look)
        src = next((SRC + v + home + "/" + f for v in ("v6_2/", "v6_1/") if os.path.exists(SRC + v + home + "/" + f)), None)
        if src:
            im = Image.open(src).convert("RGBA")
            if f == "bell.png" and home in CUT_BELLS:     # (cut on its right: the left half mirrored round its loop)
                a = np.array(im)
                top = np.where(a[:12, :, 3].any(0))[0]
                axis = (top.min() + top.max() + 1) / 2.0
                w = int(axis)
                left = a[:, :w]
                full = np.zeros((a.shape[0], 2 * w, 4), np.uint8)
                full[:, :w] = left
                full[:, w:] = left[:, ::-1]
                im = Image.fromarray(full, "RGBA")
            shrink(im.crop(im.getbbox()), (im.width + 8, im.height + 8), 2).save(OUT + home + "/" + f)   # (+ the outline: same size)
    os.makedirs(OUT + home, exist_ok=True)
    if os.path.exists(v5 + "front.png"):
        d = v5
        front = rgba(next((SRC + v + home + "/front.png" for v in V_FRONT_ONLY if os.path.exists(SRC + v + home + "/front.png")), d + "front.png"))
        inside = rgba(d + "inside.png")
        in_mask = inside[..., 3] > 0
        if os.path.exists(d + "hollow_mask.png"):  # (v5_tech: the inside runs past the hole; the window is the hole)
            in_mask = rgba(d + "hollow_mask.png")[..., 3] > 0
        else:                                      # (the window: the inside where the front has its hole, the opening's part)
            hole = in_mask & ~(front[..., 3] > 0)
            lab, _ = ndimage.label(hole)
            c = front.shape[0] // 2
            keep = lab[c, c] if lab[c, c] else np.bincount(lab.ravel())[1:].argmax() + 1
            in_mask = ndimage.binary_fill_holes(lab == keep)
        if os.path.exists(d + "glass.png"):
            Image.open(d + "glass.png").convert("RGBA").resize((CANVAS, CANVAS), Image.NEAREST).save(OUT + home + "/glass.png")
        g = rgba(next((SRC + v + home + "/guide.png" for v in ("v6_2/", "v6_1/") if os.path.exists(SRC + v + home + "/guide.png")), d + "guide.png"))
        k = 110.0 / g.shape[0]
        def dots(col):
            ys, xs = np.where((np.abs(g[..., :3].astype(int) - col).sum(-1) < 30) & (g[..., 3] > 0))
            lab, n = ndimage.label(np.isin(np.arange(g.shape[0] * g.shape[1]).reshape(g.shape[:2]), ys * g.shape[1] + xs))
            return [tuple(round(v * k) for v in ndimage.center_of_mass(lab == i + 1)[::-1]) for i in range(n)]
        hooks = (dots((255, 112, 20)), sorted(dots((255, 193, 15))))
        all_mask = (front[..., 3] > 0) | in_mask
        whole = front.copy()
        whole[in_mask & ~(front[..., 3] > 0)] = inside[in_mask & ~(front[..., 3] > 0)]
        table = rgba((d if os.path.exists(d + "table.png") else SRC + "v5/" + home + "/") + "table.png")
        t_mask = table[..., 3] > 0
        save(table, OUT + home + "/table.png")
        save(flat(t_mask, mid_tone(table, t_mask)), OUT + home + "/table_side.png")
    else:
        whole = rgba(d + "front_colour.png")
        inside = rgba(d + "inside.png")
        in_mask = inside[..., 3] > 0
        all_mask = whole[..., 3] > 0
        front = whole.copy()
        front[in_mask] = 0
    save(front, OUT + home + "/front.png")
    save(inside, OUT + home + "/inside.png")
    # the socket: the recess's darkest quarter, averaged
    px = inside[in_mask & (inside[..., 3] > 0)][:, :3].astype(float)
    lum = px.mean(axis=1)
    dark = px[lum <= np.percentile(lum, 25)].mean(axis=0)
    socket = tuple(int(c) for c in dark)
    save(flat(in_mask, socket), OUT + home + "/socket.png")
    side = mid_tone(whole, all_mask)
    save(flat(all_mask, side), OUT + home + "/side.png")
    rim = all_mask & ~(np.roll(all_mask, 1, 0) & np.roll(all_mask, -1, 0) & np.roll(all_mask, 1, 1) & np.roll(all_mask, -1, 1))
    back = flat(all_mask, side)
    back[rim] = RIM + (255,)
    save(back, OUT + home + "/side_back.png")
    Image.open(d + "icon.png").convert("RGBA").save(OUT + home + "/icon.png")
    print('"%s": "#%02x%02x%02x",%s' % ((home,) + socket + (" (v5) bell %s lanterns %s" % hooks if d == v5 else "",)))
