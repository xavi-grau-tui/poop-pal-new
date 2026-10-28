# RC Prix Garden — Round 9 look sample

The four **actual game PNGs** are:

- `textures/minigames/rcprix/garden/straight_h.png`
- `textures/minigames/rcprix/garden/corner_ne.png`
- `textures/minigames/rcprix/garden/tyres_ne.png` (red/white)
- `textures/minigames/rcprix/garden/tyres_ne_alt.png` (blue/yellow)

`round9_sample_actual_pngs_3x.png` is a nearest-neighbour 3× comparison made from those exact files on the approved grass, with the tree alongside. No generated-study pixels are in the game PNGs.

The deterministic final-grid source is `tools/art/rcprix_round9_sample.py`. It preserves the locked road alpha masks, curb widths, stripe positions, join points and orange side-face footprint. It draws five flat asphalt tones, placed 3–4 px material clusters, one-pixel curb bevels, three flat side-face bands, and separate 11 px tyre rings in two staggered rows. Only these four narrow assets are written; the other road and overlay pieces await the in-game look review.

Style references were made in the **built-in imagegen** mode and saved under `round9_imagegen_options/`. The prompt set used the current straight, corner and tyre PNGs as edit targets, the approved grass/tree comparison as a density reference, and requested flat clustered pixel art with red/white or blue/yellow tyres and orange or wood side faces. Round 9 selected orange side faces and both tyre colours.

Validation:

```
./.venv/bin/python tools/art/check_rcprix_art.py --round9-sample
# 4/4 files present, 0 problems

./.venv/bin/python tools/art/rcprix_preview.py
./.venv/bin/python tools/art/rcprix_preview.py --wide
```

The full checker currently reports **82/89 files present, 7 problems** because the seven other `tyres_*_alt` assets belong to the later full-set pass. The unchanged wide course preview therefore still shows the prior art.
