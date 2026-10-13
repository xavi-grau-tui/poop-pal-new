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
