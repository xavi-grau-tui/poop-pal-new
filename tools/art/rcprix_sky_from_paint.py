"""RC Prix Sky: the designer's 4x paintings into the game's files. Run from the repo root:

    <python with Pillow + numpy> tools/art/rcprix_sky_from_paint.py <round>      (e.g. round1)

Reads docs/mockups/rcprix_sky/<round>_paint/<name>_4x.png, checks each is on the 4x grid (one game px = one
4x4 block), and writes textures/minigames/rcprix/sky/<name>.png at one game px per px. The rings also get:
  - the cut line cleaned: our guide's ink line across the tube at the ring's middle row (painted in on some
    sizes) filled from the tube above / below it, an ink stub left inside the hole removed;
  - ring_gold_<r>: every size recoloured the way ring_gold_124 recolours ring_124 (colour for colour);
  - ring_grey_<r>: a missed ring, greyed."""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/sky"
RINGS = (124, 112, 100, 88)


def load(path):
    a = np.array(Image.open(path).convert("RGBA"))
    h, w = a.shape[:2]
    if h % 4 or w % 4:
        raise SystemExit(f"{path.name}: {w}x{h} is not a multiple of 4")
    b = a.reshape(h // 4, 4, w // 4, 4, 4)
    mixed = (b.max(axis=(1, 3)) != b.min(axis=(1, 3))).any(-1).mean()
    if mixed > 0.01:
        print(f"  warning: {path.name}: {mixed:.1%} of its 4x4 blocks aren't one colour (taking each block's top left)")
    return a[::4, ::4].copy()


def is_ink(c):
    return c[3] > 0 and int(c[0]) + int(c[1]) + int(c[2]) < 200


def clean_cut(a):
    """The guide's cut line across the tube at the middle rows (ink, a gap, ink: up to 4 rows): in each column,
    a run of ink / empty pixels there with tube just above and just below is filled, its upper part from the
    tube above, its lower part from the tube below"""
    h, w = a.shape[:2]
    cy = h // 2
    tube = lambda c: c[3] > 0 and not is_ink(c)
    for x in range(w):
        y = cy - 3
        while y <= cy + 3:
            if tube(a[y, x]):
                y += 1
                continue
            top = y
            while y <= cy + 4 and not tube(a[y, x]):
                y += 1
            if top > 0 and y < h and y - top <= 4 and tube(a[top - 1, x]) and tube(a[y, x]):
                mid = (top + y) / 2.0
                for yy in range(top, y):
                    a[yy, x] = a[top - 1, x] if yy < mid else a[y, x]
    return a


def drop_cut_puffs(a, start, end, along_x):
    """A stand cloud's over layer: the puffs in its repeated middle (art px start..end along the stand) that reach
    within 3 px of its ends are cut off by the repeat (a straight edge each time): dropped, the whole ones kept"""
    t = a if along_x else a.transpose(1, 0, 2)
    seen = np.zeros(t.shape[:2], bool)
    h = t.shape[0]
    for y in range(h):
        for x in range(start, end):
            if t[y, x, 3] == 0 or seen[y, x]:
                continue
            comp, stack = [], [(y, x)]
            seen[y, x] = True
            while stack:
                cy, cx = stack.pop()
                comp.append((cy, cx))
                for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                    if 0 <= ny < h and start <= nx < end and not seen[ny, nx] and t[ny, nx, 3] > 0:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
            xs = [c[1] for c in comp]
            if min(xs) <= start + 2 or max(xs) >= end - 3:
                for cy, cx in comp:
                    t[cy, cx] = 0
    return a


def recolour_map(src, dst):
    m = {}
    for s, d in zip(src.reshape(-1, 4), dst.reshape(-1, 4)):
        if s[3] == 0:
            continue
        m.setdefault(tuple(s), {}).setdefault(tuple(d), 0)
        m[tuple(s)][tuple(d)] += 1
    return {k: max(v, key=v.get) for k, v in m.items()}


def apply_map(a, m):
    out = a.copy()
    keys = np.array(list(m.keys()), int)
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            c = tuple(a[y, x])
            if c[3] == 0:
                continue
            if c not in m:                                   # (the nearest colour the gold ring has)
                c = tuple(keys[np.abs(keys - np.array(c, int)).sum(1).argmin()])
            out[y, x] = m[c]
    return out


def grey(a):
    out = a.copy().astype(float)
    lum = out[..., :3] @ np.array([0.3, 0.59, 0.11])
    g = 70 + lum * 0.55
    ink = lum < 70                                         # (the outline stays dark)
    out[..., 0], out[..., 1], out[..., 2] = g * 0.98, g * 0.96, g * 1.04
    out[ink] = a[ink]
    return np.clip(out, 0, 255).astype(np.uint8)


def main():
    rnd = sys.argv[1] if len(sys.argv) > 1 else "round1"
    src = ROOT / f"docs/mockups/rcprix_sky/{rnd}_paint"
    OUT.mkdir(parents=True, exist_ok=True)
    done = {}
    for p in sorted(src.glob("*_4x.png")):
        if p.name.startswith("style_"):
            continue
        name = p.name[:-len("_4x.png")]
        a = load(p)
        if name.startswith("ring_"):
            a = clean_cut(a)
        if name.startswith("stand_cloud_") and name.endswith("_over"):
            # (the stand's pieces in art px: end_a 41, middle 80, after the cloud's margin of 22)
            a = drop_cut_puffs(a, 22 + 41, 22 + 41 + 80, "front" in name or "back" in name)
        done[name] = a
    if "ring_124" in done and "ring_gold_124" in done:
        m = recolour_map(done["ring_124"], done["ring_gold_124"])
        for r in RINGS:
            if f"ring_{r}" in done:
                if r != 124:
                    done[f"ring_gold_{r}"] = apply_map(done[f"ring_{r}"], m)
                done[f"ring_grey_{r}"] = grey(done[f"ring_{r}"])
    for name, a in done.items():
        Image.fromarray(a).save(OUT / f"{name}.png")
        print(f"  {name}.png {a.shape[1]}x{a.shape[0]}")
    print("written to", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
