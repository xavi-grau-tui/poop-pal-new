"""A poster of all 120 spirits: one band per realm, each split by stage (baby, kids, adults,
mutants, legend), every sprite at the same pixel scale so the sizes show how they grow.

    .venv/bin/python tools/art/spirits_poster.py            # 4x -> docs/mockups/spirits/october/kamitomo_spirits_poster.png
    .venv/bin/python tools/art/spirits_poster.py 3 out.png

Reads the current cuts in docs/mockups/spirits/october_<realm>/px/ (october_sheet_cut.py).
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from october_sheet_cut import ORDER, SP, layout  # noqa: E402

REALMS = {
    "mountain": ("山", "Mountain", (96, 140, 70)),
    "moon": ("月", "Moon", (112, 100, 178)),
    "fox": ("狐", "Fox", (214, 128, 48)),
    "fire": ("火", "Fire", (206, 74, 52)),
    "river": ("川", "River", (64, 140, 190)),
}
PAPER = (248, 241, 226)
INK = (58, 40, 44)
AVENIR = "/System/Library/Fonts/Avenir Next.ttc"
HIRAGINO = "/System/Library/Fonts/Hiragino Sans GB.ttc"


def font(size, face="demi"):
    if face == "kanji":
        return ImageFont.truetype(HIRAGINO, size, index=2)
    return ImageFont.truetype(AVENIR, size, index={"bold": 0, "demi": 2, "medium": 5, "heavy": 8}[face])


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def build(k=4):
    CW, CH, GAP = 54 * k, 52 * k, 2 * k          # a cell fits the widest (52) and tallest (50) sprite
    SEC = 14 * k                                  # the gap between stage sections
    PAD, MARGIN = 10 * k, 15 * k
    # sections: (title, columns, rows)
    secs = [("Baby", 1), ("Kids", 5), ("Adults", 5), ("Mutants", 1), ("Legend", 1)]
    xs, x = [], MARGIN + PAD
    for _, n in secs:
        xs.append(x)
        x += n * CW + (n - 1) * GAP + SEC
    W = x - SEC + PAD + MARGIN
    band_h = 3 * CH + 2 * GAP + 2 * PAD + 22 * k
    TITLE = 64 * k
    H = TITLE + 14 * k + len(ORDER) * (band_h + 8 * k) + 18 * k

    im = Image.new("RGBA", (W, H), PAPER + (255,))
    d = ImageDraw.Draw(im)

    # the title
    d.text((MARGIN, 14 * k), "KamiTomo", font=font(26 * k, "heavy"), fill=INK)
    d.text((MARGIN + 2 * k, 46 * k), "120 spirits  ·  5 realms  ·  from baby to legend",
           font=font(9 * k, "medium"), fill=mix(INK, PAPER, 0.35))
    kx = W - MARGIN
    for realm in reversed(ORDER):
        kan, _, col = REALMS[realm]
        f = font(20 * k, "kanji")
        w = d.textlength(kan, font=f)
        kx -= w
        d.text((kx, 20 * k), kan, font=f, fill=col)
        kx -= 6 * k
    # the stage headers, once, over the first band
    hy = TITLE + 2 * k
    for (title, n), sx in zip(secs, xs):
        f = font(8 * k, "demi")
        w = d.textlength(title.upper(), font=f)
        span = n * CW + (n - 1) * GAP
        d.text((sx + (span - w) / 2, hy), title.upper(), font=f, fill=mix(INK, PAPER, 0.3))

    y = TITLE + 14 * k
    for realm in ORDER:
        kan, name, col = REALMS[realm]
        cols = layout(realm)
        sprites = {sid: Image.open(SP / f"october_{realm}/px/{sid}.png").convert("RGBA")
                   for column in cols for sid in column}
        # the band
        d.rounded_rectangle((MARGIN, y, W - MARGIN, y + band_h), radius=8 * k,
                            fill=mix(PAPER, col, 0.13), outline=mix(PAPER, col, 0.45), width=max(2, k // 2))
        d.text((MARGIN + PAD, y + 4 * k), kan, font=font(12 * k, "kanji"), fill=col)
        d.text((MARGIN + PAD + 16 * k, y + 5 * k), name, font=font(10 * k, "bold"), fill=mix(col, INK, 0.35))
        top = y + 22 * k + PAD - 4 * k
        # the dividers between sections
        for sx in xs[1:]:
            dx = sx - SEC // 2
            d.line((dx, top + 2 * k, dx, top + 3 * CH + 2 * GAP - 2 * k), fill=mix(PAPER, col, 0.3), width=max(1, k // 2))

        def put(sid, sx, row, colidx=0):
            sp = sprites[sid]
            bb = sp.getbbox()
            s = sp.crop(bb)
            s = s.resize((s.width * k, s.height * k), Image.NEAREST)
            cx = sx + colidx * (CW + GAP) + CW // 2
            base = round(top + row * (CH + GAP) + CH - 3 * k)
            # a soft floor shadow
            ew = round(s.width * 0.42)
            sh = Image.new("RGBA", (2 * ew + 2, 5 * k + 2), (0, 0, 0, 0))
            ImageDraw.Draw(sh).ellipse((0, 0, 2 * ew, 5 * k), fill=mix(col, INK, 0.6) + (46,))
            im.alpha_composite(sh, (cx - ew, base - 3 * k))
            im.alpha_composite(s, (round(cx - s.width / 2), base - s.height))

        put(cols[5][0], xs[0], 1)                        # baby
        for c in range(5):
            put(cols[c][0], xs[1], 1, c)                 # kids, in line order
            for r in range(1, 4):
                put(cols[c][r], xs[2], r - 1, c)         # adults, under their line
        put(cols[5][1], xs[3], 0.5)                      # mutants (Tech, Cosmic)
        put(cols[5][2], xs[3], 1.5)
        put(cols[5][3], xs[4], 1)                        # legend
        y += band_h + 8 * k
    return im.convert("RGB")


if __name__ == "__main__":
    k = int(sys.argv[1]) if len(sys.argv) > 1 else 4
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else SP / "october/kamitomo_spirits_poster.png"
    im = build(k)
    im.save(out, optimize=True)
    print(out, im.size)
