# The 120 spirits, round 3: concept A, all realms (brief for the designer, 2026-11-04)

**Concept A (Hyakki Parade) is the direction.** In the shrine it looks like a cartoon, which is what
we want (`docs/mockups/spirits/round2_review/in_home_vs_old.png`). Concepts B and C stop here.

All of `docs/kami_spirits_brief_round2.md` still applies: the 56 x 56 canvas, the sizes, the detail
budget, the three tests, the realms and the evolution branches. **Keep A's look exactly as it is**:
the flat cartoon colours, the outline, the simple shapes, the cartoon poses. This round fixes a few
things in the Fire realm, then makes the other four realms in the same style.

## 1. Fix the Fire realm (`round2/concept_a/` -> `round3/`)

Change only what's listed here. Spirits not named stay pixel-for-pixel as they are.

**a. The balls: each one its own.** Right now the 24 balls are the same circle with the same face
and a half-light, half-dark split; only the colour changes (`round2/concept_a/fire_balls.png`). A
ball must show who it is:
- **Its own face:**
  - the one-eyed spirits keep one eye (Wobble Wish, Grand Wish-Doll, Beckon Cat, Peppercake Oni)
  - sleepy spirits stay sleepy, grumpy ones stay grumpy
- **Its signature on the ball:**
  - spots: Soot Dot, Lantern Beetle, Fortune Shell
  - ears: Beckon Cat
  - the husk's ribs: Husk Lantern
  - the curled tail as a swirl: Cinder Newt, Patchtongue
  - horns: Clock Oni
  - the crown plume: Ashwing Crown
  - the jar lid: Jarling
  - the wrap's tie: Wrap Walker
- **Its own colour areas** (a face patch, a belly, a cap), not the generic half-and-half split.
- **No two balls alike** in a realm. The test: cover the names, and you can still tell all 24 apart.

**b. More face variety.** Several Fire spirits share the cream face patch with two dot eyes.
Keep that face for **at most a quarter of each realm**. Give the others their own, for example:
- one big eye (you already do this well)
- sleepy or half-closed eyes
- a mask with eye holes
- side-eye
- a wide grin
- eyes on a hood or a lid
- an eyeless face with a glowing mark

Each must still blink or glow for the animation.

**c. Not all red.** Seen together, the Fire realm is nearly all one red. Keep red as the realm's
colour, but give a third of it its other materials: soot black, lantern-paper cream, ember orange,
gold.

**d. Babies a little chunkier.** In the shrine the babies look small next to the old pals (Hibiko is
23 px wide, the old Ember 35). Keep the height (about 30) and make them about **28 to 32 wide**.
Redo their 5 poses and layers to match.

## 2. The other four realms, in concept A

Mountain, Moon, Fox and River: all 24 slots each, from `docs/kami_spirits_tree.md`, with the same
rules and the fixes above built in (own balls, varied faces, colour range within the realm).

| Realm | Its palette and materials | Spirits in it |
|---|---|---|
| Mountain | moss, bark, stone, crow black | kodama, tengu, mushroom spirits, kappa |
| Moon | indigo, cream, silver | moon rabbit, baku, mochi spirits |
| Fox | vermilion, gold, fried-tofu tan | kitsune, tanuki, festival-stall spirits |
| River | blue-grey, rain, frog green | frogs, umbrellas, teru teru bozu |

Each realm must look like its own world next to the others, not Fire recoloured.

## What to deliver

Folder `docs/mockups/spirits/round3/` (don't overwrite round 2):
- `<id>.png` (56 x 56) and `<id>_ball.png` (24 x 24) for all 120
- `names.csv` for all 120, with the round 2 columns
- per realm:
  - `<realm>_sheet.png` (4x, the tree layout, with names)
  - `<realm>_sheet_1x.png`
  - `<realm>_balls.png`
  - `<realm>_silhouettes.png`
- `all_realms_1x.png`: all 120 at 1x on one sheet, by realm
- `babies_px/`: the 5 babies' poses and layers, redone at the new width
- a short `README.md` listing what changed in the Fire realm

## Order

1. **First: the Fire fixes and the Mountain realm.** Send them and wait for our feedback.
2. Then Moon, Fox and River.

## Don't

- Don't install anything, and don't touch `textures/`, `scenes/`, `scripts/` or `data/`.
- Don't add detail or shading. A's flat cartoon look is the one we chose.
