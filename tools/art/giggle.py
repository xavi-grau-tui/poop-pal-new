"""Synthesized pal giggle ("hee-hee-hee-hee") for the tickle reaction.

A buzzy glottal source (sawtooth with vibrato) shaped by two vowel formants ("ee"), cut
into short syllables whose pitch steps down like a chuckle. Soft and short.
    -> sounds/fx/giggle.wav         (tickle: hee-hee-hee-hee)
    -> sounds/fx/giggle_short.wav   (button poke: a quick "hee-hee")
    -> sounds/fx/hi.wav             (a new pal hatches: a tiny voice-like "hi!")
    -> sounds/fx/bye.wav            (flush: a soft "bye!" with a falling pitch)
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


def formant_glide(src, f_from, f_to, bw):
    """Resonator whose centre frequency glides from f_from to f_to (for vowel changes)."""
    n = len(src)
    freqs = np.linspace(f_from, f_to, n)
    y = np.zeros(n)
    y1 = y2 = 0.0
    for i in range(n):
        r = math.exp(-math.pi * bw / SR)
        c1, c2 = 2 * r * math.cos(2 * math.pi * freqs[i] / SR), -r * r
        y0 = (1 - r) * src[i] + c1 * y1 + c2 * y2
        y[i] = y0
        y2, y1 = y1, y0
    return y


def hi(path):
    """'h' = a short breathy puff, then 'ai' = a vowel gliding from 'a' to 'ee', with a
    cheerful rising pitch. Voice-like, but still a little creature noise."""
    rng = np.random.default_rng(3)
    # h: filtered breath
    nh = int(SR * 0.06)
    th = np.arange(nh) / SR
    breath = rng.standard_normal(nh) * np.minimum(1, th / 0.02) * 0.35
    h = formant(breath, 1400, 900)
    # ai: voiced glide
    nv = int(SR * 0.26)
    t = np.arange(nv) / SR
    f0 = 560 * (1 + 0.35 * (t / t[-1]) ** 1.2) * (1 + 0.03 * np.sin(2 * math.pi * 9 * t))
    phase = np.cumsum(f0 / SR)
    src = 2 * (phase % 1.0) - 1 + 0.12 * rng.standard_normal(nv)
    v = formant_glide(src, 850, 380, 110) * 1.0 + formant_glide(src, 1250, 2500, 170) * 0.9
    env = np.minimum(1, t / 0.015) * np.exp(-t * 6.5)
    v *= env
    out = np.concatenate([h, v, np.zeros(int(SR * 0.05))])
    out = out / np.abs(out).max() * 0.55
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((out * 32767).astype(np.int16).tobytes())


def bye(path):
    """'b' = a tiny low pop, then 'ai' gliding like 'hi' but with a falling, wistful pitch."""
    rng = np.random.default_rng(5)
    nb = int(SR * 0.025)
    tb = np.arange(nb) / SR
    pop = np.sin(2 * math.pi * 140 * tb) * np.exp(-tb * 180) * 0.8 + rng.standard_normal(nb) * np.exp(-tb * 300) * 0.15
    nv = int(SR * 0.32)
    t = np.arange(nv) / SR
    f0 = 640 * (1 - 0.28 * (t / t[-1]) ** 0.9) * (1 + 0.03 * np.sin(2 * math.pi * 7 * t))
    phase = np.cumsum(f0 / SR)
    src = 2 * (phase % 1.0) - 1 + 0.1 * rng.standard_normal(nv)
    v = formant_glide(src, 820, 400, 110) * 1.0 + formant_glide(src, 1200, 2400, 170) * 0.9
    env = np.minimum(1, t / 0.012) * np.exp(-t * 5.5)
    out = np.concatenate([pop, v * env, np.zeros(int(SR * 0.05))])
    out = out / np.abs(out).max() * 0.55
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((out * 32767).astype(np.int16).tobytes())


if __name__ == '__main__':
    giggle(os.path.join(PROJ, '..', 'sounds', 'fx', 'giggle.wav'))
    giggle(os.path.join(PROJ, '..', 'sounds', 'fx', 'giggle_short.wav'), ((780, 0.09), (650, 0.13)))
    hi(os.path.join(PROJ, '..', 'sounds', 'fx', 'hi.wav'))
    bye(os.path.join(PROJ, '..', 'sounds', 'fx', 'bye.wav'))
    print('ok')
