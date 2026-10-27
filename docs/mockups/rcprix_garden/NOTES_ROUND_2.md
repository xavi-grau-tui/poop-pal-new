# RC Prix · Garden: notes for the final art (round 2)

The pilot passed: the 7 road pieces join exactly, the side face sits in the right places, and grass
B and C exist. Thank you. We now want the **final, complete Garden set** before anything goes into
the game: all 76 files from `BRIEF.md` (both road widths), finished and consistent. The brief's rules all still apply.

## 1. Fix in the pieces you've already drawn

1. **Curb stripes at the joins.** Where a curve meets a straight, one stripe is longer than the
   rest. Make every piece's curb start and end the same way at each join: a join always falls
   exactly at the start of a red stripe. On straights, use a stripe length that divides 180
   (for example 10 px red and 10 px white). On curves, use a whole number of stripes along each arc,
   stretched slightly to fit. The inner curb is short (about 77 px of arc) and the outer one long
   (about 206 px), so each gets its own count.
2. **Centre dashes at the joins.** The last dash on a curve sits too close to the first dash on the
   next straight. Same rule: a dash pattern that divides 180 on straights, and a whole number of
   dashes along each curve's centre line (about 141 px of arc), so every join falls in the middle
   of a gap.
3. **Grass rhythm.** Over a whole board the tufts line up in visible rows, because A, B and C put
   them in similar places (see `course_preview.png`). Spread them differently in each square:
   different spots, sizes and counts. Keep at least one bigger, darker patch and one flower cluster
   in each, never at the same position in two squares.

## 2. Give it more depth (the final look)

The pilot is clean but reads as flat vector art. For the final set, keep the clean shapes and add
pixel-art depth:

- **Asphalt:** a light grain, a few 1 px flecks in two tones slightly lighter and darker than the
  road, sparse and even, not noise. Keep the lighter band along the edges you already have.
- **Curbs:** a 1 px darker line on their road-side edge, so they look slightly raised.
- **Raised side face:** use the full 12 px from the brief, in two tones of orange (lighter at the
  top, darker below) with a 1 px dark line at the bottom where it meets the lawn.
- **Grass:** 3–4 tones of green, the tufts lit from the top left (a light pixel on their top-left,
  a darker one bottom-right).
- **Outline:** the same dark plum (#281E28) round the road's outer edge and round every object.

Before you make them all, show these depth changes on one straight and one corner first, so we can
approve the look.

## 3. Draw everything else

The rest, at the same level of finish (all listed in `BRIEF.md` and the templates), plus the whole wide set (the road pieces and overlays again with the 100 px road, `templates/1b_` and `2b_`):

- **Overlays:**
  - start line across and up/down;
  - boost pads and ramps for each of the 4 directions;
  - tyre walls for the 4 corners;
  - the 2 jump gaps (road pieces).
- **Sprites:** the 6 car slices, crate, lamp post, start lamp, spring, balloon, sparkle, helmet.
- **Decor:** 2 bushes, 2 flower patches, the 4 trees hanging over the board's edges.
- **The wooden frame:** 4 corners and the 4 sides.

Overlays and tyre walls must line up with the road pieces' exact pixels. Draw them on top of the
matching road piece, then remove the road before saving.

## 4. Check it yourself before handing over

1. Run the checker. It must say `76/76 files present, 0 problems`:

       python3 tools/art/check_rcprix_art.py

2. Build the test course. It lays a whole board from your files: every road piece and overlay,
   mixed grass, decor, trees and the frame. Anything still missing is listed and left out.

       python3 tools/art/rcprix_preview.py

   Look at `course_preview.png` and the close-up `course_preview_2x.png`. Check the joins, curbs,
   dashes, grass seams and rhythm, and that the overlays and tyre walls sit right.
3. Hand over the 76 files in `textures/minigames/rcprix/garden/`, plus both preview pictures.

## Order

1. The depth test: one straight and one corner (section 2). Wait for approval.
2. The 9 existing pieces updated (sections 1 and 2).
3. The overlays and jump gaps.
4. The sprites, decor and frame.
