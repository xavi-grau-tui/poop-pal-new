# RC Prix: new art, world by world

How RC Prix's graphics move from code-drawn art to designer art. The Garden was done first
(October 2026); this is the process to repeat for the other five worlds and, adapted, for
RC Prix 2177. The Garden's files are the worked example: `docs/mockups/rcprix_garden/`.

## Why pieces

RC Prix draws everything in code (`scripts/rc_racer.gd`, `scripts/pal_prix_art.gd`), so a designer has
nothing to replace. But every course is already laid out on a grid of squares
(`rc_racer.gd`: `CELLS`, `_build_circuit`), so the road can be built from square pieces like a
board game. The designer fills the same set of boxes for every world, and a new world is art, not
code.

## Decisions (2026-10-27, the user)

- **Twice the current detail:** one course square is 180×180 art px (a car world square is 360
  world px; one art px = 2 world px, shown 3 screen px).
- **Two road widths per world:** a wide set for the world's early levels and a narrow set for its
  later ones. Garden: 100 px (levels 1–4) and 88 px (5–9). Wide files end in `_wide`.
- **Boost pads, the start line and jumps sit on whole squares**, centred on a straight, never on
  curves. The game snaps them there (today they're placed by distance along the course).

## The steps

1. **Export the current art.** Run the game on the world's levels and save its layers and sprites
   as PNGs (the Garden's: `overview.png`, `pieces/`, `sprites/`). This shows the designer what is
   being replaced, at real sizes.
2. **Templates.** `tools/art/rcprix_templates.py` draws one box per file at its exact size, with
   guides for the road's edges, curbs, side face and join points. It also holds the list of files
   and sizes (`SIZES`) that the checker uses.
3. **Brief.** One page per world: what "smoother" means, the rules, every file, delivery
   (the Garden's `BRIEF.md`).
4. **Pilot: 7 files.** The two straights, the four corners, one grass square. Checked with
   `tools/art/check_rcprix_art.py --pilot` and assembled with `tools/art/rcprix_preview.py`.
   This catches geometry mistakes after 7 files instead of 76.
5. **Look sample: 2 files.** One straight and one corner with the final depth and finish, approved
   by the user before the full set is drawn.
6. **The full set.** Everything in the brief, in both road widths.
7. **Self-check.** The checker must report 0 problems, and the designer sends the test-course
   pictures from `rcprix_preview.py` with the files.
8. **Into the game.** The game builds courses from the pieces (to do: not built yet).

## Rules that worked

- Every pixel fully opaque or fully transparent; export with nearest neighbour. Soft edges look
  blurry in the game (learned on the food icons).
- One outline colour (#281E28), light from the top left.
- **Joins:** the road covers exactly the same pixels on both sides of a join; colours may change
  there. On straights, curb stripes and centre dashes use a length that divides 180. On curves,
  use a whole number of them per arc (inner curb about 77 px, centre line about 141 px, outer curb
  about 206 px for the 88 px road), so every join falls at the same point of the pattern.
- **Raised side face:** only under edges that face down the screen (south): the outer edge of a
  corner at the top of a bend, the inner edge of a corner at the bottom.
- **Grass:** three seamless squares that put their tufts in different places, or the board shows
  rows. Bushes, flowers and trees are separate decor sprites, never baked into the grass.
- No shadows on the ground: the game adds them. The 3D tilt slides the lawn under the track and
  the trees above it, so those stay separate layers.
- Two pieces drawn by the same script look consistent; the designer's scripts are in `tools/art/`
  (`rcprix_garden_pilot.py`, `rcprix_round2_sample.py`).

## Mistakes to avoid

- Sampling painted (generated) images pixel by pixel gives speckle and many in-between colours:
  it doesn't read as pixel art next to hand-drawn pieces (the Garden's first road and bushes).
  Use a few clear tones per material and clusters of at least 2×2 pixels. The approved trees and
  grass set the standard.
- The car: the code's original was preferred to the designer's. The game doubles it with Scale2x
  (`RcTiles.car_slices`), so a world's toy may stay code-drawn.
- Shadows and light are the game's (`RcTiles`: the track's shadow, the trees' shade, the decor's
  shadows), never baked onto the ground.

- A join check that compares colours flags correct curbs (a stripe can change colour exactly at a
  join). Compare which pixels the road covers.
- A seamless check that demands identical opposite edges draws a doubled line at every seam.
- Bands on curves drawn as straight segments show as angular patches: they must follow the arc.

## The other worlds

The structure stays; the pieces change with the world's toy (`rc_racer.gd`: `LEVELS`, `WORLDS`):

| World | Toy | What its kit needs on top of the Garden's |
|---|---|---|
| Lagoon | boat | No raised track: the channel's water, the buoys marking it, shallows and the sandbank (the crash) instead of curbs; currents instead of boost pads; ramps over sandbars |
| Sky | plane | No road: the ground far below (it slides more with the tilt), the flight path, rings to fly through, gusts, balloons, the launch deck |
| Night Race | car | The Garden's pieces in night colours, plus a **crossover** piece and a bridge (figure-8s), lamp posts, headlights, puddles and oil, rival cars |
| Reef | boat | The Lagoon's kit with rocks, logs and whirlpools, rival boats |
| Grand Prix | plane | The Sky's kit over a sea of clouds, storm clouds, rival planes |

The boat and plane worlds need their own piece lists and templates before step 2. The water and
the sky are mostly drawn as continuous layers today, not as a road, so work out with the code what
is a piece and what is a layer.

## RC Prix 2177

A separate game with its own code (`scripts/pal_prix_2.gd`, `pal_prix_2_art.gd`,
`pal_prix_2_course.gd`, `pal_prix_2_fx.gd`), so this kit does not carry over directly: its ground is
painted by shaders from the course (`scripts/shaders/pal_prix_2_board`), not by pieces. Use the same
steps: export its current art, check how its courses are built (grid or free), decide what can be
pieces, then templates, a pilot and a look sample. The rules (no soft edges, joins, one outline,
light from the top left, separate layers for the tilt) still apply.

## Still open

- The game side: building courses from the pieces (step 8).
- The spectator stand, drawn in code with the pals in its seats: its art in a later round.
- Effects drawn in code (skid marks, dust, sparkles, the banner): redraw at the new detail in code,
  or as art.
