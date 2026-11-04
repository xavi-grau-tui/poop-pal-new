# Hokora homes v5 — ImageGen art handoff

The approved Tree Hollow and nine additional homes are here as review assets.
The new homes are Neon Cyber, Moon, Golden Temple, Ruined Night, Food Stall,
Capsule Apartment, Arcade Cabinet, Bathhouse, and Fire Shrine. Nothing in this
folder has been installed into the game's `textures/` folders.

## Files per home

Each home folder has `front.png`, `inside.png`, `table.png`, and `guide.png` on
the same transparent **220 × 220** canvas; `icon.png` is **96 × 96**.
`preview_8x.png` assembles the layers. `compare_8x.png` places that assembly
beside the forest hokora at the same scale. Capsule Apartment and Arcade
Cabinet additionally have `glass.png` on the 220 × 220 canvas, with partially
transparent panes. ImageGen source paintings are retained as
`*_source_imagegen.png`.
`front_check_8x.png` shows the front over bright pink so the actual opening
edge and other transparent gaps are easy to inspect.

The central cutout in each `front.png` follows its pictured opening. `inside`
extends behind the front's edge to allow parallax. The tables are separate,
with their tops at row 142 and bases at row 162. The `guide.png` dots and bars
show attachment points and shelf lines; they are documentation, not game art.

**Suggested layer order:** `inside`, spirit, `front`, `glass` (where present),
`table`, then player-selected decorations. The glass layer can move above the
spirit if the game wants the reflection to cross it.

## Homes and recolourable materials

| Folder | Recolourable materials |
| --- | --- |
| `tree_hollow` | outer bark, moss, inner wood |
| `neon_cyber` | metal, LED trim, cables |
| `moon` | moon stone, lilac trim, lunar dust |
| `golden` | gold leaf, black lacquer, roof tile |
| `ruined_night` | weathered wood, roof tile, moss |
| `ramen_stall` | wood, awning fabric, lacquer |
| `capsule_apartment` | plastic shell, teal seam, inner lining |
| `arcade_cabinet` | red shell, cream panel, dark bezel |
| `bathhouse` | roof tile, wall tile, wood trim |
| `fire` | basalt, iron tile, ember fissures |

## Export method

The visible designs were painted with ImageGen, using the approved Tree Hollow,
forest hokora, the preceding concept, and each v5 note card as references.
`tools/art/hokora_v5_homes_export.swift` only aligns source paintings to the
220 grid, cuts the front at its real transparent opening, places the separate
room and table, exports the partial glass and creates the review images. It
does not invent design details. It can be run for an individual folder name,
for example:

```sh
CLANG_MODULE_CACHE_PATH=/tmp/hokora-clang-cache SWIFT_MODULE_CACHE_PATH=/tmp/hokora-swift-cache swift tools/art/hokora_v5_homes_export.swift neon_cyber
```

The approved Tree Hollow was exported with
`tools/art/hokora_v5_export.swift`. Each new home is ready for in-game fit and
art review; the `compare_8x.png` images are the quickest overview.
