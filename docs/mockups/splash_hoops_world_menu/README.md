# Splash Hoops world-menu art handoff

For review and possible implementation in the New Shrine build. The app code and live Splash Hoops menus have not been changed.

## Files

- [Six world-menu concept screens](six_world_concepts.png): visual direction for Morning Lagoon, Sunset Drift, Pufferfish Reef, Night Lights, Storm, and Deep Sea.
- [Level-tile frame atlas](tile_frame_atlas.png): transparent sprite atlas with normal and selected frame concepts. Atlas is 3 columns × 4 rows: row 1 = normal Morning Lagoon / Sunset Drift / Pufferfish Reef; row 2 = normal Night Lights / Storm / Deep Sea; row 3 = selected versions of row 1; row 4 = selected versions of row 2. Frames have blank centers so the technical implementation can draw level numbers, stars, and locks in code.

The atlas is generated concept art and needs technical slicing, pixel-scale fitting, and a visual check at the actual 3×3 cell size before use. Its common selection treatment is a warm edge and small corner sparks; the world-specific palette and trim change per row. Locked-state desaturation/lock icon can stay code-driven.

## Shared design direction

- Keep the existing 3×3 geometry, level numbers, counters, and controls.
- Keep the selected-stage treatment consistent: slight lift, crisp pixel outline, restrained glow, and a few small sparks.
- Vary only palette, tile material, and small motifs to reflect each game's world. Keep tile centers calm so numbers/stars/locks remain readable.
- Keep world decoration secondary to the stage tiles and match the app's pixel scale and outline style.

## Open progression decision

The concept screens show each themed world background clearly. Before implementation, decide whether later worlds should:

1. appear only after completing the previous world; or
2. stay in the selector with a subdued undiscovered treatment (for example, muted underwater colors, haze, or silhouettes), revealing the full theme on unlock.

The art does not settle this progression behavior. Review it against the existing unlock rules and onboarding before exposing the world backgrounds.
