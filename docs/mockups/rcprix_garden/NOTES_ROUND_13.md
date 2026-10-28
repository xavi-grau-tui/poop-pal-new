# RC Prix · Garden: notes for round 13 (the stand, done properly)

## The reference

**Your stand picture is the approved design:** `round11_stand_imagegen_reference.png`. Benches on posts,
the scalloped green-and-cream awning, the angled wooden side frames. **This is the design we want,
not something similar:** the same benches, posts, awning and frames, only redrawn at the game's size
and seen from each side.

The game currently shows a conversion of that picture. It's too small, and the course's other side
shows it flipped, so it looks upside down. This round fixes both.

## Three changes

1. **Bigger.** The stand is now 96 px deep instead of 68: five bench rows of about 15 px plus an
   18 px awning. Pieces: ends 28 px, middle 56 px long.
2. **The same pixel size as the road, trees and tyres.** Draw on the final grid at that size: a
   1 px `#281E28` outline, planks 3–4 px thick with a 1 px light top edge, posts 3–4 px wide,
   awning stripes about 7 px wide, clusters of at least 2×2 px, light from the top left. **Don't
   shrink the big picture.** That's what made today's stand fine and blurry. Redraw it at size.
3. **Three views, each in two layers.** The stand can sit above, below or beside the track, and the
   game draws the cheering pals **between** the two layers:
   - **front** (the stand above the track, seats facing you):
     - `under`: the benches, posts and side frames;
     - `over`: **the awning**, so the top row of pals sits half under it.
   - **back** (the stand below the track, its back toward you): **no back wall.** It's an open
     frame, so the audience shows through the gaps between the benches and posts.
     - `under`: the benches and the frame seen from behind;
     - `over`: only what is nearest to you (the rear posts, the open frame's rear beams, the awning's
       back edge), transparent everywhere else so the pals show through the gaps.
   - **side** (the stand beside the track; draw the right-hand side, the game mirrors it for the
     left):
     - `under`: the rows stepping up, seen side-on;
     - `over`: the near side frame and the edge of the awning.

   The `over` layer must be transparent wherever the pals should show.

## Roof flags

A pennant on a short pole, in **3 waving frames** (`stand_flag_0/1/2`). Draw the cloth white or light
grey with shading; the game tints it and places a few along the awning, each waving out of step.

## Files (boxes in `templates/4_sprites.png`)

| Files | Size |
|---|---|
| `stand_front_under_end_a`, `_mid`, `_end_b` | 28×96, 56×96, 28×96 |
| `stand_front_over_end_a`, `_mid`, `_end_b` | 28×96, 56×96, 28×96 |
| `stand_back_under_*`, `stand_back_over_*` | the same sizes |
| `stand_side_under_*`, `stand_side_over_*` | 96×28, 96×56, 96×28 (the stand runs up/down) |
| `stand_flag_0`, `_1`, `_2` | 12×24 |

Each `mid` must repeat seamlessly end to end. For the side view, `end_a` is the top end and
`end_b` the bottom end. The old `stand_n/s/w/e_*` files go.

## How to work

1. **Look sample first:** the front view's two layers and the three flag frames.
2. **What you deliver is what you show.** The game PNGs must be the picture you show us. If your
   tool can't make them at the exact size, send that picture and we'll convert it.
3. Then the back and side views.

## Test

A 3× picture of the front view assembled at its longest (end, 4 mids, end) with both layers, made
from the delivered PNGs and next to the road and a tree. Then `check_rcprix_art.py`.
