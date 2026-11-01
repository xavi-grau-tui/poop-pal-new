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
  then); at every send-off its ding and one ring of light come out of the bell, the bell and the
  lanterns swaying (the user: the bell says bye; part of every shrine's mechanics, never a slot);
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

## v6.1: feedback on the v6 delivery (2026-11-01)

The v6 delivery (`docs/mockups/hokora_homes/v6/`) was put in the game as a preview
(`docs/mockups/hokora_homes/v6_feedback/`: all eleven homes, and the six revised ones now vs v6).
Accepted by the user: Food Stall, Ruined Night, and the one-piece tables (Neon, Moon, Capsule,
Arcade coin box, Fire anvil, Bathhouse stool + bucket). Back to the designer: Moon (changed too much),
Capsule, Arcade, Golden, the two-part tables' trays, the tree stump, the bells.

The message, ready to send:

```
HOMES v6.1 – thank you! Some things are approved, a few go round once more

We put everything in the game (docs/mockups/hokora_homes/v6_feedback/: v6_all_homes_in_game.png,
and v6_before_after_in_game.png with today's version on the left and yours on the right).

APPROVED, going into the game now:
- Food Stall (the wheels and the shorter curtains fixed it), Ruined Night (the broken post above the
  roof is great).
- The one-piece tables: Neon, Moon, Capsule, Arcade coin box, Fire anvil, Bathhouse stool with its
  bucket. They look great at this size.

PLEASE REDO:

1. CAPSULE POD – the upper part is still the problem: it looks stretched and blocky, nearly the same
   as before. Keep the shape, the windows, the round opening and the colours, but redraw the whole
   top (the two handles and the roof band) properly at the 220 definition: crisp panel lines, clean
   curves, no stretched pixels, finished like the rest of the pod and like Neon.

2. ARCADE CABINET – the marquee with the KamiTomo logo is perfect, keep it. But the cabinet still
   looks like before, and it lost something important:
   - bring back the GAP in the middle of the control panel, between the joystick and the buttons
     (see arcade_v5_gap_between_controls.png: in v5 the panel had a recess in the middle). That's
     where the offering table stands; today the panel is one continuous shelf and the table ends up
     floating above it, inside the screen.
   - then give the whole cabinet a real quality pass, to the level of Neon, Fire and Bathhouse:
     cleaner outlines, better shaped sides and base, nicer details (speaker grille, coin door, trim).

3. GOLDEN TEMPLE – still to do from v6: taller (finer roof tiers rising higher) and much more detailed
   (ridge ornaments, brackets, carved panels, richer lacquer). Today it's almost the same as before.

4. THE TABLES' TRAYS – the two-part tables (Golden, Food Stall, Ruined Night) have thin flat trays on
   top that look strange and don't match the style. Please make each of them ONE solid piece, like
   the approved ones: a table with real volume (a clear top band, legs or a body), front face only.
   The forest keeps its own sanbo (no new forest table needed).

5. TREE HOLLOW STUMP – it shows its top (the growth rings seen from above). Front face only, please:
   the stump seen straight from the side (bark, roots, moss), its top just a flat edge. We add the
   top and the depth in the game.

6. THE BELLS (section 8 of docs/kami_homes_v6_brief.md, added after your copy): a bell and two beads
   per home, in its colours and materials, at the lanterns' definition, and a clear hook for it on
   every home (the Capsule and the Arcade have none).

7. MOON – it changed too much: the arch's inside, the pillars and the details are different now,
   and we loved the v5 one. Please go back to your v5 moon (docs/mockups/hokora_homes/v5/moon/)
   and change ONLY its width: slightly wider, using more of the template's width, everything else
   exactly as it was (same pillars, same arch, same inside, same details).

ORDER: the tables (4, 5) and the bells first, then Moon, Capsule, Arcade, Golden.
```
