"""A slide study cleaned for the game (the user, 2026-11-04: "eliminate the thin lines and the ugly
corners from the inner side ... we need consistency"; then: the corners less pixelated, as the
designer's preview, and the window's corners round, not cut straight). Our own pixel edit on the
designer's study:

  - both edges smooth rounded rectangles, antialiased: the slide's outline (OUTER, R_OUT: the
    template's mount x 4) and the window (OPEN, R_IN: the template's opening x 4). The study had been
    cut with the template's stepped masks, in 16 px steps, which left jagged corners
  - the bands along them rebuilt from the study's own colours: the moulding round the window (ZONE px
    out) and the outline and lip round the slide (OZ px in). Each ring has the study's median colour for
    its distance from the edge on each side (taken from the sides' middles), blended round each corner
    by its angle, so the lines run even all round and the corners match the sides
  - by the window's corners, beyond the moulding, the study's old corner shading off (SMUDGE)
  - elsewhere, thin dark scratches (a pixel much darker than its neighbourhood's median: SCRATCH) as
    that median

Writes docs/mockups/menu_frames/v3/brainstorm/clean/<name>.png. Then tools/art/slide_preview.py --hd.

With --step=G (pixel art, the shrines' look; the user: "no completely round corners"): both edges'
corners as stepped arcs, G px a step (16 = one hokora pixel on the phone, 8 = half), anchored at each
corner; the rings round them square-wise, so they keep the steps at one width; each step lit by its
side (its flat part as the top or bottom, its upright part as the side); the edges hard. Writes to
clean_step<G>/.

Run: .venv/bin/python tools/art/slide_clean.py [--step=16] docs/mockups/menu_frames/v3/brainstorm/wood_a.png [...]
"""
import os
import sys
import colorsys
import numpy as np
from PIL import Image
from scipy import ndimage

OUTER, R_OUT = (44, 20, 1568, 1560), 136   # (the template's mount x 4, its corners' radius)
OPEN, R_IN = (204, 172, 1408, 1288), 72    # (the template's opening x 4, its corners' radius)
ZONE = 52                              # (the moulding: this far out from the window)
OZ = 34                                # (the outline and lip: this far in from the slide's edge)
SMUDGE = 110, 14                       # (by the window's corners, this far out, darker than the board by this)
OSMUDGE = 40, 14                       # (inside the slide's round corners, beyond OZ: the same)
SCRATCH, SCRATCH_K = 32, 7             # (darker than its k x k median by this: a scratch)
MID = 0.15                             # (the sides' middles: this far in from each end, for the profiles)
AA = False                             # (--aa: the steps half-toned, as pixel art smooths a curve)
CHOSEN = dict(step=8, aa=True)         # (the user's pick, 2026-11-04: 8 px steps, half-toned)
LINE_NEAR, LINE_TOL = 18, 30
WIN_HALF = False                       # (the window cut's half-toned steps: off, see clean())
LINE_EVEN = True                       # (the outline's and window line's width measured straight out: even round the steps)
FADE = 10                              # (the grain fades into the rebuilt bands over this many px)
CORNER_SOFT, CORNER_REACH = 6, 90      # (the board's corners: detail blurred this much, this far out)           # (an edge's dark line: within this of it, this close to its darkest)
OUT = "docs/mockups/menu_frames/v3/brainstorm/clean/"
LUM = np.array([0.299, 0.587, 0.114])


def rounded(h, w, box, r):
    """A rounded rectangle: each pixel's signed distance (> 0 outside), and the outward direction of
    its nearest edge as an angle (0 = up, 90 = right, 180 = down, 270 = left)."""
    x0, y0, x1, y1 = box
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    hx, hy = (x1 - x0) / 2 - r, (y1 - y0) / 2 - r
    px, py = xx + 0.5 - cx, yy + 0.5 - cy
    qx, qy = np.abs(px) - hx, np.abs(py) - hy
    sdf = np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r
    nx = np.where(qx > 0, qx, 0) * np.sign(px)
    ny = np.where(qy > 0, qy, 0) * np.sign(py)
    flat = (qx <= 0) & (qy <= 0)                   # (inside the straight part: the nearer side)
    nx = np.where(flat & (qx > qy), np.sign(px), nx)
    ny = np.where(flat & (qy >= qx), np.sign(py), ny)
    ang = (np.degrees(np.arctan2(nx, -ny)) + 360) % 360
    return sdf, ang


def stepped(h, w, box, r, g):
    """A rounded rectangle drawn as pixel art: its corners' arcs in steps of g px (anchored at each
    corner, so all four match). Returns: inside (bool), each pixel's distance from its edge counted in
    whole pixels square-wise (chessboard: so the rings round it keep the steps, all one width), and the
    side it faces (0 up, 90 right, 180 down, 270 left: a step's flat part lit as the top or bottom, its
    upright part as the side, as hand-drawn)."""
    x0, y0, x1, y1 = box
    yy, xx = np.mgrid[0:h, 0:w]
    relx = np.where(xx < (x0 + x1) / 2, xx - x0, (x1 - 1) - xx)
    rely = np.where(yy < (y0 + y1) / 2, yy - y0, (y1 - 1) - yy)
    inbox = (relx >= 0) & (rely >= 0)
    qx, qy = (np.floor(relx / g) + 0.5) * g, (np.floor(rely / g) + 0.5) * g
    cut = (relx < r) & (rely < r) & (np.hypot(r - qx, r - qy) > r)
    inside = inbox & ~cut
    return inside


def coverage(h, w, box, r, g, n=4):
    """How much of each step (a g x g block anchored at its corner) the smooth rounded corner covers,
    0 to 1 (n x n samples a block); 1 on the straight parts and inside."""
    x0, y0, x1, y1 = box
    yy, xx = np.mgrid[0:h, 0:w]
    relx = np.where(xx < (x0 + x1) / 2, xx - x0, (x1 - 1) - xx)
    rely = np.where(yy < (y0 + y1) / 2, yy - y0, (y1 - 1) - yy)
    inbox = (relx >= 0) & (rely >= 0)
    bx, by = np.floor(relx / g) * g, np.floor(rely / g) * g
    cov = np.zeros((h, w))
    for i in range(n):
        for j in range(n):
            sx, sy = bx + (i + 0.5) * g / n, by + (j + 0.5) * g / n
            out = (sx < r) & (sy < r) & (np.hypot(r - sx, r - sy) > r)
            cov += ~out
    cov /= n * n
    return np.where(inbox, cov, 0.0)


def edge_fields(inside, outward):
    """For the pixels on one side of a shape's edge (outward: outside it, else inside it): their
    square-wise distance from the edge and the side they face."""
    h, w = inside.shape
    region = ~inside if outward else inside
    other = ~region
    up = np.zeros_like(inside); up[1:] = other[:-1]
    dn = np.zeros_like(inside); dn[:-1] = other[1:]
    lf = np.zeros_like(inside); lf[:, 1:] = other[:, :-1]
    rt = np.zeros_like(inside); rt[:, :-1] = other[:, 1:]
    hset = region & (up | dn)                      # (next to the edge across a flat part)
    vset = region & (lf | rt)                      # (... across an upright part)
    dh = ndimage.distance_transform_cdt(~hset, metric="chessboard").astype(float)
    dv = ndimage.distance_transform_cdt(~vset, metric="chessboard").astype(float)
    dist = np.minimum(dh, dv)
    yy, xx = np.mgrid[0:h, 0:w]
    ys, xs = np.where(inside)
    cy, cx = ys.mean(), xs.mean()
    if outward:
        horiz = np.where(yy < cy, 0.0, 180.0)
        vert = np.where(xx < cx, 270.0, 90.0)
    else:
        horiz = np.where(yy < cy, 0.0, 180.0)
        vert = np.where(xx < cx, 270.0, 90.0)
    ang = np.where(dh <= dv, horiz, vert)
    dist[~region] = -1
    return dist, ang


def side_profiles(s, op, dist, ang, ks, straight):
    """Each side's median colour at each whole pixel of distance (from its middle only)."""
    prof = {}
    dk = np.round(dist).astype(int)
    for side, a in enumerate((0, 90, 180, 270)):
        on = op & straight & (np.abs(((ang - a + 180) % 360) - 180) < 1)
        for k in ks:
            src = on & (dk == k)
            if src.sum() >= 8:
                prof[side, k] = np.median(s[src][:, :3], 0)
    return prof


def paint(out, s, region, dist, ang, prof, ks, only_darker=None):
    """Each pixel of the region its ring's colour: between the two rings either side of its exact
    distance (so curves come out smooth, antialiased), and between the two sides round a corner."""
    ks = list(ks)
    a = ang % 360
    lo = (a // 90).astype(int) % 4                 # (the side before, and the fraction to the next)
    t = (a - lo * 90) / 90
    iy, ix = np.where(region)
    if not len(iy):
        return
    dd = np.clip(dist[iy, ix], ks[0], ks[-1])
    k0 = np.floor(dd).astype(int)
    f = (dd - k0)[:, None]
    k1 = np.minimum(k0 + 1, ks[-1])
    sa, tt = lo[iy, ix], t[iy, ix][:, None]
    sb = (sa + 1) % 4
    table = np.full((4, ks[-1] + 2, 3), np.nan)
    for (sd, k), c in prof.items():
        if k <= ks[-1] + 1:
            table[sd, k] = c
    for sd in range(4):                            # (gaps: the nearest ring's colour)
        for k in range(ks[-1] + 2):
            if np.isnan(table[sd, k, 0]):
                near = [kk for kk in range(ks[-1] + 2) if not np.isnan(table[sd, kk, 0])]
                if near:
                    table[sd, k] = table[sd, min(near, key=lambda kk: abs(kk - k))]
    ca = table[sa, k0] * (1 - f) + table[sa, k1] * f
    cb = table[sb, k0] * (1 - f) + table[sb, k1] * f
    col = ca * (1 - tt) + cb * tt
    ok = ~np.isnan(col[:, 0])
    iy, ix, col = iy[ok], ix[ok], col[ok]
    if only_darker is not None:
        dark = s[iy, ix, :3] @ LUM < col @ LUM - only_darker
        out[iy[dark], ix[dark], :3] = col[dark]
    else:
        out[iy, ix, :3] = col
        out[iy, ix, 3] = 255


def study_lines(path):
    """A study's outline and window-edge line (width, colour), as clean() finds them: to give another
    study the same lines (clean(lines_from=...), the user: the three "the same outline")."""
    s = np.array(Image.open(path).convert("RGBA")).astype(float)
    h, w = s.shape[:2]
    op = s[..., 3] > 0
    d_in, a_in = rounded(h, w, OPEN, R_IN)
    d_out, a_out = rounded(h, w, OUTER, R_OUT)
    yy, xx = np.mgrid[0:h, 0:w]

    def straight_of(box, r):
        x0, y0, x1, y1 = box
        mx = (xx > x0 + r + (x1 - x0) * MID) & (xx < x1 - r - (x1 - x0) * MID)
        my = (yy > y0 + r + (y1 - y0) * MID) & (yy < y1 - r - (y1 - y0) * MID)
        return mx | my
    prof = side_profiles(s, op & (d_in > 0), d_in, a_in, range(0, SMUDGE[0] + 1), straight_of(OPEN, R_IN))
    oprof = side_profiles(s, op & (-d_out > 0), -d_out, a_out, range(0, OZ + OSMUDGE[0] + 1), straight_of(OUTER, R_OUT))
    return line_of(oprof) + line_of(prof)


def line_of(pr):
    """The dark line at an edge: its darkest rings next to it (width, colour)."""
    rings = [(k, np.mean([pr[sd, k] for sd in range(4) if (sd, k) in pr], 0)) for k in range(0, LINE_NEAR + 1)]
    rings = [(k, c) for k, c in rings if not np.isnan(c).any()]
    dark = min(c @ LUM for k, c in rings)
    ks = [k for k, c in rings if c @ LUM < dark + LINE_TOL]
    return max(ks) - min(ks) + 1, np.median([c for k, c in rings if k in ks], 0)


FLOW_N = 96                            # (corner_flow: the band's depth in this many samples)
FLOW_IN = 72                           # (... back to the study's grain over this far into each straight side)
FLOW_AVG = 10                          # (the profiles: the straight sides' first this many px, averaged)


def _dtw(a, b):
    """The monotone pairing of two profiles' samples (dynamic time warping) that lines up their
    lines: a list of (i, j)."""
    n = len(a)
    d = np.abs(a[:, None] - b[None, :])
    acc = np.full((n + 1, n + 1), np.inf); acc[0, 0] = 0
    for i in range(1, n + 1):
        for j in range(1, n + 1):
            acc[i, j] = d[i - 1, j - 1] + min(acc[i - 1, j] + 2, acc[i, j - 1] + 2, acc[i - 1, j - 1])
    i, j, path = n, n, []
    while i > 0 and j > 0:
        path.append((i - 1, j - 1))
        k = np.argmin([acc[i - 1, j - 1], acc[i - 1, j] + 2, acc[i, j - 1] + 2])
        i, j = (i - 1, j - 1) if k == 0 else (i - 1, j) if k == 1 else (i, j - 1)
    return path[::-1]


def corner_flow(out, depth, d_in):
    """The board's four corners rebuilt so the grain bends round them in one piece (the user,
    2026-11-04: "the inconsistencies in the pattern waves in the corners"; one board, no joints): across
    the band, the top's grain as it ends (its profile) and the side's as it begins; their lines paired
    (_dtw); round the bend each line runs along it, sliding from its depth on the top to its partner's on
    the side, its colour from one to the other. Only the board: the moulding and outline apart."""
    h, w = depth.shape
    res = out.copy()
    vs = (np.arange(FLOW_N) + 0.5) / FLOW_N
    for fy in (False, True):
        for fx in (False, True):
            def f(a):
                a = a[::-1] if fy else a
                return a[:, ::-1] if fx else a
            src, dep, din = f(out), f(depth), f(d_in)
            x0, y0, x1, y1 = OUTER
            wx0, wy0, wx1, wy1 = OPEN
            if fx:
                x0, wx0 = w - x1, w - wx1
            if fy:
                y0, wy0 = h - y1, h - wy1
            ox, oy = x0 + R_OUT, y0 + R_OUT        # (the outline's corner centre)
            ix, iy = wx0 + R_IN, wy0 + R_IN        # (the window's)
            yy, xx = np.mgrid[0:h, 0:w].astype(float) + 0.5
            board = (dep > OZ) & (din > ZONE)
            zone = board & (xx < ix + FLOW_IN) & (yy < iy + FLOW_IN) & ~((xx >= ix) & (yy >= iy))
            dr, ir = dep - OZ, din - ZONE
            v = np.clip(dr / np.maximum(dr + ir, 1e-6), 0, 1)
            th_o = np.where(xx >= ox, 0.0, np.where(yy >= oy, 90.0,
                            np.degrees(np.arctan2(ox - xx, oy - yy))))
            th_i = np.degrees(np.clip(np.arctan2(ix - xx, iy - yy), 0, np.pi / 2))
            sv = np.clip(((1 - v) * th_o + v * th_i) / 90, 0, 1)   # (0: the top's end, 1: the side's)
            # the profiles across the band where the straight sides begin (FLOW_IN in, a few px averaged)
            ht = (wy0 - ZONE) - (y0 + OZ)
            wl = (wx0 - ZONE) - (x0 + OZ)
            ty = (y0 + OZ) + vs * ht
            sx = (x0 + OZ) + vs * wl
            PA = np.mean([np.stack([ndimage.map_coordinates(src[..., c], [ty - 0.5, np.full(FLOW_N, ix + k + 0.5)], order=1)
                                    for c in range(3)], -1) for k in range(FLOW_AVG)], 0)
            PB = np.mean([np.stack([ndimage.map_coordinates(src[..., c], [np.full(FLOW_N, iy + k + 0.5), sx - 0.5], order=1)
                                    for c in range(3)], -1) for k in range(FLOW_AVG)], 0)
            path = np.array(_dtw(PA @ LUM, PB @ LUM))
            va, vb = vs[path[:, 0]], vs[path[:, 1]]
            # the bend's ends inside the straight sides blended in (no edge where the zone starts)
            z = zone
            ssm = sv[z] * sv[z] * (3 - 2 * sv[z])
            vz = v[z]
            col = np.zeros((z.sum(), 3))
            # each pixel's line: the path point whose depth at this s is the pixel's (monotone in it)
            vline = va[None, :] * (1 - ssm[:, None]) + vb[None, :] * ssm[:, None]   # (pixels x path)
            k = np.clip((vline < vz[:, None]).sum(1), 1, len(path) - 1)
            lo_v, hi_v = vline[np.arange(len(k)), k - 1], vline[np.arange(len(k)), k]
            fr = np.clip((vz - lo_v) / np.maximum(hi_v - lo_v, 1e-6), 0, 1)[:, None]
            ca = PA[path[k - 1, 0]] * (1 - fr) + PA[path[k, 0]] * fr
            cb = PB[path[k - 1, 1]] * (1 - fr) + PB[path[k, 1]] * fr
            col = ca * (1 - ssm[:, None]) + cb * ssm[:, None]
            # into the straight sides (the FLOW_IN px past the bend): back to the study's own grain
            past = np.maximum(xx[z] - ix, yy[z] - iy)
            keep = np.clip(past / FLOW_IN, 0, 1)
            keep = (keep * keep * (3 - 2 * keep))[:, None]
            r_ = f(res)
            r_[z, :3] = col * (1 - keep) + src[z, :3] * keep
    return res

def clean(path, step=0, aa=None, corner_soft=None, lines_from=None, smudge=None, osmudge=None, line_dark=None,
          flow=False):
    """corner_soft: the board corners' blur (CORNER_SOFT; 0: none, for a study whose grain already
    turns the corner). lines_from: another study whose outline and window line (width, colour) to use.
    smudge / osmudge: how far beyond the moulding / the outline the old corner shading is wiped (SMUDGE[0],
    OSMUDGE[0]; smaller for a study whose grain runs into the corners: the wipe cuts it).
    line_dark: the outline and window line the slide's own wood, darker (its board's median colour x this;
    the user: "the same colour than the diapositives but darker"), not the study's near-black.
    flow: the board's corners rebuilt so the grain bends round them (corner_flow; no corner blur)."""
    smudge = SMUDGE[0] if smudge is None else smudge
    osmudge = OSMUDGE[0] if osmudge is None else osmudge
    global AA
    if corner_soft is None:
        corner_soft = CORNER_SOFT
    if aa is not None:
        AA = aa
    s = np.array(Image.open(path).convert("RGBA")).astype(float)
    h, w = s.shape[:2]
    op = s[..., 3] > 0
    out = s.copy()
    d_in, a_in = rounded(h, w, OPEN, R_IN)         # (> 0 outside the window)
    d_out, a_out = rounded(h, w, OUTER, R_OUT)     # (< 0 inside the slide)
    depth = -d_out
    yy, xx = np.mgrid[0:h, 0:w]

    def straight_of(box, r):
        x0, y0, x1, y1 = box
        mx = (xx > x0 + r + (x1 - x0) * MID) & (xx < x1 - r - (x1 - x0) * MID)
        my = (yy > y0 + r + (y1 - y0) * MID) & (yy < y1 - r - (y1 - y0) * MID)
        return mx | my
    # the moulding round the window
    prof = side_profiles(s, op & (d_in > 0), d_in, a_in, range(0, SMUDGE[0] + 1), straight_of(OPEN, R_IN))
    paint(out, s, (d_in > -0.5) & (d_in <= ZONE + 0.5) & (depth > OZ), d_in, a_in, prof, range(0, ZONE + 1))
    # by its corners, beyond it: the old corner shading off
    corner = (d_in > ZONE + 0.5) & (d_in <= smudge) & ((a_in % 90) > 1) & ((a_in % 90) < 89) & (depth > OZ)
    paint(out, out.copy(), corner, d_in, a_in, prof, range(ZONE + 1, max(smudge, ZONE) + 1), only_darker=SMUDGE[1])
    # the outline and lip round the slide
    oks = range(0, OZ + 1)
    oprof = side_profiles(s, op & (depth > 0), depth, a_out, range(0, OZ + OSMUDGE[0] + 1), straight_of(OUTER, R_OUT))
    paint(out, s, (depth > -0.5) & (depth <= OZ + 0.5), depth, a_out, oprof, oks)
    # inside its round corners, beyond it: the old stepped outline's leftovers off
    ocorner = (depth > OZ + 0.5) & (depth <= OZ + osmudge) & ((a_out % 90) > 1) & ((a_out % 90) < 89) & (d_in > ZONE)
    paint(out, out.copy(), ocorner, depth, a_out, oprof, range(OZ + 1, OZ + osmudge + 1), only_darker=OSMUDGE[1])
    # the grain fading into the rebuilt bands (no hard cut where they begin: FADE px), and the board's
    # corners simplified (where the study's grain turns from the top's to the side's in a tangle: a soft
    # transition, its detail blurred by CORNER_SOFT)
    blurred = np.stack([ndimage.gaussian_filter(out[..., c], corner_soft) for c in range(3)], -1)
    x0, y0, x1, y1 = OUTER
    rx = np.where(xx < (x0 + x1) / 2, xx - x0, (x1 - 1) - xx)
    ry = np.where(yy < (y0 + y1) / 2, yy - y0, (y1 - 1) - yy)
    cw = np.clip(1 - (np.maximum(rx, ry) - R_OUT) / CORNER_REACH, 0, 1) * (np.minimum(rx, ry) < R_OUT + CORNER_REACH)
    wx0, wy0, wx1, wy1 = OPEN
    X = np.where(xx < (wx0 + wx1) / 2, wx0 - 1 - xx, xx - wx1)
    Y = np.where(yy < (wy0 + wy1) / 2, wy0 - 1 - yy, yy - wy1)
    cw = np.maximum(cw, np.clip(1 - (np.maximum(X, Y) + R_IN - R_IN) / CORNER_REACH, 0, 1) * (X >= -R_IN) * (Y >= -R_IN))
    board_all = (d_in > ZONE + 0.5) & (depth > OZ + 0.5)
    cw = ndimage.gaussian_filter(cw * board_all, 8) * board_all
    if flow:
        out = corner_flow(out, depth, d_in)
    elif corner_soft:
        out[..., :3] = out[..., :3] * (1 - cw[..., None]) + blurred * cw[..., None]
    for dist, prof_, k0, ang_ in ((depth, oprof, OZ, a_out), (d_in, prof, ZONE, a_in)):
        for i in range(1, FADE + 1):
            ring = board_all & (np.round(dist) == k0 + i)
            if not ring.any():
                continue
            t = i / (FADE + 1)
            tmp = out.copy()
            paint(tmp, s, ring, np.full(dist.shape, float(k0)), ang_, prof_, range(k0, k0 + 1))
            out[ring, :3] = tmp[ring, :3] * (1 - t) + out[ring, :3] * t
    # scratches elsewhere
    body = (d_in > ZONE) & (depth > OZ)
    lum = out[..., :3] @ LUM
    med = np.stack([ndimage.median_filter(out[..., c], SCRATCH_K) for c in range(3)], -1)
    scr = body & (lum < med @ LUM - SCRATCH)
    out[scr, :3] = med[scr]
    # pixel art (step): the moulding's round line round the window's corners in the same steps (the
    # user, 2026-11-04: "this round line"), each step its block's mean (anchored at the corner, as the
    # cut's steps: a thin ring comes out half-toned, as the chosen corners)
    if step:
        x0, y0, x1, y1 = OPEN
        X = np.where(xx < (x0 + x1) / 2, x0 - 1 - xx, xx - x1)   # (out from the window's side, 0 at the edge)
        Y = np.where(yy < (y0 + y1) / 2, y0 - 1 - yy, yy - y1)
        # (the whole moulding on the same rows, so the corners join the straight parts without a seam:
        #  along a straight side the rings run parallel, a block's mean there is its row's)
        corner_zone = (d_in > -0.5) & (d_in <= ZONE + step) & (depth > OZ)
        bxi = np.floor((X + R_IN) / step).astype(int)
        byi = np.floor((Y + R_IN) / step).astype(int)
        quad = np.where(yy < (y0 + y1) / 2, 0, 2) + np.where(xx < (x0 + x1) / 2, 0, 1)
        key = (quad * 1000 + byi) * 1000 + bxi
        uk, inv = np.unique(key[corner_zone], return_inverse=True)
        sums = np.zeros((len(uk), 3))
        np.add.at(sums, inv, out[corner_zone][:, :3])
        cnt = np.bincount(inv, minlength=len(uk))[:, None]
        out[corner_zone, :3] = (sums / np.maximum(cnt, 1))[inv]
    # pixel art (step): the silhouette and the window's cut stepped, and the dark lines along them (the
    # outline, the window's edge line) following the steps at their own width; the bands inside smooth
    if step:
        if AA:                                     # (the steps' half-covered blocks: half-tone)
            c_slide = coverage(h, w, OUTER, R_OUT, step)
            c_win = coverage(h, w, OPEN, R_IN, step)
            slide = c_slide > 0.75
            win = c_win > 0.25                     # (the window: a step it half covers is half open)
            half_s = (c_slide > 0.25) & ~slide
            half_w = (c_win > 0.25) & (c_win <= 0.75)
        else:
            win = stepped(h, w, OPEN, R_IN, step)
            slide = stepped(h, w, OUTER, R_OUT, step)
        if lines_from:
            ow, line_o, iw, line_i = study_lines(lines_from)
        else:
            ow, line_o = line_of(oprof)            # (the outline)
            iw, line_i = line_of(prof)             # (the window's edge line)
        if line_dark:
            wood = np.median(s[(d_in > ZONE + 10) & (depth > OZ + 10) & op][:, :3], 0)
            hh, ss, vv = colorsys.rgb_to_hsv(*(wood / 255))     # (darker wood is richer: its hue kept, more
            line_o = line_i = np.array(colorsys.hsv_to_rgb(     #  saturated, not greyed)
                hh, min(1, ss * 1.6 + 0.2), vv * line_dark)) * 255
        od = ndimage.distance_transform_edt(slide) if LINE_EVEN else ndimage.distance_transform_cdt(slide, metric="chessboard")
        # (the window line as wide round its stepped corners as along its sides, the user: "thinner to
        #  match the straight lines": measured straight out from the steps, not square-wise, which made
        #  it ~1.4x as wide across each step's diagonal)
        idist = ndimage.distance_transform_edt(~win) if LINE_EVEN else ndimage.distance_transform_cdt(~win, metric="chessboard")
        out[slide & (od <= ow), :3] = line_o
        out[~win & slide & (idist <= iw) & (od > ow), :3] = line_i
        alpha = (slide & ~win).astype(float)
        if AA:
            out[half_s, :3] = line_o
            alpha[half_s] = 0.5
            if WIN_HALF:                           # (off: the window's own texture runs clean up to its
                out[half_w, :3] = line_i           #  line, the user: "the inner texture has to continue
                alpha[half_w] = 0.5                #  until there"; the half steps read as specks on it)
    else:
        alpha = np.clip(0.5 - d_out, 0, 1) * np.clip(0.5 + d_in, 0, 1)
    out[..., 3] = np.round(alpha * 255)
    return Image.fromarray(np.clip(np.round(out), 0, 255).astype(np.uint8)), int(scr.sum())


if __name__ == "__main__":
    args = sys.argv[1:]
    step = 0
    while args and args[0].startswith("--"):
        a = args.pop(0)
        if a.startswith("--step="):                # (--step=16: pixel art, the corners in 16 px steps)
            step = int(a.split("=")[1])
        elif a == "--aa":
            AA = True
    out_dir = OUT.rstrip("/") + ("_step%d%s/" % (step, "aa" if AA else "") if step else "/")
    os.makedirs(out_dir, exist_ok=True)
    for p in args:
        im, n = clean(p, step)
        im.save(out_dir + os.path.basename(p))
        print(os.path.basename(p), "step", step, "scratch px", n)
