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
         "reverb. {part} {key}, {mood}. the drums are clear and present: punchy kick on every beat, "
         "crisp snare on 2 and 4, a bright shaker on every eighth. same instruments from start to end, no new "
         "instruments, no build, no arrangement changes. {bpm} BPM, 4/4, straight timing, loopable")
# (2026-11-12, after 1A on the phone: "soft bass, soft drums, minimal, sparse" made a band 26 dB under the lead, so the
# band vanished on a phone speaker when the lead went silent. The drums are now asked for clear and present, with a
# snare and a shaker that a phone speaker plays. Check this on 1B: the lead must still be the only melody.)
# (2026-11-13: the taiko's band had kept "soft bass, quiet flute, minimal, sparse", the words that made 1A's band
# vanish on a phone. Now present, like the others.)
STYLE_TAIKO = ("solo taiko drums, only three instruments: taiko, warm round bass, bamboo flute. dry, close, no reverb: a "
               "deep low drum, sharp rim clicks, a small high drum. {part} {key}, {mood}. the taiko is the only "
               "percussion, loud and clear; the bass and the flute are clear and present. same instruments from start "
               "to end, no new instruments, no build, no arrangement changes. {bpm} BPM, 4/4, straight timing, loopable")
# How busy the tune is, by its slot in the world (the user, 2026-11-13: the same prompt gave a childish tune and a
# complicated one; the progression needs a grip). Words alone don't hold Suno: tools/audio/tune_rate.py measures each
# take before it is split, and the takes are SORTED into the slots by that number.
# (2026-11-13, later: "very simple nursery-rhyme melody" and "cute" gave kindergarten songs: the user. EASY is few
# notes, space and repetition; the STYLE stays a cool, laid-back game tune, like the build's lo-fi soundtrack.)
# (later the same day: "lo-fi" and "catchy hook" brought busier tunes and syncopated rhythms. Now the RHYTHM is
# spelled out: notes on the beat, plain and even; worlds 1-3 exclude syncopation.)
# (2026-11-13, the pass before world 2: the slot's wording used to be glued in front of each song's own older line,
# and the two contradicted each other: 2A said "quarter notes and half notes only" and then "in eighth notes". Now
# every song's line below is ONE consistent sentence: how busy (its slot: A slow and plain, B a few eighths, C
# moving, D the showpiece) and the world's new thing (chords, long notes, off-beats). 1A and 1B keep the wording
# that made the two songs in the game.)
# THE MOODS (the user, 2026-11-13: "not all songs should be super cheerful, some could be a bit deeper but not too
# cheesy"): every world has warm songs AND at least one deeper one (a minor or dorian key; thoughtful, wistful,
# calm; "not sad"). Never: cute, silly, playful, bouncy, cheerful (they gave kindergarten songs), and the Exclude
# keeps the cheese out (sentimental ballad, cinematic, epic).
PLAIN_RHYTHM = "syncopation, off-beat rhythm, sixteenth notes, fast runs, "       # worlds 1-3: the off-beat is world 4's new thing
OTHERS = ["xylophone", "piano", "flute", "bells", "synth", "synth lead", "chiptune", "8-bit", "strings", "pads", "guitar", "brass"]
ALWAYS = "nursery rhyme, children's song, lullaby, sentimental ballad, cinematic, epic, vocals, choir, orchestra, build-up, drop, breakdown, key change, tempo change, swing, reverb, delay, arpeggio"
OWN = {1: ["xylophone"], 2: ["piano"], 3: ["flute"], 4: ["bells"], 5: ["synth", "synth lead", "chiptune", "8-bit"], 6: ["flute"]}

# world: name, the lead as Suno should hear it, what to ask for in "Split from Mix", what the world teaches,
# then its four songs: letter, title, BPM, key, mood, the lead's part (a full sentence)
WORLDS = [
    ("Toy Xylophone", "toy xylophone with wooden mallets", "xylophone", "single notes on the beat; the lanes are low, middle and high", [
        ("A", "Wooden Steps", 92, "a major pentatonic key", "sunny, warm and easygoing, a first morning at a small shrine",
         "a slow simple melody in quarter notes and half notes only, one note per beat, four beats to the bar, the same short phrase repeated, plain even rhythm, stepping up and down like stairs, one note at a time."),
        ("B", "Stepping Stones", 96, "a major pentatonic key", "light and unhurried, crossing a stream stone by stone",
         "a simple melody in quarter notes with a few eighth notes, the same short phrase repeated, plain even rhythm, hopping between neighbouring notes."),
        ("C", "Acorn Rain", 100, "a dorian minor key", "thoughtful and a little wistful, rain on a wooden roof, calm, not sad",
         "a melody in steady eighth notes that moves between low notes and high notes, plain even rhythm."),
        ("D", "Sunrise Mallets", 104, "a major pentatonic key", "bright and proud, a small showpiece",
         "a lively showpiece melody in eighth notes with wide leaps between low and high notes, each phrase ending in a short quick run."),
    ]),
    ("Toy Piano", "toy piano, plinky and bright", "piano", "two buttons at once: a chord on the accents", [
        ("A", "Plink Plonk", 100, "a major key", "warm and tidy, an easy afternoon",
         "a slow simple melody in quarter notes and half notes, one note per beat, the same short phrase repeated, plain even rhythm, with a strong two-note chord on the first beat of every bar."),
        ("B", "Tiptoe Keys", 104, "a minor key", "quiet, curious and a little mysterious, tiptoeing through the house at night",
         "a simple melody in quarter notes with a few eighth notes, the same short phrase repeated, plain even rhythm, with a strong two-note chord on beats 1 and 3."),
        ("C", "Marble Stairs", 108, "a major key", "lively and rolling, marbles down a staircase",
         "a melody of running eighth notes answered by strong two-note chord stabs, plain even rhythm."),
        ("D", "The Little Recital", 110, "a minor key that ends in major", "earnest and heartfelt, a small serious recital, a showpiece",
         "a showpiece melody that mixes quick single notes with strong two-note chords, every phrase ending on a big chord."),
    ]),
    ("Toy Ocarina", "clay ocarina, soft and round", "ocarina (or flute / woodwinds)", "long notes: hold the button for as long as the note sounds", [
        ("A", "First Breath", 96, "a major key", "calm and warm, a slow parade far away",
         "a slow simple melody of long held notes, each two beats long, with a short breath between them, the same short phrase repeated."),
        ("B", "Dusk Path", 100, "a dorian minor key", "calm and wistful, walking home at dusk, not sad",
         "a simple melody of long held notes of two to four beats joined by short quarter-note pickups, the same short phrase repeated."),
        ("C", "Kite Call", 104, "a major pentatonic key", "open and breezy, calling to a kite",
         "a melody with a long held note at the start of every bar followed by three short notes."),
        ("D", "The Little Serenade", 108, "a major key", "tender and proud, a small serenade, a showpiece",
         "a showpiece melody of short repeated notes leading into long held notes of a whole bar."),
    ]),
    ("Music Box", "wind-up music box with a metal comb", "music box (or bells / glockenspiel)", "off-beats: the notes between the beats", [
        ("A", "Wind-Up Dream", 88, "a major key", "tender and dreamy, late at night",
         "a slow simple melody in eighth notes where every second note lands on the off-beat, between the kicks, the same short phrase repeated."),
        ("B", "Off-Beat Ballerina", 92, "a minor key", "delicate and a little mysterious, a ballerina turning alone",
         "a simple melody of off-beat eighth notes that land between the kicks, with one note on the first beat of every bar, the same short phrase repeated."),
        ("C", "Clockwork Snow", 96, "a major key", "sparkling and cold, snow in a glass globe",
         "a melody of syncopated eighth notes, some held over the bar line."),
        ("D", "The Glass Carousel", 100, "a minor key", "turning, magical and a little haunting, a showpiece",
         "a showpiece melody of flowing syncopated notes, on and off the beat, like a carousel tune."),
    ]),
    ("Star Stage", "bright square-wave chiptune synth lead", "synth lead", "everything together, and faster", [
        ("A", "Stage Lights", 112, "a major key", "excited and shining, the lights coming on",
         "a melody in eighth notes with a long held note at the end of every phrase."),
        ("B", "Neon Lanterns", 116, "a minor key", "cool and driving, a night festival",
         "a melody in eighth notes with off-beat accents and a strong two-note chord on the first beat of every bar."),
        ("C", "Comet Chase", 120, "a minor key", "fast and thrilling, chasing a comet",
         "a melody in fast eighth notes with short bursts of four sixteenth notes."),
        ("D", "The Star Song", 124, "a major key", "triumphant and glittering, the grand finale",
         "a showpiece melody that mixes quick runs, off-beat accents, strong two-note chords and long held notes."),
    ]),
    ("Festival Taiko", "taiko", "taiko (or drums / percussion)", "rolls and speed: the three drums are the three buttons", [
        ("A", "Lantern Parade", 120, "a minor pentatonic key", "steady and proud, a lantern parade at dusk",
         "a steady festival pattern of deep hits on the beat answered by rim clicks."),
        ("B", "Bon Dance", 124, "a major pentatonic key", "warm and dancing, a summer bon dance",
         "a dance pattern of two deep hits and two rim clicks, with a short drum roll at the end of every fourth bar."),
        ("C", "Thunder Drums", 128, "a minor key", "stormy and tense, thunder over the shrine",
         "driving eighth-note patterns that move between the deep drum, the rim and the small drum, with drum rolls."),
        ("D", "The Great Matsuri", 132, "a minor pentatonic key", "huge and joyful, the grand festival, a showpiece",
         "a grand solo of fast patterns across all three drums, long rolls and strong hits on two drums at once."),
    ]),
]


def songs():
    for w, (world, lead, split, teaches, rows) in enumerate(WORLDS, 1):
        for letter, title, bpm, key, mood, part in rows:
            taiko = world == "Festival Taiko"
            style = (STYLE_TAIKO if taiko else STYLE).format(key=key, mood=mood, lead=lead, short=split.split(" (")[0], part=part, bpm=bpm)
            exclude = ((PLAIN_RHYTHM if letter != "D" else "syncopation, off-beat rhythm, ") if w <= 3 else "")   # (a showpiece may run) + ", ".join([o for o in OTHERS if o not in OWN[w]] + (["drum kit", "kick", "snare", "hi-hat"] if taiko else [])) + ", " + ALWAYS
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
           "pipeline and what to check in a take: `docs/tomo_tunes.md`. 1A and 1B are in the game. One song of a new",
           "world first (2A next): its stems tell us what to change before more credits go. Prefer takes of 60-90 s:",
           "the game plays a take whole.", "",
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
