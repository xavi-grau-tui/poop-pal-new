# Arcade Cabinet final_h

Pixel edits on the approved `final_g/` files. **No ImageGen or redraw.** The sign, cabinet silhouette, pillars, coin grille, screen cutout, `inside.png` and `glass.png` are retained.

- The screen bezel is one dark plum band with an outside dark edge and a single lighter line beside the opening. The front layer's alpha mask, including the screen cutout, is pixel-identical to `final_g`.
- The trays remain front faces behind the cabinet. Their top edge uses the cream deck's own row colours from row 150; the red fronts have one continuous gold line and a dark bottom edge.
- The marked control areas have a calmer cream deck. The approved joystick painting stays at x=71. The three shaded buttons are shifted one pixel left as a group, putting their centre at x=149, the same distance from x=110 as the joystick.

`diff_vs_final_g_4x.png` marks **every changed pixel** in magenta. Panels, left to right: front, trays, inside. Unchanged opaque pixels are dimmed. The export audit reports **0 changes outside the three marked areas**, **0 front alpha changes**, and **0 changes to `inside.png`**. `glass.png` is copied unchanged.

Files: `front.png`, `trays.png`, `inside.png`, `glass.png`, `guide.png` (220 × 220); `icon.png` (96 × 96); `preview_8x.png` (1760 × 1760). Rebuild and audit with `tools/art/hokora_arcade_v7_final_h_export.swift`.
