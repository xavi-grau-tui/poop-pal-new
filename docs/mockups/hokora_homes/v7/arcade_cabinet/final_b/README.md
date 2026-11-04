# Arcade Cabinet v7 final_b

The thicker Option A cabinet is supplied as aligned game layers on a 220 × 220 canvas: `inside.png` behind the spirit, then `front.png` in front. The game draws the offering table, tray ornaments, lanterns and bell. The middle of the cream deck stays empty; the joystick and buttons remain on either side. `preview_8x.png` shows the assembled cabinet, and `icon.png` is 96 × 96.

`guide.png` marks the bell hook orange at `(44,22)`, lantern hooks yellow at `(56,72)` and `(163,72)`, and tray placement green at `(20,144)` and `(199,144)`. A bell about 12 columns wide and 45 rows long ends at row 67, above the ornament space beginning at row 101.

The built-in ImageGen edit used `final/source_imagegen.png` as the edit target and `option_a/source_imagegen.png` as the proportion reference. Its prompt restored Option A's thick red pillars, deep cream-and-red wings, solid deck and lower body while keeping the empty screen, controls and table area. The selected painting is `source_imagegen.png`. `tools/art/hokora_arcade_v7_final_b_export.swift` performs nearest-neighbour export and separates the screen while keeping the painting's full flared pillar contour. A full-size ornament can visually overlap the lower pillar edge; the game draws the ornament in front.

The export checks: 80 × 78 transparent screen covered by `inside.png`; 53-pixel flat tray tops; mirrored outer structure apart from the left-only bell hook; hard alpha in the game layers. The high bell ends above the ornament area.
