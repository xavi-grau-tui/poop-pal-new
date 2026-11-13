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

What the tool guarantees (don't undo these):
- easy = notes on the beats, normal = plus the eighths, hard = plus only the quick notes three
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
2. `.venv/bin/python tools/design/tunes_world.py` makes
   `textures/minigames/tunes/<world>/*.png` and `layout.json` (each layer's box, the lanes' x at
   the wall and on the bars, the tray's top). The tool, not the designer's art, is responsible for:
   - the three bars at ONE size (`BAR_W`), each centred on its lane (the user's rule);
   - the tray repainted with three equal lanes (`even_tray()`);
   - the soft lanes on the wall, straight above the bars;
   - the notes' outline and the glow.
   For a new world, copy the tool's world-1 settings into a table per world rather than a new script.
3. `scripts/tummy_tunes.gd` reads `layout.json`: `_layer()` places a layer, `_toys()` moves the
   toys on the beat, `_flash()` dips a bar on a press, `_strike()` lights it on a hit,
   `_set_lead()` dims the room while the instrument is silent. A note falls STRAIGHT down
   onto its bar (a path that followed the tray's slanted lane was refused by the user).
4. Run `--import`, take the four screens (section 3), look at them, show the user, then install.

Each world also needs its instrument's three wrong notes (a press that is not a hit): add the
instrument to `INSTRUMENTS` in `tools/audio/tune_wrong.py` and run it (the user confirmed it on world 1,
13 November 2026: the rule for all worlds; played at -11 dB, `WRONG_DB`).

Ask the next worlds' designer for **three bars of the same size and three lanes of the same
width**: world 1 needed the tool to even them out.

## 7. Traps met so far

| Trap | What to do |
|---|---|
| Two tweens on the same property fight (the room stayed dim) | keep the tween in a variable and `kill()` it before starting the next |
| A game's button handlers swallowed the level menu's presses | forward to `super` when `is_game_over or level_menu_open()` |
| `play_level()` called directly leaves the level menu drawn on top | in QA, start through the menu: press the main button, wait 1.6 s, release |
| The lead still sounded on a missed note | the lead is muted the moment a note is due and unhit, and comes back on a hit |
| Suno's tempo wanders and a pickup note shifts the grid | `tune_chart.py` follows the grid note by note and picks the best-fitting start (`best_grid()`) |
| Publishing the decisions page made a second page | always publish with `url` = the original (see the roadmap's file table) |
| The shrine's weather (rain, its sound) showed over a game | the shrine checks `GameScreen.is_active`; anything living on the pet screen must go quiet inside a game |
| A song played to its very end never showed its result (a stopped player's position reads 0) | never wait on `get_playback_position()` alone: also end on `not playing` and on a frame clock; test the END of a song with `tools/qa/tunes_end.gd` |
| A shell line waiting on the keyboard (`cat > file` with no input) hangs a whole run | never leave a command that reads stdin |
| The phone shows "unavailable" or is locked | retry the install; a failed launch only needs the user to open the app |
| The editor open during command-line Godot runs can corrupt its UID cache | if the editor floods "Unrecognized UID", restart it; the user accepts installs with the editor open |
