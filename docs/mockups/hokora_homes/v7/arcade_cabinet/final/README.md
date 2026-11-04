# Arcade Cabinet v7 — Option A final layers

All game layers register on a 220 × 220 canvas:

1. `inside.png` — the dark-blue room behind the spirit, with extra coverage past the window for phone tilt.
2. The game draws the spirit.
3. `front.png` — the red-and-cream cabinet, broad side wings, sign, controls, coin slot and grille. Its screen opening is transparent; the 56-column middle of the control deck is plain for the game's separate offering table.
4. The game draws the table, two tray ornaments, lanterns and bell.

`guide.png` marks the bell hook orange at `(31,63)`, lantern hooks yellow at `(56,72)` and `(163,72)`, and usable tray tops green at `(20,144)` and `(199,144)`. `preview_8x.png` is the assembled cabinet without the game's movable objects. `icon.png` is 96 × 96.

The built-in ImageGen tool edited the approved Option A painting to remove the example spirit, ornaments, lanterns, bell and table, preserving the sign and lower cabinet. A final edit opened the side-wing clearance. The selected painting is `source_imagegen.png`; `tools/art/hokora_arcade_v7_final_export.swift` performs nearest-neighbour 220-grid export and separates the screen. It verifies an 82 × 82 transparent screen, 49-pixel tray tops, unobstructed 38 × 42 ornament spaces, hard alpha and mirrored outer structure (except the intentional bell hook).
