# Spirit dress-up and angry-face handoff

The new artwork was made with built-in ImageGen. Assembly, scaling, exact face-area pasting and audits used Pillow; no art was drawn by script.

## Dress-up

- `dressup_items.png`: transparent, 780 × 4420, 17 rows of three 260 px cells; items only.
- `dressup_filled.png`: the same placement beside the approved spirits for review.
- `dressup_items_2x.png` and `dressup_filled_2x.png`: nearest-neighbour 2× views.
- `sources/`: the 17 selected full-resolution ImageGen paintings used for the sheet, one per item. The three-frame sources contain all three frames in one image.

The design prompts asked for isolated transparent sprites in the October spirits' soft glossy style, a dark plum outline, few bold details, and the appropriate shape for each of the 17 items in the brief. The three platform paintings were revised to a low, broad profile after a game-size review. The source paintings are kept for further art direction.

## Angry faces

The finished realm files are beside their source sheets in `../anim_prep/` as `<realm>_prep_N_filled_v2.png` (20 files). `pilot_angry_filled.png` covers the other six spirits. `angry_face_audit.json` records the approved face box, changed-pixel count and image registration for every spirit.

The expression studies were ImageGen edits of each exact sheet: mildly annoyed, small inward brows or narrowed eyes, a tiny pout, and each distinctive face retained. The output files were made by pasting only the local face areas onto the existing sheet. Rows 1–5 and 7 are pixel-identical to the prior filled files. Some older row-6 cells were blank even though the brief describes them as base copies; the audit marks 52 such cells with `restored_missing_row6_body: true`. Those bodies were restored from the exact approved row-1 cell before the angry face was pasted.

No game assets or install scripts were changed for this handoff.
