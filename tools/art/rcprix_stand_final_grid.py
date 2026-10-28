"""Repaint the approved front/rear stand references on RC Prix's 1 px art grid.

This is a deterministic pixel-grid conversion, not image generation. It writes only
stand_front_* and stand_back_* under/over end/mid pieces. Side sprites are untouched.

    .venv/bin/python3 tools/art/rcprix_stand_final_grid.py
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/garden"
MOCK = ROOT / "docs/mockups/rcprix_garden"
FRONT = MOCK / "round15_front_open_gaps_imagegen_reference.png"
BACK = MOCK / "round16_back_chosen_reference.png"

CANVAS_W, DEPTH = 422, 107
BLOCK = 5.0
PHASE_X, PHASE_Y = 3.1, 2.1
FRONT_AWNING_BELOW = 216
FRAME_X = (115, 1975)
POSTS = (454, 848, 1267, 1659)
CUT_BEFORE_POST = 214
BACK_ROWS = (27, 662)
BACK_OVER_FROM = 315
BACK_CANOPY_EXTENSION = 2

OUTLINE = np.array((0x28, 0x1E, 0x28), np.uint8)
WOOD_FRONT = np.array(((0x70, 0x43, 0x2F), (0xA6, 0x5D, 0x34),
                       (0xD4, 0x86, 0x48), (0xF4, 0xB7, 0x6C)), np.uint8)
WOOD_BACK = np.array(((0x5D, 0x37, 0x2D), (0x8C, 0x50, 0x34),
                      (0xB9, 0x70, 0x43), (0xD9, 0x98, 0x5C)), np.uint8)
GREENS = np.array(((0x1C, 0x60, 0x37), (0x2D, 0x82, 0x43), (0x54, 0xA2, 0x5B)), np.uint8)
CREAMS = np.array(((0xC9, 0xB8, 0x89), (0xE7, 0xD8, 0xB3), (0xFA, 0xEC, 0xCA)), np.uint8)


def nearest_palette(rgb, palette):
    delta = rgb.astype(np.int16)[..., None, :] - palette.astype(np.int16)
    return palette[np.square(delta).sum(axis=-1).argmin(axis=-1)]


def classify(rgb, alpha):
    r, g, b = rgb.astype(np.int16).transpose(2, 0, 1)
    green = alpha & (g > r * 1.12) & (g > b * 1.04) & ((g - r) > 14)
    cream = alpha & ~green & (r > 145) & (g > 125) & (b > 86) & ((r - b) < 145)
    return green, cream


def crisp_pixels(rgb, alpha, rear=False):
    """Map each sampled source pixel onto a small fixed palette and one-pixel outline."""
    green, cream = classify(rgb, alpha)
    wood = WOOD_BACK if rear else WOOD_FRONT
    out = nearest_palette(rgb, wood)
    out[green] = nearest_palette(rgb, GREENS)[green]
    out[cream] = nearest_palette(rgb, CREAMS)[cream]

    luma = (rgb.astype(np.uint16) * np.array((3, 6, 1), np.uint16)).sum(axis=2) // 10
    dark_internal = alpha & (luma < 48)
    out[dark_internal] = OUTLINE
    border = alpha & ~ndimage.binary_erosion(alpha, structure=np.ones((3, 3), bool), border_value=0)
    out[border] = OUTLINE

    rgba = np.zeros((*alpha.shape, 4), np.uint8)
    rgba[..., :3] = out
    rgba[..., 3] = alpha.astype(np.uint8) * 255
    return rgba, green, cream


def front_grid():
    src = np.asarray(Image.open(FRONT).convert("RGBA"))
    xs = np.arange(PHASE_X + BLOCK / 2, src.shape[1], BLOCK).astype(int)
    ys = np.arange(PHASE_Y + BLOCK / 2, src.shape[0], BLOCK).astype(int)
    rgba = src[ys[:, None], xs[None, :]]
    rgb = rgba[..., :3]
    alpha = rgba[..., 3] > 128
    rows, cols = np.flatnonzero(alpha.any(1)), np.flatnonzero(alpha.any(0))
    y0, y1 = int(rows[0]), int(rows[-1] + 1)
    x0, x1 = int(cols[0]), int(cols[-1] + 1)
    if y1 - y0 != DEPTH:
        raise ValueError(f"front depth changed: {y1-y0}, expected {DEPTH}")
    crisp, green, cream = crisp_pixels(rgb[y0:y1], alpha[y0:y1])

    sy = ys[y0:y1, None]
    sx = xs[None, :]
    end_frames = (sx < FRAME_X[0]) | (sx > FRAME_X[1])
    # The awning cloth and scalloped edge sit over the audience; its timber end frames stay below.
    over_mask = alpha[y0:y1] & (sy < FRONT_AWNING_BELOW) & ~end_frames
    under_mask = alpha[y0:y1] & ~over_mask
    under = crisp.copy()
    under[..., 3] *= under_mask.astype(np.uint8)
    over = crisp.copy()
    over[..., 3] *= over_mask.astype(np.uint8)

    c0 = int(np.argmin(np.abs(xs - (POSTS[0] - CUT_BEFORE_POST))))
    period = round((POSTS[-1] - POSTS[0]) / (len(POSTS) - 1) / BLOCK)
    c_end = int(np.argmin(np.abs(xs - (POSTS[-1] - CUT_BEFORE_POST)))) + period
    pieces = {}
    for layer, px in (("under", under), ("over", over)):
        cropped = px[:, x0:x1]
        parts = {"end_a": cropped[:, :c0-x0],
                 "mid": cropped[:, c0-x0:c0-x0+period],
                 "end_b": cropped[:, c_end-x0:]}
        pieces.update({f"stand_front_{layer}_{name}": img for name, img in parts.items()})
    return pieces, (x0, x1, y0, y1, c0, c_end)


def back_grid(front_cuts):
    src = np.asarray(Image.open(BACK).convert("RGBA"))
    xs = np.arange(PHASE_X + BLOCK / 2, src.shape[1], BLOCK).astype(int)
    ys = np.rint(BACK_ROWS[0] + (np.arange(DEPTH) + 0.5) *
                 (BACK_ROWS[1] - BACK_ROWS[0]) / DEPTH).astype(int)
    rgba = src[ys[:, None], xs[None, :]]
    rgb = rgba[..., :3]
    alpha = rgba[..., 3] > 128
    crisp, green, cream = crisp_pixels(rgb, alpha, rear=True)

    source_y = ys[:, None]
    # Canopy plus rear legs/side frame overlay the pals. Benches remain in the under layer.
    over_mask = alpha & (source_y >= BACK_OVER_FROM)
    under_mask = alpha & ~over_mask
    cloth = (green | cream) & (source_y >= 290) & (source_y <= 420)
    canopy_rows = np.flatnonzero(cloth.sum(1) > 100)
    if len(canopy_rows):
        first = int(canopy_rows[0])
        for offset in range(1, BACK_CANOPY_EXTENSION + 1):
            y = first - offset
            if y < 0:
                continue
            # Continue each vertical stripe upward, with a one-pixel dark top edge.
            pattern = cloth[first]
            crisp[y, pattern, :3] = crisp[first, pattern, :3]
            crisp[y, pattern, 3] = 255
            over_mask[y, pattern] = True
            under_mask[y, pattern] = True  # the canopy draws over this bench row
        # Put the specified outline across the extended roof's upper silhouette.
        first_ext = max(0, first - BACK_CANOPY_EXTENSION)
        roof_row = np.flatnonzero(over_mask[first_ext])
        if len(roof_row):
            crisp[first_ext, roof_row, :3] = OUTLINE

    under = crisp.copy()
    under[..., 3] *= under_mask.astype(np.uint8)
    over = crisp.copy()
    over[..., 3] *= over_mask.astype(np.uint8)

    x0, x1, _, _, c0, c_end = front_cuts
    pieces = {}
    for layer, px in (("under", under), ("over", over)):
        cropped = px[:, x0:x1]
        parts = {"end_a": cropped[:, :c0-x0],
                 "mid": cropped[:, c0-x0:c0-x0+80],
                 "end_b": cropped[:, c_end-x0:]}
        pieces.update({f"stand_back_{layer}_{name}": img for name, img in parts.items()})
    return pieces


def lock_repeat_seam(image):
    """Give the repeating mid tile identical pixels at its two vertical boundaries."""
    left, right = image[:, 0].copy(), image[:, -1].copy()
    choose_right = (left[:, 3] == 0) & (right[:, 3] > 0)
    shared = left.copy()
    shared[choose_right, :] = right[choose_right, :]
    image[:, 0] = shared
    image[:, -1] = shared
    return image


def main():
    front, cuts = front_grid()
    pieces = {**front, **back_grid(cuts)}
    for name, rgba in pieces.items():
        if name.endswith("_mid"):
            rgba = lock_repeat_seam(rgba)
        target = OUT / f"{name}.png"
        expected = {"end_a": (41, DEPTH), "mid": (80, DEPTH), "end_b": (47, DEPTH)}
        part = next(key for key in expected if name.endswith(key))
        if rgba.shape[1::-1] != expected[part]:
            raise ValueError(f"{name}: got {rgba.shape[1::-1]}, expected {expected[part]}")
        Image.fromarray(rgba, "RGBA").save(target)
        print(target.name, rgba.shape[1], "x", rgba.shape[0])


if __name__ == "__main__":
    main()
