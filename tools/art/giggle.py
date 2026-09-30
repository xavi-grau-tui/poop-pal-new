"""Synthesized pal giggle ("hee-hee-hee-hee") for the tickle reaction.

A buzzy glottal source (sawtooth with vibrato) shaped by two vowel formants ("ee"), cut
into short syllables whose pitch steps down like a chuckle. Soft and short.
    -> sounds/fx/giggle.wav         (tickle: hee-hee-hee-hee)
    -> sounds/fx/giggle_short.wav   (button poke: a quick "hee-hee")
"""
import math, os, wave
import numpy as np

from hires import PROJ

SR = 44100


def formant(x, freq, bw):
    """Two-pole resonator (band-pass) over signal x."""
    r = math.exp(-math.pi * bw / SR)
    c1, c2 = 2 * r * math.cos(2 * math.pi * freq / SR), -r * r
    y = np.zeros_like(x)
    y1 = y2 = 0.0
    g = 1 - r
    for i, v in enumerate(x):
        y0 = g * v + c1 * y1 + c2 * y2
        y[i] = y0
        y2, y1 = y1, y0
    return y


def syllable(pitch, dur, breath=0.25):
    n = int(SR * dur)
    t = np.arange(n) / SR
    f0 = pitch * (1 + 0.04 * np.sin(2 * math.pi * 11 * t)) * np.linspace(1.08, 0.94, n)
    phase = np.cumsum(f0 / SR)
    src = 2 * (phase % 1.0) - 1                              # sawtooth "voice"
    src += breath * np.random.default_rng(int(pitch)).standard_normal(n)
    v = formant(src, 420, 90) * 1.0 + formant(src, 2500, 180) * 0.8 + formant(src, 3300, 250) * 0.3
    env = np.minimum(1, t / 0.012) * np.exp(-t * 9)          # quick attack, bouncy decay
    return v * env


def giggle(path, notes=((810, 0.11), (730, 0.10), (680, 0.10), (610, 0.16))):
    parts = []
    for i, (p, d) in enumerate(notes):
        parts.append(syllable(p, d))
        parts.append(np.zeros(int(SR * (0.035 + 0.01 * i))))
    out = np.concatenate(parts)
    out = out / np.abs(out).max() * 0.55
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((out * 32767).astype(np.int16).tobytes())


if __name__ == '__main__':
    giggle(os.path.join(PROJ, '..', 'sounds', 'fx', 'giggle.wav'))
    giggle(os.path.join(PROJ, '..', 'sounds', 'fx', 'giggle_short.wav'), ((780, 0.09), (650, 0.13)))
    print('ok')
