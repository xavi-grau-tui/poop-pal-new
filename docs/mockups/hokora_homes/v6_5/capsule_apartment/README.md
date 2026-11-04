# Capsule Pod v6.5

Clean side-window layers, all registered on a 220 × 220 canvas:

1. `trays.png` — two simple back walls and flat 30-column shelves.
2. The player's ornaments — feet at the green dots in `guide.png` (x 45 and 175, y 135–136).
3. `glass.png` — matching translucent panes and two small highlight lines per pane.
4. `front.png` — the pod with one clean transparent opening inside each side-window frame.

The central room and offering table remain the approved v6.4 versions. `guide.png` retains the bell and lantern hooks. `preview_8x.png` and `icon.png` show the assembled pod; `qa_magenta_8x.png` shows the same assembly over magenta.

The front cleanup was made with the built-in ImageGen edit tool using v6.4 `front.png` as its reference. Its generated source is `../source_imagegen.png`; `tools/art/hokora_capsule_v6_5_export.swift` places it on the final grid, preserves the accepted pod outside the side-window region, and separates the aligned layers. The export checks that no magenta is visible inside either window.
