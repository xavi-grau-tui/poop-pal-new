# RC Prix · Lagoon, round 1c: the game draws the water; you draw the sand and the water's sparkle

Thank you for round 1b. The **sprites are good** (the island, the palm seen at an angle, the starfish,
shell, pebble and seagrass) and the bank sample's foam breaking on the sand is the right idea; all of
those stay in the game.

The squares didn't work on the phone: the water read as TV static and everything turned harsh orange.
So we changed the approach (the user, 2026-10-28):

## What changed

- **The water is now drawn by the game**: flat calm colours with moving layers on top (a slow swell,
  wave crests that rise and sink, sun glints that twinkle along the sun's path, light rippling in the
  shallows, foam washing up and back on the sand). Your `water`, `channel` and `shallows` squares are
  no longer needed.
- **The colours are the original Lagoon's, improved**, not option 3's. The user found the plum channel
  too purple and the teal shallows a sudden blue border. The palette in the game now:

| Area | Colours |
|---|---|
| Open water | #e0947f peach, #ce7d7a swell, #f6c08f crests, #ffe2a8 glints |
| Channel | #c17680 dusty rose, #ad6678 deeper, #ce8789 swell, #eca996 crests, #f9d2a3 glints |
| Shallows | #de9887 → #e9a88f → #f3bc9a → #fbd4ae toward the sand (warm, no teal) |
| Foam | #fff6ea, fringe #fce2ca |
| Wet sand | #eaaa6a |

Option 3 stays the reference for **composition and finish** (the foam, the sand spit, islands with
palms and rocks), not for its colours.

## Match the Garden, piece by piece (most important)

The user's goal: **the Lagoon's assets must be aligned with the Garden's**: the same pixel density,
the same kind of detail, the same finish. Before you send anything, put it next to its Garden
counterpart at the same zoom (`reference/pixel_density.png` shows how) and check they look like they
belong to the same game:

| Lagoon piece | Its Garden counterpart (`textures/minigames/rcprix/garden/`) | Match |
|---|---|---|
| `sand_a/b/c` | `grass_a.png`, `grass_b.png`, `grass_c.png` | the same calm, clustered texture: shapes of 2–6 px (the grass's blades and patches = the sand's ripples and damp patches), no lone pixels |
| `starfish`, `shell`, `pebble`, `seagrass` | `flowers_a.png`, `flowers_b.png` | the same size and finish: small, clean, outlined, lit from the top left |
| islands, rocks | `bush_a.png` ... `bush_g.png` | the same pixel size for leaves, rock facets and shading steps |
| palms | `tree_top.png` (the border trees) | the same leaf size and the same slight angle |
| `glint`, `crest`, `splash`, `ripple` | `sparkle.png`, `butterfly_0..2.png` | the same tiny-sprite style and frame size |

If a piece has more single pixels, more colours or finer detail than its Garden counterpart, it's off.

## What we need from you

### 1. The sand, repainted: `sand_a`, `sand_b`, `sand_c` (190×190, painted at 4×: 760×760)

Today's `sand_a` is speckle: single pixels everywhere in deep orange. Sand should read as sand:

- **Pale warm gold**, lighter than now: base around #fdd87b and #fcc96e, shading #edd890, the darker
  #eaaa6a only in small damp patches.
- **Bigger shapes, not speckle:** soft wind ripples (gentle curved lines a few pixels apart, lighter on
  top, darker below), a few soft damp patches, small clusters of grains (2–4 pixels together, never
  lone pixels). Calm overall: it covers big areas.
- Seamless, the outer 12 px (3 game px) the same in A, B and C.
- The converter now checks a detail range (5–16%) and lone pixels (under 3%).

### 2. Small animated sprites for the water (each frame its own PNG, transparent around)

The game draws its own placeholders now; yours replace them and the game scatters and animates them.
Paint them at 4× like everything else.

| Sprite | About (game px) | Frames | What |
|---|---|---|---|
| `glint_0..3` | 5×5 | 4 | a sun sparkle: a dot, a little cross, a star, back to a dot (#ffe2a8, #f6c08f, white heart) |
| `crest_0..3` | 10×3 | 4 | a short wave crest rising and sinking (lit top #f6c08f, shade below #ce7d7a) |
| `splash_0..3` | 12×8 | 4 | a small foam splash for the boat hitting buoys and the beach (#fff6ea, #fce2ca) |
| `ripple_0..3` | 16×8 | 4 | a ring of ripples spreading round a buoy or a rock, fading out |

### 3. Later in the round (no rush)

`island_a`, `island_c`, `island_d`, `palm_b`, a couple of rocks (`rock_a`, `rock_b`, about 14×10 and
22×14, with a ring of foam the game adds), and decor variants (`starfish_b`, `shell_b`...). Keep the
seagrass and decor in the warm palette (the seagrass's teal can stay a little greener).

## Delivery

4× paintings in `docs/mockups/rcprix_lagoon/round1c_paint/` (for example `sand_a_4x.png`,
`glint_0_4x.png`). We convert them, put them in the game and send phone screenshots. First the sand
(A) and the glint and crest frames.
