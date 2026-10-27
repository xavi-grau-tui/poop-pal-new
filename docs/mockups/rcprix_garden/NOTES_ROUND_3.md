# RC Prix · Garden: notes for round 3 (bushes and grass seams)

We played the quality set in the game, and the courses work well. We now go **bit by bit**. This
round is only two things: the bushes and the grass seams. The road comes in a later round.

- **Approved, don't change:** the trees (perfect), the flowers, the grass's look.
- **Not needed any more:** the car. The game uses its original car; leave the `car_slice_*` files.
- **Shadows are done by the game** (trees, track, bushes, flowers): never draw them on the ground.

## 1. Bushes: the same pixel density as the trees

The trees are right. The bushes look denser and "too defined" because they're a whole bush shrunk
into a small box: their leaves are 2–3 px across, while the trees' leaf clusters are about 8–12 px.

- **The bushes' leaves must be the same size in pixels as the trees' leaves.** Same leaf shapes,
  palette, lighting from the top left and outline as the trees. A bush is a few of the trees'
  leaf clusters grouped together, not a tree made smaller.
- **Never shrink a whole picture down.** Make the bush at the trees' scale. If you start from the
  tree's source, use the same scale factor as for the trees.
- **The boxes are bigger now** to fit tree-sized leaves: `bush_a` 60×52, `bush_b` 46×40
  (templates updated). A bush is about 4–6 leaf clusters.

Test: put a bush next to a tree in one picture at 3×. They should look drawn with the same brush.

## 2. Grass: no lines where squares meet

In the game, faint straight lines show where grass squares meet. We measured two causes:

1. **The edges are smoothed out.** In each square, the 2–3 px along every edge have about half
   the texture of the inside, so a calmer strip runs along every seam.
2. **A, B and C have different edges.** Where two different squares meet, their patches are cut
   off in a straight line.

The fix, the standard way to make tile variants:

1. **Make grass A truly seamless**, without blending the edges. Paint it, then shift it by half
   a square (90 px) both ways so the seams cross in the middle, and repaint that cross by hand so
   the patches carry on. Shift back. Its edges then join itself with no strip at all.
2. **Make B and C from A, changing only the inside.** Keep a border band of about 16 px on all
   four sides **exactly the same as A's**. Vary the patches, tufts and flowers only inside it.
   Then any square joins any other exactly as A joins itself, so no lines in any combination.
3. **Keep the texture strength the same everywhere**, edges included: no calmer or blurrier strip.

Test: `python3 tools/art/rcprix_preview.py` lays a big board with A, B and C mixed. Look at it at
2× (`course_preview_2x.png`); you shouldn't be able to see where any square ends.

## Delivery

`grass_a.png`, `grass_b.png`, `grass_c.png`, `bush_a.png` (60×52) and `bush_b.png` (46×40) in
`textures/minigames/rcprix/garden/`. Run `python3 tools/art/check_rcprix_art.py` (76/76, 0 problems)
and send the course preview pictures plus one picture of a bush next to a tree at 3×.

## Later: the road

For the round after this one: the road and its overlays look too defined and don't read as the
same pixel art as the grass and trees (speckle, too many colours, finer detail). We'll send its
notes then.
