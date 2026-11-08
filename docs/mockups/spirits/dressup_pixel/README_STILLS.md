# Dress-up stills round

This round is separate from the approved pilot. The original `dressup_pixel_filled.png`, `dressup_pixel_items.png`, pilot preview, and pilot sources remain in place.

**Painting revision, 2026-11-07:** the game now takes the high-resolution ImageGen paintings in `stills_sources/` and cuts them to its own detail level. `suzu_imagegen.png` and `pinwheel_imagegen.png` were repainted for this change. The grid sheets and grid previews below remain historical review files and were deliberately not regenerated.

## Deliverables

- `dressup_pixel_stills_filled.png`: the 22-row template with one still in the first cell of each active row.
- `dressup_pixel_stills_items.png`: the same item pixels on transparent canvas.
- `stills_review.png`: the requested items beside a reference spirit, at the sheet's 4× display size.
- `stills_game_size.png`: the same cells reduced to actual game pixels.
- `swim_ring_assembled_preview.png`: both ring layers around the spirit.
- `stills_audit.txt`: grid, alpha, cell, and approved-pixel checks.
- `stills_sources/`: the selected ImageGen paintings used to make the native-grid item pixels.

The first cell alone is filled in each row, including the under and head rows, following this round's still-only instruction. The game can size and animate each still in code. Rows 1, 3, and 13 (hitodama, music notes, sakura petals) are blank. The goldfish and sugegasa are copied pixel-for-pixel from the approved pilot's first cells. The cases were paused and not edited.

## ImageGen prompt set

**Shared art direction for every new source:** one still Japanese game dress-up sprite, transparent background; chunky hand-placed October-style pixels; solid one-game-pixel-equivalent dark plum `#22101A` contour; 3–4 flat stepped tones and upper-left highlight; slightly greyed colour and soft gloss from colour steps. No spirit, motion, glow, shadow, text, or extra props. Floaters must survive an 18×16 game-pixel box; under items a 40×10 box; head items the sheet's head zone.

| Source | Subject direction |
|---|---|
| `taketombo` | Two broad opposing pale bamboo blades, central hub, short spindle. |
| `chochin` | Round vermilion-and-cream paper lantern, three ribs, dark caps and loop. |
| `pennant` | Cream festival triangle with vermilion check corner, teal edge and short wooden pole. |
| `gunbai` | Rounded ginkgo-shaped fan, cream face, red crest, honey-wood rim and handle. |
| `pinwheel` | Four broad folded paper blades in alternating vermilion and cream, gold pin, short wooden stick. |
| `spinning_top` | Squat wooden koma with broad cream, vermilion and indigo bands. |
| `suzu` | Antique-gold round bell with a bold lower slit, small bottom hole and a short knotted red cord. |
| `shimenawa` | Thick straw oval halo with two broad white shide. |
| `crane` | Compact side-view cream origami crane with a short thick neck, broad folded wing and solid outline; revised once after game-size inspection. |
| `zabuton` | Low wine-red/plum brocade cushion, broad gold diamond, lighter top and gold tassels. |
| `lotus` | Low scalloped green leaf with one notch and a few broad fold veins. |
| `swim_ring` | One flattened oval inflatable ring with large coral-red and cream sections; back and front cut from this same painting. |
| `dohyo` | Low broad oval of large cream-and-honey rice-straw braids. |
| `kitsune_mask` | Ivory side-worn fox mask, pointed ears, red eye and forehead marks. |
| `kanzashi` | One five-petal coral sakura on a short gold pin with one bead. |
| `oni_horns` | Two broad ivory horns on one muted vermilion headband. |

ImageGen supplied the designs. Exact-grid colour reduction, placement, the swim-ring split, and audits were export operations on those paintings. No game files were installed.
