# Sofubi Gacha

## Pitch
A collectible festival capsule-toy cast: molded vinyl, odd proportions, bold silhouettes, a little kimo-kawaii and highly merch-ready.

Three-point direction: silhouette first; one signature material/appendage per lineage; adults transform the body plan rather than merely scaling the kid.

## Palette by realm
Mountain: moss vinyl, bark brown, stone grey.
Moon: indigo vinyl, silver and cream.
Fox: vermilion, tofu cream, soft gold.
Fire: ember red, soot plum, cream.
River: blue-grey, rain teal, muted cream.

## Prompt template
The canonical one-spirit master prompt for this concept is below. In the image studies we applied the brief's family-strip workflow: `[SPIRIT]` was replaced by a four-member family description, or by the five-baby / three-high-stage lineup, and the characters were then separated to their stable ids. Reference images were used for pixel density and finish only, not as source designs.

```text
Pixel art game sprite of a single original Japanese spirit creature, [SPIRIT].
A collectible soft-vinyl capsule toy spirit from a Japanese festival gacha machine: chunky simple forms, odd proportions, cute and a little gross (kimo-kawaii), very few details.
Strict front view, facing the viewer, centred, full body, neutral calm idle pose, eyes open, mouth closed, standing on a flat baseline. One clear main body, separate readable appendages attached at clear joints, eyes clearly visible on the face.
Style: detailed 16-bit pixel art like a high-quality Japanese shrine game, crisp 1-pixel dark plum outline (#22101A), soft lit shading from the top left, muted slightly greyed palette, one small glowing accent. Bold simple silhouette readable at 64 pixels.
Plain transparent background, no ground, no cast shadow, no glow halo, no text, no frame.
```

## Files and processing
`source_strips/` contains the original transparent ImageGen family studies. Each requested `<id>.png` is isolated on an 80×80 canvas, reduced with nearest-neighbour and hard alpha for the game's art grid. `babies_px/` contains the five animation-layout proof sets. This is a concept-round review delivery; no game folders or runtime assets were changed.
