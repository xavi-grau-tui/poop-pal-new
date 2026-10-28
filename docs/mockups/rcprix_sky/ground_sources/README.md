# RC Prix Sky ground · ImageGen sources

These are high-resolution **source paintings**, ready for the technical team's conversion to the Sky ground grid described in [`../BRIEF_GROUND.md`](../BRIEF_GROUND.md). They are not game-grid sprites. All eight field sources are opaque, square and painted edge to edge. Rows are horizontal; rotate them to the diagonal field grid during conversion. The game adds its haze and cloud shadows.

## Fields · first delivery group

| File | Content |
| --- | --- |
| `field_wheat_source.png` | Ripe golden wheat; narrow horizontal rows |
| `field_young_green_crop_source.png` | Spring-green seedlings; narrow horizontal rows |
| `field_meadow_source.png` | Mixed grass and tiny cream, yellow and pink flowers |
| `field_ploughed_earth_source.png` | Warm brown clods and narrow horizontal furrows |
| `field_pasture_source.png` | Grass with a few tiny sheep |
| `field_orchard_source.png` | Small round fruit trees in straight rows |
| `field_vegetable_rows_source.png` | Leafy greens and cabbages in narrow horizontal rows |
| `field_hay_source.png` | Pale cut hay with a few small round bales |

The paintings use full colour and top-left light. Wheat, young crop, ploughed earth, vegetables and hay received a second ImageGen pass with tighter rows aimed at the brief's roughly 4 game px spacing. The technical conversion should assess row pitch on the phone; the high-resolution sources are not pixel-locked. Do not use these source files directly as tiling game textures without the normal conversion and edge treatment.

## Prompt set

Made with the built-in ImageGen tool. The shared prompt requested a perfectly straight-down, full-bleed square field painting, rich clustered pixel-art colour, calm even texture, no field edge, hedge, river, road, building, cloud shadow or diagonal rows. Each field prompt supplied its specific crop and palette. The rowed crops then used an edit prompt asking for approximately 30–32 thinner horizontal rows while preserving their material and lighting. Concept A and the first wheat painting were style references; their angled map layout was explicitly excluded.

Hedges, decor and river follow after the field conversion review, as ordered in the brief.
