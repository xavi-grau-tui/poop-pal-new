# Homes v6.2 art handoff

This folder contains only the v6.2 changes. Keep the approved v6.1 Golden Temple, Food Stall, Moon home, tables, and bell designs. The paintings were made with the built-in ImageGen tool. Swift scripts only place existing artwork on the game grid, crop connected sprites, and assemble previews. Production textures have not been replaced.

## Changed assets

| Item | Files | What changed |
| --- | --- | --- |
| All ten home bead sets | `<home>/bead_1.png`, `bead_2.png`, `bell_chain_4x.png` | Each bead's visible shape is 44×68 inside its 48×68 box, reaching top and bottom so the five-bead chain meets. The approved designs and palettes are retained. |
| Moon bell | `moon/bell.png`, `moon/bell_source_imagegen.png` | Same silhouette and crescent, repainted darker silver-lilac with a stronger plum outline and blue-lilac shadow. |
| Ruined Night | `ruined_night/front.png`, `inside.png`, `table.png`, `preview_8x.png`, `icon.png` | The approved v6 building is re-exported from its source with its natural broken opening. The room fills the opening behind the spirit; the v6.1 table is retained. |
| Arcade Cabinet | `arcade_cabinet/front.png`, `inside.png`, `glass.png`, `table.png`, `guide.png`, `preview_8x.png`, `icon.png`, `front_source_imagegen.png` | Edited from v6: the exact friendly arcade shape, marquee, left joystick, right coloured buttons and slanted red sides remain. A real central gap holds the approved coin-box table. Coin door, outlines and simple trim are cleaner. The accepted small bell bracket remains attached. |
| Capsule Pod | `capsule_apartment/front.png`, `inside.png`, `glass.png`, `table.png`, `guide.png`, `preview_8x.png`, `icon.png`, `front_source_imagegen.png` | Edited from v5 on a taller canvas: longer upper shell with separate panel lines, same width, a round central hatch, side windows and feet. The approved table remains. |

For all ten homes, `<home>/bell.png` is present at 76×86. Nine of these are the approved v6.1 bell copied unchanged. The new Moon bell is at the same size. All twenty beads are 48×68. `bell_chain_4x.png` is made from the delivered PNGs, with five beads under the bell.

The revised home front, inside and table layers are each 220×220. The Arcade and Capsule glass layer is copied from v5. `preview_8x.png` shows the assembled delivered layers at nearest-neighbour 8×, and `icon.png` is 96×96. The Capsule's `tall_edit_guide.png` is a technical canvas used for the ImageGen edit, not a game asset.

## ImageGen prompt set

- **Moon bell:** edit the approved bell only; preserve the loop, crescent, skirt and clapper while darkening the stone to cool silver-lilac, adding a deeper blue-lilac underside and a strong plum outline for contrast against the arch.
- **Arcade:** edit the v6 front; preserve the KamiTomo marquee, red slanted cabinet, cream panel, left joystick and three right buttons; cut a central table recess; refine only simple arcade trim, speaker/coin-door details and shading; no ornate gold patterns.
- **Capsule:** edit the v5 pod on a taller square canvas; keep its width, two handles, side windows, white/teal palette, genuinely round central opening and symmetry; extend the upper and lower shell into taller proportions with crisp panel lines.

Ruined Night's fix and bead enlargement are technical exports of already approved ImageGen paintings, with no new visual design. The bead export removes tiny disconnected source fragments before scaling.

## Checks

Dimension check: **0 problems** across 10 bells, 20 beads, and the three revised homes' front, inside and table layers. Bead visible bounds are x=2–45, y=0–67 within each 48×68 file. Capsule and Arcade bell-guide dots both land on opaque support pixels. The three front layers stay within the 220×220 canvas at rows 4/5 through 199. Review the assembled previews in the live game with the spirit and decorations before swapping production textures.
