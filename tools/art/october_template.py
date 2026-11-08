"""Build a realm's template sheet for the designer from the October pool (docs/kami_spirits_bible.md).

Each realm is a 6 x 4 grid of 260 px cells on the October cream, in the tree layout: columns 1-5 are
the five lines (the kid on top, its three adults below, the Pure/Ultra one first), column 6 is the
baby, the Tech mutant, the Cosmic mutant and the legend. Chosen October sprites are pasted at their
original size; NEW cells stay blank for the designer to fill by an ImageGen edit of the sheet.

    .venv/bin/python tools/art/october_template.py mountain moon fox river

Writes docs/mockups/spirits/october/<realm>_template_for_designer.png, <realm>_tree_proposal.png
(4x on the shrine wood, gaps marked) and prints the NEW cells as (column, row).
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from october_cut import SRC, cut_grid  # noqa: E402
from spirit_px import place, shrink  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/mockups/spirits/october"
CELL = 260

# realm -> 6 columns of 4 (slot, code or None)
REALMS = {
    "mountain": [
        [("peapod", "A11"), ("avocado", "C11"), ("melon_pan", "B13"), ("wasabi_pea", "R01")],
        [("usagi", "A21"), ("yomogi", "B11"), ("usagi_manju", None), ("yamabiko", "C14")],
        [("kakiage", "R05"), ("kinoko", "A14"), ("mujina", "C32"), ("kodama", "C13")],
        [("tengu", "B14"), ("karasu_tengu", None), ("horseradish", "A41"), ("komainu", None)],
        [("kiwi", "B15"), ("kappa", "A51"), ("gherk", "C15"), ("kiwi_bird", "R03")],
        [("bud", "A01"), ("karakuri", None), ("zorb", None), ("world_tree", None)],
    ],
    "moon": [
        [("leafwing", "A12"), ("owlet", "C25"), ("pistachio", "B21"), ("scarab", "A42")],
        [("fudge", "C23"), ("bonbon", "A23"), ("kuri", "B23"), ("gremlin", "C24")],
        [("glazy", "A22"), ("eclair", "B22"), ("churro", "C22"), ("candy_corn", "B24")],
        [("choco_taco", "C21"), ("hot_cocoa", "R10"), ("cocoa_fire", None), ("taiyaki", None)],
        [("bumble", None), ("honeybear", "B25"), ("ramune", None), ("bruin", None)],
        [("nib", "A02"), ("cocoa_9", None), ("kaguya", None), ("tsukuyomi", None)],
    ],
    "fox": [
        [("kitsune", "A33"), ("kyubi", "C34"), ("konoha", None), ("okonomi", None)],
        [("waffle", "R04"), ("popcorn", "A13"), ("daigaku_imo", None), ("stroopwafel", None)],
        [("fried_egg", "R07"), ("burger", "B34"), ("hot_dog", None), ("fish_taco", None)],
        [("drumstick", "B35"), ("kushikatsu", "C35"), ("kitsu", "B33"), ("hothog", "B31")],
        [("oden", "C31"), ("ebi_fry", "B32"), ("shiso_tempura", None), ("walrusk", "R09")],
        [("inari", "A03"), ("robobear", None), ("nebula_nug", None), ("sunbear", None)],
    ],
    "river": [
        [("kappa_maki", "R15"), ("ume_onigiri", "C53"), ("granny", None), ("hoot", "A55")],
        [("sourpatch", "A25"), ("lemon_sweet", "A45"), ("cream_soda", None), ("lime", "C54")],
        [("hermit", "R11"), ("anemone", "B54"), ("calamari", "A54"), ("octopepper", None)],
        [("buzz", "R12"), ("lemon_ant", "C52"), ("shichimi", "B55"), ("axel", None)],
        [("teru_teru", "C51"), ("omamori", None), ("kokeshi", "B53"), ("karakasa", "C33")],
        [("picklet", "A05"), ("robofrog", None), ("ningyo", "C55"), ("frog_king", None)],
    ],
}

_sheets = {}


def source(code):
    if not _sheets:
        for t in "abc":
            _sheets[t] = cut_grid(SRC / f"spirit_30_alternatives/alternative_{t}.png", 6, 5)
        ref = cut_grid(SRC / "current_spirit_style_reference.png", 3, 5)
        # the reference sheet is drawn bigger: bring it to the A/B/C sheets' scale (by median height)
        abc = np.median([im.height for t in "abc" for (r, _), im in _sheets[t].items() if r > 0])
        k = abc / np.median([im.height for im in ref.values()])
        _sheets["r"] = [ref[q].resize((round(ref[q].width * k), round(ref[q].height * k)), Image.LANCZOS)
                        for q in sorted(ref)]
    if code[0] == "R":
        return _sheets["r"][int(code[1:]) - 1]
    return _sheets[code[0].lower()][(int(code[1]), int(code[2]) - 1)]


def build(realm):
    cols = REALMS[realm]
    bg = tuple(int(v) for v in np.median(
        np.array(Image.open(SRC / "spirit_30_alternatives/alternative_c.png").convert("RGB"))[:6].reshape(-1, 3), 0))
    tp = Image.new("RGB", (6 * CELL, 4 * CELL), bg)
    k, W = 4, 56 * 4
    tree = Image.new("RGBA", (6 * (W + 8) + 8, 4 * (W + 22) + 8), (40, 36, 46, 255))
    d = ImageDraw.Draw(tree)
    gaps = []
    for c, col in enumerate(cols):
        for r, (sid, code) in enumerate(col):
            x, y = 8 + c * (W + 8), 8 + r * (W + 22)
            d.text((x, y), f"{sid}  {code or 'NEW'}", fill=(235, 225, 245) if code else (255, 170, 120))
            tile = Image.new("RGBA", (56, 56), (74, 44, 34, 255))
            if code:
                im = source(code)
                tp.paste(im, (c * CELL + (CELL - im.width) // 2, r * CELL + CELL - 20 - im.height), im)
                stage = "h26" if c == 5 and r == 0 else ("h34" if r == 0 else "h40")
                tile.alpha_composite(place(shrink(im, stage, 0.4)))
            else:
                gaps.append((c + 1, r + 1, sid))
                ImageDraw.Draw(tile).rectangle((14, 20, 41, 53), outline=(150, 110, 90, 255))
            tree.alpha_composite(tile.resize((W, W), Image.NEAREST), (x, y + 14))
    tp.save(OUT / f"{realm}_template_for_designer.png")
    tree.save(OUT / f"{realm}_tree_proposal.png")
    print(realm, "NEW:", ", ".join(f"({c},{r}) {s}" for c, r, s in gaps))


if __name__ == "__main__":
    for realm in sys.argv[1:] or list(REALMS):
        build(realm)
