"""Re-pixelate the console art (buttons, screen frame...) on a finer grid, so its pixels match
the pals and foods (~5 screen px per art pixel) instead of the old chunky ~8-9 px.

The design stays the same: each new (smaller) pixel takes the most common colour of its
patch from the image's own palette (lines and icons survive, no new colours, no blur), and
only the silhouette is softened a little so the big stair-steps of the corners round off.

    python3 tools/art/repixel.py            -> overwrites the listed textures (originals kept
                                              in tools/art/out/repixel_originals/ the first time)
"""
import os, shutil
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.join(HERE, '..', '..')
KEEP = os.path.join(HERE, 'out', 'repixel_originals')

TARGET = 5.0                              # screen px per art pixel (the pals are ~5.3)

# texture -> (screen scale it is shown at, silhouette softening in texture px[, palette size,
#             keep the icon in the middle exactly as drawn: True, or the texture to find it on])
JOBS = {
    'textures/buttons/mainbuttonnormal.png': (1.0, 3.0),
    'textures/buttons/mainbuttonpressed.png': (1.0, 3.0),
    'textures/buttons/soundbuttonnormal.png': (1.0, 3.0, 40, True),   # (keeps its icon as drawn)
    'textures/buttons/soundbuttonpressed.png': (1.0, 3.0, 40, 'textures/buttons/soundbuttonnormal.png'),
    'textures/buttons/forwardbuttonnormal.png': (1.0, 3.0, 40, True),   # (keeps its icon as drawn)
    'textures/buttons/forwardbuttonpressed.png': (1.0, 3.0, 40, 'textures/buttons/forwardbuttonnormal.png'),
    'textures/pet-background/frame1.png': (1.27, 1.5, 8),  # the pet cam window (soft art: few colours)
}


def palette_of(img, n=40):
    q = img.convert('RGB').quantize(colors=n, method=Image.Quantize.MEDIANCUT)
    pal = np.array(q.getpalette()[:n * 3], np.float32).reshape(-1, 3)
    return pal


def repixel(src, scale, soften, colors=40, keep_icon=False):
    w, h = src.size
    block = max(1, round(TARGET / scale))                   # texture px per new art pixel (whole)
    gw, gh = -(-w // block), -(-h // block)
    W, H = gw * block, gh * block
    a = np.zeros((H, W, 4), np.uint8)
    a[:h, :w] = np.asarray(src.convert('RGBA'))
    # colours: each new pixel takes the MOST COMMON palette colour of its patch (so thin
    # dark lines and icons survive, nothing gets averaged into mud)
    pal = palette_of(src, colors)
    n = len(pal)
    rgb = a[..., :3].astype(np.float32)
    idx = ((rgb[:, :, None, :] - pal[None, None]) ** 2).sum(-1).argmin(-1)
    opaque = a[..., 3] > 128
    votes = np.zeros((gh, gw, n), np.int32)
    blk = lambda m: m.reshape(gh, block, gw, block).sum((1, 3))
    dark = 1.0 + 1.6 * (1.0 - pal.mean(-1) / 255.0)          # thin dark lines win their patches
    for k in range(n):
        votes[..., k] = blk((idx == k) & opaque) * dark[k] * 100
    col = pal[votes.argmax(-1)]
    has_col = votes.sum(-1) > 0
    # shape: the silhouette softened a little, so the big corner stair-steps round off
    al = Image.fromarray(a[..., 3]).filter(ImageFilter.GaussianBlur(soften))
    alpha = np.asarray(al.resize((gw, gh), Image.BOX), np.float32)
    keep = alpha > 128
    # a pixel that became opaque without colour of its own borrows its neighbour's
    from scipy import ndimage
    if (keep & ~has_col).any():
        _, (iy, ix) = ndimage.distance_transform_edt(~has_col, return_indices=True)
        col = col[iy, ix]
    out = np.zeros((gh, gw, 4), np.uint8)
    out[..., :3] = col.clip(0, 255)
    out[..., 3] = np.where(keep, 255, 0)
    big = Image.fromarray(out, 'RGBA').resize((W, H), Image.NEAREST).crop((0, 0, w, h))
    if keep_icon:
        # the icon (dark marks inside the button face) is pasted back exactly as drawn: thin
        # diagonal strokes can't land cleanly on a grid of another size
        orig = np.asarray(src.convert('RGBA'))
        # (a pressed button finds its icon on the normal one: same place, but its darker
        # face would get mistaken for ink)
        ref = orig if keep_icon is True else np.asarray(Image.open(_original(keep_icon)).convert('RGBA'))
        m = 22                                              # clear of the outline and the bevel
        inner = np.zeros(ref.shape[:2], bool)
        inner[m:-m, m:-m] = True
        dark = ref[..., :3].astype(int).mean(-1) < 70             # the ink
        ys, xs = np.nonzero(inner & dark & (ref[..., 3] > 128))
        if len(xs):
            x0, x1, y0, y1 = xs.min() - 3, xs.max() + 4, ys.min() - 3, ys.max() + 4
            res = np.asarray(big).copy()
            res[y0:y1, x0:x1] = orig[y0:y1, x0:x1]
            big = Image.fromarray(res, 'RGBA')
            print('   icon kept as drawn:', (x0, y0, x1, y1))
    return big


def _original(rel):
    return os.path.join(KEEP, rel.replace('/', '__'))


if __name__ == '__main__':
    os.makedirs(KEEP, exist_ok=True)
    for rel, job in JOBS.items():
        scale, soften = job[0], job[1]
        colors = job[2] if len(job) > 2 else 40
        keep_icon = job[3] if len(job) > 3 else False
        path = os.path.join(PROJ, rel)
        keep = os.path.join(KEEP, rel.replace('/', '__'))
        if not os.path.exists(keep):
            shutil.copy(path, keep)                         # always work from the original
        out = repixel(Image.open(keep), scale, soften, colors, keep_icon)
        out.save(path)
        print(rel, out.size)
