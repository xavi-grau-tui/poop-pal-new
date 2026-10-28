# RC Prix · Sky, round 1: the style, the rings, the drone pad, the stand on its cloud

RC Prix's third world, the Sky (levels 19–27): a toy plane flying a course through **rings** high above
the countryside **at noon**. The Garden and the Lagoon are finished in your art
(`reference/garden_quality_bar_*.png`, `reference/lagoon_finished.png`); the Sky should reach the **same
quality**, keeping its own airy mood.

`current/` shows the Sky as it is today (`start_l19.png`: the start pad and the stand on a cloud;
`g0_l*.png`: racing).

## What the user loves and wants kept

- **The ground far below:** a patchwork of fields seen from very high, **pale and hazy** so it reads as
  far away, with soft cloud shadows drifting over it. Redo it at our quality, but **the same feeling**.
- **The see-through clouds** drifting between the plane and the ground: redo them, still **transparent**.
- **The wind:** the light streaks rushing past the plane and turning with it. That stays a game effect
  (we redraw it at the new pixel size); nothing to paint.

The plane and its behaviour stay as they are.

## Pixel density: the same as the Garden and the Lagoon

**One game pixel = 2 world px.** `reference/pixel_density.png` shows it. Today's Sky is twice as chunky
(each of its pixels is 2×2 of yours): copy its mood, not its pixel size. Paint at **4×** (one game pixel
= one 4×4 block, hard edges), never big-and-shrunk. The phone shows **299×277 game px** of the course.
Light from the **top left**, as everywhere.

## 1. Style pictures first (2 or 3 options)

On `guides/style_canvas_4x.png` (299×277 game px at 4×): one phone screen of the Sky at the new quality,
the way it would look mid-race, with:

- the ground far below: fields, hedges and tree lines between them, a river, a farm or a village;
  **pale and hazy**;
- cloud shadows on the fields and two or three see-through clouds drifting over them;
- one ring (see 2), part of the stand on its cloud (see 4), and the plane (any size-correct stand-in);
- **something new, if you like:** a flock of birds flying lower down (5–9 small birds in a loose V, their
  shadows on the ground), a windmill turning, a little train or tractor crossing the fields.

Make each option a different take, for example: **A** close to today (a soft pastel quilt, light haze);
**B** a richer countryside (orchards, lanes, farmhouses, ponds), stronger haze; **C** your own idea. The
user picks one; then we send the guides for the ground's pieces.

## 2. The rings (over our guides)

The plane flies **through** each ring. A ring is a round tube standing across the course, seen from above
at an angle, so it shows as an ellipse. Rings only sit on straight stretches, so they face just two ways:

- a course going **up or down** the screen sees the **wide** ring: you paint this one;
- a course going **sideways** sees the **tall** one: the game makes it by flipping yours over its
  diagonal, which keeps the light top left (`guides/ring_both_ways_preview.png`, with the plane for scale).

The game cuts each ring along the ink line across its middle: one half is drawn over the plane, the
other under it, so it really flies through. Don't put a single small detail (a lamp) right on that line.

**Paint over** `guides/ring_124_guide_4x.png`, `ring_112`, `ring_100` and `ring_88` (the four sizes the
levels use). The pale band is the tube (14 game px thick, outline included). The darker line in its
middle is where it counts as flown through: keep the tube centred on it.

- **The look:** today's candy red and white bands are a good start (they match the Lagoon's buoys).
  Make it a proper toy hoop at the Garden's detail: a round shine along the tube, its bands, a soft
  outline. Small extras are welcome (a little lamp or pennant at the top).
- **The next ring glows gold** in the game (it pulses, with sparkles running round it, drawn by us).
  Paint the gold version **once**, at size 124. We recolour the other sizes the same way, and make the
  grey of a missed ring ourselves.
- Deliver `ring_124_4x.png` … `ring_88_4x.png` and `ring_gold_124_4x.png`.

## 3. The drone pad: where the race starts (over our guides)

The plane starts from a pad floating in the sky, held up by **four drone rotors at its corners**.
Today's (`current/start_l19.png`) has the right idea: a sturdy steel deck, a red and white striped rim
like the Garden's curbs, landing lights, a rotor on an arm at each corner.

- **The deck:** paint over `guides/pad_east_guide_4x.png` (104×94 game px, for a course going sideways)
  and `pad_north_guide_4x.png` (94×104, for a course going up or down), each with its side face
  underneath (10 game px). Keep the deck **without a direction**: the same picture is used whichever way
  the race goes.
- **The start line:** the pale band on the guides is where it goes. Paint it as its own strip, a
  checkered line across the deck: `pad_line_v` (12×94) and `pad_line_h` (94×12). The game places it.
- **The rotors, as pieces** (the game spins them): the arm for the top-left corner (`rotor_arm`, about
  12×12; we mirror it for the others), the motor (`rotor_hub`, about 8×8), the guard ring round the
  blades (`rotor_ring`, 34×20, an ellipse like the guide's), the spinning blades in **4 frames**
  (`rotor_blades_0..3`, 32×18) and a faint blur disc (`rotor_blur`, 32×18).
- **Landing lights:** `light_on` and `light_off` (about 4×4). The game blinks them along the rim.
- **Colours:** your call. Painted steel and the striped rim work; a light blue and white touch to
  match the stand's canopy (see 4) is welcome.

## 4. The stand on its cloud (over our guides)

The pals watch from a **stand sitting on a cloud**. We reuse the Garden's stand with its canopy
turned **light blue** (already done by the game, see the guides). What we need from you is **the cloud
it sits on**: big, soft, lit from the top left, puffing out round the stand's foot.

- Paint over `guides/stand_cloud_front_guide_4x.png`, `_back`, `_side_l` and `_side_r` (the stand in
  each of its views). The pale band shows roughly where the cloud goes; go past it where the puffs want to.
- Two layers per view: **`under`** (the cloud behind and below the stand) and **`over`** (a few puffs in
  front of its feet, so it sits **in** the cloud, not on top of a flat shape). Deliver them as two files:
  `stand_cloud_front_under_4x.png`, `stand_cloud_front_over_4x.png`, and so on.
- The pink ticks on the edge mark where the stand's pieces meet (end, middle, middle, end). The game
  cuts the cloud there and repeats the middle for longer stands, so **the two middle sections must be
  the same** (paint one, copy it onto the other) and join seamlessly.
- The cloud is solid (not see-through, unlike the drifting ones): the pals sit on it.

## Later (so you see the whole Sky)

After the style pick, with guides from us:

- **the ground's pieces:** seamless field squares in several crops, hedges and tree lines, the river,
  farms and villages as decor; the game lays the patchwork and adds the haze and cloud shadows, as the
  Lagoon's water;
- **the drifting clouds:** 3 sizes, 2 shapes each, solid white with their shading (the game makes
  them see-through and drifts them);
- **the birds** (or whichever new idea the user likes), in a few frames;
- **the hot-air balloons** (obstacles in levels 25–27) at the new detail, keeping their shape and colours.

## Delivery

Into `docs/mockups/rcprix_sky/round1_paint/`. **The style pictures first**, then 2, 3 and 4 in any
order. Each group goes into the game as soon as it arrives, and we send phone screenshots back.
