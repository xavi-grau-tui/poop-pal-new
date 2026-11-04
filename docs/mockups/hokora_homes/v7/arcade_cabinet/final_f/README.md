# Arcade Cabinet final_f

Two local pixel fixes on the approved `final_e` cabinet. **No ImageGen was used.**

- The deck ends now finish in paired cream corners with a dark edge under each pillar. The isolated red marks are covered. `trays.png` is unchanged and still draws behind `front.png`, with its painted cream tops.
- The screen has a dark inset bezel and a gently rounded CRT opening. Its visible opening is 88 × 84 pixels at its widest and tallest points. `inside.png` fills every screen pixel and extends behind the bezel for tilt. The game's glass remains separate.

`diff_vs_final_e_4x.png` shows every changed pixel in magenta, in three panels: **front, trays, inside**. Unchanged opaque pixels are dimmed. The export audit found **0 changes outside the marked boxes**, **0 tray changes**, and **0 screen gaps**. The changed-pixel counts are front 1,584 and inside 698, including the new opening's alpha and bezel.

Files: `front.png`, `trays.png`, `inside.png`, `guide.png` (220 × 220), `icon.png` (96 × 96), and `preview_8x.png` (1760 × 1760). Rebuild and verify with `tools/art/hokora_arcade_v7_final_f_export.swift`.
