# RC Prix Garden — round 5 bushes

Round 5 changes only `bush_a.png` through `bush_g.png` in
`textures/minigames/rcprix/garden/`. The approved grass, trees, road and other
sprites remain untouched. A–D retain their approved round-4 study silhouettes;
E–G add three smaller, distinct forms.

## Assets and previews

| Asset | Size | Form |
| --- | --- | --- |
| `bush_a.png` | 90×76 | round, three lobes |
| `bush_b.png` | 108×46 | wide and low |
| `bush_c.png` | 86×64 | uneven |
| `bush_d.png` | 94×80 | tall |
| `bush_e.png` | 44×38 | small, two main clusters |
| `bush_f.png` | 38×32 | small, upright |
| `bush_g.png` | 48×36 | small, low |

`round5_tree_bushes_4x.png` places all seven final sprites beside the approved
tree at 4×. The assembled course previews are `course_preview.png`,
`course_preview_2x.png`, `course_preview_wide.png` and
`course_preview_wide_2x.png`.

## Built-in imagegen sources and export

The seven transparent source images are saved in `round5_sources/`. A–D were
edited from their approved `round4_sources/bush_*_study.png` images with
`tree_top.png` as the leaf-scale and palette reference. E–G were generated as
separate small bushes using the same references. The final prompt set was:

> A–D: Preserve the exact approved outer silhouette, major lobe layout,
> outline weight, proportions and transparency. Simplify only the inner
> foliage into fewer, broader stepped leaf clusters intended to read 10–12
> final pixels across, with the tree's green palette and top-left light. Do
> not enlarge the bush or add ground, shadows or text.

> E: A small rounded two-cluster bush. F: a small upright two-cluster bush.
> G: a low, spreading three-cluster bush. Use broad 10–12-pixel leaf masses,
> tree colours, top-left light, a dark closed outline and transparent ground.
> No fine leaves, shadow or text.

`tools/art/rcprix_garden_round5.py` selects one source pixel per final-grid
block with nearest-neighbour sampling and binary alpha, then cleans up the
leaf highlights on the final grid. It makes no smooth, averaged pixels. The
small sprites retain only their two or three broadest light clusters. The
full quality generator now uses this round-5 bush function, so a later full
rebuild preserves the seven assets.

## Validation

```sh
./.venv/bin/python3 tools/art/rcprix_garden_round5.py
./.venv/bin/python3 tools/art/check_rcprix_art.py
./.venv/bin/python3 tools/art/rcprix_preview.py
./.venv/bin/python3 tools/art/rcprix_preview.py --wide
```

Result: **81/81 files present, 0 problems**.
