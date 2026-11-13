# Tomo Tunes — toy xylophone layers

The approved `tomo_xylophone_mockup.png` is the visual reference. `layers_assembled_preview.png` shows the ordinary state assembled from the delivered layers; `strike_preview.png` shows the middle bar lit with the optional mallet.

All named game layers are registered RGBA PNGs at **1900 × 1896**. `room_overscan.png` is an optional **2060 × 2056** background with the 1900 × 1896 `room.png` registered at (80, 80) for camera tilt. Its outer 80 px are painted extensions blended from the room's edge; the central view remains pixel-identical to `room.png`.

Draw order, back to front:

1. `room.png` (or `room_overscan.png` at offset −80, −80)
2. `xylophone.png`
3. `toy_kokeshi_bench.png`, then the other toy bodies; `toy_maneki_paw.png` in front of `toy_maneki.png`
4. `bar_low.png`, `bar_mid.png`, `bar_high.png`; swap a bar for its `_lit` version on a hit
5. `note_low.png`, `note_mid.png`, `note_high.png`, or `note_gold.png`; `mallet.png` is optional

The bars are 540, 400 and 320 px wide, all aligned at y = 1565–1705. The note cutouts are 130 × 130 px and contain no motion streak. The clean room contains no toys or xylophone; the xylophone layer contains no bars or notes.

**Method:** Built-in ImageGen edits of the approved mockup supplied the clean room, bar-free xylophone, transparent toy extractions, lit bars, wooden notes and mallet. The generated art was then cropped, registered and resampled onto the required canvas. The room and hidden xylophone surfaces were repainted where moving objects had covered them, so the assembled image follows the approved design but is not a pixel-identical reconstruction of the flattened mockup.

**ImageGen prompt set:** isolate and inpaint the toy room; isolate the wooden frame without strike bars or falling notes; extract each toy in place with transparent surroundings; render pink/yellow/mint struck-bar variants; paint four wooden-bead notes with top-left light and no streaks; paint one optional wooden mallet. All prompts used the approved mockup as their visual reference.
