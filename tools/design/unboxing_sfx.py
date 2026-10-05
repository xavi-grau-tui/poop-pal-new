"""Synthesises the unboxing's sounds.

    <python with numpy> tools/design/unboxing_sfx.py

sounds/fx/film_peel.wav   a seamless 1 s loop of tape/film peeling: steady tiny stick-slip
                          snaps. The game plays it while a film or the box seal peels, its
                          volume and pitch following the peeling speed.
sounds/fx/box_lid.wav     the box's lid lifted off: a papery rustle, then the box's hollow
                          low "thup"."""
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
RATE = 44100


def film_peel():
    """Tape/film peeling: the adhesive lets go in tiny stick-slip snaps at a fairly steady
    rate (the game raises the pitch, so the rate, as you pull faster), each snap a short
    crisp resonance; only a little hiss under it. A seamless 1 s loop."""
    n = RATE
    rng = np.random.default_rng(5)
    x = np.zeros(n + RATE // 10)
    # the snap: two damped resonances, a brighter one and a softer body
    k = np.arange(int(RATE * 0.004))
    snap = (np.sin(2 * np.pi * 3300 * k / RATE) * np.exp(-k / (RATE * 0.00045))
            + 0.5 * np.sin(2 * np.pi * 1700 * k / RATE + 1.0) * np.exp(-k / (RATE * 0.0008)))
    i = 0.0
    while i < n:
        j = int(i)
        x[j:j + len(snap)] += rng.uniform(0.35, 1.0) * snap * (1 if rng.random() > 0.5 else -1)
        i += RATE / (520 * rng.uniform(0.82, 1.18))           # ~520 snaps a second, jittered
    x = x[:n] + band(rng.normal(0, 1, n), 2500, 9000) * 0.12
    f = int(RATE * 0.06)                                       # seamless loop
    ramp = np.linspace(0, 1, f)
    x[:f] = x[:f] * ramp + x[-f:] * (1 - ramp)
    return x[:-f]


def band(x, lo, hi):
    """A crude band-pass: the difference of two moving averages."""
    a = np.convolve(x, np.ones(max(1, RATE // hi)) / max(1, RATE // hi), mode="same")
    b = np.convolve(x, np.ones(max(1, RATE // lo)) / max(1, RATE // lo), mode="same")
    return a - b


def knock(modes, contact_ms, contact_band, length=0.25, seed=1):
    """An impact, the way real ones sound: a burst of contact noise and a few inharmonic
    resonances dying away fast (freq Hz, decay s, amplitude)."""
    n = int(RATE * length)
    t = np.arange(n) / RATE
    rng = np.random.default_rng(seed)
    x = np.zeros(n)
    for f, dec, amp in modes:
        x += amp * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * np.exp(-t / dec)
    x += band(rng.normal(0, 1, n), *contact_band) * np.exp(-t / (contact_ms / 1000)) * 0.9
    return x * np.clip(t / 0.0008, 0, 1)                       # no click at the very start


def box_lid():
    """The lid lifted off the box: a short papery rustle as it slides free, then the hollow
    low "thup" of the box's air space (what makes it sound like cardboard), softened."""
    n = int(RATE * 0.32)
    t = np.arange(n) / RATE
    rng = np.random.default_rng(11)
    grain = np.abs(rng.normal(0, 1, n))
    grain = np.convolve(grain, np.ones(int(RATE / 90)) / int(RATE / 90), mode="same")
    rustle = band(rng.normal(0, 1, n), 700, 5000) * grain * np.clip(t / 0.015, 0, 1) * np.exp(-t / 0.035)
    t0 = 0.045
    tt = np.clip(t - t0, 0, None)
    on = t >= t0
    f = 150 * (1 - 0.25 * np.clip(tt / 0.08, 0, 1))                 # the cavity, its pitch sagging
    phase = 2 * np.pi * np.cumsum(f) / RATE
    cavity = np.sin(phase) * np.exp(-tt / 0.055) * on
    body = np.sin(2 * np.pi * 360 * tt + 0.7) * np.exp(-tt / 0.025) * on * 0.45
    puff = band(rng.normal(0, 1, n), 150, 900) * np.exp(-tt / 0.03) * on * 0.6
    x = rustle * 0.5 + cavity + body + puff
    return np.convolve(x, np.ones(6) / 6, mode="same")               # soft, no hard edges


def save(name, x, peak=0.5):
    x = x / np.max(np.abs(x)) * peak
    with wave.open(str(ROOT / "sounds" / "fx" / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


if __name__ == "__main__":
    save("film_peel.wav", film_peel())
    save("box_lid.wav", box_lid(), peak=0.6)
    print("wrote film_peel.wav, box_lid.wav")
