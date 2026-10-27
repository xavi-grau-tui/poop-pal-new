# RC Prix Garden — painted quality pass

The approved painted finish has been applied to all 76 PNGs in
`textures/minigames/rcprix/garden/`. These replace the earlier geometry art in
place. Both 88 px and 100 px road widths retain the locked road masks, six-pixel
curbs, 12-pixel side faces, joins, overlay positions, file names and dimensions.

## Review pictures

- `course_preview.png` and `course_preview_2x.png`: narrow road.
- `course_preview_wide.png` and `course_preview_wide_2x.png`: wide road.
- `car_slices_preview_quality.png`: six car layers and their composite.

## Finish

- Asphalt samples the painted source with nearest-neighbour scaling and has a
  worn centre, darker shoulders and fine tonal grain. The raised red/white
  curb blocks have light top bevels, dark lower edges, a plum exterior contour
  and a one-pixel road-side lip. The orange side face has four depth tones.
- Grass A, B and C come from three different painted layouts. Their opposite
  edge columns and rows are *not* identical copies. A short partial edge
  reconciliation keeps colours close while the pattern continues over seams.
  The course previews show A/B/C mixed together.
- The trees, bushes and car derive from transparent imagegen pixel-art sources.
  The car's wheels/chassis occupy layers 1–2, body layers 3–4, cabin layer 5
  and attached roof cap layer 6. Small objects and the wooden frame have a
  final highlight pass. The start lamp remains grayscale for game tinting.
- Tyre walls now finish with rounded caps inside each corner square; ramps
  have direction arrows. Start lines and boost pads retain their full-width
  positions.

## Rebuild and validation

Run from the repository root with the bundled Pillow environment:

```sh
./.venv/bin/python3 tools/art/rcprix_garden_quality_full.py
./.venv/bin/python3 tools/art/check_rcprix_art.py
./.venv/bin/python3 tools/art/rcprix_preview.py
./.venv/bin/python3 tools/art/rcprix_preview.py --wide
```

Final checker result on 2026-10-27: **76/76 files present, 0 problems**.
The output uses binary alpha only. The generator uses nearest-neighbour
sampling for the painted sources and asserts that each road alpha mask remains
unchanged. The source images are preserved in `quality_sample/`; the generated
PNG files in `textures/minigames/rcprix/garden/` are the game assets.

## Imagegen source brief

The saved painted source images are `grass_painted_source_v2.png`,
`grass_b_painted_source.png`, `grass_c_painted_source.png`,
`asphalt_painted_source.png`, `tree_canopy_painted_source.png`,
`bush_painted_source.png` and `car_painted_source.png` in `quality_sample/`.
The visual brief used for the new variants was:

> Top-down polished pixel art for a bright RC racing garden, with crisp hard
> pixel edges, no blur, no text and light from the top left. For Grass B and C,
> make two distinct edge-to-edge, calm lawn patch layouts with mottled greens,
> small tufts and sparse cream/pink flowers; vary patch positions and shapes
> so adjoining tiles do not form rows. For trees, make a transparent layered
> leafy canopy seen from above, with deep plum-green shadows and lime-lit
> leaf clusters. For bushes, make a transparent compact leafy cluster with
> the same lighting and palette. For the car, make a transparent overhead red
> toy RC car with visible four tyres, shaded shell, lit roof and cyan glazing,
> suitable for separation into six stacked depth layers.

The earlier grass and curb imagegen edit prompts are in
`quality_sample/IMAGEGEN_PROMPTS_V2.md`.
