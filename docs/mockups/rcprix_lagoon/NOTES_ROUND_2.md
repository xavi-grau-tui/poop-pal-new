# RC Prix · Lagoon, round 2: everything still missing

The Lagoon is coming together in the game: the game draws the water (warm sunset colours, swell, crests,
your glints, foam, a sandy bottom showing through), your sand and starfish are in, and the Garden's stand
now sits on a pier. This list is **everything we still need from you**, in the order we'd like it. Same
rules as before (`NOTES_ROUND_1C.md`): 4× paintings, one game pixel per 4×4 block, hard edges, **matched
side by side with its Garden counterpart**, delivered into `docs/mockups/rcprix_lagoon/round2_paint/`
(converted by `tools/art/rcprix_lagoon_from_paint.py round2`).

## What the user said about the last batch

- **Starfish and seagrass: good**, they're in the game.
- **Shells and pebbles: not yet.** Mostly dark outline with a little fill: at game size they read as
  dark holes. Light fills, a thin outline, like the Garden's flowers.
- **Islands B and C don't match the pixel look.** They're smoother and finer than the Garden's bushes and
  trees, and C is bright lawn green with no beach. Islands must look like the same pixel art as
  `bush_a.png` ... `bush_g.png` and `tree_*.png`: the same pixel size for leaves and shading steps, the
  same outline, a sand beach all round, muted grass in the sunset palette.
- **Decor needs variety:** more than one model per type, in different shapes **and sizes**, or the beach
  looks repetitive.

## 1. Decor, with variety (first)

At least **3 models per type, in 2–3 sizes** (small, medium, the odd bigger one):

| Type | Files | Sizes (game px) |
|---|---|---|
| Starfish | `starfish_c` (we have a, b), one bigger | 8–18 |
| Shells | `shell`, `shell_b`, `shell_c`, `shell_d`: a scallop, a spiral, a cone, a tiny one | 6–14 |
| Pebbles | `pebble`, `pebble_b`, `pebble_c`, `pebble_d`: round, flat, a little group | 6–14 |
| Seagrass | `seagrass_c` (we have a, b), one taller tuft | 6–14 |
| New kinds | `crab` (2 frames if you like), `driftwood` (2 sizes), `grass_tuft` (beach grass, 2), `coconut`, `sandcastle` (tiny toy one), `bucket` (toy) | 8–24 |

Soft and small, in the sand's warm palette, outlined lightly, lit from the top left, like the Garden's
`flowers_a.png` / `flowers_b.png`.

## 2. Islands and palms, redone to the Garden's pixel look

`island_a` (90×50), `island_b` (120×64), `island_c` (150×80), `island_d` (180×70), all with a sand beach
all round, muted grass on top, an earthy side at the bottom, irregular shapes. Plus `palm_a` (keep), 
`palm_b`, and `rock_a`, `rock_b` (about 14×10 and 22×14) for the water and the islands' edges.
The game adds their shadow and the foam ring round them.

## 3. Sand B and C

`sand_b`, `sand_c` like `sand_a` (keep its ripples and calm), different patterns inside, the outer 3 px
identical so they mix. Today the one square repeats.

## 4. Water sprites still to do

`splash_0..3` (about 12×8: foam when the boat hits a buoy or the beach) and `ripple_0..3` (about 16×8: rings
spreading round a buoy or a rock), the colours in `NOTES_ROUND_1C.md`.

## 5. Buoys (over our guides)

`round2_buoy_guides/` has a guide per slice: the buoys float in 3D as **5 stacked slices** (waterline,
body, white band, top, cap), **14×14 game px each** (56×56 at 4×), red and yellow. The user likes the
original design: **keep its shape and colours** (red or yellow with the white band and cap), only redraw it
at the Garden's detail, like the Garden's car slices. Paint over each guide (keep the pink corner marks)
and deliver `buoy_red_0_4x.png` ... `buoy_red_4_4x.png` and `buoy_yellow_0..4_4x.png`. Their behaviour
(bobbing, pushed by the boat, springing back) doesn't change. `buoy_stack_preview.png` shows the stack as
the game draws it.

## 6. Fish shadows

`fish_0..2` (about 10×5, 3 frames): a soft dark fish silhouette seen from above (body, fin, a tail that
wiggles across the frames), one colour with maybe one lighter step, the size of the Garden's butterflies.
The game keeps their behaviour (swim, dart away and fade near the boat).

## 7. Later, with guides from us

The sandbar jumps (a raised sand ramp across the channel, today flat yellow blocks), the start pontoon
(the game draws a checkered one for now) and the pier's posts. We'll send guides.

## Delivery order

1 (decor) and 2 (islands) first, then 3 and 4, then 5 and 6. Send each group when it's ready; we put it in
the game and send phone screenshots.
