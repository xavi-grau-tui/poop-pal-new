# RC Prix: new art, world by world

How RC Prix's graphics move from code-drawn art to designer art. The Garden was done first
(October 2026, rounds 1–22); this is the process to repeat for the other five worlds and, adapted,
for RC Prix 2177. The Garden's files are the worked example: `docs/mockups/rcprix_garden/` (the
brief, a `NOTES_ROUND_<n>.md` per round, guides, samples and backups of every delivery).

**In one line:** the designer gives the look, we give the exact geometry. Whenever size, position
or perspective must be exact, we build it as a guide or block-out in code and the designer paints
over it. Expect rounds to fail whenever the designer has to invent the geometry.

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
8. **Into the game behind a switch.** The new art shows only with the dev launcher's **RC ART**
   switch on (`DevLaunch.rc_new_art`, QA arg `rc_new_art=1`) until the user approves it. Review every
   round **in the game** (QA shots, the whole painted course, the phone), never only from the
   designer's preview pictures.
9. **Finish.** Make the new art the default, remove the switches (RC ART, COLOURS), remove the
   pieces nothing uses any more, and do a last pass over all the world's levels.

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

## Working with the designer

The designer works with an image generator (imagegen). Their pictures look great, but:
- **The picture shown is often not the file delivered.** The delivered PNGs were script repaints,
  pieces cut from other art, or flat redraws. Every brief ends with **"the PNGs you deliver must be the
  pictures you show"**, and the test is a contact sheet made **from the delivered PNGs**. Always
  compare the files in the game with what the user was shown.
- **It can't hit an exact pixel grid, exact sizes or exact positions.** So for anything where those
  matter (stands, barriers, anything along a curve):
  1. we build the geometry in code: the layout, every piece's place, size, angle and visible faces;
  2. we give the designer a **4× paint-over guide** with the real road under it, every piece as a
     faded ghost, the boxes each piece must stay in, and **pink corner marks** to line the picture up
     by (`rcprix_barrier_paint_guides.py`);
  3. they paint the look over it (a 4×4 grid, the road removed, the marks kept);
  4. we bring it down onto the game's grid and check every piece against the guide.
- **"Make it like this reference" works; "design the layout" doesn't.** Name the approved sample
  files in every message (for example `round18_samples/tyres_ne_option_a.png`), and say what to keep
  exactly and what may change.
- **A look sample first** (2–4 files, the hardest cases: a near and a far corner), then the full set.
- **Each message must be paste-ready, short, and complete**, backed by a `NOTES_ROUND_<n>.md`. If a
  round fails, say exactly what's wrong in measurable terms (sizes, counts, overlaps), not "make it
  better".
- **Back up each delivery before replacing it** (`round<n>_delivered_*/`), and never commit the
  designer's uncommitted files without asking.

## Perspective (the game's camera)

The ground is seen straight from above, and anything tall is drawn **up the screen** by its height
(the road's orange side face is the example). So:
- **only faces that look down the screen show:** on a curve's near side (below the road) a barrier
  shows its outer wall, on the far side its inner wall, where it runs up and down its ends;
- **a tall thing's top is its footprint moved up** by its height, so on the near side it may cover
  the foot of the raised road's side face (it stands in front of it);
- **nearer things cover farther ones:** draw from the top of the screen down;
- **every corner of the course needs its own drawing:** never mirror or rotate one view into another;
- **a stand seen from behind shows the pals from behind,** with its roof between the camera and them.

`rcprix_barrier_blockout.py` renders this from geometry: footprint, height, visible walls, light
from the top left. Use it for any 3D prop.

## What the game does in code (`scripts/rc_tiles.gd`, `rc_racer.gd`)

- **Stamping order:** the road pieces, then **all barriers after every road piece** (a later piece
  must never cut one), then overlays (start, boosts, ramps).
- **Jumps:** the hole is cut from the straight in code (`gap_piece`), placed past the square's middle
  so the long ramp fits in the same square (`HOLE_AHEAD`). The ramp art must match the gameplay reach
  (the checker compares every ramp with `ramp_e`).
- **Barriers:** one file per corner with a run-on margin (`_tyres_on`). The margin strip toward a
  straight is kept; toward another corner it's dropped (that corner walls itself). The barrier covers
  the whole curve **plus the stretch where the car bounces** (`_find_rails`: 9 centre points past the
  curve). The run-on pieces looked detached in the game, so the user dropped them (`RUN_ONS := false`):
  only the curve's own wall shows.
- **Decor** never on the track, its barriers, a stand or other decor; **border trees never over a
  barrier** (`_hides`).
- **Start line** on a straight where a front-view stand fits (`_front_start`), plus up to two more
  stands, scored back > side > front. Moving the start must never change the autopilot results:
  check all levels with `FAST=1 ... until=done`.
- **Textures drawn in `_draw`** must be ImageTextures (`RcTiles.drawn`); imported textures drew
  blank there.
- **Colour grade:** the scenery stays in normal colours, the stands always SOFT, the car unchanged
  (`RcTiles.GRADES`, `grade_material`).

## Element by element (what the Garden taught)

- **Road and curbs:** see "Rules that worked". The Round 9 road is the standard.
- **Bushes:** drawn individually at the trees' pixel density, never cut from a tree; a small set too.
- **Stands:** the user picks a front design and a back design from pictures; we convert them on
  5 px blocks; the designer repaints on the final grid. Two layers (`under` and `over`) with the pals
  drawn between them. 1× size, as close to the road as possible, as long as fits. Side views are the
  front turned.
- **Corner barriers:** two styles mixed by level (toy blocks red/white, tyres blue/yellow). It took
  rounds 17–22 because the layout was left to the designer. Rules: the whole curve plus the bounce
  stretch, hugging the road's real edge at every angle (not one radius per corner: the side face
  only exists where the edge faces down), straight bricks along the curve, perspective as above,
  nothing ever cut. Round 22 worked first time: our layout, the designer's paint, converted and
  checked by script (every file 100% on the layout).
- **Start lights:** gantry and lamp sprites, swapped by the game.
- **Boost pads:** one per direction (`boost_n/s/e/w`), all redrawn together.
- **Race messages:** a pixel racing font, one PNG per character (`textures/minigames/rcprix/font`),
  animated letter by letter in code (`RcLettering`), not banners.
- **Butterflies:** sprite frames; the game keeps them over the lawn, off the track.

## Tools

| Tool | What it does |
|---|---|
| `tools/art/rcprix_templates.py` | file list, sizes, templates |
| `tools/art/check_rcprix_art.py` | every file present, sizes, joins, ramps, tree match |
| `tools/art/rcprix_preview.py` | test courses from the pieces |
| `tools/art/rcprix_barrier_blockout.py` | 3D barrier block-outs in perspective (`--game` writes them in) |
| `tools/art/rcprix_barrier_paint_guides.py` | the 4× paint-over guides |
| `tools/art/rcprix_barrier_from_paint.py` | the designer's 4× paintings onto the game grid, checked against the layout (`--game` writes only the ones that fit) |
| `tools/art/rcprix_stand_from_reference.py` | stand pieces from approved pictures; side views |
| `tools/art/rcprix_bush_redraw.py` | bushes from the designer's sketches |
| `tools/art/rcprix_lagoon_from_paint.py` | the Lagoon's 4× paintings onto the game grid, with the checks |
| `tools/art/rcprix_pixelate.py` | any high-res painting onto the game grid (area scale, 50% alpha cut, small palette, lone pixels dropped) |
| `tools/art/rcprix_sky_from_sources.py` | the Sky's art from the designer's paintings (flags in `docs/mockups/rcprix_sky/PLAN.md`) |
| `tools/art/rcprix_sky_round1_guides.py`, `rcprix_sky_ground_guides.py` | the Sky's guides (rings, pad, stand clouds; the ground's grid on one phone screen) |
| `tools/qa/shoot.sh` | QA shots (`rc_new_art=1`, `levels=`, `HEADLESS=1` for errors, `FAST=1 until=done` for autopilot results) |

To see a whole course at once, dump the painted mat: a temporary `RC_DUMP` save in `_tile_art`
(remove it afterwards). It's the quickest way to check barriers, decor and stands on every level.

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

## What the Lagoon taught (October 2026)

The Lagoon (`docs/mockups/rcprix_lagoon/`: `PLAN.md`, `NOTES_ROUND_1B/1C/2.md`) went differently from the
Garden, and better in the end. For the Sky, Night, Reef and Grand Prix:

- **Pieces only where edges are hard.** Water has soft bands that run past a square, so the game keeps the
  shapes (the distance to the centre line) and a shader fills them (`scripts/rc_lagoon.gd`). Narrow gaps fill
  with sand, big lakes stay water: a morphological opening on a coarse grid (`rc_racer.gd` `_sea_fields`);
  corners rounded by averaging the distance in the shader (`soften`).
- **Big calm surfaces are drawn by the game, not painted.** The designer's painted water squares read as
  TV static. The water is now flat colours plus moving layers (swell, crests, glints, foam, a sandy bottom
  under them); the designer gives small animated sprites (glint, crest) and the textures that have a
  pattern (sand). Expect the same for the sky and clouds.
- **Style picture first, then 4x paintings.** Ask for 2-3 style pictures, the user picks one, then every piece
  is painted at 4x (one game px = a 4x4 block) and `tools/art/rcprix_lagoon_from_paint.py` converts and checks
  it. Script-drawn art and soft image-tool art both failed before that.
- **The converter's checks** (fail early, before the user sees it): size, hard pixels, a detail range per
  material (calm water low, sand 5-16%), lone pixels under 3% (speckle reads as static), a colour cap per kind
  (decor 6, rocks 8, palms 10, islands 14, big pieces 24), tiling and identical borders across variants, mixed
  4x4 blocks (soft brush or off the grid).
- **Match each piece to its Garden counterpart, side by side at the same zoom** (sand vs grass, decor vs
  flowers, islands vs bushes, palms vs trees, sparkles vs butterflies): `reference/pixel_density.png`.
- **Keep the world's own colours.** Option 3's purple channel and teal shallows were rejected for the
  original Lagoon's warm sunset; take a style picture's composition and finish, not necessarily its palette.
- **Reuse the Garden's finished pieces,** recoloured in code where needed: the stands (on a pier, a peach
  canopy, legs and posts foamed at the water), the start lights, the frame, the stands' flags at the finish,
  the light effects in the world's colours (FX switch; Lagoon: no mist, the glow's ring edges faded wide).
- **Decor:** several models per kind in 2-3 sizes, small (16 px max), favouring the small ones, the same kind
  kept apart, outlines a darker shade of the piece's own colour (the game also does it: `_soft_outline`).
  Pieces that don't read at game size come out (driftwood, beach grass, toys).
- **3D props over our guides,** as the barriers: buoys (5 slices), currents and jumps (4 directions), with
  `round*_guides/`. Their behaviour stays in code, only the look changes.
- **Life without clutter:** fish shadows (finer pixels, darker), crabs that scuttle off as the boat passes (5
  per course, not 10), a finer wake. The user prefers rich but calm.

## What the Sky taught (October 2026)

The Sky (`docs/mockups/rcprix_sky/PLAN.md`) is done apart from polish. For Night, Reef and Grand Prix:

- **The designer paints, we pixelate.** Their ImageGen paintings (high-res, transparent, no glow, light from the top
  left) are good; their pixel art and scripted shapes are not (the first rings and clouds were rejected). So they
  paint big and `tools/art/rcprix_pixelate.py` puts it on the grid, for every size the game needs, each scaled
  from the painting itself (never a resized sprite). Ask for one painting per thing, not per size.
- **Turn on the big painting, not on the pixels.** The fields are painted straight and turned to the grid's angle
  before pixelating (no jagged edges); the rings are transposed and flipped as pixels only because they're symmetric.
- **One good painting, many uses.** The drifting clouds became the stands' clouds and the runway's clouds too; the
  user preferred that to purpose-painted banks.
- **Far away = paler, never see-through.** The ground: the paintings softened, desaturated and hazed by a shader.
  The drifting clouds ended solid and paled towards the haze, the lower layer more (the user, after trying 65–85%
  transparency). Shadows too are pale.
- **Keep what the user loves in the original** (the diagonal grid, the wind streaks, the noise cloud shading) and
  fill it with the new art rather than replacing it.
- **Readable props beat clever ones:** the drone pad read as military; a cloud runway seen from the side, the
  stands seen from the front (the start moved to a straight where a front stand fits).
- **Timing with sound:** effects tied to an event fire on the sound's own frame (the gold ring on the chime).
- **Check gameplay after each visual change:** the autopilot (`FAST=1 HEADLESS=1 ... until=done`) must give the
  same stars and time.

## RC Prix 2177

A separate game with its own code (`scripts/pal_prix_2.gd`, `pal_prix_2_art.gd`,
`pal_prix_2_course.gd`, `pal_prix_2_fx.gd`), so this kit does not carry over directly: its ground is
painted by shaders from the course (`scripts/shaders/pal_prix_2_board`), not by pieces. Use the same
steps: export its current art, check how its courses are built (grid or free), decide what can be
pieces, then templates, a pilot and a look sample. The rules (no soft edges, joins, one outline,
light from the top left, separate layers for the tilt) still apply.

For the other worlds and 2177, start each kit by listing its 3D props (barriers, buoys, rings,
stands) and plan their geometry in code from the first round, with paint-over guides.

## Still open

State (2026-10-30): Garden, Lagoon and Sky done behind RC ART; Night Race, Reef and Grand Prix not started
(next: Night Race, the Garden's kit in night colours plus a crossover, bridges, lamps).

- Finish (step 9), once every world is done: make the new art the default, remove the switches, remove unused
  pieces (the designer's `gap_*` files, `start_lamp`, the car slices from the brief; the Sky's drone pad and
  concept C runway; the Lagoon's dropped decor: the untracked `bucket`, `sandcastle`, `driftwood`, `grass_tuft`,
  `crab_*` PNGs from `rcprix_lagoon_round2_crab_decor.py` are not used by the game).
- Lagoon: more stands seen from the front (as the Sky); designer sand B/C, splash and ripple.
- Sky: wind streaks, contrail and sparkles on the 2 px grid.
- Garden: effects drawn in code (skid marks, dust, FINISH): undecided.
- Garden: maybe move the start gantry off the front stand's back rows.
