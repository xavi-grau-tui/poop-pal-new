# RC Prix · Garden: notes for round 3 (road and bushes)

We played the quality set in the game. Thank you: the courses work well.

- **Approved, keep as they are:** grass A/B/C, the flowers, the trees. One fix in the grass: in
  the game, faint straight lines show where grass squares meet (the edge reconciliation leaves a
  visible strip). The pattern must carry on across every edge with no straight line, in any
  combination of A, B and C next to each other. Check it on a big board in `course_preview.png`.
- **Not needed any more: the car.** The game now uses its original car, redrawn at the new detail
  in code. Leave the `car_slice_*` files as they are.
- **Shadows and light are now done by the game:** the trees' shade, the track's shadow, the
  bushes' and flowers' shadows. Don't draw shadows on the ground.

## What's wrong with the road and the bushes

They look **too defined and don't read as the same pixel art** as the grass and the trees. They were
sampled pixel by pixel from painted, generated sources, which leaves:

- single-pixel speckle everywhere (the asphalt grain, the bush leaves);
- many slightly different colours where pixel art would use a few clear tones;
- detail finer than the grass and trees around them, so they look like a different style.

## The rules for this round

1. **Few clear tones per material:**
   - asphalt: 3 greys, plus 1 lighter grey for the worn centre band;
   - curbs: red and white, 3 tones each (light top, mid, dark lower edge);
   - side face: 3 oranges;
   - bushes: 4 greens, like the trees.

   No other in-between colours.
2. **No single stray pixels.** Texture is made of small clusters of at least 2×2 pixels, placed
   sparsely and evenly, never noise.
3. **The same pixel scale as the grass and trees.** Look at the approved trees: their leaf
   clusters and their outline are the standard. The road and bushes should look drawn by the same
   hand.
4. **Draw it, don't sample it.** Keep the script for the exact shapes (masks, joins, stripe
   positions), but paint the shading with a limited palette instead of sampling a painted image.

## The pieces

- **Road (both widths, all pieces and overlays):**
  - asphalt calm and even: the 3 greys in soft, large areas (darker shoulders, lighter worn centre
    band), plus sparse 2×2 grain;
  - curbs keep the raised look, with clean blocks and crisp edges, and the 3 tones each;
  - the side face keeps its depth with 3 oranges.

  Overlays (start line, boost pads, ramps, tyre walls) follow the same rules.
- **Bushes A and B:** the trees' style and palette at small size: a few leaf clusters, 4 greens,
  the same outline as the trees. Calmer than now, so they don't compete with the car.

Everything the game depends on stays exactly as it is: sizes, names, road masks, joins, overlay
positions.

## Order and checks

1. First a sample: one straight, one corner and bush A. Wait for approval.
2. Then all road pieces and overlays in both widths, and bush B.
3. Before handing over: `check_rcprix_art.py` 76/76, 0 problems, plus the `rcprix_preview.py`
   pictures (and `--wide`).
