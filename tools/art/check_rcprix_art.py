"""Checks the designer's RC Prix art before it goes in (docs/mockups/rcprix_garden/BRIEF.md): every file
there, at its exact size, every pixel fully opaque or fully clear, and no stray files.

    <python with Pillow + numpy> tools/art/check_rcprix_art.py [folder] [--pilot|--round9-sample|--round10-sample|--round11-sample|--round12-sample|--round13-sample|--round13-all]

Prints one line per problem and exits 1 if there are any."""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from rcprix_templates import SIZES, SQ, WIDE  # noqa: E402
BARRIER_RUN = 64           # the corner barriers' margin for their run-ons (round 21, rcprix_barrier_blockout.py)
SIZES = {n: ((SQ + 2 * BARRIER_RUN,) * 2 if n.startswith("tyres_") else wh) for n, wh in SIZES.items()}

ROOT = Path(__file__).resolve().parents[2]
SEAMLESS = ("grass_a", "grass_b", "grass_c")
PILOT = ("straight_h", "straight_v", "corner_ne", "corner_nw", "corner_se", "corner_sw", "grass_a")
ROUND9_SAMPLE = ("straight_h", "corner_ne", "tyres_ne", "tyres_ne_alt")
ROUND10_SAMPLE = ("start_h", "boost_e", "ramp_e", "start_gantry", "start_lamp_off", "start_lamp_red", "start_lamp_green")
ROUND11_SAMPLE = ("stand_n_end_a", "stand_n_mid", "stand_n_end_b", "flag_0", "flag_1")
ROUND12_SAMPLE = ("butterfly_0", "butterfly_1", "butterfly_2")
ROUND13_SAMPLE = tuple(f"stand_front_{layer}_{part}" for layer in ("under", "over")
                       for part in ("end_a", "mid", "end_b")) + tuple(f"stand_flag_{i}" for i in range(3))
ROUND13_ALL = tuple(f"stand_{view}_{layer}_{part}" for view in ("front", "back", "side_r", "side_l")
                    for layer in ("under", "over") for part in ("end_a", "mid", "end_b")) + tuple(
                        f"stand_flag_{i}" for i in range(3))
JOINS = (
    ("corner_ne", "e", "straight_h", "w"), ("corner_nw", "w", "straight_h", "e"),
    ("corner_se", "e", "straight_h", "w"), ("corner_sw", "w", "straight_h", "e"),
    ("corner_ne", "n", "straight_v", "s"), ("corner_nw", "n", "straight_v", "s"),
    ("corner_se", "s", "straight_v", "n"), ("corner_sw", "s", "straight_v", "n"),
)
JOINS += tuple((a + WIDE, ae, b + WIDE, be) for a, ae, b, be in JOINS)     # (the wide set joins the same way)


def edge_pixels(image, side):
    """Which pixels along a piece's edge the road covers (two pieces join when these match; their colours
    may differ, as a curb stripe can change colour exactly at a join)"""
    return {"n": image[0], "s": image[-1], "w": image[:, 0], "e": image[:, -1]}[side][:, 3] > 0


# The approved tree's look, measured (NOTES_ROUND_6.md): its six colours (outline, deep shadow, two mids,
# light, highlight) and what share of the foliage each covers, and how big its light leaf patches are.
# Every bush must match it, so the bushes look drawn with the same brush as the trees.
TREE_TONES = np.array([(0x25, 0x1A, 0x24), (0x1A, 0x41, 0x31), (0x2B, 0x66, 0x39), (0x31, 0x72, 0x3B),
                       (0x5F, 0xB1, 0x38), (0x97, 0xD5, 0x3A)], float)
TREE_MATCH = {   # measure: (lowest, highest); the tree itself measures in the middle
    "palette": (0.95, 1.0),        # pixels within 32 of one of the six colours (tree 99%)
    "edge dark": (0.75, 1.0),      # outer edge pixels in the outline colour (tree 78%)
    "inner dark": (0.0, 0.08),     # outline colour inside the bush (tree 4%)
    "run": (2.2, 4.2),             # average px before the colour changes, across and down (tree 3.65; the approved bushes 2.2-3.1)
    "leaf patch": (20, 999),       # median size in px of the light leaf patches, light + highlight (tree 47; approved bushes 22+)
    "outline": (0.06, 0.20),       # share of each colour: outline (tree 9%)
    "shadow": (0.18, 0.34),        #   deep shadow (tree 26%)
    "mid": (0.18, 0.38),           #   the two mids together (tree 27%)
    "light": (0.18, 0.34),         #   light (tree 26%)
    "highlight": (0.06, 0.18),     #   highlight (tree 12%)
}


def tree_match(a):
    """A sprite's measures against TREE_MATCH (see there)"""
    from scipy import ndimage
    rgb, op = a[..., :3].astype(float), a[..., 3] > 0
    dist = np.linalg.norm(rgb[..., None, :] - TREE_TONES[None, None], axis=-1)
    tone = dist.argmin(-1)
    pad = np.pad(op, 1)
    edge = op & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
    labels, _ = ndimage.label(op & (tone >= 4))
    patches = np.bincount(labels.ravel())[1:]
    patches = patches[patches >= 3]
    runs = []
    for t in (np.where(op, tone, -1), np.where(op, tone, -1).T):
        for row in t:
            b = np.r_[-1, np.flatnonzero(np.diff(row) != 0), len(row) - 1]
            runs += [j - i for i, j in zip(b[:-1], b[1:]) if row[j] >= 0]
    share = np.bincount(tone[op], minlength=6) / op.sum()
    return {"palette": (dist.min(-1)[op] <= 32).mean(), "edge dark": (tone[edge] == 0).mean(),
            "inner dark": ((tone == 0) & op & ~edge).sum() / op.sum(), "run": np.mean(runs),
            "leaf patch": np.median(patches) if len(patches) else 0, "outline": share[0], "shadow": share[1],
            "mid": share[2] + share[3], "light": share[4], "highlight": share[5]}


def main():
    modes = ("--pilot", "--round9-sample", "--round10-sample", "--round11-sample", "--round12-sample", "--round13-sample", "--round13-all")
    args = [arg for arg in sys.argv[1:] if arg not in modes]
    pilot = "--pilot" in sys.argv[1:]
    round9_sample = "--round9-sample" in sys.argv[1:]
    round10_sample = "--round10-sample" in sys.argv[1:]
    round11_sample = "--round11-sample" in sys.argv[1:]
    round12_sample = "--round12-sample" in sys.argv[1:]
    round13_sample = "--round13-sample" in sys.argv[1:]
    round13_all = "--round13-all" in sys.argv[1:]
    folder = Path(args[0]) if args else ROOT / "textures" / "minigames" / "rcprix" / "garden"
    problems = []
    required = ({n: SIZES[n] for n in ROUND13_ALL} if round13_all else
                {n: SIZES[n] for n in ROUND13_SAMPLE} if round13_sample else
                {n: SIZES[n] for n in ROUND12_SAMPLE} if round12_sample else
                {n: SIZES[n] for n in ROUND11_SAMPLE} if round11_sample else
                {n: SIZES[n] for n in ROUND10_SAMPLE} if round10_sample else
                {n: SIZES[n] for n in ROUND9_SAMPLE} if round9_sample else
                {n: SIZES[n] for n in PILOT} if pilot else SIZES)
    images = {}
    for name, (w, h) in required.items():
        p = folder / f"{name}.png"
        if not p.exists():
            problems.append(f"missing   {p.name}")
            continue
        im = Image.open(p)
        if im.size != (w, h):
            problems.append(f"size      {p.name}: {im.size[0]}×{im.size[1]}, should be {w}×{h}")
        a = np.asarray(im.convert("RGBA"))
        images[name] = a
        soft = int(((a[..., 3] > 0) & (a[..., 3] < 255)).sum())
        if soft:
            problems.append(f"soft edge {p.name}: {soft} half-transparent pixels (every pixel fully opaque or fully clear)")
        if name in SEAMLESS and a.shape[:2] == (SQ, SQ):
            if (a[..., 3] < 255).any():
                problems.append(f"holes     {p.name}: ground must be fully opaque")
            # (seamless means the right edge carries on into the left, not that they're the same column;
            # that can't be checked by machine: look at course_preview.png, tools/art/rcprix_preview.py)
        if name.startswith("bush_"):
            got = tree_match(a)
            off = [f"{k} {got[k]:.2f} (tree: {lo:g}–{hi:g})" for k, (lo, hi) in TREE_MATCH.items() if not lo <= got[k] <= hi]
            if off:
                problems.append(f"not tree  {p.name}: " + ", ".join(off))
    # every ramp like ramp_e turned: the game measures ramp_e (RcTiles.ramp_reach) and draws them all so
    # their high end meets the jump's hole, so each must reach exactly as far, the same length
    if "ramp_e" in images:
        e = Image.fromarray(images["ramp_e"]).getchannel("A").getbbox()
        if e:
            lo, hi = e[0], e[2]
            for name, a in images.items():
                base = name.removesuffix(WIDE)
                if not base.startswith("ramp_") or name == "ramp_e":
                    continue
                b = Image.fromarray(a).getchannel("A").getbbox()
                if not b:
                    continue
                want = {"ramp_w": (SQ - hi, SQ - lo, 0), "ramp_n": (SQ - hi, SQ - lo, 1), "ramp_s": (lo, hi, 1)}.get(base)
                if base.endswith("_e"):
                    want = (lo, hi, 0)
                if want:
                    got = (b[0], b[2]) if want[2] == 0 else (b[1], b[3])
                    if abs(got[0] - want[0]) > 2 or abs(got[1] - want[1]) > 2:
                        axis = "across" if want[2] == 0 else "down"
                        problems.append(f"ramp      {name}.png: drawn {got[0]}-{got[1]} px {axis}, should be {want[0]}-{want[1]} (as ramp_e, turned)")
    for name, a in images.items():
        if not name.startswith("ramp_"):
            continue
        box = Image.fromarray(a).getchannel("A").getbbox()
        if not box:
            continue
        vertical = name.removesuffix(WIDE).endswith(("_n", "_s"))
        span = (box[2] - box[0]) if vertical else (box[3] - box[1])
        want = 88 if name.endswith(WIDE) else 76
        if span != want:
            problems.append(f"ramp      {name}.png: {span} px across the road, should be {want}")
    for left, le, right, re in JOINS:
        if left in images and right in images:
            if not np.array_equal(edge_pixels(images[left], le), edge_pixels(images[right], re)):
                problems.append(f"join      {left}.{le} does not match {right}.{re}")
    if round9_sample and "corner_ne" in images:
        neighbour = folder / "straight_v.png"
        if neighbour.exists():
            vertical = np.asarray(Image.open(neighbour).convert("RGBA"))
            if not np.array_equal(edge_pixels(images["corner_ne"], "n"), edge_pixels(vertical, "s")):
                problems.append("join      corner_ne.n does not match straight_v.s")
    for p in sorted(folder.glob("*.png")):
        if not (round13_all or round13_sample or round12_sample or round11_sample or round10_sample or round9_sample or pilot) and p.stem not in SIZES:
            problems.append(f"unknown   {p.name} (not in the brief's list)")
    for line in problems:
        print(line)
    print(f"{len(required) - sum(l.startswith('missing') for l in problems)}/{len(required)} files present, {len(problems)} problems")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
