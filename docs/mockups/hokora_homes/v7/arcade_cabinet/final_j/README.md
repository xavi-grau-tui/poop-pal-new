# Arcade Cabinet final_j

**Approved visual master:** `style_reference_imagegen.png` (the third ImageGen cabinet selected by the user). **Official game layers:** `front.png`, `trays.png`, `inside.png`, `glass.png`, and `guide.png`, all registered at 220 × 220. `preview_8x.png` and `icon.png` show the assembled result. The game install scripts now select this folder.

The built-in ImageGen tool made `style_reference_imagegen.png` **for finish direction only**. It was not used as a game layer. Prompt: “A finish-only style reference for the existing KamiTomo red arcade cabinet; preserve its sign, screen, trays, controls, coin grille, feet and hooks; enrich its lacquered red, cream, gold and plum materials with clean stepped shading, purposeful seams, rivets, bevels and top-left light, matching the four neighboring homes.” The delivered game pixels were repainted on final_i’s 220 grid by `tools/art/hokora_arcade_v7_final_j_export.swift`.

The repaint adds coherent red lacquer tones, panel join shadows, a lit gold sign frame, a shaded screen bezel, control-deck plate seams and fasteners, matching tray bevels, and a more dimensional lower cabinet. `quality_vs_other_homes.png` shows final_j beside the Food Stall, Capsule Pod, Tree Hollow and Bathhouse at the same scale.

## Audit

- `front.png`: alpha mask identical to final_i; 7,321 colour pixels changed.
- `trays.png`: alpha mask identical to final_i; 2,051 colour pixels changed.
- `inside.png`, `glass.png`, and `guide.png`: copied unchanged from final_i.
- 0 alpha-mask changes across the edited layers. The screen opening, tray tops, positions and dimensions are therefore unchanged.
- `diff_vs_final_i_4x.png` marks every changed front and tray pixel in magenta, with the front on the left and trays on the right.

Rebuild and recheck from the repository root with `swift tools/art/hokora_arcade_v7_final_j_export.swift`.
