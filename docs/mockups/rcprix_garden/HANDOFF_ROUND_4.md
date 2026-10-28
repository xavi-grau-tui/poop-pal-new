# RC Prix Garden — round 4 bushes

Only `bush_a.png`, `bush_b.png`, `bush_c.png` and `bush_d.png` changed in
`textures/minigames/rcprix/garden/`. Sizes are 60×52, 46×40, 54×46 and
40×34 respectively. The round-3 grass, approved trees and all road art remain
untouched.

The four built-in imagegen silhouette studies are saved in `round4_sources/`.
They supplied the round, wide/low, asymmetric and taller arrangements. To keep
exactly the tree's pixel density, the final sprites use **unscaled pixels from
the approved `tree_top.png`**: two or three 24–27 px foliage clusters per bush,
with each bright leaf mass about 8–12 px wide. The clusters are composed on
the final sprite grid by `tools/art/rcprix_garden_round4.py`; the large
imagegen studies are not shrunk into the game assets. The 3× comparison is
`round4_bush_tree_3x.png`.

Imagegen prompt set (built-in tool, transparent output; tree as style
reference):

- **A:** round compact bush of three broad overlapping clusters; tree's leaf
  scale, palette, top-left light and dark outline; no tiny leaves or shadow.
- **B:** wide low bush of three broad lobes, distinctly flatter than A; same
  tree leaf scale and colour treatment; no tiny leaves or shadow.
- **C:** small asymmetric bush of two or three broad clusters, one higher and
  one lower side lobe; same tree scale and colour treatment.
- **D:** compact taller bush with an upright centre cluster and lower foliage;
  same tree scale and colour treatment.

Validation after export:

```sh
./.venv/bin/python3 tools/art/rcprix_garden_round4.py
./.venv/bin/python3 tools/art/check_rcprix_art.py
./.venv/bin/python3 tools/art/rcprix_preview.py
./.venv/bin/python3 tools/art/rcprix_preview.py --wide
```

Result: **78/78 files present, 0 problems**. Both course preview sizes were
regenerated. The full quality generator also uses the round-4 bush function,
so a future rebuild preserves these four sprites.
