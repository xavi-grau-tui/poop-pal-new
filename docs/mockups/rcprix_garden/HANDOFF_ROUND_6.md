# RC Prix Garden · round 6 bush handoff

The seven approved round-5 silhouettes are preserved pixel for pixel. Only the
interior foliage colours and the dark outline treatment changed. The tree,
grass, road and other sprites were not edited in this round.

## Final assets

`textures/minigames/rcprix/garden/bush_a.png` through `bush_g.png` are the
32-bit transparent PNGs used by the game. Their sizes are 90×76, 108×46,
86×64, 94×80, 44×38, 38×32 and 48×36. Every opaque pixel uses exactly one
of the approved tree's six colours, and all alpha values are 0 or 255.

The imagegen studies are in `round6_sources/bush_*_tone_study.png`. The
`round6_sources/bush_*.png` files are their nearest-neighbour final-grid seeds
with the original round-5 alpha masks. `tools/art/rcprix_garden_round6.py`
repaints those seeds into the delivered bush PNGs. The full-quality Garden
generator now uses that round-6 repaint, so a later rebuild retains this work.

Imagegen prompt, applied separately to each bush with its round-5 image and
`tree_top.png` as references: preserve the exact silhouette, lobes,
transparency and exterior outline; repaint the inner foliage with only
`#251a24`, `#1a4131`, `#2b6639`, `#31723b`, `#5fb138`, `#97d53a`;
make dark and mid green dominant, give broad light leaf patches small upper-left
highlight tips and lower-right shadows, merge tiny flecks into calm colour
runs, and add no ground, cast shadow or text. The generated studies were
cleaned on the final pixel grid for the checker and visual comparison.

## Review and validation

- `round6_tree_bushes_4x.png`: the delivered seven bushes beside the approved
  tree at 4×, nearest-neighbour.
- `round6_tree_tones_final_3x.png`: the tree and delivered bushes snapped to
  the six tree colours at 3×.
- `course_preview.png`, `course_preview_2x.png`, `course_preview_wide.png` and
  `course_preview_wide_2x.png`: regenerated after export.
- `python3 tools/art/check_rcprix_art.py`: **81/81 files present, 0 problems**.
- All seven final alpha masks match their round-5 silhouettes exactly; none
  contain half-transparent pixels.

No installation was performed. The assets are ready for the technical team's
normal game build.
