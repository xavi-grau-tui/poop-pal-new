"""The dress-ups' pixel-art brief sheet (2026-11-07): floaters, under items and head items, all drawn
as native pixel art on the spirits' own grid.

Round 1 of the dress-ups (docs/mockups/spirits/dressup/) was painted at painting resolution and shrunk
~4x: at game size it went flat and off-style (the user). The spirits are pixel art, 4 x 4 sheet px a
game pixel, so here every reference spirit is its real sprite enlarged 4x pixel for pixel, the zone
where the item goes is drawn with the game-pixel grid in it, and the designer draws on that grid:

  FLOATERS  hover over the head, never touch it; drawn once, moved by code (bob, drift, orbit, sway,
            glow); up to 3 frames only where the shape changes. On the small spirit.
  UNDER     sit under the spirit (cushion, ring, leaf), following its width: one per size, small /
            medium / large (inari, glazy, frog_king). The swim ring in two halves (back, front).
  HEAD      worn on top or at the side of the head, never over the face: a small and a large size
            (inari, glazy); code places them on each spirit's head (spirits whose top is a feature,
            a flame or a crown, don't wear them).

    .venv/bin/python tools/art/dressup_pixel_template.py
        -> docs/mockups/spirits/dressup_pixel_brief/dressup_pixel_sheet.png (to draw on)
           and dressup_pixel_guide.png (the same, labelled)
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from october_sheet_cut import SP  # noqa: E402

OUT = SP / "dressup_pixel_brief"
K = 4                         # sheet px per game px
G = 64                        # a cell's canvas in game px (the 56 sprite canvas with room round it)
OFF = (4, 2)                  # where the 56 canvas sits in it
CELL = G * K
BG = (254, 253, 245)          # the October sheets' paper
REF = {"S": "october_fox/px/inari.png", "M": "october_moon/px/glazy.png", "L": "october_river/px/frog_king.png"}

FLOAT = [  # (item, the unlock it takes over, frames, how code moves it)
    ("hitodama wisp", "headlamp", 3, "flicker drawn; code bob + glow"),
    ("taketombo", "propeller cap", 3, "spin drawn; code hover"),
    ("music notes, a pair", "headphones", 1, "code rise + fade"),
    ("goldfish in a bubble", "snorkel", 3, "tail flap drawn; code orbit"),
    ("paper crane", "round glasses", 3, "wing flap drawn; code drift"),
    ("chochin lantern", "explorer hat", 1, "code sway + glow pulse"),
    ("pennant flag", "racing helmet", 3, "wave drawn; code hover"),
    ("gunbai fan", "referee hat", 1, "code rock"),
    ("pinwheel", "hard hat", 3, "spin drawn; code hover"),
    ("spinning top", "hachimaki", 3, "spin drawn; code wobble"),
    ("suzu bell", "scarf", 1, "code swing + sparkle"),
    ("shimenawa halo", "sumo topknot", 3, "slow turn drawn; code hover"),
    ("sakura petals, three", "new", 3, "tumble drawn; code drift down"),
]
UNDER = ["zabuton cushion", "lotus leaf", "swim ring: BACK half", "swim ring: FRONT half", "straw dohyo ring"]
HEAD = [("kitsune mask, worn at the side", "Tomopedia, 30 spirits"), ("sugegasa straw hat", "Paper Sumo secret"),
        ("kanzashi flower hairpin", "Lucky Pinch"), ("oni horns", "Top Spin secret")]


def font(size):
    for f in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/System/Library/Fonts/Helvetica.ttc"):
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            pass
    return ImageFont.load_default()


def zone_for(kind, bbox):
    """the item's zone in cell game px (x0, y0, x1, y1), from the sprite's bbox on its 56 canvas"""
    x0, y0, x1, y1 = (v + o for v, o in zip(bbox, OFF * 2))
    cx = (x0 + x1) // 2
    if kind == "float":
        return cx - 9, y0 - 19, cx + 9, y0 - 3              # 18 x 16, 3 px over the head
    if kind == "under":
        return x0 - 4, y1 - 6, x1 + 4, min(G, y1 + 4)       # round the base, 4 px past each side
    return x0 - 3, y0 - 12, x1 + 3, y0 + 5                  # head: on top, overlapping its crown


def cell(ref, kind, live=True):
    c = Image.new("RGB", (CELL, CELL), BG)
    big = ref.resize((56 * K, 56 * K), Image.NEAREST)
    d = ImageDraw.Draw(c)
    x0, y0, x1, y1 = (v * K for v in zone_for(kind, ref.getbbox()))
    for x in range(x0, x1 + 1, K):
        d.line([(x, y0), (x, y1)], fill=(234, 229, 218))
    for y in range(y0, y1 + 1, K):
        d.line([(x0, y), (x1, y)], fill=(234, 229, 218))
    for i in range(x0, x1, 8):
        d.line([(i, y0), (min(i + 4, x1), y0)], fill=(205, 120, 120))
        d.line([(i, y1), (min(i + 4, x1), y1)], fill=(205, 120, 120))
    for i in range(y0, y1, 8):
        d.line([(x0, i), (x0, min(i + 4, y1))], fill=(205, 120, 120))
        d.line([(x1, i), (x1, min(i + 4, y1))], fill=(205, 120, 120))
    if not live:
        d.line([(x0, y0), (x1, y1)], fill=(220, 210, 200))
        d.line([(x0, y1), (x1, y0)], fill=(220, 210, 200))
    c.paste(big, (OFF[0] * K, OFF[1] * K), big)          # the spirit over the zone's grid
    return c


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    refs = {k: Image.open(SP / p).convert("RGBA") for k, p in REF.items()}
    rows = []  # (section, label, sub, [cells])
    for name, old, n, how in FLOAT:
        rows.append(("FLOATERS", name, f"takes over: {old} · {n} frame{'s' if n > 1 else ''}: {how}",
                     [cell(refs["S"], "float", c < n) for c in range(3)]))
    for name in UNDER:
        rows.append(("UNDER", name, "one per size: small / medium / large", [cell(refs[k], "under") for k in "SML"]))
    for name, src in HEAD:
        rows.append(("HEAD", name, f"small / large (code fits it to each head) · from: {src}",
                     [cell(refs["S"], "head"), cell(refs["M"], "head"), cell(refs["M"], "head", False)]))
    sheet = Image.new("RGB", (3 * CELL, len(rows) * CELL), BG)
    for r, (_, _, _, cells) in enumerate(rows):
        for c, im in enumerate(cells):
            sheet.paste(im, (c * CELL, r * CELL))
    sheet.save(OUT / "dressup_pixel_sheet.png")
    lw = 620
    guide = Image.new("RGB", (lw + 3 * CELL, len(rows) * CELL + 130), (34, 28, 34))
    guide.paste(sheet, (lw, 130))
    d = ImageDraw.Draw(guide)
    d.text((16, 12), "Dress-ups as pixel art: 4 x 4 sheet px = 1 game pixel, exactly like the spirits. Draw inside the dashed zones.",
           fill=(245, 236, 226), font=font(24))
    d.text((16, 50), "1 px plum outline, 3-4 tones + one highlight, lit top left, the October spirits' soft gloss, chunky shapes.",
           fill=(220, 206, 196), font=font(19))
    d.text((16, 80), "Crossed zones: nothing to draw. Every 4 x 4 block one flat colour (shrink 4x and enlarge 4x: no change).",
           fill=(220, 206, 196), font=font(19))
    last = None
    for r, (sec, name, sub, _) in enumerate(rows):
        y = 130 + r * CELL
        if sec != last:
            d.rectangle([0, y, lw - 8, y + 34], fill=(120, 60, 50))
            d.text((16, y + 5), sec, fill=(255, 240, 225), font=font(22))
            last = sec
        d.text((16, y + 80), f"{r + 1}. {name}", fill=(255, 244, 232), font=font(26))
        for i, line in enumerate(sub.split(" · ")):
            d.text((16, y + 120 + i * 28), line, fill=(200, 186, 180), font=font(19))
    guide.save(OUT / "dressup_pixel_guide.png")
    json.dump([[r[0], r[1]] for r in rows], open(OUT / "rows.json", "w"), indent=1)
    print(OUT, sheet.size, len(rows), "rows")


if __name__ == "__main__":
    main()
