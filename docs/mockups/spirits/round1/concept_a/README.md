# Hyakki Parade

## Pitch
Folklore yokai recast as a lively night parade: old objects, masks, charms and small household spirits, mischievous and gently spooky.

Three-point direction: silhouette first; one signature material/appendage per lineage; adults transform the body plan rather than merely scaling the kid.

## Palette by realm
Mountain: moss green, bark brown, weathered stone, crow charcoal.
Moon: indigo, mochi cream, silver.
Fox: vermilion, fried-tofu gold, cream.
Fire: ember red, soot plum, warm paper cream.
River: blue-grey, rain silver, muted river green.

## Prompt template
The canonical one-spirit master prompt for this concept is below. In the image studies we applied the brief's family-strip workflow: `[SPIRIT]` was replaced by a four-member family description, or by the five-baby / three-high-stage lineup, and the characters were then separated to their stable ids. Reference images were used for pixel density and finish only, not as source designs.

```text
Pixel art game sprite of a single original Japanese spirit creature, [SPIRIT].
A folklore yokai from the night parade of a hundred demons: masks, paper charms, old objects come alive, mischievous and slightly spooky, never gory.
Strict front view, facing the viewer, centred, full body, neutral calm idle pose, eyes open, mouth closed, standing on a flat baseline. One clear main body, separate readable appendages attached at clear joints, eyes clearly visible on the face.
Style: detailed 16-bit pixel art like a high-quality Japanese shrine game, crisp 1-pixel dark plum outline (#22101A), soft lit shading from the top left, muted slightly greyed palette, one small glowing accent. Bold simple silhouette readable at 64 pixels.
Plain transparent background, no ground, no cast shadow, no glow halo, no text, no frame.
```

## Files and processing
`source_strips/` contains the original transparent ImageGen family studies. Each requested `<id>.png` is isolated on an 80×80 canvas, reduced with nearest-neighbour and hard alpha for the game's art grid. `babies_px/` contains the five animation-layout proof sets. This is a concept-round review delivery; no game folders or runtime assets were changed.
