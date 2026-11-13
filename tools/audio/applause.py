#!/usr/bin/env python3
"""The applause at a level's result, in three sizes, one per star count (the user, 2026-11-13: "a little applause is
heard when showing the result with three intensities depending if it's 1 star, 2 stars or 3 stars").

    .venv/bin/python tools/audio/applause.py        writes sounds/fx/applause_1.wav, _2.wav, _3.wav

Made here, no samples: every clap is a short burst of noise through a hand's own resonance (each clapper has their
own pitch, pace and place), and a crowd is many clappers. 1 star: a few polite hands, 2 s. 2 stars: a small room,
3 s. 3 stars: a full room that swells, with a couple of whistles, 4.2 s.
"""
import os

import numpy as np
import soundfile as sf
from scipy import signal

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SR = 44100
SIZES = {1: dict(people=4, length=2.0, level=0.30, whistles=0),
         2: dict(people=14, length=3.0, level=0.42, whistles=0),
         3: dict(people=45, length=4.2, level=0.55, whistles=2)}


def clap(rng, pitch):
    n = int(SR * 0.05)
    x = rng.standard_normal(n) * np.exp(-np.arange(n) / (SR * rng.uniform(0.004, 0.009)))
    sos = signal.butter(2, [pitch * 0.6, min(pitch * 1.7, 9000)], 'bandpass', fs=SR, output='sos')
    return signal.sosfilt(sos, x)


def applause(people, length, level, whistles, seed):
    rng = np.random.default_rng(seed)
    n = int(SR * length)
    out = np.zeros((n + SR, 2))
    for _ in range(people):
        pitch = rng.uniform(900, 2600)                 # this pair of hands
        pace = rng.uniform(0.17, 0.27)                 # s between claps
        pan = rng.uniform(0.15, 0.85)
        loud = rng.uniform(0.5, 1.0)
        t = rng.uniform(0.0, 0.35)                     # they don't all start together
        stop = length * rng.uniform(0.62, 0.95)        # nor stop together
        while t < stop:
            c = clap(rng, pitch * rng.uniform(0.95, 1.05)) * loud * rng.uniform(0.7, 1.0)
            i = int(t * SR)
            out[i:i + len(c), 0] += c * (1 - pan)
            out[i:i + len(c), 1] += c * pan
            t += pace * rng.uniform(0.9, 1.12)
            pace *= 1.012                              # tiring
    for _ in range(whistles):
        d = rng.uniform(0.35, 0.55)
        tt = np.arange(int(SR * d)) / SR
        f = rng.uniform(1700, 2100) * (1 + 0.35 * (tt / d) ** 2)
        w = 0.05 * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * tt / d) ** 0.6
        i = int(rng.uniform(0.5, length * 0.55) * SR); pan = rng.uniform(0.2, 0.8)
        out[i:i + len(w), 0] += w * (1 - pan) * people ** 0.5
        out[i:i + len(w), 1] += w * pan * people ** 0.5
    out = out[:n]
    tt = np.arange(n) / SR
    env = np.minimum(1.0, tt / 0.25) * np.minimum(1.0, (length - tt) / (length * 0.45)) ** 1.3
    out *= env[:, None]
    return level * out / np.abs(out).max()


def main():
    for stars, cfg in SIZES.items():
        x = applause(seed=stars, **cfg)
        sf.write(os.path.join(ROOT, 'sounds', 'fx', f'applause_{stars}.wav'), x.astype(np.float32), SR, subtype='PCM_16')
        print(f'{stars} star(s): {cfg["people"]} people, {cfg["length"]} s')


if __name__ == '__main__':
    main()
