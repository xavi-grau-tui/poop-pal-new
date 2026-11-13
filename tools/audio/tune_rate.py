#!/usr/bin/env python3
"""Tomo Tunes: how complicated is a take's tune? Run it on full Suno songs BEFORE splitting them, to choose which
take fits which slot of a world (the user, 2026-11-13: the same prompt gives simpler and busier tunes).

    .venv/bin/python tools/audio/tune_rate.py ~/Downloads/"Wooden Steps"*.mp3

It listens above 300 Hz (the lead's range; the band is below) and prints, per file: notes a second, how many
different pitches, the average jump between notes (semitones), the share of quick notes (closer than an eighth),
and one score from 1 (a nursery rhyme) to 10 (busy). A world wants its songs in rising order: A lowest, D highest.
"""
import sys
import numpy as np
import tune_chart as T


def rate(path):
    x = T.decode(path)
    notes = T.notes_of(x, lo=300.0)
    t = np.array([n[0] for n in notes]); midi = np.array([n[1] for n in notes])
    length = len(x) / T.SR
    gaps = np.diff(t)
    eighth = float(np.median(gaps[(gaps > 0.2) & (gaps < 0.6)])) if len(gaps) else 0.3
    if eighth > 0.45:
        eighth /= 2
    per_s = len(notes) / length
    quick = float((gaps < 0.7 * eighth).mean())
    jump = float(np.abs(np.diff(midi)).clip(0, 12).mean())
    pitches = len(set(midi))
    rep = float((np.diff(midi) == 0).mean())
    score = 1 + 9 * np.clip(0.35 * (per_s - 1.5) / 2.5 + 0.25 * quick / 0.3 + 0.25 * (jump - 2) / 4 + 0.15 * (pitches - 6) / 10, 0, 1)
    return per_s, pitches, jump, quick, rep, 30 / eighth, score


if __name__ == '__main__':
    print(f'{"score":>5} {"notes/s":>8} {"pitches":>8} {"jump":>6} {"quick":>6} {"repeats":>8} {"BPM":>6}  file')
    rows = sorted(((rate(p), p) for p in sys.argv[1:]), key=lambda r: r[0][-1])
    for (per_s, pitches, jump, quick, rep, bpm, score), p in rows:
        print(f'{score:5.1f} {per_s:8.2f} {pitches:8d} {jump:6.1f} {100 * quick:5.0f}% {100 * rep:7.0f}% {bpm:6.1f}  {p.split("/")[-1]}')
