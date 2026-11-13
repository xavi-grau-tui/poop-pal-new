# Tomo Tunes, World 2: approved piano mock-up layers

`layers_assembled_preview.png` is a composite made from the delivered layers. The approved composition is `tomo_piano_mockup_v3.png`; the layers preserve its blue-hour tatami room, dark piano, record player, tea, metronome, cranes, and lantern. The separate cutouts and empty room/piano were painted with ImageGen, then registered and cut to the approved composition.

## Canvas and placement

- All 25 game layers are transparent RGBA PNGs on the same **1900 × 1896** canvas. Keep their canvas origin when drawing them.
- `room_overscan.png` is **2060 × 2056**; its central rectangle, starting at (80, 80), matches `room.png` pixel for pixel. Its outer 80 px is extended for tilt.
- `key_low`, `key_mid`, and `key_high` are each **370 × 140** in their registered layers, centered at **(517, 1635)**, **(953, 1635)**, and **(1388, 1635)**. The lit keys use the same silhouettes and positions.
- Each note occupies **130 × 130** in its registered layer. They have no motion trails.

## Layer order, back to front

1. `room.png` or `room_overscan.png` (with the latter offset by −80, −80)
2. `lantern_glow.png` (animate opacity)
3. `piano.png` (body, small keys, lid, and stand; no large coloured keys)
4. `record_player.png`, `record.png`, `record_arm.png`
5. `tea.png`, `tea_steam.png`
6. `metronome.png`, `metronome_needle.png`
7. `cranes_bar.png`, `crane_1.png`, `crane_2.png`, `crane_3.png`
8. `lantern.png`
9. `key_low.png`, `key_mid.png`, `key_high.png` (swap with the corresponding `_lit` file on hits)
10. `note_low.png`, `note_mid.png`, `note_high.png`, `note_gold.png` (move these during play)

Each movable prop is whole on its own layer; its background is present in `room.png`. The record, tonearm, steam, metronome needle, and cranes can move independently. `cranes_bar.png` contains the mobile's stick and strings.

No game assets or install scripts were changed.
