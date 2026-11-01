# Homes v6: fixes and the tables, brief for the designer (2026-11-01)

After the user saw all eleven homes in the game with their sets and skies
(`docs/mockups/hokora_homes/v6_brief/v6_all_homes_in_game.png`, one screen per home beside it).
Neon, Fire Shrine and Bathhouse are the reference: perfect in style, proportion and finish. The
others get small, targeted fixes only (same style), and every home gets a new table drawn as a
flat front face, at the lanterns' definition.

What we do ourselves, without the designer (the user and us, slight edits to the pictures):
- each home's ornament places: the shelf ledges at the table's level (so the tilt brings the
  objects a little in front, with depth), the lantern hooks and the beam where they read clearly;
- room for the evolved spirits: the tallest (kushikatsu, kodama, komainu) reach ~115 px of the
  925 canvas above the baby; the pal may come down a little, and the openings are checked with the
  tallest one;
- the bell rope's code: each home's bell.png / bead_1.png / bead_2.png when drawn (the forest's until
  then), its own tone (HOMES "bell_pitch"), and the bell rung hard with its sound (sounds/fx/suzu.wav)
  at every send-off (the user: the bell says bye; part of every shrine's mechanics, never a slot);
- the hanging pieces redone at the lanterns' look (thicker outline, sized to clear the tallest
  spirit).

The message, ready to send:

```
HOMES v6 – small fixes on six homes + new tables and bells for all

We put all eleven homes in the game with their lanterns, shelf objects and hanging pieces (see
docs/mockups/hokora_homes/v6_brief/: v6_all_homes_in_game.png and one screen per home). They look
great together. This round is SMALL, TARGETED FIXES, not redesigns: keep each home's style, colours,
shapes and ideas exactly as they are, and improve only what's listed.

THE REFERENCE: NEON, FIRE SHRINE AND BATHHOUSE
These three are perfect in every way: the look, the proportions, the finish, the detail. That's
the level for every home. Put each fixed home next to them at 8x before sending (compare_8x.png
with the three), and leave these three untouched.

Same rules as v5.1: the 220 grid (v5_template_220.png), 2-pixel outer outline, inner shapes
outlined, 3-4 flat tones plus a highlight, light from the top left, hard pixels. The opening where
the spirit lives (cols 66-157, rows 72-163) stays completely clear: evolved spirits are much taller
than the baby. Keep the hooks, beam and ledges where they are in your v5 guide.png unless a fix
below moves them (then mark it in the new guide.png).

1. MOON – slightly wider. Use the template's full width (cols 8-212) without changing anything else.

2. GOLDEN TEMPLE – taller and more detailed, to the level of Neon, Fire and Bathhouse. Same idea
   (a gold and black lacquer pagoda): a higher silhouette (finer roof tiers rising to rows 4-16),
   more gold detail (ridge ornaments, bracket work, carved panels) and richer lacquer shading.

3. ARCADE CABINET – the right direction, now make it better:
   - the controls: redraw them cleaner and better shaped (a clear joystick on the left, round
     buttons on the right, a proper control-panel slope);
   - the big marquee at the top: put the KamiTomo logo on it (textures/console/logo_kamitomo.png,
     redrawn to fit the marquee in the cabinet's style, lit like a marquee);
   - the ornaments: give the shelf objects a clear flat place to stand at the level of the table
     (for example the two ends of the control panel, flat on top, the joystick and buttons between
     them), and a bar or edge above the screen for the hanging piece.

4. RUINED NIGHT – slightly taller, and a little more finished overall (cleaner outlines and tone
   steps, like the reference three). On its most wrecked side, let the column come out a bit
   above the broken roof (a jagged broken post), so the hanging piece and the lantern can hang
   higher.

5. FOOD STALL (yatai) – the style is lovely, keep it; fix the proportions:
   - the wheels are too squashed: make them rounder and a little bigger, like real cart wheels;
   - less cloth in the upper part: the awning curtains take too much height. Shorter, and drawn
     at the same quality as the rest of the stall (they are softer and less detailed today).

6. CAPSULE POD – keep the idea, the shape, the windows and the round opening (all very cool), but
   the picture must be better: the upper part looks low-resolution and blocky. Redraw the whole pod
   at the full 220 definition, with clean outlines, crisp panel lines and smooth curves, finished
   like Neon.

7. TABLES (all eleven homes, the forest's sanbo included as the model) – NEW FORMAT
   We give the tables real depth in the game, like the forest's sanbo: we draw the front face and
   build the thickness and the top from it as the phone tilts. So:
   - FRONT FACE ONLY: the table seen perfectly straight on, flat. No top surface, no sides, no
     perspective, no shadow on the ground.
   - If the table is made of two parts on top of each other (a tray on a base, a board on a
     block), one file per part, each its own front face.
   - Paint it big and clean (about 1000 px wide, ImageGen is fine): we reduce it ourselves to the
     lanterns' definition (it ends up about 116 x 44 pixels on screen, the same pixel size as the
     lanterns, finer than the home's), so draw clear shapes with a strong dark outline that
     survive that size. Check it yourself reduced to 116 px wide.
   - The same table idea as v5 for each home (stump, coin box, anvil, bath stool...).
   - Files: tables/<home>_table_front.png (and <home>_tray_front.png / <home>_base_front.png for
     two-part tables), plus a preview of each reduced to 116 px wide, 8x.

8. A BELL FOR EACH HOME (new, all eleven except the forest, which keeps its own)
   The bell rope (the bell with its chain of beads, left of the left lantern) is part of every
   shrine: the game rings it when a spirit is sent off. Each home gets its own, in the home's colours
   and materials (the user), built like the forest's (textures/pet/shrine_new/bell.png and
   bead_red.png / bead_white.png):
   - bell.png: the bell alone, about 76 x 86, its hanging loop at the top middle;
   - bead_1.png and bead_2.png: two beads, about 48 x 68 each, that alternate down the chain (the
     game hangs five, 1-2-1-2-1, and swings them). Each must look right on its own and next to the
     other, top and bottom meeting cleanly.
   - Draw them at the lanterns' definition (the same pixel size as the lanterns, NOT the home's
     220 grid): thick dark outline, 3-4 flat tones plus a highlight. A big ImageGen painting is fine,
     we reduce it ourselves; check it reduced to those sizes.
   - Ideas: Neon a chrome bell with LED beads; Fire a hot iron bell with charred wood beads;
     Bathhouse a brass bell with wooden beads; Moon a pale stone bell with pearl beads; Golden a gold
     bell with black lacquer beads; Ruined a cracked, rusty bell on frayed rope knots; Tree Hollow a
     wooden bell with acorn beads; Food Stall a little brass bell with red and white paper beads;
     Capsule a white plastic bell with pastel beads; Arcade a bell with token beads.
   - Every home needs a clear place for it to hang, left of the left lantern (its hook at col 22,
     row 60 of the 220 grid, as in your guide.png) with room for the chain under it: on the Capsule and the Arcade there is none
     today, please add a small hook or bracket there.
   Files: <home>/bell.png, bead_1.png, bead_2.png, plus bell_preview_8x.png (the bell and five beads
   hanging, next to the home's lantern).

WHAT TO DELIVER (docs/mockups/hokora_homes/v6/<home>/)
- For the six homes: front.png, inside.png (and glass.png for Capsule and Arcade) at 220, guide.png
  if anything moved, icon.png, preview_8x.png, compare_8x.png (next to Neon, Fire, Bathhouse).
- For all eleven: the table files above.
- For the ten new homes: the bell files above.

ORDER: the tables and the bells first (small and quick, they unblock the game), then Golden Temple, Capsule Pod,
Arcade Cabinet, Food Stall, Ruined Night, Moon. Send each one as soon as it's done.
```
