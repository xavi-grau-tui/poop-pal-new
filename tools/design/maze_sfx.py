"""Synthesises the Poo Maze's soft sound effects (no samples needed).

    <python with numpy> tools/design/maze_sfx.py

sounds/fx/wood_tap.wav   the ball tapping a wooden wall: a short, dry knock
sounds/fx/hole_plop.wav  the ball dropping into a hole: a soft, muffled falling plop"""
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
RATE = 44100


def save(name, x, peak=0.7):
    x = x / np.max(np.abs(x)) * peak
    data = (x * 32767).astype(np.int16)
    with wave.open(str(ROOT / "sounds" / "fx" / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def t_axis(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def wood_tap():
    t = t_axis(0.12)
    # a few inharmonic partials that die fast, like a small block of wood
    x = np.zeros_like(t)
    for f, decay, amp in ((820, 0.028, 1.0), (1730, 0.016, 0.45), (2950, 0.009, 0.25), (430, 0.035, 0.35)):
        x += amp * np.sin(2 * np.pi * f * t) * np.exp(-t / decay)
    # the click of contact: a couple of ms of filtered noise
    rng = np.random.default_rng(1)
    click = rng.normal(0, 1, t.size) * np.exp(-t / 0.0015)
    click = np.convolve(click, np.ones(4) / 4, mode="same")
    x += 0.35 * click
    x *= np.minimum(1.0, t / 0.0008)            # no pop at the very start
    return x


def hole_plop():
    t = t_axis(0.42)
    # a soft pitch drop (the ball sinking away) ...
    f = 360 * np.exp(-t / 0.16) + 110
    phase = 2 * np.pi * np.cumsum(f) / RATE
    body = np.sin(phase) * np.exp(-t / 0.13) * np.minimum(1.0, t / 0.012)
    # ... and a dull, low bump when it lands at the bottom
    t2 = np.clip(t - 0.17, 0, None)
    thud = np.sin(2 * np.pi * 85 * t2) * np.exp(-t2 / 0.05) * (t >= 0.17) * 0.6
    x = body + thud
    # muffle: gentle low-pass so nothing is sharp
    k = np.exp(-np.arange(24) / 6.0)
    return np.convolve(x, k / k.sum(), mode="same")


if __name__ == "__main__":
    save("wood_tap.wav", wood_tap())
    save("hole_plop.wav", hole_plop(), peak=0.6)
    print("wrote wood_tap.wav + hole_plop.wav")
