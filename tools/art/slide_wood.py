"""The menu slide in wood, three tones (the user, 2026-11-04: the designer's one-piece wood study
docs/mockups/menu_frames/v3/brainstorm/wood_a.png, "in clear, mid brown and browner"; the slide in the
game must be EXACTLY the one in its preview, docs/mockups/menu_frames/v3/brainstorm/in_app/):

  - each tone its own study (its own colours and grain, the user: "also the pattern"): clear = wood_b,
    mid = wood_a, brown = the designer's brown study (STUDIES) when it comes. Each cleaned
    (tools/art/slide_clean.py, the user's pick: the edges in 8 px steps, half-toned) and shown at full
    detail at its size on the phone (tools/art/slide_preview.py's hd: 883 x 908, 1:1)
  - until the brown comes: wood_a's pixels with only the wood recoloured (saturation and value scaled,
    the dark outline and lines kept: LINE_L), a stand-in

Writes docs/mockups/menu_frames/v3/wood_tones/slide_<tone>.png (883 x 908, the slide on the phone),
all_3x.png and in_app.png (the Games, Food and Decor menus with mid, clear, brown: in today's tints'
place, diapositive2 / 1 / 3). Nothing goes into textures/.

Run: .venv/bin/python tools/art/slide_wood.py [--clear <study>] [--mid <study>] [--brown <study>] [--out <dir>]
(any tone's study swapped, e.g. the v4 set: docs/mockups/menu_frames/v4/wood_*.png)
"""
import argparse
import colorsys
import os
import sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from slide_preview import hd, in_app_sheet     # noqa: E402
import slide_clean                             # noqa: E402

B = "docs/mockups/menu_frames/v3/brainstorm/"
STUDIES = {"clear": B + "wood_b.png", "mid": B + "wood_a.png", "brown": B + "wood_brown.png"}
OUT = "docs/mockups/menu_frames/v3/wood_tones/"
LINE_L = 50                                  # (darker than this: the outline and lines, kept)
STAND_IN = {"brown": (1.08, 0.72, -3)}     # (no study yet: wood_a recoloured; saturation x, value x, hue shift)
TONES = ["clear", "mid", "brown"]
MENU_TONES = ["mid", "clear", "brown"]       # (games, food, decor)
# (the brown study's board calmed to the others' detail, the user: "still too detailed ... resemble the
#  other ones": its glossy patches flattened (GLOSS of their size kept), its grain's contrast (GRAIN
#  kept) and its saturation (SAT) lowered; the moulding and edges as cleaned. Its own grain pattern stays)
CALM = {B + "wood_brown.png": dict(gloss=0.4, grain=0.55, sat=0.8, blur=40, feather=12, simplify=9)}

ap = argparse.ArgumentParser()
for t in TONES:
    ap.add_argument("--" + t)
ap.add_argument("--out")
ap.add_argument("--line-dark", type=float, help="every slide's outline its own wood x this (0.4: a dark wood)")
ap.add_argument("--brown-v", type=float, help="the brown made paler: its wood's brightness (HSV value) to this, all of it scaled alike")
ap.add_argument("--brown-lines", type=float, help="the brown's dark grain lines brought this far back to its board colour (0.5: half as dark)")
ap.add_argument("--brown-grain", type=float, help="the brown's grain contrast scaled (calm(): 0.6 = softer)")
ap.add_argument("--lines-from", help="the swapped tones' outline and window line from this study (as the others')")
args = ap.parse_args()
SWAPPED = {t for t in TONES if getattr(args, t)}
for t in TONES:
    if getattr(args, t):
        STUDIES[t] = getattr(args, t)
if args.brown_grain:
    CALM[STUDIES["brown"]] = dict(gloss=1, grain=args.brown_grain, sat=1, blur=40, feather=12)
if args.out:
    OUT = args.out.rstrip("/") + "/"
os.makedirs(OUT, exist_ok=True)
slides = {}
CLEAN = OUT + "clean/"
os.makedirs(CLEAN, exist_ok=True)


def calm(im, gloss, grain, sat, blur, feather, simplify=0):
    """A study's board (away from the moulding and the edges) less detailed: its fine lines off first
    (a simplify x simplify median: only the main grain strokes stay, as the other woods'), then its
    gloss, grain contrast and saturation lowered."""
    from scipy import ndimage
    a = np.array(im).astype(float)
    if simplify:
        a[..., :3] = np.stack([ndimage.median_filter(a[..., c], simplify) for c in range(3)], -1)
    h, w = a.shape[:2]
    d_in, _ = slide_clean.rounded(h, w, slide_clean.OPEN, slide_clean.R_IN)
    d_out, _ = slide_clean.rounded(h, w, slide_clean.OUTER, slide_clean.R_OUT)
    board = (d_in > slide_clean.ZONE + 6) & (-d_out > slide_clean.OZ + 6)
    wgt = ndimage.gaussian_filter(board.astype(float), feather)[..., None] * board[..., None]
    rgb = a[..., :3]
    big = np.stack([ndimage.gaussian_filter(rgb[..., c], blur) for c in range(3)], -1)
    mid = np.median(rgb[board], 0)
    new = mid + gloss * (big - mid) + grain * (rgb - big)
    lum = (new @ [0.299, 0.587, 0.114])[..., None]
    new = lum + sat * (new - lum)
    a[..., :3] = rgb * (1 - wgt) + np.clip(new, 0, 255) * wgt
    return Image.fromarray(np.round(a).astype(np.uint8))


def lighter_lines(im, k):
    """The board's grain lines (darker than its median colour) brought back towards it: each dark
    pixel's difference from the board's colour times k (its hue and the light grain kept)."""
    from scipy import ndimage
    a = np.array(im).astype(float)
    h, w = a.shape[:2]
    d_in, _ = slide_clean.rounded(h, w, slide_clean.OPEN, slide_clean.R_IN)
    d_out, _ = slide_clean.rounded(h, w, slide_clean.OUTER, slide_clean.R_OUT)
    board = (d_in > slide_clean.ZONE + 2) & (-d_out > slide_clean.OZ + 2) & (a[..., 3] > 0)
    rgb = a[..., :3]
    m = np.median(rgb[board], 0)
    lum = rgb @ [0.299, 0.587, 0.114]
    dark = board & (lum < m @ [0.299, 0.587, 0.114])
    wgt = ndimage.gaussian_filter(board.astype(float), 3)[..., None]   # (softly at the bands' edges)
    soft = m + (rgb - m) * k
    rgb[dark] = (rgb * (1 - wgt) + soft * wgt)[dark]
    return Image.fromarray(np.round(a).astype(np.uint8))


def paler(im, v_to):
    """The whole slide's brightness scaled so its wood's median reaches v_to (hue and saturation kept;
    the outline, moulding and grain scaled alike, so their contrast stays)."""
    a = np.array(im).astype(float)
    op = a[..., 3] > 200
    v = a[..., :3].max(2) / 255
    k = v_to / np.median(v[op])
    a[..., :3] = np.clip(a[..., :3] * k, 0, 255)
    return Image.fromarray(np.round(a).astype(np.uint8))


def made(path, tone):
    """The study cleaned (the chosen edges), calmed if its tone asks, at its size on the phone."""
    opts = dict(slide_clean.CHOSEN)
    # the studies' own grain round the board's corners, whole (the user, 2026-11-04: "the curves were
    # there just more clear"): no blur there, no wipe (both erased it)
    opts.update(corner_soft=0, smudge=slide_clean.ZONE, osmudge=0)
    if args.lines_from and tone in SWAPPED:
        opts["lines_from"] = args.lines_from
    if args.line_dark:
        opts["line_dark"] = args.line_dark
    im, _ = slide_clean.clean(path, **opts)
    if path in CALM:                       # (only the study it was tuned for)
        im = calm(im, **CALM[path])
    if tone == "brown" and args.brown_lines:   # (the user: its lines "too dark ... a zebra": the
        im = lighter_lines(im, args.brown_lines) #  board's own brown, slightly darker, as the others')
    if tone == "brown" and args.brown_v:  # (the user: "too intense, could be paler like the natural
        im = paler(im, args.brown_v)       #  progression from first and second")
    p = CLEAN + tone + ".png"
    im.save(p)
    return hd(p)


for tone in TONES:
    if os.path.exists(STUDIES[tone]):
        slides[tone] = made(STUDIES[tone], tone)
        slides[tone].save(OUT + "slide_%s.png" % tone)
        print(tone, "<-", STUDIES[tone])
        continue
    im = np.array(slides["mid"]).astype(float)
    if True:
        sk, vk, dh = STAND_IN[tone]
        op = im[..., 3] > 0
        lum = im[..., :3] @ [0.299, 0.587, 0.114]
        for y, x in zip(*np.where(op & (lum >= LINE_L))):
            h, s, v = colorsys.rgb_to_hsv(*(im[y, x, :3] / 255))
            im[y, x, :3] = np.array(colorsys.hsv_to_rgb((h + dh / 360) % 1, min(s * sk, 1), min(v * vk, 1))) * 255
    slides[tone] = Image.fromarray(np.round(im).astype(np.uint8))
    slides[tone].save(OUT + "slide_%s.png" % tone)
    print(tone, "<- stand-in (wood_a recoloured)")

W, H = slides["mid"].size
S = 1
sheet = Image.new("RGBA", (W * S * 3 + 60, H * S), (40, 36, 44, 255))
for i, tone in enumerate(TONES):
    sheet.alpha_composite(slides[tone].resize((W * S, H * S), Image.NEAREST), (i * (W * S + 30), 0))
sheet.save(OUT + "all_3x.png")
in_app_sheet([slides[t] for t in MENU_TONES]).save(OUT + "in_app.png")
print("ok")
