# Spirits round 2 — concept_c

Offering Spirits: each spirit takes its body shape from the food or offering that formed it.

- Canonical character art is `<built-in function id>.png`, 56×56, transparent, baseline row 54.
- Ball icons are `<built-in function id>_ball.png`, 24×24, centered on a 16 px character body with one top cue.
- `source_strips/` contains the high-resolution ImageGen studies; `babies_px/` contains the five baby poses and separated animation layers.
- `fire_sheet.png` is the 4× review sheet; `fire_sheet_1x.png` shows the game-scale layout.
- `fire_balls.png` and `fire_silhouettes.png` provide quick size and silhouette reviews.
- `names.csv` includes the ID, localized name, body type, signature feature, detail summary and one-line personality.

Baby poses are `idle`, `blink`, `happy`, `eat`, and `sad`. Full-pose frames are the authoritative review art; `body`, `eyes`, `mouth`, `eyes_closed`, `mouth_open`, and `loose_part` are animation-layer aids.

All processing used hard alpha and nearest-neighbour pixel reduction from ImageGen source paintings. No game files or install scripts were touched.
