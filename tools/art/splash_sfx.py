"""Splash Hoops' storm sounds (world 5), synthesized like arcade_sfx.py: soft, under the music.

    python3 tools/art/splash_sfx.py     -> sounds/fx/storm_gust.wav, thunder.wav
"""
import os, wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'sounds', 'fx')
rng = np.random.default_rng(11)


def onepole(x, a):
    """a simple low-pass (a = 0..1: how fast it follows)"""
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += a * (v - acc)
        y[i] = acc
    return y


def save(name, x, gain=0.8):
    x = x / (np.max(np.abs(x)) + 1e-9) * gain
    data = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def gust():
    """wind swelling and dying away: filtered noise, its 'whistle' rising then falling"""
    n = int(SR * 2.6)
    x = rng.standard_normal(n)
    t = np.arange(n) / n
    swell = np.sin(np.pi * t) ** 1.6
    low = onepole(x, 0.04)
    mid = onepole(x, 0.12) - onepole(x, 0.03)
    tone = mid * (0.5 + 0.5 * np.sin(np.pi * t))
    return (low * 1.2 + tone * 0.9) * swell


def thunder():
    """a soft crack, then a long low rumble rolling away"""
    n = int(SR * 2.8)
    x = rng.standard_normal(n)
    t = np.arange(n) / SR
    crack = onepole(x, 0.35) * np.exp(-t * 18.0) * 0.6
    rumble = onepole(onepole(x, 0.012), 0.05) * np.exp(-t * 1.3)
    roll = 0.75 + 0.25 * np.sin(t * 9.0 + np.sin(t * 3.0) * 2.0)
    return crack + rumble * roll * 3.0


if __name__ == '__main__':
    save('storm_gust', gust(), 0.7)
    save('thunder', thunder(), 0.8)
    print('ok')
