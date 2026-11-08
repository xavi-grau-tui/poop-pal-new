"""The dress-up brief's sheets (2026-11-06): the designer draws the new dress-up items at the spirits'
own sheet scale, beside real spirits, so they come out at exactly the spirits' pixel density.

The rule: nothing touches the body (the faces sit low, 4 px above the floor on the median spirit,
so anything worn round the base would cover a mouth). Every item is either UNDER the spirit (it sits
on it), FLOATING above its head, or BESIDE it.

    .venv/bin/python tools/art/dressup_template.py

Writes docs/mockups/spirits/dressup_brief/dressup_sheet.png (to draw on: one row per item, 260 px
cells, a reference spirit in each: small, medium, large for the UNDER items; the medium one for the
rest, whose three cells are the item's frames when it spins or waves), dressup_guide.png (the same,
labelled) and anim_prep/pilot_angry.png (the pilot six's base cells, a row for the angry face).

    .venv/bin/python tools/art/dressup_template.py --v2

Round 2 (2026-11-07): the BESIDE rows on the small spirit (inari, exactly 4 sheet px per art px), whose
cell leaves room for a box sized in art pixels (14 x 18); dressup_sheet_v2.png / dressup_guide_v2.png,
the guide marking which rows to keep from round 1 and which to redraw. The first sheets stay as they are.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from october_sheet_cut import CELL, SP, latest, layout  # noqa: E402

OUT = SP / "dressup_brief"
REF = {"S": ("fox", "inari"), "M": ("moon", "glazy"), "L": ("river", "frog_king")}
# (row label, family, what the three cells hold)
ROWS = [
    ("zabuton cushion", "under", "S M L"),
    ("lotus leaf", "under", "S M L"),
    ("swim ring: BACK half", "under", "S M L"),
    ("swim ring: FRONT half", "under", "S M L"),
    ("straw dohyo ring", "under", "S M L"),
    ("music notes (3 notes)", "above", "one cell"),
    ("taketombo (bamboo copter)", "above", "frames 1 2 3"),
    ("paper shide halo", "above", "one cell"),
    ("hitodama wisp", "above", "one cell"),
    ("sakura petals (2)", "above", "one cell"),
    ("suzu bell on a red cord", "beside", "one cell"),
    ("omamori charm", "beside", "one cell"),
    ("chochin lantern", "beside", "one cell"),
    ("gunbai fan", "beside", "one cell"),
    ("pinwheel", "beside", "frames 1 2 3"),
    ("spinning top", "beside", "frames 1 2 3"),
    ("checkered flag", "beside", "frames 1 2 3"),
]


# round 2: what each row needs (shown on the guide)
V2 = {1: "keep", 2: "keep, + outline", 3: "keep", 4: "keep", 5: "keep", 6: "redraw: bigger", 7: "keep",
      8: "redraw: bolder", 9: "keep", 10: "redraw: bigger"}
BESIDE_ART = (14, 18)  # the beside box in art px (w, h); the S spirit is 4 sheet px per art px


def ref_key(fam, c, v2=False):
    """Which reference spirit a cell holds: S M L for the UNDER rows, M for the rest (v2: S beside)."""
    if fam == "under":
        return "SML"[c]
    return "S" if v2 and fam == "beside" else "M"


def cell_of(realm, sid, sheets):
    cols = layout(realm)
    c, r = next((c, r) for c, col in enumerate(cols) for r, s in enumerate(col) if s == sid)
    return sheets[realm].crop((c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL))


def bbox(cell, bg):
    a = np.array(cell).astype(int)
    fg = np.abs(a - np.array(bg)).sum(2) > 45
    ys, xs = np.nonzero(fg)
    return xs.min(), ys.min(), xs.max(), ys.max()


def main(v2=False):
    OUT.mkdir(parents=True, exist_ok=True)
    sheets = {r: Image.open(latest(r)).convert("RGB") for r in {v[0] for v in REF.values()}}
    bg = tuple(int(v) for v in np.median(np.array(sheets["moon"])[:6].reshape(-1, 3), 0))
    cells = {k: cell_of(*v, sheets) for k, v in REF.items()}
    boxes = {k: bbox(c, bg) for k, c in cells.items()}
    sh = Image.new("RGB", (3 * CELL, len(ROWS) * CELL), bg)
    guide = (120, 200, 220)
    d = ImageDraw.Draw(sh)
    for r, (label, fam, _) in enumerate(ROWS):
        for c in range(3):
            key = ref_key(fam, c, v2)
            sh.paste(cells[key], (c * CELL, r * CELL))
            x0, y0, x1, y1 = boxes[key]
            ox, oy = c * CELL, r * CELL
            # the floor line (where the spirit stands today), dashed
            for x in range(ox + 6, ox + CELL - 6, 8):
                d.line((x, oy + y1 + 1, x + 3, oy + y1 + 1), fill=guide)
            if fam == "under":
                # how wide the item goes (about 1.2 x the spirit)
                w = (x1 - x0) * 1.2
                cx = (x0 + x1) / 2
                d.line((ox + cx - w / 2, oy + y1 + 14, ox + cx + w / 2, oy + y1 + 14), fill=guide, width=1)
            elif fam == "above":
                # the hover box over the head
                hw, hh = (x1 - x0) * 0.22, (y1 - y0) * 0.22
                cx, top = (x0 + x1) / 2, y0 - (y1 - y0) * 0.08
                d.rectangle((ox + cx - hw, oy + top - hh * 2, ox + cx + hw, oy + top), outline=guide)
            elif v2:
                # the spot beside it, sized in art px (the S spirit: 4 sheet px each)
                bw, bh = BESIDE_ART[0] * 4, BESIDE_ART[1] * 4
                d.rectangle((ox + x1 + 8, oy + y1 - bh, ox + x1 + 8 + bw, oy + y1), outline=guide)
            else:
                # the spot beside it (right side), up to half its height
                h = (y1 - y0) * 0.55
                d.rectangle((ox + x1 + 6, oy + y1 - h, ox + min(CELL - 4, x1 + 6 + (x1 - x0) * 0.35), oy + y1), outline=guide)
    tag = "_v2" if v2 else ""
    sh.save(OUT / f"dressup_sheet{tag}.png")
    f = ImageFont.truetype("/System/Library/Fonts/Avenir Next.ttc", 20, index=2)
    fs = ImageFont.truetype("/System/Library/Fonts/Avenir Next.ttc", 15, index=5)
    L, T = 330, 40
    g = Image.new("RGB", (L + sh.width, T + sh.height), (40, 36, 46))
    g.paste(sh, (L, T))
    dg = ImageDraw.Draw(g)
    for c, txt in enumerate(["cell 1", "cell 2", "cell 3"]):
        dg.text((L + c * CELL + 10, 8), txt, font=f, fill=(240, 230, 245))
    for r, (label, fam, what) in enumerate(ROWS):
        y = T + r * CELL + CELL // 2 - 30
        dg.text((12, y), f"{r + 1}. {label}", font=f, fill=(240, 230, 245))
        dg.text((12, y + 28), f"{fam.upper()} · {what}", font=fs, fill=(235, 215, 170))
        if v2:
            note = V2.get(r + 1, "redraw: bigger, on the small spirit")
            dg.text((12, y + 52), note.upper(), font=fs,
                    fill=(150, 220, 150) if note.startswith("keep") else (255, 150, 130))
    for i in range(len(ROWS) + 1):
        dg.line((L, T + i * CELL, g.width, T + i * CELL), fill=(120, 110, 130), width=1)
    g.save(OUT / f"dressup_guide{tag}.png")
    if v2:
        print(OUT / f"dressup_sheet{tag}.png", sh.size)
        return
    # the pilot six's angry faces: their base cells, twice (row 2 to draw on)
    pil = Image.open(SP / "anim_pilot/pilot_sheet.png").convert("RGB")
    pa = Image.new("RGB", (pil.width, 2 * CELL), bg)
    for row in range(2):
        pa.paste(pil.crop((0, 0, pil.width, CELL)), (0, row * CELL))
    pa.save(SP / "anim_prep/pilot_angry.png")
    print(OUT / "dressup_sheet.png", sh.size, "|", SP / "anim_prep/pilot_angry.png", pa.size)


if __name__ == "__main__":
    main("--v2" in sys.argv)
