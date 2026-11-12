#!/usr/bin/env python3
"""Tomo Tunes: the 24 songs and their Suno prompts, from one table (docs/tomo_tunes.md has the why).

    python3 tools/audio/suno_prompts.py            writes docs/tomo_tunes_prompts.md
    python3 tools/audio/suno_prompts.py check      only checks the lengths

Every prompt is the recipe that worked for the build's game music (docs/ideas_roadmap.md, "Music
prompts") bent to what a rhythm game needs: ONE lead instrument that Suno can split out as a stem
(the notes the player plays), dry and on the grid, over a backing that never changes tempo.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIMIT = 1000          # the Style field (v4.5 and later; the pilot song confirms it)

STYLE = ("{Lead} solo instrumental: the {short} plays the tune, loud and up front, and it is the only melodic "
         "instrument. Cute toy-instrument rhythm game music in {key}, {mood}. The {short} is dry and close with no "
         "reverb and no echo, playing one clear melody {part} {beats} The melody is a simple singable 4-bar phrase "
         "that repeats with small variations, a low phrase answered by a high phrase, and it starts on the first beat. "
         "Backing, quiet and low in the mix: {backing}. Constant {bpm} BPM in 4/4 with no tempo changes, straight even "
         "timing with no swing, no breaks, the arrangement stays the same from start to end, narrow dynamics, warm "
         "rounded mix, clean ending on a bar.")
# (2026-11-12: the first 1A takes opened with "Soft pixel chiptune..." and Suno gave the tune to a synth. The lead
# now comes first, the word chiptune is gone outside the Star Stage, and synth leads are in the Exclude.)
ON_BEAT = "The strongest notes fall on the beats."
OFF_BEAT = "The kick marks every beat, so the notes between the beats are easy to hear."      # the Music Box, and the Star Stage's off-beat songs
BACKING = "a soft round bass, a soft kick on every beat and a snare on beats 2 and 4, warm pad chords"
BACKING_STAGE = "a round sine bass, a soft chiptune kick on every beat and a snare on beats 2 and 4, warm pad chords"
EXCLUDE = ("vocals, choir, vocal chops, swing, shuffle, triplets, tempo change, rubato, long intro, fade in, fade out, "
           "heavy reverb, delay, echo, arpeggios, glissando, trills, guitar, strings, second lead instrument")
NO_SYNTH = "synth lead, square wave lead, chiptune melody, 8-bit lead, "       # every world but the Star Stage

# the taiko world: the drums ARE the lead, so the backing has no drum kit
STYLE_TAIKO = ("Soft pixel chiptune festival rhythm game instrumental in {key}, {mood}. The lead is a solo set of taiko "
               "drums, dry and close with no reverb: a deep low drum, sharp rim clicks and a small high drum, playing "
               "{part} The pattern is a clear 4-bar phrase that repeats with small variations and starts on the first "
               "beat. The taiko is the only percussion: no drum kit, no kick, no snare, no hi-hat. Backing: soft "
               "pulse-wave bass on every beat, a quiet bamboo flute melody low in the mix, quiet warm pad chords. "
               "Constant {bpm} BPM in 4/4 with no tempo changes, straight even timing with no swing, no breaks, the "
               "arrangement stays the same from start to end, narrow dynamics, warm rounded mix, clean ending on a bar.")
EXCLUDE_TAIKO = ("vocals, choir, shouts, vocal chops, drum kit, kick drum, snare, hi-hat, cymbals, swing, shuffle, "
                 "triplets, tempo change, rubato, long intro, fade in, fade out, heavy reverb, delay, echo, guitar, strings")

# world: name, the lead as Suno should hear it, what to ask for in "Split from Mix", what the world teaches,
# then its four songs: letter, title, BPM, key, mood, the lead's part (a full sentence)
WORLDS = [
    ("Toy Xylophone", "toy xylophone with wooden mallets", "xylophone", "single notes on the beat; the lanes are low, middle and high", [
        ("A", "Wooden Steps", 92, "a major pentatonic key", "sunny, gentle and curious, like a first morning at a small shrine",
         "in even eighth notes that step up and down like stairs, one note at a time."),
        ("B", "Hopscotch", 96, "a major pentatonic key", "playful and bouncy, like children skipping",
         "in eighth notes with a short rest at the end of every bar, hopping between two neighbouring notes."),
        ("C", "Acorn Rain", 100, "a major key", "light and quick, like acorns dropping on a wooden roof",
         "in steady eighth notes that jump between a low bar and a high bar."),
        ("D", "Sunrise Mallets", 104, "a major pentatonic key", "bright and proud, a small showpiece",
         "in eighth notes with wide leaps between low and high bars, each phrase ending in a quick run of four sixteenth notes."),
    ]),
    ("Toy Piano", "toy piano, plinky and bright", "piano", "two buttons at once: a chord on the accents", [
        ("A", "Plink Plonk", 100, "a major key", "cheerful and tidy, like a child's first piano lesson",
         "in eighth notes, with a strong two-note chord on the first beat of every bar."),
        ("B", "Tiptoe Keys", 104, "a minor key", "sneaky and funny, like tiptoeing past a sleeping cat",
         "in soft eighth notes, with a strong two-note chord on beats 1 and 3."),
        ("C", "Marble Stairs", 108, "a major key", "lively and rolling, like marbles down a staircase",
         "of running single eighth notes answered by two-note chord stabs."),
        ("D", "The Little Recital", 110, "a major key", "grand in a tiny way, a showpiece for a toy piano",
         "that mixes quick single notes with strong two-note chords, ending every phrase on a big chord."),
    ]),
    ("Toy Ocarina", "clay ocarina, soft, round and breathy", "ocarina (or flute / woodwinds)", "long notes: hold the button for as long as the note sounds", [
        ("A", "First Breath", 96, "a major key", "calm and warm, like a slow parade far away",
         "of long held notes, each two beats long, with a short breath between them."),
        ("B", "Paper Hat Parade", 100, "a major key", "proud and silly, a parade of paper hats",
         "of long held notes of two to four beats joined by short pickup notes."),
        ("C", "Kite Call", 104, "a major pentatonic key", "open and breezy, like calling to a kite",
         "with a long note at the start of every bar followed by three short notes."),
        ("D", "The Little Serenade", 108, "a major key", "a small proud serenade, a showpiece",
         "of short repeated notes leading into long held notes of a whole bar."),
    ]),
    ("Music Box", "wind-up music box with a metal comb", "music box (or bells / glockenspiel)", "off-beats: the notes between the beats", [
        ("A", "Wind-Up Lullaby", 88, "a major key", "tender and sleepy, a lullaby",
         "in eighth notes where every second note of the tune lands on the off-beat, between the kicks."),
        ("B", "Off-Beat Ballerina", 92, "a minor key", "delicate and a little mysterious, a ballerina turning",
         "of off-beat eighth notes that land between the kicks, with one note on the first beat of every bar."),
        ("C", "Clockwork Snow", 96, "a major key", "sparkling and cold, like snow in a glass globe",
         "of syncopated eighth notes, some held over the bar line."),
        ("D", "The Glass Carousel", 100, "a major key", "turning and magical, a showpiece",
         "of flowing syncopated notes, on and off the beat, like a carousel tune."),
    ]),
    ("Star Stage", "bright square-wave chiptune synth lead", "synth lead", "everything together, and faster", [
        ("A", "Stage Lights", 112, "a major key", "excited and shining, the lights coming on",
         "in eighth notes with a long held note at the end of every phrase."),
        ("B", "Neon Lanterns", 116, "a minor key", "cool and driving, a night festival",
         "in eighth notes with off-beat accents and a strong two-note chord on the first beat of every bar."),
        ("C", "Comet Chase", 120, "a minor key", "fast and thrilling, chasing a comet",
         "in fast eighth notes with short bursts of four sixteenth notes."),
        ("D", "The Star Song", 124, "a major key", "triumphant and glittering, the grand finale",
         "that mixes quick runs, off-beat accents, strong two-note chords and long held notes."),
    ]),
    ("Festival Taiko", "taiko", "taiko (or drums / percussion)", "rolls and speed: the three drums are the three buttons", [
        ("A", "Lantern Parade", 120, "a minor pentatonic key", "steady and proud, a lantern parade at dusk",
         "a steady festival pattern of deep hits on the beat answered by rim clicks."),
        ("B", "Bon Dance", 124, "a major pentatonic key", "warm and dancing, a summer bon dance",
         "a dance pattern of two deep hits and two rim clicks, with a short drum roll at the end of every fourth bar."),
        ("C", "Thunder Drums", 128, "a minor key", "stormy and exciting, thunder over the shrine",
         "driving eighth-note patterns that move between the deep drum, the rim and the small drum, with drum rolls."),
        ("D", "The Great Matsuri", 132, "a minor pentatonic key", "huge and joyful, the grand festival, a showpiece",
         "a grand solo of fast patterns across all three drums, long rolls and strong hits on two drums at once."),
    ]),
]


def songs():
    for w, (world, lead, split, teaches, rows) in enumerate(WORLDS, 1):
        for letter, title, bpm, key, mood, part in rows:
            taiko = world == "Festival Taiko"
            beats = OFF_BEAT if (w == 4 or (w, letter) in ((5, 'B'), (5, 'D'))) else ON_BEAT
            short = split.split(" (")[0]
            style = (STYLE_TAIKO if taiko else STYLE).format(key=key, mood=mood, Lead=lead[0].upper() + lead[1:], short=short, part=part, bpm=bpm,
                                                             beats=beats, backing=BACKING_STAGE if w == 5 else BACKING)
            exclude = EXCLUDE_TAIKO if taiko else (EXCLUDE if w == 5 else NO_SYNTH + EXCLUDE)
            yield w, world, split, teaches, letter, title, bpm, style, exclude


def main():
    rows = list(songs())
    worst = max(len(r[7]) for r in rows)
    over = [f"{r[0]}{r[4]} {r[5]}: {len(r[7])}" for r in rows if len(r[7]) > LIMIT]
    print(f"{len(rows)} songs, longest style {worst} characters (limit {LIMIT})" + ("; OVER: " + ", ".join(over) if over else ""))
    if "check" in sys.argv:
        return 1 if over else 0
    out = ["# Tomo Tunes: the Suno prompts (24 songs)", "",
           "Made by `tools/audio/suno_prompts.py` (edit the table there, never this file). The plan, the",
           "pipeline and what to check in a take: `docs/tomo_tunes.md`. **Make the pilot first (1A, Wooden",
           "Steps) and stop there**: its stems tell us what to change in the other 23 before any credits go.", "",
           "For every song: Custom mode, **Instrumental on**, the newest model. Paste the Style and the Exclude,",
           "set the title. Make 2 to 4 takes and keep the one that passes the ear check in the plan.", ""]
    last = 0
    for w, world, split, teaches, letter, title, bpm, style, exclude in rows:
        if w != last:
            out += [f"## World {w}: {world}", "", f"Teaches: {teaches}. Split from Mix: ask for **{split}**.", ""]
            last = w
        role = {"A": "levels 1, 4, 7", "B": "levels 2, 5, 8", "C": "levels 3, 6", "D": "level 9, the showpiece"}[letter]
        out += [f"### {w}{letter}. {title} ({bpm} BPM; {role})", "", "Style:", "", "```", style, "```", "", "Exclude:", "", "```", exclude, "```", ""]
    with open(os.path.join(ROOT, "docs", "tomo_tunes_prompts.md"), "w") as f:
        f.write("\n".join(out))
    return 1 if over else 0


if __name__ == "__main__":
    sys.exit(main())
