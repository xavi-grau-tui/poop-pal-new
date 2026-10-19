"""Top Spin's sounds (scripts/top_spin.gd), synthesized (numpy only):

    sounds/fx/top_whir.wav  a spinning top's whir: a soft hum and the air fluttering as its blades
                            sweep round, a seamless 1 s loop (the game raises its pitch and its
                            level with the spin: it climbs as you wind, sinks as the top runs down)
    sounds/fx/top_zip.wav   a good pull while winding: the ripcord zipping out, its teeth clicking
                            faster and faster, a faint rising tone (short, no tail)

    <venv>/bin/python tools/audio/top_sounds.py [names]   (no names: all of them)
"""
import os
import sys
import wave
import numpy as np

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
SR = 44100
rng = np.random.default_rng(23)


def save(name, x, peak=0.8, fade=True):
    x = x / np.max(np.abs(x)) * peak
    if fade:
        f = min(len(x), int(SR * 0.006))
        x[-f:] *= np.linspace(1, 0, f)
    with wave.open(os.path.join(ROOT, 'sounds', 'fx', name), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    print('wrote', name)


def circ_band(x, lo, hi):
    """A band-pass done round the loop (in the frequency domain): no seam where it wraps"""
    f = np.fft.rfft(x)
    hz = np.fft.rfftfreq(len(x), 1.0 / SR)
    f *= ((hz >= lo) & (hz <= hi)) * 1.0
    return np.fft.irfft(f, len(x))


def whir():
    """1 s, every part a whole number of cycles in it, so the loop has no click: a round hum
    (150 Hz and two partials), the air the blades push (band noise) fluttering 25 times a second
    as they sweep past, a thin high whine on top"""
    n = SR
    t = np.arange(n) / SR
    blades = 1.0 + 0.55 * np.sin(2 * np.pi * 25.0 * t)
    hum = (np.sin(2 * np.pi * 150.0 * t) + 0.45 * np.sin(2 * np.pi * 300.0 * t + 0.4)
           + 0.2 * np.sin(2 * np.pi * 450.0 * t + 1.1)) * (1.0 + 0.18 * np.sin(2 * np.pi * 25.0 * t))
    air = circ_band(rng.standard_normal(n), 700.0, 3400.0) * blades
    air /= np.max(np.abs(air))
    whine = np.sin(2 * np.pi * 1800.0 * t) * 0.08
    return hum * 0.55 + air * 0.5 + whine


def zip_():
    """0.22 s: the cord's teeth clicking out, faster and faster (40 to 150 a second), each a
    short bright tick; a faint tone rising under them; a quick fade, no tail"""
    dur = 0.22
    n = int(SR * dur)
    t = np.arange(n) / SR
    rate = 40.0 + 110.0 * (t / dur) ** 1.4
    ph = np.cumsum(rate) / SR
    ticks = np.zeros(n)
    last = -1
    tick = rng.standard_normal(int(SR * 0.004)) * np.exp(-np.arange(int(SR * 0.004)) / SR / 0.0012)
    for i in range(n):
        k = int(ph[i])
        if k != last:
            last = k
            m = min(len(tick), n - i)
            ticks[i:i + m] += tick[:m]
    # brighten the ticks (a crude high-pass: the difference of neighbours)
    ticks = np.diff(ticks, prepend=0.0)
    f = 380.0 + 700.0 * (t / dur) ** 1.2
    tone = np.sin(2 * np.pi * np.cumsum(f) / SR) * 0.25
    env = np.minimum(1, t / 0.008) * np.clip(1.15 - t / dur, 0, 1)
    return (ticks / np.max(np.abs(ticks)) * 0.9 + tone) * env


SOUNDS = {'top_whir.wav': whir, 'top_zip.wav': zip_}

if __name__ == '__main__':
    names = sys.argv[1:] or list(SOUNDS)
    for name in names:
        key = name if name.endswith('.wav') else name + '.wav'
        save(key, SOUNDS[key](), peak=0.8, fade=key != 'top_whir.wav')
