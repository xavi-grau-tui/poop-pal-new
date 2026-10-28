# RC Prix · Garden: notes for round 10 (start line, start lights, boost pads, ramps)

The full round-9 road and tyre walls are approved and in the game. This round covers the things
that sit **on** the road, plus the start lights. The spectator stand and butterflies come after,
with their own notes.

`round10_now_2x.png` shows today's pieces on your new straight. `round10_game_now.png` shows them
in the game.

## Colours

The game now shows the scenery slightly softer: lighter and a bit less saturated (the "SOFT"
setting). The car keeps its full colours. **Keep drawing at your normal colours, like the road.**
The game softens everything the same way. Don't pre-soften your files.

## What's wrong now

- **Start line:** a thin checker strip with no depth. It doesn't read as a start/finish line
  painted across the road.
- **Boost pads:** yellow and black chevrons in a box. They read as a hazard sign more than as a
  speed boost.
- **Ramps:** a flat teal block with a thin arrow. They don't read as a ramp rising toward the gap.
- **Start lights:** drawn by the game as a plain dark rectangle with three grey circles that turn
  red and then green. No design at all.

## What to draw

The same style as your road: flat tones, clusters of at least 2×2, light from the top left,
outline `#281E28`, on the final pixel grid. Make them match each other: one family of road
furniture.

**Start line** (`start_h`, `start_v`)
- A bold checkered band across the full road width, about 20–24 px deep, 2 or 3 rows of squares,
  with a 1 px edge. The road's curbs stay visible either side.

**Boost pads** (`boost_e`, `boost_w`, `boost_n`, `boost_s`)
- A glowing speed strip: 2–3 bright chevrons pointing the way you drive, on a darker inset pad.
  Pick a "speed" colour that isn't the curbs' red, such as cyan, lime or magenta.
- The chevrons must point east, west, north or south to match each file name.
- About 60×60 px in the middle of the road square, as now.

**Ramps** (`ramp_e`, `ramp_w`, `ramp_n`, `ramp_s`)
- A wooden or metal ramp that clearly **rises** toward the gap: lighter at the high end, darker
  at the low end, a few planks or ribs across it, side rails, and an arrow painted on it.
- Keep today's footprint (about 26×46 px across the road). The game places it right before the
  jump's hole.

**Start lights** (new files, sprites)
- `start_gantry.png`, 90×32: the frame that holds three lamps. A small gantry or board in the
  track's style, maybe with posts or a stripe, and three empty lamp sockets centred at x = 18,
  45 and 72, y = 16.
- `start_lamp_off.png`, `start_lamp_red.png`, `start_lamp_green.png`, 22×22 each: one lamp in each
  state. Lit lamps get a bright centre and a glow ring. The off lamp is dark glass with a small
  highlight.
- I'll swap the game's drawn gantry for these.

## Files

| Files | Size | Count |
|---|---|---|
| `start_h`, `start_v` + `_wide` | 180×180 overlay | 4 |
| `boost_e/w/n/s` + `_wide` | 180×180 overlay | 8 |
| `ramp_e/w/n/s` + `_wide` | 180×180 overlay | 8 |
| `start_gantry` | 90×32 | 1 |
| `start_lamp_off/red/green` | 22×22 | 3 |

The overlays keep their template boxes (`templates/2_overlays.png`, `2b_overlays_wide.png`) and
stay transparent outside the drawing.

## How to work

1. **A look sample first:** `start_h`, `boost_e`, `ramp_e`, the gantry and the three lamps, on the
   final grid. We try them in the game before the rest.
2. What you show us is what you deliver: real PNGs, not generated studies.
3. Then the full set in both widths. Extending your road script is best, so everything matches.

## Test before handing over

1. A 3× picture made **from the delivered PNGs**, on your straight, next to the grass and tree.
2. `python3 tools/art/check_rcprix_art.py`: 0 problems.

## Sample approved: the full set

The revised sample is approved and in the game: `start_h`, `boost_e`, the long `ramp_e` (the one
you showed), the gantry and the three lamps. Please complete the set in exactly that style.

| Files | Notes |
|---|---|
| `start_v` | the start line for up/down roads |
| `start_h_wide`, `start_v_wide` | the same for the wide road |
| `boost_w`, `boost_n`, `boost_s` | chevrons pointing west, north, south |
| `boost_e_wide`, `boost_w_wide`, `boost_n_wide`, `boost_s_wide` | the wide road's pads |
| `ramp_w`, `ramp_n`, `ramp_s` | the long ramp rising west, north, south |
| `ramp_e_wide`, `ramp_w_wide`, `ramp_n_wide`, `ramp_s_wide` | the wide road's ramps |

That's 17 files.

**Turn the drawings, but keep the light from the top left.** A plain mirror or rotation puts the
light and the shading on the wrong side. Redraw the highlights and shadows for each direction.

**The ramps must reach exactly like `ramp_e`.** The game measures `ramp_e` and draws every ramp so
its high end meets the jump's hole. `ramp_e` is drawn from x = 41 to 138, with the high end at 138.
So:
- `ramp_w`: high end on the left, from x = 42 to 139;
- `ramp_s`: high end at the bottom, from y = 41 to 138;
- `ramp_n`: high end at the top, from y = 42 to 139;
- the `_wide` ones reach the same way, only wider across the road (the road is 100 px wide
  instead of 88).

The checker now tests this. A ramp that reaches differently is listed as `ramp ... should be ...`.

**No "1" or other number on the start line** (the user doesn't want it; I removed it from `start_h`). The boost plate's frame and bolts stay in all versions.

Test: `python3 tools/art/check_rcprix_art.py` with no round-10 problems left (the stand and flags
are round 11), and a 3× picture of all the new pieces made from the delivered PNGs.

**Ramp width (added):** the game lets you jump anywhere between the curbs, so the ramps must be that
wide across the road: **76 px on the narrow road, 88 px on the wide one** (today's `ramp_e` is
64 px, so redraw it too). Keep its length and where it reaches.
