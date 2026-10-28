# RC Prix · Lagoon, round 1: water, sand, decor, islands

RC Prix's second world, the Lagoon (levels 10–18): a toy boat racing a channel marked by red and
yellow buoys, across a lagoon **at sunset**. The Garden is finished in your art; the Lagoon should
reach the **same quality** (`reference/garden_quality_bar_*.png`), keeping its own sunset mood.

This round is everything that doesn't need exact geometry from us: the water and the sand, the
bank's look, the decor on the sand, the islands and the palms. The sandbar jumps, the start line,
the pier stand and the current arrows come next, over guides we build (as the Garden's barriers).
The boat and the buoys stay as they are.

## Pixel density: the same as the Garden (most important)

**`reference/pixel_density.png`** shows it side by side. In short:

- **One game pixel = 2 world px, exactly the Garden's.** A Lagoon square is 190×190 px (the Garden's
  180×180): the same amount of detail per square.
- **Match the Garden's files**, not today's Lagoon: count the pixels in `textures/minigames/rcprix/
  garden/bush_a.png` (96×82), `flowers_a.png` (16×12) and a grass blade in `grass_a.png`. A wave
  crest, a shell or a palm leaf should be built from pixels of that size.
- **Today's Lagoon is twice as chunky** (each of its pixels is 2×2 of yours). Don't copy its pixel
  size, only its mood and colours.
- **Draw on the real grid at the final size.** Never paint big and shrink: that gives soft, blurry
  pixels (we've had to redo deliveries for this).
- `reference/garden_quality_bar_1.png` and `_2.png` are the Garden on the phone: that's the finish
  the Lagoon should have on the same screen.

## How the Lagoon is built (different from the Garden)

No square road pieces this time. The game draws the shapes itself from the channel's centre line,
in bands, and fills each band with **your seamless squares**:

| Band | Width (art px, from the channel's edge out) | Fill |
|---|---|---|
| Channel | half width 58 (levels 1–4) or 53 (levels 5–9) from the centre | `channel_*` |
| Shallows | 26 | `shallows_*` |
| Sand bank | 20 | `sand_*` (its edges: below) |
| Open lagoon | everything else | `water_*` |
| Narrow gaps | water too narrow between curves (hairpin tips, thin strips, small closed ponds) | `sand_*`: filled with sand, rounded |

Where two channels run side by side their banks merge into one sand spit; the game handles that.
The big lakes inside the course's loops stay water, with islands; only the narrow gaps fill. Those
filled patches can still be a square or two of sand, so **the sand must not show any repeat or grid**.
`reference/lagoon_standins_ingame.png` shows the game already drawing this with our quick stand-in
squares (in `textures/minigames/rcprix/lagoon/`). Your squares replace them, so the result shows up
in the game straight away.

## What to draw

### 1. Twelve seamless squares: `templates/1_textures.png`

`water_a/b/c`, `channel_a/b/c`, `shallows_a/b/c`, `sand_a/b/c`, each **190×190 px**.

- **Seamless:** each square tiles with itself (left edge continues the right, top the bottom).
- **Any variant next to any other:** the game mixes A, B and C at random, so the **outer 3 px ring
  must be identical in all three variants** of a kind (the white line in the template). Put the
  variety inside: different wave crests, ripples, sand patches. No grid should show at phone size.
- **Painted at the sunset's middle tone.** The game adds the sunset across the board itself
  (warmer orange at the top, plum at the bottom), so paint the water as it looks mid-board.
- **Water:** sunset pink-orange like today, with short wave crests catching the low sun and a few
  soft ripples. Calm and readable: the boat, the buoys and the foam must stand out on it.
- **Channel:** a little deeper and darker than the open water, the same family.
- **Shallows:** lighter and warmer, a hint of sand showing through.
- **Sand:** warm sand with soft lit patches and fine grains, at the Garden's detail.

### 2. One bank sample: `templates/2_bank_guide_4x.png`

A straight and a curve of the channel, wide (top) and narrow (bottom), with the exact bands.
**Paint over it on its 4×4 grid** (one game pixel = one 4×4 block) to show how the edges should look:

- where the shallows meet the sand (foam breaking, wet sand),
- the sand bank itself and its outline on both sides,
- where the sand meets the open water.

Keep the band edges where the lines are and keep the pink corner marks. We take the colours and
the edge widths from your painting and the game draws them along every channel.

### 3. Decor on the sand: `starfish`, `shell`, `pebble`, `seagrass` (and more if you like)

The original Lagoon had starfish, shells and pebbles along the banks and seagrass in the shallows;
the game places them again (on the banks and on the filled sand, never on each other). Redraw them
at the Garden's detail, the way the Garden's flowers and grass tufts are drawn:

- `starfish.png`, `shell.png`, `pebble.png` about **10–16 px**, `seagrass.png` about 8×10 px (a tuft
  growing in the shallow water); transparent around, outlined, lit from the top left.
- **Two or three variants each** are welcome (`starfish_b.png`, ...), and new kinds that suit a sunset
  beach: a small crab, driftwood, a beach grass tuft, sand ripples, a bucket-and-spade toy. Show us.
- Today the game uses the original ones at their size (`textures/minigames/rcprix/lagoon/`), as a
  placeholder.

### 4. Islands and palms

Islands sit in the open water and the big lakes inside the course (today: plain ovals, all the same,
`current/level_*.png`). Draw **four islands**, transparent around:

| File | About (px) | What |
|---|---|---|
| `island_a.png` | 90×50 | a small sandbar island, sand only, maybe a shell or two |
| `island_b.png` | 120×64 | sand beach, a grassy top |
| `island_c.png` | 150×80 | bigger, room for two palms, a rock |
| `island_d.png` | 180×70 | long and irregular |

- Seen from above at the game's slight angle, like the Garden's track: a beach (wet sand at the
  water, outlined), a raised grassy top with its earthy side showing at the bottom, lit from the top
  left. Not ovals: natural, irregular shapes.
- **Don't draw** their shadow on the water or the shallows ring around them: the game adds both, so
  the islands sit on any water.
- **Palms** as separate sprites (`palm_a.png`, `palm_b.png`, about 30×40 px): trunk and crown, the
  crown's leaves at the Garden trees' leaf size; the game puts them on the islands and adds their
  shadow.

## Rules (as the Garden)

- Every pixel fully opaque, no soft edges, no anti-aliasing; export with nearest neighbour.
- The squares are full squares: no transparency.
- Light from the top left. The outline colour where one is needed: #281E28, or a warm dark brown
  for the sand if it reads better at sunset (show us).
- **The PNGs you deliver must be the pictures you show.** Draw on the real grid; don't shrink a
  bigger picture.

## Files in this folder

| File | What it is |
|---|---|
| `PLAN.md` | The whole Lagoon plan, round by round |
| `current/level_1..9.png` | Every Lagoon course as the game draws it today (the look we're replacing) |
| `current/ingame_level_*.png` | Today's Lagoon on the phone |
| `reference/pixel_density.png` | **The pixel density to match**: the Garden's art next to the Lagoon's sizes, x2 and x4 |
| `reference/garden_quality_bar_*.png` | The finished Garden in the game: the quality to match |
| `reference/garden_course_preview.png` | A whole Garden course in your art |
| `reference/lagoon_standins_ingame.png` | The new renderer with our quick stand-ins |
| `templates/1_textures.png` | The 12 squares, one box each, the 3 px shared border marked |
| `templates/2_bank_guide.png`, `_4x.png` | The bank sample's guide (paint over the 4×) |

## Delivery

1. **First (look sample):** `water_a`, `channel_a`, `shallows_a`, `sand_a`, the bank sample, the
   four decor pieces and `island_b` with one palm. We put them in the game and send you phone
   screenshots before you go on.
2. **Then:** the B and C variants of each square, the other islands and palm, decor variants and
   extra kinds.

Into `textures/minigames/rcprix/lagoon/` (squares, decor, islands, palms) and
`docs/mockups/rcprix_lagoon/round1_bank/bank_paint_4x.png` (the sample).
