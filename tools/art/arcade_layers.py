"""The Arcade's game layers (the user, 2026-11-02/03): final_k_study (the chosen ImageGen study on the
220 grid) for their shapes, edited: the joystick moved up and left, between the table and the left tray;
both arms and their red braces off, the caps' diagonal shoulders kept with a 2 px outline, the left
arm's bar put up on its pillar in place of the top hooks (both off), the bell hangs from it; the deck's
and trays' painted perspective at their ends flattened, so the game's 3D alone shows their sides. Then
repainted from the designer's final_l study (REF): each pixel the commonest colour of its block, the
lettering cleaner (block means at the study's own pixel phase, snapped to its colours), the coin grille
as it was. Its side trays (trays.png: front faces only, drawn behind the cabinet, HOMES
"ledges_behind", the game gives them depth) with their copies (ledges_side.png) two-toned so the top
reads as the tray's own. The screen's glass as before: a flat light-blue tint (GLASS) over the window,
its corners rounded a pixel. The home's 3D sides (side.png, side_back.png) again from this front.
Writes textures/pet/homes/arcade_cabinet/front.png, ledges.png, ledges_side.png, glass.png, side.png
and side_back.png on the 925 canvas; prints the middles of the trays' visible tops for HOMES "ledges".
Run after tools/art/homes_install.py and tools/art/tables_install.py:

    .venv/bin/python tools/art/arcade_layers.py
"""
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = "docs/mockups/hokora_homes/v7/arcade_cabinet/final_k_study/"
OUT = "textures/pet/homes/arcade_cabinet/"
LIP = 4                             # (the trays' top rows, under their outline: the top's colour)
GLASS = (164, 184, 250, 96)
JOY_ROWS, JOY_COLS, JOY_DX, JOY_DY = (146, 164), (68, 84), -13, -2   # (the joystick, and where it goes)
PLAIN_COL = 96                                         # (a plain column of the deck)
ARM_ROWS = (47, 69)                                    # (the arms and braces, from the caps' bottom row)
KEEP = [36, 39, 40, 41, 42, 43, 45, 45, 45, 46, 47] + [48] * 11   # (per row from 47: the first column kept, left side)
BAR_ROWS, BAR_X, BAR_DX, BAR_DY = (47, 58), 41, 2, -33  # (the left bar: its rows, its columns, where it goes)
BAR_STRIPE = 34                                         # (the bar's own red is left of this column)
HOOK_ROWS, HOOK_COLS = (10, 25), [(30, 45), (176, 192)]   # (the top hooks: their rows and columns)
OUTLINE = (0, 0, 0, 255)
END_ROWS, END_COLS = (146, 170), (38, 51)              # (the deck's left end, painted in perspective; the right mirrored)
SCREW = (40, 46, 160, 165)                             # (its plate's screw there: x0, x1, y0, y1)
TRAY_END = 36                                          # (the left tray's inner end column)
OUTLINE_W, THIN_ROWS = 2, (36, 58)                     # (the outline's width elsewhere; the shoulders' rows)
REF = "docs/mockups/hokora_homes/v7/arcade_cabinet/final_l/imagegen_sign_reference.png"
REF_BOX = (6, 5, 1247, 1243)                           # (the cabinet in it: grid pixels 1-218 across, 1-217 down)
GRILLE = (76, 146, 178, 206)                           # (the coin grille, kept: x0, x1, y0, y1)
SIGN = (66, 156, 20, 46)                               # (the lettering inside the sign's gold frame)
SIGN_PHASE = (0.0, -0.5)                               # (study px: the shift that fits its pixel grid best there)
SIGN_COLOURS = 7
KANJI = (120, 152, 37, 46)


def big(a):
    return Image.fromarray(a).resize((925, 925), Image.NEAREST)


art = np.array(Image.open(SRC + "front.png").convert("RGBA"))
# (the joystick: the pixels that differ from a plain deck column, its place filled with that column's colours)
ys, xs = slice(*JOY_ROWS), slice(*JOY_COLS)
plain = art[ys, PLAIN_COL][:, None]
joy = np.abs(art[ys, xs, :3].astype(int) - plain[..., :3]).sum(2) >= 24
stick = art[ys, xs].copy()
art[ys, xs] = plain
art[JOY_ROWS[0] + JOY_DY:JOY_ROWS[1] + JOY_DY, JOY_COLS[0] + JOY_DX:JOY_COLS[1] + JOY_DX][joy] = stick[joy]

# (the arms off, both sides (the user): each arm's bar and the red brace under it; the cap's shoulder
# kept, its diagonal dark outline down to the beam's end, then the lanterns' gold hook's outline. KEEP: the
# first column kept on each row from ARM_ROWS[0], counted from the outside (the art is symmetric: the
# right side mirrored, x -> 219 - x))
bar = art[BAR_ROWS[0]:BAR_ROWS[1], :BAR_X].copy()       # (the left bar, for its new place)
red = (bar[..., 0] > 100) & (bar[..., 1] < 110) & (bar[..., 3] > 0)
red[:, :BAR_STRIPE] = False                             # (its own red stripe stays)
bar[red] = OUTLINE                                      # (the brace's start: the bar's end and bottom outline)
for side in (art, art[:, ::-1]):
    for i, keep in enumerate(KEEP):
        side[ARM_ROWS[0] + i, :keep] = 0
# (the top hooks off, the pillars' plain edge from below them; the left bar put up in the left one's
# place, against its pillar, the bell hangs from it)
for c0, c1 in HOOK_COLS:
    art[HOOK_ROWS[0]:HOOK_ROWS[1], c0:c1] = art[HOOK_ROWS[1] + 1, c0:c1]
up = art[BAR_ROWS[0] + BAR_DY:BAR_ROWS[1] + BAR_DY, BAR_DX:BAR_X + BAR_DX]
up[bar[..., 3] > 0] = bar[bar[..., 3] > 0]
# (the caps' shoulders' outer outline as thick as the rest (the user): OUTLINE_W pixels, the outer ones off)
for side in (art, art[:, ::-1]):
    for y in range(*THIN_ROWS):
        x = np.where(side[y, :110, 3] > 0)[0].min()
        run = 0
        while side[y, x + run, :3].max() < 50:
            run += 1
        side[y, x:x + max(run - OUTLINE_W, 0)] = 0

# (the deck's ends flat, no painted perspective (the user): the game's 3D alone shows the trays' sides,
# so the side away from the tilt never shows; each end the deck's plain column, its screw kept)
for side in (art, art[:, ::-1]):
    y0, y1 = END_ROWS
    screw = side[SCREW[2]:SCREW[3], SCREW[0]:SCREW[1]].copy()
    plain = side[y0:y1, PLAIN_COL].copy()
    side[y0:y1, END_COLS[0]:END_COLS[1]] = plain[:, None]
    keep = np.abs(screw[..., :3].astype(int) - side[SCREW[2]:SCREW[3], PLAIN_COL][:, None, :3]).sum(2) >= 60
    side[SCREW[2]:SCREW[3], SCREW[0]:SCREW[1]][keep] = screw[keep]

face = np.array(Image.open(SRC + "trays.png").convert("RGBA"))
for side in (face, face[:, ::-1]):                     # (the trays' painted inner ends flat too: their red front)
    side[END_ROWS[0] + 4:END_ROWS[1], TRAY_END] = side[END_ROWS[0] + 4:END_ROWS[1], TRAY_END - 6]

# (repainted from the designer's final_l study (the user's pick, 2026-11-03: its lettering and look), on
# these exact layers: each pixel the commonest colour of its block of the study; the lettering again at
# the study's own pixel phase (SIGN_PHASE), block means snapped to its commonest colours, for clean
# outlines; the coin grille as it was (its thin lines fall between the blocks))
ref = np.array(Image.open(REF).convert("RGB")).astype(int)


def block(y, x, phase=(0.0, 0.0)):
    sx, sy = (REF_BOX[2] - REF_BOX[0] + 1) / 218, (REF_BOX[3] - REF_BOX[1] + 1) / 217
    return (int(round(REF_BOX[1] + (y - 1) * sy + phase[1])), int(round(REF_BOX[1] + y * sy + phase[1])),
            int(round(REF_BOX[0] + (x - 1) * sx + phase[0])), int(round(REF_BOX[0] + x * sx + phase[0])))


q = ref // 10
key = q[..., 0] * 10000 + q[..., 1] * 100 + q[..., 2]
commonest = np.zeros((220, 220, 3), np.uint8)
for y in range(1, 219):
    for x in range(1, 219):
        y0, y1, x0, x1 = block(y, x)
        k = key[y0 + 1:y1 - 1, x0 + 1:x1 - 1]
        vals, cnt = np.unique(k, return_counts=True)
        commonest[y, x] = ref[y0 + 1:y1 - 1, x0 + 1:x1 - 1][k == vals[cnt.argmax()]].mean(0)
keep = np.zeros((220, 220), bool)
keep[GRILLE[2]:GRILLE[3], GRILLE[0]:GRILLE[1]] = True
for layer in (art, face):
    m = (layer[..., 3] > 0) & ~keep
    layer[m, :3] = commonest[m]
x0, x1, y0, y1 = SIGN
mean = np.zeros((y1 - y0, x1 - x0, 3))
for j, y in enumerate(range(y0, y1)):
    for i, x in enumerate(range(x0, x1)):
        b0, b1, c0, c1 = block(y, x, SIGN_PHASE)
        mean[j, i] = ref[b0:b1, c0:c1].reshape(-1, 3).mean(0)
reg = mean.reshape(-1, 3).astype(int)
q = reg // 14
qk = q[:, 0] * 10000 + q[:, 1] * 100 + q[:, 2]
keys, counts = np.unique(qk, return_counts=True)
pal = []
for kk in keys[np.argsort(-counts)]:
    c = reg[qk == kk].mean(0)
    if all(np.abs(c - p).sum() > 45 for p in pal):
        pal.append(c)
    if len(pal) == SIGN_COLOURS:
        break
pal = np.array(pal)
snap = pal[((mean[..., None, :] - pal[None, None]) ** 2).sum(-1).argmin(-1)].astype(np.uint8)
kx0, kx1, ky0, ky1 = KANJI                              # (神友: too small to snap, the commonest colours kept)
snap[ky0 - y0:ky1 - y0, kx0 - x0:kx1 - x0] = commonest[ky0:ky1, kx0:kx1]
art[y0:y1, x0:x1, :3] = snap
a = face[..., 3] > 0
top = np.where(a.any(1))[0].min()
lip = np.zeros(a.shape, bool)
lip[top + 1:top + 1 + LIP] = a[top + 1:top + 1 + LIP]
body = face[a & ~lip][:, :3].astype(float)
bl = body.mean(1)
apron = tuple(int(c * 0.47) for c in body[(bl > np.percentile(bl, 30)) & (bl < np.percentile(bl, 80))].mean(0))
shade = tuple(int(c * 0.78) for c in np.median(face[lip][:, :3], 0))
side = np.zeros_like(face)
side[a] = apron + (255,)
side[lip] = shade + (255,)

front = art[..., 3] > 0
hole = ~front & ndimage.binary_fill_holes(front)
lab, _ = ndimage.label(hole)
win = lab == np.bincount(lab.ravel())[1:].argmax() + 1
w = win.astype(int)                                 # (the corners rounded a pixel)
win &= ~(np.roll(w, 1, 0) + np.roll(w, -1, 0) + np.roll(w, 1, 1) + np.roll(w, -1, 1) <= 2)
glass = np.zeros_like(art)
glass[win] = GLASS

# (the home's 3D sides from this front: side.png and side_back.png, in their colours, the arms and hooks
# gone from them too (the user: the shape behind like the front one))
sides = (front | (np.array(Image.open(SRC + "inside.png").convert("RGBA"))[..., 3] > 0) | (face[..., 3] > 0))
old = np.array(Image.open(OUT + "side_back.png").convert("RGBA").resize((220, 220), Image.NEAREST))
vals, cnt = np.unique(old[old[..., 3] > 0][:, :3], axis=0, return_counts=True)
body, rim_c = vals[cnt.argmax()], vals[cnt.argsort()[-2]]
rim = sides & ~(np.roll(sides, 1, 0) & np.roll(sides, -1, 0) & np.roll(sides, 1, 1) & np.roll(sides, -1, 1))
flat = np.zeros_like(art)
flat[sides] = tuple(body) + (255,)
big(flat).save(OUT + "side.png")
flat[rim] = tuple(rim_c) + (255,)
big(flat).save(OUT + "side_back.png")
big(art).save(OUT + "front.png")
big(face).save(OUT + "ledges.png")
big(side).save(OUT + "ledges_side.png")
big(glass).save(OUT + "glass.png")
k = 925 / 220
seen = a[top + 2] & ~front[top + 2]                 # (the deck in front hides the trays' inner ends; a row down: the pillars' feet)
xs = [np.where(seen[x0:x1])[0] + x0 for x0, x1 in ((0, 110), (110, 220))]
print("ledges", [(round((x.min() + x.max() + 1) / 2 * k), round((top + 1) * k)) for x in xs])
