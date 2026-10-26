"""The shrine (hokora) around the pal, in the gut's look (yokai migration, docs/yokai_migration.md):
a small weathered wooden shrine on a granite pedestal, painted on the gut's chunky grid (110 cells
across its 925 px picture, ~8.4 px each), each piece shaded like a gut loop (a pale body, deeper
towards its edges, a creamy highlight up-left, a soft outline), shown x8.4 and softened a touch.
The pal's window (where frame1 sits): grid x 31..80, y 33..77.

For the 3D tilt (scripts/shrine.gd) it comes in layers:
  front.png       the front face (roof, pillars, beam, sill, the pedestal's block)
  slab.png        the pedestal's top slab (its own 3D piece, out in front of the wood); slab_side.png
                  its side colours, no outline (its top, seen from above)
  bell.png, bead_red.png, bead_white.png   the bell rope's pieces (the game swings them on a chain)
  sun.png, moon_0..7.png  the sky behind it, moved with the real time (the moon in its real phase)
  inside.png      the inside, behind the pal (dark planks, a lattice band, the floor, an old mirror)
  side.png        the front's silhouette in its side colours (stacked behind it: the box's sides)
  side_back.png   the same with a contour (the backmost copy)

    <venv>/bin/python tools/art/shrine.py      -> textures/pet/shrine/
"""
import sys, os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

G = 110
SS = 6
OUTLINE = np.array([78, 52, 50], np.float32)
STONE_LINE = (70, 68, 72)             # the stone's outline: dark grey (the user), not the wood's brown
ROOF_LINE = (64, 74, 86)              # the roof's: its own blue-grey, darker
rng = np.random.default_rng(5)
BLUR = 0.8
OLD_LINE = (78, 52, 50)               # the first outline, kept inside and on the rope (the user: the mirror's and the ornaments' were nicer)
ROOF_TILES = os.environ.get('ROOF_TILES', '0') == '1'
ROOF_FINE = os.environ.get('ROOF_FINE', '1') == '1'   # the roof in half-cell pixels (the user: less pixelated)

PAL = {      # body, edges, highlight: weathered, low colour
    'wood':   [(212, 192, 166), (116, 84, 64), (240, 230, 214)],
    'wood2':  [(200, 174, 146), (104, 72, 54), (232, 218, 200)],     # beams, a shade darker
    'dark':   [(150, 118, 96), (70, 46, 40), (196, 172, 152)],       # lattice
    'inside': [(86, 78, 76), (40, 34, 36), (110, 102, 98)],         # the shrine's inside, in shadow
    'roof':   [(196, 204, 208), (96, 110, 122), (238, 244, 246)],
    'stone':  [(212, 208, 204), (124, 118, 120), (242, 240, 236)],
    'red':    [(236, 140, 128), (176, 64, 60), (252, 214, 204)],
    'white':  [(248, 244, 236), (176, 166, 160), (255, 255, 255)],
    'gold':   [(238, 210, 140), (170, 120, 50), (255, 246, 214)],
    'leaf':   [(178, 206, 150), (84, 124, 66), (226, 242, 204)],
    'cup':    [(240, 236, 226), (150, 140, 140), (255, 255, 255)],
    'indigo': [(92, 112, 168), (48, 58, 104), (150, 168, 214)],      # the ceramics' blue rings
    'hinoki': [(242, 230, 208), (150, 114, 86), (254, 250, 240)],     # the offering stand: fresh pale cypress (against the old wood)
}

# (looks being tried, 2026-10-21, the user: the gut looked more solid; SHRINE_LOOK=outline: the
# pal's and the gut's near-black plum outline, crisper; =palette: that plus warmer colours in the
# gut's palette, deeper shading, brighter highlights)
LOOK = os.environ.get('SHRINE_LOOK', 'vermilion')     # (the user, 2026-10-21: the red one, a bit pale)
if LOOK in ('outline', 'palette', 'vermilion'):
    OUTLINE = np.array([66, 38, 50], np.float32)          # (a dark plum, a little washed out: the user, not full black)
    STONE_LINE = ROOF_LINE = (66, 38, 50)
    BLUR = 0.45
if LOOK == 'palette':
    PAL.update({
        'wood':   [(230, 176, 136), (164, 88, 70), (254, 230, 204)],
        'wood2':  [(214, 154, 116), (146, 74, 60), (248, 214, 184)],
        'dark':   [(168, 100, 86), (94, 42, 46), (210, 152, 132)],
        'inside': [(96, 60, 72), (46, 22, 36), (128, 88, 100)],
        'roof':   [(132, 136, 186), (66, 62, 116), (204, 210, 240)],
        'stone':  [(226, 210, 210), (150, 116, 128), (252, 244, 242)],
        'hinoki': [(252, 234, 204), (196, 128, 96), (255, 250, 238)],
    })
if LOOK == 'vermilion':                 # (painted red like an Inari shrine, a bit pale: the user picked it)
    PAL.update({
        'wood':   [(242, 146, 124), (186, 78, 80), (255, 216, 198)],
        'wood2':  [(232, 130, 112), (170, 66, 72), (254, 206, 188)],
        'dark':   [(198, 108, 102), (120, 48, 58), (234, 164, 150)],
        'inside': [(96, 56, 66), (46, 20, 34), (128, 84, 94)],
        'roof':   [(176, 168, 190), (112, 100, 130), (228, 224, 238)],   # (paler again: the user)
        'stone':  [(232, 220, 214), (156, 128, 132), (255, 250, 244)],
        'hinoki': [(252, 234, 204), (196, 128, 96), (255, 250, 238)],
    })

YY, XX = np.mgrid[0:G * SS, 0:G * SS] / SS


def shade(mask_hi, pal, thick, stripes=None, hl_gate=None, grain=0.0, ss=SS, lights=None):
    body, rim, hl = [np.array(c, np.float32) for c in pal]
    d = ndimage.distance_transform_edt(mask_hi) / SS
    t = np.clip(d / thick, 0, 1)
    k = t * t * (3 - 2 * t)
    rgb = rim[None, None] + (body - rim)[None, None] * np.clip((k - 0.22) / 0.6, 0, 1)[..., None]
    if stripes is not None:
        rgb = np.where(stripes[..., None], rgb * 0.84 + rim * 0.16, rgb)
    if lights is not None:                       # (lit edges, e.g. each roof tile row's top)
        rgb = np.where(lights[..., None], rgb * 0.55 + hl * 0.45, rgb)
    h = max(1, int(thick * 0.55 * SS))
    ds = np.zeros_like(d)
    ds[:-h, :-h] = d[h:, h:]
    hlm = (ds > thick * 0.95) & (d > thick * 0.55)
    if hl_gate is not None:
        hlm &= hl_gate
    hlm = ndimage.binary_opening(hlm, iterations=SS // 2)
    rgb = np.where(hlm[..., None], hl[None, None] * 0.75 + rgb * 0.25, rgb)
    rgb *= (1 + rng.normal(0, 0.015 + grain, rgb.shape[:2]))[..., None]
    H = mask_hi.shape[0] // ss                  # (ss: the hi-res pixels per pixel; SS / 2 for a fine layer)
    m = mask_hi.reshape(H, ss, H, ss)
    a = m.mean((1, 3))
    c = (rgb * mask_hi[..., None]).reshape(H, ss, H, ss, 3).sum((1, 3)) / np.maximum(1e-6, m.sum((1, 3)))[..., None]
    return c, a > 0.45


class Layer:
    """fine=True: pixels half a cell (for the roof's slopes: the user, less pixelated), its outline
    two of them thick (the same weight as the rest)"""
    def __init__(s, fine=False):
        s.fine = fine
        s.ss = SS // 2 if fine else SS
        n = G * SS // s.ss
        s.rgb = np.zeros((n, n, 3), np.float32)
        s.a = np.zeros((n, n), bool)

    def add(s, mask_hi, pal, thick, outline=True, round_ring=False, cut_corners=False, **kw):
        c, a = shade(mask_hi, pal, thick, ss=s.ss, **kw)
        if cut_corners:                 # (the corner cells become outline: a clean diagonal step, the user)
            ys, xs = np.where(a)
            for y in (ys.min(), ys.max()):
                for x in (xs.min(), xs.max()):
                    a[y, x] = False
        if outline is not False:
            # (round_ring: the outline grown without its corner pixels, so round corners stay round)
            st = ndimage.generate_binary_structure(2, 1) if round_ring else np.ones((3, 3))
            ring = ndimage.binary_dilation(a, structure=st, iterations=2 if s.fine else 1) & ~a
            s.rgb[ring] = OUTLINE if outline is True else np.array(outline, np.float32)
            s.a |= ring
        s.rgb[a] = c[a]
        s.a |= a

    def line(s, mask_hi, col=OUTLINE):
        H = s.rgb.shape[0]
        a = mask_hi.reshape(H, s.ss, H, s.ss).mean((1, 3)) > 0.35
        s.rgb[a] = col
        s.a |= a

    def finish(s, blur=None):
        img = np.dstack([np.clip(s.rgb, 0, 255), s.a * 255]).astype(np.uint8)
        return Image.fromarray(img, 'RGBA').resize((925, 924), Image.NEAREST).filter(ImageFilter.GaussianBlur(BLUR if blur is None else blur))


def canvas():
    im = Image.new('L', (G * SS, G * SS), 0)
    return im, ImageDraw.Draw(im)


def M(im):
    return np.asarray(im) > 127


def P(x, y):
    return (x * SS, y * SS)


def poly(pts):
    im, d = canvas(); d.polygon([P(*p) for p in pts], fill=255); return M(im)


def rrect(x0, y0, x1, y1, r):
    im, d = canvas(); d.rounded_rectangle([P(x0, y0), P(x1, y1)], radius=r * SS, fill=255); return M(im)


def ellipse(x0, y0, x1, y1):
    im, d = canvas(); d.ellipse([P(x0, y0), P(x1, y1)], fill=255); return M(im)


def bar(pts, w):
    im, d = canvas(); d.line([P(*p) for p in pts], fill=255, width=max(1, int(w * SS))); return M(im)


INSIDE_LOOK = os.environ.get('INSIDE_LOOK', '')     # (being tried, 2026-10-21: '' / 'red' / 'wood')
FLOOR_WOOD = [(214, 160, 120), (146, 90, 70), (240, 206, 170)]


def back_layer():
    """Inside the shrine, behind the pal (it replaces the cream window too): a dark plank back wall,
    a lattice band at the top, the floor boards, a round bronze mirror behind the pal (its middle:
    grid 57, 50), darker into the corners. INSIDE_LOOK 'red': the back wall painted like the outside
    (in shadow), a wooden floor; 'wood': bare warm wood inside, a purple curtain at the top, a
    gilt-rimmed mirror, a wooden floor"""
    L = Layer()
    planks = ((XX - 26) % 6 < 0.9)
    back = {'red': [(150, 70, 76), (66, 24, 38), (188, 108, 106)],
            'wood': [(156, 112, 86), (78, 48, 44), (192, 152, 122)]}.get(INSIDE_LOOK, PAL['inside'])
    L.add(rrect(29, 30, 82, 80, 0.5), back, 12, stripes=planks, outline=OLD_LINE)
    if INSIDE_LOOK == 'wood':
        # a curtain (maku) across the top, purple, gathered in three swags
        cur = rrect(30, 32, 81, 37, 0.3)
        for cx in (38.5, 55.5, 72.5):
            cur |= ellipse(cx - 8.5, 33, cx + 8.5, 41)
        L.add(cur, [(150, 108, 172), (84, 52, 108), (200, 170, 216)], 2.0, stripes=((XX - 30) % 17 < 1.0), outline=OLD_LINE)
    else:
        lat = ((XX - 26) % 4 < 1.0) | ((YY - 34) % 4 < 1.0)
        L.add(rrect(31, 33, 80, 40, 0.5), back, 2.5, stripes=lat, outline=OLD_LINE)
    if INSIDE_LOOK:
        # floorboards: boards across, their joints staggered, a little grain
        row = np.floor((YY - 69) / 2.5)
        boards = ((YY - 69) % 2.5 < 0.5) | (((XX + row * 7) % 13) < 0.6)
        L.add(rrect(30, 69, 81, 79, 0.5), FLOOR_WOOD, 4, stripes=boards, grain=0.04, outline=OLD_LINE)
    else:
        L.add(rrect(30, 69, 81, 79, 0.5), [(118, 108, 102), (60, 52, 52), (146, 136, 128)], 4, stripes=((YY - 69) % 3.4 < 0.7), outline=OLD_LINE)
    # the mirror, hung on the back wall (no stand: the user)
    if INSIDE_LOOK == 'wood':
        L.add(ellipse(42, 36, 72, 64), [(214, 172, 104), (128, 86, 48), (246, 220, 158)], 3, outline=OLD_LINE)    # (a gilt rim)
        L.add(ellipse(45, 39, 69, 61), [(112, 104, 100), (72, 64, 66), (140, 132, 126)], 7, outline=False)
    else:
        # (a dull old mirror: the pal stands out), centred between the lattice band and the floor (the user)
        L.add(ellipse(43, 41.5, 71, 67.5), [(120, 112, 104), (62, 56, 56), (150, 142, 132)], 8, outline=OLD_LINE)
        L.add(ellipse(47, 45.5, 67, 63.5), [(104, 98, 94), (70, 64, 64), (128, 122, 116)], 7, outline=False)
    return L.finish(blur=0.8)          # (the first look inside: soft brown outlines, the user)


def front_layer(f):
    """Smaller (the user): no side walls, slim pillars hugging the pal's window (x 31..82, y 31..78),
    a lower roof with short eaves, a smaller pedestal"""
    L = Layer()
    sway = math.sin(f / 4 * math.tau)
    # the granite pedestal's block (its top slab is its own 3D piece: slab_layer)
    L.add(rrect(25, 89, 86, 101, 1), PAL['stone'], 5, outline=STONE_LINE, grain=0.05, cut_corners=True)   # (even corners, a diagonal step: the user)
    if MOSS:
        L.add(_moss(rrect(25, 89, 86, 101, 1), 101.0, 3.0), PAL['moss'], 1.4, outline=False)
    # pillars, slim, right against the window, standing on the sill (the user: its outline over their feet)
    L.add(rrect(25, 31, 31, 80, 1.2), PAL['wood'], 3.2, stripes=((YY * 1.7 + XX * 0.3) % 7 < 0.6))
    L.add(rrect(80, 31, 86, 80, 1.2), PAL['wood'], 3.2, stripes=((YY * 1.7 + XX * 0.3) % 7 < 0.6))
    # the floor of the shrine (a plank sill under the window), over the pillars' feet
    L.add(rrect(24, 77, 87, 83, 1.2), PAL['wood2'], 2.5, stripes=((XX - 24) % 9 < 0.9))
    # the tie beam, its ends just past the pillars
    L.add(rrect(21, 28, 90, 33, 1.2), PAL['wood2'], 2.5)
    # the gable: a low wooden board under the roof's peak, a small lattice in it
    gab = poly([(28, 29), (55.5, 15.25), (83, 29)])
    lat2 = ((XX - 26) % 4 < 1.0) | ((YY - 17) % 4 < 1.0)
    L.add(gab, PAL['wood2'], 3.5, stripes=lat2 & (YY > 21) & (YY < 27) & (np.abs(XX - 55.5) < 10))
    # the roof: two slopes, short eaves, its boards in rows, the bargeboard band under it. Every
    # slope exactly 1 down per 2 across, so its edges step evenly (the user: it looked too
    # pixelated, the steps went 2, 3, 2...), the rows on whole cells
    R = Layer(fine=ROOF_FINE)               # (the roof last, over everything: its own layer, maybe finer)
    rows = (YY % 4 < 1.0)
    tiles = {}
    if ROOF_TILES:                          # (tiles: each row's top caught by the light, its bottom in shadow)
        rows = (YY % 4 >= 3.0)
        tiles = {'lights': (YY % 4 < 0.75)}
    left = poly([(55.5, 6.75), (59, 12), (25, 29), (15, 29), (15, 27)])
    right = poly([(55.5, 6.75), (52, 12), (86, 29), (96, 29), (96, 27)])
    R.add(left, PAL['roof'], 4, outline=ROOF_LINE, stripes=rows, **tiles)
    R.add(right, PAL['roof'], 4, outline=ROOF_LINE, stripes=rows, **tiles)
    R.add(poly([(15, 29), (25, 29), (55.5, 13.75), (86, 29), (96, 29), (96, 31.5), (86, 31.5), (55.5, 16.25), (25, 31.5), (15, 31.5)]), PAL['wood2'], 1.3)
    R.add(rrect(52.5, 5, 58.5, 10, 2), PAL['roof'], 2.5, outline=ROOF_LINE)          # the ridge's end cap
    # (the bell rope is its own pieces now, swung in the game: rope_parts)
    return Image.alpha_composite(L.finish(), R.finish())


def slab_layer():
    """The pedestal's granite top slab, a little wider than the wooden shrine: its own 3D piece
    (scripts/shrine.gd), reaching out in front of the wood, its top seen from above"""
    L = Layer()
    L.add(rrect(20, 83, 91, 90, 1), PAL['stone'], 3.5, outline=STONE_LINE, grain=0.05, cut_corners=True)
    return L.finish()


# NEW SHRINE's slab (the user, 2026-10-26: a bit shorter at its sides, in the forest frame's own
# base stone and outline; only slab.png and slab_side.png, into textures/pet/shrine_new/:
#   SHRINE_SLAB=new python3 tools/art/shrine.py)
NEW_SLAB_X = (24, 87)
NEW_STONE = [(240, 202, 164), (196, 150, 122), (252, 233, 192)]
NEW_STONE_LINE = (36, 2, 18)
NEW_SLAB_CORNERS = [(NEW_SLAB_X[0] - 0.5, 82.5), (NEW_SLAB_X[1], 82.5), (NEW_SLAB_X[0] - 0.5, 90), (NEW_SLAB_X[1], 90)]


def slab_layer_new():
    L = Layer()
    L.add(rrect(NEW_SLAB_X[0], 83, NEW_SLAB_X[1], 90, 1), NEW_STONE, 3.5, outline=NEW_STONE_LINE, grain=0.05, cut_corners=True)
    return L.finish()


def sanbo_layers():
    """The offering stand (sanbo) on the slab's top, in front of the wood, where offerings land: two
    boxes for the 3D tilt (scripts/shrine.gd), its base (a cut-out in its face) and its tray, a
    little wider, on top (its outline over the base's top); low, so the pal stays in sight"""
    base = Layer()
    base.add(rrect(45, 78.5, 66, 84, 0.8), PAL['hinoki'], 2.0)
    base.line(rrect(52, 80, 59, 83, 0), np.array([92, 66, 54], np.float32))      # the cut-out, one square in the middle (the user: symmetric)
    tray = Layer()
    tray.add(rrect(41, 76, 70, 79.1, 0.8), PAL['hinoki'], 1.6)
    return base.finish(), tray.finish()


def _prop(mask_fn, w, h, rings=(), line=1):
    """A small ceramic prop drawn at the foods' pixel size (~3 px each on screen, finer than the
    shrine's grid, like the offerings it holds): mask_fn(x, y) on a 4x supersampled canvas -> its
    shape; white glaze lit from the top left, a soft shade low and right, a 1 px outline; rings =
    [(mask_fn, colour)] painted on it"""
    k = 4
    yy, xx = np.mgrid[0:h * k, 0:w * k] / k
    m = mask_fn(xx, yy).reshape(h, k, w, k).mean((1, 3)) > 0.5
    rgb = np.zeros((h, w, 3), np.float32)
    Y, X = np.mgrid[0:h, 0:w]
    lit = 1.0 - 0.10 * (X / w) - 0.16 * (Y / h)
    rgb[:] = np.array([248, 244, 236], np.float32) * lit[..., None]
    d = ndimage.distance_transform_edt(m)
    edge = (d <= 1.5) & m
    rgb[edge] *= 0.86
    hl = (d >= 2) & (X < w * 0.4) & (Y < h * 0.45) & m
    rgb[hl] = np.minimum(rgb[hl] * 1.06, 255)
    for fn, col in rings:
        r = fn(xx, yy).reshape(h, k, w, k).mean((1, 3)) > 0.5
        rgb[r & m] = col
    e = line
    out = np.zeros((h + 2 * e, w + 2 * e, 4), np.uint8)
    out[e:-e, e:-e, :3] = np.clip(rgb, 0, 255)
    out[e:-e, e:-e, 3] = m * 255
    full = np.zeros((h + 2 * e, w + 2 * e), bool)
    full[e:-e, e:-e] = m
    ring = ndimage.binary_dilation(full, structure=np.ones((3, 3)), iterations=e) & ~full
    out[ring, :3] = OUTLINE
    out[ring, 3] = 255
    return Image.fromarray(out, 'RGBA')


CUP_PX = float(os.environ.get('CUP_PX', '0.72'))   # (scripts/shrine.gd's CUP_PX: keep them the same)


def drink_parts():
    """The drink offering (scripts/shrine.gd), at the foods' pixel size: a small white sake bottle
    (tokkuri) with a blue band, that comes down and pours; the little cup (kiki-choko: white, a blue
    ring inside) on the sanbo's tray, seen a little from above (its mouth shows): cup.png, its body
    alone (cup_body.png: the 3D copies' silhouette) and the drink in it (cup_liquid.png, white: the
    game tints it)"""
    def el(x, y, cx, cy, rx, ry):
        return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0
    # drawn at CUP_PX grid cells per pixel (the user: chunkier, like the shrine; it was 0.36, the
    # foods' size): the shapes are laid out on the 0.36 layout (30 x 20) and sampled coarser
    f = 0.36 / CUP_PX
    W, H = round(30 * f), round(20 * f)
    sc = lambda fn: (lambda x, y: fn(x / f, y / f))
    body = sc(lambda x, y: el(x, y, 15, 9, 15, 11) & (y >= 4.5))
    mouth = sc(lambda x, y: el(x, y, 15, 4.6, 15, 4.6))
    inside = sc(lambda x, y: el(x, y, 15, 4.8, 12.6, 3.3))
    ring = sc(lambda x, y: el(x, y, 15, 5.0, 7.0, 2.4) & ~el(x, y, 15, 5.0, 4.2, 1.2))
    e = 1 if CUP_PX > 0.5 else 2           # (the outline: about 0.7 cells thick either way)
    out = {}
    cup = _prop(lambda x, y: body(x, y) | mouth(x, y), W, H,
                rings=[(inside, (204, 198, 192)), (ring, PAL['indigo'][0])], line=e)
    out['cup'] = cup
    out['cup_body'] = _prop(body, W, H, line=e)
    liq = np.zeros((H + 2 * e, W + 2 * e, 4), np.uint8)
    yy, xx = np.mgrid[0:H * 4, 0:W * 4] / 4
    lm = inside(xx, yy).reshape(H, 4, W, 4).mean((1, 3)) > 0.5
    liq[e:-e, e:-e][lm] = (255, 255, 255, 255)
    out['cup_liquid'] = Image.fromarray(liq, 'RGBA')
    tw, th = 16, 30
    bottle = lambda x, y: el(x, y, 8, 21.5, 8, 8.5) | ((np.abs(x - 8) <= 2.6) & (y >= 3) & (y <= 15)) | el(x, y, 8, 2.6, 3.8, 2.0)
    band = lambda x, y: (y >= 19.5) & (y <= 21.5)
    out['tokkuri'] = _prop(bottle, tw, th, rings=[(band, PAL['indigo'][0])])
    return out


def rope_parts():
    """The bell rope (suzu-no-o) as pieces the game hangs on a chain (scripts/shrine.gd): the bell
    and a red and a white bead of the twisted rope, each cropped to itself"""
    out = {}
    for name, pal, (rx, ry), th in (('bell', PAL['gold'], (2.6, 2.5), 2.2), ('bead_red', PAL['red'], (1.8, 2.1), 1.5),
                                    ('bead_white', PAL['white'], (1.8, 2.1), 1.5)):
        L = Layer()
        L.add(ellipse(55 - rx, 55 - ry, 55 + rx, 55 + ry), pal, th, outline=OLD_LINE)
        im = L.finish(blur=0.8)              # (as first drawn: the user liked those outlines)
        out[name] = im.crop(im.getbbox())
    return out


def sky_parts():
    """The sun and the moon in its 8 phases (0 new, 2 first quarter, 4 full, 6 last quarter), for
    the sky behind the shrine (scripts/shrine.gd moves them with the real time): flat, one tone, no
    outline (the user: subtle and distant), on the art's grid; the sun with a faint halo, the
    moon's night side a faint ghost; cropped"""
    out = {}

    def disc(r, col, alpha_of):
        n = int(math.ceil(r * 2 + 4))
        img = np.zeros((n, n, 4), np.float32)
        c = n / 2.0
        for y in range(n):
            for x in range(n):
                nx, ny = (x + .5 - c) / r, (y + .5 - c) / r
                a = alpha_of(nx, ny)
                if a > 0:
                    img[y, x] = (*col, a * 255)
        im = Image.fromarray(img.astype(np.uint8), 'RGBA')
        return im.resize((round(n * 925 / 110), round(n * 924 / 110)), Image.NEAREST).filter(ImageFilter.GaussianBlur(BLUR))

    def sun_a(nx, ny):
        d = math.hypot(nx, ny)
        return 1.0 if d <= 1.0 else (.32 if d <= 1.45 else 0.0)
    out['sun'] = disc(4.6, (255, 244, 220), sun_a)
    for ph in range(8):
        k = math.cos(2 * math.pi * ph / 8)

        def moon_a(nx, ny, ph=ph, k=k):
            if math.hypot(nx, ny) > 1.0:
                return 0.0
            h = math.sqrt(max(0.0, 1 - ny * ny))
            lit = nx > k * h if ph <= 4 else -nx > k * h
            return 1.0 if lit else .16
        out['moon_%d' % ph] = disc(4.0, (250, 246, 236), moon_a)
    return out


# The front's corners: a small dark dot at each in the side pictures, so the stacked copies draw a
# line from each front corner back to the back's (the user: the box's edges along its depth
# outlined, as pixel art draws them; then thinner: half an art pixel). Each is the dot's top-left
# (grid, on the outline's outer corner; for the stone's cut corners, the step's middle); the right
# side mirrored.
CORNER_DOT = 0.5                      # (grid cells)
CORNER_COL = (66, 38, 50)             # (the outline's colour: the edges all one dark)
_FRONT_CORNERS_L = [(14, 26), (14, 32), (52, 4), (20, 33.5), (23, 76), (23, 83.5), (24.5, 88.5), (24.5, 101)]
FRONT_CORNERS = sorted(set(_FRONT_CORNERS_L + [(110.5 - x, y) for x, y in _FRONT_CORNERS_L]))
SLAB_CORNERS = [(19.5, 82.5), (91, 82.5), (19.5, 90), (91, 90)]
_mirror = lambda pts: sorted(set(pts + [(110.5 - x, y) for x, y in pts]))
TRAY_CORNERS = _mirror([(40, 75), (40, 79.5)])             # the sanbo's tray and base (the user: the table's edges too)
BASE_CORNERS = _mirror([(44.5, 77.5), (44, 84.5)])


def side_of(front, outlined=False, light=0.78, seams=(), corners=(), corner_col=CORNER_COL):
    """The front's silhouette in side colours, for the box's sides (copies stacked behind the front):
    its colours smoothed (no outlines or highlights: a stack of them must read as one surface),
    greyed and a little darker; outlined = the backmost copy's, with a contour; seams = grid rows
    (y0, y1) outlined right across (stacked, they draw an edge along the side: the user, the
    columns' ends outlined from every side)"""
    a = np.asarray(front, np.float32)
    al = a[..., 3] > 127
    rgb = a[..., :3].copy()
    lum = rgb @ np.array([.3, .59, .11], np.float32)
    dark = lum < 90                                    # the outline and dark lines: fill from around
    src = al & ~dark
    acc = np.zeros_like(rgb); wsum = np.zeros(al.shape, np.float32)
    for c_ in range(3):
        acc[..., c_] = ndimage.uniform_filter(np.where(src, rgb[..., c_], 0), 41)
    wsum = ndimage.uniform_filter(src.astype(np.float32), 41)
    sm = acc / np.maximum(wsum, 1e-3)[..., None]
    l2 = sm @ np.array([.3, .59, .11], np.float32)
    sm = (sm * .6 + l2[..., None] * .4) * light
    out = np.dstack([np.clip(sm, 0, 255), al * 255]).astype(np.uint8)
    im = Image.fromarray(out, 'RGBA')
    if seams:
        cell = a.shape[0] / G
        rows = np.arange(a.shape[0])[:, None] / cell
        band = np.zeros(al.shape, bool)
        for y0, y1 in seams:
            band |= (rows >= y0) & (rows < y1)
        o = np.asarray(im).copy()
        o[band & al, :3] = OUTLINE
        im = Image.fromarray(o, 'RGBA')
    if corners:
        o = np.asarray(im).copy()
        cw, chh = a.shape[1] / G, a.shape[0] / G
        for gx, gy in corners:
            o[int(round(gy * chh)):int(round((gy + CORNER_DOT) * chh)), int(round(gx * cw)):int(round((gx + CORNER_DOT) * cw))] = (*corner_col, 255)
        im = Image.fromarray(o, 'RGBA')
    if outlined:
        edge = al & ~ndimage.binary_erosion(al, iterations=9)
        o = np.asarray(im).copy()
        o[edge, :3] = OUTLINE
        im = Image.fromarray(o, 'RGBA')
    return im


# (being tried, 2026-10-21: the shrine on land, moss on its stone; the user likes it floating too)
MOSS = os.environ.get('MOSS', '0') == '1'     # (with the land: off with it for now)
PAL['moss'] = [(150, 178, 104), (88, 116, 66), (196, 216, 146)]


def _moss(inside, bottom, h):
    """Moss creeping up a stone from its bottom edge: a ragged band up to ~h cells high, a couple of
    patches reaching higher"""
    edge = (np.sin(XX * 0.9) * 0.6 + np.sin(XX * 0.37 + 1.3) * 1.0 + np.sin(XX * 0.17 + 0.4) * 1.4)
    reach = h * 0.55 + edge * h * 0.25
    return inside & (YY > bottom - reach)


GRASS = [(178, 204, 140), (124, 154, 102), (214, 232, 180)]
GRASS_LINE = (100, 130, 84)           # (the user: no plum outline on the grass, a darker green)


def land_layer():
    """The grassy ground the shrine stands on (the user: grass, not floating): its horizon (grid y
    92 in the middle, a gentle hill) behind the pedestal, a serrated grass edge on it, outlined in
    a darker green. scripts/shrine.gd lays it as a ground plane for the tilt (land.gdshader) and
    casts the shrine's shadow on it from the sun"""
    L = Layer()
    hz = lambda x: 92.0 + ((x - 55.5) / 58.0) ** 2 * 4.0
    ground = (YY > hz(XX)) | ((YY > hz(XX) - 1.0) & ((XX % 3.0) < 1.0))
    L.add(ground, GRASS, 5.0, grain=0.03, outline=GRASS_LINE)
    return L.finish(blur=0.45)


LANTERN_AT = (76.0, 34.0)             # where its cord hangs from: the bell rope's mirror, a pixel under the beam's outline
LANTERN_BOX = (66, 31, 86, 52)        # its picture's crop (grid): LANTERN_AT is (10, 3) cells into it
def lantern_layer():
    """The red paper lantern (chochin) with its cord, hung from one point under the beam on the
    right (the bell rope's on the left; the user): red paper and its ribs, black caps and tassel, a
    pale circle in the middle, lit from inside by a candle (the paper glows warmer and brighter
    round its middle), one soft brown outline round it all. Mirror-symmetric (its shapes measured
    from the middles of the fine samples, so no side gets an extra pixel). scripts/shrine.gd swings
    it round that point and adds a faint flickering glow"""
    ax, ay = LANTERN_AT
    u, v = XX + 0.5 / SS - ax, YY + 0.5 / SS - ay
    au = np.abs(u)
    ell = lambda cu, cv, ru, rv: ((u - cu) / ru) ** 2 + ((v - cv) / rv) ** 2 <= 1.0
    L = Layer()
    L.add((au < 1.0) & (v > 0.0) & (v < 3.0), [(120, 84, 66), (96, 64, 52), (150, 110, 88)], 0.5, outline=False)   # the cord
    L.add((au < 1.0) & (v > 13.4) & (v < 16.6), [(60, 44, 48), (36, 24, 30), (96, 76, 80)], 0.6, outline=False)    # the tassel
    body = ell(0, 8.3, 4.5, 4.9) & (v > 3.4) & (v < 13.2)
    L.add(body, [(236, 96, 78), (164, 44, 48), (255, 176, 150)], 2.6, outline=False)
    L.add(ell(0, 8.3, 3.2, 3.6), [(250, 138, 100), (240, 108, 82), (255, 190, 150)], 1.8, outline=False)  # the candle's light through the paper
    inner = ell(0, 8.3, 3.6, 4.2)
    L.line(inner & (((v - 5.0) % 2.2) < 0.55) & ~ell(0, 8.3, 2.6, 2.6), np.array([196, 70, 62], np.float32))   # its ribs
    L.add(ell(0, 8.3, 2.0, 2.0), [(255, 236, 200), (240, 196, 150), (255, 250, 230)], 0.8, outline=False)   # the circle, lit
    for v0, v1, w in ((2.5, 3.9, 3.0), (12.6, 14.0, 3.0)):                                              # the caps
        L.add((au < w) & (v > v0) & (v < v1), [(70, 50, 54), (40, 26, 32), (112, 90, 94)], 0.7, outline=False)
    ring = ndimage.binary_dilation(L.a, structure=np.ones((3, 3))) & ~L.a
    L.rgb[ring] = OLD_LINE
    L.a |= ring
    im = L.finish(blur=0.8)
    x0, y0, x1, y1 = LANTERN_BOX
    return im.crop((round(x0 * 925 / 110), round(y0 * 924 / 110), round(x1 * 925 / 110), round(y1 * 924 / 110)))


ORN_AT = (30.0, 81.0)                 # the ornaments' middles (grid x): left of the sanbo and its mirror right
ORN_FOOT = 84.0                       # where they stand on the slab (grid y: as the sanbo's base)
PAL['sakaki'] = [(92, 150, 90), (46, 92, 58), (160, 206, 140)]


def _ornament_finish(L, line):
    ring = ndimage.binary_dilation(L.a, structure=np.ones((3, 3))) & ~L.a
    L.rgb[ring] = np.array(line, np.float32)
    L.a |= ring
    return L.finish(blur=0.45)


def stone_lantern_layer():
    """A small stone lantern (toro) on the slab, left of the sanbo (the user: a stone ornament): its
    plinth, post, platform, the fire box with its window (dark, a faint warm glow inside), the roof
    with its corners turned up and the jewel on top; in the base's stone, its outline. Mirror-
    symmetric (measured from the fine samples' middles). Full canvas, a 3D piece (its side_of)"""
    cx = ORN_AT[0]
    u, v = XX + 0.5 / SS - cx, YY + 0.5 / SS
    au = np.abs(u)
    f = ORN_FOOT
    L = Layer()
    stone = PAL['stone']
    for (w, y0, y1, th) in ((4.0, f - 2.0, f, 1.4), (1.6, f - 7.0, f - 2.0, 1.0), (3.6, f - 8.5, f - 7.0, 1.0), (3.0, f - 13.0, f - 8.5, 1.6)):
        L.add((au < w) & (v > y0) & (v < y1), stone, th, outline=False, grain=0.05)
    L.add((au < 1.6) & (v > f - 12.0) & (v < f - 9.5), [(150, 96, 70), (96, 56, 48), (196, 140, 96)], 0.6, outline=False)   # its window
    roof = (v > f - 15.5) & (v < f - 13.0) & (au < 2.6 + (v - (f - 15.5)) * 1.0)
    roof |= (v > f - 14.0) & (v < f - 12.8) & (au < 5.4) & (au > 3.6)                                         # (its corners, turned up)
    L.add(roof, stone, 1.2, outline=False, grain=0.05)
    L.add(((u / 1.2) ** 2 + ((v - (f - 16.4)) / 1.2) ** 2) <= 1.0, stone, 0.8, outline=False)              # the jewel
    return _ornament_finish(L, STONE_LINE)


def sakaki_layer():
    """A potted sakaki (the shrine's sacred evergreen) on the slab, right of the sanbo (the user: a
    plant): a small white pot with an indigo band (as the cup), glossy dark leaves on three stems in
    a rounded bush; one outline round it all. Full canvas, a 3D piece (its side_of)"""
    cx = ORN_AT[1]
    u, v = XX + 0.5 / SS - cx, YY + 0.5 / SS
    au = np.abs(u)
    f = ORN_FOOT
    L = Layer()
    for sx, top in ((-2.4, f - 11.0), (0.0, f - 13.5), (2.4, f - 11.0)):               # the stems
        t = np.clip((v - top) / ((f - 4.0) - top), 0, 1)
        L.add((np.abs(u - sx * (1.0 - t)) < 0.5) & (v > top) & (v < f - 4.0), [(120, 84, 60), (84, 56, 44), (150, 110, 80)], 0.5, outline=False)
    leaves = np.zeros_like(au, bool)
    for lx, ly, rx, ry in ((-3.6, f - 10.5, 1.9, 1.3), (-1.4, f - 12.5, 1.9, 1.3), (1.4, f - 12.5, 1.9, 1.3), (3.6, f - 10.5, 1.9, 1.3),
                           (0.0, f - 14.2, 1.6, 1.3), (-2.6, f - 8.2, 1.9, 1.2), (2.6, f - 8.2, 1.9, 1.2), (0.0, f - 9.8, 2.0, 1.3)):
        leaves |= (((u - lx) / rx) ** 2 + ((v - ly) / ry) ** 2) <= 1.0
    L.add(leaves, PAL['sakaki'], 1.0, outline=False)
    pot = (v > f - 5.0) & (v < f) & (au < 3.4 - (v - (f - 5.0)) * 0.25)
    L.add(pot, [(244, 240, 232), (176, 166, 162), (255, 255, 255)], 1.4, outline=False)
    L.line(pot & (v > f - 3.6) & (v < f - 2.6), np.array(PAL['indigo'][0], np.float32))
    return _ornament_finish(L, OUTLINE)


# ------------------------------------------------------------------ A BOLD LOOK (being tried)
# (2026-10-22, the user: the gut reads stronger at first glance; a simpler, bolder shrine with the same
# pieces, fewer straight lines: chunky rounded wood, a curved roof with its eaves turned up, puffy
# shading like the gut's loops, rounded stone, a light warm inside so the spirit stands out.
# SHRINE_SHAPE=bold; the pal's window stays where it is)
SHAPE = os.environ.get('SHRINE_SHAPE', '')


def _roof_curve(x):
    t = np.clip(np.abs(x - 55.5) / 45.5, 0, 1)
    top = 5.0 + 19.0 * (1.0 - (1.0 - t) ** 1.9) - 3.5 * np.clip((t - 0.8) / 0.2, 0, 1) ** 2   # (a sag, the tips turned up)
    return top, top + 8.0 - 1.0 * t


def front_layer_bold():
    L = Layer()
    L.add(rrect(23, 89, 88, 101, 3), PAL['stone'], 6, outline=STONE_LINE, grain=0.04)
    for x0 in (21, 80):
        L.add(rrect(x0, 30, x0 + 10, 81, 3), PAL['wood'], 4.5)
    L.add(rrect(20, 77, 91, 84, 3), PAL['wood2'], 3.5)
    top, bot = _roof_curve(XX)
    L.add((YY > bot - 1.0) & (YY < 27.0) & (np.abs(XX - 55.5) < 34), PAL['wood2'], 5)                   # the gable
    L.add(rrect(18, 26, 93, 34, 3), PAL['wood2'], 3.5)                                                   # the beam
    R = Layer(fine=True)
    roof = (YY > top) & (YY < bot) & (np.abs(XX - 55.5) < 46)
    roof |= ((XX - 10.0) ** 2 / 2.2 ** 2 + (YY - (top + bot) / 2) ** 2 / 3.4 ** 2 <= 1.0) & (XX < 12)     # (round eave tips)
    roof |= ((XX - 101.0) ** 2 / 2.2 ** 2 + (YY - (top + bot) / 2) ** 2 / 3.4 ** 2 <= 1.0) & (XX > 99)
    R.add(roof, PAL['roof'], 3.5, outline=ROOF_LINE)
    R.add(ellipse(51.5, 1.5, 59.5, 9.5), PAL['roof'], 2.5, outline=ROOF_LINE)                           # the ridge's round cap
    return Image.alpha_composite(L.finish(), R.finish())


def back_layer_bold():
    L = Layer()
    L.add(rrect(29, 30, 82, 80, 0.5), [(246, 232, 210), (206, 176, 156), (255, 248, 236)], 12, outline=OLD_LINE)
    L.add(rrect(30, 70, 81, 79, 0.5), [(226, 186, 150), (184, 140, 112), (244, 214, 182)], 4, outline=OLD_LINE,
          stripes=((YY - 70) % 3.0 < 0.6))
    ring = ellipse(43, 41.5, 71, 67.5) & ~ellipse(45, 43.5, 69, 65.5)
    L.add(ring, [(222, 196, 170), (196, 164, 140), (236, 216, 194)], 1.0, outline=False)              # the mirror, faint
    return L.finish(blur=0.8)


def slab_layer_bold():
    L = Layer()
    L.add(rrect(18, 83, 93, 90, 3), PAL['stone'], 4, outline=STONE_LINE, grain=0.04)
    return L.finish()


if __name__ == '__main__':
    here = os.path.dirname(os.path.abspath(__file__))
    if os.environ.get('SHRINE_SLAB') == 'new':
        out = os.path.join(here, '..', '..', 'textures', 'pet', 'shrine_new')
        slab = slab_layer_new()
        slab.save(os.path.join(out, 'slab.png'))
        side_of(slab, light=0.97, corners=NEW_SLAB_CORNERS, corner_col=NEW_STONE_LINE).save(os.path.join(out, 'slab_side.png'))
        sys.exit()
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, '..', '..', 'textures', 'pet', 'shrine')
    os.makedirs(out, exist_ok=True)
    back_layer().save(os.path.join(out, 'inside.png')) if SHAPE != 'bold' else back_layer_bold().save(os.path.join(out, 'inside.png'))
    fronts = [front_layer(0) if SHAPE != 'bold' else front_layer_bold()]
    fronts[0].save(os.path.join(out, 'front.png'))
    slab = slab_layer() if SHAPE != 'bold' else slab_layer_bold()
    slab.save(os.path.join(out, 'slab.png'))
    side_of(slab, light=0.97, corners=SLAB_CORNERS if SHAPE != 'bold' else ()).save(os.path.join(out, 'slab_side.png'))     # (its top, lit from above)
    dp = drink_parts()
    for k in ('tokkuri', 'cup', 'cup_liquid'):
        dp[k].save(os.path.join(out, k + '.png'))
    side_of(dp['cup_body'], light=0.9).save(os.path.join(out, 'cup_side.png'))
    base, tray = sanbo_layers()
    base.save(os.path.join(out, 'sanbo_base.png'))
    tray.save(os.path.join(out, 'sanbo_tray.png'))
    side_of(base, light=0.8, corners=BASE_CORNERS).save(os.path.join(out, 'sanbo_base_side.png'))
    side_of(tray, light=0.97, corners=TRAY_CORNERS).save(os.path.join(out, 'sanbo_tray_side.png'))  # (its top lit)
    land_layer().save(os.path.join(out, 'land.png'))
    lantern_layer().save(os.path.join(out, 'lantern.png'))
    if os.environ.get('ORNAMENTS'):           # (possibles for the decor menu, not in the game yet)
        for name, fn in (('orn_stone', stone_lantern_layer), ('orn_plant', sakaki_layer)):
            im = fn()
            im.save(os.path.join(out, name + '.png'))
            side_of(im, light=0.85).save(os.path.join(out, name + '_side.png'))
    for k, im in list(rope_parts().items()) + list(sky_parts().items()):
        im.save(os.path.join(out, k + '.png'))
    col_ends = ((32.2, 33.1),)
    side_corners = FRONT_CORNERS if SHAPE != 'bold' else ()
    side_of(fronts[0], seams=col_ends, corners=side_corners).save(os.path.join(out, 'side.png'))
    back_contour = True
    side_of(fronts[0], back_contour, seams=col_ends, corners=side_corners).save(os.path.join(out, 'side_back.png'))
    print('ok', out)
