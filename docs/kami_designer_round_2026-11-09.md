# The designer's next round (2026-11-09): fixes, supports, a table, animations

Four small things, in one message. What we do ourselves stays out of it: the lanterns' light by
colour (glow, flicker, a pool of light on the wood), the suzu bell (cut from his painting), steam,
smoke and glows (code). The cases wait until we've looked at the Torii and Seigaiha pilot together.

References made for this round:
- `docs/kami_table_supports_brief.md` and `docs/mockups/hokora_homes/supports_brief/` (the floating
  tables in the game).
- `docs/mockups/hokora_decor/anim_brief/`: the ten ornaments' pictures as they are in the game
  (twelve files with the left versions), and `_all_bases.png` with all of them.
- `docs/mockups/spirits/dressup_pixel/pinwheel_frames_review_16x.png`: the two pinwheel frames.

The forest already has its own bell and beads (v8). Only its table is still the River Shrine's.

The message, ready to send:

```
NEXT ROUND – four small things (the order below = the order to send them)

Everything you sent is in the game or approved, thank you. This round is small: two dress-up fixes,
one or two table supports, a table for the forest, and frames for ten ornaments. Send each part as
soon as it's done.

1. DRESS-UP FIXES (docs/mockups/spirits/dressup_pixel/, new files, keep the old ones)
   a. PINWHEEL FRAME 1. Frame 2 (45 degrees) is great: keep it exactly as it is. Redraw frame 1 to
      match it: the same pointed folded blades, the same length, the same size, the same gold hub
      in the same place, only turned 45 degrees back. Today frame 1 is bigger, with square blades,
      so the spin would pulse in size (see pinwheel_frames_review_16x.png). Keep the alternating
      vermilion and cream. Files: pinwheel_frame1_0deg_16x16.png, its 4x, and a review of both
      frames side by side.
   b. KITSUNE MASK (worn at the side): a little pale and small today. Make it a touch bigger and
      stronger: a clean white face, clear red markings, a dark outline, readable ears. Same place
      on the head, same style as the other head items.

2. TABLE SUPPORTS (Tree Hollow needed, Golden Temple optional)
   The full brief is in docs/kami_table_supports_brief.md, with the picture in
   docs/mockups/hokora_homes/supports_brief/. In short: Tree Hollow's stump top hangs in the air,
   so draw the rest of the stump under it (a short trunk and roots spreading onto the hollow floor).
   For the Golden Temple, a low black and gold step under its table, only if you think it helps.
   Front face only, like the tables.

3. A TABLE FOR THE FOREST HOKORA
   The forest (our main shrine) still uses the River Shrine's stone table. Give it its own, in the
   forest's wood and moss, so it belongs to that home: for example a wooden offering stand (a sanbo,
   like the very first hokora's) or a mossy log bench. Same format as the v6 tables: front face only,
   flat, painted big and clean (we reduce it to about 116 x 44 px at the lanterns' definition), a
   strong dark outline that survives that size.
   Deliver to docs/mockups/hokora_homes/forest_table/: forest_table_front.png, and a preview at
   game size next to the forest home, at 8x.

4. ORNAMENT ANIMATIONS (10 pieces)
   These ornaments are in the game as stills. Bring them to life with small loops. Start from the
   picture that is in the game (copied to docs/mockups/hokora_decor/anim_brief/, all of them in
   _all_bases.png): the same canvas size, the same pixel size, the object in exactly the same place
   in every frame. Only the moving part changes. Don't draw any glow or light halo: the game adds
   the light.
   - lantern_firefly_jar: the fireflies drift and blink inside the jar (3 frames)
   - shelf_sleeping_squirrel: breathing, the body rising and falling, a small tail twitch (2-3)
   - shelf_goldfish: the fish swimming across the bowl and turning (4)
   - shelf_maneki and shelf_maneki_left: the raised paw waving (3)
   - shelf_neon_cat and shelf_neon_cat_left: the raised paw waving (3)
   - shelf_desk_fan: the blades spinning (3)
   - shelf_shishi_odoshi: the bamboo tipping down, pouring, and back up (4)
   - shelf_claw_toy: the claw going down and coming back up (4)
   - shelf_koma and shelf_koma_left: the top spinning, its bands and flowers turning (3)
   Names: <id>_0.png, <id>_1.png ... (frame 0 = today's picture, or as close to it as possible).
   Deliver to docs/mockups/hokora_decor/anim/<id>/, plus a preview of each loop at 8x (a strip of
   its frames, or a GIF).

Don't touch textures/, scenes/, scripts/ or data/. Nothing goes into the game until the user has
seen it.
```

## Our side, once approved

- Pinwheel: the 4-frame spin (frames 1 and 2, then the same two with vermilion and cream swapped).
- Kitsune mask, supports, forest table: cut and installed, checked in the game first.
- Ornament frames: into `textures/pet/shrine_new/decor/` as `<id>_N.png`. `Hokora.frames()` already
  plays them (`_decor_frames`), so only the files are needed. The pace may need tuning per piece.

## Feedback on the delivery (2026-11-09)

Review page: https://claude.ai/artifact/JaAicgcgs3KJpfDHHiodP9 (every loop at game pace). The user:
"we are on the right way"; the desk fan and the left neon cat are the weakest. The fox mask sits too
high at the side: we fit it lower and further over the head ourselves (head items are placed by code).

Approved: firefly jar, goldfish, sleeping squirrel, shishi-odoshi (we clean a stray line), kitsune
mask, Tree Hollow trunk (we tuck it under the stump top), Golden step, forest table.
Back: pinwheel frame 1, desk fan, claw machine, the four lucky cats, both koma tops. Why: they were
pixel edits on the old art (smears, stray strokes, half-moved parts); the good ones were repainted.

The message, ready to send:

```
ROUND 9 NOV – FEEDBACK. Good progress, thank you!

APPROVED, going into the game:
- firefly jar, goldfish, sleeping squirrel, shishi-odoshi (we clean the small stray line
  ourselves), kitsune mask, Tree Hollow trunk, Golden Temple step, forest table.

FIVE GO ROUND ONCE MORE. The frames that worked were the ones where the moving part was
repainted whole. The others were pixel edits on the old art, and that left smears, stray
strokes and half-moved parts. So for these:
- Repaint the moving part as a complete, clean shape in each frame (its own outline, its
  own shading), as if each frame were a still you'd approve on its own.
- No motion lines, streaks, smears or ghost pixels. The movement comes from the frames
  alone.
- Make the movement big enough to read at game size (a few pixels at least), with clear
  key poses.
- Frame 0 = today's picture, exactly. Everything that doesn't move stays pixel-identical.
- Check each loop at game size, playing at 0.3 s a frame (a GIF), before sending.

1. PINWHEEL FRAME 1: take frame 2 and turn its blades 45 degrees. The same fat pointed
   blades, the same length, the same amount of colour, the same hub. Today's frame 1 is
   thin strokes with outline tails, so the spin flickers between a thin X and a fat cross.
   Quick check: frame 1 and frame 2 should have about the same number of vermilion and
   cream pixels.

2. DESK FAN: keep the fan body and the cage exactly as today. Only the blades turn. Draw
   the same four pink blades round the mint hub in three positions (0, 30 and 60 degrees),
   each a clean blade shape with its outline, seen through the cage bars. No black or white
   streaks.

3. CLAW MACHINE: the claw goes clearly down towards the prizes and back up (4 frames). The
   cable gets longer, the claw stays the same clean shape (open going down, closed coming
   up if you like). No dark streaks beside it.

4. LUCKY CATS (maneki + left, neon + left): a real wave. Redraw the whole raised arm in each
   frame: up (today), bent forward at the wrist, and back. The paw moves several pixels.
   Nothing else on the cat changes, and no strokes or marks round the paw. The left neon cat
   is the weakest: start that one from its own frame 0 and repaint the arm cleanly.

5. KOMA TOPS (+ left): a top spinning fast looks still. Keep it upright and in place (no
   tilt or wobble), and make the spin show by moving its bands and flowers sideways round
   the body, frame to frame. The stick and the stand don't move. No stray pixels round it.

Same folders as before (docs/mockups/hokora_decor/anim/<id>/ and
docs/mockups/spirits/dressup_pixel/), new files with _v2, old ones kept. Don't touch
textures/, scenes/, scripts/ or data/.
```
