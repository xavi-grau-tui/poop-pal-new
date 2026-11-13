#!/usr/bin/env python3
"""Tomo Tunes: the "wrong note" of a world's instrument, one per lane (low, middle, high).

The user, 2026-11-13: a press when it is not time should play "a little dissonant sound of the instrument being
played (low, medium or high)" and cost more groove. A trial on world 1; if it works it becomes the rule for every
world, each with its own instrument.

    .venv/bin/python tools/audio/tune_wrong.py            writes sounds/tunes/fx/<instrument>_wrong_<lane>.wav

The sound: the instrument's bar struck DEAD (short, damped) on two notes a semitone apart, the second a hair late and
flat: a clonk that is clearly the instrument and clearly wrong, in the lane's own register. Made here, no samples.
"""
import os

import numpy as np
import soundfile as sf

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SR = 44100
# per instrument: the partials of one struck note (ratio, level, decay s), and each lane's MIDI note
INSTRUMENTS = {
    'xylophone': {'partials': [(1.0, 1.0, 0.10), (3.0, 0.45, 0.05), (6.1, 0.22, 0.025)], 'knock': 0.5,
                  'lanes': {'low': 67, 'mid': 76, 'high': 83}},          # G4, E5, B5: the middle of each lane in songs 1A and 1B
}


def strike(midi, partials, knock, cents=0.0, length=0.3):
    f = 440.0 * 2 ** ((midi - 69 + cents / 100.0) / 12.0)
    t = np.arange(int(SR * length)) / SR
    x = sum(a * np.sin(2 * np.pi * f * r * t) * np.exp(-t / d) for r, a, d in partials)
    rng = np.random.default_rng(int(midi * 7 + cents))
    x += knock * rng.standard_normal(len(t)) * np.exp(-t / 0.004)          # the mallet's knock
    return x


# Instruments whose wrong notes are cut from the REAL instrument: a song's lead stem (the user, 2026-11-13, on the
# piano's first, synthesised ones: "dissonant notes should correspond to each instrument"). The rule from world 2 on.
FROM_STEM = {'piano': '2A'}


def from_stem(name, sid):
    """per lane: the cleanest single note of the stem in that lane (strong, alone, room after it), played DEAD with
    itself a semitone up, a hair late"""
    import sys
    from scipy import signal
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import tune_chart as T
    lead_path = T.find(os.path.join(ROOT, 'sounds', 'tunes', 'incoming', sid))[0]
    notes = T.notes_of(T.decode(lead_path))
    hi = T.decode(lead_path, SR, 1)
    lane = T.lanes_of([n[1] for n in notes])
    out = {}
    for k, lname in enumerate(('low', 'mid', 'high')):
        best = None
        for i, n in enumerate(notes[:-1]):
            gap = notes[i + 1][0] - n[0]
            if lane[n[1]] != k or n[4] is not None or gap < 0.3:
                continue
            if best is None or n[3] * min(gap, 0.6) > best[1]:
                best = (i, n[3] * min(gap, 0.6))
        n = notes[best[0]]
        a = int((n[0] - 0.004) * SR)
        x = hi[a:a + int(0.34 * SR)].astype(np.float64)
        up = signal.resample(x, int(len(x) / 2 ** (1 / 12)))             # the same note a semitone up
        late = int(0.018 * SR)
        y = x.copy()
        y[late:late + len(up)] += 0.9 * up[:len(y) - late]
        t = np.arange(len(y)) / SR
        y *= np.exp(-t / 0.11) * np.minimum(1.0, t / 0.002)                # a dead stroke
        y[-int(0.03 * SR):] *= np.linspace(1, 0, int(0.03 * SR))
        out[lname] = (0.6 * y / np.abs(y).max(), n[1], n[0])
    return out


def main():
    out = os.path.join(ROOT, 'sounds', 'tunes', 'fx')
    os.makedirs(out, exist_ok=True)
    for name, ins in INSTRUMENTS.items():
        for lane, midi in ins['lanes'].items():
            a = strike(midi, ins['partials'], ins['knock'])
            b = strike(midi + 1, ins['partials'], ins['knock'] * 0.6, cents=-30.0)
            late = int(0.018 * SR)
            x = a.copy(); x[late:] += 0.9 * b[:-late]
            x *= np.minimum(1.0, np.arange(len(x)) / (0.002 * SR))
            x[-int(0.03 * SR):] *= np.linspace(1, 0, int(0.03 * SR))
            x = 0.6 * x / np.abs(x).max()
            sf.write(os.path.join(out, f'{name}_wrong_{lane}.wav'), x.astype(np.float32), SR, subtype='PCM_16')
            print(f'{name} {lane}: MIDI {midi} and {midi + 1}, {len(x) / SR:.2f} s')
    for name, sid in FROM_STEM.items():
        for lane, (x, midi, at) in from_stem(name, sid).items():
            sf.write(os.path.join(out, f'{name}_wrong_{lane}.wav'), x.astype(np.float32), SR, subtype='PCM_16')
            print(f'{name} {lane}: the stem of {sid} at {at:.2f} s (MIDI {midi}) with itself a semitone up')


if __name__ == '__main__':
    main()
