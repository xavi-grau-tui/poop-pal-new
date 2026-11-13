#!/usr/bin/env python3
"""Tomo Tunes: a world's painted layers (the designer's, 1900 x 1896, docs/mockups/tomo_tunes/round1/) made into the
game's pixel layers: 1 art pixel = 6 painted pixels = 3 screen pixels (the user, 2026-11-13: "3x"), a few
colours per layer, hard alpha. Writes textures/minigames/tunes/<world>/<layer>.png, each cropped to its own box, and
layout.json with every layer's place (in art pixels; the game draws at x3).

    .venv/bin/python tools/design/tunes_world.py            (world 1, the toy xylophone)

Ours, not the designer's: the coloured bands on the wall inside xylophone.png don't line up with the bars, so they are
cut and the lanes are made here (lane_*.png: soft light down the wall, fading at the top); the notes get a dark
outline so a mint bead reads on the mint lane; glow.png sits behind a falling note.
"""
import json
import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, 'docs', 'mockups', 'tomo_tunes', 'round1')
OUT = os.path.join(ROOT, 'textures', 'minigames', 'tunes', 'xylophone')
W, H = 317, 316                       # 950 x 948 on screen at x3
WALL_CUT = 1172                       # xylophone.png above this row = the misaligned wall bands
LAYERS = ['room', 'xylophone', 'toy_kokeshi_bench', 'toy_kokeshi', 'toy_daruma', 'toy_ball', 'toy_maneki', 'toy_maneki_paw',
          'toy_top', 'bar_low', 'bar_mid', 'bar_high', 'bar_low_lit', 'bar_mid_lit', 'bar_high_lit',
          'note_low', 'note_mid', 'note_high', 'note_gold', 'mallet']
OUTLINE = (74, 44, 32)
LANES = {'low': (505, (246, 150, 180)), 'mid': (995, (250, 206, 110)), 'high': (1430, (150, 220, 190))}   # the bars' centres (painted px)
LANE_W, LANE_TOP, LANE_BOTTOM = 46, 34, 196       # art px: the wall above the tray


def small(name):
    """the layer at the game's size: premultiplied box filter, hard alpha"""
    im = np.asarray(Image.open(os.path.join(SRC, name + '.png')).convert('RGBA')).astype(np.float32) / 255.0
    if name == 'xylophone':
        im = im.copy(); im[:WALL_CUT, :, 3] = 0.0
    a = im[..., 3:4]
    pre = Image.fromarray((np.concatenate([im[..., :3] * a, a], 2) * 255).astype(np.uint8), 'RGBA').resize((W, H), Image.BOX)
    p = np.asarray(pre).astype(np.float32) / 255.0
    al = p[..., 3:4]
    rgb = np.where(al > 0.001, p[..., :3] / np.maximum(al, 0.001), 0.0)
    return np.clip(rgb, 0, 1), (al[..., 0] >= 0.5)


def outlined(rgb, mask):
    """a 1 px dark outline around the shape (grows the mask)"""
    m = np.pad(mask, 1)
    grown = m[1:-1, 1:-1] | m[:-2, 1:-1] | m[2:, 1:-1] | m[1:-1, :-2] | m[1:-1, 2:]
    ring = grown & ~mask
    rgb = rgb.copy(); rgb[ring] = np.array(OUTLINE) / 255.0
    return rgb, grown


def main():
    os.makedirs(OUT, exist_ok=True)
    got = {n: small(n) for n in LAYERS}
    for n in LAYERS:
        if n.startswith('note_'):
            got[n] = outlined(*got[n])
    layout = {}
    for n, (rgb, mask) in got.items():
        # each layer keeps its own few colours (a palette shared by the whole world went to the room's browns and
        # turned the pink and mint bars orange): the room 56, a toy or a bar 20, a note 12
        k = 56 if n == 'room' else (12 if n.startswith('note_') else 20)
        own = Image.fromarray((rgb[mask][None] * 255).astype(np.uint8), 'RGB').quantize(k, method=Image.MEDIANCUT, dither=Image.NONE)
        q = np.asarray(Image.fromarray((rgb * 255).astype(np.uint8), 'RGB').quantize(palette=own, dither=Image.NONE).convert('RGB'))
        im = Image.fromarray(np.dstack([q, mask.astype(np.uint8) * 255]), 'RGBA')
        box = im.getbbox()
        im.crop(box).save(os.path.join(OUT, n + '.png'))
        layout[n] = [box[0], box[1], box[2] - box[0], box[3] - box[1]]
    # the lanes on the wall: light falling down it, soft at the sides, gone at the top (alpha in 8 steps: pixel art)
    for name, (cx, col) in LANES.items():
        h = LANE_BOTTOM - LANE_TOP
        y = np.linspace(0, 1, h)[:, None]
        x = np.abs(np.linspace(-1, 1, LANE_W))[None, :]
        a = (0.10 + 0.42 * y ** 1.4) * np.clip((1.0 - x) / 0.16, 0, 1) ** 0.7
        a = np.round(a * 16) / 16
        im = np.zeros((h, LANE_W, 4), np.uint8); im[..., :3] = col; im[..., 3] = (a * 255).astype(np.uint8)
        Image.fromarray(im, 'RGBA').save(os.path.join(OUT, f'lane_{name}.png'))
        layout[f'lane_{name}'] = [round(cx / 6) - LANE_W // 2, LANE_TOP, LANE_W, h]
    # the glow behind a falling note
    g = 40
    d = np.hypot(*np.meshgrid(np.arange(g) - g / 2 + 0.5, np.arange(g) - g / 2 + 0.5))
    a = np.round(np.clip(1.0 - d / (g / 2), 0, 1) ** 1.6 * 0.55 * 10) / 10
    im = np.zeros((g, g, 4), np.uint8); im[..., :3] = (255, 246, 214); im[..., 3] = (a * 255).astype(np.uint8)
    Image.fromarray(im, 'RGBA').save(os.path.join(OUT, 'glow.png'))
    layout['lanes_x'] = [round(c / 6) for c, _ in LANES.values()]
    with open(os.path.join(OUT, 'layout.json'), 'w') as f:
        json.dump(layout, f, indent=1)
    print(f'{len(got)} layers + 3 lanes + glow -> {os.path.relpath(OUT, ROOT)}')
    for k, v in layout.items():
        print(f'  {k:18} {v}')


if __name__ == '__main__':
    main()
