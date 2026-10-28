"""RC Prix Lagoon, round 1: stand-in squares in the current Lagoon's colours, so the game's new Lagoon
renderer (scripts/rc_lagoon.gd) can be tried before the designer's arrive. Run from the repo root:

    <python with Pillow + numpy> tools/art/rcprix_lagoon_standins.py

Writes textures/minigames/rcprix/lagoon/{water,channel,shallows,sand}_{a,b,c}.png, 190x190 each. Painted
at the sunset's middle tone (the game adds the sunset top to bottom). Seamless: a flat base, and nothing
within 3 px of the edges but the base and a soft wrap-around pattern, so any variant joins any other."""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/lagoon"
SQ = 190
EDGE = 3

KINDS = {
    #            base            light           dark            dashes
    "water":    ((212, 142, 143), (238, 186, 160), (196, 128, 134), 70),
    "channel":  ((190, 117, 129), (208, 142, 146), (176, 104, 122), 40),
    "shallows": ((223, 157, 142), (246, 200, 170), (210, 144, 136), 50),
}
SAND = ((244, 220, 166), (254, 238, 196), (226, 196, 142))


def periodic_noise(rng, cells):
    """Value noise that wraps round the square (cells across), 0..1"""
    g = rng.random((cells, cells))
    t = np.arange(SQ) / SQ * cells
    i = np.floor(t).astype(int)
    f = t - i
    f = f * f * (3 - 2 * f)
    i0, i1 = i % cells, (i + 1) % cells
    a = g[np.ix_(i0, i0)] * (1 - f)[None, :] + g[np.ix_(i0, i1)] * f[None, :]
    b = g[np.ix_(i1, i0)] * (1 - f)[None, :] + g[np.ix_(i1, i1)] * f[None, :]
    return a * (1 - f)[:, None] + b * f[:, None]


def water(kind, seed):
    base, light, dark, n = KINDS[kind]
    rng = np.random.default_rng(seed)
    im = np.zeros((SQ, SQ, 3), np.uint8)
    im[:] = base
    for _ in range(n):                                   # short wave crests: a light dash, a dark one under it
        L = int(rng.integers(4, 9))
        x = int(rng.integers(EDGE, SQ - EDGE - L - 1))
        y = int(rng.integers(EDGE, SQ - EDGE - 2))
        im[y, x:x + L] = light
        im[y + 1, x + 1:x + L + 1] = dark
    return im


def sand(seed):
    base, lit, dark = SAND
    rng = np.random.default_rng(seed)
    im = np.zeros((SQ, SQ, 3), np.uint8)
    im[:] = base
    nz = periodic_noise(rng, 19)                         # soft lit patches, wrapping round
    chk = (np.add.outer(np.arange(SQ), np.arange(SQ)) % 2) == 0
    im[(nz > 0.68) | ((nz > 0.62) & chk)] = lit
    for _ in range(160):                                 # grains
        x, y = (int(v) for v in rng.integers(EDGE, SQ - EDGE, 2))
        im[y, x] = dark
    return im


# the original Lagoon's bank decor (rc_racer.gd _lagoon_bank_decor), each cell 2x2 art px: its size in the game
DECOR = {
    "pebble": [".##.", "#lm#", "#md#", ".##."],
    "starfish": ["..#..", ".#s#.", "#sSs#", ".#s#.", ".#.#."],
    "shell": [".#.", "#w#", "#p#"],
    "seagrass": ["g.g", "g.g", ".gG", ".G."],
}
DECOR_COLS = {"#": (118, 82, 58), "l": (214, 208, 200), "m": (170, 162, 160), "d": (130, 122, 124),
              "s": (250, 140, 90), "S": (255, 196, 140), "w": (255, 246, 236), "p": (248, 196, 206),
              "g": (110, 150, 96), "G": (80, 120, 78)}


def decor(rows):
    im = np.zeros((len(rows) * 2, len(rows[0]) * 2, 4), np.uint8)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                im[2 * y:2 * y + 2, 2 * x:2 * x + 2] = (*DECOR_COLS[ch], 255)
    return im


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, rows in DECOR.items():
        Image.fromarray(decor(rows)).save(OUT / f"{name}.png")
    for vi, v in enumerate("abc"):
        for kind in KINDS:
            Image.fromarray(water(kind, 11 * vi + len(kind))).save(OUT / f"{kind}_{v}.png")
        Image.fromarray(sand(5 + vi)).save(OUT / f"sand_{v}.png")
    print("written to", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
