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

## Hedges, landmarks and river · second delivery group

These are **transparent high-resolution ImageGen paintings**. Keep the hedge and river strips horizontal in source space. The game-side conversion sets their final pixel size, cuts the strips, turns them to the diagonal grid, and applies the same haze used for the accepted fields.

| File | Content | Target game size or use |
| --- | --- | --- |
| `hedge_low_source.png` | Low leafy hedge | Horizontal strip, about 3 px thick |
| `hedge_tree_line_source.png` | Row of small round trees | Horizontal strip, crowns about 4–6 px |
| `farmhouse_barn_source.png` | Farmhouse, barn and yard | 12 × 9 px |
| `village_source.png` | Cluster of roofs around a small square | 32 × 24 px |
| `church_source.png` | Cross-shaped roof and tower | 10 × 12 px |
| `windmill_tower_source.png` | Standing stone tower, cap and front spindle, 3/4 view from south | 12 × 18 px |
| `windmill_sails_source.png` | Upright detached four-arm sails; rotate around the central hub | 22 × 22 px |
| `stone_bridge_source.png` | Raised stone bridge with deck and two arches, steep diagonal up to right | 14 × 34 px |
| `pond_source.png` | Small irregular pond with grassy edge | 16 × 10 px |
| `haystacks_source.png` | Three golden hay bales | 10 × 6 px |
| `copse_source.png` | Small group of round trees | 24 × 18 px |
| `river_source.png` | Straight blue river with sandy and grassy banks | Horizontal strip, about 4:1 |

The new images were generated individually with the built-in ImageGen tool, using the accepted field paintings as style references. Their shared prompt specified clustered pixel-art colour, full saturation, top-left lighting and a plain transparent background. The river prompt specified a continuous left-to-right strip with banks on both sides. All are **source paintings**, not pixel-locked game sprites.

### Revised landmarks

The windmill tower, detached sails and bridge were repainted with ImageGen after the ground was reviewed in game. The windmill is now viewed from the south at a slight elevation, with its spindle on the front below the cap; place the sail hub there and rotate the sail sprite around its own centre. The bridge runs from lower left toward upper right, about 70° above horizontal, so its deck crosses the separately drawn horizontal river while the arches show on its lower-right face. These three files **replace the earlier source paintings**; the target game sizes are in the table above. The bridge's tall image contains transparent margins and should be fitted by its painted bounds, preserving its steep angle.
