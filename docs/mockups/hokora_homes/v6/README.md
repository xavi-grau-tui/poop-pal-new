# Hokora homes v6 — art handoff

This folder contains **review assets**, not installed game textures. The six revised homes are in `golden/`, `capsule_apartment/`, `arcade_cabinet/`, `ramen_stall/`, `ruined_night/`, and `moon/`. Each has an ImageGen source painting, `front.png` and `inside.png` at 220×220, the existing glass layer where applicable, a placement guide, a 96×96 icon, an 8× assembled preview, and an 8× comparison against Neon Cyber, Fire Shrine, and Bathhouse. The approved v5 inside rooms, glass, and hook guides were copied into v6 because these revisions target the fronts.

The `tables/` folder has ImageGen front-face paintings for all eleven homes. Two-part tables have separate tray/base files. `all_tables_4x.png` shows the reduced previews together; each source also has its own game-size PNG and `_preview_8x.png`. Target widths and names are in `manifest.tsv` (the main pieces are 116 px wide, with narrower secondary parts). The sources are straight-on front faces, ready for the game's depth treatment.

The v6 home previews still show each home's v5 in-place table for alignment. Use the new `tables/` designs when implementing the revised tables. None of the files under `textures/` were replaced in this handoff.

## Export

The source artwork and targeted edits were created with ImageGen. The Swift scripts only crop, put the paintings on the existing pixel grid, separate the tall spirit opening, scale with nearest neighbour, and assemble previews:

```sh
CLANG_MODULE_CACHE_PATH=/private/tmp/hokora_swift_cache SWIFT_MODULE_CACHE_PATH=/private/tmp/hokora_swift_cache swift tools/art/hokora_v6_tables_export.swift
CLANG_MODULE_CACHE_PATH=/private/tmp/hokora_swift_cache SWIFT_MODULE_CACHE_PATH=/private/tmp/hokora_swift_cache swift tools/art/hokora_v6_homes_export.swift
```

The arcade source contains the painted joystick and buttons. The home export places its control panel below the reserved tall-spirit area while keeping the upper shelf ends available for ornaments.

## ImageGen direction

The shared prompt direction was: preserve each approved home's silhouette, palette, openings, and 220-grid pixel-art finish; change only the specific v6 brief details. For tables: a single transparent, straight-on front face with a strong dark outline and flat material shading, no visible top, side, ground shadow, or perspective.
