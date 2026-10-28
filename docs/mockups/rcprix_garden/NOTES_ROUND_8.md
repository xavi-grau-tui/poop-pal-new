# RC Prix · Garden: notes for round 8 (back to the round-6 sketches, only bigger)

## The decision

Round 7 (tree canopy cut into bush shapes) is **not approved**: the bushes look like pieces of the
tree, not like bushes designed on their own, and not like solid pixel art. **Don't use tree pixels.**

The designs we want are your **round-6 sketches**, the ones you showed in your app
(`round6_sources/bush_*_tone_study.png`): each bush drawn individually, solid, with leafy rosettes.
They had only one problem: drawn at their own pixel size, their leaves are smaller than the tree's.
**This round only makes them bigger.** Same drawings, same rosettes, same shapes.

## The guides

`round8_guides/bush_a_guide.png` … `bush_g_guide.png` are the sketches already enlarged to the final
size, so the leaves match the tree's (see `round8_guides_3x.png`: sketch on top, guide below).
A–D are enlarged 1.7×.

The guides are made by plain enlargement, so their pixels are uneven (some 1 px, some 2 px wide).
**Redraw each one by hand on top of its guide:**

- Keep every rosette where it is, at the guide's size and shape.
- Clean pixels: a 1 px `#251a24` outline that bumps around each rosette, 1 px leaf tips, and no
  2×2 doubled pixels or stair-steps left over from the enlargement.
- The tree's six colours only (`#251a24`, `#1a4131`, `#2b6639`, `#31723b`, `#5fb138`, `#97d53a`),
  with each rosette's light patch and highlight tip at the top left, like the sketch.
- **No scripts that repaint, snap or cut.** The PNG you show us is the PNG in the game.

## The small bushes E, F, G

Shrinking the sketches E–G into their small boxes makes their leaves tiny again, so their guides
only give the outline. Redraw them as **4–6 tree-sized rosettes** (each about 10–12 px across)
filling that outline: fewer leaves, not smaller ones.

## Sizes (templates updated)

| File | Size |
|---|---|
| `bush_a.png` | 96×82 |
| `bush_b.png` | 172×67 |
| `bush_c.png` | 102×77 |
| `bush_d.png` | 106×102 |
| `bush_e.png` | 44×38 |
| `bush_f.png` | 38×32 |
| `bush_g.png` | 48×36 |

## Test before handing over

1. A 4× picture made **from the delivered PNGs**: each bush next to its round-6 sketch and next to
   the tree. It must look like the same drawing as the sketch, with leaves the size of the tree's.
2. `python3 tools/art/check_rcprix_art.py`: 81/81 files, 0 problems.
