# RC Prix · Garden: notes for round 11 (the spectator stand and the flags)

Send after round 10 (or alongside it, if that's easier for the designer).

`round11_stand_now.png` shows today's stand. The game draws it as plain wooden steps with a
red-and-white awning, and the little flags as flat coloured rectangles on sticks. Both need a real
design.

## How the stand works (don't change this)

- The stand sits beside the finish line, facing the track. Depending on the course its **back**
  is toward the top, bottom, left or right of the screen.
- Its depth is always 68 px: **five seat rows of 12 px each, plus the 8 px awning at the back**.
  Its length changes with the course (100, 130, 170 or 220 px). That's why it comes in pieces: two
  ends and a middle that the game repeats.
- **The game draws the audience** (the pals, hopping and cheering) on the seat rows. Draw an empty
  stand only: seats, steps, awning, structure.
- The game shows the stand and its audience in slightly softer colours (the "SOFT" look). Keep
  drawing at your normal colours.

## What to draw

**The stand**, in the same style as the road and tyres: flat tones, light from the top left,
outline `#281E28`.
- A proper little grandstand: five stepped rows of benches, each row a bit lighter than the one in
  front (higher, nearer the light), with a clear front lip on each step.
- A striped awning or roof edge along the back, with a scalloped or flag-bunting edge toward the
  seats. Garden colours are welcome (for example green and cream, or the curbs' red and white).
- Side ends with a frame, a railing or posts, maybe a small sign or banner on the front.
- The middle piece must **repeat seamlessly** end to end (its left edge continues its right edge).

**The flags**, waved by some of the audience:
- `flag_0.png` and `flag_1.png`: one flag on a stick in two waving frames, the game alternates
  them. Draw the flag cloth **white or light grey** with shading and an outline. The game tints it
  in four colours, so one drawing makes them all.
- A triangular pennant or a small chequered race flag, with a clear stick and a waving shape.

## Files

| Files | Size | What |
|---|---|---|
| `stand_n_end_a`, `stand_n_mid`, `stand_n_end_b` | 20×68, 40×68, 20×68 | back at the top (seats face down) |
| `stand_s_end_a`, `stand_s_mid`, `stand_s_end_b` | 20×68, 40×68, 20×68 | back at the bottom |
| `stand_w_end_a`, `stand_w_mid`, `stand_w_end_b` | 68×20, 68×40, 68×20 | back at the left |
| `stand_e_end_a`, `stand_e_mid`, `stand_e_end_b` | 68×20, 68×40, 68×20 | back at the right |
| `flag_0`, `flag_1` | 12×20 | the flag, two frames |

`end_a` is the left end (or top end, for the side stands) and `end_b` the right (or bottom) end. The
boxes are in `templates/4_sprites.png`.

## How to work

1. **A look sample first:** `stand_n_end_a`, `stand_n_mid`, `stand_n_end_b` and both flags. We try
   them in the game before the other three directions.
2. What you show us is what you deliver: real PNGs on the final grid.
3. Then the other three directions.

## Test before handing over

1. A 3× picture made **from the delivered PNGs**: the stand assembled at 220 px long (end, mids,
   end) next to the road.
2. `python3 tools/art/check_rcprix_art.py`: 0 problems.
