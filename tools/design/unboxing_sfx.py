"""Synthesises the unboxing's sound: a film peeling off a screen.

    <python with numpy> tools/design/unboxing_sfx.py

sounds/fx/film_peel.wav   a short, soft 'zip': crackly bright noise that rises and fades"""
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
RATE = 44100


def film_peel():
    t = np.arange(int(RATE * 0.32)) / RATE
    rng = np.random.default_rng(5)
    noise = rng.normal(0, 1, t.size)
    # brighten: subtract a smoothed copy (crude high-pass), then soften the very top
    smooth = np.convolve(noise, np.ones(12) / 12, mode="same")
    hiss = np.convolve(noise - smooth, np.ones(3) / 3, mode="same")
    # the zip: tiny adhesive pops, getting faster as the film comes away
    rate = 90 + 260 * (t / t[-1])
    phase = np.cumsum(rate) / RATE
    pops = (np.sin(2 * np.pi * phase) > 0.6).astype(float)
    pops = np.convolve(pops, np.exp(-np.arange(40) / 8.0), mode="same")
    x = hiss * (0.35 + 0.65 * pops / max(pops.max(), 1e-9))
    env = np.minimum(1.0, t / 0.05) * np.exp(-np.clip(t - 0.12, 0, None) / 0.08)
    return x * env


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
