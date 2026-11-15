# The handbook: how the work is done here (standards, recipes, traps)

Written 13 November 2026 so that anyone picking the project up (a person or any AI model) works the
same way. **What to do next** is in `docs/ideas_roadmap.md` (its top). **How to do it** is here.
When a rule here and an older note disagree, this file and the roadmap's top win.

## 1. Standing rules (the user's, never to be broken)

1. **Status comes from the code and git, never from notes.** Before saying "done" or "pending",
   look (`git log`, grep the code). Notes go stale; the spirits' art was once called unfinished
   from an old note when all 120 were in the game.
2. **Questions get answers, not actions.** "Would you merge?" is a question.
3. **Ask before merging to `main`.** Work happens on `yokai-migration`. `main` is the October
   game, tagged `gut-era-2026-10-19`.
4. **Never delete old art or old versions** from this repo: it is the history. A clean repo comes
   later, built to match the live app exactly.
5. **No `Co-Authored-By` or AI trailers** in commits or PRs.
6. **Show before installing.** A designer's delivery, or a new look, is shown to the user (a
   screenshot in `docs/mockups/...`) and gets their OK before it goes on the phone.
7. **The designer never touches** `textures/`, `scenes/`, `scripts/` or `data/`. Deliveries land in
   `docs/mockups/<topic>/roundN/` and we bring them into the game with a tool.
8. **The loop (docs/loop_v2.md) stays on paper** until the user says which piece to build.
9. **Document as you go**: a decision goes into its plan file's "Decided so far" table with the
   date and the user's words; the roadmap's top is updated when the picture changes.
10. Temporary files go in the session's scratch folder, never in the repo. Anything worth keeping
    (a QA script, a tool) is moved into `tools/`.

## 2. Writing style (docs, commits, replies)

- Plain words, full sentences, short. Lead with the answer. No invented labels.
- Commit message: what changed and why, in one or two sentences, quoting the user's words when the
  change answers them. Example: `Tomo Tunes: the hard chart keeps only the quick notes three
  buttons can play (the user: hard gets too hard)`.
- Code comments say WHY, with the date and the user's words when a rule came from them.
- Numbers in docs come from running the tool, never from memory.

## 3. The commands

All from the repo's root. `G=/Applications/Godot.app/Contents/MacOS/Godot`. Python is
`.venv/bin/python` (numpy, scipy, Pillow, soundfile).

| To do | Command |
|---|---|
| Import new files (after adding PNG / OGG) | `$G --headless --path . --import` |
| A screenshot of something | `$G --path . --windowed --always-on-top --resolution 1000x1000 --audio-driver Dummy res://tools/qa/preview.tscn -- script=<a .gd that extends Node2D> out=<png> wait=<s>` |
| Tomo Tunes' look, four screens | the same with `script=res://tools/qa/tunes_look.gd dir=<folder> wait=40` |
| Export for the phone | `$G --headless --path . --export-debug "iOS" "<scratch>/ios/Poop Pal.ipa"` |
| Build | in `<scratch>/ios`: `xcodebuild -project "Poop Pal.xcodeproj" -scheme "Poop Pal" -configuration Debug -destination "id=00008130-000115C03661001C" -derivedDataPath dd -allowProvisioningUpdates build` |
| Install, launch | `xcrun devicectl device install app --device 00008130-000115C03661001C <dd/Build/Products/.../*.app>` then `xcrun devicectl device process launch --device 00008130-000115C03661001C com.xavigrau.pooppal` |

**After every headless Godot run**: `find . -name ".recovery_mode_lock" -delete` (and the same file
in `~/Library/Application Support/Godot/app_userdata/KamiTomo/`), or the user's editor opens on a
"crashed" dialog. If a headless run re-saved `project.godot`, `git checkout project.godot` (only
if it held no real change).

**The phone.** Installs are debug builds: they open on the dev launcher (ALL UNLOCKED opens every
level). The signing is a free account: a profile lasts 7 days (the current one ends 14 November
2026, 12:08 UTC). After that, `xcodebuild ... clean build` makes a new one; if it says "No
Accounts", the user signs in at Xcode > Settings > Accounts, and may have to Trust the developer
again on the phone. A launch fails when the phone is locked: say so, the user opens the app.

## 4. The art standard

- **Paint big, show small.** Art is painted large (by the designer or a generator) and a tool
  makes the game's pixel version. Never hand-edit the small files: change the tool and rerun.
- **Pixel size**: the play area is 950 x 948. Tomo Tunes uses 1 art pixel = 3 screen pixels
  (the user chose 3 over 4). Textures are drawn with `TEXTURE_FILTER_NEAREST` at an integer scale.
- **Colours**: each layer keeps its own few colours (a room about 56, a toy or bar 20, a note 12).
  One shared palette for a whole scene was tried and turned pink and mint bars orange: don't.
- **Hard alpha** (no half-transparent edge pixels), premultiplied when shrinking so edges don't go dark.
- **Things the player must read** (notes, the pal) get a dark outline (74, 44, 32) and sit on top.
- **Living backgrounds**: everything in a scene that can move, moves a little, on the beat or on
  the action. Still pictures behind a game were rejected in October.
- **Check a look in the real game**, by screenshot, before showing it; open the PNG and look.

## 5. Recipe: a new Tomo Tunes song

The full reasons are in `docs/tomo_tunes.md` (sections 2, 6c, 6d).

1. The user makes takes in Suno from `docs/tomo_tunes_prompts.md` (made by
   `tools/audio/suno_prompts.py`: edit the table there, never the .md).
2. `.venv/bin/python tools/audio/tune_rate.py <takes.mp3>` rates how busy each tune is. The
   simplest good take is the world's song A, the busiest its D.
3. The user splits the chosen take (Get Stems, Split from Mix, the world's instrument) and puts
   the three MP3s in `sounds/tunes/incoming/<id>/` (e.g. `1C/`). The file with "(Without" in its
   name is the band, the other with "(" is the lead, the plain one is the full song. A full song
   named "... (1).mp3" confuses this: rename it.
4. `.venv/bin/python tools/audio/tune_chart.py <id> "<Title>"` writes
   `sounds/tunes/<id>/lead.ogg`, `backing.ogg` and `data/charts/tunes_<id>.json`. Read its report:
   - "% of the notes on the grid" under about 75: the tune is loose or the grid is off; listen to
     `incoming/<id>/check_normal.wav` (a click on every charted note).
   - "the beats are where the kick is" under 1.3x: check the easy chart by ear.
   - the band's level: it must end about 6 dB under the lead "as a phone hears it".
5. The count-in is 3 clicks and then the first note; the user says, song by song, when a song
   wants another count: put it in `COUNT_BEATS_OF` in `scripts/tummy_tunes.gd` (1B has 4).
6. Add the id to `TUNES` in `scripts/tummy_tunes.gd`, run `--import`, try it on the Mac, install.

   - "the grid follows": the tune's own notes, or "the band's beats" (taken when the tune is too
     busy or swung to give the grid itself; "swung: the off-beat at 0.65" is a jazzy tune).
   - "chords heard" (worlds 2 and 5): a first, rough detector. Listen to `check_hard.wav`.

What the tool guarantees (don't undo these):
- easy = notes on the beats (in a syncopated tune: the notes the tune lands on), normal = plus the eighths, hard = plus only the quick notes three
  buttons can play (`playable()`).
- A take is played WHOLE, with its own ending (the user: "we should play the full song"). Only a
  take more than 35 s over its slot's length (A 60 s, B 65, C 70, D 80) is cut, where a phrase
  ends, the band ringing out one more bar. So ask Suno for takes near the slot's length.
- The band is rebuilt for a phone speaker gently: sub-bass nearly out, the bass's harmonics
  added and levelled. No limiter, no boosted top band (that hissed and clipped).

Prompt lessons (all in `suno_prompts.py`'s comments): short tags, the instrument first, a trio,
"no new instruments, no build"; drums asked for "clear and present"; never "nursery rhyme" or
"cute" (kindergarten songs), never "lo-fi" or "catchy hook" (busy, syncopated tunes); say the
note values ("quarter notes and half notes only") and exclude syncopation in worlds 1-3.

## 6. Recipe: a Tomo Tunes world's art

World 1 (the toy xylophone) is the model. Its brief is `docs/tomo_tunes_art_brief.md`.

1. The designer delivers, in `docs/mockups/tomo_tunes/roundN/`, one mock-up and registered
   transparent layers on the same 1900 x 1896 canvas: `room`, the instrument's frame, three
   bars and their `_lit` twins, the toys (anything that moves on its own layer, like the cat's
   paw), four notes, plus a README.
2. Add the world to `WORLDS` in `tools/design/tunes_world.py` (its round's folder, the instrument's
   frame layer, what the designer called the bars, the other layers back to front, the faint ones).
   `.venv/bin/python tools/design/tunes_world.py` makes
   `textures/minigames/tunes/<world>/*.png` and `layout.json` (each layer's box, the lanes' x at
   the wall and on the bars, the tray's top). The tool, not the designer's art, is responsible for:
   - the three bars at ONE size (`BAR_W`), each centred on its lane (the user's rule);
   - the tray repainted with three equal lanes (`even_tray()`);
   - the soft lanes on the wall, straight above the bars;
   - the notes' outline and the glow.
   For a new world, copy the tool's world-1 settings into a table per world rather than a new script.
3. In `scripts/tummy_tunes.gd`: the instrument in `INSTRUMENT_OF`, each moving layer's pivot in
   `PIVOTS`, its movement in `_toys()` (a branch per world), and `HUD_SHIFT` if the art puts
   something under the score band (tell the designer to keep the top right corner free).
   The script reads `layout.json`: `_layer()` places a layer, `_toys()` moves the
   toys on the beat, `_flash()` dips a bar on a press, `_strike()` lights it on a hit,
   `_set_lead()` dims the room while the instrument is silent. A note falls STRAIGHT down
   onto its bar (a path that followed the tray's slanted lane was refused by the user).
4. Run `--import`, take the four screens (section 3), look at them, show the user, then install.

Each world also needs its instrument's three wrong notes (a press that is not a hit), cut from
the REAL instrument: add `'<instrument>': '<a song id>'` to `FROM_STEM` in
`tools/audio/tune_wrong.py`, the instrument to `INSTRUMENT_OF` in `tummy_tunes.gd`, and run it (the user confirmed it on world 1,
13 November 2026: the rule for all worlds; played at -11 dB, `WRONG_DB`).

Every world is its OWN PLACE with its OWN PALETTE, in the shared style (the user, on world 2's
first mock-up: "the aesthetics have to match first world but not be too similar, concepts may
vary"). Name the place and the palette in the brief, and check the instrument reads as itself.
Not every world is childish: world 1 is the nursery, and from world 2 on the rooms grow up with
the music (the user, on world 2's second mock-up: "not everything has to be childish").
A world's ornaments must match world 1's toys: about as big (35 to 60 art pixels), spread on BOTH
sides of the lanes, each moving plainly on the beat (hop, squash, swing). If the painting has
them small or bunched, re-place and enlarge them with `groups` in `WORLDS` (the tool scales from
the big painting, so bigger means more detail), and ask the next designer for it up front.

Ask the next worlds' designer for **three bars of the same size and three lanes of the same
width**: world 1 needed the tool to even them out.

## 6b. Recipe: measuring a game's difficulty

Never tune a level by feel alone: play it with the pretend players and read the table.

1. `python3 tools/qa/sweep.py <game>` plays the game's 54 levels headless and prints a table: each
   level's stars, the tries that failed, the seconds, how far under the par. Games: `hoops`, `maze`,
   `prix`, `prix2`, `spin` (add `human=1 runs=5` for the regular player), `sumo skill=1|2 runs=3`.
   1-4 minutes a run (Splash Hoops about 20: its player thinks ahead). `python3 tools/qa/sweep.py all
   keep=DIR` remakes `docs/difficulty_measured.md` (about two hours; with `keep=` a run already in DIR
   is read back, not played again).
2. Every game but Tomo Tunes has a CLEAN player (no mistakes of its own: a level's length, its par's
   margin, whether it can be finished at all) and a REGULAR one (`human=1`: the clean one with a
   person's mistakes on top, seeded by `seed=N`). The top of `tools/qa/sweep.py` says what each is.
   Each lives at the end of its game's script, under "QA (development only)", off unless tools/qa
   turns it on (`qa_autopilot`, `qa_human`, `qa_seed`; `tools/qa/capture.gd` sets them).
3. How the players were made, to copy for a new game: a physics game thinks ahead with its own rules
   (Splash Hoops: each press tried on a copy of the tank, `_qa_try`, with a guard in the few functions
   that would move something on screen); a board game follows a flow map to its goal (Tilt Maze:
   Dijkstra over a 14 px grid, walls and holes dear, `_qa_flow`); a fighting game gets rules by hand
   (Top Spin, the weakest: a floor). The regular player: the hand's late (a queue of what it wanted,
   read QA_REACT x K s late), lapses (the hand frozen 0.2-0.6 s), gentler corrections (or the late hand
   wobbles), more care after a mistake, and patience (it leans harder when the ball doesn't come).
   Keep the clean player's steering and only ADD mistakes: a first Pal Prix try that pressed like two
   buttons fell off every course.
4. A game prints one line per level when `qa_autopilot` is on (`print("QA race ...")`); `sweep.py`
   reads those lines (its `PATTERNS`). A new game or a new number: add the print and a pattern. Extra
   lines (`QA fall`, `QA hit`, `QA crash`, `QA out`) say why a try failed; never leave a debug print
   that fires every frame: `shoot.sh` stops at LINES_OUT lines and the run dies with it.
5. Seed the game's own randomness in QA (`seed(level * 31 + qa_seed)` when the player starts), or two
   runs of the same level differ (Paper Sumo isn't seeded yet: read three runs).
6. A level the clean player can't finish is a finding, not a player to fix: look at why first (Tilt
   Maze's magnets in Space pinned the pal for good: a game bug).
7. Set a level's marks with the contract's loop (`docs/games_pass.md`, section 3), then confirm on
   the phone. A pretend player is not calibrated: read its table as a shape (this world harder than
   that one), never as "a player fails 40% of the time".

## 7. Traps met so far

| Trap | What to do |
|---|---|
| Two tweens on the same property fight (the room stayed dim) | keep the tween in a variable and `kill()` it before starting the next |
| `var x := o.spin` with `o` from an untyped array (`tops.filter(...)`): "Cannot infer the type", and the whole script fails to load | give the type: `var x: float = o.spin` |
| Two QA runs at once: each `shoot.sh` backs up the test save and puts it back, and the two can cross | copy the save folder yourself before running several, and put it back at the end |
| A game's button handlers swallowed the level menu's presses | forward to `super` when `is_game_over or level_menu_open()` |
| `play_level()` called directly leaves the level menu drawn on top | in QA, start through the menu: press the main button, wait 1.6 s, release |
| The lead still sounded on a missed note | the lead is muted the moment a note is due and unhit, and comes back on a hit |
| Suno's tempo wanders and a pickup note shifts the grid | `tune_chart.py` follows the grid note by note and picks the best-fitting start (`best_grid()`) |
| Publishing the decisions page made a second page | always publish with `url` = the original (see the roadmap's file table) |
| The shrine's weather (rain, its sound) showed over a game | the shrine checks `GameScreen.is_active`; anything living on the pet screen must go quiet inside a game |
| A song played to its very end never showed its result (a stopped player's position reads 0) | never wait on `get_playback_position()` alone: also end on `not playing` and on a frame clock; test the END of a song with `tools/qa/tunes_end.gd` |
| A shell line waiting on the keyboard (`cat > file` with no input) hangs a whole run | never leave a command that reads stdin |
| A rule the model assumes but the game doesn't enforce (the meal wait, skipped by a send-off) | when a number comes from `pacing.py`, check the code enforces the rule behind it |
| The model and the game count different things (six games against seven) | after adding a game, a prize or a price, put it in `pacing.py` the same day |
| The phone shows "unavailable" or is locked | retry the install; a failed launch only needs the user to open the app |
| The editor open during command-line Godot runs can corrupt its UID cache | if the editor floods "Unrecognized UID", restart it; the user accepts installs with the editor open |
