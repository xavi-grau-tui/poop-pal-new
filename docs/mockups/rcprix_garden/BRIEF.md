# RC Prix · Garden: new graphics brief

RC Prix's first world, the Garden: a toy RC car racing on a raised plastic track laid on a garden
lawn, seen from above at a slight angle (like Micro Machines). We want to replace the current art,
which the game draws in code, with smoother, more polished art from you. The game will then build
every course from your pieces.

Start with the Garden. When it works in the game, the other five worlds follow the same kit.

## What's in this folder

| File | What it is |
|---|---|
| `overview.png` | The current Garden art, cut into pieces: the look we're replacing (sizes there are the old ones) |
| `style_reference.png` | The Garden's visual target, confirmed by the user: the track, lawn, flowers and layered foliage should have this character |
| `pilot_preview.png` | The road pilot joined into a sample course with mixed lawn variants; this checks geometry and colour, not the finished look |
| `pieces/`, `sprites/` | The same current art as single PNGs, if you want to start from it |
| `templates/1_road_pieces.png` | The road pieces to draw, one box per file, with guides (the narrow road, later levels) |
| `templates/1b_road_pieces_wide.png` | The same road pieces with the wide road (early levels) |
| `templates/2_overlays.png` | Things drawn on top of a road piece (start line, boost pads, ramps, tyre walls) |
| `templates/2b_overlays_wide.png` | The same overlays for the wide road |
| `templates/3_ground.png` | The lawn squares |
| `templates/4_sprites.png` | The car, the small objects, the decor and the board's wooden frame |

The templates are drawn by `tools/art/rcprix_templates.py`, so the boxes match the game exactly.

## Decided (2026-10-27)

- **Twice the current detail:** a course square is 180×180 px.
- **Two road widths per world:** a wide road for a world's early levels (Garden 1–4: 100 px wide)
  and a narrow one for its later levels (Garden 5–9: 88 px). Every road piece and overlay comes in
  both widths; the wide files end in `_wide`.
- **Boost pads, the start line and jumps sit on whole squares**, centred on a straight. They never
  go on curves.

## Visual target and acceptance

Use `style_reference.png` as the target for the finished Garden circuits. The current tile pilot is
only a geometry and renderer trial. Its bare lawn and empty corners are not the final art direction.
The generated reference is a scene, so the game does not need to reproduce its exact arrangement;
it should deliver the same visual quality on each course as the camera moves.

- **Road:** broad, connected grey shading follows the turns without square tile boundaries.
  White dashes bend with the centre line. Red and white curb blocks continue through joins. The
  orange raised side has a bright upper lip and a deeper shaded face, with the dark plum outline.
- **Ground:** fresh, varied greens with restrained, irregular patches. The three repeating lawn
  tiles should not form an obvious grid at normal game size.
- **Garden detail:** separate small flower clusters and grass tufts sit at varied positions off
  the road. Layered leafy canopies and bushes supply the dark and light green depth visible in
  the reference. Do not bake large bushes into a repeating lawn tile.
- **Gameplay view:** judge the art in a real Garden course at phone size, including a moving car.
  All four wheels should read as attached to the car and over the asphalt, inside the curbs.

The finished look needs the later foliage, flower and car sprites as well as the road tiles.

## What "smoother" means here

The current art is chunky and noisy: big pixels, random speckle on the grass, dithered shadows.
The new art keeps the pixel-art look but is cleaner and finer:

- **Twice the detail.** Every piece is drawn at twice the current resolution (a course square is
  180×180 px instead of 90×90), so curves and edges come out smoother.
- **Large, flat colour areas with 2–3 tones of shading.** No random noise, no dithering, no single
  stray pixels.
- **Clean curves.** The road's curves follow the guide arcs evenly, with no jagged steps.
- **One outline style.** A 1 px dark outline round each object (dark plum, #281E28, the same as now).
  Inside lines are lighter than the outline.
- **Light from the top left**, on everything.

## Rules for every file

1. **Exact size.** Each file is exactly the size written under its box. Draw inside the box only.
2. **No half-transparent pixels.** Every pixel is fully opaque or fully transparent. This is the
   lesson from the food icons: soft edges look blurry in the game.
3. **Export with nearest neighbour.** If you work bigger, shrink with "nearest neighbour", never
   with smooth resampling. Or draw directly at the final size.
4. **PNG, lowercase file names**, exactly as written in the templates.
5. **No shadows on the ground.** The game adds the track's shadow on the lawn by itself.
6. **Don't include the guide lines.** They're only on the templates.

## The road pieces (`templates/1_road_pieces.png`)

Each piece is one course square, 180×180 px. The game lays them side by side on a grid, so they
must join perfectly. The guides show where:

- **Pink: the road's edges.** The road is 88 px wide (curbs included), centred in the square; in the
  wide set (`templates/1b_road_pieces_wide.png`, files ending in `_wide`) it's 100 px. The pink dots
  are where the road leaves the square; there it must meet the next piece exactly. Draw the wide
  set as the same design with a wider road: same curbs, dashes, side face and colours.
- **Blue: the curb's inner edge.** The curb is a 6 px band of red and white stripes along each edge.
  Make the stripes' length divide 180 (for example 15 or 20 px), so they continue across pieces.
- **Orange: the raised side face.** The track is a raised plastic strip. Where an edge faces down
  the screen (south), its side face shows: a 12 px band under that edge, in the track's orange
  plastic. Edges facing north, east or west show no side face. Small supports under the track (as
  now) are optional; if you draw them, space them 45 px apart on straights and use a whole number
  along each curve, so they line up across pieces.
- **Grey: the centre line.** For lining things up; draw a dashed white centre line if you like.
- **Corners** are a quarter circle round the square's corner. They're named by the two edges the
  road leaves through: `corner_ne` joins the top edge to the right edge.
- **Jump gaps** (`gap_h`, `gap_v`): the road stops, there's a 60 px hole (the orange box) where the
  lawn shows through, then the road starts again. Show the road's cut ends.

Outside the road, the piece is transparent: the lawn is a separate layer under it.

## The overlays (`templates/2_overlays.png`)

These go on top of a road piece, in the same 180×180 square, and are transparent everywhere else.
Keep them inside the road's edges, except the tyre walls. Each also comes in a wide version
(`templates/2b_overlays_wide.png`) that fits the wide road.

- **Start line** (across and up/down): a black-and-white checkered band right across the road.
- **Boost pads**, one for each direction of travel (east, west, north, south): yellow and black
  chevrons pointing the way the car goes. About 32 px long along the road.
- **Ramps**, one for each direction: the lift before a jump gap, in the car's direction.
- **Tyre walls**, one for each corner: a row of stacked black tyres along the corner's outer edge,
  just outside the pink line, about 18 px each.

## The ground (`templates/3_ground.png`)

Three lawn squares, 180×180, fully opaque. **Each must repeat seamlessly**: its left edge joins its
own right edge and its top joins its bottom, and any one must also sit next to the other two. The
game mixes them, so make them similar, with small differences (a few flowers, a darker patch).
Keep them calm: the road must stand out.

## Sprites, decor and the frame (`templates/4_sprites.png`)

- **The car**: 6 slices, 44×32 each, the nose pointing right. The game stacks them bottom first,
  each a little higher than the last, to make the car look 3D (see the current slices in
  `sprites/`): 1–2 the chassis and wheels, 3–4 the body, 5 the cabin, 6 the roof. Same outline on
  each slice. Draw every slice at full brightness: the game darkens the lower ones itself.
- **Small objects**: crate, lamp post, start lamp, spring, balloon, sparkle, helmet. Sizes as in
  the boxes.
- **The start lamp** is one of the three countdown lights. Draw it in white and light greys only:
  the game tints it grey (off), red (3, 2, 1) and green (go).
- **Decor on the lawn**: two bushes, two flower patches.
- **Trees hanging over the edges**: big leafy canopies seen from above, cut off by the board's edge
  they hang over (top, bottom, left, right). They're drawn over the car, so no trunk.
- **The board's wooden frame**: 20 px wide. Four corners, plus a top, bottom, left and right piece
  180 px long that repeat along each side, so their ends must join.

## Colours

Keep the current Garden's feel (see `overview.png`): a fresh green lawn, dark grey asphalt, red and
white curbs, orange plastic sides, black tyres, light brown wood. You can refine the exact colours;
keep each material to 3–4 tones.

## Delivery

Put every file in `textures/minigames/rcprix/garden/`, named exactly as in the templates (76 files:
the 22 road pieces and overlays twice, once per road width, plus the ground, sprites, decor and frame).
Then run the checker:

    python3 tools/art/check_rcprix_art.py

It lists any missing files, wrong sizes, half-transparent pixels or unknown file names. When it
says `0 problems`, the set is ready to go in the game.

You can deliver in two rounds: first the road pieces, the overlays and the ground, so the course
can be tried in the game; then the sprites, decor and frame.

## Seven-file pilot

Before drawing all the files, the first delivery is `straight_h`, `straight_v`, the four
`corner_*` pieces and `grass_a`. The other files wait until these seven have been tried in a real
course. Check this delivery with:

    ./.venv/bin/python3 tools/art/check_rcprix_art.py --pilot

The checker also checks every straight/corner join: the road must cover exactly the same pixels on
both sides (colours may change at a join, as a curb stripe does). Grass seams can't be checked by
machine: judge them in the test course (`python3 tools/art/rcprix_preview.py`). The full check
(without `--pilot`) is the delivery check for all 76 files.

`grass_b.png` and `grass_c.png` are supplied early to vary the lawn in previews. The seven-file
pilot check still requires only `grass_a.png` so the tech team's first renderer trial can stay
focused on the original pilot scope.

The foliage and most of the flower clusters in `style_reference.png` are separate decor sprites.
They are not part of the repeating lawn square; adding them comes after the seven-piece road
pilot so the grass does not look like a repeated bush pattern.

## Not in this kit yet

- **The spectator stand** beside the start straight: the game draws it, with your pals in its seats
  hopping as the car passes. Its art comes in a later round.
- **Effects** the game draws (skid marks, dust, sparkles, the banner) stay as they are for now.
