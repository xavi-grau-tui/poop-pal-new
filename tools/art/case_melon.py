from PIL import Image, ImageDraw, ImageFont
import numpy as np
from scipy.ndimage import binary_dilation, label
SP='/private/tmp/claude-501/-Users-xaviergrau-Documents-PoopPal-Godot-poop-pal-main-kiro/3f4ad48c-4964-4225-af04-b57eada39524/scratchpad/'
BODY = np.array([176, 222, 196]); DOT = (240, 250, 236)
SIDE = (146, 196, 170); EDGE = (118, 168, 144); CARVE_D = (140, 190, 164); CARVE_L = (206, 240, 220)
REF = np.array([250, 237, 217]); TAN = np.array([215, 181, 141])
def shift(m, dx, dy):
    o = np.zeros_like(m); h, w = m.shape
    o[max(dy,0):h+min(dy,0), max(dx,0):w+min(dx,0)] = m[max(-dy,0):h+min(-dy,0), max(-dx,0):w+min(-dx,0)]
    return o
def carve(rgb, m):
    rgb[m] = BODY; rgb[m & ~shift(m, 3, 3)] = CARVE_D; rgb[m & ~shift(m, -3, -3)] = CARVE_L
NODOTS = []
def dots(rgb, m):
    h, w = m.shape; yy, xx = np.mgrid[0:h, 0:w]; cell = 72
    cx = (xx + (yy // cell % 2) * cell // 2) % cell - cell // 2; cy = yy % cell - cell // 2
    px, py = xx - cx, yy - cy                       # each dot's centre
    # a dot only where it fits whole on the case (never cut by a button, the screen, an edge...)
    from scipy.ndimage import binary_erosion
    yd, xd = np.mgrid[-10:11, -10:11]
    whole = binary_erosion(m, structure=(xd * xd + yd * yd) <= 100)
    ok = whole[np.clip(py, 0, h - 1), np.clip(px, 0, w - 1)]
    for (x0, y0, x1, y1) in NODOTS:
        ok &= ~((px >= x0 - 10) & (px < x1 + 10) & (py >= y0 - 10) & (py < y1 + 10))   # (the whole dot, never half)
    rgb[m & ok & ((cx * cx + cy * cy) < 81)] = DOT
def make(path, keep_boxes, cover=(), logo_box=None, logo_tones=None, front_logo=None):
    a = np.asarray(Image.open(path).convert('RGBA')).astype(int)
    rgb, alpha = a[..., :3].copy(), a[..., 3] > 0
    h, w = alpha.shape
    keep = np.zeros((h, w), bool)
    for (x0, y0, x1, y1) in keep_boxes: keep[y0:y1, x0:x1] = True
    shell = (np.abs(rgb - REF).sum(-1) < 40) & alpha & ~keep
    off = (rgb - REF).mean(-1, keepdims=True)
    rgb[shell] = np.clip(BODY + off[shell] * 1.4, 0, 255)
    for (x0, y0, x1, y1) in cover:                  # under the case (the sticker): plain shell
        c = np.zeros_like(alpha); c[y0:y1, x0:x1] = True; c &= alpha
        rgb[c] = BODY; shell |= c
    xx = np.mgrid[0:h, 0:w][1]
    # the device's sides: every tone shifted into the case's (its shade lines kept), the dark
    # outline and the black corners left exactly as they are
    yy_ = np.mgrid[0:h, 0:w][0]
    side = ((xx < 70) | (xx > w - 70) | (yy_ < 40) | (yy_ > h - 40)) & alpha & (rgb.sum(-1) > 330) & ~shell & ~keep
    rgb[side] = np.clip(np.array(SIDE) + (rgb[side] - TAN) * 1.1, 0, 255)
    dark = alpha & (rgb.sum(-1) < 300) & ~keep
    outside = ~alpha.copy(); outside[0, :] = outside[-1, :] = True; outside[:, 0] = outside[:, -1] = True
    rim = dark & binary_dilation(outside, iterations=14)
    rgb[rim & (rgb.sum(-1) > 60)] = (70, 104, 88)    # the device's dark brown outline: the case's colour, darker (black corners stay)
    lab, n = label(alpha & (rgb.sum(-1) < 520) & ~keep & ~rim)
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        if len(ys) < 1500 and (ys.mean() < 120 or ys.mean() > h - 120) and (xs.mean() < 120 or xs.mean() > w - 120):
            z = binary_dilation(lab == i, iterations=5) & alpha & ~rim
            rgb[z] = BODY; shell |= z
    if logo_box:
        x0, y0, x1, y1 = logo_box; lm = np.zeros((h, w), bool); sub = rgb[y0:y1, x0:x1]
        hit = np.zeros(sub.shape[:2], bool)
        for t in logo_tones: hit |= np.abs(sub - np.array(t)).sum(-1) < 24
        lm[y0:y1, x0:x1] = hit; carve(rgb, lm); shell |= lm
    if front_logo:
        x0, y0, x1, y1 = front_logo; lm = np.zeros((h, w), bool)
        lm[y0:y1, x0:x1] = ~shell[y0:y1, x0:x1] & alpha[y0:y1, x0:x1]
        carve(rgb, lm); shell |= lm
    for (ox0, oy0, ox1, oy1), (ix0, iy0, ix1, iy1) in BUMPS if path.endswith('w0_play.png') else []:
        ring = np.zeros_like(alpha); ring[oy0:oy1, ox0:ox1] = True; ring[iy0:iy1, ix0:ix1] = False; ring &= alpha
        ring &= ~shell                                 # (only the button's own frame: not the case round it)
        lum = rgb.sum(-1)
        hi = ring & (lum >= 600); mid = ring & (lum >= 330) & (lum < 600); lo = ring & (lum < 330)
        rgb[hi] = BODY; rgb[mid] = BODY; rgb[lo] = EDGE   # the bump: case colour, only its edge a darker tone
        # in the hole: whatever is OUTSIDE the button's dark outline (cream corners, a brown spot) is
        # case; inside the outline the button keeps every colour of its own
        sub = rgb[iy0 - 4:iy1 + 4, ix0 - 4:ix1 + 4]
        openp = sub.sum(-1) >= 330
        lab_, n_ = label(openp)
        edge_ids = set(np.unique(np.concatenate([lab_[0], lab_[-1], lab_[:, 0], lab_[:, -1]]))) - {0}
        outside = np.isin(lab_, list(edge_ids))
        sub[outside] = BODY
        # the faces' rounded corners: the cream specks between the corner and the box's edge
        hh, ww = sub.shape[:2]
        yy2, xx2 = np.mgrid[0:hh, 0:ww]
        near_edge = (np.minimum(np.minimum(yy2, hh - 1 - yy2), np.minimum(xx2, ww - 1 - xx2)) < 12)
        corner_zone = near_edge & ((yy2 < 22) | (yy2 > hh - 23)) & ((xx2 < 22) | (xx2 > ww - 23))
        specks = corner_zone & (sub.sum(-1) > 600)
        sub[specks] = BODY
        NODOTS.append((ox0, oy0, ox1, oy1))           # (no dots inside the frame)
    if path.endswith('w0_play.png'):
        # round every button: whatever light lies outside its dark outline (a cream stripe under it,
        # its lower corners) is case; the button and its outline stay exactly as they are
        from scipy.ndimage import binary_fill_holes
        for (ox0, oy0, ox1, oy1) in AROUND[3:]:            # (the bottom buttons: the menu ones are done above)
            sub = rgb[oy0:oy1, ox0:ox1]
            # the button itself: its dark outline and everything inside it, never touched
            dk = sub.sum(-1) < 330
            lb, nb = label(dk)
            sizes = [(lb == i).sum() for i in range(1, nb + 1)]
            # (the whole box round the button's dark outline: nothing in it changes)
            ys_, xs_ = np.nonzero(dk)
            btn = np.zeros_like(dk)
            if len(ys_):
                btn[ys_.min():ys_.max() + 1, xs_.min():xs_.max() + 1] = True
            openp = (sub.sum(-1) >= 330) & ~btn
            lab_, n_ = label(openp)
            ids = set(np.unique(np.concatenate([lab_[0], lab_[-1], lab_[:, 0], lab_[:, -1]]))) - {0}
            outside = np.isin(lab_, list(ids)) & (np.abs(sub - BODY).sum(-1) > 30) & (np.abs(sub - np.array(DOT)).sum(-1) > 30)
            sub[outside] = BODY
        # the screen's bezel: the case reaches the screen's dark border; its shaded band stays shaded
        bz = np.zeros_like(alpha); bz[556:1600, 18:1062] = True; bz[608:1565, 65:1016] = False
        bz &= alpha & (rgb.sum(-1) > 500) & (np.abs(rgb - BODY).sum(-1) > 30)
        off2 = (rgb - REF).mean(-1, keepdims=True)
        rgb[bz] = np.clip(BODY + off2[bz] * 1.4, 0, 255)
    dots(rgb, shell & ~keep)
    return Image.fromarray(np.dstack([rgb, a[..., 3]]).astype(np.uint8))
# the case's bumps: the button's frame (outer box) in the case's colours, a hole for the face (inner box)
BUMPS = [((58, 293, 352, 568), (102, 338, 312, 512)), ((388, 293, 682, 568), (432, 338, 642, 512)),
         ((718, 293, 1012, 568), (762, 338, 972, 512))]       # (only the menu buttons)
# the buttons' surroundings (menu buttons, then the bottom three), and the speaker (no dots there)
AROUND = [(50, 285, 360, 578), (380, 285, 690, 578), (710, 285, 1020, 578),
          (130, 1595, 352, 1812), (428, 1600, 652, 1768), (728, 1595, 952, 1812)]
SPEAKER = (395, 1735, 685, 1885)
front_keep = [(102, 338, 312, 512), (432, 338, 642, 512), (762, 338, 972, 512),
              (148, 1616, 333, 1791), (450, 1620, 630, 1742), (748, 1616, 933, 1791),   # (the bottom buttons, whole: outline and all)
              (65, 608, 1016, 1565), (96, 86, 530, 274)]
NODOTS.append(SPEAKER)
for (x0, y0, x1, y1) in AROUND[3:]:
    NODOTS.append((x0 - 10, y0 - 10, x1 + 10, y1 + 10))      # (no half dots touching the bottom buttons)
F = make(SP + 'shots9/w0_play.png', front_keep, front_logo=(575, 105, 1000, 265))
NODOTS.clear()                 # (the front's button frames: not on the back)
B = make('textures/console/back.png', [], cover=[(90, 360, 1000, 855), (305, 1295, 750, 1695), (290, 1005, 770, 1155), (110, 1770, 970, 1865)],
         logo_box=(243, 83, 860, 321), logo_tones=[(234, 219, 194), (200, 166, 130), (255, 249, 238)])
k = 0.42
tiles = [im.resize((int(1080 * k), int(1920 * k))) for im in (F, B)]
W = tiles[0].width
sheet = Image.new('RGBA', (W * 2 + 60, tiles[0].height + 80), (60, 46, 40, 255))
d = ImageDraw.Draw(sheet); font = ImageFont.truetype('fonts/Pixellari.ttf', 28)
for i, (t, l) in enumerate(zip(tiles, ['Melon Soda case - front', 'Melon Soda case - back'])):
    x = 20 + i * (W + 20); sheet.alpha_composite(t, (x, 60)); d.text((x, 18), l, fill=(250, 240, 220), font=font)
sheet.save('docs/mockups/case_melon_soda.png'); print('ok')
