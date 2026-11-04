# Capsule Pod v6.4

The approved v6.2 ImageGen design is retained. The 220 px export widens the two side bays by eight columns overall while leaving the central circular opening unchanged. The 220-grid layers use hard pixel edges.

All game layers are 220 × 220 and register on the same canvas. Draw order, back to front:

1. `inside.png` (existing central room)
2. `window_back.png` (the two side rooms)
3. `window_trays.png` (the two object floors)
4. Player shelf objects, with feet at approximately `(44, 136)` and `(175, 136)`
5. `glass.png` (translucent side panes and existing highlights)
6. `front.png` (side openings are transparent within their frames)
7. `table.png` (existing approved table)

`guide.png` marks the tray centres. `preview_8x.png` is the assembled image with nearest-neighbour enlargement; `icon.png` is 96 × 96.

The layer export is reproducible with `tools/art/hokora_capsule_v6_4_export.swift`.
