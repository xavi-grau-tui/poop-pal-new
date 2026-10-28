# RC Prix Garden · stand visual studies

**Rejected for geometry in the next review.** The green-and-cream roof does
not align to the audience stand's width, and the side stand's near/lower end
does not repeat the staircase shown at its far/upper end. Focused imagegen
edits did not hold both constraints. These images are not approved designs or
game sprites. The geometry must be constructed on the final pixel grid.

These are review images made with the **built-in imagegen tool** from the
user's front and right-side references. They have not replaced the game
sprites.

| View | File | Canvas |
|---|---|---:|
| Front | `round14_front_pixel_study.png` | 2073×758 |
| Rear | `round14_back_pixel_study_v2.png` | 2073×758 |
| Right side | `round14_side_right_pixel_study_v2.png` | 1024×1536 |
| Left side | `round14_side_left_pixel_study_v2.png` | 1024×1536 |

The front remains wide and upright, with the detached awning and four bench
levels. The rear uses the same canvas and silhouette, showing rear posts and
openings between the four slats. Its generated image was one pixel taller, so
its saved review copy was cropped by one pixel without scaling. The right
side has four ordered vertical seat tiers and a full-length, constant-width
scalloped roof. The left is an exact horizontal mirror of the right review
image; its timber and fabric cannot drift independently.

The imagegen studies still need native-grid cleanup before becoming game
sprites: exact sprite dimensions, binary transparency, layer separation and
the project's checker. The earlier `stand_front/back/side_*` game PNG drafts
remain unapproved and should not be substituted for these studies.

## Prompt set

1. **Front:** edit the approved horizontal grandstand reference, preserving
   its four bench rows, exposed posts, angled end frames and detached awning;
   coarsen the pixel grid to the Garden tree scale, with flat material tones
   and hard edges; no rotation, extra row, checkerboard or UI overlay.
2. **Rear:** edit the front into the back of the same physical stand; align
   its canvas and silhouette with the front, keep the roof upright at the top,
   reverse the slat construction and leave transparent openings, with no back
   wall.
3. **Right side:** correct the supplied vertical side reference; four regular
   stepped tiers, support posts and open gaps; a rectangular roof of constant
   width along the entire right edge, with equal-size green-and-cream
   scallops; no triangular taper or diagonal isometric footprint.
4. **Left side:** derived as a strict horizontal mirror of the right-side
   image so both views are symmetric.
