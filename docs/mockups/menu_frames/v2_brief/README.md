# Menu slides v2: the slide frame only, at the approved homes' finish (2026-11-04)

The menu "slide" (diapositive) redrawn to match the approved homes (Fire, Bathhouse, Neon Cyber,
River Shrine), with EXACTLY today's measurements, in 4 alternative looks. Only the slide frame: the
inner labels (logo plate, stats plate, list cards, chips, dots, arrow) come later.

Why v1 was dropped (the user, 2026-11-01): "awful outlines, awful textures and inner labels".

## Files here
- `slide_template_402x394.png`: the exact template (mount, window border, opening, bottom band)
- `slide_template_annotated.png`: the same, explained, with the pixel grid
- `mask_outer.png`, `mask_window_border.png`, `mask_opening.png`: the shapes to match pixel for pixel
- `style_reference_approved_homes.png`: the finish to match (Fire, Bathhouse, Neon Cyber, River)
- `current_frames.png`: today's three tints; `current_*_menu.png`: the slide in today's menus

## Measurements (file pixels, the 402 x 394 file of textures/menus/diapositive1.png)
- Mount: x 11-391, y 5-389, the same rounded corners (= mask_outer.png)
- Window border: x 43-359, y 35-329, 8 file px thick (2 art pixels) (= mask_window_border.png)
- Window opening: x 51-351, y 43-321 (301 x 279), transparent (= mask_opening.png)
- Bottom band: y 330-390 (the legend, the page dots and the >> arrow sit there)
- 1 art pixel = 4 x 4 file pixels (the hokora pixel on screen)

## The 4 alternatives
- A Bathhouse: honey wood + cream plaster
- B River Shrine: a vermilion lacquer window border with gold corner caps
- C Stone: smooth warm-grey stone, the window carved in
- D Lacquer: a dark lacquer window border with one thin gold trim, a light mount

Delivery: `docs/mockups/menu_frames/v2/<a_bathhouse|b_river|c_stone|d_lacquer>/`.
