# Arcade cabinet v7 — three layout previews

**Official selection (2026-11-02):** `final_j/`. The user's chosen third ImageGen finish is `final_j/style_reference_imagegen.png`; `final_j/front.png` and the other registered 220-grid layers are the game-ready version. `tools/art/homes_install.py --home arcade_cabinet` and `tools/art/arcade_layers.py` install those layers into `textures/pet/homes/arcade_cabinet/`.

The side-by-side sheet `options_contact_4x.png` shows A, B and C in that order. Each option folder contains its ImageGen source, a 220 × 220 nearest-neighbour concept, and a 1760 × 1760 `preview_8x.png`. The spirit and ornaments are placement examples only.

| Option | Layout idea | Fit note for final art |
| --- | --- | --- |
| A | Broad projecting side wings with flat outer trays; controls flank the central table. | Closest to the 80 × 80 screen and 40-column tray reservations. |
| B | Tall central screen tower joined to two vertical side cabinets. | Increase the clear screen height on the final grid. |
| C | One broad cabinet with two open side alcoves. | Increase the clear screen height and widen the alcove tray tops on the final grid. |

All three retain the red-and-cream KamiTomo identity, lower coin slot and grille, hooks, central offering table and visible controls. `layout_guide.png` records the hard reservations: 96 × 88 screen, 56-column table, 44-column trays and 42-row ornament clearance. These are concept previews for selection; the chosen one still needs the exact game layers and grid checks before installation.

The built-in ImageGen tool made all three paintings. Its prompts used `v6_3/arcade_cabinet/preview_8x.png` as the palette/style reference and described A as broad wings, B as attached side cabinets, and C as internal alcoves; follow-up edits used `layout_guide.png` to enlarge the screen and reserve tray/table space. `tools/art/hokora_arcade_v7_concept_export.swift` makes the previews without smoothing.
