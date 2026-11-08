"""Rig a spirit's 56 x 56 sprite for scripts/spirit_rig.gd: its eyes (to blink), its moving parts cut
out (a bolt to flash, a flame to flicker) and the body made whole behind them.

    .venv/bin/python tools/art/spirit_rig.py out_dir realm:id[:part] ...
        part: bolt (the yellow bolts sticking out of its top), flame (the flame over its wick)

Writes <id>_body.png (eyes open), <id>_closed.png (eyes shut), <id>_<part>.png and rig.json:
{id: {eyes: [[x, y, w, h], ...], parts: {bolt: {}, flame: {anchor: [x, y]}}, wobble, base}}, all in
the 56 canvas's pixels. A prototype (2026-11-06): the eyes are found as the two small dark spots
off the outline, side by side near the middle; check them on the debug sheet it saves.
"""
import colorsys
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
OUTLINE = (34, 16, 26)
EYES = {  # hand-set eyes where the finder can't tell (yellow eyes, merged shapes): [x, y, w, h]
    "ladyluck": [[17, 35, 7, 8], [33, 35, 8, 8]],
    "daruma": [[20, 36, 4, 4], [32, 36, 4, 4]],
}


def luma(a):
    return 0.3 * a[..., 0] + 0.59 * a[..., 1] + 0.11 * a[..., 2]


def hsv(a):
    f = a[..., :3] / 255.0
    h = np.zeros(a.shape[:2]); s = np.zeros(a.shape[:2]); v = np.zeros(a.shape[:2])
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            h[y, x], s[y, x], v[y, x] = colorsys.rgb_to_hsv(*f[y, x])
    return h * 360, s, v


def find_eyes(a):
    op = a[..., 3] > 0
    dark = op & (luma(a) < 75)
    outside = ~op
    touch = dark & ndimage.binary_dilation(outside, structure=np.ones((3, 3)))
    lab, n = ndimage.label(dark)              # (4-connected: a brow touching an eye corner stays apart)
    outline_ids = set(np.unique(lab[touch])) - {0}
    ys, xs = np.nonzero(op)
    cx, top, bot = xs.mean(), ys.min(), ys.max()
    cands = []
    for i, s in enumerate(ndimage.find_objects(lab)):
        if i + 1 in outline_ids:
            continue
        h, w = s[0].stop - s[0].start, s[1].stop - s[1].start
        area = int((lab[s] == i + 1).sum())
        if 2 <= area <= 20 and h <= 5 and w <= 4 and w / h <= 1.6:
            cands.append(dict(x=s[1].start, y=s[0].start, w=w, h=h, a=area,
                              mx=(s[1].start + s[1].stop) / 2, my=(s[0].start + s[0].stop) / 2))
    best, score = None, 1e9
    for i, p in enumerate(cands):
        for q in cands[i + 1:]:
            l, r = (p, q) if p["mx"] < q["mx"] else (q, p)
            gap = r["mx"] - l["mx"]
            if abs(l["my"] - r["my"]) > 1.5 or not 5 <= gap <= 22:
                continue
            mid = (l["mx"] + r["mx"]) / 2
            sc = abs(mid - cx) * 2 + abs(l["a"] - r["a"]) + abs((l["my"] - top) / (bot - top + 1) - 0.6) * 10
            if sc < score:
                best, score = (l, r), sc
    return [[e["x"], e["y"], e["w"], e["h"]] for e in best] if best else []


def close_eyes(a, eyes):
    c = a.copy()
    for x, y, w, h in eyes:
        for xx in range(x, x + w):
            skin = c[y - 1, xx].copy()
            if luma(skin[None, None])[0, 0] < 75:  # (a brow or the outline right above: look higher)
                skin = c[max(0, y - 2), xx].copy()
            for yy in range(y, y + h - 1):
                c[yy, xx] = skin
    return c


def split(a, mask, avoid=None):
    """Cut `mask` out of the sprite; refill what lay inside the body and redraw its outline."""
    part = np.zeros_like(a)
    part[mask] = a[mask]
    body = a.copy()
    body[mask] = 0
    op = body[..., 3] > 0
    # what the part covered inside the body's outline (a notch closed over, up to ~5 px deep)
    padded = np.pad(op, 6)
    shell = ndimage.binary_closing(padded, structure=np.ones((3, 3)), iterations=5)[6:-6, 6:-6] & mask
    if shell.any():
        inner = op & ~(luma(body) < 75)
        if avoid is not None:                 # (refill from the body's own colours, not the part's)
            inner &= ~avoid(body)
        idx = ndimage.distance_transform_edt(~inner, return_distances=False, return_indices=True)
        body[shell] = body[idx[0][shell], idx[1][shell]]
        body[shell, 3] = 255
    op = body[..., 3] > 0
    lab, n = ndimage.label(op, structure=np.ones((3, 3)))      # (crumbs the cut left behind)
    for i, sz in enumerate(ndimage.sum(op, lab, range(1, n + 1))):
        if sz < 5:
            body[lab == i + 1] = 0
    op = body[..., 3] > 0
    edge = op & ndimage.binary_dilation(~op, structure=np.array([[0, 1, 0], [1, 1, 1], [0, 1, 0]]))
    body[edge, :3] = OUTLINE
    return body, part


def warm_px(a):
    h, s, v = hsv(a)
    return (h > 8) & (h < 70) & (s > 0.3)


def bolt_mask(a):
    op = a[..., 3] > 0
    h, s, v = hsv(a)
    yellow = op & (h > 30) & (h < 68) & (s > 0.45) & (v > 0.55)
    ys, _ = np.nonzero(op)
    top = ys.min() + (ys.max() - ys.min()) * 0.45
    upper = np.arange(56)[:, None] < top
    lab, n = ndimage.label(yellow & upper, structure=np.ones((3, 3)))
    seeds = np.zeros_like(yellow)
    for i, sl in enumerate(ndimage.find_objects(lab)):
        if (lab[sl] == i + 1).sum() >= 3:
            seeds |= lab == i + 1
    # the bolt's pale highlights and orange edges, next to the yellow, up top
    warm = op & (h > 8) & (h < 70) & (s > 0.12) & (v > 0.45) & (luma(a) >= 60)
    keep = seeds | (ndimage.binary_dilation(seeds, structure=np.ones((3, 3)), iterations=3) & warm & upper)
    # its own outline: dark pixels hugging the bolt that don't border the body's colours
    dark = op & (luma(a) < 75)
    ring = dark & ndimage.binary_dilation(keep, structure=np.ones((3, 3)))
    return keep | ring


def flame_mask(a):
    op = a[..., 3] > 0
    h, s, v = hsv(a)
    warm = op & (((h < 60) & (s > 0.35) & (v > 0.7)) | ((s < 0.3) & (v > 0.95)))
    ys, xs = np.nonzero(op)
    # the flame: the warm part above the body's widest rows, the topmost warm component
    lab, n = ndimage.label(warm, structure=np.ones((3, 3)))
    objs = ndimage.find_objects(lab)
    i = min(range(n), key=lambda k: objs[k][0].start)
    keep = lab == i + 1
    dark = op & (luma(a) < 75)
    ring = dark & ndimage.binary_dilation(keep, structure=np.ones((3, 3)))
    ys2, xs2 = np.nonzero(keep)
    wick_y = ys2.max() + 1
    ring &= np.arange(56)[:, None] < wick_y            # the wick and the wax below stay
    anchor = [int(round(xs2.mean())), int(wick_y)]
    return keep | ring, anchor


def main(out, specs):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    rig = {}
    dbg = Image.new("RGBA", (len(specs) * 4 * 60, 60), (74, 44, 34, 255))
    for k, spec in enumerate(specs):
        realm, sid, *part = spec.split(":")
        a = np.array(Image.open(ROOT / f"docs/mockups/spirits/october_{realm}/px/{sid}.png").convert("RGBA")).astype(int)
        entry = {"parts": {}}
        body = a
        for p in part:
            if p == "bolt":
                body, layer = split(body, bolt_mask(body), avoid=warm_px)
                entry["parts"]["bolt"] = {}
            elif p == "flame":
                m, anchor = flame_mask(body)
                body, layer = split(body, m)
                entry["parts"]["flame"] = {"anchor": anchor}
            elif p == "wobble":
                entry["wobble"] = True
                continue
            Image.fromarray(layer.astype(np.uint8)).save(out / f"{sid}_{p}.png")
        eyes = EYES.get(sid) or find_eyes(body)
        entry["eyes"] = eyes
        closed = close_eyes(body, eyes)
        Image.fromarray(body.astype(np.uint8)).save(out / f"{sid}_body.png")
        Image.fromarray(closed.astype(np.uint8)).save(out / f"{sid}_closed.png")
        rig[sid] = entry
        x0 = k * 240
        dbg.alpha_composite(Image.fromarray(a.astype(np.uint8)), (x0 + 2, 2))
        dbg.alpha_composite(Image.fromarray(body.astype(np.uint8)), (x0 + 62, 2))
        dbg.alpha_composite(Image.fromarray(closed.astype(np.uint8)), (x0 + 122, 2))
        for p in part:
            if (out / f"{sid}_{p}.png").exists():
                dbg.alpha_composite(Image.open(out / f"{sid}_{p}.png"), (x0 + 182, 2))
        d = ImageDraw.Draw(dbg)
        for x, y, w, h in eyes:
            d.rectangle((x0 + 62 + x - 1, 2 + y - 1, x0 + 62 + x + w, 2 + y + h), outline=(0, 255, 120, 255))
        print(sid, entry)
    (out / "rig.json").write_text(json.dumps(rig, indent=1))
    dbg.resize((dbg.width * 6, dbg.height * 6), Image.NEAREST).save(out / "debug_6x.png")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
