# RC Prix · Garden: notes for round 4 (bushes)

Round 3's grass is approved: the seams are gone. This round is **only the bushes**.

## The problem

The bushes still look denser than the trees, as if they were farther from the camera. We measured
why: each bush was painted as a big picture and shrunk 20–25 times, while the tree was shrunk only
about 8 times. So every leaf and detail in a bush is 2.5–3 times smaller than in the tree.

To show the look we want, the game currently doubles your bushes. On the phone that matches the
trees, but the bushes come out too big. We want **that density at a normal bush size**.

## What to draw

- **Leaves the same pixel size as the tree's.** A bush is 2–4 leaf clusters, each about the size
  of one of the tree's leaf clusters (about 8–12 px across), with the same shapes, palette, light
  from the top left and dark outline.
- **Never shrink a whole picture down.** If you start from a generated picture, scale it by the
  same factor as the tree (about 8 source px per game px), or draw the clusters directly at size.
- **Four different bushes** instead of two, so the same bush doesn't show twice on screen. Make
  them clearly different in shape and size: round, wide and low, small, tall-ish.

| File | Size |
|---|---|
| `bush_a.png` | 60×52 |
| `bush_b.png` | 46×40 |
| `bush_c.png` | 54×46 (new) |
| `bush_d.png` | 40×34 (new) |

The boxes are in `templates/4_sprites.png`. The game keeps each bush well apart from another of
the same kind.

## Test before handing over

1. A picture of all four bushes next to the tree at 3×. The leaves must look the same size.
2. `python3 tools/art/check_rcprix_art.py`: 78/78 files, 0 problems.
3. `python3 tools/art/rcprix_preview.py`.
