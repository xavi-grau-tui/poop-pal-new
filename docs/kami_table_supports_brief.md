# Table supports: brief for the designer (2026-11-08)

The user (2026-11-08): "some tables appear like floating, we should add an element to join them to
the shrine". Since d47e1eae the offering and the spirit sit exactly on every home's table. That
makes it easy to see which tables don't stand on anything.

Checked straight on in the game, all eleven homes:
- **Tree Hollow** floats. Its stump top hangs in the middle of the hollow, with nothing under it.
- **Golden Temple** stands on the edge of the floor, but its thin legs over the black floor make it
  look like it hovers. Optional.
- The others stand on something: the Food Stall's bench on the cart's beam, the Capsule's table in
  the opening's rim, the slabs on their rocks and ledges.

The support is a second part under the table, like the old two-part tables (a tray on a base): one
front face that we stack under the table and give depth as the phone tilts.

Reference: `docs/mockups/hokora_homes/supports_brief/` holds `floating_tables_in_game.png` (the two
homes in the game today, with the gap marked) and each table now at 4x.

The message, ready to send:

```
TABLE SUPPORTS – one small piece (two at most), quick

Since the last update, the offering and the spirit sit exactly on each home's table. That shows one
table that floats: TREE HOLLOW's stump top hangs in the air in the middle of the hollow. Please draw
the piece that joins it to the floor. See docs/mockups/hokora_homes/supports_brief/
floating_tables_in_game.png (red box = where it goes) and tree_hollow_table_now_4x.png (today's
stump top).

1. TREE HOLLOW – THE STUMP'S TRUNK AND ROOTS (needed)
   The rest of the stump under today's stump top: a short trunk with bark, its roots spreading onto
   the hollow floor, a little moss like the top. Same wood, colours and outline as the stump top, so
   the two read as one stump.
   - Its top edge meets the underside of the stump top exactly: about as wide as the stump top's
     bottom edge, no gap, no overlap.
   - Height: from under the stump top to the hollow floor, about 40% of the stump top's width (in
     the game: about 95 px wide at the top, the roots up to about 116 px at the floor, about 42 px
     tall, at the lanterns' and tables' definition).
   - Don't redraw the stump top: it stays as it is.

2. GOLDEN TEMPLE – A LOW DAIS (optional, if you think it helps)
   A low black lacquer and gold step under the table, a little wider than the table (about 124 x 12
   px in the game), so its feet stand on something instead of on the dark floor. Same gold and
   lacquer as the table. If you think the table already looks right, skip it and tell us.

SAME FORMAT AS THE TABLES
- FRONT FACE ONLY: seen perfectly straight on, flat. No top surface, no sides, no perspective, no
  shadow on the ground. We build the depth in the game.
- Paint it big and clean (ImageGen is fine). We reduce it ourselves to the tables' definition, so
  use clear shapes and a strong dark outline that survive that size. Check it reduced to the sizes
  above.

WHAT TO DELIVER (docs/mockups/hokora_homes/supports/<home>/)
- <home>_base_front.png: the support alone, transparent background (your big version).
- preview_8x.png: the support reduced to its game size, with today's table on top of it, at 8x.

Don't touch textures/, scenes/, scripts/ or data/. Nothing goes into the game until the user has
seen it.
```

## Our side, once approved

- Cut it at the tables' definition and install it as `textures/pet/homes/<home>/table_base.png`.
- shrine.gd draws it under the table, at the table's depth, with the same built sides as the table.
  `_table_top()` keeps reading table.png, so the offering doesn't move.
