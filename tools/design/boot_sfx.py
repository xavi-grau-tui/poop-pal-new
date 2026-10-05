"""Synthesises the boot's sound: the Kobaya Tech rabbit appearing.

    <python with numpy> tools/design/boot_sfx.py

sounds/fx/kobaya_bunny.wav   two tiny sniffs (a twitching nose) and a soft little hop 'pip';
                             meant to be played very quietly"""
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
RATE = 44100


def sniff(rng, length=0.045):
    t = np.arange(int(RATE * length)) / RATE
    n = rng.normal(0, 1, t.size)
    airy = n - np.convolve(n, np.ones(8) / 8, mode="same")      # breathy, no rumble
    env = np.sin(np.pi * t / length) ** 2
    return airy * env * 0.5


def pip(length=0.07):
    t = np.arange(int(RATE * length)) / RATE
    f = 900 + 900 * (t / length)                                 # a small upward chirp
    phase = 2 * np.pi * np.cumsum(f) / RATE
    env = np.minimum(1.0, t / 0.006) * np.exp(-t / 0.025)
    return (np.sin(phase) + 0.25 * np.sin(2 * phase)) * env


def bunny():
    rng = np.random.default_rng(11)
    out = np.zeros(int(RATE * 0.42))
    for start, part in ((0.00, sniff(rng)), (0.075, sniff(rng)), (0.20, pip())):
        i = int(RATE * start)
        out[i:i + part.size] += part
    return out


def save(name, x, peak=0.5):
    x = x / np.max(np.abs(x)) * peak
    with wave.open(str(ROOT / "sounds" / "fx" / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


if __name__ == "__main__":
    save("kobaya_bunny.wav", bunny())
    print("wrote kobaya_bunny.wav")
