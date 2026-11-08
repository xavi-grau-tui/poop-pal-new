"""The designer's animation prep sheet -> each spirit's frames on its sprite's exact pixel grid.

The sheet (docs/mockups/spirits/anim_pilot/pilot_filled.png) has one column per spirit and seven
260 px rows, each an exact copy of the spirit's approved cell with one change:
    1 base   2 eyes closed   3 mouth open   4 happy   5 sad   6 body only   7 parts only

Nothing may drift between frames, so no frame is cut on its own. The base is cut exactly like the
realm's sprite (october_sheet_cut.py: the same mask, crop, scale and place, so it is pixel-identical
to px/<id>.png). Every other row is cropped by the base's box and shrunk by the same factor, and only
the area the designer changed (with a 1 px margin) is taken from it; everything else is the base's
own pixels. The parts are the base's pixels where the body-only frame differs, so body + parts at
rest is the base exactly.

    .venv/bin/python tools/art/spirit_anim_cut.py

Writes docs/mockups/spirits/anim_frames/<id>/{base,closed,open,happy,sad}.png, the faces without their parts
(<face>_body.png), part_<name>.png, rig.json (each part's kind, box and pivot) and a 6x check sheet per
sheet. The sheets: the pilot, then every anim_prep sheet with a _filled.png (spirit_anim_prep.py).
    .venv/bin/python tools/art/spirit_anim_cut.py [sheet names]

The angry face (2026-11-07) came later, in its own files: row 6 of each <sheet>_filled_v2.png (rows 1-5
and 7 identical to _filled.png) and row 2 of anim_prep/pilot_angry_filled.png (row 1 the base). It is
cut the same way (the base's grid, only the changed face area) into angry.png and angry_body.png:
    .venv/bin/python tools/art/spirit_anim_cut.py --angry
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from october_sheet_cut import CELL, MULT, SP, crops_of, latest, layout, stage  # noqa: E402
from spirit_px import CANVAS, OUTLINE  # noqa: E402

PILOT_DIR = SP / "anim_pilot"
FACES = ["base", "closed", "open", "happy", "sad"]
# the pilot's columns: (realm, id, its moving parts: name -> kind and where it sits, for naming)
PILOT = [
    ("mountain", "kakiage", {}),
    ("fire", "nacho", {"flame": {"kind": "flame"}}),
    ("fire", "popper", {"tassel": {"kind": "swing", "solid": True}}),
    ("fire", "ladyluck", {"bolt": {"kind": "bolt"}}),
    ("mountain", "komainu", {"tongue": {"kind": "flick"}}),
    ("mountain", "tengu", {"cap": {"kind": "slip", "seed": "grey", "solid": True},
                           "tuft_l": {"kind": "flap", "seed": "green", "at": "left"},
                           "tuft_r": {"kind": "flap", "seed": "green", "at": "right"}}),
]


def mask_cell(cell, bg):
    """crops_of's mask, for one 260 px cell (int RGB array) -> RGBA array, full cell."""
    fg = np.abs(cell[..., :3] - bg).sum(2) > 45
    fg = ndimage.binary_opening(fg, iterations=1)
    fg = ndimage.binary_fill_holes(ndimage.binary_closing(fg, iterations=2))
    lab, n = ndimage.label(fg)
    sizes = ndimage.sum(fg, lab, range(1, n + 1))
    keep = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s >= 40])
    out = np.zeros(cell.shape[:2] + (4,), np.uint8)
    out[..., :3] = cell[..., :3]
    out[..., 3] = np.where(keep, 255, 0)
    return out


def shrink_full(rgba, w, h, sharpen=0.4):
    """spirit_px.shrink at a given size, without the final crop: (h+2, w+2, 4), the 1 px pad kept."""
    from PIL import ImageFilter
    a = rgba.astype(float)
    al = a[..., 3:] / 255.0
    pre = np.concatenate([a[..., :3] * al, a[..., 3:]], 2)
    small = np.array(Image.fromarray(pre.astype(np.uint8)).resize((w, h), Image.LANCZOS)).astype(float)
    alpha = small[..., 3] / 255.0
    rgb = small[..., :3] / np.maximum(alpha[..., None], 1e-3)
    out = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8))
    if sharpen:
        out = out.filter(ImageFilter.UnsharpMask(radius=1, percent=int(sharpen * 100), threshold=2))
    rgb = np.array(out).astype(int)
    op = ndimage.binary_fill_holes(np.pad(alpha > 0.5, 1))
    rgb = np.pad(rgb, ((1, 1), (1, 1), (0, 0)))
    edge = op & ~ndimage.binary_erosion(op)
    rgb[edge] = OUTLINE
    res = np.zeros(op.shape + (4,), np.uint8)
    res[..., :3] = np.clip(rgb, 0, 255)
    res[..., 3] = np.where(op, 255, 0)
    res[~op] = 0                                   # (transparent pixels are 0,0,0,0, as place() leaves them)
    return res


def small_mask(diff, box, w, h):
    """A painting-size change mask -> the padded sprite grid (any overlap), grown by 1 px."""
    x0, y0, x1, y1 = box
    d = diff[y0:y1, x0:x1].astype(np.float32)
    s = np.array(Image.fromarray(d * 255).convert("F").resize((w, h), Image.BOX)) > 0.5
    return ndimage.binary_dilation(np.pad(s, 1), structure=np.ones((3, 3)))


def _canvas_f(a, off):
    c = np.zeros((CANVAS, CANVAS), np.float32)
    ox, oy = off
    c[oy:oy + a.shape[0], ox:ox + a.shape[1]] = a
    return c


def to_canvas(full, off):
    c = np.zeros((CANVAS, CANVAS, 4), np.uint8)
    ox, oy = off
    H, W = full.shape[:2]
    c[oy:oy + H, ox:ox + W] = full
    return c


def cut_spirit(sheet, col, realm, sid, parts_cfg, refine=False):
    """refine: keep only the face pixels that clearly changed (and their soft edges); the prep
    sheets' faces were re-rendered with faint noise over a whole box round each face"""
    cols = layout(realm)
    c, r = next((c, r) for c, column in enumerate(cols) for r, s in enumerate(column) if s == sid)
    realm_sheet = np.array(Image.open(latest(realm)).convert("RGB")).astype(int)
    bg = np.median(realm_sheet[:6, :, :3].reshape(-1, 3), 0)
    base_crops = crops_of(SP / f"october_{realm}/{realm}_filled.png", cols)
    f = 34 / np.median([base_crops[(i, 0)].height for i in range(5)])
    rows = [sheet[i * CELL:(i + 1) * CELL, col * CELL:(col + 1) * CELL] for i in range(7)]
    base_rgba = mask_cell(rows[0], bg)
    ys, xs = np.nonzero(base_rgba[..., 3])
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    bw, bh = box[2] - box[0], box[3] - box[1]
    hh = bh * f * MULT[stage(c, r)]
    ww = bw * hh / bh
    h = round(min(hh, 50, hh * 52 / ww))
    w = round(bw * h / bh)

    def full(i):
        x0, y0, x1, y1 = box
        return shrink_full(mask_cell(rows[i], bg)[y0:y1, x0:x1], w, h)

    base = full(0)
    ys, xs = np.nonzero(base[..., 3])
    sbw, sbh = xs.max() - xs.min() + 1, ys.max() - ys.min() + 1
    off = ((CANVAS - sbw) // 2 - xs.min(), 54 + 1 - sbh - ys.min())   # spirit_px.place
    out = {"base": to_canvas(base, off)}
    px = np.array(Image.open(SP / f"october_{realm}/px/{sid}.png").convert("RGBA"))
    if not (out["base"] == px).all():
        bad = np.argwhere((out["base"] != px).any(2))
        raise SystemExit(f"{sid}: the base frame isn't the approved sprite ({len(bad)} px, e.g. {bad[:3].tolist()})")

    def canvas_mask(m):
        return to_canvas(np.repeat(m[..., None], 4, 2).astype(np.uint8), off)[..., 0] > 0

    def coverage(paint_mask):
        """the share of each sprite pixel a painting-size mask covers, on the canvas"""
        x0, y0, x1, y1 = box
        d = paint_mask[y0:y1, x0:x1].astype(np.float32)
        s = np.array(Image.fromarray(d).resize((w, h), Image.BOX))
        return _canvas_f(np.pad(s, 1), off)

    masks = {}
    for i, name in enumerate(FACES[1:], start=1):
        diff = np.abs(rows[i] - rows[0]).sum(2) > 0
        masks[name] = canvas_mask(small_mask(diff, box, w, h))
        var = to_canvas(full(i), off)
        if refine:
            d = np.abs(var.astype(int) - out["base"].astype(int)).sum(2)
            keep = ndimage.binary_dilation(d > 24, structure=np.ones((3, 3))) & (d > 6)
            masks[name] = masks[name] & keep
        frame = out["base"].copy()
        frame[masks[name]] = var[masks[name]]
        out[name] = frame
    report = {n: int(masks[n].sum()) for n in masks}

    rig = {"realm": realm, "parts": {}}
    if parts_cfg:
        # the parts' shapes come from row 7 (the base's own pixels, exact); the body-only painting
        # is used only under them and 1 px round them (its repaint further out is ignored)
        # (raw, without the cut's closing: it would bridge parts that nearly touch)
        p7 = ndimage.binary_fill_holes(np.abs(rows[6] - bg).sum(2) > 45)
        lb, n = ndimage.label(p7, structure=np.ones((3, 3)))
        p7 = np.isin(lb, [j + 1 for j, s in enumerate(ndimage.sum(p7, lb, range(1, n + 1))) if s >= 12])
        names = list(parts_cfg)
        assign = {}
        if len(names) == 1:
            assign = {names[0]: p7}
        else:
            # parts that touch are told apart by colour first (a seed: "green", "grey"), every
            # pixel going to its nearest seed; parts of one colour are then picked by where they sit
            cell = rows[6].astype(int)
            mx, mn = cell.max(2), cell.min(2)
            lum = cell.mean(2)
            seeds = {"green": (cell[..., 1] > cell[..., 0] + 8) & (cell[..., 1] > cell[..., 2] + 8),
                     "grey": (mx - mn < 30) & (lum > 35),
                     "dark": (mx - mn < 30) & (lum > 35) & (lum < 110),
                     "white": (mx - mn < 40) & (lum >= 150),
                     "gold": (cell[..., 0] > cell[..., 2] + 40) & (cell[..., 1] > cell[..., 2] + 20) & (lum > 110),
                     "blue": (cell[..., 2] > cell[..., 0] + 20)}
            kinds = sorted({parts_cfg[nm].get("seed", "all") for nm in names})
            if kinds == ["all"]:
                regions = {"all": p7}
            else:
                lab = np.zeros(p7.shape, int)
                for i, k in enumerate(kinds, start=1):
                    lab[seeds[k] & p7] = i
                idx = ndimage.distance_transform_edt(lab == 0, return_distances=False, return_indices=True)
                near = lab[idx[0], idx[1]]
                regions = {k: p7 & (near == i) for i, k in enumerate(kinds, start=1)}
            for k, region in regions.items():
                group = [nm for nm in names if parts_cfg[nm].get("seed", "all") == k]
                if len(group) == 1:
                    assign[group[0]] = region
                    continue
                lb, n = ndimage.label(region, structure=np.ones((3, 3)))
                comps = sorted([(lb == j) for j in range(1, n + 1)], key=lambda m: -m.sum())
                rest = [nm for nm in group if parts_cfg[nm].get("at") == "rest"]
                group = [nm for nm in group if nm not in rest]
                big = comps[:len(group)]
                cen = [ndimage.center_of_mass(m) for m in big]
                picks = {}
                if rest:                                   # (one part takes every piece the others don't)
                    for nm in group:
                        key = {"top": lambda i: cen[i][0], "left": lambda i: cen[i][1],
                               "right": lambda i: -cen[i][1]}[parts_cfg[nm]["at"]]
                        picks[nm] = min([i for i in range(len(big)) if i not in picks.values()], key=key)
                    for nm, i in picks.items():
                        assign[nm] = big[i].copy()
                    assign[rest[0]] = np.any([m for j, m in enumerate(comps) if j not in picks.values()], 0)
                    continue
                for nm in group:
                    key = {"top": lambda i: cen[i][0], "left": lambda i: cen[i][1],
                           "right": lambda i: -cen[i][1]}[parts_cfg[nm]["at"]]
                    picks[nm] = min([i for i in range(len(big)) if i not in picks.values()], key=key)
                for nm, i in picks.items():
                    assign[nm] = big[i].copy()
                for m in comps[len(group):]:           # crumbs join the nearest part
                    c0 = np.array(ndimage.center_of_mass(m))
                    nm = min(picks, key=lambda q: np.hypot(*(np.array(ndimage.center_of_mass(assign[q])) - c0)))
                    assign[nm] |= m
        if len(assign) > 1:
            # each part keeps its biggest piece; stray bits go to the nearest part's piece
            strays = []
            for nm in assign:
                lb, n = ndimage.label(assign[nm], structure=np.ones((3, 3)))
                if n > 1:
                    keep = 1 + int(np.argmax(ndimage.sum(assign[nm], lb, range(1, n + 1))))
                    strays += [lb == j for j in range(1, n + 1) if j != keep]
                    assign[nm] = lb == keep
            for m in strays:
                d = {nm: ndimage.distance_transform_edt(~assign[nm])[m].min() for nm in assign}
                assign[min(d, key=d.get)] |= m
        under = np.zeros((CANVAS, CANVAS), bool)
        pcore = {}
        opaque = out["base"][..., 3] > 0
        for nm, m in assign.items():
            cov = coverage(m)
            pcore[nm] = (cov > 0.35) & opaque
            under |= cov > 0
        under = ndimage.binary_dilation(under, structure=np.ones((3, 3)))
        bvar = to_canvas(full(5), off)
        # a part is every pixel round it that differs from the body under it (its outline and edge
        # included), each going to the nearest part; the rest stays the approved sprite's own pixels,
        # so the body + its parts at rest is the base exactly
        sep = (np.abs(out["base"].astype(int) - bvar.astype(int))[..., :3].sum(2) > 40) | (bvar[..., 3] == 0)
        cand = under & opaque & sep
        dist = {nm: ndimage.distance_transform_edt(~pcore[nm]) for nm in pcore}
        nearest = np.argmin(np.stack([dist[nm] for nm in pcore]), 0)
        pmasks = {}
        for i, nm in enumerate(pcore):
            core = ndimage.binary_erosion(pcore[nm], structure=np.ones((3, 3)))
            m = ((cand & (nearest == i)) | core) & opaque          # (no holes in it)
            if parts_cfg[nm].get("solid"):
                # a solid part (a cap, a tassel) loses thin strands: opened, then its 1 px rim back
                o = ndimage.binary_opening(m, structure=np.ones((3, 3)))
                lb, n = ndimage.label(o)
                if n:
                    o = lb == 1 + int(np.argmax(ndimage.sum(o, lb, range(1, n + 1))))
                m = ndimage.binary_dilation(o, structure=np.ones((3, 3))) & m
            lb, n = ndimage.label(m, structure=np.ones((3, 3)))
            if n > 1:                                   # (and no loose single pixels)
                sizes = ndimage.sum(m, lb, range(1, n + 1))
                m = np.isin(lb, [j + 1 for j, s in enumerate(sizes) if s >= 3])
            pmasks[nm] = m
        mask_all = np.any(list(pmasks.values()), 0)
        body = out["base"].copy()
        body[mask_all] = bvar[mask_all]
        out["body"] = body
        for nm, m in pmasks.items():
            pimg = np.zeros_like(out["base"])
            pimg[m] = out["base"][m]
            out[f"part_{nm}"] = pimg
            ys, xs = np.nonzero(m)
            kind = parts_cfg[nm]["kind"]
            # the pivot: a tassel hangs from its top, the rest stand on their foot
            py = int(ys.min()) if kind == "swing" else int(ys.max())
            rig["parts"][nm] = {"kind": kind, "box": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
                                "pivot": [int(round(xs.mean())), py]}
        # each face without its parts: the body's pixels under the parts
        for face in FACES:
            fb = out[face].copy()
            keep_face = masks[face] if face in masks else np.zeros_like(under)
            fb[mask_all & ~keep_face] = body[mask_all & ~keep_face]     # (the face's own change wins)
            out[f"{face}_body"] = fb
        rest = body.copy()
        for nm, m in pmasks.items():
            rest[m] = out["base"][m]
        report["under"] = int(under.sum())
        report["rest_vs_base_px"] = int((rest != out["base"]).any(2).sum())
    return out, rig, report


def cut_variant(sheet, col, realm, sid, row, refine=True):
    """One more face from a sheet whose row 1 is the spirit's approved cell: cut on the base's exact
    grid (as cut_spirit), only the changed area taken -> (base, face, changed px)"""
    cols = layout(realm)
    c, r = next((c, r) for c, column in enumerate(cols) for r, s in enumerate(column) if s == sid)
    realm_sheet = np.array(Image.open(latest(realm)).convert("RGB")).astype(int)
    bg = np.median(realm_sheet[:6, :, :3].reshape(-1, 3), 0)
    base_crops = crops_of(SP / f"october_{realm}/{realm}_filled.png", cols)
    f = 34 / np.median([base_crops[(i, 0)].height for i in range(5)])
    rows = {i: sheet[i * CELL:(i + 1) * CELL, col * CELL:(col + 1) * CELL] for i in (0, row)}
    base_rgba = mask_cell(rows[0], bg)
    ys, xs = np.nonzero(base_rgba[..., 3])
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    bw, bh = box[2] - box[0], box[3] - box[1]
    hh = bh * f * MULT[stage(c, r)]
    ww = bw * hh / bh
    h = round(min(hh, 50, hh * 52 / ww))
    w = round(bw * h / bh)

    def full(i):
        x0, y0, x1, y1 = box
        return shrink_full(mask_cell(rows[i], bg)[y0:y1, x0:x1], w, h)

    base = full(0)
    ys, xs = np.nonzero(base[..., 3])
    sbw, sbh = xs.max() - xs.min() + 1, ys.max() - ys.min() + 1
    off = ((CANVAS - sbw) // 2 - xs.min(), 54 + 1 - sbh - ys.min())
    base = to_canvas(base, off)
    px = np.array(Image.open(SP / f"october_{realm}/px/{sid}.png").convert("RGBA"))
    if not (base == px).all():
        raise SystemExit(f"{sid}: the base frame isn't the approved sprite")
    diff = np.abs(rows[row] - rows[0]).sum(2) > 0
    m = to_canvas(np.repeat(small_mask(diff, box, w, h)[..., None], 4, 2).astype(np.uint8), off)[..., 0] > 0
    var = to_canvas(full(row), off)
    if refine:
        d = np.abs(var.astype(int) - base.astype(int)).sum(2)
        m &= ndimage.binary_dilation(d > 24, structure=np.ones((3, 3))) & (d > 6)
    face = base.copy()
    face[m] = var[m]
    return base, face, int(m.sum())


def angry_sheets():
    """(name, file, row index, [(realm, id)]): the pilot's angry sheet, then each prep sheet's v2"""
    out = [("pilot_angry", SP / "anim_prep/pilot_angry_filled.png", 1, [(rl, sid) for rl, sid, _ in PILOT])]
    for s in json.loads((SP / "anim_prep/manifest.json").read_text())["sheets"]:
        f = SP / f"anim_prep/{s['name']}_filled_v2.png"
        if f.exists():
            out.append((s["name"], f, 5, [(e["realm"], e["id"]) for e in s["spirits"]]))
    return out


def main_angry():
    dest = SP / "anim_frames"
    done = {}
    for name, path, row, spirits in angry_sheets():
        sheet = np.array(Image.open(path).convert("RGB")).astype(int)
        for col, (realm, sid) in enumerate(spirits):
            base, face, n = cut_variant(sheet, col, realm, sid, row)
            d = dest / sid
            Image.fromarray(face).save(d / "angry.png")
            # without its parts: the body under the parts wherever the face didn't change (spirit_parts.build)
            if (d / "base_body.png").exists():
                body = np.array(Image.open(d / "base_body.png").convert("RGBA"))
                same = (body != base).any(2) & (face == base).all(2)
                fb = face.copy()
                fb[same] = body[same]
                Image.fromarray(fb).save(d / "angry_body.png")
            done[sid] = (realm, n)
            if n == 0:
                print("NO CHANGE:", name, sid)
    print(len(done), "angry faces;", sum(1 for v in done.values() if v[1] == 0), "unchanged")
    return done


def check_sheet(all_out, k=6):
    names = FACES + ["body"]
    W = CANVAS * k
    sh = Image.new("RGBA", (len(all_out) * (W + 8) + 8, (len(names) + 1) * (W + 8) + 8), (74, 44, 34, 255))
    d = ImageDraw.Draw(sh)
    for i, (sid, out) in enumerate(all_out.items()):
        x = 8 + i * (W + 8)
        d.text((x, 0), sid, fill=(240, 230, 245))
        for j, nm in enumerate(names + ["parts"]):
            if nm == "parts":
                im = np.zeros_like(out["base"])
                for key in out:
                    if key.startswith("part_"):
                        m = out[key][..., 3] > 0
                        im[m] = out[key][m]
            else:
                im = out.get(nm, out["base"])
            sh.alpha_composite(Image.fromarray(im).resize((W, W), Image.NEAREST), (x, 10 + j * (W + 8)))
    return sh


def sheets():
    """(name, filled sheet, [(realm, id, parts)]): the pilot, then each prep sheet once it's filled."""
    out = [("pilot", PILOT_DIR / "pilot_filled.png", PILOT)]
    man = SP / "anim_prep/manifest.json"
    if man.exists():
        for s in json.loads(man.read_text())["sheets"]:
            f = SP / f"anim_prep/{s['name']}_filled.png"
            if f.exists():
                out.append((s["name"], f, [(e["realm"], e["id"], e["parts"]) for e in s["spirits"]]))
    return out


def main(only=None):
    dest = SP / "anim_frames"
    rigs_path = dest / "rig.json"
    rigs = json.loads(rigs_path.read_text()) if rigs_path.exists() else {}
    for name, path, spirits in sheets():
        if only and name not in only:
            continue
        sheet = np.array(Image.open(path).convert("RGB")).astype(int)
        all_out = {}
        for col, (realm, sid, parts) in enumerate(spirits):
            # (the prep sheets have faces only: their parts are made in code, spirit_parts.py)
            pilot = name == "pilot"
            out, rig, report = cut_spirit(sheet, col, realm, sid, parts if pilot else {}, refine=not pilot)
            d = dest / sid
            d.mkdir(parents=True, exist_ok=True)
            for nm, im in out.items():
                Image.fromarray(im).save(d / f"{nm}.png")
            if name == "pilot" or sid not in rigs:
                rigs[sid] = rig
            all_out[sid] = out
            print(name, sid, report, {k: v["pivot"] for k, v in rig["parts"].items()})
        check_sheet(all_out).save(dest / f"check_{name}_6x.png")
    dest.mkdir(parents=True, exist_ok=True)
    rigs_path.write_text(json.dumps(rigs, indent=1))


if __name__ == "__main__":
    if "--angry" in sys.argv:
        main_angry()
    else:
        main(sys.argv[1:] or None)
