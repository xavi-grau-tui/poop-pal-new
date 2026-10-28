# RC Prix · Garden: notes for round 9 (the road and the tyre walls)

The bushes are done and approved, and so are the lawn, the flowers and the trees. Next are **the road
and the tyre walls**. Start lines, boost pads, ramps and effects come in a later round.

`round9_road_now_2x.png` shows today's road and tyre wall next to the approved grass and tree.

## What's wrong now

- **The road isn't pixel art like the grass and trees.** The asphalt is a soft, airbrushed
  gradient with fine noise. The grass and trees use a few flat tones in clear clusters.
- **The curbs are flat:** plain red and white blocks with no light or depth.
- **The side face** (the orange edge under the road) is a smooth gradient band.
- **The tyre walls** are one black mass: about 3 colours, no individual tyres to read, and big
  black blobs at the ends.

## What we want

The same pixel-art language as the approved grass and tree: **a few flat tones per material,
clusters of at least 2×2 px, light from the top left, one outline colour `#281E28`.** No
gradients, no noise, no soft pixels.

**Asphalt**
- 4–5 tones of a muted blue-grey, darker than the grass and calm enough that the car stands out.
- Texture made of pixel clusters, not noise: a few small stones (2–3 px), the odd crack or tar
  patch, a slightly darker, worn band where cars drive. Keep it sparse. The road should read as
  calm next to the busy grass.
- The centre dashes are flat cream with a 1 px darker bottom edge.

**Curbs**
- Red and white blocks, each with a 1 px light top edge and a 1 px shaded bottom edge, so they
  read as slightly raised.
- The stripe lengths keep the join rules (BRIEF.md: lengths that divide 180 on straights, a
  whole number per arc on curves).

**Side face** (under south-facing edges only, as now)
- 2–3 flat bands, no gradient. Pick a colour that suits the garden toy look: today's orange, or
  a wood or brick tone. Show us two options on the look sample.

**Tyre walls**
- **Individual tyres you can read:** each tyre seen from above is a ring (about 10–12 px) with a
  dark hole in the middle, a light rim at its top left and an outline.
- **A colour combination:** painted tyres alternating, as on real kart tracks. Show us two
  options, for example red/white and blue/yellow (or the garden's own colours).
- Two rows, staggered, following the curve. Clean rounded ends, not black blobs.
- No shadows on the ground: the game adds them.

## The geometry doesn't change

The road's edges, curb widths, join points and side-face position stay exactly as in the
templates (`templates/1_road_pieces.png`, `1b_road_pieces_wide.png`, `2_overlays.png`). The checker
tests the joins.

**Not needed:** `gap_h` and `gap_v`. The game now builds the jump squares itself from your
straights, so they always match.

## How to work (lessons from the bushes)

1. **First a look sample, 3 files:** `straight_h`, `corner_ne` and `tyres_ne`, each with the two
   side-face and tyre colour options. We try them **in the game** before the full set.
2. **What you show us is what you deliver.** The PNGs in the game must be exactly the pictures
   you showed. If a script builds the pieces, show us the script's output, not a generated study.
3. **Draw on the final pixel grid.** A generated picture is fine as a style reference only. The
   road pieces must be built at their exact size (a script drawing the geometry with your chosen
   tones and motifs is the right tool for the road).
4. Then the full set, in both road widths: `straight_h`, `straight_v`, the four corners and the
   four `tyres_*`, plus their `_wide` versions.

## Test before handing over

1. A 3× picture made **from the delivered PNGs**: the straight, a corner and a tyre wall next to
   the grass and the tree. They should look drawn in the same style.
2. `python3 tools/art/check_rcprix_art.py`: 0 problems (sizes, hard edges, joins).
3. `python3 tools/art/rcprix_preview.py` and `--wide`: the joined course pictures.

## Update after your options (go-ahead to draw on the grid)

Thanks for the options in `round9_imagegen_options/`. Decisions:

- **You may draw and clean on the final pixel grid**, with scripts or by hand. Image generation is
  for style references only, as you said.
- **Tyres: both colourways, mixed by level.** Red/white goes in `tyres_ne/nw/se/sw.png`,
  blue/yellow in the new `tyres_ne_alt.png` … `tyres_sw_alt.png`, both also in `_wide`: 16 tyre
  files in all (boxes in `templates/2_overlays.png` and `2b_overlays_wide.png`). The game uses
  red/white on odd levels and blue/yellow on even ones. Your option pictures have the right look:
  individual painted rings, a dark hole and a light rim.
- **Side face: keep the orange**, as 2–3 flat bands. The "wood" option came out the same orange,
  so it isn't a real choice yet.
- **Asphalt: flatter than in your options.** It still has soft streaks and airbrushed shading.
  Use 4–5 flat tones, with texture only as small pixel clusters.

The look sample is then **4 files at their exact size**: `straight_h`, `corner_ne`, `tyres_ne`
and `tyres_ne_alt`. They must pass the checker's joins, and we try them in the game before the
full set.
