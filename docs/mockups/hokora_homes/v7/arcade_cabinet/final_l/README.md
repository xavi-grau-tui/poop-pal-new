# Arcade Cabinet final_l — review delivery

Source: `../current_k/`. This finish pass keeps its approved silhouette, solitary raised left arm, screen opening, row-145 tray tops, flat deck and tray faces, joystick position, inside and glass. It changes only colours at the arm joint and cap shoulders, deck and tray ends, former joystick spot, sign, and the three buttons moved about 8 grid pixels right.

## Review

- `preview_8x.png`: the assembled 220-grid layers, nearest-neighbour at 8×.
- `sign_comparison.png`: current_k sign, final_l 220-grid sign, then the higher-density sign at the same displayed size.
- `sign_2x.png`: sign plate only on a registered transparent 440 × 440 canvas. Its lettering is rasterized independently at twice the game grid density; it is not a smooth upscale.
- `diff_vs_current_k_4x.png`: magenta marks every changed pixel in front, trays, inside and glass (left to right).
- `imagegen_sign_reference.png`: built-in ImageGen visual study; it is **not** a game layer because it changes approved shapes.

## Audit

`front.png`, `trays.png`, `inside.png`, and `glass.png` are 220 × 220. The front and tray alpha masks match current_k pixel-for-pixel. `inside.png` and `glass.png` are byte-identical copies. The pixel audit reports 2,515 changed front pixels, 86 changed tray pixels, 0 changes to inside/glass, and 0 changes outside the listed finish areas. Rebuild and rerun it from the repository root with `.venv/bin/python docs/mockups/hokora_homes/v7/arcade_cabinet/final_l/make_final_l.py`.

This folder is for user and tech review. Nothing was installed into `textures/` or the game.

ImageGen prompt, built-in mode: “Take the approved current_k red-and-cream arcade as the edit target. Preserve its single raised left arm, flat deck and trays, shifted-left joystick, sign, screen, grille and feet. Improve the legibility of the exact text ‘KamiTomo’ and ‘神友’ with even pixel-art strokes; show three buttons shifted right as a visual reference, without changing the cabinet layout.” The delivered grid layers are pixel-level edits of current_k, following the brief's exact-mask requirement.
