"""Cut the designer's filled realm sheets into the 120 spirits' 56 x 56 sprites.

Each sheet (docs/mockups/spirits/october_<realm>/<realm>_filled.png, or its newest _vN) is the template's 6 x 4 grid
of 260 px cells (docs/kami_spirits_bible.md). Every sprite is shrunk by one factor per sheet (the
median kid -> 34 px) times its stage (baby 1.08, kid 1, adult and mutant 1.15, legend 1.3), so
they keep the sizes they were drawn at; nothing wider than 52 or taller than 50.

    .venv/bin/python tools/art/october_sheet_cut.py            # all five realms
    .venv/bin/python tools/art/october_sheet_cut.py fox

Writes october_<realm>/px/<slot>.png, <realm>_realm_4x.png, <realm>_realm_in_home.png and
docs/mockups/spirits/october/all_120_triage.png (every realm's tree at 3x on the shrine wood).
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from october_template import REALMS  # noqa: E402
from spirit_px import place, shrink  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SP = ROOT / "docs/mockups/spirits"
CELL = 260
FIRE = [["paprika", "hoozuki", "pepper_plant", "chameleon"], ["daruma", "oo_daruma", "maneki", "spicecake"],
        ["nacho", "popper", "quesadilla", "burrito"], ["dotty", "firebug", "salamander", "ladyluck"],
        ["kimchi", "gochujang", "ceviche", "takoyaki"], ["ember", "mecha_oni", "comet_chili", "hou_ou"]]
ORDER = ["mountain", "moon", "fox", "fire", "river"]
MULT = dict(baby=1.08, kid=1.0, adult=1.15, mutant=1.15, legend=1.3)


def layout(realm):
    if realm == "fire":
        return FIRE
    return [[sid for sid, _ in col] for col in REALMS[realm]]


def stage(c, r):
    if c == 5:
        return ["baby", "mutant", "mutant", "legend"][r]
    return "kid" if r == 0 else "adult"


def latest(realm):
    """The realm's newest sheet: <realm>_filled_vN.png with the highest N, else <realm>_filled.png."""
    vs = sorted(SP.glob(f"october_{realm}/{realm}_filled_v[0-9]*.png"),
                key=lambda p: int(p.stem.split("_v")[-1].split("_")[0]) if p.stem.split("_v")[-1].isdigit() else -1)
    vs = [p for p in vs if p.stem.split("_v")[-1].isdigit()]
    return vs[-1] if vs else SP / f"october_{realm}/{realm}_filled.png"


def crops_of(sheet, cols):
    a = np.array(Image.open(sheet).convert("RGBA")).astype(int)
    bg = np.median(a[:6, :, :3].reshape(-1, 3), 0)
    crops = {}
    for c, col in enumerate(cols):
        for r, sid in enumerate(col):
            cell = a[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL].copy()
            fg = np.abs(cell[..., :3] - bg).sum(2) > 45
            fg = ndimage.binary_opening(fg, iterations=1)
            fg = ndimage.binary_fill_holes(ndimage.binary_closing(fg, iterations=2))
            lab, n = ndimage.label(fg)
            sizes = ndimage.sum(fg, lab, range(1, n + 1))
            cell[..., 3] = np.where(np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s >= 40]), 255, 0)
            im = Image.fromarray(cell.astype(np.uint8))
            crops[(c, r)] = im.crop(im.getbbox())
    return crops


def cut(realm, sheet=None, out=None):
    cols = layout(realm)
    crops = crops_of(sheet or latest(realm), cols)
    # (the scale comes from the first filled sheet, so replacing a kid later doesn't resize the realm)
    base = crops_of(SP / f"october_{realm}/{realm}_filled.png", cols)
    f = 34 / np.median([base[(c, 0)].height for c in range(5)])
    out = Path(out) if out else SP / f"october_{realm}/px"
    out.mkdir(parents=True, exist_ok=True)
    sprites = {}
    for (c, r), im in crops.items():
        h = im.height * f * MULT[stage(c, r)]
        w = im.width * h / im.height
        h = round(min(h, 50, h * 52 / w))
        sp = place(shrink(im, f"h{h}", 0.4))
        sp.save(out / f"{cols[c][r]}.png")
        sprites[cols[c][r]] = sp
    return cols, sprites


def tree_sheet(cols, sprites, k):
    W = 56 * k
    sh = Image.new("RGBA", (6 * (W + 6) + 6, 4 * (W + 18) + 6), (40, 36, 46, 255))
    d = ImageDraw.Draw(sh)
    for c, col in enumerate(cols):
        for r, sid in enumerate(col):
            x, y = 6 + c * (W + 6), 6 + r * (W + 18)
            d.text((x, y), sid, fill=(235, 225, 245))
            t = Image.new("RGBA", (56, 56), (74, 44, 34, 255))
            t.alpha_composite(sprites[sid])
            sh.alpha_composite(t.resize((W, W), Image.NEAREST), (x, y + 13))
    return sh


def in_home_sheet(cols, sprites):
    front = Image.open(ROOT / "textures/pet/homes/forest/front.png").convert("RGBA")
    inside = Image.open(ROOT / "textures/pet/homes/forest/inside.png").convert("RGBA")
    WW, PAL = int(925 * 1.02), 5.3
    fr, ins = front.resize((WW, WW), Image.NEAREST), inside.resize((WW, WW), Image.NEAREST)
    tw = WW // 4
    sh = Image.new("RGBA", (6 * (tw + 6) + 6, 4 * (tw + 18) + 6), (40, 36, 46, 255))
    d = ImageDraw.Draw(sh)
    for c, col in enumerate(cols):
        for r, sid in enumerate(col):
            b = Image.new("RGBA", (WW, WW), (150, 190, 215, 255))
            b.alpha_composite(ins)
            s = sprites[sid].crop(sprites[sid].getbbox())
            s = s.resize((round(s.width * PAL), round(s.height * PAL)), Image.NEAREST)
            b.alpha_composite(s, (WW // 2 - s.width // 2 - 6, int(WW * 0.69) - s.height))
            b.alpha_composite(fr)
            x, y = 6 + c * (tw + 6), 6 + r * (tw + 18)
            d.text((x, y), sid, fill=(230, 222, 240))
            sh.alpha_composite(b.resize((tw, tw), Image.NEAREST), (x, y + 13))
    return sh


def main(realms):
    done = {}
    for realm in realms:
        cols, sprites = cut(realm)
        tree_sheet(cols, sprites, 4).save(SP / f"october_{realm}/{realm}_realm_4x.png")
        in_home_sheet(cols, sprites).save(SP / f"october_{realm}/{realm}_realm_in_home.png")
        done[realm] = (cols, sprites)
        print(realm, len(sprites))
    if len(done) == 5:
        sheets = [tree_sheet(*done[r], 3) for r in ORDER]
        W = sheets[0].width
        all_ = Image.new("RGBA", (W, sum(s.height + 22 for s in sheets)), (28, 24, 32, 255))
        d = ImageDraw.Draw(all_)
        y = 0
        for realm, s in zip(ORDER, sheets):
            d.text((8, y + 5), realm.upper(), fill=(255, 220, 160))
            all_.alpha_composite(s, (0, y + 22))
            y += s.height + 22
        all_.save(SP / "october/all_120_triage.png")


if __name__ == "__main__":
    main(sys.argv[1:] or ORDER)
