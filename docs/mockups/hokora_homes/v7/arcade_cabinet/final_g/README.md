# Arcade Cabinet final_g

Pixel edits on `current/`, the version already in the game. **No ImageGen or redraw.** The sign, controls, yellow button, coin grille, cabinet silhouette, screen opening, `inside.png` and `glass.png` retain their positions and shapes.

- The dark screen bezel now has equal, mirrored side bands, straight outside edges, and one light bevel line. The stray pale pixels at its bottom corners are covered.
- The tray faces begin at row 150, level with the deck. Their red fronts are taller; they remain behind `front.png` so the game can stack depth behind them.
- The two red pillar feet have paired dark end lines and clean cream deck corners.

`diff_vs_current_4x.png` marks **every changed pixel** in magenta. Its panels are front, trays, inside (left to right); unchanged opaque pixels are dimmed. The script found **0 changes outside the marked spots** and **0 changes to `inside.png`**. `glass.png` is copied unchanged.

Files: `front.png`, `trays.png`, `inside.png`, `glass.png`, `guide.png` (220 × 220), `icon.png` (96 × 96), and `preview_8x.png` (1760 × 1760). The guide's green dots mark the middle of the left and right tray tops. Rebuild and audit with `tools/art/hokora_arcade_v7_final_g_export.swift`.
