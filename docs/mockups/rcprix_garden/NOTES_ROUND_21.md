# RC Prix · Garden: notes for round 21 (corner barriers round the whole curve)

This replaces round 20's layout. Round 20's look and perspective rules still apply.

## What changed

The barriers must wall **the whole curve**, as the old game did. The car bounces off them along the
whole curve and a little way into each straight. Round 20 covered only the middle of each corner, with
grass gaps at both ends.

The new block-out (`tools/art/rcprix_barrier_blockout.py`) is already in the game, on every level that
has barriers (1–5 and 9):
- **The whole 90°** of each curve, snug against the road. On the near side the barrier stands in front
  of the raised road, so its top covers the foot of the road's orange side face; that's intended.
- **One more piece past each end** (one block, or two tyres), running into the next square. The game
  shows these only where the next square is a straight.
- **Perspective:**
  - below the road you see the barrier's **outer wall**;
  - above the road you see the **inner wall**, the side facing the road;
  - where the barrier runs up and down the screen, the blocks show their **ends**.
- **The small gap** where a run-on continues up or down the screen is right: the next piece's top is
  drawn upward. Keep it.

See `round21_barrier_blockout_3x.png` (each corner with the straights it runs into) and
`round21_barrier_blockout/` (one PNG per game file).

## Files: 16, now **308×308**

Each file is the corner square (180×180) with a **64 px margin** all round, the square at (64, 64).
- **The curve stays inside the square.**
- **Each run-on stays inside the margin strip beside its end:**

| Corner | Run-on strips |
|---|---|
| `ne` | top and right |
| `nw` | top and left |
| `se` | bottom and right |
| `sw` | bottom and left |

- **The margin's four corners stay empty.**

| Style | Files |
|---|---|
| Blocks, red/white | `tyres_ne`, `tyres_nw`, `tyres_se`, `tyres_sw`, and the same four `_wide` |
| Tyres, blue/yellow | `tyres_ne_alt`, `tyres_nw_alt`, `tyres_se_alt`, `tyres_sw_alt`, and the same four `_wide` |

## The look (from your round 20 sample, two fixes)

Paint over the block-out:
- **Keep every silhouette:** the position, size, top face and visible walls of every piece.
- **Change only the surface,** into your glossy studies' style.

Your round 20 sample had the colours and outline right. Two things to bring closer to the studies:
- **Blocks:** rounded, bevelled corners, and a **bright shine strip** along each block's top (the
  studies' gloss). Yours were flatter.
- **Tyres:** a **rounded doughnut** top with a smaller hole and a thinner side wall, as in the study.
  Yours read as tall cans with big holes.

Same rules as before:
- light from the top left on every corner;
- each corner painted on its own, never mirrored or rotated;
- nearer pieces cover farther ones as in the block-out;
- nothing on the road or curb (covering the foot of the orange side face is fine).

## How to work

1. **Look sample first:** `tyres_ne` and `tyres_se`, and the same two `_alt`. Show them at 3× with the
   straights they run into, made from the delivered PNGs (the script's contact sheet code, pointed at
   `textures/minigames/rcprix/garden/`), next to your studies.
2. Then the other 12.
3. **The PNGs you deliver must be the pictures you show.**

## Test

`check_rcprix_art.py` at 0 problems (it now expects 308×308 for `tyres_*`).
