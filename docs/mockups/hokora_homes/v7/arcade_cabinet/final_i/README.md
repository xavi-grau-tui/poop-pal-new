# Arcade Cabinet final_i

Pixel edits on `../final_h/`. The approved screen and trays are unchanged. The deck's top bands now run continuously, stray pixels around the yellow button are removed, and the joystick and three buttons have clean rims, highlights, and contact shadows in their original positions.

`front.png`, `trays.png`, `inside.png`, `glass.png`, and `guide.png` are registered 220 × 220 layers. `preview_8x.png` is assembled from those layers at nearest-neighbour 8×. `icon.png` is 96 × 96.

Audit: 643 front pixels changed, all within the deck bands or control footprints; 0 pixels changed on `trays.png`, `inside.png`, or `glass.png`; 0 alpha-mask changes; 0 changes outside the allowed deck areas. `diff_vs_final_h_4x.png` shows every changed pixel in magenta, with panels ordered front, trays, inside, glass.

Rebuild and recheck with `swift tools/art/hokora_arcade_v7_final_i_export.swift` from the repository root.
