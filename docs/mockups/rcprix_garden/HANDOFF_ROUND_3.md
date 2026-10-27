# RC Prix Garden — round 3 handoff

This round changes **only** `grass_a.png`, `grass_b.png`, `grass_c.png`,
`bush_a.png` and `bush_b.png` in `textures/minigames/rcprix/garden/`.
The approved trees, flowers, car, road and overlays are untouched.

## Bushes

`bush_a` is 60×52 and `bush_b` is 46×40. Each is composed of a few broad
leaf clusters with the tree's dark outline, layered greens and top-left light.
Both were generated with the built-in imagegen tool using `tree_top.png` as the
style and pixel-scale reference, then fitted with nearest-neighbour sampling
and binary alpha. The final 3× comparison is `round3_bush_tree_3x.png`.

Imagegen source files: `quality_sample/bush_round3_large_clusters_source.png`
and `quality_sample/bush_b_round3_source.png`.

Final prompts:

> **Bush A:** Edit the approved tree sprite into one standalone transparent
> low-resolution bush made of exactly four or five large separated leaf
> clusters. Preserve the tree's pixel scale, stepped cluster shapes,
> yellow-green highlights, deep green layers, dark plum outline and top-left
> lighting. Fit a 60×52 sprite; no tiny leaves, ground, shadow or text.

> **Bush B:** Use the same approved tree style and actual apparent pixel size.
> Draw a distinct, lower, wider transparent bush made of three or four broad
> leaf clusters for a 46×40 sprite. Preserve the same palette, lighting and
> outline; no dense miniature leaves, ground, shadow or text.

## Grass seams

`tools/art/rcprix_garden_round3.py` shifts the approved grass A by half a tile,
replaces the resulting centre cross with full-strength copied grass texture,
then shifts it back. This joins its edges without a smoothed perimeter strip.
B and C keep a **bit-for-bit identical 16 px border** from A, while their
interiors retain separate patch layouts. The interior transition uses an
irregular patch boundary so it does not form a second straight line.
`round3_grass_seam_board.png` shows a 3×3 A/B/C mixture without road cover.

The A/B/C opposite edge columns and rows are not identical copies; their
patterns continue across the edge. Measured green-channel edge variation on A
is 13.9 versus 14.8 in the interior.

## Rebuild and review

```sh
./.venv/bin/python3 tools/art/rcprix_garden_round3.py
./.venv/bin/python3 tools/art/check_rcprix_art.py
./.venv/bin/python3 tools/art/rcprix_preview.py
./.venv/bin/python3 tools/art/rcprix_preview.py --wide
```

Checker result: **76/76 files present, 0 problems**. Review
`course_preview.png`, `course_preview_2x.png`, `course_preview_wide.png` and
`course_preview_wide_2x.png`. The full quality generator now calls the same
round-3 bush and grass functions so a future rebuild preserves these changes.
