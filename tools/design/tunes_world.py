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
SRC = OUT = ''                        # (set per world in build())
# A world = its instrument. src: the designer's round; frame: the instrument's body; bars: what the designer called
# the three bars (they are written as bar_* for every world); even: the tool makes the bars one size and repaints
# the tray with equal lanes (world 1 only: from world 2 on the designer delivers them equal); still / move: the
# other layers, back to front, the ones that stay and the ones the game moves; soft: faint layers (steam, a glow)
# that keep their weaker pixels.
WORLDS = {
    'xylophone': dict(src='round1', frame='xylophone', bars='bar', even=True, wall_cut=1172, soft=[],
                      layers=['toy_kokeshi_bench', 'toy_kokeshi', 'toy_daruma', 'toy_ball', 'toy_maneki', 'toy_maneki_paw', 'toy_top', 'mallet']),
    'piano': dict(src='round2', frame='piano', bars='key', even=False, wall_cut=0, soft=['lantern_glow', 'tea_steam'],
                  layers=['lantern_glow', 'record_player', 'record', 'record_arm', 'tea', 'tea_steam', 'metronome', 'metronome_needle',
                          'cranes_bar', 'crane_1', 'crane_2', 'crane_3', 'lantern']),
}
W, H = 317, 316                       # 950 x 948 on screen at x3
OUTLINE = (74, 44, 32)
LANES = {'low': (246, 150, 180), 'mid': (250, 206, 110), 'high': (150, 220, 190)}   # the wall lanes' colours
BAR_W = 62                            # art px: the three bars at ONE size (the user, 2026-11-13); the designer's were 90, 66 and 53
LANE_TOP, LANE_BOTTOM = 34, 196       # art px: the wall above the tray


def small(name, wall_cut=0, cut=0.5):
    """the layer at the game's size: premultiplied box filter, hard alpha (a pixel is in from `cut` of full)"""
    im = np.asarray(Image.open(os.path.join(SRC, name + '.png')).convert('RGBA')).astype(np.float32) / 255.0
    if wall_cut:                                   # (world 1: the frame's misaligned bands on the wall, above this row)
        im = im.copy(); im[:wall_cut, :, 3] = 0.0
    a = im[..., 3:4]
    pre = Image.fromarray((np.concatenate([im[..., :3] * a, a], 2) * 255).astype(np.uint8), 'RGBA').resize((W, H), Image.BOX)
    p = np.asarray(pre).astype(np.float32) / 255.0
    al = p[..., 3:4]
    rgb = np.where(al > 0.001, p[..., :3] / np.maximum(al, 0.001), 0.0)
    return np.clip(rgb, 0, 1), (al[..., 0] >= cut)


NOTE = 18                             # art px across, before its outline (the user, 2026-11-13: "slightly smaller"; it was 22)


def bead(name):
    """a note at NOTE art px, from its painted 130 px cutout, in the middle of an empty canvas"""
    im = Image.open(os.path.join(SRC, name + '.png')).convert('RGBA')
    im = np.asarray(im.crop(im.getbbox())).astype(np.float32) / 255.0
    a = im[..., 3:4]
    pre = Image.fromarray((np.concatenate([im[..., :3] * a, a], 2) * 255).astype(np.uint8), 'RGBA').resize((NOTE, NOTE), Image.BOX)
    p = np.asarray(pre).astype(np.float32) / 255.0
    rgb, mask = np.zeros((H, W, 3), np.float32), np.zeros((H, W), bool)
    y, x = H // 2, W // 2
    rgb[y:y + NOTE, x:x + NOTE] = np.clip(p[..., :3] / np.maximum(p[..., 3:4], 0.001), 0, 1)
    mask[y:y + NOTE, x:x + NOTE] = p[..., 3] >= 0.5
    return rgb, mask


def outlined(rgb, mask):
    """a 1 px dark outline around the shape (grows the mask)"""
    m = np.pad(mask, 1)
    grown = m[1:-1, 1:-1] | m[:-2, 1:-1] | m[2:, 1:-1] | m[1:-1, :-2] | m[1:-1, 2:]
    ring = grown & ~mask
    rgb = rgb.copy(); rgb[ring] = np.array(OUTLINE) / 255.0
    return rgb, grown


def even_tray(rgb, mask):
    """The xylophone's tray repainted with three EQUAL lanes (the user, 2026-11-13: "the keys should be the same size
    and the note lanes more aligned with those"; the designer's lanes were 3 different widths). The outer rails, the
    front beam and the corner blocks stay as painted; between the rails, row by row, the tray is split in thirds
    with two wooden dividers. Returns the picture and, per row, the tray's inner left and right edge."""
    rgb = rgb.copy()
    px = rgb * 255
    paint = np.array([[249, 192, 190], [250, 214, 142], [203, 224, 188]], np.float32)       # the three lanes as painted
    d = np.abs(px[:, :, None, :] - paint[None, None]).sum(3)
    which = d.argmin(2)
    near = mask & (d.min(2) < 30)
    pink, mint = near & (which == 0), near & (which == 2)       # (the yellow is too close to the wood's highlights to find edges with)
    lane = pink | mint | (near & (which == 1))
    cols = [np.median(rgb[near & (which == k)], 0) for k in range(3)]
    seen = [y for y in range(H) if pink[y].sum() > 30 and mint[y].sum() > 30]
    fl = np.polyfit(seen, [np.nonzero(pink[y])[0].min() for y in seen], 1)        # the tray's inner left edge, row by row
    fr = np.polyfit(seen, [np.nonzero(mint[y])[0].max() + 1 for y in seen], 1)    # and its inner right edge
    rows = list(range(seen[0], seen[-1] + 1))
    wood = rgb[mask & ~lane]
    lum = wood.sum(1)
    tone = [np.median(wood[(lum >= np.percentile(lum, a)) & (lum <= np.percentile(lum, b))], 0) for a, b in ((85, 99), (45, 70), (8, 25))]
    edges = {}
    for y in rows:
        L, R = float(np.polyval(fl, y)), float(np.polyval(fr, y))
        edges[y] = (L, R)
        half = 2.6 + 1.6 * (y - rows[0]) / (rows[-1] - rows[0])                              # a divider is wider near us
        for x in range(int(np.ceil(L)), int(R)):
            u = (x + 0.5 - L) / (R - L)
            c = cols[min(2, int(u * 3))]
            for k in (1, 2):
                off = x + 0.5 - (L + (R - L) * k / 3.0)
                if abs(off) <= half:
                    c = tone[0] if off < -half + 1.2 else (tone[2] if off > half - 1.5 else tone[1])
                elif half < off <= half + 1.5:
                    c = c * 0.88                                                                # its shadow on the lane
            rgb[y, x] = c
            mask[y, x] = True
    return rgb, mask, edges


def same_size(rgb, mask, cx):
    """a bar at BAR_W, centred on cx: its two ends kept (the pegs), the middle cut or stretched"""
    xs = np.nonzero(mask.any(0))[0]; x0, x1 = xs.min(), xs.max() + 1
    cap = min(20, (x1 - x0) // 2 - 2)
    mid = x0 + cap + (np.arange(BAR_W - 2 * cap) * (x1 - x0 - 2 * cap) / (BAR_W - 2 * cap)).astype(int)
    cols = np.concatenate([np.arange(x0, x0 + cap), mid, np.arange(x1 - cap, x1)])
    cut = lambda a: a[:, cols]
    out, om = np.zeros_like(rgb), np.zeros_like(mask)
    left = int(round(cx - BAR_W / 2))
    out[:, left:left + BAR_W] = cut(rgb)
    om[:, left:left + BAR_W] = cut(mask)
    return out, om


def main():
    for world, cfg in WORLDS.items():
        build(world, cfg)


def build(world, cfg):
    global SRC, OUT
    SRC = os.path.join(ROOT, 'docs', 'mockups', 'tomo_tunes', cfg['src'])
    OUT = os.path.join(ROOT, 'textures', 'minigames', 'tunes', world)
    os.makedirs(OUT, exist_ok=True)
    frame = cfg['frame']
    got = {'room': small('room'), frame: small(frame, cfg['wall_cut'])}
    for n in cfg['layers']:
        got[n] = small(n, cut=0.22 if n in cfg['soft'] else 0.5)
    for lane in ('low', 'mid', 'high'):
        for lit in ('', '_lit'):
            got[f'bar_{lane}{lit}'] = small(f"{cfg['bars']}_{lane}{lit}")
    for n in ('note_low', 'note_mid', 'note_high', 'note_gold'):
        got[n] = outlined(*outlined(*bead(n)))           # the outline twice: 2 art px (the user: "a bit more of outline")
    rows = np.nonzero(got['bar_mid'][1].any(1))[0]
    bar_y = int(rows.mean())                                               # the row the bars lie on
    if cfg['even']:
        rgb, mask, edges = even_tray(*got[frame])
        got[frame] = (rgb, mask)
        top = min(edges)
        bar_row = min(max(edges), bar_y)
        centre = lambda k: edges[bar_row][0] + (edges[bar_row][1] - edges[bar_row][0]) * (2 * k + 1) / 6.0
        lane_w = int((edges[top][1] - edges[top][0]) / 3.0) - 6
        for n in list(got):
            if n.startswith('bar_'):
                got[n] = same_size(*got[n], centre(['low', 'mid', 'high'].index(n.split('_')[1])))
    else:                                                                  # the designer's bars are already equal and in place
        bar_cx = [float(np.nonzero(got[f"bar_{lane}"][1].any(0))[0].mean()) + 0.5 for lane in ('low', 'mid', 'high')]
        centre = lambda k: bar_cx[k]
        top = int(np.nonzero(got[frame][1].any(1))[0].min())
        lane_w = 47
    layout = {}
    for n, (rgb, mask) in got.items():
        # each layer keeps its own few colours (a palette shared by the whole world went to the room's browns and
        # turned the pink and mint bars orange): the room 56, a toy or a bar 20, a note 12
        k = 56 if n == 'room' else (12 if n.startswith('note_') else 20)
        own = Image.fromarray((rgb[mask][None] * 255).astype(np.uint8), 'RGB').quantize(k, method=Image.MEDIANCUT, dither=Image.NONE)
        q = np.asarray(Image.fromarray((rgb * 255).astype(np.uint8), 'RGB').quantize(palette=own, dither=Image.NONE).convert('RGB'))
        if n.startswith('note_'):
            q = q.copy(); q[mask & (np.abs(rgb * 255 - np.array(OUTLINE)).sum(2) < 2)] = OUTLINE
        im = Image.fromarray(np.dstack([q, mask.astype(np.uint8) * 255]), 'RGBA')
        box = im.getbbox()
        im.crop(box).save(os.path.join(OUT, n + '.png'))
        layout[n] = [box[0], box[1], box[2] - box[0], box[3] - box[1]]
    # the lanes on the wall: light falling down it, soft at the sides, gone at the top (alpha in 8 steps: pixel art)
    LANE_W = lane_w
    for k, (name, col) in enumerate(LANES.items()):
        cx = centre(k)                                         # straight above its bar (the user: the notes fall straight to the keys)
        h = min(LANE_BOTTOM, top) - LANE_TOP
        y = np.linspace(0, 1, h)[:, None]
        x = np.abs(np.linspace(-1, 1, LANE_W))[None, :]
        a = (0.10 + 0.42 * y ** 1.4) * np.clip((1.0 - x) / 0.16, 0, 1) ** 0.7
        a = np.round(a * 16) / 16
        im = np.zeros((h, LANE_W, 4), np.uint8); im[..., :3] = col; im[..., 3] = (a * 255).astype(np.uint8)
        Image.fromarray(im, 'RGBA').save(os.path.join(OUT, f'lane_{name}.png'))
        layout[f'lane_{name}'] = [int(round(cx - LANE_W / 2)), LANE_TOP, LANE_W, h]
    # the glow behind a falling note
    g = 40
    d = np.hypot(*np.meshgrid(np.arange(g) - g / 2 + 0.5, np.arange(g) - g / 2 + 0.5))
    a = np.round(np.clip(1.0 - d / (g / 2), 0, 1) ** 1.6 * 0.55 * 10) / 10
    im = np.zeros((g, g, 4), np.uint8); im[..., :3] = (255, 246, 214); im[..., 3] = (a * 255).astype(np.uint8)
    Image.fromarray(im, 'RGBA').save(os.path.join(OUT, 'glow.png'))
    # a note falls straight down onto its bar (following the tray's slanted lane was tried and refused by the user)
    layout['lanes_x'] = [round(centre(k), 2) for k in range(3)]
    layout['frame'] = frame
    layout['layers'] = cfg['layers']
    layout['tray_top'] = top
    layout['bar_y'] = bar_y
    with open(os.path.join(OUT, 'layout.json'), 'w') as f:
        json.dump(layout, f, indent=1)
    print(f'{len(got)} layers + 3 lanes + glow -> {os.path.relpath(OUT, ROOT)}')
    for k, v in layout.items():
        print(f'  {k:18} {v}')


if __name__ == '__main__':
    main()
