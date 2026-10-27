# RC Prix Garden art handoff — 76-file geometry pass

All 76 PNGs specified by `BRIEF.md` are in `textures/minigames/rcprix/garden/`.
They are generated at their final pixel dimensions by `tools/art/rcprix_garden_full.py`.
The script draws pixels directly and keeps alpha fully opaque or fully clear.

## Contents

- 9 existing narrow pieces updated to the approved round-two standard: 6 road pieces and 3 lawn squares.
- 8 wide road pieces at 100 px total road width, including both jump gaps.
- 14 overlays at each width, including start lines, boost pads, ramps and corner tyre walls.
- 29 sprites and board pieces: car slices, objects, foliage, flowers, trees and frame.
- 2 narrow jump gaps. Total: 76 files.

The narrow road is 88 px wide. All road and overlay names ending `_wide` use a
100 px road. The start lamp is white/grey for runtime tinting. All six car slices
are drawn at full brightness for runtime layer darkening. No supports were drawn.

## Review

Run with the repository's Pillow environment:

    ./.venv/bin/python3 tools/art/check_rcprix_art.py
    ./.venv/bin/python3 tools/art/rcprix_preview.py

The checker reported `76/76 files present, 0 problems` on 2026-10-27. The
assembled course pictures are `course_preview.png` and `course_preview_2x.png`
for the narrow road, plus `course_preview_wide.png` and
`course_preview_wide_2x.png` for the 100 px road. `car_slices_preview.png` shows
the six car layers and an unshifted composite. The game renderer has not yet
been changed to consume these files; visual placement and motion at phone size
remain for the technical integration pass. The current art focuses on exact
shapes and joins. A later art pass can refine the foliage and material finish.

## Structural revision after review

- Car slices 1–2 contain the chassis and four wheels. Slices 3–4 contain only
  the red body, slice 5 the cabin, and slice 6 the lit roof rim.
- Ramps use a cool steel palette and span the asphalt from inner curb to inner curb;
  their three broad tones brighten toward the raised lip in the travel direction.
- Boost pads use yellow and black chevrons across the full asphalt width.
- Corner tyre walls have a continuous dark backing with two staggered rows of
  touching tyres. Each width uses the matching corner radius.
