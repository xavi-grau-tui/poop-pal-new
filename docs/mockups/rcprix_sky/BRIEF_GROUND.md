# RC Prix · Sky: the ground far below

The countryside seen from very high under the plane. The user loves today's look (`current/g0_l25_1.png`):
a patchwork of fields on a **diagonal grid**, pale and hazy because it's far away. We keep that layout and
feeling; your paintings bring the quality.

**Workflow:** you paint high-resolution pictures with ImageGen; we convert them to the game's pixels, and
**we turn them to the grid's angle ourselves** (from your big painting, so no jagged edges). So paint
everything **straight**: rows and hedges horizontal.

## How the game builds it

- `ground_guides/ground_grid_4x.png`: one phone screen of today's grid. Fields are about **100 × 82 game px**,
  their long edges about 15° down from horizontal, their short edges about 70°. About three fields across the
  screen.
- `ground_guides/ground_today_4x.png`: today's colours, hedges and river, before the haze.
- The game lays out the fields, fills each with one of your field paintings (turned to the angle), strings your
  hedges along the edges, places your decor, draws the river, then adds **the haze and the cloud shadows** (as
  today). So paint at **full colour**; the game makes it pale.
- Scale marks in the guide (game px): a farmhouse 7 × 6, a village 30 × 22, a tree 4 × 4, the plane 52 × 52.

## Style (all pieces)

- **Seen straight down** (not at an angle like concept A), light from the top left.
- Concept A's soft, calm countryside, painted like your cumulus: clusters of light and shade, no smooth
  gradients.
- Every piece on a **transparent background** except the field squares (edge to edge).

## What to paint

1. **Field squares** (8 crops, each a square painting that fills the whole square, no border). In the game a
   square covers about **128 × 128 game px**. Crops:
   wheat (gold) · young green crop · meadow with tiny flowers · ploughed earth (straight furrows) · pasture
   (soft grass, a few tiny sheep) · orchard (rows of round little trees, about 5 game px each) · vegetable rows ·
   hay (pale yellow-green, a few round bales).
   Rows and furrows run **horizontal**, about 4 game px apart. Calm, even texture across the square: no single
   big feature, since squares repeat across fields.
2. **Hedges** (transparent, long horizontal strips, about 8 times as long as tall): a low hedge (about 3 game px
   thick) and a tree line (round trees, 4–6 game px). We cut them to length and turn them to both edge angles.
3. **Decor** (transparent, each its own picture), game sizes in brackets:
   farmhouse with barn (12 × 9) · small village, a cluster of roofs round a little square (32 × 24) · church
   (10 × 12) · windmill tower (8 × 8) plus its sails separately (16 × 16; we spin them) · stone bridge for the river
   (20 × 10, crossing left to right) · pond (16 × 10) · haystacks (10 × 6) · a copse of trees (24 × 18).
4. **River** (one horizontal strip, about 4 times as long as tall): water with soft ripples and grassy, slightly
   sandy banks along the top and bottom. The game draws the river's winding path with it.

## Delivery

Into `docs/mockups/rcprix_sky/ground_sources/`, with a README listing each file, as last time. Fields first (they
decide the look), then hedges, decor and the river. We'll convert each group and send phone screenshots.
