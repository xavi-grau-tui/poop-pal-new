"""Synthesises the unboxing's sounds.

    <python with numpy> tools/design/unboxing_sfx.py

sounds/fx/film_peel.wav   a seamless 1 s loop of tape/film peeling: steady tiny stick-slip
                          snaps. The game plays it while a film or the box seal peels, its
                          volume and pitch following the peeling speed.
sounds/fx/box_lid.wav     the box's lid lifted off: a dull cardboard tap.
sounds/fx/box_land.wav    the device set down in your hand: a soft plastic tap."""
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
    """The lid lifted off: a dull cardboard tap."""
    return knock([(190, 0.035, 1.0), (430, 0.022, 0.55), (980, 0.012, 0.3), (2100, 0.006, 0.15)],
                 4, (500, 4000), seed=11)


def box_land():
    """The device set down in your hand: a soft plastic tap."""
    return knock([(320, 0.030, 0.9), (870, 0.016, 0.5), (1900, 0.008, 0.3), (3700, 0.004, 0.15)],
                 2.5, (1200, 7000), seed=3)


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
    save("box_land.wav", box_land(), peak=0.6)
    print("wrote film_peel.wav, box_lid.wav, box_land.wav")
