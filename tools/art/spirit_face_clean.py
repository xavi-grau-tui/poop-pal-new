"""Clean the spirits' face frames so a face change only changes the face (2026-11-07, the user:
"some animations are a bit glitchy with colour changes ... we need something very clean").

The designer's faces are ImageGen edits pasted on the approved sheet: besides the drawn features
they re-tint the whole face box a little, and spirit_anim_cut.py's refine kept that tint wherever it
touched a feature (300-500 off-tone pixels a face), so the face area shimmered at every blink or
expression. Here each face is rebuilt from the approved base:

  - kept: only the pixels that clearly changed (the drawn eyes, brows, mouths, and where an old eye
    was painted over); a pixel that moved less than that goes back to the base (the difference
    can't be seen, the shimmer could), and lone specks are dropped
  - a kept pixel close to the body colour right round it IS that body colour (the paint-over of an
    open eye becomes the exact skin, not a near-skin), a kept line close to one of the sprite's own
    colours becomes that colour
  - everything else is the base, pixel for pixel; the silhouette never changes (no new opaque pixel
    outside it, none lost)

The faces as cut are kept in anim_frames/<id>/raw_faces/ (first run only), so this can be rerun.
Run spirit_parts.py afterwards: the <face>_body.png frames are made from these faces.

    .venv/bin/python tools/art/spirit_face_clean.py [ids]      -> anim_frames/<id>/<face>.png
                                                               + anim_frames/face_clean_check_<n>.png
"""
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from october_sheet_cut import SP  # noqa: E402

D = SP / "anim_frames"
FACES = ["closed", "open", "happy", "sad", "angry"]
STRONG, FILL, SNAP = 40, 36, 30


def clean(base, face):
    b = base.astype(int)
    f = face.astype(int)
    inside = b[..., 3] > 0
    d = np.abs(f[..., :3] - b[..., :3]).sum(2) * inside
    strong = d > STRONG
    keep = strong.copy()
    lab, n = ndimage.label(keep, structure=np.ones((3, 3)))
    for i, sl in enumerate(ndimage.find_objects(lab), 1):
        comp = lab[sl] == i
        if comp.sum() <= 2 and d[sl][comp].max() < 120:
            keep[sl][comp] = False
    out = b.copy()
    pal = np.unique(b[inside][:, :3], axis=0)
    H, W = keep.shape
    for y, x in zip(*np.nonzero(keep)):
        c = f[y, x, :3]
        y0, y1, x0, x1 = max(0, y - 2), min(H, y + 3), max(0, x - 2), min(W, x + 3)
        win = ~keep[y0:y1, x0:x1] & inside[y0:y1, x0:x1]
        local = b[y0:y1, x0:x1][win][:, :3]
        if len(local):
            dl = np.abs(local - c).sum(1)
            if dl.min() < FILL:
                out[y, x, :3] = local[dl.argmin()]
                continue
        dp = np.abs(pal - c).sum(1)
        out[y, x, :3] = pal[dp.argmin()] if dp.min() < SNAP else c
    # a kept pixel that ended up within the threshold of the base is the base (no faint flicker)
    back = (np.abs(out[..., :3] - b[..., :3]).sum(2) <= STRONG) & keep
    out[back] = b[back]
    out[..., 3] = b[..., 3]
    return out.astype(np.uint8), int(keep.sum()), int(((face != base).any(2)).sum())


def main(only):
    ids = only or sorted(p.name for p in D.iterdir() if p.is_dir() and (p / "base.png").exists())
    tiles, report = [], []
    for sid in ids:
        sd = D / sid
        raw = sd / "raw_faces"
        raw.mkdir(exist_ok=True)
        base = np.array(Image.open(sd / "base.png").convert("RGBA"))
        row = [base]
        for fc in FACES:
            if not (sd / f"{fc}.png").exists():
                continue
            if not (raw / f"{fc}.png").exists():
                shutil.copy2(sd / f"{fc}.png", raw / f"{fc}.png")
            face = np.array(Image.open(raw / f"{fc}.png").convert("RGBA"))
            out, kept, was = clean(base, face)
            Image.fromarray(out).save(sd / f"{fc}.png")
            row += [face, out]
            report.append((sid, fc, was, kept))
        tiles.append((sid, row))
    # check sheets: base, then each face as cut | cleaned, on the shrine wood, 4x
    K, per = 4, 30
    for n in range(0, len(tiles), per):
        chunk = tiles[n:n + per]
        w = 11 * 56 * K + 10 * 4
        sheet = Image.new("RGB", (w + 120, len(chunk) * (56 * K + 6)), (30, 26, 34))
        dr = ImageDraw.Draw(sheet)
        for r, (sid, row) in enumerate(chunk):
            y = r * (56 * K + 6)
            dr.text((4, y + 4), sid, fill=(235, 225, 245))
            for c, im in enumerate(row):
                can = Image.new("RGBA", (56, 56), (74, 44, 34, 255))
                can.alpha_composite(Image.fromarray(im))
                sheet.paste(can.convert("RGB").resize((56 * K, 56 * K), Image.NEAREST), (120 + c * (56 * K + 4), y))
        sheet.save(D / f"face_clean_check_{n // per + 1}.png")
    for sid, fc, was, kept in report:
        print(f"{sid:14s} {fc:7s} changed {was:4d} -> {kept:4d}")


if __name__ == "__main__":
    main(sys.argv[1:] or None)
