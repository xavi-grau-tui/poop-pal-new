# RC Prix · Garden: notes for round 20 (corner barriers in perspective)

## The look

**Your two imagegen studies are the approved look** (the user, 2026-10-27):
- **Blocks:** glossy, rounded red and white bricks, thick dark outline, a bright shine on the top-left of
  each, the side wall a darker shade.
- **Tyres:** chunky blue and yellow tyres with a rounded top, a dark hole, a white shine on the top
  left and a thick side wall.

Paint the game files in exactly that style. Keep it as glossy and chunky as in the studies: no flat
fills, no thinner outlines, no smaller pieces.

## Where and how each piece stands: `round20_barrier_blockout/`

The studies all show one view. In the game, the view changes around each curve because the camera looks
from the bottom of the screen:
- **The near part of a curve** (the barrier below the road) shows the barrier's **outer wall**.
- **The far part** (the barrier above the road) shows its **inner wall**, the side facing the road.
- **Where the curve runs up and down,** the blocks show their **ends**.

The block-out (`tools/art/rcprix_barrier_blockout.py`) works this out for every piece of every corner:
its footprint, its top, which walls show, and which piece covers which. See
`round20_barrier_blockout_3x.png`.

**Paint over the block-out:**
- **Keep every silhouette:** each piece's position, size, top face and visible walls.
- **Change only the surface,** into the studies' style: shine, rounded edges, shading, outline.

Rules:
- **Blocks:** 5 per corner, end to end along the curve with a 2 px gap. Red, white, red, white, red.
- **Tyres:** 6 per corner, just touching. Blue, yellow, blue…
- **Light from the top left on every corner.** Each corner shows different walls, so paint each one on
  its own; never mirror or rotate one corner into another.
- **Nearer pieces cover farther ones,** as in the block-out. Don't overlap pieces any other way.
- Nothing on the road, the curb or its orange side face. Nothing within 4 px of the square's edge.

## Files (16, 180×180, transparent around the barrier)

| Style | Files |
|---|---|
| Blocks, red/white | `tyres_ne`, `tyres_nw`, `tyres_se`, `tyres_sw`, and the same four `_wide` |
| Tyres, blue/yellow | `tyres_ne_alt`, `tyres_nw_alt`, `tyres_se_alt`, `tyres_sw_alt`, and the same four `_wide` |

Deliver them into `textures/minigames/rcprix/garden/`, under the same names as the block-out files.

## How to work

1. **Look sample first:** `tyres_ne` (near side) and `tyres_se` (far side), and the same two `_alt`.
   Show them at 3× on their road pieces next to your studies, made from the delivered PNGs.
2. Then the other 12.
3. **The PNGs you deliver must be the pictures you show.** If your tool can't make them exactly, send
   the pictures and we convert them.

## Test

`round20_barrier_blockout_3x.png` remade with your files in place of the block-out (the script's sheet
code, pointed at `textures/minigames/rcprix/garden/`), and `check_rcprix_art.py` at 0 problems.
