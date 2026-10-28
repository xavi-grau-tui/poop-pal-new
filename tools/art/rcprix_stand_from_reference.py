"""SUPERSEDED for the front and back by the designer's repaint (rcprix_stand_final_grid.py); run plainly it
only makes the side views from the current front. The spectator stand's game pieces from the designer's approved front picture (the user, 2026-10-27:
round15_front_open_gaps_imagegen_reference.png is the design; the designer's tool can't draw the other
views or exact sizes). Run from the repo root:

    <python with Pillow + numpy + scipy> tools/art/rcprix_stand_from_reference.py

The picture is drawn on 5 px blocks: one pixel per block is one game pixel (crisp, the road's density).
Its stray red pixels in the gaps go. It's split in two layers, the game drawing the pals between them:
  front_under  the benches, posts and side frames
  front_over   the awning (the top row of pals sits half under it)
and each layer in three pieces cut at the same place between two posts: end_a, a middle the game
repeats (one post spacing, seamless) and end_b. From behind and from the side the game uses the same
pieces (rc_racer Crowd: turned on its side; from behind darker benches, the posts over the pals), so
the stand from behind comes from the user's chosen rear picture (round16_back_chosen_reference.png),
split at the canopy's top edge: softly painted, so averaged down to the same size as the front (its width at the front's scale,
squashed to the front's depth: seen from above at an angle) and locked to its own colours:
  back_under   the four bench rows seen from behind and the upper side frames
  back_over    the canopy from behind and the six legs, drawn over the pals"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs/mockups/rcprix_garden/round15_front_open_gaps_imagegen_reference.png"
OUT = ROOT / "textures/minigames/rcprix/garden"
BLOCK = 5.0                     # the picture's pixel: one game pixel
PHASE = (3.1, 2.1)              # where its blocks start (x, y), measured
AWNING_BELOW = 216              # source rows above this are the awning (save the side frames)
FRAME_X = (115, 1975)           # the side frames: left of / right of these source columns
POSTS = (454, 848, 1267, 1659)  # its bench posts' centres (source x)
CUT_BEFORE_POST = 214           # the pieces are cut this far (source px) before a post: mid-bench
COLOURS = 20
REAR = ROOT / "docs/mockups/rcprix_garden/round16_back_chosen_reference.png"   # the user's chosen rear (same canvas as the front)
REAR_ROWS = (27, 662)           # the rear's top and bottom (source rows), squashed into the front's depth
REAR_CANOPY_FROM = 309          # source rows from here down (the canopy and the legs) go over the pals


def sample(src):
    """One pixel per block, the block's centre: [rgb, alpha] at the game's size, and each pixel's source x/y"""
    a = np.asarray(src).astype(int)
    xs = np.arange(PHASE[0] + BLOCK / 2, a.shape[1], BLOCK).astype(int)
    ys = np.arange(PHASE[1] + BLOCK / 2, a.shape[0], BLOCK).astype(int)
    s = a[ys][:, xs]
    return s, xs, ys


def rear(xs, depth):
    """The rear's two layers at the front's columns (the same posts: the same cuts) and depth"""
    whole = np.asarray(Image.open(REAR).convert("RGBA")).copy()
    top, bottom = whole.copy(), whole.copy()
    top[REAR_CANOPY_FROM:, :, 3] = 0
    bottom[:REAR_CANOPY_FROM, :, 3] = 0
    under, over = Image.fromarray(top), Image.fromarray(bottom)
    x_from = int(xs[0] - BLOCK / 2)
    box = (x_from, REAR_ROWS[0], x_from + int(len(xs) * BLOCK), REAR_ROWS[1])
    shrunk = {}
    for name, im in (("back_under", under), ("back_over", over)):
        a = np.asarray(im.crop(box)).astype(float)
        al = a[..., 3:] / 255.0
        pm = Image.fromarray(np.uint8(np.dstack([a[..., :3] * al, a[..., 3:]]))).resize((len(xs), depth), Image.BOX)
        b = np.asarray(pm).astype(float)
        alpha = b[..., 3] > 128
        rgb = b[..., :3] / np.maximum(b[..., 3:] / 255.0, 1e-3)
        shrunk[name] = (rgb, alpha)
    allpx = np.concatenate([rgb[m] for rgb, m in shrunk.values()]).astype(np.uint8)
    pal_img = Image.fromarray(allpx.reshape(1, -1, 3)).quantize(COLOURS, method=Image.Quantize.MEDIANCUT)
    pal = np.array(pal_img.getpalette()[:COLOURS * 3]).reshape(-1, 3)
    out = {}
    for name, (rgb, alpha) in shrunk.items():
        px = np.zeros(alpha.shape + (4,), np.uint8)
        px[..., :3] = pal[np.linalg.norm(rgb[..., None, :] - pal[None, None], axis=-1).argmin(-1)]
        px[..., 3] = alpha * 255
        out[name] = px
    return out


def main():
    src = Image.open(SRC).convert("RGBA")
    s, xs, ys = sample(src)
    rgb, alpha = s[..., :3], s[..., 3] > 128
    red = (rgb[..., 0] > 150) & (rgb[..., 1] < 90) & (rgb[..., 2] < 90)   # the picture's stray red marks
    alpha &= ~red
    alpha = ndimage.binary_opening(alpha, np.ones((2, 1))) | ndimage.binary_opening(alpha, np.ones((1, 2)))
    # one palette, the picture's own colours
    pal_img = Image.fromarray(rgb[alpha].astype(np.uint8).reshape(1, -1, 3)).quantize(COLOURS, method=Image.Quantize.MEDIANCUT)
    pal = np.array(pal_img.getpalette()[:COLOURS * 3]).reshape(-1, 3)
    rgb = pal[np.linalg.norm(rgb[..., None, :] - pal[None, None], axis=-1).argmin(-1)]
    # the layers
    sy = ys[:, None] + 0 * xs[None, :]
    sx = xs[None, :] + 0 * ys[:, None]
    frames = (sx < FRAME_X[0]) | (sx > FRAME_X[1])
    awning = alpha & (sy < AWNING_BELOW) & ~frames
    under = alpha & ~awning
    gap_rows = alpha.sum(1) < alpha.shape[1] * 0.5
    bench_rows = ~gap_rows

    def img(mask, darken=1.0):
        px = np.zeros(mask.shape + (4,), np.uint8)
        px[..., :3] = np.clip(rgb * darken, 0, 255)
        px[..., 3] = mask * 255
        return px

    layers = {"front_under": img(under), "front_over": img(awning)}
    # crop to the whole stand, then cut the pieces between two posts (same place each time: seamless)
    rows = np.flatnonzero(alpha.any(1))
    cols = np.flatnonzero(alpha.any(0))
    y0, y1, x0, x1 = rows[0], rows[-1] + 1, cols[0], cols[-1] + 1
    col_of = lambda x: int(np.argmin(np.abs(xs - x)))
    c0 = col_of(POSTS[0] - CUT_BEFORE_POST)
    period = round((POSTS[-1] - POSTS[0]) / (len(POSTS) - 1) / BLOCK)
    c_end = col_of(POSTS[-1] - CUT_BEFORE_POST) + period
    sizes = {}
    layers = {k: v[y0:y1] for k, v in layers.items()}
    layers.update(rear(xs, y1 - y0))
    for name, px in layers.items():
        parts = {"end_a": px[:, x0:c0], "mid": px[:, c0:c0 + period], "end_b": px[:, c_end:x1]}
        for part, a in parts.items():
            Image.fromarray(a).save(OUT / f"stand_{name}_{part}.png")
            sizes[part] = (a.shape[1], a.shape[0])
            if name.startswith("front"):         # beside the track: the front turned on its side, its back (the awning) outward
                side = Image.fromarray(a).rotate(-90, expand=True)
                layer = name.split("_")[1]
                side.save(OUT / f"stand_side_r_{layer}_{part}.png")
                side.transpose(Image.FLIP_LEFT_RIGHT).save(OUT / f"stand_side_l_{layer}_{part}.png")
    print("stand pieces:", sizes, "rows of benches (px from the top):", list(np.flatnonzero(np.diff(bench_rows[y0:y1].astype(int)) == 1) + 1))


def sides():
    """The side views from the front pieces as they are now (the designer's final-grid repaint), turned"""
    for layer in ("under", "over"):
        for part in ("end_a", "mid", "end_b"):
            side = Image.open(OUT / f"stand_front_{layer}_{part}.png").rotate(-90, expand=True)
            side.save(OUT / f"stand_side_r_{layer}_{part}.png")
            side.transpose(Image.FLIP_LEFT_RIGHT).save(OUT / f"stand_side_l_{layer}_{part}.png")
    print("side views made from the front pieces")


if __name__ == "__main__":
    # (the front and back are now the designer's repaint, tools/art/rcprix_stand_final_grid.py: only
    # --convert makes them again from the pictures, overwriting it)
    import sys
    if "--convert" in sys.argv:
        main()
    sides()
