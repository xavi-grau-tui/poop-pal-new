"""The sticker book's sounds (case_stickers.gd), synthesized:

    sounds/fx/sticker_page.wav   a page turned: a short soft paper tap
    sounds/fx/sticker_peel.wav   a sticker pulled off: a quick crackly "zzap", no long hiss

    <venv>/bin/python tools/audio/sticker_sounds.py
"""
import os
import wave
import numpy as np
from scipy.signal import butter, sosfilt

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
SR = 44100
rng = np.random.default_rng(7)


def band(x, lo, hi):
    return sosfilt(butter(2, [lo, hi], btype='band', fs=SR, output='sos'), x)


def save(name, x):
    x = x / np.max(np.abs(x)) * 0.8
    fade = min(len(x), int(SR * 0.004))
    x[-fade:] *= np.linspace(1, 0, fade)
    with wave.open(os.path.join(ROOT, 'sounds', 'fx', name), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


def tap():
    n = int(SR * 0.07)
    t = np.arange(n) / SR
    click = band(rng.standard_normal(n), 1800, 5200) * np.exp(-t / 0.005)
    body = np.sin(2 * np.pi * 210 * t) * np.exp(-t / 0.014) * 0.5
    return click + body


def zzap():
    n = int(SR * 0.13)
    t = np.arange(n) / SR
    u = t / t[-1]
    # glue letting go: crackles, denser and higher as the sticker comes off, all in ~0.1 s
    crackle = (rng.random(n) < 0.05 + 0.25 * u) * rng.standard_normal(n)
    noise = rng.standard_normal(n) * 0.25
    x = np.zeros(n)
    for i, (lo, hi) in enumerate([(900, 2400), (1600, 4200), (2800, 7000)]):
        seg = (u >= i / 3) & (u < (i + 1) / 3 + 0.08)
        x += band((crackle + noise), lo, hi) * seg
    env = np.minimum(1, t / 0.004) * (1 - u) ** 1.6
    return x * env


if __name__ == '__main__':
    save('sticker_page.wav', tap())
    save('sticker_peel.wav', zzap())
    print('ok')
