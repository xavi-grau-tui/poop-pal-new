# RC Prix · Lagoon: plan for the new art

World 2 of RC Prix, levels 10–18: a toy boat racing a channel marked by buoys across a lagoon
at sunset. Same process as the Garden (`docs/rcprix_art_process.md`); this page is what's
different and the order of the rounds.

**Decided (the user, 2026-10-28):** keep the sunset mood (warm pink/orange water, sandy banks,
red and yellow buoys). The Reef (world 5) gets the bright turquoise daytime look later.

## Today (`current/`)

The whole board is painted in code from the distance to the channel's centre line
(`rc_racer.gd`: `_paint_water`, `_water_px`, `_lagoon_water`, `_lagoon_bank_decor`):

| Band (from the centre) | World px | What it is |
|---|---|---|
| Channel | 0 → half width (118 on level 1, 102 on level 9) | Deeper water, where the boat races |
| Shallows | + 52 (`SHORE_PAINT`) | Lighter water, foam at the far side, the buoys on the inner edge; the boat slows here |
| Bank | + ~40 | Sand outlined dark, pebbles, starfish, shells, seagrass; running onto it is a crash |
| Open lagoon | the rest | Sunset water, wave crests, the sun's road of light, islands with palms |

Also: buoys (floating sprites in slices, pushed by the boat: `FloatingBuoys`), currents (a warm
glow plus moving foam arrows: `WaterFx`), sandbars across the channel to jump (flat sand blocks
today), the pier stand with the crowd, fish, the boat (5 code-drawn slices), the wooden frame.

Weak spots visible in `current/level_*.png`: flat sandbar blocks, flat water with a repeated dash
pattern, thin banks pinching into V shapes at hairpins, islands all the same oval.

## Pieces or bands? (recommended: bands + sprites)

The Garden's road worked as square pieces because a raised road has hard, fixed edges. The
Lagoon's edges are soft bands that run past the square: the bank ends ~104 art px from the centre
but a square is only 95 each side, so neighbouring channels' banks overlap and merge into one sand
spit between them (as today). Square pieces would need two passes and many join cases.

So: **the game keeps the geometry** (the distance bands, as now, at twice the detail) and
**the designer gives the look**:

- **Seamless textures** (one square each, tiling, 190×190 art px): open lagoon water, channel
  water, shallows, sand. A few variants each so no grid shows.
- **Edge rules** in the designer's colours: the bank's outline, wet edge and foam, drawn crisp by
  code along the bands (the designer paints a sample strip; we match it).
- **Sprites** for everything with a shape: buoys, islands, palms, decor, sandbar ramps, current
  arrows, start pontoon, pier, boat.

**Sand in the narrow gaps** (the user, 2026-10-28: fill the gaps between curves, widen or softly join
the thin necks, but keep the big waters and their islands): only open water a disc of 72 world px fits
in stays water (a morphological opening on a coarse grid, `rc_racer.gd` `_sea_fields`), so hairpin
tips and narrow strips become sand with rounded edges; closed-in ponds under 2 squares become sand too.
Islands only where the water is wide; no fish on the sand. **Decor** (starfish, shells, pebbles,
seagrass) on the banks and the filled sand from round 1 (`RcLagoon.decor`).

Doubling the detail: one art px = 2 world px, as the Garden. A boat square is 380 world px =
190 art px.

## Props (3D: we build the geometry, the designer paints over guides)

| Prop | Plan |
|---|---|
| Buoys | Red and yellow, in slices for the floating 3D (like the car). Block-out in code, paint-over |
| Sandbar jumps | A raised sand ramp across the channel on a whole straight square, 4 directions × 2 widths, matching the jump reach (as the Garden's ramps) |
| Start | A floating start line (checked pontoon or a buoy line) h/v × 2 widths; the start lights reused |
| Pier stand | The Garden's stand art on wooden posts in the water, ripples round the posts |
| Islands | 3–4 shapes and sizes, each with its beach, grass top, cliff side and shadow; palms as separate sprites over the boat (like the trees) |
| Currents | Foam arrows on whole squares, 4 directions × 2 widths, still animated by code |
| Boat | 5 slices redrawn at twice the detail (round 4; the old one doubled meanwhile, as the car) |

## Rounds

1. **Look sample:** the four water/sand textures and one painted bank strip (straight + curve),
   at sunset. We render them into a real Lagoon course behind RC ART and check on the phone.
2. **Props block-outs:** buoys, sandbar ramp, start line, pier; paint guides; the designer paints.
3. **Islands, palms, decor** (shells, starfish, rocks, seagrass, driftwood), currents.
4. **The boat.**
5. **Atmosphere** (FX switch): low sun glow, glinting sun road, slow wave shimmer, seagulls
   instead of butterflies.
6. **Finish:** all 9 levels, then make it the default with the Garden.

Two widths (as the Garden): wide for levels 1–4 (half width 116) and narrow for 5–9 (106). The
game uses those two instead of the per-level widths now.

## Checklist (updated 2026-10-28)

How it's built now: **the game draws the water** (the original Lagoon's warm colours, swell, crests, glints,
foam, a sandy bottom showing through: `RcLagoon.SHADER`), **the designer draws the sand and everything with
a shape**, matched side by side with its Garden counterpart (`NOTES_ROUND_1C.md`, `NOTES_ROUND_2.md`).

### Done
- [x] Renderer behind RC ART (old look a switch away), two channel widths, sand in narrow gaps and small
      ponds, big lakes kept, rounded sand corners (`_sea_fields`, `SAND_ROUND`)
- [x] Water drawn by the game in the original's warm colours (no purple, no teal), moving layers, the
      designer's glint and crest frames, a sandy bottom under all the effects and never over them
- [x] The designer's sand A, starfish A/B, seagrass A/B in the game
- [x] Islands placed again (the `_sea` cap bug), the designer's island B and palm A on them
- [x] The Garden's start gantry and lamps in the Lagoon
- [x] A floating checkered start pontoon with flag posts (drawn by the game)
- [x] The Garden's stand on a pier (posts in the water, foam), in the sunset's light
- [x] Buoy paint guides (`round2_buoy_guides/`); the game takes the designer's slices when they're in
- [x] Converter: a detail range per material, a speckle check, a colour limit
- [x] The designer's round 2: decor variety (4 shells, 4 pebbles, 3 starfish, 3 seagrass), islands A–D, palm B
- [x] Decor outlines in each piece's own colour, darker (the user: not near-black)
- [x] Tiny shapeless bits on the sand (1–5 px, sand and shell colours, mixed sizes)
- [x] The sandy bottom stronger (light and shade only, the user: "now fine")
- [x] The Garden's light effects in sunset colours (FX switch): glow, beams, plum cloud shadows, no mist;
      the glow's ring edges fade wide (the user saw "crossed sun beams")
- [x] Rounder inner corners: the distance softened in the shader (`soften`)
- [x] The designer's buoys (behaviour untouched) and pier posts with animated foam

### Designer (`NOTES_ROUND_2.md`)
- [ ] Decor with variety: 3+ models per type in 2–3 sizes (starfish, shells, pebbles, seagrass), shells
      and pebbles redone (light fills, thin outline), new kinds: crab, driftwood, beach grass, coconut,
      toy sandcastle, toy bucket
- [ ] Islands A–D redone to the Garden's pixel look (bushes/trees), sand beach all round; palm B; rocks A, B
- [ ] Sand B and C
- [ ] Splash and ripple frames
- [ ] Fish shadows (3 frames)
- [ ] Round 3, over our guides: sandbar jumps, the start pontoon
- [ ] Islands' beach back to sand colours if the user confirms (the cleanup made it olive)
- [ ] Decor outlines in the piece's own colour, darker, in the files themselves (the game does it now)

### Code (me), as the art arrives
- [ ] Decor: place the new kinds (crab, driftwood, grass tufts, coconut, sandcastle, bucket), mixed sizes,
      the same kind kept apart (as the Garden's bushes)
- [ ] Rocks in the water and at the islands' edges, with a foam ring
- [ ] Fish shadows from the designer's frames (same behaviour)
- [ ] Splash on buoy hits and beaching, ripple rings round buoys and rocks
- [ ] Guides for the sandbar jumps, the start pontoon and the pier posts
- [ ] Maybe seagulls over the water (the Garden's butterflies' role)
- [ ] The old flat sandbar blocks until the new jumps
- [ ] Final pass over all 9 levels (autopilot, every course), then the default with the Garden
