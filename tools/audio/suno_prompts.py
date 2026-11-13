#!/usr/bin/env python3
"""Tomo Tunes: the 24 songs and their Suno prompts, from one table (docs/tomo_tunes.md has the why).

    python3 tools/audio/suno_prompts.py            writes docs/tomo_tunes_prompts.md
    python3 tools/audio/suno_prompts.py check      only checks the lengths

Every prompt is short and built for what a rhythm game needs: ONE lead instrument that Suno can split out as a stem
(the notes the player plays), dry and on the grid, over a backing that never changes tempo.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIMIT = 1000          # the Style field (v4.5 and later; the pilot song confirms it)

# 2026-11-12, after three tries on 1A: a long prose prompt opening with "chiptune" gave the tune to a synth, and a
# full band let Suno pass the lead around. What worked (the user: "now it's pure xylophone lead"): SHORT, tags, the
# instrument first, a band of three, "no new instruments", and every other lead in the Exclude.
STYLE = ("solo {lead}, {short} trio, only three instruments: {short}, warm round bass, crisp drums. dry, close, no "
         "reverb. {level} {part} {key}, {mood}. the drums are clear and present: punchy kick on every beat, "
         "crisp snare on 2 and 4, a bright shaker on every eighth. same instruments from start to end, no new "
         "instruments, no build, no arrangement changes. {bpm} BPM, 4/4, straight timing, loopable")
# (2026-11-12, after 1A on the phone: "soft bass, soft drums, minimal, sparse" made a band 26 dB under the lead, so the
# band vanished on a phone speaker when the lead went silent. The drums are now asked for clear and present, with a
# snare and a shaker that a phone speaker plays. Check this on 1B: the lead must still be the only melody.)
STYLE_TAIKO = ("solo taiko drums, only three instruments: taiko, soft bass, quiet bamboo flute. dry, close, no reverb: a "
               "deep low drum, sharp rim clicks, a small high drum. {part} {key}, {mood}. the taiko is the only "
               "percussion. minimal, sparse, same instruments from start to end, no new instruments, no build, no "
               "arrangement changes. {bpm} BPM, 4/4, straight timing, loopable")
# How busy the tune is, by its slot in the world (the user, 2026-11-13: the same prompt gave a childish tune and a
# complicated one; the progression needs a grip). Words alone don't hold Suno: tools/audio/tune_rate.py measures each
# take before it is split, and the takes are SORTED into the slots by that number.
# (2026-11-13, later: "very simple nursery-rhyme melody" and "cute" gave kindergarten songs: the user. EASY is few
# notes, space and repetition; the STYLE stays a cool, laid-back game tune, like the build's lo-fi soundtrack.)
LEVEL = {"A": "a relaxed catchy hook, few notes with space between them, lots of repetition, laid-back lo-fi game tune,",
         "B": "a relaxed catchy hook with a little more movement, laid-back lo-fi game tune,",
         "C": "a lively catchy melody with more notes and movement, upbeat game tune,",
         "D": "a busy showpiece melody, the liveliest of all, with runs and leaps, upbeat game tune,"}
OTHERS = ["xylophone", "piano", "flute", "bells", "synth", "synth lead", "chiptune", "8-bit", "strings", "pads", "guitar", "brass"]
ALWAYS = "nursery rhyme, children's song, lullaby, vocals, choir, orchestra, build-up, drop, breakdown, key change, tempo change, swing, reverb, delay, arpeggio"
OWN = {1: ["xylophone"], 2: ["piano"], 3: ["flute"], 4: ["bells"], 5: ["synth", "synth lead", "chiptune", "8-bit"], 6: ["flute"]}

# world: name, the lead as Suno should hear it, what to ask for in "Split from Mix", what the world teaches,
# then its four songs: letter, title, BPM, key, mood, the lead's part (a full sentence)
WORLDS = [
    ("Toy Xylophone", "toy xylophone with wooden mallets", "xylophone", "single notes on the beat; the lanes are low, middle and high", [
        ("A", "Wooden Steps", 92, "a major pentatonic key", "sunny, warm and easygoing, a first morning at a small shrine",
         "in even eighth notes that step up and down like stairs, one note at a time."),
        ("B", "Hopscotch", 96, "a major pentatonic key", "playful and bouncy, light on its feet",
         "in eighth notes with a short rest at the end of every bar, hopping between two neighbouring notes."),
        ("C", "Acorn Rain", 100, "a major key", "light and quick, like acorns dropping on a wooden roof",
         "in steady eighth notes that jump between a low bar and a high bar."),
        ("D", "Sunrise Mallets", 104, "a major pentatonic key", "bright and proud, a small showpiece",
         "in eighth notes with wide leaps between low and high bars, each phrase ending in a quick run of four sixteenth notes."),
    ]),
    ("Toy Piano", "toy piano, plinky and bright", "piano", "two buttons at once: a chord on the accents", [
        ("A", "Plink Plonk", 100, "a major key", "cheerful and tidy, a sunny afternoon",
         "in eighth notes, with a strong two-note chord on the first beat of every bar."),
        ("B", "Tiptoe Keys", 104, "a minor key", "sneaky and funny, like tiptoeing past a sleeping cat",
         "in soft eighth notes, with a strong two-note chord on beats 1 and 3."),
        ("C", "Marble Stairs", 108, "a major key", "lively and rolling, like marbles down a staircase",
         "of running single eighth notes answered by two-note chord stabs."),
        ("D", "The Little Recital", 110, "a major key", "grand in a tiny way, a showpiece for a toy piano",
         "that mixes quick single notes with strong two-note chords, ending every phrase on a big chord."),
    ]),
    ("Toy Ocarina", "clay ocarina, soft and round", "ocarina (or flute / woodwinds)", "long notes: hold the button for as long as the note sounds", [
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
        ("A", "Wind-Up Dream", 88, "a major key", "tender and dreamy, late at night",
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
            style = (STYLE_TAIKO if taiko else STYLE).format(key=key, mood=mood, lead=lead, short=split.split(" (")[0], part=part, bpm=bpm, level=LEVEL[letter])
            exclude = ", ".join([o for o in OTHERS if o not in OWN[w]] + (["drum kit", "kick", "snare", "hi-hat"] if taiko else [])) + ", " + ALWAYS
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
