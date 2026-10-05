"""Synthesises the unboxing's sounds.

    <python with numpy> tools/design/unboxing_sfx.py

sounds/fx/film_peel.wav   a seamless 1 s loop of the film's adhesive crackling away: bright
                          hiss full of tiny pops. The game plays it while a film peels,
                          its volume and pitch following the peeling speed.
sounds/fx/box_lid.wav     the box's cardboard lid sliding off: a grainy scrape, then the
                          soft whump of air as it comes free.
sounds/fx/box_land.wav    the device set down in your hand: a soft plastic thud."""
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


def band(x, lo, hi):
    """A crude band-pass: the difference of two moving averages."""
    a = np.convolve(x, np.ones(max(1, RATE // hi)) / max(1, RATE // hi), mode="same")
    b = np.convolve(x, np.ones(max(1, RATE // lo)) / max(1, RATE // lo), mode="same")
    return a - b


def box_lid():
    n = int(RATE * 0.62)
    t = np.arange(n) / RATE
    rng = np.random.default_rng(11)
    noise = rng.normal(0, 1, n)
    scrape = band(noise, 250, 2600)
    # stick-slip: the cardboard catching and letting go, a rough grain
    grain = np.abs(rng.normal(0, 1, n))
    grain = np.convolve(grain, np.ones(int(RATE / 60)) / int(RATE / 60), mode="same")
    env = np.clip(t / 0.06, 0, 1) * np.clip((0.46 - t) / 0.12, 0, 1)
    x = scrape * (0.35 + grain) * env
    # it comes free: a soft low whump of air
    t0 = 0.40
    tw = np.clip(t - t0, 0, None)
    whump = np.sin(2 * np.pi * (150 * tw - 160 * tw * tw)) * np.exp(-tw / 0.05) * (t >= t0)
    return x + whump * 0.9


def box_land():
    n = int(RATE * 0.25)
    t = np.arange(n) / RATE
    rng = np.random.default_rng(3)
    thud = np.sin(2 * np.pi * 110 * t * (1 - 0.3 * t / 0.25)) * np.exp(-t / 0.045)
    tick = band(rng.normal(0, 1, n), 1500, 6000) * np.exp(-t / 0.006) * 0.5
    return thud + tick


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
