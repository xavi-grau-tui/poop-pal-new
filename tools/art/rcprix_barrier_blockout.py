"""The corner barriers as 3D block-outs in the game's view, for the designer to paint over (round 20: the user,
2026-10-27, perspective matters, the near part of a curve seen from outside, the far part from inside; round
21: the whole curve walled like the original, snug to the road, and on into the straights as far as the car
bounces off it). Run from the repo root:

    <python with Pillow + numpy + scipy> tools/art/rcprix_barrier_blockout.py [--game]

The game's camera: the ground straight from above, anything tall drawn up the screen by its height (as the
road's orange side face). So each block / tyre is its footprint on the grass, its top face that footprint moved
up by its height, and between them only the walls that face the bottom of the screen: on the near part of a
curve (below the road) the barrier's outer wall, on the far part (above the road) its inner wall, the road side;
where it runs up/down, the blocks' ends. Nearer pieces cover farther ones (drawn bottom-most last). Standing in
front of the raised road, a barrier's top may cover the foot of the road's orange side face.

Each file is the corner square with a RUN margin round it (SQ + 2 RUN square, the square at RUN, RUN): the
whole 90 degrees of the curve inside the square, and past each of its two ends one more piece in the margin
strip beside that end (the rail reaches 9 centre points, 36 art px, on: rc_racer _find_rails). The game
stamps a strip only where the next square is a straight (rc_tiles _tyres_on): nothing of the curve is in a
strip and nothing of a run-on outside its strip.
  tyres_<corner>[_wide]      blocks (sample B / the glossy study), red / white
  tyres_<corner>_alt[_wide]  tyres (sample A / the glossy study), blue / yellow
Writes them to docs/mockups/rcprix_garden/round21_barrier_blockout/ (with --game also into the game's
folder) and round21_barrier_blockout_3x.png (each on its corner with the straights it runs into)."""
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
TILES = ROOT / "textures/minigames/rcprix/garden"
OUT = ROOT / "docs/mockups/rcprix_garden/round21_barrier_blockout"
SQ = 180
RUN = 64                    # the margin round the square for the run-ons, art px
W = SQ + 2 * RUN
CENTRES = {"ne": (180, 0), "nw": (0, 0), "se": (180, 180), "sw": (0, 180)}
BASE = {"ne": 90, "nw": 0, "se": 180, "sw": 270}     # the arc's angles (image y down) from the centre
ENDS = {"ne": ("e", "n"), "nw": ("n", "w"), "se": ("s", "e"), "sw": ("w", "s")}   # the low and high angle's ends
GAP = 2                     # ground between the road's edge and a barrier's footprint
INK = np.array((32, 16, 24))
LIGHT = np.array((-0.6, -0.8))                         # light from the top left
# per colour (the glossy studies' own): top shine, top, wall lit (faces left), wall (faces the camera), wall
# dark (faces right), the wall's foot on the ground
SHADES = {
    "red": [(246, 166, 156), (232, 136, 128), (218, 62, 54), (206, 52, 48), (152, 32, 40), (118, 24, 30)],
    "white": [(255, 252, 246), (248, 240, 230), (222, 214, 204), (208, 200, 190), (160, 152, 146), (128, 120, 120)],
    "blue": [(186, 222, 255), (52, 126, 236), (40, 100, 210), (32, 84, 186), (24, 60, 140), (18, 44, 108)],
    "yellow": [(255, 246, 180), (250, 200, 50), (236, 176, 36), (220, 156, 30), (170, 110, 24), (130, 82, 20)],
}
BLOCK = dict(depth=9, height=10, length=30, gap=2)     # straight bricks, as the study (not bent along the curve)
TYRE = dict(r=12, hole=5, height=4, gap=1)


def road_edge(corner, wide):
    """The road's outer edge round the corner, angle by angle: edge(a0, a1) -> its farthest radius between those
    angles (degrees). Where the edge faces down the screen that's the foot of its orange side face, where it
    runs up/down the curb itself (round 22: one radius for the whole corner left a gap there)"""
    a = np.asarray(Image.open(TILES / f"corner_{corner}{wide}.png").convert("RGBA"))[..., 3] > 0
    ys, xs = np.nonzero(a)
    cx, cy = CENTRES[corner]
    ang = np.degrees(np.arctan2(ys + 0.5 - cy, xs + 0.5 - cx)) % 360
    rad = np.hypot(xs + 0.5 - cx, ys + 0.5 - cy)
    far = np.zeros(360)
    np.maximum.at(far, ang.astype(int) % 360, rad)

    def edge(a0, a1):
        bins = np.arange(math.floor(min(a0, a1)) - 1, math.ceil(max(a0, a1)) + 2) % 360
        return float(far[bins].max())
    return edge


def render(pieces):
    """pieces: [(inside(gx, gy) -> bool array, normal(gx, gy) -> (nx, ny) arrays, height, colour, extra)]
    in the file's coordinates, drawn far to near"""
    yy, xx = np.mgrid[0:W, 0:W].astype(float) + 0.5
    out = np.zeros((W, W, 4), np.uint8)
    for inside, normal, h, colour, extra in sorted(pieces, key=lambda p: p[4]["y"]):
        sh = SHADES[colour]
        top = inside(xx, yy + h)
        # the walls: of the ground points under the pixel within the height, the nearest one (largest y)
        # inside the footprint is where the wall we see stands
        wall = np.zeros_like(top)
        zfront = np.full(xx.shape, -1.0)
        for z in np.arange(0, h + 0.01, 0.5):
            hit = inside(xx, yy + z)
            zfront = np.where(hit, z, zfront)
            wall |= hit
        wall &= ~top
        mask = top | wall
        if not mask.any():
            continue
        if "centre" not in extra:             # a block's corners rounded off a little
            n8 = ndimage.convolve(mask.astype(int), np.ones((3, 3)), mode="constant") - mask
            mask &= n8 > 3
            top &= mask
            wall &= mask
        rgb = np.zeros((W, W, 3))
        rgb[top] = sh[1]
        if wall.any():
            nx, ny = normal(xx, yy + np.maximum(zfront, 0))
            lit = -(nx * LIGHT[0])
            idx = np.where(lit > 0.25, 2, np.where(lit < -0.25, 4, 3))
            for k in (2, 3, 4):
                rgb[wall & (idx == k)] = sh[k]
            rgb[wall & (zfront <= 1.0) & (idx != 4)] = sh[5]           # its foot, where it meets the grass
        t_up = np.roll(top, 1, 0)
        t_left = np.roll(top, 1, 1)
        if "centre" not in extra:             # the top face's lit rim (its top-left edges)
            rgb[top & ~(t_up & t_left)] = sh[0]
        rgb[wall & np.roll(top, 1, 0)] = sh[1] if colour in ("white", "yellow") else sh[0]
        if "centre" in extra:                 # a tyre's rounded top: lit on its top-left shoulder, the slope into the hole shaded
            ex, ey = extra["centre"]
            dx, dy = xx - ex, yy + h - ey
            dist = np.hypot(dx, dy)
            facing = -(dx * LIGHT[0] + dy * LIGHT[1]) / np.maximum(dist, 1e-6)
            mid = (TYRE["hole"] + TYRE["r"]) / 2
            rgb[top & (np.abs(dist - mid) <= 1.6) & (facing > 0.45)] = sh[0]          # the shine round its top-left
            rgb[top & (np.abs(dist - mid) <= 0.8) & (facing > 0.85)] = (255, 255, 255)
            rgb[top & (dist <= TYRE["hole"] + 1.5)] = sh[3]                         # the slope into the hole
            rgb[top & (dist >= TYRE["r"] - 1.5) & (facing < -0.2)] = sh[3]          # the far side of its round
            hole = dist <= TYRE["hole"]
            rgb[hole] = INK + 8
            rgb[hole & (np.hypot(dx, dy + 2) > TYRE["hole"])] = sh[4]          # its far inner wall
        ring = ndimage.binary_dilation(mask, np.ones((3, 3))) & ~mask
        out[ring, :3] = INK
        out[ring, 3] = 255
        out[mask, :3] = rgb[mask]
        out[mask, 3] = 255
        if "centre" in extra:
            edge = ndimage.binary_dilation(hole, np.ones((3, 3))) & ~hole & top
            out[edge, :3] = INK
    return Image.fromarray(out)


def frame(corner):
    """The corner's centre in the file, and its two ends: [(angle, the way out of the square)]"""
    cx, cy = CENTRES[corner]
    b = math.radians(BASE[corner])
    lo_out = (math.sin(b), -math.cos(b))
    hi = b + math.pi / 2
    hi_out = (-math.sin(hi), math.cos(hi))
    return (cx + RUN, cy + RUN), [(BASE[corner], lo_out), (BASE[corner] + 90, hi_out)]


def end_gaps(h):
    """How far the curve stops short of the square's edge at an end (its top, drawn up, must not reach into the
    strip) and how far a run-on starts past it (its top must not reach back into the square)"""
    def short(out):
        return 2 + h * max(0.0, -out[1])

    def past(out):
        return 2 + h * max(0.0, out[1])
    return short, past


def sector(c, r0, r1, a0, a1):
    cx, cy = c

    def ang(gx, gy):
        return (np.degrees(np.arctan2(gy - cy, gx - cx)) - a0) % 360

    def inside(gx, gy):
        r = np.hypot(gx - cx, gy - cy)
        return (r >= r0) & (r <= r1) & (ang(gx, gy) <= a1 - a0)

    def normal(gx, gy):
        r = np.maximum(np.hypot(gx - cx, gy - cy), 1e-6)
        ux, uy = (gx - cx) / r, (gy - cy) / r
        a = ang(gx, gy)
        dist = np.stack([r1 - r, r - r0, np.radians(a) * r, np.radians((a1 - a0) - a) * r])
        k = np.argmin(np.abs(dist), 0)
        tx, ty = -uy, ux
        return np.choose(k, [ux, -ux, -tx, tx]), np.choose(k, [uy, -uy, -ty, ty])
    return inside, normal


def slab(c, ang, out, r0, r1, s0, s1):
    """A straight block past an end: across r0..r1 from the centre along the end's radius, along s0..s1 out"""
    cx, cy = c
    ux, uy = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    ox, oy = out

    def inside(gx, gy):
        r = (gx - cx) * ux + (gy - cy) * uy
        s = (gx - cx) * ox + (gy - cy) * oy
        return (r >= r0) & (r <= r1) & (s >= s0) & (s <= s1)

    def normal(gx, gy):
        r = (gx - cx) * ux + (gy - cy) * uy
        s = (gx - cx) * ox + (gy - cy) * oy
        k = np.argmin(np.abs(np.stack([r1 - r, r - r0, s - s0, s1 - s])), 0)
        return np.choose(k, [ux, -ux, -ox, ox]), np.choose(k, [uy, -uy, -oy, oy])
    return inside, normal


def blocks(corner, edge):
    """Straight bricks round the curve, all the same length, each square to it at its middle and just off the road
    where it stands, end to end at their inner corners (the gaps opening outward, as the study), then one more past
    each end"""
    d, h, L, gap = BLOCK["depth"], BLOCK["height"], BLOCK["length"], BLOCK["gap"]
    c, ends = frame(corner)
    short, past = end_gaps(h)
    r_lo = edge(ends[0][0] - 1, ends[0][0] + 1) + GAP
    r_hi = edge(ends[1][0] - 1, ends[1][0] + 1) + GAP
    a_lo = math.radians(ends[0][0]) + short(ends[0][1]) / r_lo
    a_hi = math.radians(ends[1][0]) - short(ends[1][1]) / r_hi

    def lay(length, n):
        """[(middle angle, r0, half length)] from a_lo, and where the last one ends"""
        out, a = [], a_lo
        for _ in range(n):
            r0 = edge(math.degrees(a), math.degrees(a) + 12) + GAP
            for _ in range(3):
                span = 2 * math.atan(length / 2 / r0)
                r0 = edge(math.degrees(a), math.degrees(a + span)) + GAP
            span = 2 * math.atan(length / 2 / r0)
            out.append((a + span / 2, r0, r0 * math.tan(span / 2)))
            a += span + gap / r0
        return out, a - gap / r0

    n = max(3, round((a_hi - a_lo) * (r_lo + r_hi) / 2 / (L + gap)))
    lo, hi = L * 0.6, L * 1.4
    for _ in range(40):                           # the length that fills the curve exactly
        mid = (lo + hi) / 2
        if lay(mid, n)[1] > a_hi:
            hi = mid
        else:
            lo = mid
    laid, _ = lay(lo, n)
    pieces = []
    for i, (mid, r0, hl) in enumerate(laid):
        t = (-math.sin(mid), math.cos(mid))
        inside, normal = slab(c, math.degrees(mid), t, r0, r0 + d, -hl, hl)
        pieces.append((inside, normal, h, "red" if i % 2 == 0 else "white", {"y": c[1] + (r0 + d / 2) * math.sin(mid)}))
    for k, (ang, out) in enumerate(ends):        # a run-on brick past each end, the colour after the curve's end one
        r0 = r_lo if k == 0 else r_hi
        s0 = past(out)
        inside, normal = slab(c, ang, out, r0, r0 + d, s0, s0 + L)
        y = c[1] + (r0 + d / 2) * math.sin(math.radians(ang)) + out[1] * (s0 + L / 2)
        last = 0 if k == 0 else n - 1
        pieces.append((inside, normal, h, "white" if last % 2 == 0 else "red", {"y": y}))
    return pieces


def tyres(corner, edge):
    """Tyres round the curve, each just off the road where it stands, evenly spread end to end and never
    touching each other, then two more past each end"""
    R, h, gap = TYRE["r"], TYRE["height"], TYRE["gap"]
    c, ends = frame(corner)
    short, past = end_gaps(h)
    rm_at = lambda a: edge(a - math.degrees(R / 150), a + math.degrees(R / 150)) + GAP + R
    rm_lo, rm_hi = rm_at(ends[0][0]), rm_at(ends[1][0])
    a_lo = ends[0][0] + math.degrees((short(ends[0][1]) + R + 1) / rm_lo)    # (the end tyres right at the ends, whole)
    a_hi = ends[1][0] - math.degrees((short(ends[1][1]) + R + 1) / rm_hi)
    pitch = 2 * R + 2 + gap
    n = int(math.radians(a_hi - a_lo) * (rm_lo + rm_hi) / 2 // pitch) + 1
    while True:
        centres = [(a, rm_at(a)) for a in np.linspace(a_lo, a_hi, n)]
        xy = [(c[0] + r * math.cos(math.radians(a)), c[1] + r * math.sin(math.radians(a))) for a, r in centres]
        if all(math.dist(p, q) >= pitch - gap for p, q in zip(xy, xy[1:])):
            break
        n -= 1
    pieces = []

    def tyre(px, py, colour):
        def inside(gx, gy):
            return np.hypot(gx - px, gy - py) <= R

        def normal(gx, gy):
            r = np.maximum(np.hypot(gx - px, gy - py), 1e-6)
            return (gx - px) / r, (gy - py) / r
        return (inside, normal, h, colour, {"y": py, "centre": (px, py)})

    for i, (px, py) in enumerate(xy):
        pieces.append(tyre(px, py, "blue" if i % 2 == 0 else "yellow"))
    for k, (ang, out) in enumerate(ends):        # two run-on tyres past each end, carrying on the colours
        rm = rm_lo if k == 0 else rm_hi
        ar = math.radians(ang)
        bx, by = c[0] + rm * math.cos(ar), c[1] + rm * math.sin(ar)
        last = 0 if k == 0 else n - 1
        for j in range(2):
            s = past(out) + R + 1 + j * (2 * R + 2 + gap)
            colour = "blue" if (last + j + 1) % 2 == 0 else "yellow"
            pieces.append(tyre(bx + out[0] * s, by + out[1] * s, colour))
    return pieces


def check(im, corner, edge):
    """Where the pixels are: the curve's inside the square, the run-ons inside their strips (the file's corners
    empty), none on the road; returns (px clear of the road, any pixels where they mustn't be)"""
    a = np.asarray(im)[..., 3] > 0
    ys, xs = np.nonzero(a)
    cx, cy = CENTRES[corner][0] + RUN, CENTRES[corner][1] + RUN
    inx = (xs >= RUN) & (xs < RUN + SQ)
    iny = (ys >= RUN) & (ys < RUN + SQ)
    strips = {"n": inx & (ys < RUN), "s": inx & (ys >= RUN + SQ), "w": iny & (xs < RUN), "e": iny & (xs >= RUN + SQ)}
    ok = inx & iny
    for e in ENDS[corner]:
        ok |= strips[e]
    ok &= (xs > 0) & (ys > 0) & (xs < W - 1) & (ys < W - 1)      # (touching the file's edge: cut off by it)
    sq = inx & iny
    ang = np.degrees(np.arctan2(ys[sq] + 0.5 - cy, xs[sq] + 0.5 - cx)) % 360
    rad = np.hypot(xs[sq] + 0.5 - cx, ys[sq] + 0.5 - cy)
    gaps = [rad[i] - edge(ang[i], ang[i]) for i in range(len(rad))]
    near = (min(gaps), float(np.percentile(gaps, 2)))
    return near, int((~ok).sum())


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    game = "--game" in sys.argv
    sheet = []
    for wide in ("", "_wide"):
        for corner in CENTRES:
            r = road_edge(corner, wide)
            for alt, make in (("", blocks), ("_alt", tyres)):
                name = f"tyres_{corner}{alt}{wide}"
                im = render(make(corner, r))
                im.save(OUT / f"{name}.png")
                if game:
                    im.save(TILES / f"{name}.png")
                near, stray = check(im, corner, r)
                print(f"{name}: nearest {near[0]:.1f} px to the road's edge, {stray} px out of place")
                sheet.append((name, corner, wide, im))
    # the contact sheet: each on its corner with the straights it runs into, 3x
    cols = 4
    cell = W + 8
    order = sorted(sheet, key=lambda s: (["ne", "nw", "se", "sw"].index(s[1]), s[2] == "_wide", "_alt" in s[0]))
    board = Image.new("RGBA", (cols * cell, (len(order) + cols - 1) // cols * cell), (40, 30, 40, 255))
    offs = {"n": (0, -1), "s": (0, 1), "e": (1, 0), "w": (-1, 0)}
    for k, (name, corner, wide, im) in enumerate(order):
        t = Image.new("RGBA", (W, W), (112, 170, 76, 255))
        t.alpha_composite(Image.open(TILES / f"corner_{corner}{wide}.png").convert("RGBA"), (RUN, RUN))
        for e in ENDS[corner]:
            dx, dy = offs[e]
            straight = "straight_v" if dy else "straight_h"
            t.alpha_composite(Image.open(TILES / f"{straight}{wide}.png").convert("RGBA").crop(
                (max(0, -dx * (SQ - RUN)) if dx else 0, max(0, -dy * (SQ - RUN)) if dy else 0,
                 (RUN if dx > 0 else SQ) if dx else SQ, (RUN if dy > 0 else SQ) if dy else SQ)),
                (RUN + SQ if dx > 0 else 0 if dx < 0 else RUN, RUN + SQ if dy > 0 else 0 if dy < 0 else RUN))
        t.alpha_composite(im)
        board.paste(t, ((k % cols) * cell + 4, (k // cols) * cell + 4))
    big = board.resize((board.width * 3, board.height * 3), Image.NEAREST)
    dr = ImageDraw.Draw(big)
    for k, (name, *_rest) in enumerate(order):
        dr.text(((k % cols) * cell * 3 + 18, (k // cols) * cell * 3 + 16), name, fill=(255, 255, 255, 255))
    big.save(OUT.parent / "round21_barrier_blockout_3x.png")


if __name__ == "__main__":
    main()
