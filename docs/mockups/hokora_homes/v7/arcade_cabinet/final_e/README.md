# Arcade Cabinet v7 final_e

This is a small pixel finish pass on the **approved `final_c_wide` files**. It does not use ImageGen. The side trays keep their painted cream tops and original depth. The screen, sign, controls, grille, lower pillars and all other geometry remain in place.

Files: `front.png`, `trays.png`, `inside.png`, `guide.png`, `icon.png`, `preview_8x.png`. The three game layers and guide are 220 × 220; the icon is 96 × 96 and the preview is 1760 × 1760.

The edits are short tone adjustments inside existing cream, red, blue and gold regions: sign edge, controls, cabinet flecks, grille and tray paint. `inside.png` is pixel-identical to the approved version. No layer has any changed alpha pixel or material region.

`diff_all_layers_4x.png` marks **every changed pixel in magenta**. Its panels, left to right, are front, trays and inside; unchanged opaque pixels are darkened for context. Changed pixel counts: front **56**, trays **28**, inside **0**.

Rebuild and audit with `tools/art/hokora_arcade_v7_final_e_export.swift`. The script checks each layer's alpha against `final_c_wide` pixel by pixel and refuses to export if a colour-region classification changes.
