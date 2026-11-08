"""Each spirit's moving bits, made on the approved sprite itself (2026-11-06: the designer drew the
faces; the parts are ours, in the drink aura's style, like the pilot's lightning).

Nothing hidden is ever invented: a part moves only where air is behind it, or by a pixel over its
own body (the gap filled with the body colour right next to it). So:
  bend      sprouts, leaves, ears, tails, wings, fins, tassels: bent from where they join the body,
            whole pixels, the joint never moves (style: sway, twitch, wag, flap, swing, beat)
  flame     flames and flame tips: the designer's own flame stretched, swayed, its core flickering,
            embers rising (scripts/spirit_anim.gd builds the frames)
  bolt      lightning: white-hot strikes with a glow, dimming between (never hidden)
  drift     floating bits (drops, wisps, clouds): a slow pixel bob
  fall      petals, rain, drips: fall, fade, form again
  rise      smoke: rises, fades, forms again
  twinkle   stars and sparkles: each flashes white-hot now and then
  glow      a lamp's light: brighter, dimmer
  lag       things that just sit on top (a crown, a cap, a marble): a pixel behind on hops
  cycle     the wind-up spirits' key and cogs (their own drawing code below)
and per spirit: wobbly (rocks like a daruma instead of hopping), fx (bubbles rising in a drink,
glints on water or gold, drips forming at an edge).

The parts are found from boxes on the 56 x 56 sprite (and a colour where the box holds more than
the part); see the SPEC table. The body under a part is the sprite without it: air outside the
body's outline, the nearest body colour inside it, the outline closed where the part joined.
body + every part at rest is the sprite exactly (checked).

    .venv/bin/python tools/art/spirit_parts.py [ids]

Writes into docs/mockups/spirits/anim_frames/<id>/: <face>_body.png (each face without its parts),
part_<name>.png (the part at rest) and part_<name>_<i>.png (its poses or frames), merges each
spirit's rig into anim_frames/rig.json, and a check sheet per realm (parts_check_<realm>.png).
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from october_sheet_cut import SP  # noqa: E402
from spirit_px import OUTLINE  # noqa: E402

DEST = SP / "anim_frames"
FACES = ["base", "closed", "open", "happy", "sad", "angry"]
S = 56


def B(box, motion, rule=None, **kw):
    return dict(box=box, motion=motion, rule=rule, **kw)


# id -> parts (name -> box (x0, y0, x1, y1, inclusive), motion, colour rule, options) and flags
SPEC = {
    # Mountain
    "peapod": {"parts": {"sprout": B((23, 19, 38, 27), "sway", "green")}},
    "melon_pan": {"parts": {"sprout": B((31, 16, 45, 25), "sway", "green")}},
    "usagi": {"parts": {"leaf": B((26, 21, 37, 30), "sway", "green"), "petal": B((40, 45, 48, 53), "drift", "pink")}},
    "yomogi": {"parts": {"leaf": B((12, 19, 24, 27), "sway", "green")}},
    "usagi_manju": {"parts": {"petal": B((39, 20, 47, 28), "fall", "pink", style="petal")}},
    "yamabiko": {"parts": {"cloud_l": B((2, 30, 17, 46), "drift", "white", axis="x", side=-1),
                           "cloud_r": B((38, 30, 54, 46), "drift", "white", axis="x", side=1)}},
    "mujina": {"parts": {"leaf": B((21, 21, 36, 31), "sway", "green")}},
    "kodama": {"parts": {"sprout": B((19, 19, 35, 29), "sway", "green")}},
    "karasu_tengu": {"parts": {"cap": B((19, 15, 35, 27), "lag", "dark"),
                               "wing_l": B((2, 32, 16, 45), "flap", "white", anchor="right"),
                               "wing_r": B((38, 32, 54, 45), "flap", "white", anchor="left")}},
    "gherk": {"parts": {"antennae": B((16, 15, 37, 26), "sway", "gold")}},
    "kiwi_bird": {"wobbly": True},
    "bud": {"parts": {"sprout": B((22, 23, 37, 30), "sway", "green")}},
    "karakuri": {"clockwork": True, "parts": {"sprout": B((37, 13, 48, 23), "sway", "green")}},
    "zorb": {"parts": {"star": B((20, 21, 34, 34), "sway", "gold"), "stars": B((0, 0, 55, 55), "twinkle", "gold", loose=True)}},
    "world_tree": {"parts": {"canopy": B((3, 9, 53, 22), "sway", None, amp=1)}},
    # Moon
    "leafwing": {"parts": {"leaf": B((17, 17, 46, 34), "sway", "green"), "bells": B((12, 20, 28, 38), "swing", "white")}},
    "owlet": {"parts": {"wing_l": B((2, 25, 19, 54), "flap", "nonwhite", anchor="right"),
                        "wing_r": B((37, 25, 54, 54), "flap", "nonwhite", anchor="left")}},
    "scarab": {"parts": {"wisp_l": B((2, 18, 13, 35), "flame", "blue"), "wisp_r": B((43, 32, 55, 48), "flame", "blue"),
                         "tips": B((15, 13, 45, 31), "flame", None)}},
    "fudge": {"parts": {"ear_l": B((17, 17, 27, 29), "twitch"), "ear_r": B((28, 17, 38, 29), "twitch")}},
    "bonbon": {"parts": {"ear_l": B((11, 13, 25, 25), "twitch"), "ear_r": B((26, 13, 41, 25), "twitch")}},
    "kuri": {"parts": {"ear_l": B((17, 15, 29, 31), "twitch"), "ear_r": B((30, 15, 42, 31), "twitch")}},
    "gremlin": {"parts": {"ghost": B((41, 35, 52, 45), "drift", "white"), "dots": B((0, 0, 55, 55), "drift", None, loose=True)}},
    "churro": {"parts": {"star": B((40, 46, 48, 54), "twinkle", "gold")}},
    "choco_taco": {"wobbly": True, "parts": {"chime": B((24, 46, 32, 55), "swing")}},
    "hot_cocoa": {"wobbly": True},
    "cocoa_fire": {"parts": {"light": B((18, 33, 36, 42), "glow")}},
    "taiyaki": {"parts": {"tail": B((40, 27, 53, 45), "wag", anchor="left", amp=2)}},
    "bumble": {"parts": {"leaf": B((37, 27, 46, 37), "sway", "green", anchor="left")}},
    "ramune": {"parts": {"marble": B((24, 25, 34, 35), "lag", "green")},
               "fx": [{"type": "bubbles", "box": [18, 34, 40, 49]}]},
    "cocoa_9": {"clockwork": True},
    "kaguya": {"parts": {"sparkles": B((0, 0, 55, 55), "twinkle", None, loose=True)}},
    "tsukuyomi": {"parts": {"ear_l": B((12, 10, 26, 29), "twitch"), "ear_r": B((31, 10, 46, 29), "twitch")}},
    # Fox
    "kitsune": {"parts": {"ear_l": B((12, 19, 21, 29), "twitch"), "ear_r": B((33, 19, 42, 29), "twitch")}},
    "kyubi": {"parts": {"wisp_l": B((2, 27, 12, 44), "flame", "blue"), "wisp_r": B((43, 27, 54, 44), "flame", "blue")}},
    "konoha": {"parts": {"leaf": B((16, 15, 43, 34), "sway", "green", amp=1)}},
    "waffle": {"parts": {"leaf": B((28, 21, 43, 31), "sway", "green", anchor="left")}},
    "fried_egg": {"parts": {"tail": B((39, 32, 52, 48), "wag", anchor="left", amp=2)}},
    "burger": {"parts": {"leaf": B((21, 17, 32, 28), "sway", "green"), "tail": B((40, 31, 53, 47), "wag", anchor="left", amp=2)}},
    "hot_dog": {"parts": {"tail": B((40, 31, 53, 48), "wag", anchor="left", amp=2)}},
    "fish_taco": {"parts": {"tail": B((42, 35, 54, 49), "wag", anchor="left", amp=2)}},
    "drumstick": {"parts": {"bachi_l": B((2, 28, 11, 39), "beat", "warm"), "bachi_r": B((43, 28, 53, 39), "beat", "warm")}},
    "kitsu": {"wobbly": True},
    "hothog": {"parts": {"sprout": B((23, 15, 39, 24), "sway", "green")}},
    "walrusk": {"wobbly": True},
    "robobear": {"clockwork": True},
    "nebula_nug": {"parts": {"flame": B((17, 12, 33, 25), "flame", "blue"),
                             "stars": B((4, 26, 52, 50), "twinkle", "gold", loose=True, onbody=True)}},
    "sunbear": {"parts": {"leaf": B((22, 15, 37, 25), "sway", "gold")}},
    # Fire
    "hoozuki": {"parts": {"leaf": B((32, 18, 49, 34), "sway", "green", anchor="left")}},
    "pepper_plant": {"parts": {"stem": B((25, 13, 36, 24), "sway", "green")}},
    "chameleon": {"wobbly": True},
    "daruma": {"wobbly": True},
    "oo_daruma": {"wobbly": True},
    "quesadilla": {"parts": {"light": B((10, 22, 46, 44), "glow")}},
    "burrito": {"parts": {"smoke": B((11, 7, 23, 20), "rise", "white")}},
    "firebug": {"parts": {"bolt": B((29, 15, 43, 35), "strike", "gold"), "flame_l": B((2, 24, 13, 40), "flame", "warm"),
                          "flame_r": B((43, 24, 55, 38), "flame", "warm"), "flame_t": B((13, 21, 25, 30), "flame", "warm")}},
    "salamander": {"parts": {"tips": B((13, 14, 38, 32), "flame", None), "drop_a": B((8, 32, 16, 42), "drift", "blue"),
                             "drop_b": B((40, 25, 49, 34), "drift", "blue"), "drop_c": B((44, 41, 52, 49), "drift", "blue")}},
    "ember": {"parts": {"tip": B((17, 26, 31, 35), "flame", None)}},
    "mecha_oni": {"clockwork": True},
    "comet_chili": {"parts": {"spark": B((21, 8, 31, 23), "flame", "warm")}},
    "hou_ou": {"parts": {"crest": B((11, 8, 36, 25), "flame", "warm"), "tail": B((31, 14, 53, 42), "flame", "warm")}},
    # River
    "kappa_maki": {"parts": {"drop": B((32, 22, 40, 29), "twinkle", "blue")},
                   "fx": [{"type": "drip", "at": [44, 31]}]},
    "ume_onigiri": {"parts": {"drip": B((44, 28, 51, 37), "fall", "blue", style="drip")},
                    "fx": [{"type": "glints", "points": [[20, 23], [36, 22]]}]},
    "kappa": {"fx": [{"type": "glints", "points": [[21, 18], [31, 17]]}]},
    "granny": {"parts": {"bud": B((42, 31, 50, 41), "sway", "white")}},
    "sourpatch": {"parts": {"leaf": B((36, 26, 48, 34), "sway", "green", anchor="left")}},
    "lemon_sweet": {"parts": {"cherries": B((13, 14, 38, 30), "sway", "red", amp=1)}},
    "cream_soda": {"parts": {"cherry": B((29, 16, 42, 30), "sway", "noncream")}, "fx": [{"type": "bubbles", "box": [10, 31, 46, 45]}]},
    "lime": {"parts": {"drops": B((0, 0, 55, 55), "drift", "blue", loose=True), "leaf": B((27, 15, 39, 26), "sway", "green")}},
    "hermit": {"wobbly": True},
    "anemone": {"parts": {"splashes": B((0, 0, 55, 55), "drift", "blue", loose=True),
                          "tentacles": B((8, 41, 49, 55), "swing", None, amp=1)}},
    "calamari": {"parts": {"fin_l": B((2, 26, 15, 42), "flap", anchor="right"), "fin_r": B((41, 26, 54, 42), "flap", anchor="left")}},
    "octopepper": {"parts": {"knot": B((39, 23, 49, 32), "sway", "white", anchor="left", amp=1),
                             "tentacles": B((9, 45, 47, 55), "swing", None, amp=1)}},
    "axel": {"parts": {"gills_l": B((2, 25, 14, 45), "flap", "pink", anchor="right"),
                       "gills_r": B((41, 25, 54, 45), "flap", "pink", anchor="left")}},
    "teru_teru": {"wobbly": True, "parts": {"drops": B((0, 0, 55, 55), "fall", "blue", loose=True, style="rain")}},
    "omamori": {"wobbly": True},
    "kokeshi": {"wobbly": True},
    "robofrog": {"clockwork": True},
    "ningyo": {"parts": {"fin_l": B((8, 27, 18, 39), "flap", "purple", anchor="right"),
                         "fin_r": B((39, 27, 50, 39), "flap", "purple", anchor="left")}},
    "frog_king": {"parts": {"crown": B((18, 9, 38, 22), "lag", "gold")},
                  "fx": [{"type": "glints", "points": [[23, 13], [33, 13]]}]},
}
REALM = {}  # filled from the prep manifest


# ------------------------------------------------------------------ colours and shapes
def rule_mask(im, rule):
    r, g, b, a = (im[..., i].astype(int) for i in range(4))
    op = a > 0
    mx, mn = np.maximum(np.maximum(r, g), b), np.minimum(np.minimum(r, g), b)
    if rule is None:
        return op
    return op & {
        "green": (g > r + 8) & (g > b + 8),
        "white": (mn > 165) & (mx - mn < 60),
        "nonwhite": ~((mn > 175) & (mx - mn < 50)),
        "pink": (r > 170) & (r > g + 35) & (b > g - 10),
        "blue": (b > r + 25) & (b > g - 20),
        "gold": (r > 160) & (g > 110) & (b < 120) & (r >= g),
        "warm": (r > 180) & (g > 90) & (b < 140),
        "dark": (mx < 110),
        "purple": (b > g + 15) & (r > g + 5),
        "red": (r > 140) & (g < 110) & (b < 110) & (r > g + 50),
        "noncream": ~((mn > 135) & (mx - mn < 95)),
    }[rule]


def dark_mask(im):
    return (im[..., 3] > 0) & (im[..., :3].astype(int).sum(2) < 170)


def comps(mask):
    lab, n = ndimage.label(mask, structure=np.ones((3, 3)))
    return [lab == k for k in range(1, n + 1)]


def box_mask(box):
    x0, y0, x1, y1 = box
    m = np.zeros((S, S), bool)
    m[max(0, y0):min(S, y1 + 1), max(0, x0):min(S, x1 + 1)] = True
    return m


def find_part(im, spec):
    """the part's pixels: in its box, of its colour, with the dark outline touching them"""
    inbox = box_mask(spec["box"])
    if spec.get("loose"):
        # loose bits: small pieces apart from the body (stars round it, drops, sparkles)
        op = im[..., 3] > 0
        pieces = comps(op)
        main = max(pieces, key=lambda m: m.sum())
        loose = np.zeros((S, S), bool)
        for p in pieces:
            if p is main or p.sum() > 60:
                continue
            if spec["rule"] is None or (p & rule_mask(im, spec["rule"])).any():
                loose |= p
        # stars on the body itself (nebula_nug): small bright gold blobs inside the box
        if spec.get("onbody"):
            seeds = rule_mask(im, spec["rule"]) & inbox & ~loose
            for c in comps(seeds):
                if 2 <= c.sum() <= 24:
                    loose |= ndimage.binary_dilation(c) & (dark_mask(im) | c)
        return loose & inbox
    seed = rule_mask(im, spec["rule"]) & inbox
    if spec["rule"] is None:
        return seed
    ring = ndimage.binary_dilation(seed, structure=np.ones((3, 3))) & ~seed & dark_mask(im) & inbox
    return own_edge(im, seed | ring, inbox)


def own_edge(im, m, inbox, steps=3):
    """(2026-11-07) the part's own shading and outline round it go with it: a pixel next to the
    part whose colour is nearer the part's colours (or the outline) than the body's right beside it.
    Before, only the part's colour and the darkest outline went, so the grey under a white wing, a
    cloud's shadow or a stem's line stayed on the body as loose bits, seen whenever the part moved."""
    op = im[..., 3] > 0
    rgb = im[..., :3].astype(int)
    for _ in range(steps):
        near = ndimage.binary_dilation(m, structure=np.ones((3, 3))) & ~m & inbox & op
        far = op & ~ndimage.binary_dilation(m, structure=np.ones((3, 3)), iterations=3)
        if not near.any() or not far.any():
            break
        _, (by, bx) = ndimage.distance_transform_edt(~far, return_indices=True)
        _, (py, px) = ndimage.distance_transform_edt(~m, return_indices=True)
        add = np.zeros_like(m)
        for y, x in zip(*np.nonzero(near)):
            c = rgb[y, x]
            d_body = np.abs(c - rgb[by[y, x], bx[y, x]]).sum()
            d_part = np.abs(c - rgb[py[y, x], px[y, x]]).sum()
            if dark_mask(im)[y, x] or d_part + 12 < d_body:
                add[y, x] = True
        if not add.any():
            break
        m = m | add
    return m


def strays(im, masks):
    """bits the parts would leave on the body by themselves (pieces apart from the body's mass, next
    to a part): they belong to that part. Returns {part name: extra mask}."""
    names = [nm for nm in masks if masks[nm][1].get("motion") not in (None, "cycle")]
    if not names:
        return {}
    mask_all = np.any([masks[nm][0] for nm in names], 0)
    rest = (im[..., 3] > 0) & ~mask_all
    pieces = comps(rest)
    if not pieces:
        return {}
    main = max(pieces, key=lambda c: c.sum())
    near = ndimage.binary_dilation(mask_all, structure=np.ones((3, 3)), iterations=4)
    # thin strands sticking out of the body next to a part (a stem's top, a cap's knot): the body's
    # mass is what survives an opening, grown back two pixels inside the body (its own outline)
    core = ndimage.binary_opening(main, structure=np.ones((3, 3)))
    if core.any():
        core = max(comps(core), key=lambda c: c.sum())
        kept = ndimage.binary_dilation(core, structure=np.ones((3, 3)), iterations=2) & main
        thin = main & ~kept & near
        pieces = [c for c in pieces if c is not main] + [main & ~thin] + comps(thin)
        main = pieces[-1 - len(comps(thin))] if thin.any() else main
    out = {}
    for c in pieces:
        if c is main or c.sum() > 30 or not (c & near).any():
            continue
        best = min(names, key=lambda nm: ndimage.distance_transform_edt(~masks[nm][0])[c].min())
        out[best] = out.get(best, np.zeros_like(c)) | c
    return out


def anchor_of(m, spec, body):
    """where the part joins the body: the side it touches it most, unless the spec says"""
    if spec.get("anchor"):
        return spec["anchor"]
    if spec["motion"] in ("sway", "twitch", "beat"):
        return "bottom"
    if spec["motion"] == "swing":
        return "top"
    ys, xs = np.nonzero(m)
    touch = ndimage.binary_dilation(m) & body & ~m
    ty, tx = np.nonzero(touch)
    if not len(ty):
        return "bottom"
    dy, dx = ty.mean() - ys.mean(), tx.mean() - xs.mean()
    return ("bottom" if dy > 0 else "top") if abs(dy) >= abs(dx) else ("right" if dx > 0 else "left")


# ------------------------------------------------------------------ poses
def bend(img, m, anchor, k):
    """the part bent k pixels at its far end, the joint still: rows (top/bottom anchor) slide
    sideways, columns (left/right anchor) slide up or down; k > 0 = right, or up"""
    out = np.zeros_like(img)
    ys, xs = np.nonzero(m)
    if anchor in ("bottom", "top"):
        ref = ys.max() if anchor == "bottom" else ys.min()
        span = max(1, ys.max() - ys.min())
        for y, x in zip(ys, xs):
            d = abs(ref - y) / span
            nx = x + int(round(k * d))
            if 0 <= nx < S:
                out[y, nx] = img[y, x]
    else:
        ref = xs.max() if anchor == "right" else xs.min()
        span = max(1, xs.max() - xs.min())
        for y, x in zip(ys, xs):
            d = abs(ref - x) / span
            ny = y - int(round(k * d))
            if 0 <= ny < S:
                out[ny, x] = img[y, x]
    return out


def lift(img, m, dy):
    out = np.zeros_like(img)
    ys, xs = np.nonzero(m)
    for y, x in zip(ys, xs):
        if 0 <= y - dy < S:
            out[y - dy, x] = img[y, x]
    return out


def glow_frames(im, m):
    """the lamp's light a shade brighter and a shade dimmer (only its lit pixels, not the face)"""
    lum = im[..., :3].astype(float).mean(2)
    lit = m & (lum > 150)
    out = []
    for f in (1.0, 1.1, 0.9):
        p = np.zeros_like(im)
        p[m] = im[m]
        c = im[lit, :3].astype(float) * f
        p[lit, :3] = np.clip(c, 0, 255).astype(np.uint8)
        out.append(p)
    return out


# ------------------------------------------------------------------ clockwork (the wind-up spirits)
def gold_mask(im):
    r, g, b, a = (im[..., i].astype(int) for i in range(4))
    return (a > 0) & (r > 170) & (g > 125) & (b < 90) & (r > g + 15) & (g > b + 70)


def gold_loose(im):
    r, g, b, a = (im[..., i].astype(int) for i in range(4))
    return (a > 0) & (r > 140) & (r > g + 10) & (g > b + 30) & (r > b + 70)


def with_outline(m, im):
    return m | (ndimage.binary_dilation(m, structure=np.ones((3, 3))) & ~m & dark_mask(im))


def key_part(im):
    """the key's bow: every pixel in its rows and columns down to the outline row under its loops,
    but not the stem; and the stem's centre column"""
    seed = min([m for m in comps(gold_mask(im)) if m.sum() >= 8], key=lambda m: np.nonzero(m)[0].min())
    lab, _ = ndimage.label(gold_loose(im) | seed, structure=np.ones((3, 3)))
    top = np.isin(lab, np.unique(lab[seed]))
    ys, xs = np.nonzero(top)
    widths = {y: xs[ys == y].max() - xs[ys == y].min() + 1 for y in range(ys.min(), ys.max() + 1) if (ys == y).any()}
    stem_w = min(widths[y] for y in widths if y > ys.min() + 3)
    bow_end = next(y for y in sorted(widths) if y > ys.min() + 3 and widths[y] <= stem_w + 1)
    stem = xs[ys == bow_end]
    cx = (stem.min() + stem.max()) / 2
    wide = ys < bow_end
    x0, x1, y0 = xs[wide].min() - 2, xs[wide].max() + 2, ys.min() - 2
    m = np.zeros(im.shape[:2], bool)
    m[max(0, y0):bow_end + 1, max(0, x0):x1 + 1] = im[max(0, y0):bow_end + 1, max(0, x0):x1 + 1, 3] > 0
    m[bow_end, stem.min() - 1:stem.max() + 2] = False      # (the stem goes on through)
    # (not the leaf or tag beside it: only what's joined to the bow)
    lab, _ = ndimage.label(m, structure=np.ones((3, 3)))
    m = np.isin(lab, np.unique(lab[m & top])[np.unique(lab[m & top]) > 0])
    return m, cx


def key_frames(im, m, cx):
    """the bow narrowed about its stem: each row area-averaged into fewer pixels, snapped back to
    the bow's own colours, its ends outlined; the far side a shade darker"""
    ys, xs = np.nonzero(m)
    pal = np.unique(im[m][:, :3], axis=0).astype(float)
    out = []
    for i, (s, dim) in enumerate([(1.0, 1.0), (0.66, 1.0), (0.33, 0.85), (0.66, 0.85)]):
        f = np.zeros_like(im)
        if i == 0:
            f[m] = im[m]
            out.append(f)
            continue
        for y in range(ys.min(), ys.max() + 1):
            row = np.nonzero(m[y])[0]
            if not len(row):
                continue
            span = max(cx - row.min(), row.max() - cx) + 0.5
            for x in range(int(np.floor(cx - span * s)), int(np.ceil(cx + span * s)) + 1):
                a0, a1 = cx + (x - 0.5 - cx) / s, cx + (x + 0.5 - cx) / s
                cov, col, tot = 0.0, np.zeros(3), 0.0
                for sx in range(int(np.floor(a0)), int(np.ceil(a1)) + 1):
                    w = max(0.0, min(a1, sx + 0.5) - max(a0, sx - 0.5))
                    if w <= 0:
                        continue
                    tot += w
                    if 0 <= sx < S and m[y, sx]:
                        cov += w
                        col += w * im[y, sx, :3]
                if tot and cov / tot >= 0.5:
                    c = pal[np.argmin(((pal - col / cov) ** 2).sum(1))] * dim
                    f[y, x, :3] = np.clip(c, 0, 255)
                    f[y, x, 3] = 255
            hit = np.nonzero(f[y, :, 3])[0]
            if len(hit):
                for x in (hit.min(), hit.max()):
                    f[y, x, :3] = OUTLINE
        out.append(f)
    return out


def cog_parts(im):
    seeds = [m for m in comps(gold_mask(im)) if np.nonzero(m)[0].mean() > S * 0.5 and m.sum() >= 8]
    seeds.sort(key=lambda m: -m.sum())
    seeds = sorted(seeds[:2], key=lambda m: np.nonzero(m)[1].mean())
    out = []
    yy, xx = np.mgrid[:S, :S]
    for s in seeds:
        cy, cx = ndimage.center_of_mass(s)
        ys, xs = np.nonzero(s)
        rad = max(np.hypot(ys - cy, xs - cx)) + 0.5
        disk = np.hypot(yy - cy, xx - cx) <= rad + 1.0
        m = with_outline(gold_loose(im) & disk, im) & disk
        ys, xs = np.nonzero(m)
        cy, cx = ys.mean(), xs.mean()
        out.append((m, (cy, cx), max(np.hypot(ys - cy, xs - cx)) + 0.5))
    return out


def cog_frames(im, m, c, rad, steps=3, teeth=8):
    """the cog a third of a tooth on each frame: a supersampled turn of its own pixels"""
    cy, cx = c
    out = []
    for k in range(steps):
        th = np.deg2rad(360 / teeth / steps * k)
        f = np.zeros_like(im)
        if k == 0:
            f[m] = im[m]
            out.append(f)
            continue
        for y in range(int(cy - rad - 1), int(cy + rad + 2)):
            for x in range(int(cx - rad - 1), int(cx + rad + 2)):
                if not (0 <= y < S and 0 <= x < S) or np.hypot(y - cy, x - cx) > rad:
                    continue
                hits = []
                for oy in (-0.33, 0, 0.33):
                    for ox in (-0.33, 0, 0.33):
                        dy, dx = y + oy - cy, x + ox - cx
                        sy = cy + dy * np.cos(th) + dx * np.sin(th)
                        sx = cx - dy * np.sin(th) + dx * np.cos(th)
                        iy, ix = int(round(sy)), int(round(sx))
                        if 0 <= iy < S and 0 <= ix < S and m[iy, ix]:
                            hits.append((iy, ix, oy == 0 and ox == 0))
                if len(hits) >= 5:
                    centre = [hh for hh in hits if hh[2]]
                    iy, ix, _ = centre[0] if centre else hits[0]
                    f[y, x] = im[iy, ix]
        out.append(f)
    return out


# ------------------------------------------------------------------ the body under the parts
def body_without(im, mask_all):
    """the sprite without its parts: air where they stood out of the body, the nearest body colour
    where they lay over it"""
    op = im[..., 3] > 0
    rest = op & ~mask_all
    sil = ndimage.binary_fill_holes(ndimage.binary_closing(rest, structure=np.ones((3, 3)), iterations=1)) | rest
    inside = mask_all & sil
    body = im.copy()
    body[mask_all & ~sil] = 0
    src = rest & ~dark_mask(im)
    if inside.any() and src.any():
        _, (iy, ix) = ndimage.distance_transform_edt(~src, return_indices=True)
        body[inside] = im[iy[inside], ix[inside]]
    # (no outline is redrawn where a part joined: a bent part never leaves its joint, and a pixel
    # of body edge without outline beside it would flicker on and off as it moved)
    return body


# ------------------------------------------------------------------ one spirit
def build(sid):
    spec = SPEC.get(sid, {})
    d = DEST / sid
    faces = {f: np.array(Image.open(d / f"{f}.png").convert("RGBA")) for f in FACES if (d / f"{f}.png").exists()}
    im = faces["base"]
    rig = {"realm": REALM.get(sid, ""), "parts": {}}
    if spec.get("wobbly"):
        rig["wobbly"] = True
    if spec.get("fx"):
        rig["fx"] = spec["fx"]
    masks, frames = {}, {}
    for nm, ps in spec.get("parts", {}).items():
        m = find_part(im, ps)
        if not m.any():
            raise SystemExit(f"{sid}.{nm}: nothing found in its box")
        if ps.get("loose"):
            # every loose bit (a star, a drop, a dot) moves on its own
            for i, c in enumerate(sorted(comps(m), key=lambda c: np.nonzero(c)[1].mean())):
                masks[f"{nm}{i}"] = (c, dict(ps, loose=False))
            continue
        masks[nm] = (m, ps)
    for nm, extra in strays(im, masks).items():
        masks[nm] = (masks[nm][0] | extra, masks[nm][1])
    body0 = im[..., 3] > 0
    for nm, (m, ps) in masks.items():
        img = np.zeros_like(im)
        img[m] = im[m]
        mo = ps["motion"]
        ys, xs = np.nonzero(m)
        entry = {"box": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())]}
        if mo in ("sway", "twitch", "wag", "flap", "swing"):
            anchor = anchor_of(m, ps, body0 & ~m)
            h = (ys.max() - ys.min()) if anchor in ("bottom", "top") else (xs.max() - xs.min())
            amp = ps.get("amp", 2 if h >= 12 else 1)
            poses = [bend(img, m, anchor, k) for k in range(-amp, amp + 1)]
            side = "l" if xs.mean() < S / 2 else "r"
            entry.update(kind="bend", style=mo, anchor=anchor, amp=amp, side=side, frames=len(poses))
            frames[nm] = poses
        elif mo == "beat":
            frames[nm] = [img, lift(img, m, 1), lift(img, m, 2)]
            entry.update(kind="bend", style="beat", amp=0, side="l" if xs.mean() < S / 2 else "r", frames=3)
        elif mo == "flame":
            entry.update(kind="flame", embers=True)
        elif mo == "strike":
            entry.update(kind="bolt", nohide=True)
        elif mo == "glow":
            frames[nm] = glow_frames(im, m)
            entry.update(kind="glow", frames=3)
        elif mo in ("drift", "fall", "rise", "twinkle", "lag"):
            entry.update(kind=mo)
            for key in ("axis", "side", "style"):
                if key in ps:
                    entry[key] = ps[key]
            if mo == "fall":
                entry["floor"] = int(np.nonzero(body0.any(1))[0].max())
        entry["pivot"] = [int(round(xs.mean())), int(ys.max())]
        rig["parts"][nm] = entry
        Image.fromarray(img).save(d / f"part_{nm}.png")
        for i, f in enumerate(frames.get(nm, [])):
            Image.fromarray(f).save(d / f"part_{nm}_{i}.png")
    if spec.get("clockwork"):
        km, kcx = key_part(im)
        masks["key"] = (km, {})
        cyc = {"key": key_frames(im, km, kcx)}
        for side, (m, c, rad) in zip(("cog_l", "cog_r"), cog_parts(im)):
            masks[side] = (m, {})
            cyc[side] = cog_frames(im, m, c, rad)
        for nm, fr in cyc.items():
            m = masks[nm][0]
            ys, xs = np.nonzero(m)
            img = np.zeros_like(im)
            img[m] = im[m]
            Image.fromarray(img).save(d / f"part_{nm}.png")
            for i, f in enumerate(fr):
                Image.fromarray(f).save(d / f"part_{nm}_{i}.png")
            rig["parts"][nm] = {"kind": "cycle", "frames": len(fr), "rate": 3 if nm == "key" else 2,
                                "box": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
                                "pivot": [int(round(xs.mean())), int(ys.max())]}
            frames[nm] = fr
    if masks:
        mask_all = np.any([m for m, _ in masks.values()], 0)
        body = body_without(im, mask_all)
        # the cogs turn over their own spot: under them, the body colour round them
        for side in ("cog_l", "cog_r"):
            if side in masks:
                m = masks[side][0]
                src = (body[..., 3] > 0) & ~ndimage.binary_dilation(m, iterations=2) & ~dark_mask(body) & ~gold_loose(body)
                _, (iy, ix) = ndimage.distance_transform_edt(~src, return_indices=True)
                body[m] = body[iy[m], ix[m]]
        rest = body.copy()
        rest[mask_all] = im[mask_all]
        assert (rest == im).all(), f"{sid}: body + parts at rest isn't the sprite"
        for f, fi in faces.items():
            fb = fi.copy()
            same = mask_all & (fi == im).all(2)          # (a face's own change wins)
            fb[same] = body[same]
            Image.fromarray(fb).save(d / f"{f}_body.png")
    return rig, masks, frames


def check_sheet(realm, done):
    """each spirit: the sprite, its parts tinted, and its two furthest poses"""
    k = 4
    rows = [(sid, r) for sid, r in done if r[0].get("realm") == realm and r[1]]
    W = 56 * k
    sh = Image.new("RGBA", (4 * (W + 6) + 6, max(1, len(rows)) * (W + 18) + 6), (40, 36, 46, 255))
    dd = ImageDraw.Draw(sh)
    for i, (sid, (rig, masks, frames)) in enumerate(rows):
        base = np.array(Image.open(DEST / sid / "base.png").convert("RGBA"))
        body = np.array(Image.open(DEST / sid / "base_body.png").convert("RGBA"))
        tint = base.copy()
        for m, _ in masks.values():
            tint[m, :3] = (tint[m, :3].astype(int) // 2 + np.array([0, 110, 120])).clip(0, 255).astype(np.uint8)
        a, b = body.copy(), body.copy()
        for nm, fr in frames.items():
            for img, j in ((a, 0), (b, len(fr) - 1)):
                on = fr[j][..., 3] > 0
                img[on] = fr[j][on]
        for nm in rig["parts"]:
            if nm not in frames:
                p = np.array(Image.open(DEST / sid / f"part_{nm}.png").convert("RGBA"))
                on = p[..., 3] > 0
                a[on] = p[on]
                b[on] = p[on]
        y = 6 + i * (W + 18)
        dd.text((6, y), f"{sid}: {', '.join(rig['parts'])}", fill=(255, 220, 160))
        for j, t in enumerate((base, tint, a, b)):
            tile = Image.new("RGBA", (56, 56), (74, 44, 34, 255))
            tile.alpha_composite(Image.fromarray(t))
            sh.alpha_composite(tile.resize((W, W), Image.NEAREST), (6 + j * (W + 6), y + 14))
    sh.save(DEST / f"parts_check_{realm}.png")


def main(only):
    man = json.loads((SP / "anim_prep/manifest.json").read_text())
    for s in man["sheets"]:
        for e in s["spirits"]:
            REALM[e["id"]] = e["realm"]
    rigs_path = DEST / "rig.json"
    rigs = json.loads(rigs_path.read_text())
    done = []
    for sid in (only or list(REALM)):
        for f in (DEST / sid).glob("part_*.png"):          # (a fresh start for this spirit's parts)
            f.unlink()
        for f in (DEST / sid).glob("*_body.png"):
            f.unlink()
        rig, masks, frames = build(sid)
        rigs[sid] = rig
        done.append((sid, (rig, masks, frames)))
        if rig["parts"] or rig.get("fx") or rig.get("wobbly"):
            print(sid, {k: (v["kind"] + ("/" + v.get("style", "") if v.get("style") else "")) for k, v in rig["parts"].items()},
                  "wobbly" if rig.get("wobbly") else "", [f["type"] for f in rig.get("fx", [])])
    # (the pilot's candle gets embers too, like every flame now)
    if "flame" in rigs.get("nacho", {}).get("parts", {}):
        rigs["nacho"]["parts"]["flame"]["embers"] = True
    rigs_path.write_text(json.dumps(rigs, indent=1))
    for realm in ("mountain", "moon", "fox", "fire", "river"):
        check_sheet(realm, done)


if __name__ == "__main__":
    main(sys.argv[1:])
