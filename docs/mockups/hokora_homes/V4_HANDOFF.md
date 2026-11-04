# New Homes v4 — art handoff

The nine approved v3 silhouettes were painted as distinct empty homes using the built-in ImageGen tool. The final 110 × 110 art was sampled with nearest-neighbour scaling from those paintings. All exported PNGs have hard alpha (transparent or opaque). The 96 × 96 icons and 8× previews come from those final grids. **No game texture or code was replaced.**

Compare all homes together in [v4_all_nine_110_grid.png](v4_all_nine_110_grid.png). The original placement sheet is [v3_fit_check.png](v3_fit_check.png).

Each home folder contains:

- `front_colour.png`: assembled 110 × 110 colour front, including the recessed room behind the spirit.
- `front_colour_preview_8x.png`: the exact same pixels enlarged without smoothing, on a pale background.
- `guide_points_110.png`: separate transparent overlay marking the window, floor line, shelf boxes, hanging beam and attachment points. Its dots use the actual attachment positions listed below.
- `front.png`, `inside.png`, `side.png`, `side_back.png`, `floor.png`, `floor_side.png`, `near.png`, `land.png`: 110 × 110 layers cut by masks from the same assembled front. The central spirit box and both movable shelf zones are on `inside`, behind movable objects; they are not on a foreground layer. `near` holds protruding roots, rubble, wheels or base edges. The layer masks do not invent a new side-view painting.
- `icon.png`: 96 × 96 menu icon of the whole home.
- `front_colour_imagegen.png` and, where present, later `*_imagegen.png`: high-resolution ImageGen source paintings retained for future art edits.

| Home folder | Recolour materials | Bell hook | Lantern hooks |
| --- | --- | --- | --- |
| `neon_cyber/` | metal, LED trim, cable | (13,29) | (25,30), (85,30) |
| `moon/` | stone, lilac recess, crater moss | (9,43) | (29,33), (81,33) |
| `golden/` | gold leaf, lacquer, roof tile | (16,32) | (22,35), (88,35) |
| `ruined_night/` | aged wood, roof tile, moss | (11,30) | (25,30), (85,30) |
| `tree_hollow/` | bark, moss, leaves | (11,21) | (26,30), (86,32) |
| `ramen_stall/` | wood, awning cloth, trim | (11,30) | (25,30), (85,30) |
| `capsule_apartment/` | plastic shell, interior panel, teal trim | (14,31) | (25,30), (85,30) |
| `arcade_cabinet/` | cabinet paint, marquee trim, screen housing | (18,29) | (23,29), (82,30) |
| `bathhouse/` | tile, wood, waterline trim | (11,30) | (25,30), (85,30) |

**Fit review before installation:** the Moon and Tree Hollow bell points moved farther from the forest target than the brief's “few pixels” allowance. Their marked points attach to visible stone/wood, but the bell's in-game rope position needs a phone check. Several homes retain pillars or roots *behind* the reserved shelf zones in `inside`; movable shelf objects will draw in front of them, yet the visual fit should be reviewed with real objects. The game tilt may also need adjusted depth because `side` and `side_back` are cuts from frontal paintings, as specified, rather than new perspective drawings.

Prompt set: preserve each approved v3 silhouette and distinctive structure; paint an empty frame, dark recessed room, level floor at art row 83, clear spirit and movable-object zones, matching the forest hokora's coarse pixels and muted palette. Specific subjects were Neon Cyber gate, Moon pavilion, Golden pagoda, Ruined Night frame, Tree Hollow, wheeled Ramen Stall, Capsule pod, Arcade cabinet and Bathhouse. ImageGen made every painted element; the Swift tools in `tools/art/` only scale, mask, assemble and annotate those paintings.
