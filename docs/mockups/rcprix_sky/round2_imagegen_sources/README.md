# Sky ring and stand cloud source paintings

These ten transparent PNGs are the original ImageGen paintings for the Sky art pass. They are **conversion sources**, not game-grid sprites. Use `tools/art/rcprix_pixelate.py` and the matching files in `../guides/` to place and convert them. Keep the source PNGs intact.

| Source | Role |
| --- | --- |
| `ring_red_source.png` | Standard red and cream hoop, wide top-down view |
| `ring_gold_source.png` | Gold next-ring hoop, same design |
| `stand_cloud_front_under_source.png` | Front cloud body behind stand and audience |
| `stand_cloud_front_over_source.png` | Sparse foreground puffs in front of feet |
| `stand_cloud_back_under_source.png` | Rear cloud body behind stand and audience |
| `stand_cloud_back_over_source.png` | Sparse foreground puffs in front of rear feet |
| `stand_cloud_side_l_under_source.png` | Left-side cloud body |
| `stand_cloud_side_l_over_source.png` | Left-side foreground puffs |
| `stand_cloud_side_r_under_source.png` | Right-side cloud body, lit from screen top left |
| `stand_cloud_side_r_over_source.png` | Right-side foreground puffs |

The cloud body sources follow the approved `../style_samples/cloud_imagegen_study.png`: connected billows, white top-left caps, lavender creases and a shaded base. The `over` sources deliberately contain only a few separated puffs. Render in this order: `under`, stand/audience, `over`.

The ring sources follow `../guides/ring_124_guide_4x.png`: a thin flattened hoop with a large open center. The gold image was generated from the red image to keep its stripe layout. Keep the tube narrow when fitting to the guide; the source images contain extra transparent margin.

**Prompt set used:** built-in ImageGen, transparent background. The red ring prompt specified the ring guide's thin foreshortened geometry, alternating glossy red and bright cream stripes, top-left light, darker far inner wall, and no background or glow. The gold prompt changed only the red material to polished gold. Each `under` cloud prompt used the approved cloud study plus its view guide to make one continuous bank without the stand. Each `over` prompt used its corresponding under source and guide to make only sparse foreground puffs, leaving the stand visible. The left and right side sources were generated separately to keep lighting from screen top left.
