"""RC Prix's art kit for the designer (the user, 2026-10-26: new, smoother graphics for the Garden):
the template sheets with guides, one box per file to draw, at its exact size (docs/mockups/rcprix_garden/BRIEF.md).

    <python with Pillow> tools/art/rcprix_templates.py   -> docs/mockups/rcprix_garden/templates/

The kit is drawn at twice the game's current density (ART_PX): a course square is SQ px, each art px 2 world px.
The road's geometry (ROAD_HALF, CURB, SIDE) is what makes the pieces join up, so the guides show it exactly."""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "mockups" / "rcprix_garden" / "templates"
ART_PX = 2                    # world px per art px (the game now: 4)
SQ = 360 // ART_PX            # a course square (rc_racer.gd CELLS["car"] = 360 world px)
ROAD_HALF = 44                # the road's half width, curbs included (art px): a world's later levels
ROAD_HALF_WIDE = 50           # ...and its early ones (the user, 2026-10-27: two widths per world; Garden 1-4),
WIDE = "_wide"                # the same pieces again under these names
CURB = 6                      # the curb band along each edge
SIDE = 12                     # the raised track's side face, under its south edge
FRAME = 20                    # the board's wooden frame

GUIDE = {"box": (60, 60, 70), "road": (232, 64, 160), "curb": (40, 150, 230), "side": (240, 150, 40), "mid": (120, 120, 130)}

ROAD = [   # file, label
    ("straight_h", "Straight, across"), ("straight_v", "Straight, up/down"),
    ("corner_ne", "Corner N-E"), ("corner_nw", "Corner N-W"), ("corner_se", "Corner S-E"), ("corner_sw", "Corner S-W"),
    ("gap_h", "Jump gap, across"), ("gap_v", "Jump gap, up/down"),
]
OVERLAYS = [
    ("start_h", "Start line, across"), ("start_v", "Start line, up/down"),
    ("boost_e", "Boost pad → east"), ("boost_w", "Boost pad → west"), ("boost_n", "Boost pad → north"), ("boost_s", "Boost pad → south"),
    ("ramp_e", "Ramp → east"), ("ramp_w", "Ramp → west"), ("ramp_n", "Ramp → north"), ("ramp_s", "Ramp → south"),
    ("tyres_ne", "Tyre wall, corner N-E"), ("tyres_nw", "Tyre wall, corner N-W"), ("tyres_se", "Tyre wall, corner S-E"), ("tyres_sw", "Tyre wall, corner S-W"),
]
GROUND = [("grass_a", "Grass A (seamless)"), ("grass_b", "Grass B (seamless)"), ("grass_c", "Grass C (seamless)")]
SPRITES = [   # file, label, w, h
    *[(f"car_slice_{i}", f"Car slice {i + 1}", 44, 32) for i in range(6)],
    ("crate", "Crate", 20, 20), ("lamp_post", "Lamp post", 10, 18), ("start_lamp", "Start lamp", 32, 32),
    ("spring", "Spring", 24, 14), ("balloon", "Balloon", 18, 26), ("sparkle", "Sparkle", 18, 18), ("helmet", "Helmet", 16, 14),
    ("bush_a", "Bush A", 40, 36), ("bush_b", "Bush B", 32, 28), ("flowers_a", "Flowers A", 16, 12), ("flowers_b", "Flowers B", 16, 12),
    ("frame_corner_tl", "Frame corner TL", FRAME, FRAME), ("frame_corner_tr", "Frame corner TR", FRAME, FRAME),
    ("frame_corner_bl", "Frame corner BL", FRAME, FRAME), ("frame_corner_br", "Frame corner BR", FRAME, FRAME),
    ("frame_top", "Frame top", SQ, FRAME), ("frame_bottom", "Frame bottom", SQ, FRAME),
    ("frame_left", "Frame left", FRAME, SQ), ("frame_right", "Frame right", FRAME, SQ),
    ("tree_top", "Tree over top edge", 200, 110), ("tree_bottom", "Tree over bottom edge", 200, 110),
    ("tree_left", "Tree over left edge", 110, 200), ("tree_right", "Tree over right edge", 110, 200),
]
ROAD_WIDE = [(n + WIDE, lab + " (wide)") for n, lab in ROAD]
OVERLAYS_WIDE = [(n + WIDE, lab + " (wide)") for n, lab in OVERLAYS]
# every file and its size, for tools/art/check_rcprix_art.py
SIZES = {n: (SQ, SQ) for n, _ in ROAD + OVERLAYS + ROAD_WIDE + OVERLAYS_WIDE + GROUND} | {n: (w, h) for n, _, w, h in SPRITES}


def _font(size, bold=False):
    try:
        return ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial%s.ttf" % (" Bold" if bold else ""), size)
    except OSError:
        return ImageFont.load_default()


def road_guides(d, ox, oy, name, k):
    """The road's bands in one square: its edges, curbs and (on a south-facing edge) its side face"""
    half = ROAD_HALF_WIDE if name.endswith(WIDE) else ROAD_HALF
    name = name.removesuffix(WIDE)
    c = SQ / 2
    P = lambda x, y: (ox + x * k, oy + y * k)
    if name in ("straight_h", "gap_h", "start_h") or name[:-2] in ("boost", "ramp") and name[-1] in "ew":
        for y, col in ((c - half, "road"), (c + half, "road"), (c - half + CURB, "curb"), (c + half - CURB, "curb"), (c + half + SIDE, "side"), (c, "mid")):
            d.line([P(0, y), P(SQ, y)], fill=GUIDE[col], width=1)
        if name == "gap_h":
            d.rectangle([P(c - 30, c - half), P(c + 30, c + half + SIDE)], outline=GUIDE["side"])
    elif name in ("straight_v", "gap_v", "start_v") or name[:-2] in ("boost", "ramp"):
        for x, col in ((c - half, "road"), (c + half, "road"), (c - half + CURB, "curb"), (c + half - CURB, "curb"), (c, "mid")):
            d.line([P(x, 0), P(x, SQ)], fill=GUIDE[col], width=1)
        if name == "gap_v":
            d.rectangle([P(c - half, c - 30), P(c + half, c + 30)], outline=GUIDE["side"])
    else:
        # a corner: a quarter circle round the square's corner between the two edges it leaves through
        cx = SQ if name[-1] == "e" else 0
        cy = 0 if name[-2] == "n" else SQ
        a0 = {"ne": 0.5, "nw": 0.0, "se": 1.0, "sw": 1.5}[name[-2:]] * math.pi
        arc = lambda r, dy=0.0: [P(cx + r * math.cos(a0 + i * math.pi / 160), cy + r * math.sin(a0 + i * math.pi / 160) + dy) for i in range(81)]
        for r, col in ((c - half, "road"), (c + half, "road"), (c - half + CURB, "curb"), (c + half - CURB, "curb"), (c, "mid")):
            d.line(arc(r), fill=GUIDE[col], width=1)
        # its side face: under whichever edge faces south (down the screen): the outer one of a
        # corner at the top, the inner one of a corner at the bottom
        side = arc(c + half if name[-2] == "n" else c - half, SIDE)
        d.line([q for q in side if q[1] <= oy + SQ * k], fill=GUIDE["side"], width=1)
    # where it joins its neighbours: a tick at the middle of each edge it leaves through
    for e in {"straight_h": "ew", "gap_h": "ew", "start_h": "ew", "straight_v": "ns", "gap_v": "ns", "start_v": "ns"}.get(name, name[-2:] if name.startswith(("corner", "tyres")) else ("ew" if name[-1] in "ew" else "ns")):
        x, y = {"n": (c, 0), "s": (c, SQ), "e": (SQ, c), "w": (0, c)}[e]
        d.ellipse([P(x, y)[0] - 4, P(x, y)[1] - 4, P(x, y)[0] + 4, P(x, y)[1] + 4], fill=GUIDE["road"])


def sheet(title, items, k, cols, road=False):
    font, small, bold = _font(15), _font(13), _font(22, True)
    cells = [(n, lab, *(SIZES[n])) for n, lab, *_ in items]
    cw = max(w for _, _, w, _ in cells) * k + 24
    rows, x, y, rowh = [], 20, 84, 0
    placed = []
    for n, lab, w, h in cells:
        bw = max(w * k, 150) + 24
        if x + bw > cols * cw + 20:
            x, y, rowh = 20, y + rowh + 48, 0
        placed.append((n, lab, w, h, x, y))
        x += bw
        rowh = max(rowh, h * k)
    W, H = cols * cw + 40, y + rowh + 70
    im = Image.new("RGB", (W, H), (248, 245, 240))
    d = ImageDraw.Draw(im)
    d.text((20, 20), title, fill=(40, 34, 44), font=bold)
    for n, lab, w, h, x, y in placed:
        d.rectangle([x, y, x + w * k - 1, y + h * k - 1], fill=(255, 255, 255), outline=GUIDE["box"])
        if road:
            road_guides(d, x, y, n, k)
        d.text((x, y + h * k + 4), lab, fill=(40, 34, 44), font=font)
        d.text((x, y + h * k + 22), f"{n}.png · {w}×{h}", fill=(120, 110, 120), font=small)
    return im


def legend(im):
    d = ImageDraw.Draw(im)
    x = 20
    y = 52
    for key, text in (("road", "road edge + join points"), ("curb", "curb's inner edge"), ("side", "side face / gap"), ("mid", "centre")):
        d.rectangle([x, y + 4, x + 22, y + 8], fill=GUIDE[key])
        d.text((x + 28, y - 2), text, fill=(40, 34, 44), font=_font(14))
        x += 190
    return im


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    legend(sheet("Road pieces, for a world's later levels: road 88 px wide (each box one course square, 180×180, shown 2x)", ROAD, 2, 4, road=True)).save(OUT / "1_road_pieces.png")
    legend(sheet("Overlays — drawn over a road piece, transparent elsewhere (180×180, shown 2x)", OVERLAYS, 2, 4, road=True)).save(OUT / "2_overlays.png")
    legend(sheet("WIDE road pieces, for a world's early levels: road 100 px wide (180×180, shown 2x)", ROAD_WIDE, 2, 4, road=True)).save(OUT / "1b_road_pieces_wide.png")
    legend(sheet("WIDE overlays, to go on the wide road pieces (180×180, shown 2x)", OVERLAYS_WIDE, 2, 4, road=True)).save(OUT / "2b_overlays_wide.png")
    sheet("Ground — seamless squares, any one next to any other (180×180, shown 2x)", GROUND, 2, 3).save(OUT / "3_ground.png")
    sheet("Sprites, decor and the board's frame (exact sizes, shown 3x)", SPRITES, 3, 3).save(OUT / "4_sprites.png")
    print("ok", OUT, len(SIZES), "files")


if __name__ == "__main__":
    main()
