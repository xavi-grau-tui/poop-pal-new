# RC Prix Garden · round 13 layered stand

**Superseded for art direction.** The user supplied the exact front artwork
and corrected the side orientation after these native-grid drafts. See
`ROUND_13_CORRECTED_DIRECTION.md`. The 21 PNGs documented below are technical
drafts only and are not approved for the game.

The six front pieces and three roof-flag frames are in
`textures/minigames/rcprix/garden/`:

- `stand_front_under_end_a/mid/end_b.png` (28×96, 56×96, 28×96)
- `stand_front_over_end_a/mid/end_b.png` (same sizes)
- `stand_flag_0/1/2.png` (12×24)

`round13_front_layers_3x.png` is assembled **from those delivered PNGs**. It
shows the under layer, transparent over layer, composition, three flags,
and the existing road and tree at the same pixel scale. The four copies of
`mid` are the exact same file. The checker reports **9/9, 0 problems** with
`--round13-sample`.

The user's approved image is the design reference for every view. The rear
has no backing wall: the spaces between benches and posts are transparent
in both layers, so pals drawn between them can be seen through the stand.
The near roof occupies only the lower 18 px of the rear over layer. The side
view likewise leaves the spaces between its tiers open and places only its
near frame and awning edge in the over layer.

- `stand_back_under_end_a/mid/end_b.png`, `stand_back_over_end_a/mid/end_b.png`
  (28×96, 56×96, 28×96)
- `stand_side_under_end_a/mid/end_b.png`, `stand_side_over_end_a/mid/end_b.png`
  (96×28, 96×56, 96×28)
- `round13_all_views_2x.png` is assembled from these PNGs. Front under and
  over are at upper left, front composite at upper middle; rear under and over
  are below, rear composite at lower middle; side composite is at right.
- `round13_side_long_3x.png` rotates the delivered side PNGs for a landscape
  reading of the long tier ends. The sprites themselves remain 96 px wide and
  run vertically in the game.

The user requested a stronger long-view perspective. The built-in imagegen
study `round13_side_long_perspective_reference.png` records the target:
long converging bench edges, staggered seat ends, visible risers, and an
awning that rises toward the distant end. The current repeating three-piece
sprite adds staggered ends and tier thickness. A continuous taper across the
full length **cannot be represented by one identical repeating `mid`**. For
the full target, the renderer needs a full-length side sprite or four distinct
middle slices. The existing repeatable side files are a provisional layout
until that change is agreed with the game team.

The checker reports **21/21 files present, 0 problems** with `--round13-all`.
The older `stand_n/s/e/w_*` files remain in place until the game switches to
the layered sprites.

The built-in imagegen tool made `round13_stand_imagegen_study.png` as a visual
study from the approved `round11_stand_imagegen_reference.png`. The user
approved that exact visual design. Built-in imagegen then made
`round13_back_imagegen_study.png` and `round13_side_imagegen_study.png` from
the approved image for view planning. The final game PNGs were drawn directly
on the 96 px grid with `tools/art/rcprix_garden_round13_front.py` and
`tools/art/rcprix_garden_round13_views.py`; no generated study was shrunk into
the game files.

## Imagegen prompt

> Edit the attached approved stand image conceptually: preserve its exact
> recognizable design language—five rows of warm wooden benches on posts,
> angled wooden side frames, green-and-cream scalloped awning. Show a larger
> front-facing stand at a visibly coarse, clean pixel grid matching a
> 96-pixel-deep game sprite. Place a clean separated two-layer diagram side by
> side: UNDER shows five bench rows, posts, angled side frames and no awning;
> OVER shows only the awning and its support silhouette, transparent elsewhere
> so cheering characters can be placed between layers. Include three small
> white pennant flags on short posts in successive wave poses nearby. Crisp
> flat pixel clusters, dark #281E28 one-pixel style outline, 3–4-pixel plank
> and post visual weight, ~7-pixel awning stripes, light from top left.
> Transparent background. No spectators, text, gradients, anti-aliasing,
> microtexture, or extra objects.

Rear prompt: edit the approved image into its back view, preserving the same
bench, angled frame and scalloped awning identity; draw the rear faces of five
benches and 3–4 px posts, with open transparent gaps and **no back wall**;
separate benches/posts (under) from the near roof (over), preserve pixel size,
palette and top-left light.

Side prompt: use the approved image as the exact identity; show the right-hand
side, with five stepped tiers on posts and open gaps; separate the tiers
(under) from the near frame and awning edge (over); preserve the same palette,
outline and pixel size, and keep the background transparent.

Long perspective prompt: preserve the approved stand design while showing a
right-hand view that reads as a long grandstand receding along the track. Use
long converging bench edges, staggered ends, solid shaded risers and a rising
scalloped awning; keep clear openings beneath the seats and separate the
awning and near frame from the seating layer.
