# RC Prix Garden · round 7 bush handoff

The first round-7 comparison had broad, regular colour bands that differed
from the tree's irregular canopy. The corrected game sprites are
`textures/minigames/rcprix/garden/bush_a.png` through `bush_g.png`.
Their byte-identical masters are in `round7_tree_match_final/`; the earlier
`round7_final/` set is superseded.

`round7_tree_match_4x.png` and the refreshed `round7_tree_bushes_4x.png` were
made directly from the delivered game PNGs, beside `tree_top.png`. The approved
round-5 box sizes and alpha silhouettes remain unchanged.

## Art process

The corrected bush texture uses the tree's own pixels at native scale. A, B,
C, E, F and G use contiguous tree canopy crops within their approved outlines.
D combines larger 24×24 tree canopy patches where a single crop could not
cover its taller shape. A few clipped light patches and dark gaps were
cleaned on the final pixel grid. No smooth scaling or colour interpolation was
used. Median light-patch areas are 30–49 pixels; the smaller A median includes
partial patches clipped by its outline. Light plus highlight covers
33–39% of the opaque pixels. Every opaque pixel uses one of the tree's six
colours.

The built-in imagegen style study is saved as
`round7_sources/bush_a_tree_style_study.png`. Prompt: keep bush A's silhouette
and transparent boundary, but draw foliage as though cut directly from the
approved tree; use irregular clumped rosettes, jagged light patches and dark
gaps at the same game-pixel scale; avoid broad diagonal bands, repeated rows
and geometric ribbons; use only `#251a24`, `#1a4131`, `#2b6639`, `#31723b`,
`#5fb138` and `#97d53a`; no ground, cast shadow, smooth edges or text. The
final game PNGs use the actual tree pixels for stricter style matching.

`tools/art/rcprix_garden_quality_full.py` reads the corrected master PNGs on
a full-art rebuild. It copies their pixels without repainting them.
`scripts/rc_tiles.gd` has the older `BUSH_BIG` trial override disabled, so the
game reads the delivered `bush_*.png` files at native scale.

## Validation

- `python3 tools/art/check_rcprix_art.py`: **81/81 files present, 0 problems**.
- All seven game PNGs are byte-for-byte identical to their
  `round7_tree_match_final/` masters.
- The 4× comparison uses the game PNGs. Narrow and wide course previews were
  regenerated from the corrected assets.
