# RC Prix · Garden: notes for round 22 (corner barriers, painted over the guides)

The last round for the barriers. **We fixed the layout; you paint the look.**

## The look: samples A and B

- **B, toy barrier blocks** (`round18_samples/tyres_ne_option_b.png`, and your glossy brick study): chunky
  straight bricks with a light top, a tall red or white front, darker ends, a shine on the top-left and a
  thick dark outline. Red, white, red…
- **A, tidy tyre row** (`round18_samples/tyres_ne_option_a.png`, and your glossy tyre study): round
  doughnut tyres with a thick wall, a dark hole and a white shine on the top-left, in **blue and yellow**.

Paint them exactly in that style: crisp pixel art, chunky, glossy, clean outlines.

## The layout: `round22_paint_guides/` (fixed, don't change it)

There's one guide per game file: `<name>_guide_4x.png`, 1232×1232, four times the game's size. Each shows:
- **the real road**: the corner, and the straights it runs into;
- **every piece at half strength:** where it goes, its size and angle, and which walls show;
- **the square** (white) and **the run-on strips** (yellow);
- **four pink corner marks.**

The layout already follows every rule:
- the barrier walls the whole curve, snug to the road;
- it runs on into the straights, where the car bounces;
- perspective: the outer wall shows below the road, the inner wall above it, the ends where it runs up
  and down the screen;
- light from the top left;
- nothing cut.

**Paint over each guide:**
- **One piece on each ghost piece:** same place, same size, same angle, same visible walls. Don't add,
  remove, move or resize any.
- **Every piece whole** inside its white square or yellow strip. No piece crosses a line.
- **Nearer pieces cover farther ones,** as in the guide.
- **Then remove the road and the grass:** transparent around the barrier. Keep the four pink marks
  exactly where they are, so we can line your picture up.
- **Every corner painted on its own.** The views differ, so never mirror or rotate a corner.

## Delivery

Deliver 16 pictures, `<name>_paint_4x.png`, 1232×1232, transparent except the barrier and the pink marks,
into `docs/mockups/rcprix_garden/round22_paint/`. If your tool can't keep the exact size, keep the pink
marks: we line the picture up by them.

We bring them down onto the game's pixel grid (one game pixel per 4×4 block) and check them in the game.
So **paint on a clean 4×4 grid** (every colour block 4×4 px, the outline 4 px) and the result will be your
picture exactly.

**Look sample first:** `tyres_ne` and `tyres_se_alt`, next to samples A and B.

## After the look sample (2026-10-27)

**The look is approved.** The blocks are right. The tyres need **a visible side wall**: a band of darker
colour below each ring, as in the glossy tyre study, so they stand up instead of lying flat.

**The guides were remade:** the barriers now follow the road's real edge at every angle. Before, on the
near corners (`ne`, `nw`), they stood off the curb where the curve runs up and down the screen.
- **`tyres_ne`:** repaint it on its new guide; about 61% of it still lines up.
- **`tyres_se_alt`:** about 94% still lines up. Nudge the tyres onto the new ghosts and add the side wall.
- **The other 14:** paint them on the new guides.
