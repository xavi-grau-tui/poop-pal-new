# Dress-ups as pixel art: floaters, under items, head items (2026-11-07)

## Why a new round

Round 1 (docs/mockups/spirits/dressup/) was painted at painting resolution and shrunk about 4x for
the game. Its shading and outlines melted, and at game size the items looked flat and off-style
next to the spirits (the user). The ideas were fine; the method was wrong. Round 1 is kept and not
used.

## The one rule that fixes it

The spirits are native pixel art: on the sheets, every game pixel is a 4 x 4 block of one colour.
Draw every dress-up the same way, directly on that grid.

- **4 x 4 sheet px = 1 game pixel**, each block one flat colour, nothing in between.
- **The reference spirits** on the template are the real sprites enlarged 4x pixel for pixel. The
  zone for each item shows the game-pixel grid.
- **The look:** the October spirits' own. That means:
  - a 1-pixel plum outline;
  - 3–4 tones plus one highlight, lit from the top left;
  - soft gloss, chunky shapes, one clear idea;
  - nothing that matters thinner than 1 game pixel.
- **The test:** shrink your result 4x with nearest neighbour, then enlarge it 4x again. It must not
  change.
- **If you use ImageGen:** edit the template itself, so the reference spirits hold the style (the
  way the Fire sheet worked), then snap every 4 x 4 block to one colour by hand.

## The sheet

- To draw on: `docs/mockups/spirits/dressup_pixel_brief/dressup_pixel_sheet.png`.
- Labels: `dressup_pixel_guide.png`, made by `tools/art/dressup_pixel_template.py`.
- 22 rows of three cells. Draw inside the dashed zone only. A crossed zone means nothing to draw.

### Floaters (rows 1–13): hover over the head, never touch it

- **Drawn once.** Our code moves them (bob, drift, orbit, sway, glow, rise and fade).
- **Size:** they fill most of the 18 x 16 px box.
- **Frames:** up to three, only where the shape changes. Every frame of one floater keeps the same
  size and place, and **only the moving part changes**: everything else is the same pixel for pixel
  (the goldfish's bubble, the crane's body). Redrawing the whole item each frame makes it boil and
  shimmer (pilot, 2026-11-07).
- **Don't draw:** motion lines, glows or shadows. Code adds those.

| # | Floater | Takes over | Frames |
|---|---------|-----------|--------|
| 1 | Hitodama wisp | headlamp | 3, flicker |
| 2 | Taketombo | propeller cap | 3, spin |
| 3 | Music notes, a pair | headphones | 1 |
| 4 | Goldfish in a bubble | snorkel | 3, tail flap |
| 5 | Paper crane | round glasses | 3, wing flap |
| 6 | Chōchin lantern | explorer hat | 1 |
| 7 | Pennant flag | racing helmet | 3, wave |
| 8 | Gunbai fan | referee hat | 1 |
| 9 | Pinwheel | hard hat | 3, spin |
| 10 | Spinning top | hachimaki | 3, spin |
| 11 | Suzu bell | scarf | 1 |
| 12 | Shimenawa halo | sumo topknot | 3, slow turn |
| 13 | Sakura petals, three | new | 3, tumble |

### Under items (rows 14–18): the spirit sits on them

- **One per size:** small, medium and large (Inari, Mikazuki, Tonosama). They follow the spirit's
  width, about 4 px past each side.
- **Low and flat:** the faces sit low, so nothing may rise over the bottom of a face.
- **The swim ring** is two halves: the back half goes behind the spirit, the front half in front.
  Together they must make one ring.
- **Items:** zabuton cushion, lotus leaf, swim ring (back, front) and the straw dohyō ring.

### Head items (rows 19–22): worn on top or at the side of the head

- **Two sizes:** small and large. Our code fits them to each spirit's head.
- **Never over the face.** They may overlap the top of the head by a pixel or two.
- **Items:**
  - a kitsune mask worn at the side (Tomopedia, 30 spirits);
  - a sugegasa straw hat (Paper Sumo secret);
  - a kanzashi flower hairpin (Lucky Pinch);
  - oni horns (Top Spin secret).

## Delivery

- **Where:** `docs/mockups/spirits/dressup_pixel/`.
- `dressup_pixel_filled.png`: the sheet, filled.
- `dressup_pixel_items.png`: the same layout, transparent, items only.
- Your sources, if any.

As always, don't touch `textures/`, `scenes/`, `scripts/` or `data/`.
