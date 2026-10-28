# RC Prix · Garden: notes for round 5 (bushes at the tree's density)

We loved your round-4 **sketches** (`round4_sources/bush_a_study.png` … `bush_d_study.png`) and
tried them in the game at their own pixel size: the shapes are exactly what we want. **Keep these
four designs.** The bushes cut from the tree are not needed.

## The one problem

At that size the sketches are still a little finer than the tree: their leaf clusters are smaller.
See `round5_tree_vs_bushes_4x.png` (tree on the left, sketches A and D on the right, at 4×).

- The tree's leaf clusters are about **10–12 px** across.
- A's are about 20% smaller; B, C and D's about 30–35% smaller (D's clusters are about 6 px).

## What to draw

1. **The same four bushes, redrawn with the tree's leaf size.** Same silhouette, same outline
   size as now, but with **bigger, fewer leaf clusters** (each about 10–12 px, like the tree's),
   so the pixels look exactly as big as the tree's. Same palette, top-left light, dark outline.
2. **Three new small bushes** in the same style and the same leaf size: each one only 2–3 leaf
   clusters (for example a single lobe of one of the big bushes). The game mixes them with the big
   ones.
3. **Never shrink a whole picture down.** Draw at the final size, or if you start from a generated
   picture, one of its pixel blocks must become exactly one game pixel and its clusters must already
   be 10–12 blocks across.

| File | Size | What |
|---|---|---|
| `bush_a.png` | 90×76 | the round, three-lobe sketch A |
| `bush_b.png` | 108×46 | the wide, low sketch B |
| `bush_c.png` | 86×64 | the uneven sketch C |
| `bush_d.png` | 94×80 | the tall sketch D |
| `bush_e.png` | 44×38 | new small bush |
| `bush_f.png` | 38×32 | new small bush |
| `bush_g.png` | 48×36 | new small bush, low |

The boxes are in `templates/4_sprites.png` (updated). These replace the round-4 bushes.

## Test before handing over

1. A picture of all seven bushes next to the tree at 4×, like `round5_tree_vs_bushes_4x.png`. The
   leaf clusters must look the same size as the tree's.
2. `python3 tools/art/check_rcprix_art.py`: 81/81 files, 0 problems.
3. `python3 tools/art/rcprix_preview.py`.
