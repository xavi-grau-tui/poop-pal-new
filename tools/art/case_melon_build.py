import numpy as np
from PIL import Image
SP='/private/tmp/claude-501/-Users-xaviergrau-Documents-PoopPal-Godot-poop-pal-main-kiro/3f4ad48c-4964-4225-af04-b57eada39524/scratchpad/'
ns = {}
exec(open(SP + 'case_mock.py').read(), ns)
make = ns['make']; BODY = ns['BODY']
src = np.asarray(Image.open(SP + 'shots9/w0_play.png').convert('RGBA')).astype(int)
ns['NODOTS'].clear(); ns['NODOTS'].append(ns['SPEAKER'])
F = np.asarray(make(SP + 'shots9/w0_play.png', ns['front_keep'], front_logo=(575, 105, 1000, 265))).astype(int)
changed = (np.abs(F[..., :3] - src[..., :3]).sum(-1) > 0)
for (x0, y0, x1, y1) in ns['front_keep']:
    changed[y0:y1, x0:x1] = False
for (o, i) in ns['BUMPS']:
    x0, y0, x1, y1 = i
    changed[y0 - 4:y1 + 4, x0 - 4:x1 + 4] |= (np.abs(F[y0 - 4:y1 + 4, x0 - 4:x1 + 4, :3] - src[y0 - 4:y1 + 4, x0 - 4:x1 + 4, :3]).sum(-1) > 0)
# the bottom buttons: their inside (the dark outline closed, its holes filled) never changes;
# every light pixel round it, in their box, is case (the outline's steps at the corners)
from scipy.ndimage import binary_closing, binary_fill_holes
for (x0, y0, x1, y1) in [(148, 1616, 333, 1791), (450, 1620, 630, 1742), (748, 1616, 933, 1791)]:
    sub = src[y0 - 2:y1 + 2, x0 - 2:x1 + 2, :3]
    dark = sub.sum(-1) < 330
    # inside = between the outline's ends on its row AND between them on its column (a rounded box)
    hh, ww = dark.shape
    xs_ = np.arange(ww)[None, :].repeat(hh, 0); ys_ = np.arange(hh)[:, None].repeat(ww, 1)
    rmin = np.where(dark.any(1), np.argmax(dark, 1), ww)[:, None]
    rmax = np.where(dark.any(1), ww - 1 - np.argmax(dark[:, ::-1], 1), -1)[:, None]
    cmin = np.where(dark.any(0), np.argmax(dark, 0), hh)[None, :]
    cmax = np.where(dark.any(0), hh - 1 - np.argmax(dark[::-1, :], 0), -1)[None, :]
    inside = (xs_ >= rmin) & (xs_ <= rmax) & (ys_ >= cmin) & (ys_ <= cmax)
    light = ~inside & ~dark
    F[y0 - 2:y1 + 2, x0 - 2:x1 + 2, :3][light] = BODY
    changed[y0 - 2:y1 + 2, x0 - 2:x1 + 2] |= light
out = F.copy(); out[..., 3] = np.where(changed, 255, 0)
Image.fromarray(out.astype(np.uint8)).save('textures/cases/melon_front.png')
f = Image.fromarray(src.astype(np.uint8)); f.alpha_composite(Image.fromarray(out.astype(np.uint8)))
f.crop((60, 1590, 1060, 1910)).save(SP + 'case_btns.png')
f.crop((40, 280, 1040, 600)).save(SP + 'case_menu_btns.png')
ns['NODOTS'].clear()
B = make('textures/console/back.png', [], cover=[(90, 360, 1000, 855), (290, 1005, 770, 1155), (110, 1770, 970, 1865), (305, 1290, 775, 1700)],
         logo_box=(243, 83, 860, 321), logo_tones=[(234, 219, 194), (200, 166, 130), (255, 249, 238)])
B.save('textures/cases/melon_back.png')
print('ok')

# ---------------------------------------------------------------- the game's layers (2026-10-13)
# The front case is drawn in two layers so the buttons always sit on it, whatever their state:
#   base: everything the case covers, and solid case under every button (drawn under them)
#   top:  the carved HaraTomo and the screws' spots (drawn over the logo and the screws)
# and the menu buttons get Melon Soda images of their own (their frame in the case's colours).
from scipy.ndimage import binary_dilation, label as lab2
base = out.copy()
for (x0, y0, x1, y1) in [(52, 290, 358, 572), (382, 290, 688, 572), (712, 290, 1018, 572),
                         (140, 1608, 342, 1800), (442, 1612, 640, 1752), (740, 1608, 942, 1800)]:
    base[y0:y1, x0:x1, :3] = BODY
    base[y0:y1, x0:x1, 3] = 255
# the speaker grille, painted on the case: its holes dark, round them the case (the speaker's own
# images, with a light rim on each hole, are hidden while the case is on)
sx0, sy0, sx1, sy1 = ns['SPEAKER']
grille = src[sy0:sy1, sx0:sx1, :3]
holes = grille.sum(-1) < 520          # (the holes with their soft edge; only the light rim goes)
base[sy0:sy1, sx0:sx1, :3] = np.where(holes[..., None], grille, BODY)
base[sy0:sy1, sx0:sx1, 3] = 255
top = np.zeros_like(out)
for (x0, y0, x1, y1) in [(575, 105, 1000, 265), (20, 1835, 80, 1895), (1000, 1835, 1060, 1895), (20, 20, 80, 80), (1000, 20, 1060, 80)]:
    top[y0:y1, x0:x1] = out[y0:y1, x0:x1]
Image.fromarray(base.astype(np.uint8)).save('textures/cases/melon_front.png')
Image.fromarray(top.astype(np.uint8)).save('textures/cases/melon_front_top.png')
EDGE = ns['EDGE']
for name in ['buttonfoodnormal', 'buttonfoodpressed', 'padbuttonnormal', 'padbuttonpressed', 'settingsbuttonnormal', 'settingsbuttonpressed']:
    a = np.asarray(Image.open(f'textures/buttons/{name}.png').convert('RGBA')).astype(int)
    rgb, al = a[..., :3], a[..., 3] > 0
    dark = al & (rgb.sum(-1) < 330)
    outside = ~al
    Ld, nd = lab2(dark)
    outer_ids = set(np.unique(Ld[binary_dilation(outside, iterations=2) & dark])) - {0}
    outer = np.isin(Ld, list(outer_ids))                           # the frame's outer outline (whole)
    openp = al & ~dark
    L, n = lab2(openp)
    touch = set(np.unique(L[binary_dilation(outside | outer, iterations=1) & openp])) - {0}
    frame = np.isin(L, list(touch))                                # the cream frame, its shadow
    rgb[frame] = BODY
    rgb[outer] = EDGE
    a[..., :3] = rgb
    Image.fromarray(a.astype(np.uint8)).save(f'textures/cases/melon_{name}.png')
print('layers ok')
