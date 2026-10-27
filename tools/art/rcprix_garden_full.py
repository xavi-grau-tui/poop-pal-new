"""Generate the RC Prix Garden handoff art at the template's exact pixel sizes.

This is a geometry-first pass. All shapes are rasterised directly on the target
pixel grid with binary alpha. Run from the repository root with Pillow installed.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

from rcprix_templates import (CURB, FRAME, GROUND, OVERLAYS, ROAD,
                              ROAD_HALF, ROAD_HALF_WIDE, SIDE, SPRITES, SQ,
                              SIZES)
from rcprix_garden_pilot import road_coordinates
from rcprix_round2_sample import (ASPHALT, ASPHALT_LIT, ASPHALT_SHADE, CURB_LINE,
                                  DASH, GRAIN_DARK, GRAIN_LIT, GRASS, GRASS_LIT,
                                  GRASS_MID, GRASS_SHADE, PLUM, RED, RED_LIT,
                                  SIDE_DARK, SIDE_LIT, WHITE, WHITE_SHADE)

OUT = Path(__file__).resolve().parents[2] / "textures/minigames/rcprix/garden"
TRANSPARENT = (0, 0, 0, 0)
ORANGE = (225, 133, 48, 255)
WOOD = (165, 101, 56, 255)
WOOD_LIT = (207, 149, 81, 255)
WOOD_DARK = (105, 59, 44, 255)
GREEN_DARK = (43, 95, 50, 255)
GREEN_MID = (64, 129, 56, 255)
GREEN_LIT = (132, 187, 75, 255)
PINK = (244, 177, 169, 255)
GOLD = (250, 201, 74, 255)
TYRE = (49, 47, 58, 255)
TYRE_LIGHT = (91, 88, 102, 255)


def blank(size=(SQ, SQ)):
    return Image.new("RGBA", size, TRANSPARENT)


def road_color(offset, progress, half, corner):
    away = abs(offset)
    length = SQ * math.pi / 4 if corner else SQ
    if away >= half - 1:
        return PLUM
    if away >= half - CURB:
        outer = offset > 0
        radius = SQ / 2 + (half - CURB / 2) * (1 if outer else -1)
        stripe_length = (radius * math.pi / 2 / (20 if outer else 8)) if corner else 10
        curb_progress = min(progress, length - 1e-6) * radius / (SQ / 2) if corner else progress
        white = int(curb_progress // stripe_length) % 2 == 1
        return (WHITE_SHADE if away >= half - 2 else WHITE) if white else (RED if away >= half - 2 else RED_LIT)
    if away >= half - CURB - 1:
        return CURB_LINE
    if away >= half - CURB - 5:
        return ASPHALT_SHADE
    dash_period = length / (5 if corner else 6)
    if away < 1.8 and abs(progress % dash_period - dash_period / 2) < 5:
        return DASH
    if away < 17:
        return ASPHALT_LIT
    if away < 29:
        return ASPHALT_SHADE
    return ASPHALT


def top(name, x, y, half):
    offset, _ = road_coordinates(name, x, y)
    return abs(offset) < half


def side_color(name, x, y, half):
    if not top(name, x, y - SIDE, half):
        return None
    depth = next((up for up in range(1, SIDE + 1) if top(name, x, y - up, half)), 0)
    if depth == SIDE:
        return PLUM
    return SIDE_LIT if depth <= 5 else SIDE_DARK


def road_piece(name, half):
    base = name.replace("gap_h", "straight_h").replace("gap_v", "straight_v")
    corner = base.startswith("corner_")
    gap = name.startswith("gap_")
    im = blank()
    pix = im.load()
    for y in range(SQ):
        for x in range(SQ):
            offset, progress = road_coordinates(base, x, y)
            in_gap = gap and 60 <= progress < 120
            if in_gap:
                continue
            side = side_color(base, x, y, half)
            if corner and y == (0 if name[-2] == "n" else SQ - 1):
                side = None
            if side is not None:
                pix[x, y] = side
            if abs(offset) < half:
                pix[x, y] = road_color(offset, progress, half, corner)
                if gap and progress in (59.5, 120.5):
                    pix[x, y] = PLUM if abs(offset) > half - CURB - 2 else WOOD_DARK
    # Sparse repeatable flecks, entirely inside the asphalt.
    rng = random.Random(100 + sum(map(ord, name)) + half)
    for _ in range(32):
        x, y = rng.randrange(SQ), rng.randrange(SQ)
        if pix[x, y] in (ASPHALT, ASPHALT_LIT, ASPHALT_SHADE):
            pix[x, y] = GRAIN_LIT if rng.randrange(2) else GRAIN_DARK
    if gap:
        d = ImageDraw.Draw(im)
        if name == "gap_h":
            for edge in (59, 120):
                d.line((edge, SQ // 2 - half + 2, edge, SQ // 2 + half - 2), fill=PLUM, width=2)
                d.line((edge + (2 if edge == 59 else -2), SQ // 2 - half + 8,
                        edge + (2 if edge == 59 else -2), SQ // 2 + half - 8), fill=SIDE_LIT, width=2)
        else:
            for edge in (59, 120):
                d.line((SQ // 2 - half + 2, edge, SQ // 2 + half - 2, edge), fill=PLUM, width=2)
                d.line((SQ // 2 - half + 8, edge + (2 if edge == 59 else -2),
                        SQ // 2 + half - 8, edge + (2 if edge == 59 else -2)), fill=SIDE_LIT, width=2)
    return im


def grass_tile(index):
    im = Image.new("RGBA", (SQ, SQ), GRASS)
    d = ImageDraw.Draw(im)
    rng = random.Random(902 + 307 * index)
    # Keep the outer 10px clear so any A/B/C neighbour meets without a seam.
    for i in range(5 + index):
        x, y = rng.randrange(19, 160), rng.randrange(19, 160)
        rx, ry = (rng.randrange(10, 15), rng.randrange(6, 10)) if i == 0 else (rng.randrange(3, 8), rng.randrange(2, 6))
        col = (109, 174, 70, 255) if i == 0 else ((139, 199, 77, 255) if i % 2 else (117, 183, 70, 255))
        d.polygon([(x-rx, y), (x-rx+4, y-ry+2), (x+2, y-ry),
                   (x+rx, y-2), (x+rx-3, y+ry), (x-4, y+ry-2)], fill=col)
    for _ in range(10 + index * 3):
        x, y = rng.randrange(15, 165), rng.randrange(15, 165)
        d.rectangle((x+2, y+2, x+4, y+3), fill=GRASS_SHADE)
        d.rectangle((x, y, x+2, y+1), fill=GRASS_LIT)
    x, y = ((39, 122), (126, 45), (93, 143))[index]
    for dx, dy in ((-5, 0), (4, -3), (5, 5), (-2, 6)):
        d.rectangle((x+dx, y+dy, x+dx+2, y+dy+2), fill=WHITE if dx < 0 else PINK)
    d.rectangle((x, y+2, x+2, y+4), fill=GOLD)
    return im


def overlay(name, half):
    im = blank()
    d = ImageDraw.Draw(im)
    vertical = name.endswith(("_n", "_s", "_v"))
    if name.startswith("start_"):
        for across in range(-half + CURB + 2, half - CURB - 1, 8):
            for along in range(82, 98, 8):
                col = WHITE if ((across // 8 + along // 8) % 2) else PLUM
                box = (SQ//2+across, along, SQ//2+across+7, along+7) if vertical else (along, SQ//2+across, along+7, SQ//2+across+7)
                d.rectangle(box, fill=col)
        return im
    if name.startswith("boost_"):
        direction = name[-1]
        a = SQ//2
        span = half - CURB - 2
        def point(t, u):
            return {"e": (a+t, a+u), "w": (a-t, a+u),
                    "s": (a+u, a+t), "n": (a+u, a-t)}[direction]
        # One 32px-long pad, extending from one inner curb to the other.
        outline = [point(t, u) for t, u in ((-16,-span),(15,-span),(15,span),(-16,span))]
        d.polygon(outline, fill=PLUM)
        inset = [point(t, u) for t, u in ((-14,-span+2),(13,-span+2),(13,span-2),(-14,span-2))]
        d.polygon(inset, fill=GOLD)
        for t in (-8, 4):
            d.line([point(t-6,-span+5), point(t+5,0), point(t-6,span-5)], fill=PLUM, width=5, joint="curve")
        d.line([point(-13,-span+3), point(12,-span+3)], fill=WHITE, width=2)
        return im
    if name.startswith("ramp_"):
        direction = name[-1]
        a = SQ//2
        span = half - CURB - 2
        def point(t, u):
            return {"e": (a+t, a+u), "w": (a-t, a+u),
                    "s": (a+u, a+t), "n": (a+u, a-t)}[direction]
        # Cool steel, full width, with broad tones progressing from toe to
        # raised lip in the car's direction. Distinct from the wooden crate.
        ramp_dark = (58, 95, 111, 255)
        ramp_mid = (91, 150, 163, 255)
        ramp_lit = (145, 207, 206, 255)
        d.polygon([point(t,u) for t,u in ((-20,-span),(19,-span),(19,span),(-20,span))], fill=PLUM)
        for t0, t1, col in ((-18,-6,ramp_dark),(-6,8,ramp_mid),(8,17,ramp_lit)):
            d.polygon([point(t,u) for t,u in ((t0,-span+2),(t1,-span+2),(t1,span-2),(t0,span-2))], fill=col)
        d.line([point(17,-span+1), point(17,span-1)], fill=WHITE, width=3)
        d.line([point(-18,-span+2), point(15,-span+2)], fill=(187, 228, 224, 255), width=2)
        return im
    # A continuous backing and two close, staggered rows of touching tyres.
    corner = name[-2:]
    cx = SQ if corner[1] == "e" else 0
    cy = 0 if corner[0] == "n" else SQ
    sx = -1 if cx else 1
    sy = 1 if cy == 0 else -1
    def on_arc(theta, radius):
        return (round(cx + sx * radius * math.cos(theta)),
                round(cy + sy * radius * math.sin(theta)))
    d.line([on_arc(i*math.pi/96, SQ/2+half+12) for i in range(49)], fill=PLUM, width=21, joint="curve")
    for row, radial in ((0, 18), (1, 6)):
        for i in range(20):
            theta = (i + (0.5 if row == 0 else 0.95)) * math.pi / 40
            x, y = on_arc(theta, SQ/2+half+radial)
            d.ellipse((x-8, y-7, x+8, y+7), fill=PLUM)
            d.ellipse((x-6, y-5, x+6, y+5), fill=TYRE)
            d.arc((x-5, y-4, x+5, y+3), 190, 335, fill=TYRE_LIGHT, width=2)
            d.ellipse((x-2, y-2, x+2, y+2), fill=PLUM)
    return im


def outlined_polygon(d, points, fill, outline=PLUM, width=1):
    d.polygon(points, fill=fill)
    d.line(points + [points[0]], fill=outline, width=width, joint="curve")


def make_car_slice(index):
    im = blank((44, 32))
    d = ImageDraw.Draw(im)
    # Slice roles: 1–2 chassis/wheels, 3–4 body, 5 cabin, 6 lit roof rim.
    # Each is full brightness; the renderer darkens lower slices when stacked.
    body = (195, 52, 48, 255)
    body_lit = (250, 99, 65, 255)
    if index <= 1:
        d.rounded_rectangle((1, 5, 42, 26), radius=7, fill=PLUM)
        for box in ((3, 2, 11, 10), (32, 2, 40, 10), (3, 21, 11, 29), (32, 21, 40, 29)):
            d.rectangle(box, fill=PLUM)
            d.rectangle((box[0]+2, box[1]+2, box[2]-2, box[3]-2), fill=TYRE_LIGHT)
        d.rounded_rectangle((8, 8, 37, 23), radius=5, fill=WOOD_DARK)
        d.rectangle((14, 12, 28, 19), fill=TYRE)
        if index == 1:
            d.line((10, 10, 35, 10), fill=TYRE_LIGHT, width=2)
    elif index <= 3:
        d.rounded_rectangle((6, 6, 39, 25), radius=7, fill=body, outline=PLUM)
        d.polygon([(11, 8), (31, 8), (37, 13), (12, 13)], fill=body_lit)
        d.rectangle((36, 11, 40, 20), fill=GOLD)
        d.rectangle((6, 12, 8, 19), fill=WHITE_SHADE)
        if index == 3:
            d.line((11, 23, 32, 23), fill=(148, 36, 41, 255), width=2)
    elif index == 4:
        d.rounded_rectangle((12, 7, 33, 24), radius=5, fill=body_lit, outline=PLUM)
        d.polygon([(17, 15), (29, 15), (31, 21), (17, 21)], fill=(127, 202, 207, 255))
        d.line((17, 15, 29, 15), fill=WHITE, width=2)
    else:
        d.arc((13, 7, 32, 23), 178, 362, fill=WHITE, width=3)
        d.line((16, 8, 28, 8), fill=(255, 217, 161, 255), width=2)
    return im


def small_sprite(name, size):
    if name.startswith("car_slice_"):
        return make_car_slice(int(name[-1]))
    im = blank(size)
    d = ImageDraw.Draw(im)
    w, h = size
    if name == "crate":
        d.rectangle((1, 2, w-2, h-2), fill=WOOD_DARK, outline=PLUM)
        d.rectangle((3, 4, w-4, h-4), fill=WOOD, outline=WOOD_LIT)
        d.line((4, 4, w-5, h-5), fill=WOOD_DARK, width=2)
        d.line((w-5, 4, 4, h-5), fill=WOOD_DARK, width=2)
    elif name == "lamp_post":
        d.rectangle((4, 7, 6, 17), fill=WOOD_DARK)
        d.rectangle((1, 3, 9, 9), fill=PLUM)
        d.rectangle((2, 4, 8, 7), fill=GOLD)
        d.rectangle((3, 1, 7, 3), fill=PLUM)
    elif name == "start_lamp":
        d.ellipse((3, 3, 28, 28), fill=(88, 88, 92, 255), outline=PLUM, width=2)
        d.ellipse((6, 6, 25, 25), fill=(229, 230, 229, 255))
        d.arc((8, 8, 23, 22), 195, 300, fill=WHITE, width=3)
        d.arc((8, 8, 24, 24), 5, 80, fill=(172, 174, 177, 255), width=2)
    elif name == "spring":
        for i in range(4):
            x = 2 + i*5
            d.line([(x, 11), (x+2, 3), (x+5, 11)], fill=PLUM, width=3)
            d.line([(x+1, 9), (x+2, 5), (x+4, 9)], fill=WHITE_SHADE, width=1)
    elif name == "balloon":
        d.ellipse((2, 1, 15, 17), fill=RED, outline=PLUM, width=2)
        d.arc((4, 3, 11, 12), 180, 285, fill=PINK, width=2)
        d.polygon([(7, 17), (11, 17), (9, 20)], fill=PLUM)
        d.line((9, 20, 8, 25), fill=WOOD_DARK, width=1)
    elif name == "sparkle":
        d.polygon([(9, 0), (11, 6), (17, 9), (11, 11), (9, 17), (7, 11), (0, 9), (7, 6)], fill=GOLD, outline=PLUM)
        d.rectangle((8, 4, 9, 8), fill=WHITE)
    elif name == "helmet":
        d.pieslice((1, 1, 14, 14), 180, 360, fill=RED, outline=PLUM, width=2)
        d.rectangle((2, 7, 13, 11), fill=RED, outline=PLUM)
        d.rectangle((3, 8, 10, 10), fill=WHITE_SHADE)
    elif name.startswith("bush_"):
        d.ellipse((2, h//3, w-3, h-2), fill=GREEN_DARK, outline=PLUM)
        for x, y, r in ((w//4, h//2, 9), (w//2, h//3, 12), (w*3//4, h//2, 8)):
            d.ellipse((x-r, y-r, x+r, y+r), fill=GREEN_MID, outline=GREEN_DARK)
            d.polygon([(x-r//2, y-r+2), (x+3, y-r+1), (x+r//2, y-2), (x-3, y)], fill=GREEN_LIT)
        d.line((5, h-5, w-6, h-5), fill=PLUM, width=2)
    elif name.startswith("flowers_"):
        rng = random.Random(11 if name.endswith("a") else 29)
        for cx, cy in ((4, 7), (11, 4), (12, 10)):
            for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2)):
                d.rectangle((cx+dx, cy+dy, cx+dx+1, cy+dy+1), fill=WHITE if rng.randrange(2) else PINK)
            d.rectangle((cx, cy, cx+1, cy+1), fill=GOLD)
            d.point((cx, min(h-1, cy+4)), fill=GREEN_DARK)
    return im


def frame_piece(name, size):
    im = blank(size)
    d = ImageDraw.Draw(im)
    w, h = size
    d.rectangle((0, 0, w-1, h-1), fill=WOOD)
    if name.startswith("frame_corner"):
        d.rectangle((0, 0, w-1, h-1), outline=PLUM, width=2)
        d.rectangle((4, 4, w-5, h-5), fill=WOOD_LIT, outline=WOOD_DARK)
        d.rectangle((8, 8, 11, 11), fill=GOLD)
    elif name.endswith(("top", "bottom")):
        d.line((0, 1, w-1, 1), fill=PLUM, width=2)
        d.line((0, 4, w-1, 4), fill=WOOD_LIT, width=3)
        d.line((0, h-2, w-1, h-2), fill=PLUM, width=2)
        for x in range(25, w, 45):
            d.rectangle((x, 8, x+6, 10), fill=WOOD_DARK)
            d.rectangle((x+2, 9, x+4, 10), fill=GOLD)
    else:
        d.line((1, 0, 1, h-1), fill=PLUM, width=2)
        d.line((4, 0, 4, h-1), fill=WOOD_LIT, width=3)
        d.line((w-2, 0, w-2, h-1), fill=PLUM, width=2)
        for y in range(25, h, 45):
            d.rectangle((8, y, 10, y+6), fill=WOOD_DARK)
    return im


def tree_piece(name, size):
    im = blank(size)
    d = ImageDraw.Draw(im)
    w, h = size
    rng = random.Random(50 + sum(map(ord, name)))
    horizontal = name.endswith(("top", "bottom"))
    for _ in range(19):
        if horizontal:
            x = rng.randrange(-15, w+15)
            y = rng.randrange(-20, 55) if name.endswith("top") else rng.randrange(h-55, h+20)
        else:
            x = rng.randrange(-20, 55) if name.endswith("left") else rng.randrange(w-55, w+20)
            y = rng.randrange(-15, h+15)
        r = rng.randrange(15, 25)
        d.ellipse((x-r, y-r, x+r, y+r), fill=GREEN_DARK, outline=PLUM)
        d.ellipse((x-r+3, y-r+2, x+r-3, y+r-5), fill=GREEN_MID)
        d.polygon([(x-r+5, y-r+7), (x, y-r+1), (x+r-6, y-r+7), (x+5, y-3)], fill=GREEN_LIT)
    return im


def generate():
    OUT.mkdir(parents=True, exist_ok=True)
    # 1. Existing nine pieces (six road, three grass).
    for name, _ in ROAD[:6]:
        road_piece(name, ROAD_HALF).save(OUT / f"{name}.png")
    for i, (name, _) in enumerate(GROUND):
        grass_tile(i).save(OUT / f"{name}.png")
    # 2. Full wide road set, then 3. narrow gaps and overlays in both widths.
    for name, _ in ROAD:
        road_piece(name, ROAD_HALF_WIDE).save(OUT / f"{name}_wide.png")
    for name, _ in ROAD[6:]:
        road_piece(name, ROAD_HALF).save(OUT / f"{name}.png")
    for half, suffix in ((ROAD_HALF, ""), (ROAD_HALF_WIDE, "_wide")):
        for name, _ in OVERLAYS:
            overlay(name, half).save(OUT / f"{name}{suffix}.png")
    # 4. Sprites, decor and frame.
    for name, _, w, h in SPRITES:
        size = (w, h)
        if name.startswith("frame_"):
            im = frame_piece(name, size)
        elif name.startswith("tree_"):
            im = tree_piece(name, size)
        else:
            im = small_sprite(name, size)
        im.save(OUT / f"{name}.png")
    # Review sheet for the layered car, which the course preview does not draw.
    review = Path(__file__).resolve().parents[2] / "docs/mockups/rcprix_garden/car_slices_preview.png"
    sheet = Image.new("RGBA", (7*56, 48), (125, 191, 71, 255))
    stack = blank((44, 32))
    for i in range(6):
        slice_image = make_car_slice(i)
        sheet.alpha_composite(slice_image, (i*56+6, 8))
        stack.alpha_composite(slice_image)
    sheet.alpha_composite(stack, (6*56+6, 8))
    sheet.resize((sheet.width*3, sheet.height*3), Image.Resampling.NEAREST).save(review)
    print(f"saved {len(SIZES)} Garden assets to {OUT}")


if __name__ == "__main__":
    generate()
