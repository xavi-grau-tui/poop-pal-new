"""Menu slide previews exactly as the app will show them (the user, 2026-11-04): a slide study (any size,
the slide's proportions) fitted to the exact slide template on the game's pixel grid, then put in the
real menus at their in-app size and place.

  1. the fit: the study mapped piecewise (its outer edge to the template's mount, its window to the
     template's opening), so its window lands exactly on the template's; each art pixel (4 x 4 file px)
     its study block's commonest colour (its line colour where the block is mostly line); the template's
     outer shape and transparent opening applied (docs/mockups/menu_frames/v2_brief/mask_*.png)
  2. the menus: docs/mockups/menu_frames/current_{games,food,decor}_menu.png, the slide where the app
     draws it (2.19 x 2.30, nearest), the window and whatever sits on the slide (legend, dots, arrow)
     kept

Writes <out>/<name>_slide.png (402 x 394, as textures/menus/diapositive*.png) and
<out>/<name>_in_app.png (the three menus side by side, 1:1 with the phone's screen). With --hd: the
study itself at the slide's on-screen size (883 x 908, all its detail; hd()), <name>_slide_hd.png and
<name>_in_app_hd.png.

A preview only: it writes nothing into textures/. Lines thinner than one art pixel in the study come out
broken: draw them at least 1 art pixel (16 px on a 1608 x 1576 study) wide.

Run: .venv/bin/python tools/art/slide_preview.py <study.png> [<study.png> ...] --out <folder>
"""
import argparse
import os
import numpy as np
from PIL import Image
from scipy import ndimage

B = "docs/mockups/menu_frames/"
OUTER = np.array(Image.open(B + "v2_brief/mask_outer.png")) > 0
OPENING = np.array(Image.open(B + "v2_brief/mask_opening.png")) > 0
RING = np.array(Image.open("textures/menus/diapositive1_ring.png").convert("RGBA"))[..., 3] > 0
TX, TY = [11, 51, 352, 392], [5, 43, 322, 390]       # (the template: the mount's edges, the opening's)
H, W = OUTER.shape
LINE_L, LINE_SHARE, BIN = 70, 0.4, 12
PLACE, SCALE = (113, 648), (2.1916, 2.2987)          # (where the app draws the slide, measured on the screenshots)
BAND_Y = 330                                         # (the slide's bottom band, file px: the legend, dots and arrow)
CORNER_SQ = 48                                       # (screen px: the window's corners rebuilt this far in)
EDGE_IN = 40                                         # (screen px: they sit at least this far inside the slide's edge)
MENUS = [("current_games_menu.png", 2), ("current_food_menu.png", 1), ("current_decor_menu.png", 3)]


def study_frame(s):
    """The study's mount edges and its window's (the biggest dark or empty area inside it)."""
    op = s[..., 3] > 128
    ys, xs = np.where(op)
    lum = s[..., :3] @ [0.299, 0.587, 0.114]
    hole = (ndimage.binary_fill_holes(op) & ~op) | (op & (lum < 60))
    lab, n = ndimage.label(hole)
    big = np.argmax(ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))) + 1
    wy, wx = np.where(lab == big)
    return [xs.min(), wx.min(), wx.max() + 1, xs.max() + 1], [ys.min(), wy.min(), wy.max() + 1, ys.max() + 1]


def fit(path):
    s = np.array(Image.open(path).convert("RGBA")).astype(int)
    sx, sy = study_frame(s)
    res = np.zeros((H, W, 4), int)
    for cy0 in range(1, H, 4):
        for cx0 in range(-1, W, 4):
            ys, xs = slice(max(cy0, 0), min(cy0 + 4, H)), slice(max(cx0, 0), min(cx0 + 4, W))
            if not (OUTER[ys, xs] & ~OPENING[ys, xs]).any():
                continue
            a, b = np.interp([xs.start, xs.stop], TX, sx)
            c, d = np.interp([ys.start, ys.stop], TY, sy)
            blk = s[int(c):max(int(d), int(c) + 1), int(a):max(int(b), int(a) + 1)].reshape(-1, 4)
            op = blk[blk[:, 3] > 128]
            if not len(op):
                continue
            lum = op[:, :3] @ [0.299, 0.587, 0.114]
            if (lum < LINE_L).mean() >= LINE_SHARE:
                col = np.median(op[lum < LINE_L][:, :3], 0)
            else:
                q = op[:, :3] // BIN
                k = q[:, 0] * 10000 + q[:, 1] * 100 + q[:, 2]
                u, n = np.unique(k, return_counts=True)
                col = op[k == u[n.argmax()]][:, :3].mean(0)
            res[ys, xs, :3] = col
            res[ys, xs, 3] = 255
    need = OUTER & ~OPENING
    gap = need & (res[..., 3] == 0)
    if gap.any():
        iy, ix = ndimage.distance_transform_edt(res[..., 3] == 0, return_distances=False, return_indices=True)
        res[gap] = res[iy[gap], ix[gap]]
    res[..., 3] = need * 255
    res[~need] = 0
    return Image.fromarray(res.astype(np.uint8))


def hd(path):
    """The study itself at the slide's size on the phone's screen (883 x 908 of 1080 x 1920, the
    sprite's scale), smoothly scaled: all its detail, shown 1:1 (the user, 2026-11-04: the game's
    slide must look like the study, not like it on the coarse grid)."""
    s = Image.open(path).convert("RGBA")
    w, h = round(W * SCALE[0]), round(H * SCALE[1])
    a = np.array(s).astype(float)
    a[..., :3] *= a[..., 3:4] / 255                      # (premultiplied: no dark fringe at the edges)
    r = np.array(Image.fromarray(np.round(a).astype(np.uint8)).resize((w, h), Image.LANCZOS)).astype(float)
    al = r[..., 3:4]
    r[..., :3] = np.where(al > 0, r[..., :3] * 255 / np.maximum(al, 1), 0)
    return Image.fromarray(np.clip(np.round(r), 0, 255).astype(np.uint8))


def _period(strip, axis, lo=4, hi=90):
    """The pattern's repeat along an axis of a strip (px): the shortest shift it matches itself at."""
    n = strip.shape[axis]
    errs = []
    for d in range(lo, min(hi, n // 2)):
        a = np.take(strip, range(0, n - d), axis=axis)
        b = np.take(strip, range(d, n), axis=axis)
        errs.append(np.abs(a - b).mean())
    errs = np.array(errs)
    return lo + int(np.argmax(errs <= errs.min() * 1.05 + 0.5))


def fill_corners(reg, inside, slide_px):
    """The window's insides (inside: today's window within its ring) carried on to wherever the new
    slide leaves the window open: each missing pixel copied from along the nearer side, by whole
    repeats of that side's pattern (so stripes, the grid, the panel's edge run on into the corner)."""
    out = reg.copy()
    filled = ndimage.binary_fill_holes(slide_px)
    win = filled & ~slide_px
    ys, xs = np.where(inside)
    y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
    # (each corner's last CORNER_SQ px rebuilt from the straight sides beside it, whatever today's menu
    #  has there: its own round rims, e.g. the Food grid's, go too)
    wy, wx = np.where(win)
    yy, xx = np.mgrid[0:reg.shape[0], 0:reg.shape[1]]
    near_x = (xx < wx.min() + CORNER_SQ) | (xx > wx.max() - CORNER_SQ)
    near_y = (yy < wy.min() + CORNER_SQ) | (yy > wy.max() - CORNER_SQ)
    inside = inside & ~(near_x & near_y)
    gap = win & ~inside
    if not gap.any():
        return out
    band = 40                                      # (the sides' strips the repeats are measured on)
    mx, my = slice(x0 + (x1 - x0) // 4, x1 - (x1 - x0) // 4), slice(y0 + (y1 - y0) // 4, y1 - (y1 - y0) // 4)
    f = reg[..., :3].astype(float)
    per = {"top": _period(f[y0:y0 + band, mx], 1), "bottom": _period(f[y1 - band:y1, mx], 1),
           "left": _period(f[my, x0:x0 + band], 0), "right": _period(f[my, x1 - band:x1], 0)}
    across = {"top": _period(f[y0:y0 + 3 * band, mx], 0), "bottom": _period(f[y1 - 3 * band:y1, mx], 0),
              "left": _period(f[my, x0:x0 + 3 * band], 1), "right": _period(f[my, x1 - 3 * band:x1], 1)}
    cy, cx = (y0 + y1) / 2, (x0 + x1) / 2
    for y, x in zip(*np.where(gap)):
        dy = (y - y0) if y < cy else (y1 - y)       # (how far in from the top or bottom, the left or right)
        dx = (x - x0) if x < cx else (x1 - x)
        tb, lr = ("top" if y < cy else "bottom"), ("left" if x < cx else "right")
        sy_in, sx_in = (1 if y < cy else -1), (1 if x < cx else -1)
        along_tb = [(0, per[tb] * sx_in * k) for k in range(1, 40)]
        along_lr = [(per[lr] * sy_in * k, 0) for k in range(1, 40)]
        # (then, where the side itself is missing there: from further in, by its repeat across)
        in_tb = [(across[tb] * sy_in * k, 0) for k in range(1, 12)]
        in_lr = [(0, across[lr] * sx_in * k) for k in range(1, 12)]
        steps = along_tb + along_lr + in_tb + in_lr if dy <= dx else along_lr + along_tb + in_lr + in_tb
        for sy, sx in steps:
            yy, xx = y + sy, x + sx
            if 0 <= yy < reg.shape[0] and 0 <= xx < reg.shape[1] and inside[yy, xx]:
                out[y, x] = reg[yy, xx]
                break
    return out


def in_menu(slide, shot_name, tint):
    shot = np.array(Image.open(B + shot_name).convert("RGBA")).astype(int)
    w, h = round(W * SCALE[0]), round(H * SCALE[1])
    x0, y0 = PLACE
    old = np.array(Image.open("textures/menus/diapositive%d.png" % tint).convert("RGBA").resize((w, h), Image.NEAREST)).astype(int)
    ring = np.array(Image.fromarray(RING).resize((w, h), Image.NEAREST))
    window = ndimage.binary_fill_holes(ring)
    reg = shot[y0:y0 + h, x0:x0 + w]
    over = (np.abs(reg[..., :3] - old[..., :3]).sum(2) > 30) & (old[..., 3] > 0) & ~window
    over = ndimage.binary_dilation(over, iterations=1) & (old[..., 3] > 0) & ~window
    over[:round(BAND_Y * SCALE[1])] = False        # (only the bottom band has things on it: the legend, dots, arrow,
    over &= ndimage.distance_transform_edt(old[..., 3] > 0) > EDGE_IN   # (all well inside the slide's edge)
    new = np.array(slide if slide.size == (w, h) else slide.resize((w, h), Image.NEAREST)).astype(float)
    # today's slide off first (as the game will swap it): its mount as the screen behind it (the nearest
    # pixel outside it), so no sliver of its outline shows round a new edge that sits inside it
    keep = reg.copy()
    gone = (old[..., 3] > 0) & ~window
    iy, ix = ndimage.distance_transform_edt(gone, return_distances=False, return_indices=True)
    reg[gone] = reg[iy[gone], ix[gone]]
    # the window's insides out to the new window's stepped corners (the user, 2026-11-04: "fill in the
    # inner part of the diapositive in the corner with the inner current texture"): today's round
    # window ring off, and what is inside it (the window's wood, the grid, the panel) carried on into
    # each corner, along the side it is nearer, by whole repeats of its pattern (fill_corners)
    reg[:] = fill_corners(reg, window & ~ndimage.binary_dilation(ring, iterations=6), new[..., 3] > 128)
    al = new[..., 3:4] / 255                       # (blended: a smooth slide's soft edge)
    reg[..., :3] = np.round(new[..., :3] * al + reg[..., :3] * (1 - al)).astype(int)
    reg[over] = keep[over]                         # (the legend, the dots, the arrow on top again)
    shot[y0:y0 + h, x0:x0 + w] = reg
    return Image.fromarray(shot.astype(np.uint8))


def in_app_sheet(slides):
    """The menus side by side, each with its slide (one for all, or one per menu: games, food, decor)."""
    if not isinstance(slides, (list, tuple)):
        slides = [slides] * len(MENUS)
    shots = [in_menu(sl, n, t) for sl, (n, t) in zip(slides, MENUS)]
    sheet = Image.new("RGBA", (1080 * len(shots) + 40 * (len(shots) - 1), 1920), (30, 28, 34, 255))
    for i, im in enumerate(shots):
        sheet.alpha_composite(im, (i * 1120, 0))
    return sheet


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("studies", nargs="+")
    ap.add_argument("--out", required=True)
    ap.add_argument("--hd", action="store_true", help="the study at full detail (see hd()), not on the grid")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    for path in args.studies:
        name = os.path.splitext(os.path.basename(path))[0]
        slide = hd(path) if args.hd else fit(path)
        tag = "_hd" if args.hd else ""
        slide.save(os.path.join(args.out, name + "_slide%s.png" % tag))
        in_app_sheet(slide).save(os.path.join(args.out, name + "_in_app%s.png" % tag))
        print(name)
