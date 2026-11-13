# Tomo Tunes: the plan (12 November 2026)

THE APPROACH IS DECIDED (the user, 2026-11-12, after the pilot on the phone: "pretty cool", "the approach
works very well"); the game around it is still to build. The music game (the code's `tummy_tunes.gd`), the sixth game, Caffeinated's FOCUS. This
is how it plays, the six worlds, the songs, how a Suno song becomes a level, and the build order.
The prompts are in `docs/tomo_tunes_prompts.md` (made by `tools/audio/suno_prompts.py`).

## 0. The one idea

**You play the world's toy instrument, and the band plays on.** Every note that falls is a note
that instrument plays in the song. Hit it and you hear it. Miss it and the instrument goes silent
until your next hit, while the bass and the drums carry on. That is what makes a "guitar hero"
game make sense, and everything below serves it:

1. **The notes are the lead's notes**, never the bass or the drums behind it.
2. **The lanes are pitch**: left = low, middle = mid, right = high. The thumbs draw the tune. (The
   Taiko world: left = the deep drum, middle = the rim, right = the small drum.)
3. **A miss is heard**, not just scored: the instrument drops out.
4. **The same phrase is the same pattern** every time it returns, so a song can be learnt.
5. **Easy, normal and hard are the same tune**, thinned: easy plays its notes on the beat, normal
   adds the ones between, hard is everything. What you don't play, the instrument plays for you
   while you're hitting.

## 1. Where it stands

Since 12 November: the pilot song 1A plays in the game the new way (section 6b). Before that, a
prototype with one song: three lanes under the device's three buttons, notes falling to
a line, PERFECT within 60 ms and GOOD within 130, a groove meter that fails the song when empty,
a combo, and sync to the song's real playback position. Its chart comes from
`tools/design/rhythm_chart.py`, which finds where sounds start in three bands of the WHOLE mix
(low, mid, high) and makes those the lanes. So today you press on the kick and the bass as much
as on the tune, and nothing changes in the sound when you miss. No levels, no stars, no holds.

## 2. How a Suno song becomes a level

Suno can now pull one instrument out of a finished song and give back that instrument plus
"everything else" as two files (Get Stems, **Split from Mix**; Pro plan, 10 credits). That is
exactly the pair this game needs.

| Step | Who | What |
|---|---|---|
| 1 | you | Generate the song from its prompt (Instrumental on). Keep the take that passes the ear check below. |
| 2 | you | Get Stems, Split from Mix, ask for the world's instrument. Download the stem, the "everything else" file and the full song. |
| 3 | you | Drop the three files in `sounds/tunes/incoming/<world><letter>/` (e.g. `1A/`). |
| 4 | me | `.venv/bin/python tools/audio/tune_chart.py 1A "Wooden Steps"`: finds every note of the lead stem (its start, its pitch, its length), follows the beat grid note by note, sorts the notes into easy / normal / hard, rebuilds the band so a phone can hear it (section 2b), and writes `sounds/tunes/<id>/lead.ogg`, `backing.ogg` and `data/charts/tunes_<id>.json`. (Cutting to 60-75 s on bar lines: to add when a take runs longer.) |
| 5 | me | The tool also renders a check file: the song with a click on every charted note. If the clicks sit on the tune, the level is right before it is ever played. |
| 6 | game | Plays the two files as one synchronized stream (Godot's `AudioStreamSynchronized`, in 4.3+; we're on 4.4) and turns the lead's volume down on a miss. |

**The plan is Pro** (the user, 2026-11-12), so Split from Mix is the route. With Premier there is a cleaner route to try if the
splits bleed: generate the backing alone, then add the lead as its own stem in Studio, in the
song's tempo and key. Without usable stems the fallback is one file: the chart is still read from
the lead's register, and a miss ducks the whole song and plays a dull clack.

### 2b. The band has to be heard on a phone

Found on the phone with 1A (the user, twice: "barely hearable"). Suno's "everything else" file was
99% under 250 Hz, bass and kick, which a phone speaker hardly plays; and the song itself had its
drums 26 dB under the xylophone, because the prompt asked for "soft drums, minimal". Raising the
level did not help. Two fixes:

- **The prompt** now asks for a band that is present: a punchy kick, a crisp snare on 2 and 4, a
  bright shaker on every eighth (all things a phone speaker plays). To check on the next song: the
  lead must still be the only melody.
- **The tool helps the band, gently** (`balance()` in `tune_chart.py`). The first try rebuilt it
  hard (a driven bass, the full song's top band gated to the beats and raised 11 times, a limiter):
  on the phone it hissed and sounded clipped (the user). Now it only adds the bass's own 2nd and
  3rd harmonics, clean, so the bass line is heard on a phone, turns the sub-bass down, and brings
  both files down together until their sum has headroom: no noise, no limiter. 1A's band sits
  10 dB under the lead on a phone (Suno's stem: 20). The real fix is the prompt above; a song
  whose band is still thin after it should be made again, not repaired.

**The ear check for a take** (30 seconds, before spending a split):
- The beat is steady from the first second to the last. Tap along: you never have to adjust.
- Exactly one instrument plays the tune, and you can sing it back.
- The lead is dry: no echo trailing after its notes.
- Nothing stops: no break, no drop, no long intro. At least 75 s of the same music.

**What the tool then reports** (so a bad take is refused by numbers, not by feel): the measured
BPM and its drift, the share of the lead's notes that sit on the grid (wanted: 95% or more), the
notes per second of each chart, the lead's lowest and highest note, any silence longer than two
bars.

**The pilot.** One song first: 1A, Wooden Steps. Its stems decide what changes in the other 23
prompts (does Suno isolate a toy xylophone cleanly, is the lead dry enough, does it hold its
tempo). Nothing else is generated until 1A has been played on the phone.

## 3. The six worlds: an instrument and one new thing each

| # | World | The new thing | BPM | What the player does |
|---|---|---|---|---|
| 1 | Toy Xylophone | single notes on the beat | 92-104 | learns that the lanes are low, middle, high |
| 2 | Toy Piano | chords | 100-110 | two buttons at once on the accents |
| 3 | Toy Ocarina | long notes | 96-108 | holds the button for as long as the note sounds: a breath |
| 4 | Music Box | off-beats | 88-100 | plays between the beats (slower, because it is the hard one to feel) |
| 5 | Star Stage (the pixel synth, the toy band behind it) | everything, faster | 112-124 | the finale is the Star Song: Stardust Sugar |
| 6 | Festival Taiko | rolls and speed | 120-132 | the masters' world: the three drums are the three buttons; the finale gives the Taiko case |

**One change from the October skeleton, to confirm.** It had Toy Drums as world 3 ("holds and
rolls") and left world 6 open (Toy Trumpet or The Tummy). Here a wind instrument takes 3 (the Toy Ocarina: the user didn't love the trumpet, 2026-11-12; a
melodica is the alternative) and the
drums become world 6 as the Festival Taiko. The reasons: a held note is a breath, so it belongs
to a wind instrument; rolls and speed are the hardest thing and belong to the masters' world; the
Taiko case and the taiko headband are already the game's planned prizes; and a drum lead is the
stem Suno separates best. The Tummy (the spirit's own voice as the lead) stays as an idea for the
encores.

The games' rule holds: levels 7-8 of a world mix in the world before's thing (world 3's hard
charts have chords, and so on), so by the Star Stage nothing is new, only together.

**The look** (the suite's rules, for its own pass): the instrument is the toy and the playfield.
The three targets are the xylophone's three bars, three piano keys, the ocarina's three holes,
the music box's comb, three stage pads, the three drums. One place per world with its light, the
spirit dead centre with its headphones, bar lines falling with the notes so the beat is seen.

## 4. A world's nine levels

Four songs per world: A, B, C and the showpiece D. 24 songs.

| Level | Song, chart | The 3-6-9 rhythm |
|---|---|---|
| 1, 2, 3 | A, B, C on easy | 3: the golden note (a small secret) |
| 4, 5, 6 | A, B, C on normal | 6: the encore (the world's secret) |
| 7, 8 | A, B on hard, with the world before's thing | |
| 9 | D, the showpiece | the finale: its prize on the first clear |

- **Stars.** 1 = the song finished with the groove alive. 2 = 85% of the notes. 3 = 95%.
- **FOCUS** (the Caffeinated drink's power): the timing windows grow by a third (PERFECT 60 to
  80 ms, GOOD 130 to 170) and a stray press costs no groove. Tuned so that 95% takes a regular
  player 2-3 tries with it and about 1 try in 8 without (`docs/games_pass.md`).
- **The golden note** shows only while FOCUS is on: one glowing note in level 3. Hit it: coins or
  a sticker. **The encore**: level 6 has five golden notes; all five and the band plays eight more
  bars with the world's secret prize at the end. Worlds 1-3 want the plain drink, 4-6 the better.
- **Failing** stays as built: the groove empty stops the song. Retry is one press.
- A level is 60-75 s. Notes per second: easy 1.5-2.2 (the beat), normal up to 3-4, hard up to 6.

## 5. The charts: from the lead's notes to the three buttons

- **Lane = pitch.** The song's notes are split in three equal groups by pitch: the low third is
  the left lane, the middle third the middle, the high third the right. One pitch is always one
  lane. Fast runs inside one group are spread to the neighbour lane in the direction the tune
  moves, so no thumb has to hammer one button at speed.
- **A long note** (a beat or more in the stem) is a hold: a ribbon behind the note. The start is
  judged like any note; letting go early loses the rest of the ribbon, not the note.
- **A chord**: the lead's loudest accents on a strong beat become two lanes at once (the low and
  the high one), from world 2 on.
- **A roll** (world 6): a burst of fast hits on one drum is a hold that the game plays as a roll.
- **Easy / normal / hard**: the notes on the beats; plus the eighths; plus everything.
- Every chart is checked by ear with the click file before it goes in (step 5 above).

## 6. Build order

| # | Step | Size | Needs |
|---|---|---|---|
| 1 | The pilot song through the pipeline: `tune_chart.py`, the click file | M | the 1A stems |
| 2 | The engine: two synchronized files, the lead muted on a miss, the chart with lengths, holds, chords | M | step 1 |
| 3 | Levels: the level menu, the 9-level table, stars, the best accuracy, FOCUS and its HUD icon | S | the games pass's shared work (the power) |
| 4 | World 1 whole, with its look, on the phone: your verdict | M | songs 1A-1D |
| 5 | Worlds 2-6: each its songs, its new thing, its look | L | the other 20 songs |
| 6 | The golden note and the encore, the tutorial, a tap-to-the-beat calibration for Bluetooth headphones | M | |

The songs are the long pole, and they are yours to generate, so the pilot can start now, in
parallel with the other games' pass.

## 6b. The pilot, 12 November 2026: song 1A is through

- The prompts had to change twice before the xylophone led: short, tags, the instrument first, a band of three, "no
  new instruments" (`tools/audio/suno_prompts.py` has the story). The take is 70 s, so nothing is cut.
- Split from Mix gave a clean pair: the two files line up to the sample and the xylophone stem holds 186 notes in
  G major pentatonic, 94% of them on the eighth-note grid, the kick 4.7 times stronger on the beats.
- **Suno's timing wanders**: steady inside a phrase (6 ms), but tens of ms between phrases, so one fixed grid does
  not fit. `tools/audio/tune_chart.py` follows the grid note by note and a note's time in the chart is its real time
  in the audio. Charts: easy 97 notes (1.4 a second), normal 174 (2.5), hard 186.
- In the game (`tummy_tunes.gd`, TUNE = "1A", the normal chart): the pair plays as one `AudioStreamSynchronized`;
  the lead goes silent when a note is due and not hit, and comes back on a hit. Played on the phone by the user:
  "pretty cool", the approach works; the band was too quiet (fixed, section 2b) and the first missed note still
  sounded (fixed).
- Still to build: levels and stars, holds and chords, the lanes' look, FOCUS. No holds were found in 1A (a
  xylophone's notes are short), as expected.

## 6c. Decided so far

| Date | Decision |
|---|---|
| 2026-11-12 | The approach: the player plays the lead of a Suno song split in two; lanes by pitch; a miss silences the lead while the band plays on |
| 2026-11-12 | Suno Pro: Split from Mix is the route (one instrument + everything else) |
| 2026-11-12 | World 3 is the Toy Ocarina (the user didn't love the trumpet); the drums are world 6 as the Festival Taiko |
| 2026-11-12 | The prompt shape: short tags, the instrument first, a band of three, "no new instruments", the other leads in the Exclude (a long prose prompt let a synth take the tune; a full band passed the lead around) |
| 2026-11-12 | The band must be heard on a phone: asked for in the prompt and rebuilt by the tool (section 2b) |
| 2026-11-12 | The lead goes silent the moment a note is due and not hit, not after the miss is judged (the user: "the first note is still heard even if not pressing"); a hit, even late, brings it back |

Added 2026-11-13 (the user, after more play: "how the notes of the lead coincide with the required taps is great"):

| Date | Decision |
|---|---|
| 2026-11-13 | A bar of metronome before the first note: tic tac tac tac at the song's own tempo (made in code, `COUNT_BEATS`), so the first note can be hit |
| 2026-11-13 | The band must not live in the sub-bass. 1A's stem is only bass and kick, so the tool takes the sub-bass nearly out and lets the bass's harmonics carry it, levelled with a slow gain. That is a repair: songs from the new prompt (present drums) should not need it |

| 2026-11-13 | The tune's difficulty is chosen by measuring, not by hoping: the same prompt gives simpler and busier tunes (the user). Each prompt now says how busy its slot is (A a nursery rhyme ... D the showpiece), and `tools/audio/tune_rate.py` rates every take BEFORE the split (notes a second, pitches, jumps, quick notes, one score). A world's four songs are the takes sorted by that score, whatever prompt made them |

| 2026-11-13 | A level's length by its slot: song A about 60 s, B 65, C 70, the showpiece D 80. Suno's takes are often over 2 minutes: the tool cuts them there, on a bar line, with a short fade (`LEN_BY_SLOT`) |

| 2026-11-13 | The game lists its songs in the shared level menu, each on easy, normal and hard (temporary: `TUNES` in `tummy_tunes.gd`); stars: 85% and 95% of the notes hit. Two songs in: 1A (59.6 s) and 1B (63.6 s, a busier take: 3.7 notes a second on hard) |
| 2026-11-13 | The beat grid is the one the tune fits best, tried from the band's kick and from each of the tune's first notes (1B opens on a pickup, which had put its whole grid half a step off) |
| 2026-11-13 | World 1's art: the designer's mock-up approved and delivered as 20 layers (`docs/mockups/tomo_tunes/round1/`). To do on our side before it goes in: the coloured bands on the wall (in `xylophone.png`) don't line up with the bars, so the lanes are drawn by the game; the game's lanes move to the bars' centres (x 505, 995, 1430 of 1900) |
| 2026-11-13 | A cut song ends where a phrase ends (the user: "the song finishes before it ends"): the tool picks the bar line near the slot's length where the tune lands and rests, 4-bar phrases first; that downbeat is the last note to play, the band rings out over one more bar. 1A is now 64.9 s, 1B 66.2 s |
| 2026-11-13 | The hard chart is the normal chart plus only the quick notes three buttons can play (the user: "the hard sometimes gets too hard"): a quick note stays as a two-thumb roll into a note on the neighbouring lane, never under 0.1 s, at most one every two beats (`playable()`). 1B hard: 236 notes to 193. The pixel size for world 1's art: 3 (the user) |
| 2026-11-13 | World 1's look is in the game's code (not on the phone until the user's OK): `tools/design/tunes_world.py` makes the designer's layers into pixel layers (1 art pixel = 3 on screen, a few colours per layer) in `textures/minigames/tunes/xylophone/`, with our own soft lanes on the wall, outlined notes and a glow. In the game: the lanes sit on the bars' centres, a bar dips on a press and lights on a hit, the toys keep the beat, the room dims while the instrument is silent. Screens: `docs/mockups/tomo_tunes/in_game_world1_play.png`, `_miss.png` |
| 2026-11-13 | The three bars are one size and the lanes line up with them (the user: "the keys should be same size and note lanes more aligned with those"). The tool does it, not the designer: `BAR_W` = 62 art pixels for every bar, the tray repainted with three equal lanes (`even_tray()`), the wall's lanes carrying on from the tray's, and a note follows the tray's lane onto its bar. The user's verdict on the look: "looks great". The how-to for the next worlds: `docs/handbook.md`, section 6 |
| 2026-11-13 | After the first play with the art (the user): (1) "song 2 doesn't get to the end, we should play the full song": a take is played WHOLE with its own ending unless it runs more than 35 s over its slot's length (`FULL_UP_TO`); 1A is 70 s, 1B 85 s. (2) "the note balls should fall straight to the keys": notes fall straight down and the wall's lanes sit straight above the bars (following the tray's slanted lanes is out). (3) "rain sound and effect shouldn't be there": the shrine's rain stops, seen and heard, while any game is open (`shrine.gd`, `GameScreen.is_active`) |
| 2026-11-13 | The count-in can differ by song: the user says which (`COUNT_BEATS_OF`; 1B has 4 clicks, the default is 3) |
| 2026-11-13 | KEPT (the user: "great, that's the way", then a bit quieter: -11 dB), so it is the rule for every world: a press that is not a hit plays the instrument's wrong note in that lane's register (low, middle, high) and costs more groove (a stray press 0.07, was 0.04; a missed note stays 0.08). The sounds are made by `tools/audio/tune_wrong.py` (a dead stroke on two notes a semitone apart), `sounds/tunes/fx/xylophone_wrong_*.wav`. If the user keeps it, it is the rule for every world: add the world's instrument to the tool's `INSTRUMENTS` table |
| 2026-11-13 | A song finished = applause with the result card, in three sizes by the stars (the user): a few hands for 1 star, a small room for 2, a full room with whistles for 3. Made by `tools/audio/applause.py` (`sounds/fx/applause_1..3.wav`); a failed song gets none. Only in Tomo Tunes for now |
| 2026-11-13 | The result card didn't come when a song ended (the user): a take played whole ends exactly at its length, the player stops and its position reads 0, so "time is up" never came. The song now also ends when the player has stopped, or by the frame clock (`played`). QA: `tools/qa/tunes_end.gd` jumps to 4 s before the end and checks the card opens. The notes: 18 art pixels across (were 22) with a 2-pixel outline (the user: slightly smaller, a bit more outline) |

## 6d. How each new song is made (the workflow)

1. **You:** take the song's prompt from `docs/tomo_tunes_prompts.md`. Suno, Advanced, v6,
   Instrumental on; Styles and Exclude pasted; the title. 2-4 takes.
1b. **Me (or you):** `.venv/bin/python tools/audio/tune_rate.py <the takes' MP3s>`: the takes in order of how busy
   their tune is. The simplest good take is the world's song A, the busiest its D.
2. **You:** keep the take where the lead plays the tune from start to end, the beat never wavers
   and the drums are clearly there. 60-75 s is enough.
3. **You:** on it, "...", Get Stems, Split from Mix, ask for the world's instrument (named in the
   prompts file). Download the three MP3s as Suno names them.
4. **You:** put them in `sounds/tunes/incoming/<id>/` (e.g. `1B/`) and tell me.
5. **Me:** run `tune_chart.py <id> "<title>"`. It refuses nothing yet, it reports: the tempo, the
   share of notes on the grid, the lanes, the band's level. I listen to the click file
   (`check_normal.wav`: a click on every charted note) and fix what's off.
6. **Me:** put it in the game and install it on the phone. **You:** play it and say what's off.
7. When a song needs a prompt change, it goes into `tools/audio/suno_prompts.py` (never into the
   generated prompts file), with a comment saying why, so the next songs get it.

## 7. Open points

- **The six instruments** (section 3): the Ocarina at 3 and the Taiko at 6, to confirm by ear on
  their first songs.
- **Your Suno plan**: Pro (the user, 2026-11-12), so Split from Mix is the route.
- **The tempos.** The build's background tracks sit at 82-107 BPM and 118 felt too fast there. A
  rhythm game's tempo is its difficulty, so worlds 5 and 6 go to 112-132. If that breaks the
  soundtrack's feel, the alternative is to stay under 112 and get the difficulty from denser charts.
- **Suno misses the asked tempo** (known from the build's tracks): the tool measures it; the
  prompt's number is only a target.
- **A split is regenerated, not cut out** (Suno's note): the stem and "everything else" may not
  add up exactly to the original song. The game plays the pair, so that is what gets checked.
- **Latency.** Wired and the phone's speaker are covered by the engine's own latency figure.
  Bluetooth headphones need the calibration of step 6.

## 8. Where Suno's features are described

- Split from Mix and the plans: https://help.suno.com/en/articles/13925185 and
  https://help.suno.com/en/articles/12702337
- The stem separation update (stems are regenerated): https://about.suno.com/blog/stem-separation-updates
- Studio, adding an instrument to a song: https://help.suno.com/en/articles/7940161
- Exporting from Studio (MIDI per stem, Premier, a rough transcription): https://help.suno.com/en/articles/8128193
