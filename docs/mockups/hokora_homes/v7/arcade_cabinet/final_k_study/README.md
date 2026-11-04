# Arcade Cabinet — approved study as game layers (review delivery)

`approved_study.png` is the **third ImageGen study** selected by the user. This delivery samples that picture directly onto the 220 × 220 home grid with nearest-neighbour resampling and hard alpha, then separates the actual sampled pixels into `front.png`, `inside.png`, and `trays.png`. The separate layers reassemble **pixel-for-pixel** into `study_on_220_grid.png` at zero tilt. `source_vs_layers_4x.png` shows the high-resolution study on the left and the delivered layers on the right.

This is a review delivery only. No files in `textures/` or `tools/art/` were changed for this delivery. The tech team can install it after user validation.

## Files

- `front.png`: lacquered body, sign, screw-mounted outer screen frame, controls, grille, feet, and **both upper hooks**. The screen opening is cut out as a rounded 80 × 80 window.
- `inside.png`: the approved study's dark screen artwork, with extra coverage around the window for phone tilt.
- `trays.png`: both projecting deck wings, their cream bevels and red front faces, at their positions in the study.
- `glass.png`: transparent; the study's dark screen colour is kept. The tech team can add a game shine over it if desired.
- `guide.png`: the existing bell, lantern and tray attachment dots, kept for placement review.
- `icon.png` (96 × 96) and `preview_8x.png` (nearest-neighbour 8×).
- `make_layers.py`: repeatable export and pixel-level assembly audit. Run from the repository root with `.venv/bin/python docs/mockups/hokora_homes/v7/arcade_cabinet/final_k_study/make_layers.py`.

The conversion preserves the study's own glossy red surfaces and purposeful highlights. Its shape differs slightly from final_i/final_j because the study itself is the approved source; the tech team should review the screen and tray depth at game tilt before installation.
