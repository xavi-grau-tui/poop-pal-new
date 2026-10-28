# RC Prix · Garden: notes for round 6 (bushes drawn exactly like the tree)

Round 5 is clear progress: the shapes of all seven bushes are approved, keep them. But they don't
yet look drawn with the same brush as the tree. We measured the approved tree and turned it into a
recipe, and the checker now tests every bush against it. **A bush is done when the checker passes.**

`round6_tree_tones_3x.png` shows the tree and the seven bushes with every pixel snapped to the
tree's six colours. The differences are easy to see there.

## The tree's recipe

**1. Only the tree's six colours.** No other greens, no blue-green or purple darks.

| Colour | Hex | Share of the bush (the tree's) |
|---|---|---|
| outline | `#251a24` | 6–20% (9%) |
| deep shadow | `#1a4131` | 18–34% (26%) |
| mid + mid 2 | `#2b6639`, `#31723b` | 18–38% together (27%) |
| light | `#5fb138` | 18–34% (26%) |
| highlight | `#97d53a` | 6–18% (12%) |

So the tree is **mostly dark and mid green**. The highlight is only the small top-left tip of each
leaf patch. It is not the main colour.

**2. Leaf patches about 7×7 px.** Each leaf cluster has one light patch (light + highlight) of
about 30–60 px in area (the tree's median is 47 px, about 7×7). Each has a highlight tip of a few
pixels at its top left, and deep shadow below and to its right where it tucks under the next
cluster. No single-pixel or 2×2 specks of light.

**3. Calm colour.** On average the colour changes only every 3.2–4.2 px across and down (the
tree's is 3.65). Below that it reads as speckle.

**4. The outline.** A 1 px `#251a24` line around the outside, on at least 75% of the edge. The
other edge pixels may be deep shadow, never light or highlight. Inside the bush, the outline colour
appears at most 8%, only in the deep gaps between clusters, never as lines through a cluster.

## What we see in round 5 (from the checker)

| Bush | What's off |
|---|---|
| A | too much highlight (29%), too little shadow, light patches too small (19 px), some off-palette colours |
| B | too much highlight (36%), too little shadow, outline missing on part of the edge, a bit speckled, off-palette colours |
| C | highlight floods it (57%), the light colour is almost missing, off-palette colours |
| D | highlight floods it (45%), little light and shadow, a third of its pixels off-palette |
| E, F, G | speckled: light patches only 5 px (need 30+), colour changes every 2.2–2.4 px |

The small bushes in particular need **fewer, bigger patches**. At 38–48 px wide that means just
2–3 clusters, each with one clear 7×7-ish light patch.

## How to work

- **Draw or repaint on the final pixel grid, locked to the six colours** (an indexed palette in
  your editor). Snapping a generated picture to the palette is fine as a start, but then repaint by
  hand: merge specks into patches, push most of the bright area back to light and mid, and add the
  deep shadow under each cluster.
- Keep sizes and silhouettes as in round 5.
- Use the tree as the reference next to you at 4× while working.

## Test before handing over

1. `python3 tools/art/check_rcprix_art.py`: 81/81 files, **0 problems**. Any bush that doesn't match
   the tree is listed as `not tree` with the measures that are off and the tree's range.
2. Make the tone picture again (all seven next to the tree, snapped to the six colours) and the 4×
   picture next to the tree.
3. `python3 tools/art/rcprix_preview.py`.
