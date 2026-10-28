# RC Prix · Sky: plan

Levels 19–27, the plane through rings over the fields at noon. Same process as the Lagoon
(`docs/rcprix_art_process.md`): style pictures first, then 4× paintings over our guides, each piece
matched with its Garden counterpart, behind the dev launcher's RC ART switch (FX for effects).

## Kept (the user loves it)

- the ground far below: pale, hazy patchwork with cloud shadows (`_sky_floor`), PARALLAX 0.55;
- see-through clouds drifting between the plane and the ground;
- the wind streaks (`AirFx`) turning with the plane: redrawn on the 2 px grid, same behaviour.

## Redone by the designer (round 1: `BRIEF_ROUND_1.md`)

- [ ] style pictures (2–3), the user picks one
- [ ] rings: wide, 4 sizes (124, 112, 100, 88), plus gold at 124; tall = transposed; the game cuts the
      halves, recolours gold and grey. Levels' `ring_r` rounded to the nearest painted size (or the
      nearest image drawn at the level's own size: to decide when the art is in)
- [ ] drone pad: deck east / north (no direction), start-line strips, rotor pieces + 4 blade frames, lights
- [ ] the stand's cloud: 4 views × under / over, cut at the stand's pieces; the Garden stand with a light
      blue canopy (recoloured as the Lagoon's `stand_tex`)

## Stands (the user, 2026-10-28)

- [ ] more stands seen from the front: in the Sky prefer the front view; at the start line two from the
      front and one from behind
- [ ] later, the same for the Lagoon (many of its stands are seen from behind)

## Later rounds

- [ ] the ground: field squares, hedges / tree lines, river, decor (farms, villages, windmills); the game
      lays the patchwork, hazes it, adds cloud shadows
- [ ] drifting clouds: 3 sizes × 2 shapes (the game sets transparency)
- [ ] new: bird flocks lower down (own parallax, shadows), maybe a train / tractor, windmills
- [ ] hot-air balloons (levels 25–27), keep shape and colours
- [ ] game side: wind streaks, contrail, ring stars and guide sparkles on the 2 px grid; the rotors spun from
      the designer's frames; the old `_draw_cloud` stand kept behind the RC ART switch
