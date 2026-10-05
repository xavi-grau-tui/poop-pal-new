"""Synthesises the unboxing's sound: a film peeling off a screen.

    <python with numpy> tools/design/unboxing_sfx.py

sounds/fx/film_peel.wav   a seamless 1 s loop of the film's adhesive crackling away: bright
                          hiss full of tiny pops. The game plays it while a film peels,
                          its volume and pitch following the peeling speed."""
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
RATE = 44100


def film_peel():
    n = RATE                                   # 1 s, looped
    rng = np.random.default_rng(5)
    noise = rng.normal(0, 1, n)
    # bright: subtract a short smoothed copy (a crude high-pass), keep the top end crisp
    hiss = noise - np.convolve(noise, np.ones(6) / 6, mode="same")
    # adhesive pops at irregular, fast intervals
    pops = np.zeros(n)
    i = 0
    while i < n:
        pops[i] = rng.uniform(0.5, 1.0)
        i += int(RATE / rng.uniform(260, 420))
    pops = np.convolve(pops, np.exp(-np.arange(30) / 5.0), mode="same")
    x = hiss * (0.3 + 0.7 * pops / pops.max())
    # seamless loop: crossfade the last 60 ms into the first
    f = int(RATE * 0.06)
    ramp = np.linspace(0, 1, f)
    x[:f] = x[:f] * ramp + x[-f:] * (1 - ramp)
    return x[:-f]


def save(name, x, peak=0.5):
    x = x / np.max(np.abs(x)) * peak
    with wave.open(str(ROOT / "sounds" / "fx" / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


if __name__ == "__main__":
    save("film_peel.wav", film_peel())
    print("wrote film_peel.wav")
