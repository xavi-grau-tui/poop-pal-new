# Ornaments: brief for the designer (v3, round 3, 2026-10-31)

The big round after the homes v5 (`docs/kami_homes_v5_brief.md`), all ten homes now in the game.
v2 (the user, 2026-10-31): a matching set (lantern, shelf object, hanging piece) for each home, the
round-1 pieces all kept; shelf objects animate in frames (the fish swimming, the cat's paw), hanging
pieces swing (code), lanterns may have a frame animation of the fire inside. v3: one big message
for the designer's remaining budget, in priority order, with the lessons of round 1 (too much
resolution) and the homes (the 220 grid): sizes are in the 220 homes' pixel (4.2 px on the 925
canvas), the same pixel as the forest hokora's real detail.

```
ORNAMENTS + LAST FIXES (round 3) – a set for each home, animations, a few extras

All ten homes are in the game and they look amazing, thank you. This is a big round: please go
through it in the order below, sending each part as soon as it's done, so whatever gets finished
is usable.

THE ONE RULE: THE HOMES' PIXEL
Every ornament is drawn on the SAME pixel as the homes at 220 (v5_template_220.png): a lantern is
26 x 42 of those pixels, nothing finer. In round 1 many pieces had far too much resolution (they
looked like small paintings, not pixel art). Draw each file at exactly the size given below (1x),
1-pixel #200010 outline, inner shapes outlined, 3-4 flat tones per material plus a highlight line,
light from the top left, hard pixels only (no soft edges, halos, gradients or noise). Your round-1
lanterns are the reference: perfect. Check every file at its real size next to the home it goes
with (compare_8x).

HOW THEY MOVE IN THE GAME
- LANTERNS (the two side hooks): the game swings them and adds a glow. Add the light inside as
  2-3 frames (a flame flickering, a pulse, fireflies moving); the lantern's body stays still.
- SHELF OBJECTS (on the two ledges, low): a small loop of 2-4 frames when it makes sense (a fish
  swimming, a paw waving, steam rising).
- HANGING PIECE (the middle beam, high): the game swings it with the phone's tilt, don't draw the
  swing. A twinkle or a blink can be frames.
- Every frame has the object in exactly the same place; only the moving part changes. Names:
  <id>_0.png, <id>_1.png ... (a still piece: <id>.png). The game plays them slowly.

SIZES (art pixels, exactly this size)
- Lantern: 26 wide x 42 tall, its hook at the top middle.
- Shelf object: ONE object per file, up to 30 wide x 36 tall, standing on the bottom edge, facing
  right. The player can put a different object on each side; we mirror it for the left. If the
  mirror would look wrong (writing, a waving paw), also draw <id>_left_0.png ...
- Middle hanging piece: up to 90 wide x 37 tall, hung from both top corners. Keep its bottom third
  light: it sits just above the spirit.
- Icon: 96 x 96 per piece (its first frame, centred).
Each home's guide.png has its hooks, beam and ledges: make the set fit THAT home (the capsule's
shelf objects stand inside its side holes, the arcade's beside the controls).

PART 1 – A SET FOR EACH HOME (lantern / shelf object / hanging piece; * = animated)
- Tree Hollow: a firefly jar lantern, the fireflies moving* / a sleeping squirrel breathing* / a
  vine with hanging acorns and leaves
- Neon Cyber: a holographic cube lantern, its neon kanji flickering* / a little robot lucky cat
  waving its paw* / a dangling cable with blinking LED nodes and tiny holo charms*
- Moon: a crescent lantern with a pulsing moon-glow core* / the moon rabbit pounding mochi* / a
  string of little stars and crescents that twinkle*
- Golden Temple: a gold-leaf lantern with a phoenix, its flame flickering* / a golden phoenix
  statue opening its wings* / gold tassels with tiny bells
- Ruined Night: a broken stone lantern with a ghostly blue flame* / a cluster of glowing
  mushrooms pulsing* / a tattered rope with cobwebs and a spider going up and down*
- Food Stall: a red stall lantern (akachochin) with a flickering candle* / a steaming pot, its
  lid rattling* / wooden menu plaques on a string
- Capsule Pod: a small pod-shaped LED lamp blinking* / a tiny desk fan turning* / a string of
  instant photos and fairy lights twinkling*
- Arcade Cabinet: a lantern with a pixel heart beating inside* / a tiny claw-machine toy, the
  claw moving* / a string of tokens and plush keychains
- Bathhouse: a frosted bath lamp with steam swirling inside* / a rubber duck bobbing in a wooden
  bucket* / towels and washcloths on a line
- Fire Shrine: an iron cage lantern with a live flame* / a little fire salamander flicking its
  tail on a coal* / a chain of dried red chilies with small iron bells
Per home deliver: the three pieces (+ frames), their icons, and set_preview_8x.png = the home with
its set on it (both lanterns, the object on both ledges, the hanging piece), 8x, no smoothing.

PART 2 – ANIMATE ROUND 1 (same files, add the frames, redrawn at the homes' pixel if they were
too fine)
- shelf_goldfish: the fish swims round the bowl (4 frames)
- shelf_maneki and shelf_neon_cat: the paw waves (2-3 frames)
- shelf_candles: the flame flickers (3 frames)
- shelf_stone: the light inside flickers (2 frames)
- hang_pinwheels: the pinwheels turn (2-3 frames)
- hang_led: the lights blink in turn (3 frames)
- every round-1 lantern: the light inside (2-3 frames)
Round 1's shelf PAIRS: split into single objects (one per file) as above.

PART 3 – SMALL HOME FIXES
- Tree Hollow: open the gap between the hanging roots (the spirit's sides should show between
  them), same files as before.

PART 4 – MORE FREE PIECES (if there's still time; * = animated)
Shelf: tanuki statue · kokeshi doll* · shishi-odoshi bamboo fountain* · incense burner* · omikuji
box · frog statue · firefly jar* · sleeping cat*
Hanging: wisteria · dried persimmons · tanabata wish papers · omamori charms · origami stars

PART 5 – THE MENU SLIDES (after the rest): the brief is in docs/kami_menu_frames_brief.md
(start with its step 1: the slide frame + logo plate + stats plate in paper AND thin wood).

WHERE: docs/mockups/hokora_decor/round3/<home or round1>/ (one folder per home, one for round 1's
animations, one for the extras). ImageGen sources are fine as long as each file is checked at its
real size.
```

REJECTED by the user the same day, and taken back out of the game (the installed folder kept in
the scratchpad): the round-3 redraws are too small, too pixelated, without good outlines and don't
look like the round-1 lanterns; the hanging pieces hang too low. The mistake was in THIS brief: it
put ornaments on the homes' 220 pixel (26 x 42 for a lantern), 4x coarser than the hokora's own
red lantern (textures/pet/shrine_new/lantern.png: 108 x 176, drawn at the canvas' own pixel). The
round-1 ImageGen lanterns reduced straight to 108 x 176 look right. The two shelf slots, frame
playback and placement code stay (they show nothing until there's art).
INSTALLED AGAIN, APPROVED (the user on the in-game screenshots: "the way to go, the definition is
acceptable"): `tools/art/ornaments_from_sources.py` shrinks the designer's ImageGen paintings straight
to the red lantern's definition and look (2 x 2 pixels, the painting's edges in the red lantern's plum plus a thick 2-art-pixel plum outline, colours a little richer; lantern 108 x 176, shelf 156 x 176, hanging 420 x 112 still the older look, to redo: the user, "keep the aesthetics exactly like the original lanterns"), 97 stills:
round 3's sets and extras, round 1's lanterns as new `<id>_drawn` items ("Painted ...": the
recoloured red lanterns stay, the user), round 1's 15 hanging pieces and its shelf pairs split in
two. Stills only: animation frames at this definition still to make (edits on each still). The
hanging pieces hang higher (shrine.gd BEAM_AT / HOME_BEAM_AT).
What was installed first (rejected, for the record): `tools/art/ornaments_install.py` ->
`textures/pet/shrine_new/decor/` (x 925/220, nearest). The shelf is two slots (the user: option 1),
"shelf" (left ledge) and "shelf_right"; pieces face right, the right ledge mirrors them or uses
`<id>_left`. Frames loop (lanterns 260 ms, the right one a frame behind; shelf 300; hanging 400).
New items are "Coming soon" until their sources are decided (economy pillar). Left: the moon
rabbit's mallet frames, the hanging pieces' tilt swing (not built), round 1's other hanging pieces.

Notes for us:
- The bell rope is not a slot: its beads take the home's colour preset (no art needed).
- Single shelf objects mean the shelf slot becomes two (left, right) or one slot with a "both sides"
  choice; to decide with the user. Round 1's pairs are split into singles when converted.
- Code to add: frame cycling for lanterns (inside light, the glow on top), shelf objects and
  hanging pieces (`<id>_0.._n`; the hanging slot already swaps two frames every 650 ms); mirroring
  of shelf objects; per-side choice; shelves placed on each home's ledges (guide.png).
- A home's set: unlocked with or near its home (where each piece comes from: to design with the
  homes' sources, docs/kami_future_hokoras.md). Nothing deleted: round 1 stays as it is.
- After this round, if budget remains: the menu slides (`docs/kami_menu_frames_brief.md`, step 1).
