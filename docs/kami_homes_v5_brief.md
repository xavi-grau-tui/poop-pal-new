# New homes v5: brief for the designer (2026-10-31)

After the user tried the v4 homes in the game (`docs/kami_future_hokoras.md`, "v4 in the game"): the
colours and ideas are loved; every home must now be revised to the forest hokora's style, size and
fit, each gets its own offering table, and a 10th home is added for the Fire realm. References in
`docs/mockups/hokora_homes/v5_brief/`. Measurements are on the 110 grid of the 925 canvas; the
table's row 71 / floor row 81 are where the forest's sanbo really stands in the game (its picture
is drawn 4 rows lower and lifted by `Shrine._platform_offset()`).

The message, ready to send:

```
NEW HOMES v5 – revise all nine to the forest hokora's style, + a Fire home

We tried all nine in the game: the colours and the ideas are great, thank you! Now they must sit
in the game as if they were made together with the forest hokora. We want this super well done,
so please read everything and use the references in docs/mockups/hokora_homes/v5_brief/:
- v5_style_reference.png – the style to match (the forest hokora, close up)
- v5_template_8x.png / v5_template_110.png – where everything goes
- v5_notes_01 ... v5_notes_10 – one card per home: what to keep, change and add

1. STYLE: MATCH THE FOREST HOKORA (textures/pet/shrine_new/front.png)
Every home must look like it belongs to the same set as the forest hokora:
- Same pixel size: the home is 110 art pixels across (1 art pixel = 8.4 px on the 925 canvas).
- Same outline: 1 art pixel, dark plum #200010, around the outer edge of every shape. A home may
  use its own darkest tone instead where that reads better (the moon stone's softer outline is
  fine), but always a clean, continuous 1-pixel line.
- Inner lines in a dark tone of the material, never black.
- Same shading: 3-4 tones per material plus one highlight, light from the top left.
- Same kind of detail: 1-2 pixel marks for grain, cracks, moss, rivets, tiles. No noise, no
  dithering, no tiny detail that disappears at game size.
- Muted colours (neon may glow brighter, never pure). Hard pixels only: no soft edges, no halos,
  no painted glow (the game adds glows).
Each home keeps its own theme, materials and colours: only the drawing style is shared.
How: give ImageGen the forest hokora's front.png and v5_style_reference.png as references for
every picture. Then check yourself: put your home next to the forest hokora at 8x (make
compare_8x.png, the two side by side, and send it with the home). Same pixel size, same outline
weight, similar tones. If it doesn't look like a sibling, it isn't done.

2. SIZE AND FIT: TALLER, LIKE THE FOREST HOKORA (v5_template_8x.png)
- The home stays inside cols 4-106, rows 1-100 (the green box).
- TALLER: most homes look short and wide. The body itself (roof, top, crown, not only an antenna)
  reaches rows 2-8; the base meets the ground at rows 92-100 (the game's ground patch is below,
  don't go lower). About the forest hokora's height.
- The OPENING where the spirit lives (red box, cols 33-78, rows 36-81) stays clear. Only its top 6
  rows may be overlapped (a branch, an eave).
- FLOOR LINE: row 81. The spirit and the table stand on it.
- TABLE zone (purple): cols 42-69, rows 71-81. Leave it empty on the home; the table is its own file.
- SHELF LEDGES (green boxes): one each side, a flat surface whose top is between rows 78 and 86,
  at least 16 columns wide, with 18 rows free above it. They can be anything that fits the home
  (logs, a counter, a step, the inside of a side hole).
- HOOKS: the two lanterns hang at (25,30) and (85,30) and the bell rope at (11,30); the boxes under
  the dots are the space they take, keep it free. There must be something to hang from at each
  dot. You may move a hook a few pixels to sit on your shape: mark where it ends up.
- BEAM (blue): a bar or edge across the top of the opening for the middle hanging piece.

3. A TABLE FOR EACH HOME (new)
Each home gets its own offering table instead of the forest's sanbo (each card says which).
- Front view only, as a separate file; we make it 3D in the game.
- In place on the canvas: centred on col 55-56, standing on row 81, its top surface (where the food
  lands) at row 71, about 22-28 columns wide.
- Same style rules as the home.

4. GLASS (Capsule Pod and Arcade Cabinet only)
The glass is a separate layer: a flat, light, see-through pane (the ONLY place with partial
transparency, about 30-50%) with one or two 1-pixel highlight lines. We add a moving shine on it.

5. WHAT TO DELIVER PER HOME (docs/mockups/hokora_homes/v5/<home>/), all 110 x 110 unless said
- front.png: everything in front of the spirit (roof, walls, pillars, floor, ledges, logs,
  controls, wheels)
- inside.png: everything seen behind the spirit through any opening (back wall, the room; the
  capsule's tiny rooms behind its side holes)
- glass.png: only Capsule Pod and Arcade Cabinet
- table.png: the table alone, in place
- guide.png: the hooks (dots), the beam, the two shelf ledge tops, as you placed them
- icon.png: 96 x 96, the whole home with its table
- preview_8x.png: front + inside + glass + table together, 8x, no smoothing
- compare_8x.png: the preview next to the forest hokora at 8x
No side, side_back, floor, near or land layers this time: we build the 3D sides in the game.

6. THE HOMES (one card each)
01 Neon Cyber – keep its colours (the best palette), taller, style pass. Table: metal plinth with
   an LED edge.
02 Moon – wider (use cols 4-106) and a little taller; its softer outline is fine. Table: stone
   pedestal with a crescent.
03 Golden Temple – we like it; taller, more beautiful, a little different. Table: black lacquer
   sanbo with gold corners.
04 Ruined Night – VERY cool, just taller. Table: an old cracked sanbo propped on a stone.
05 Tree Hollow – THE example of adapting to the forest hokora. Taller; a branch across the upper
   part of the hole, slightly hiding the spirit from above; two logs coming out of the roots at
   table level, one each side, as the shelf ledges. Table: a tree stump with growth rings.
06 Food Stall (yatai) – taller, more beautiful wheels and a general look closer to the forest
   hokora (wood, outlines, weathering); shelf objects on the counter ends. Table: a lacquered
   serving board on a small block.
07 Capsule Pod – we love it. Taller; two OPEN side holes with glass (glass only there) and a tiny
   room visible behind each; the shelf objects stand INSIDE those holes, with space under the
   side bars. Table: a small white plastic side table.
08 Arcade Cabinet – the controls between the table and the shelf objects (a joystick on the left,
   buttons on the right); glass over the screen; a style pass. Table: a coin box with an INSERT
   COIN slot.
09 Bathhouse – taller, more defined, more visible decoration on the walls (tile patterns, a bigger
   Mt Fuji mural, a noren with a crest). Table: a wooden bath stool with a wooden bucket.
10 Fire Shrine (NEW, the home of the fire spirits) – a small shrine carved into dark volcanic
   rock, glowing magma cracks (flat bright pixels), an iron-tiled roof with upturned ends, a forge
   chimney (we add the embers), strings of dried red chilies, a hot iron bell. Charcoal, rust,
   ember orange, a little gold. Its own silhouette, recognisable in black. Table: a small anvil.

7. ORDER (one home first, so we get it right together)
Step 1: Tree Hollow, complete (all the files above), plus the Fire Shrine's SILHOUETTE.
We put the tree in the game and check it with you.
Step 2: once the tree is approved, the other eight in order, then the Fire Shrine in colour.
Send each home as soon as it's done.
```

## v5.1 correction: definition (2026-10-31, after the Tree Hollow pilot)

The user: the tree "still lacks some definition to have the same quality level as the hokora". Measured:
the forest hokora is not really on a 110 grid; its picture holds detail at about twice that (fine
highlight lines, specks, smooth outline curves at ~4 px of the 925 canvas), while the brief asked for
110 and the tree is exactly 110 (blockier, stair-stepped outlines). His same tree painting reduced at
220 already looks much closer (`v5_brief/v5_definition_whole.png`, `v5_definition_closeup.png`). The
second gap is the drawing: the forest outlines every shape inside it (each root strand, each moss
clump) and uses clean flat tones; the tree is soft gradients with few inner outlines.

The message, ready to send:

```
TREE HOLLOW – very close! One correction to the brief: the definition

The tree now really belongs with the forest hokora: shape, colours, branch, logs, the stump
table, all great. But next to the hokora it still looks a bit blocky and soft. Two reasons, and
the first one is our mistake in the brief:

1. THE GRID IS 220, NOT 110. The forest hokora actually has detail at twice the size we told you:
   fine highlight lines, specks, smooth outline curves. Please work on a 220 x 220 grid (1 pixel =
   4.2 px of the 925 canvas), the same density as your lanterns. Use v5_template_220.png (the same
   template, every number x2: opening cols 66-157, rows 72-163, floor row 162, table top row 142).
   Outlines are 2 pixels thick on the outer edge (like the forest's), inner lines 1-2 pixels.
   See v5_definition_whole.png and v5_definition_closeup.png: your same tree painting reduced to
   220 instead of 110 is already much closer.
2. OUTLINE THE SHAPES INSIDE, FLATTER TONES. The forest outlines every shape within it (each root
   strand, each moss clump, each tile) with the dark plum line, and paints each with 3-4 clean flat
   tones plus a highlight line. The tree's inside of the trunk is soft gradients with few lines:
   give the bark strands, the roots, the moss clumps and the logs their own outlines and clean
   tone steps.

Please redo the Tree Hollow this way (front, inside, table, guide at 220; icon stays 96 x 96;
compare_8x.png next to the forest at the same scale), and use the same 220 rules for all the
other homes and the Fire Shrine.
```

Our side: `tools/art/homes_install.py` takes any size (it scales to the 925 canvas); guide points at 220
are halved for `HokoraCatalog.HOMES`.

## v5.2 Tree Hollow fixes (2026-10-31, the user on the 220 tree: "looks amazing")

The front / inside were cut along a rectangle (`v5_brief/v5_tree_layers_now.png`), so the tilt slides
pieces of trunk and roots; the stump table floats. The message, ready to send:

```
TREE HOLLOW 220 – it looks amazing! A few fixes before the other homes

1. CUT THE FRONT ALONG THE REAL EDGE OF THE HOLLOW, NOT A RECTANGLE.
   Right now front.png has a square hole and inside.png is a rectangle that contains pieces of the
   trunk, the hollow's rim and the roots. In the game the inside slides deeper when the phone tilts,
   so those pieces get cut along straight lines. Rule:
   - front.png = EVERYTHING that is the tree: the trunk, the rim of the hollow, the branch over it,
     the ledges and ALL the roots (also the ones at the bottom of the hollow, in front of its floor).
     Its hole follows the hollow's own curved edge.
   - inside.png = ONLY the dark inside of the hollow (its back wall and floor), seen through that
     hole. No trunk, no rim, no roots in it.
   Check: put front.png over a bright colour; the only thing missing must be the dark hollow.
2. LEAVE A GAP between the roots / branches hanging over the opening: they shouldn't close it.
   Keep the inside of the hollow simple for now; we'll rearrange it later.
3. THE TABLE STANDS IN FRONT, ON A LOG. The stump table now floats (a disc on tiny legs). Give it
   a short cylinder log under the top, down to the floor line (row 162), like a real stump, still
   in the table zone (cols 84-139, top at row 142). It stands in front of everything else.

Same files as before (front, inside, table, guide at 220; compare_8x.png). Once the tree is
approved, the same rules apply to all the other homes.
```

Done on our side instead (the user: "can't we arrange it from here?"): `tools/art/homes_tech_fix.py`
recuts the tree along the hollow's real edge and stands the stump on a log, into
`docs/mockups/hokora_homes/v5_tech/tree_hollow/` (homes_install.py prefers v5_tech; the designer's
files untouched). Still for the designer: the gap between the roots hanging over the opening, and the
rule for the next homes (cut along the real edge; tables standing on the floor).

## v5.3 go-ahead for the other homes (2026-10-31, the tree approved; its root gap and inner walls later)

```
NEW HOMES – the Tree Hollow is approved, please go ahead with all the others

The Tree Hollow at 220 looks amazing in the game: it's now THE reference for all the homes
(docs/mockups/hokora_homes/v5/tree_hollow/). Please do the other eight plus the Fire Shrine in
colour, at the same quality. Everything in the v5 brief and the cards (v5_notes_01 ... 10) still
applies; these are the rules we learned with the tree:

1. 220 x 220 GRID (v5_template_220.png): 2-pixel outer outline, inner shapes outlined too, 3-4
   clean flat tones per material plus a highlight line, like the tree and the forest hokora.
2. CUT THE FRONT ALONG THE REAL EDGE OF THE OPENING, never a rectangle.
   - front.png = everything that is the home: walls, pillars, roof, the rim of the opening,
     ledges, roots, wheels, controls... Its hole follows the opening's own edge.
   - inside.png = only what's seen behind the spirit through that hole (the back wall, the room).
     Make it a bit bigger than the hole (about 16 pixels more on every side) so it can slide with
     the phone's tilt without showing a gap; the front covers the extra.
   - Check: front.png over a bright colour; the only thing missing must be the opening.
3. THE TABLE STANDS ON THE FLOOR: a solid base, log, legs or block that reaches the floor line
   (row 162), nothing floating. Top at row 142, within cols 84-139.
4. GLASS (Capsule Pod side holes, Arcade screen) as its own glass.png, as in the brief.
5. Hooks: draw something to hang from at each dot and mark them in guide.png.

ORDER: 01 Neon Cyber, 02 Moon, 03 Golden, 04 Ruined Night, 06 Food Stall, 07 Capsule Pod,
08 Arcade Cabinet, 09 Bathhouse, 10 Fire Shrine (colour, from its 220 silhouette).
Send each home as soon as it's done (front, inside, table, glass if any, guide, icon, preview_8x,
compare_8x next to the forest hokora). We'll put each one in the game as it arrives.
```
