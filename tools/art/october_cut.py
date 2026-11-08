"""Cut the October spirit sheets into 56 x 56 sprites, named by the tree's slots.

The three alternative sheets (docs/mockups/pal_brainstorm/spirit_30_alternatives/alternative_{a,b,c}.png)
share one layout: columns = the realms' baby lineages (Mountain, Moon, Fox, Fire, River), rows = the
baby, then the kid fed Sprouty, Sweet, Savory, Spicy, Sour. That is exactly the tree's first 30
slots, so each sheet is a full set of babies and kids. The style reference sheet's 15 are cut too
(as ref_01..ref_15, unassigned).

Each sprite keeps its loose parts (wisps, drops, sparks), is shrunk with spirit_px (hard edge,
redrawn 1 px outline), babies to 26 px tall and kids by the sheet's own scale (the median kid
34 px), so their relative sizes stay as drawn.

    .venv/bin/python tools/art/october_cut.py docs/mockups/spirits/october
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from spirit_px import place, shrink  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs/mockups/pal_brainstorm"
REALMS = ["mountain", "moon", "fox", "fire", "river"]
ROWS = ["baby", "sprouty", "sweet", "savory", "spicy", "sour"]
SLOTS = {  # realm -> [baby, kid fed Sprouty, Sweet, Savory, Spicy, Sour]
    "mountain": ["bud", "peapod", "usagi", "kakiage", "tengu", "kiwi"],
    "moon": ["nib", "leafwing", "fudge", "glazy", "choco_taco", "bumble"],
    "fox": ["inari", "kitsune", "waffle", "fried_egg", "drumstick", "oden"],
    "fire": ["ember", "paprika", "daruma", "nacho", "dotty", "kimchi"],
    "river": ["picklet", "kappa_maki", "sourpatch", "hermit", "buzz", "teru_teru"],
}


def components(path):
    a = np.array(Image.open(path).convert("RGBA")).astype(int)
    bg = np.median(np.concatenate([a[:4, :, :3].reshape(-1, 3), a[-4:, :, :3].reshape(-1, 3)]), 0)
    fg = np.abs(a[..., :3] - bg).sum(2) > 45
    fg = ndimage.binary_opening(fg, iterations=1)
    fg = ndimage.binary_fill_holes(ndimage.binary_closing(fg, iterations=2))
    lab, n = ndimage.label(fg)
    objs = ndimage.find_objects(lab)
    comps = []
    for i, s in enumerate(objs):
        h, w = s[0].stop - s[0].start, s[1].stop - s[1].start
        if h * w < 30:
            continue
        cy, cx = (s[0].start + s[0].stop) / 2, (s[1].start + s[1].stop) / 2
        comps.append(dict(i=i + 1, s=s, h=h, w=w, cx=cx, cy=cy))
    return a, lab, comps


def groups(vals, k):
    """Split sorted values into k bands at the k-1 biggest gaps."""
    v = np.sort(vals)
    gaps = np.argsort(np.diff(v))[-(k - 1):]
    cuts = sorted((v[g] + v[g + 1]) / 2 for g in gaps)
    return cuts


def band(x, cuts):
    return int(np.searchsorted(cuts, x))


def cut_grid(path, nrows, ncols, min_h=60):
    a, lab, comps = components(path)
    big = [c for c in comps if c["h"] >= min_h]
    rcuts = groups([c["cy"] for c in big], nrows)
    ccuts = groups([c["cx"] for c in big], ncols)
    cells = {}
    for c in comps:
        r, k = band(c["cy"], rcuts), band(c["cx"], ccuts)
        cells.setdefault((r, k), []).append(c)
    out = {}
    for key, cs in cells.items():
        if not any(c["h"] >= min_h for c in cs):
            continue
        m = np.isin(lab, [c["i"] for c in cs])
        crop = a.copy()
        crop[..., 3] = np.where(m, 255, 0)
        im = Image.fromarray(crop.astype(np.uint8))
        out[key] = im.crop(im.getbbox())
    return out


def main(out):
    out = Path(out)
    sets = {}
    for tag in "abc":
        cells = cut_grid(SRC / f"spirit_30_alternatives/alternative_{tag}.png", 6, 5)
        kids = [cells[(r, k)].height for r in range(1, 6) for k in range(5) if (r, k) in cells]
        scale = 34 / np.median(kids)
        d = out / tag.upper()
        d.mkdir(parents=True, exist_ok=True)
        for (r, k), im in cells.items():
            sid = SLOTS[REALMS[k]][r]
            size = "h26" if r == 0 else f"h{max(24, round(im.height * scale))}"
            sp = place(shrink(im, size, 0.4))
            sp.save(d / f"{sid}.png")
            sets[(tag.upper(), REALMS[k], r)] = sp
        print(tag, len(cells), "cells, kid scale %.3f" % scale)
    ref = cut_grid(SRC / "current_spirit_style_reference.png", 3, 5)
    rk = [im.height for im in ref.values()]
    scale = 34 / np.median(rk)
    d = out / "REF"
    d.mkdir(parents=True, exist_ok=True)
    refs = []
    for n, key in enumerate(sorted(ref)):
        sp = place(shrink(ref[key], f"h{round(ref[key].height * scale)}", 0.4))
        sp.save(d / f"ref_{n + 1:02d}.png")
        refs.append(sp)
    print("ref", len(ref))
    picker(sets, refs, out)


def picker(sets, refs, out, k=4):
    W = 56 * k
    wood = (74, 44, 34, 255)
    for realm in REALMS:
        sh = Image.new("RGBA", (130 + 3 * (W + 10), 30 + 6 * (W + 10)), (40, 36, 46, 255))
        d = ImageDraw.Draw(sh)
        for j, t in enumerate("ABC"):
            d.text((130 + j * (W + 10) + W // 2 - 4, 10), t, fill=(240, 230, 250))
        for r in range(6):
            sid = SLOTS[realm][r]
            d.text((8, 30 + r * (W + 10) + W // 2 - 12), f"{ROWS[r]}\n{sid}", fill=(230, 222, 240))
            for j, t in enumerate("ABC"):
                sp = sets.get((t, realm, r))
                tile = Image.new("RGBA", (56, 56), wood)
                if sp is not None:
                    tile.alpha_composite(sp)
                sh.alpha_composite(tile.resize((W, W), Image.NEAREST), (130 + j * (W + 10), 30 + r * (W + 10)))
        sh.save(out / f"pick_{realm}.png")
    sh = Image.new("RGBA", (5 * (W + 10) + 10, 3 * (W + 26) + 10), (40, 36, 46, 255))
    d = ImageDraw.Draw(sh)
    for n, sp in enumerate(refs):
        x, y = 10 + (n % 5) * (W + 10), 10 + (n // 5) * (W + 26)
        d.text((x, y), f"ref_{n + 1:02d}", fill=(230, 222, 240))
        tile = Image.new("RGBA", (56, 56), wood)
        tile.alpha_composite(sp)
        sh.alpha_composite(tile.resize((W, W), Image.NEAREST), (x, y + 14))
    sh.save(out / "pick_ref_extras.png")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else str(ROOT / "docs/mockups/spirits/october"))
