# Garden quality pass: three-piece approval sample

`imagegen_style_study.png` is the first visual study. The revised finish uses
`grass_painted_source.png` and `asphalt_painted_source.png`, generated separately
with the built-in imagegen tool from `style_reference.png`. These painted material
sources are sampled at 180×180 with nearest-neighbour and fitted inside the
approved shapes by `tools/art/rcprix_garden_quality_sample.py`.

The second approval revision uses `grass_painted_source_v2.png`, an imagegen edit
that calms the green contrast while preserving the patch and flower layout.
`curb_raised_imagegen_study.png` is an imagegen edit showing the intended raised
curb finish. The final six-pixel curb shading in the exact samples is drawn on
the locked pixel grid from that study so its geometry and stripe phase stay exact.

`straight_h.png`, `corner_se.png` and `grass_a.png` are the exact 180×180 pixel
approval samples. `three_piece_preview_2x.png` places them together at nearest
neighbour 2×. The grass uses six greens, keeps its opposite edges identical,
and has no half-transparent pixels. The road samples start from the approved
geometry and preserve their alpha masks byte-for-byte. The 76 game assets in
`textures/minigames/rcprix/garden/` remain unchanged pending approval.

After this finish is approved, apply the same material rules to both road widths,
the other road pieces and overlays, and use three distinct grass compositions to
break up repetition across a course. Then run the 76-file checker and both course
previews before handoff.
