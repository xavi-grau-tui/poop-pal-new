# Future hokoras: brief for the designer (v3, 2026-10-30)

Round 2 of the plan in `docs/kami_collection_art.md` ("Next rounds with the designer"). v1 was only
in chat; v2 fixes its pixel size (it said 6 px, the hokora's grid is 8.4 px) and adds what round 1
taught: the ImageGen pieces came with pixels much finer than the hokora's (the user: "not
pixelated enough"), and separate generations don't line up as layers. Send it with
`docs/mockups/hokora_decor/reference_pixel_density.png` attached.

The message, ready to send (v3, 2026-10-30: the first concepts were reskins of the forest hokora,
same shape with other textures, and included the table, lanterns and bell; v3 asks for original
shapes and only the frame):

```
NEW HOMES – v3 (please read this before going on)

The first concepts are too close to the forest hokora: same shape, new textures. What we need is
different: each home is a NEW building with its own shape, and you only draw the empty FRAME.
The table, lanterns, bell, hanging pieces and shelf objects are separate pieces that the player
swaps in and out, so they must NOT be painted on the home. We add them in the game on top.

WHAT TO DRAW: ONLY THE EMPTY HOME
- the building: roof, walls/pillars, the floor it stands on, its base or ground
- the room behind the spirit (the dark inside)
That's all. Leave the spots for the movable pieces empty.

DO NOT DRAW
- the offering table
- the lanterns, the bell and its rope
- anything hanging from the beam, anything on the shelf spots
- the spirit, the sky, the background
(The default lantern and bell for each home come later, as separate pieces.)

BE ORIGINAL
Don't start from the forest hokora's picture. Change the silhouette: roof shape, proportions,
height, symmetry, what it's built from, what's around its base. A neon cyber shrine should be
recognisable as itself from its outline alone, even in black. Ideas per home are below, but the
shape is yours.

THE ONLY FIXED THINGS (so every movable piece fits every home)
Use guide_hanging.png and guide_shelf.png as the template:
1. The spirit's window: the red box must fit inside it, same place. The window itself can be any
   shape (round, arched, a screen, a hole in a trunk) as long as the red box is clear.
2. The floor line under the window: same height. The offering table stands there, centred.
3. Somewhere to hang things, marked with a dot on a separate guide layer:
   - two lantern hooks, one on each side of the window, around its top
   - the beam: a horizontal bar or edge above the window (blue box) for the middle hanging piece
   - the bell hook, on the left, outside the left lantern
4. Two shelf spots on the floor line, one on each side of the table (green boxes): flat, empty and
   not covered by the building.
These can be anything that fits the home (a metal bracket, a branch, a cable, a neon tube), as
long as the dots are there.

PIXEL SIZE (round 1's pieces had pixels much too small)
- A home is 110 art pixels wide on its 925 x 925 picture: 1 art pixel = 8.4 px. Zoom into
  textures/pet/shrine_new/front.png to see the size.
- Paint at any size, but check by shrinking to 110 px wide and back up with no smoothing. If it
  doesn't read, simplify: big shapes, a 1-pixel dark outline (#200010), light from the top left.
- Hard pixels only: no soft edges, no halos, no painted glow (the game makes the glow).
- Soft palette so the spirit stays the star; neon can be brighter, never pure.

STEP 1 NOW: one concept per home, in black silhouette + one coloured front each (110 px wide, or
exactly 4x), with the guide layer of dots. We check them in the game and choose.
STEP 2 LATER (for the chosen ones): the layers for the 3D tilt, all cut from the same picture so
they line up: front, inside, side, side_back, slab (the floor) and slab_side, land, a 96 x 96 icon.
And tell us which 2-3 materials the player could recolour (e.g. metal / neon / fabric).

THE HOMES
1. Neon Cyber Shrine – a tech shrine: stacked metal boxes, antennas, LED edges, cables; tall and
   narrow, maybe leaning. Teal and magenta.
2. Moon Shrine – a round stone pavilion on a small floating rock, craters, a crescent on top.
   Silver, lilac.
3. Golden Temple – a tiny multi-tier pagoda, gold leaf and black lacquer. Tall, prestigious.
4. Ruined Night Shrine – a collapsed, tilted shrine held together by roots and glowing mushrooms;
   asymmetric, half the roof gone.
5. Tree Hollow – no building: a hole in a huge trunk, a tiny wooden door frame, roots for the
   floor, a branch as the beam.
6. Ramen Stall (yatai) – a cart with wheels and a cloth awning; the awning rod is the beam, the
   counter is the floor.
7. Capsule Apartment – a white plastic sleeping pod with a round hatch, seen from the front.
8. Arcade Cabinet – an old upright arcade machine; the spirit lives in the screen, the marquee is
   the beam, the control panel is the floor.
9. Bathhouse (sento) – a tiled bath corner with a noren curtain and a little Mt Fuji mural.

Start with silhouettes for all nine (fast, small): it's the quickest way to see if they're
different enough.
```

## How homes fit the game (for us, not the designer)

Proposal, to confirm with the user:
- **Menu:** Home Decor gets a first section, **Homes**, before Lanterns, Hanging, Shelf and Colours.
  Each card is the home's 96 x 96 icon; picking one rebuilds the hokora with the boot's fade. The
  section shows only once a second home is owned (until then Home Decor looks as it does now).
- **Colours follow the home:** each home has its own presets (its 2-3 materials), so the Colours
  section lists that home's presets; the choice is remembered per home.
- **Decorations carry over:** lanterns, hanging and shelf pieces stay on when you change home. If
  the lantern is the old home's default, it becomes the new home's default.
- **Anchors per home in code:** each home's folder + its hook, beam, shelf and bell positions in
  `hokora_catalog.gd` (one entry per home), read by `shrine.gd` instead of today's constants.
- **Sources (the big rewards):** Cyber Shrine = RC Prix 2177's finale; Moon Shrine = 60 spirits in
  the Tomopedia; Ruined Night Shrine = all of Paper Sumo's seasons; Tree Hollow = 90 spirits;
  Ramen Stall = the Shop (the one expensive item, a coin sink for late game); Golden Temple = 120
  spirits (with Gold Leaf). Homes 7-9 later.
- **The first hokora** could come back as a secret home ("Old Hokora"); the gut stays dev-only.

## v4: the silhouettes approved, on to the full homes (2026-10-30)

The user loved the nine v3 silhouettes (`docs/mockups/hokora_homes/v3_silhouettes/`). The fit check
against the forest hokora and the fixed points is `docs/mockups/hokora_homes/v3_fit_check.png`.
The message sent next:

```
NEW HOMES – v4: the silhouettes are amazing, go ahead with all nine

We love them. Please turn all nine into full homes, keeping the shapes and the elements you drew
(the antennas, the crescent, the pagoda tiers, the broken roof, the branches, the wheels, the
hatch, the marquee, the bath). Now they must fit the game screen and the movable pieces.

FIT (see docs/mockups/hokora_homes/v3_fit_check.png)
The sheet lays each silhouette over the forest hokora (green) with the fixed points:
- SIZE: the forest hokora is the size limit. A branch, an antenna or an asymmetric bit may poke
  out a little, but the home's overall size is the same, nothing touches the edges of the canvas,
  and the sky must show around it (top corners and sides).
- RED BOX = the spirit's window: completely clear. The opening can be any shape around it.
- RED LINE = the floor line (row 83 of 110): the floor of the window and the two shelf spots sit
  exactly on it. The offering table stands there in the middle.
- GREEN BOXES = the shelf spots: empty, flat, on the floor line, not covered by pillars, walls,
  roots, rubble or wheels (something stands there in the game).
- BLUE BOX = the beam: a bar or edge across it, for the middle hanging piece; everything below
  it down to the red box stays clear.
- YELLOW DOTS = lantern hooks, ORANGE DOT = bell hook: there must be something to hang from at
  each dot (an eave, a bracket, a branch, a cable). You may move a hook a few pixels so it sits
  on your shape: just mark where it ends up.
Shape and details stay yours; asymmetry is welcome (the ruined shrine and the tree are great for
that), as long as the boxes and dots are respected.

PER HOME
1 Neon Cyber: the side pillars/modules stand in both shelf spots: move them outwards. The floor
  is below the line: raise it. Add brackets at the hooks.
2 Moon: the floor is a little above the line: lower it to row 83. Add brackets under the eaves for
  the hooks.
3 Golden: no floor at the shelf spots (the base is lower): add a terrace on the line. The base
  reaches the bottom of the canvas: make it shorter.
4 Ruined Night: the rubble fills the shelf spots: clear them. Something at the right hook.
5 Tree Hollow: too big (the crown leaves the canvas at the top left, roots and branch reach the
  edges): shrink it to the forest hokora's size. The hollow is narrower than the red box at the
  top corners: widen it. Clear the trunk ledges from the shelf spots.
6 Ramen Stall: a bit too wide (the awning rod touches the edges). The counter must be the floor
  line, with the shelf spots on it, not on the wheels.
7 Capsule: the pod's round ends touch the edges: narrower. Its floor is above the line: lower it.
8 Arcade: too tall (the cabinet goes down to the bottom edge): shorter. The control panel is the
  floor, on the line.
9 Bathhouse: the best fit already; check the floor sits on the line.

PIXEL SIZE (as before)
- 110 x 110 art pixels per home, hard pixels only, no soft edges or halos, no painted glow.
- 1-pixel dark outline #200010, light from the top left, soft palette (neon brighter, never pure).
- Deliver every layer at 110 x 110 (1 pixel = 1 art pixel) plus an 8x preview; we scale them into
  the game.

STILL DON'T DRAW: the offering table, lanterns, bell, hanging pieces, shelf objects, the spirit,
the sky. They're separate and come later.

WHAT TO DELIVER PER HOME (in docs/mockups/hokora_homes/<home>/)
1. front_colour: the whole home in colour, with the guide layer of boxes and dots as a separate file.
   Send each one as soon as it's done so we can try it in the game; go on to its layers unless we
   say otherwise.
2. The layers for the 3D tilt, all cut from that same coloured front so they line up pixel for
   pixel (never generated separately):
   - front: everything in front of the spirit (roof, pillars, frame)
   - inside: the back wall of the room behind the spirit
   - side and side_back: the side walls, seen when the phone tilts
   - floor and floor_side: the floor it stands on and its thickness
   - near: anything that sticks out towards the viewer (roots, rubble, wheels), if any
   - land: its ground patch or base (rock, grass, street)
   - icon: 96 x 96, the whole home, for the menu
3. A line saying which 2-3 materials the player could recolour (e.g. metal / neon / cable).

Order: 1 to 9 as numbered.
```

## v4 in the game (ON TRIAL, 2026-10-30)

The nine v4 homes are testable: Home Decor's first section, **Homes** (all owned with ALL UNLOCKED;
"Coming soon" otherwise). `tools/art/homes_install.py` turns the designer's 110 px layers into
`textures/pet/homes/<home>/` (front, inside, socket, side, side_back, icon) on the forest's 925 canvas;
`HokoraCatalog.HOMES` holds each home's bell and lantern hooks (from V4_HANDOFF.md) and its recess
colour; `Shrine._apply_home()` swaps them live. Not yet: colour presets per home, the homes' own
land, inner walls in the recess, the rain on their roofs, their own shelf spots.

The user's verdict on v4: the colours are what we want; the size on screen, the proportions and the
pixel density are not there yet. The density target: the decorations' (the lanterns', half the
forest's pixel, ~220 px across), the forest hokora possibly redone to match later. His ImageGen
paintings are only ~125 px of real detail across, so a finer home needs new paintings, not a
resample.

## v5 (2026-10-31)

The user's review of v4 in the game and the revision brief (all nine to the forest hokora's style
and height, a table per home, glass for the capsule and the arcade, a 10th Fire Shrine, the Tree
Hollow first as the pilot): `docs/kami_homes_v5_brief.md`, references in
`docs/mockups/hokora_homes/v5_brief/`. Code to add when v5 arrives: each home's own table (2D, its
3D sides made in code), its shelf ledges from guide.png, the glass layer with a moving shine.
