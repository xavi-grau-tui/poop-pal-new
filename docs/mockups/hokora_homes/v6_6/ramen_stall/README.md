# Food Stall v6.6 — mudguards and separate wheels

All game layers register on the same 220 × 220 canvas:

1. `front.png` — the approved v6.1 stall with wheel pixels removed and its lower wooden beam continued behind them.
2. `mudguard_left.png`, `mudguard_right.png` — matching wooden front faces, each with a flat top about 30 art columns wide. The right is the mirror of the left. The game can stack copies behind each face to add depth.
3. Player ornaments — their feet go at the green dots in `guide.png` (approximately x 36 and 184, y 114–115).
4. `wheels.png` — both approved round wheels in their original positions, drawn above the mudguard depth.

`inside.png` and `table.png` are retained from the approved stall for integration. `preview_8x.png` shows the assembly with two small existing ornaments for placement only; those ornaments are not baked into the game layers. `icon.png` is a 96 × 96 preview.

The built-in ImageGen edit created the mudguard front-face painting at `../mudguard_imagegen_source.png`. `tools/art/hokora_food_stall_v6_6_export.swift` puts it on the 220-grid with nearest-neighbour sampling, separates the wheels from the accepted front, and checks hard alpha and unchanged stall pixels outside the wheel areas.
