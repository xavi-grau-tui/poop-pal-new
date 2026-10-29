"""RC Prix Sky, round 2: the designer's ImageGen paintings (docs/mockups/rcprix_sky/round2_imagegen_sources/) put on
the game's pixel grid. Run from the repo root:

    <python with Pillow + numpy> tools/art/rcprix_sky_from_sources.py

Writes into textures/minigames/rcprix/sky/:
  ring_<r>, ring_gold_<r>, ring_grey_<r>   every ring size the levels use (ring_r, world px, 86 .. 124 by 2), each
            scaled from the painting itself (never a resized ring): the tube's outside r + 14 game px across (its
            centre line, where it counts, r / 2 from the middle), on a canvas 3 px bigger all round
  stand_cloud_<view>_<under|over>_<long>   the cloud under a stand <long> art px long (the stand's three lengths,
            rc_racer STAND_LONGS / 2), whole (no repeated middle), CLOUD_MARGIN 22 past the stand all round:
            front / back banks at the canvas's foot, the side views' towers on the stand's far side; the over
            layer placed as the painter placed it against its under layer"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from rcprix_pixelate import opaque_box, pixelate  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs/mockups/rcprix_sky/round2_imagegen_sources"
OUT = ROOT / "textures/minigames/rcprix/sky"
RINGS = range(86, 126, 2)
LONGS = (248, 328, 408)                # the stand's lengths, art px (end_a 41 + 2 / 3 / 4 middles of 80 + end_b 47)
DEEP = 107                             # the stand's depth, art px
MARGIN = 22
FRONT_MAX_H = 90                       # a front / back bank no taller than this (past it, it's widened instead)


def grey(a):
    out = a.copy().astype(float)
    lum = out[..., :3] @ np.array([0.3, 0.59, 0.11])
    g = 70 + lum * 0.55
    ink = a[..., :3].max(-1) < 90                        # (the outline stays dark; the red doesn't count)
    out[..., 0], out[..., 1], out[..., 2] = g * 0.98, g * 0.96, g * 1.04
    out[ink] = a[ink]
    return np.clip(out, 0, 255).astype(np.uint8)


def save(name, a):
    Image.fromarray(a).save(OUT / f"{name}.png")


def rings():
    for look, file in (("", "ring_red_source.png"), ("gold_", "ring_gold_source.png")):
        im = Image.open(SRC / file).convert("RGBA")
        im = im.crop(opaque_box(im))
        for r in RINGS:
            w = r + 14
            h = round(im.height * w / im.width)
            a = pixelate(im, (w, h), 10)
            canvas = np.zeros((h + 6, w + 6, 4), np.uint8)
            canvas[3:3 + h, 3:3 + w] = a
            save(f"ring_{look}{r}", canvas)
            if look == "":
                save(f"ring_grey_{r}", grey(canvas))
    print("  rings", list(RINGS)[0], "..", list(RINGS)[-1])


def cloud(view):
    along_x = view in ("front", "back")
    under = Image.open(SRC / f"stand_cloud_{view}_under_source.png").convert("RGBA")
    over = Image.open(SRC / f"stand_cloud_{view}_over_source.png").convert("RGBA")
    ub = opaque_box(under)
    ob = opaque_box(over)
    k_canvas = under.width / over.width                  # (the over painting's canvas onto the under's)
    for long in LONGS:
        L = long + 2 * MARGIN                            # the canvas along the stand
        T = DEEP + 2 * MARGIN                            # ...and across it
        uw, uh = ub[2] - ub[0], ub[3] - ub[1]
        if along_x:
            w = L
            h = min(round(uh * w / uw), FRONT_MAX_H)
            sx, sy = w / uw, h / uh
        else:
            h = L
            w = min(round(uw * h / uh), T)
            sx, sy = w / uw, h / uh
        canvas_w, canvas_h = (L, T) if along_x else (T, L)
        # the under bank: at the canvas's foot (front / back), on the stand's far side (side views)
        ux = 0 if along_x or view == "side_l" else canvas_w - w
        uy = canvas_h - h
        for layer, im, box in (("under", under, ub), ("over", over, ob)):
            if layer == "over":
                # its box in the under painting's px, then the same scale and place
                bx0, by0 = box[0] * k_canvas, box[1] * k_canvas
                bw, bh = (box[2] - box[0]) * k_canvas, (box[3] - box[1]) * k_canvas
                ox = ux + (bx0 - ub[0]) * sx
                oy = uy + (by0 - ub[1]) * sy
                pw, ph = max(1, round(bw * sx)), max(1, round(bh * sy))
            else:
                ox, oy, pw, ph = ux, uy, w, h
            a = pixelate(im.crop(box), (pw, ph), 7)
            canvas = np.zeros((canvas_h, canvas_w, 4), np.uint8)
            # (nudged inside the canvas, never cut: a puff past its edge showed a straight line, the user)
            ox = min(max(ox, 0), canvas_w - pw)
            oy = min(max(oy, 0), canvas_h - ph)
            x0, y0 = int(round(ox)), int(round(oy))
            x1, y1 = min(canvas_w, x0 + pw), min(canvas_h, y0 + ph)
            x0c, y0c = max(0, x0), max(0, y0)
            canvas[y0c:y1, x0c:x1] = a[y0c - y0:y1 - y0, x0c - x0:x1 - x0]
            save(f"stand_cloud_{view}_{layer}_{long}", canvas)
    print("  stand clouds", view)


## The ground's fields (ground_sources/field_<kind>_source.png): rows painted horizontal, turned here to the grid's
## long edges (rc_racer _sky_floor: v = y * 0.9 - x * 0.24 -> lines atan(0.24 / 0.9) = 14.9 degrees down to the
## right) while still big, then cut to a square that covers any one field (a field's box is about 125 x 105 art px)
FIELD_SRC = ROOT / "docs/mockups/rcprix_sky/ground_sources"
FIELD_SQUARE = 165                     # a painting's square in game px (its ~31 rows about 5 px apart)
FIELD_PATCH = 132                      # the square cut from it once turned (fits inside: 165 / (cos + sin))
FIELD_ANGLE = float(np.degrees(np.arctan2(0.24, 0.9)))


def fields():
    for p in sorted(FIELD_SRC.glob("field_*_source.png")):
        kind = p.name[len("field_"):-len("_source.png")]
        im = Image.open(p).convert("RGBA")
        k = im.width / FIELD_SQUARE                       # source px per game px
        turned = im.rotate(-FIELD_ANGLE, resample=Image.BICUBIC, expand=False)
        c = turned.width / 2.0
        half = FIELD_PATCH * k / 2.0
        patch = turned.crop((round(c - half), round(c - half), round(c + half), round(c + half)))
        save(f"field_{kind}", pixelate(patch, (FIELD_PATCH, FIELD_PATCH), 12))
    print("  fields")


## The ground's other pieces: hedges cut to a field edge's length and turned to each edge (a: the long edges, along
## (0.9, 0.24), b: the short ones, along (-0.32, 0.86); RcSky.ground strings them centred on each edge), the river
## strip (the game repeats it along its winding path), the decor at its size in game px (1.4x the brief's: specks
## next to a 100 px field otherwise), the bridge turned upright to cross the river (which runs left to right)
EDGE_A = 92.0 * float(np.hypot(0.9, 0.24)) / (0.86 * 0.9 + 0.32 * 0.24)     # 100.7 art px
EDGE_B = 76.0 * float(np.hypot(0.32, 0.86)) / (0.86 * 0.9 + 0.32 * 0.24)    # 82.0
ANGLE_B = float(np.degrees(np.arctan2(0.86, 0.32)))                          # 69.6 (up to the right)
HEDGES = {"hedge_low": 4, "hedge_tree_line": 6}                             # their thickness, art px
RIVER_H = 22                                                                 # the river strip, banks and all
DECOR = {"farmhouse_barn": 17, "village": 45, "church": 14, "windmill_tower": 24, "windmill_sails": 28,
         "pond": 22, "haystacks": 14, "copse": 34, "stone_bridge": 20}       # width, game px (the bridge: seen from the
                                                                             # side, running up to the right at 70 degrees)
MILL_HUB = (558, 608)                  # the sails' spindle on the tower's painting (source px)


def strip(name, thick, length):
    """A horizontal strip painting scaled to `thick` art px and repeated (every other copy mirrored) to `length`"""
    im = Image.open(FIELD_SRC / f"{name}_source.png").convert("RGBA")
    im = im.crop(opaque_box(im))
    k = im.height / thick                                 # source px per art px
    if length is None:
        length = 2 * im.width / k
    n = int(np.ceil(length * k / im.width)) + 1
    long = Image.new("RGBA", (im.width * n, im.height), (0, 0, 0, 0))
    for i in range(n):
        long.paste(im.transpose(Image.FLIP_LEFT_RIGHT) if i % 2 else im, (i * im.width, 0))
    return long.crop((0, 0, round(length * k), im.height)), k


def ground_pieces():
    for name, thick in HEDGES.items():
        for tag, length, angle in (("a", EDGE_A + 2, -FIELD_ANGLE), ("b", EDGE_B + 2, ANGLE_B)):
            im, k = strip(name, thick, length)
            turned = im.rotate(angle, resample=Image.BICUBIC, expand=True)
            save(f"{name}_{tag}", pixelate(turned, (max(1, round(turned.width / k)), max(1, round(turned.height / k))), 8))
    im, k = strip("river", RIVER_H, None)                # (exactly two copies, the second mirrored: it wraps round)
    save("river", pixelate(im, (round(im.width / k), RIVER_H), 10))
    for name, w in DECOR.items():
        im = Image.open(FIELD_SRC / f"{name}_source.png").convert("RGBA")
        box = opaque_box(im)
        if name == "windmill_sails":
            # (cut square round its hub: it turns round its middle)
            hub = (630, 629)
            r = max(hub[0] - box[0], box[2] - hub[0], hub[1] - box[1], box[3] - hub[1])
            box = (hub[0] - r, hub[1] - r, hub[0] + r, hub[1] + r)
        elif name == "windmill_tower":
            # (cut so the sails' spindle is its middle: RcSky.ground puts the sails on the tower's middle)
            hx, hy = MILL_HUB
            rx = max(hx - box[0], box[2] - hx)
            ry = max(hy - box[1], box[3] - hy)
            box = (hx - rx, hy - ry, hx + rx, hy + ry)
        im = im.crop(box)
        h = max(1, round(im.height * w / im.width))
        save(f"decor_{name}", pixelate(im, (w, h), 10))
    print("  hedges, river, decor")


## The drifting clouds (cloud_sources/, shown nearly see-through by the game) and the hot-air balloons
## (balloon_sources/, blue and pink only: the user), at their game sizes
SKY = ROOT / "docs/mockups/rcprix_sky"
CLOUDS = {"large_a": 160, "large_b": 160, "medium_a": 100, "medium_b": 100, "small_a": 50, "small_b": 50}
BALLOONS = {"blue": "blue_white", "pink": "pink_white"}
BALLOON_W = 38                         # game px: today's (19 board px at 4 world px)


def sky_things():
    for name, w in CLOUDS.items():
        im = Image.open(SKY / f"cloud_sources/cloud_{name}_source.png").convert("RGBA")
        im = im.crop(opaque_box(im))
        save(f"cloud_{name}", pixelate(im, (w, round(im.height * w / im.width)), 8))
    for name, src in BALLOONS.items():
        im = Image.open(SKY / f"balloon_sources/balloon_{src}_source.png").convert("RGBA")
        im = im.crop(opaque_box(im))
        save(f"balloon_{name}", pixelate(im, (BALLOON_W, round(im.height * BALLOON_W / im.width)), 16))
    print("  clouds, balloons")


## The stands' clouds made from the drifting clouds' paintings (the user: those are nicer): for each view and length,
## big drifting clouds overlapped where the bank goes (where round 2's painted bank was: its picture is the guide,
## stand_cloud_<view>_under_<long>), back ones first; then a few small ones over the stand's feet (where round 2's
## foreground puffs were)
DRIFT = ["large_a", "large_b", "medium_a", "medium_b"]
DRIFT_SMALL = ["small_a", "small_b", "medium_a", "medium_b"]
_drift_cache = {}


def drift_cloud(name, w):
    key = (name, w)
    if key not in _drift_cache:
        im = Image.open(SKY / f"cloud_sources/cloud_{name}_source.png").convert("RGBA")
        im = im.crop(opaque_box(im))
        _drift_cache[key] = pixelate(im, (w, round(im.height * w / im.width)), 8)
    return _drift_cache[key]


def paste(canvas, a, cx, cy):
    """`a` blended on `canvas` centred on (cx, cy), moved inside it (never cut)"""
    ch, cw = canvas.shape[:2]
    h, w = a.shape[:2]
    x0 = int(round(min(max(cx - w / 2, 0), cw - w)))
    y0 = int(round(min(max(cy - h / 2, 0), ch - h)))
    m = a[..., 3] > 0
    canvas[y0:y0 + h, x0:x0 + w][m] = a[m]


def stand_clouds_from_drift():
    """(the user, 2026-10-29: past the stand a little on every edge; along its south edge, the screen's bottom, a row
    of puffs over the stand's foot for depth, like the runway's)"""
    import random
    m = MARGIN
    for view in ("front", "back", "side_l", "side_r"):
        along_x = view in ("front", "back")
        for long in LONGS:
            rnd = random.Random(hash((view, long)) & 0xffff)
            W, H = (long + 2 * m, DEEP + 2 * m) if along_x else (DEEP + 2 * m, long + 2 * m)
            # under: big ones over the whole canvas (the stand and the margin round it), the higher ones behind
            under = np.zeros((H, W, 4), np.uint8)
            spots = []
            for y in np.arange(26, H - 18, 40):
                for x in np.arange(30, W - 20, 58):
                    spots.append((x + rnd.uniform(-10, 10), y + rnd.uniform(-6, 6)))
            spots.sort(key=lambda p: p[1])
            for (x, y) in spots:
                a = drift_cloud(rnd.choice(DRIFT), rnd.randint(90, 130))
                paste(under, a[:, ::-1].copy() if rnd.random() < 0.5 else a, x, y)
            save(f"stand_cloud_{view}_under_{long}", under)
            # over: a row of puffs along the south edge, their tops over the stand's foot
            over = np.zeros((H, W, 4), np.uint8)
            x = m + rnd.uniform(0, 14)
            while x < W - m:
                a = drift_cloud(rnd.choice(DRIFT_SMALL), rnd.randint(44, 64))
                paste(over, a[:, ::-1].copy() if rnd.random() < 0.5 else a, x, H - m - 4 + rnd.uniform(-3, 3))
                x += rnd.uniform(38, 52)
            save(f"stand_cloud_{view}_over_{long}", over)
    print("  stand clouds from the drifting clouds")


## The start platform (the user picked concept C, the cloud runway, with an orange windsock): for each way the
## race starts (the painting runs down: the plane starts at its bunting and flies over the checkered line), turned
## and cut so the line's middle is the picture's middle (SkyDock draws it there); its width across the course
## PLATFORM_ACROSS game px (clear of the stand above the start). The windsock taken off concept A's pole, orange
PLATFORM_SRC = SKY / "platform_concepts/platform_C_cloud_runway.png"
PLATFORM_LINE = (663, 801)             # the checkered line's middle on the painting (source px)
PLATFORM_ACROSS = 168
SOCK_BOX = (960, 105, 1200, 352)       # concept A's windsock and its pole
SOCK_H = 22                            # game px


def platform():
    import colorsys
    im = Image.open(PLATFORM_SRC).convert("RGBA")
    box = opaque_box(im)
    k = (box[2] - box[0]) / PLATFORM_ACROSS               # source px per game px
    W, H = im.size
    lx, ly = PLATFORM_LINE
    for name, rot in (("s", 0), ("e", 90), ("n", 180), ("w", 270)):
        r = im.rotate(rot, expand=True)
        # (the line's middle, turned with it: rotate() turns counter-clockwise)
        px, py = {0: (lx, ly), 90: (ly, W - 1 - lx), 180: (W - 1 - lx, H - 1 - ly), 270: (H - 1 - ly, lx)}[rot]
        b = opaque_box(r)
        rx = max(px - b[0], b[2] - px)
        ry = max(py - b[1], b[3] - py)
        cut = r.crop((round(px - rx), round(py - ry), round(px + rx), round(py + ry)))
        save(f"platform_{name}", pixelate(cut, (round(cut.width / k / 2) * 2, round(cut.height / k / 2) * 2), 14))
    sock = Image.open(SKY / "platform_concepts/platform_A_grassy_islet.png").convert("RGBA").crop(SOCK_BOX)
    a = np.array(sock).astype(float)
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            r_, g_, b_, al = a[y, x] / 255.0
            if al <= 0.5:
                continue
            h, sat, v = colorsys.rgb_to_hsv(r_, g_, b_)
            if g_ > r_ and g_ > b_ or (v > 0.95 and sat < 0.08):
                a[y, x, 3] = 0                            # (A's grass, its white ground)
            elif sat > 0.45 and (h < 0.05 or h > 0.95):
                a[y, x, :3] = np.array(colorsys.hsv_to_rgb(0.075, sat, min(1.0, v * 1.05))) * 255   # (red to orange)
    sock = Image.fromarray(a.astype(np.uint8))
    sock = sock.crop(opaque_box(sock))
    save("windsock", pixelate(sock, (round(sock.width * SOCK_H / sock.height), SOCK_H), 10))
    print("  platform, windsock")


## The start runway (round 5: the designer's deck, no cloud, sat here on the drifting clouds like the stands): the
## deck PLATFORM_W game px long, big clouds behind and under it, small puffs over its front edge, cut so the checkered
## line's middle is the picture's middle (SkyDock draws it on the start line); "e" as painted (the plane flying right),
## "w" mirrored (flying left: the user, one way or the other). The windsock's 4 frames on one shared canvas (the pole fixed)
RUNWAY_SRC = SKY / "platform_sources"
RUNWAY_LINE = (1029, 575)              # the checkered line's middle on the deck's painting (source px)
PLATFORM_W = 114                       # (10% over the former pad: the user)
PLATFORM_H = 110                       # (the former pad's size and 10%, the user: 94 deep on top plus its front face)
SOCK_FRAMES_H = 24                     # game px, the pole and all


def runway():
    import random
    rnd = random.Random(7)
    im = Image.open(RUNWAY_SRC / "runway_deck_source.png").convert("RGBA")
    box = opaque_box(im)
    deck = pixelate(im.crop(box), (PLATFORM_W, PLATFORM_H), 14)
    dh, dw = deck.shape[:2]
    lx = (RUNWAY_LINE[0] - box[0]) * PLATFORM_W / (box[2] - box[0])   # the line in deck px
    ly = (RUNWAY_LINE[1] - box[1]) * PLATFORM_H / (box[3] - box[1])
    mx, mt, mb = 56, 26, 46                               # the clouds' room round the deck
    cw, ch = dw + 2 * mx, dh + mt + mb
    canvas = np.zeros((ch, cw, 4), np.uint8)
    # behind and under it: big ones along it, lower than its middle (it sits on them), one at each end
    # (at the stands' clouds' scale, the user)
    for i in range(3):
        x = mx + dw * (i + 0.5) / 3 + rnd.uniform(-8, 8)
        paste(canvas, drift_cloud(rnd.choice(DRIFT), rnd.randint(90, 130)), x, mt + dh * 0.75 + rnd.uniform(-4, 10))
    for x in (mx - 6, mx + dw + 6):
        paste(canvas, drift_cloud(rnd.choice(DRIFT), rnd.randint(90, 110)), x, mt + dh * 0.5)
    dm = deck[..., 3] > 0
    canvas[mt:mt + dh, mx:mx + dw][dm] = deck[dm]
    # a few puffs over its front edge
    for i in range(3):
        x = mx + dw * (i + 0.5) / 3 + rnd.uniform(-10, 10)
        paste(canvas, drift_cloud(rnd.choice(DRIFT_SMALL), rnd.randint(36, 56)), x, mt + dh + rnd.uniform(4, 12))
    # cut so the line's middle is the middle
    px, py = mx + lx, mt + ly
    rx = int(np.ceil(max(px, cw - px)))
    ry = int(np.ceil(max(py, ch - py)))
    out = np.zeros((2 * ry, 2 * rx, 4), np.uint8)
    ox, oy = int(round(rx - px)), int(round(ry - py))
    out[oy:oy + ch, ox:ox + cw] = canvas
    save("platform_e", out)
    save("platform_w", out[:, ::-1].copy())
    # the windsock: one box round all four frames, the same for each (the pole stays put)
    frames = [Image.open(RUNWAY_SRC / f"windsock_{i}_source.png").convert("RGBA") for i in range(4)]
    boxes = [opaque_box(f) for f in frames]
    u = (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))
    kh = (u[3] - u[1]) / SOCK_FRAMES_H
    for i, f in enumerate(frames):
        save(f"windsock_{i}", pixelate(f.crop(u), (round((u[2] - u[0]) / kh), SOCK_FRAMES_H), 10))
    print("  runway, windsock")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    if "--runway" in sys.argv:
        runway()
        return
    if "--platform" in sys.argv:
        platform()
        return
    if "--stand-drift" in sys.argv:
        stand_clouds_from_drift()
        return
    if "--things" in sys.argv:
        sky_things()
        return
    if "--fields" in sys.argv:
        fields()
        ground_pieces()
        return
    rings()
    for view in ("front", "back", "side_l", "side_r"):
        cloud(view)
    fields()
    ground_pieces()
    print("written to", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
