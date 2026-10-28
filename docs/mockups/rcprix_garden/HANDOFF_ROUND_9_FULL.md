# RC Prix Garden — Round 9 full road and tyre art

The approved sample finish now covers **12 road pieces** and **16 tyre walls** in `textures/minigames/rcprix/garden/`: both 88 px and 100 px road widths, all four corners, and red/white plus blue/yellow tyre walls. Each delivered sprite is a 180×180 transparent PNG drawn directly on the final pixel grid.

The reproducible art source is `tools/art/rcprix_round9_sample.py`. Despite the original sample filename, it now writes the entire Round 9 set. It uses the locked geometry renderer for the road masks and stripe placement, preserves the exact old alpha masks, aligns painted curb pixels at every tangent join, and draws the two tyre colourways as separate 11 px rings in staggered rows. The earlier **built-in imagegen** results in `round9_imagegen_options/` served as style references. The prompt set requested flat clustered pixel art, raised red/white curbs, orange or wood side-face choices, and individually readable red/white or blue/yellow tyres; the approved selections were orange and both tyre colourways. No generated pixels were resized into the game assets.

`rcprix_garden_quality_full.py` skips the Round 9 roads and tyres so a later run of that older generator cannot replace this finish.

## Actual-PNG review pictures

- `round9_full_actual_pngs_3x.png` — quick narrow/wide comparison with both tyre colourways.
- `round9_full_roads_3x.png` — all twelve road pieces on the approved grass, with the tree alongside.
- `round9_full_tyres_3x.png` — all sixteen tyre walls over their matching corners.
- `course_preview.png` and `course_preview_wide.png` — assembled courses. The preview builds its jump gap from the current straight art, as the game does.

All 3× pictures above use nearest-neighbour enlargement of the exact delivered PNGs.

## Checks run

```
./.venv/bin/python tools/art/check_rcprix_art.py
# 89/89 files present, 0 problems

./.venv/bin/python tools/art/rcprix_preview.py
./.venv/bin/python tools/art/rcprix_preview.py --wide
```

Additional inspection found no changed road alpha masks and no painted pixel differences at any of the narrow or wide straight/corner joins.
