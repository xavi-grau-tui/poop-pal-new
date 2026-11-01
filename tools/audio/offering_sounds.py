"""The shrine's offering sounds (scripts/shrine.gd, yokai migration: in place of the gut's), synthesized
(numpy only):

    sounds/fx/offer_whoosh.wav   the offering dropping in from above: a soft airy whoosh, falling
    sounds/fx/offer_tok.wav      it lands on the sanbo's tray: a light hollow wooden tok
    sounds/fx/offer_clap.wav     the offering chosen (the food's confirm sound in the shrine): two soft
                                 hand claps, as at a shrine before a prayer (kashiwade)
    sounds/fx/offer_munch.wav    one bite of the spirit: a tiny chibi "nom" (the user: the crunchy
                                 one sounded like farts; the game varies its pitch)
    sounds/fx/offer_pour.wav     a drink poured from the little bottle into the cup: a thin trickle, a
                                 glug or two, the note rising as the cup fills
    sounds/fx/spirit_inhale.wav  the spirit drawing the drink's essence out of the cup: an airy breath in,
                                 rising, little sparkles in it
    sounds/fx/spirit_rise.wav    the send-off (the flush's whoosh in the shrine): an airy breath rising and
                                 soft chime notes climbing as the spirit floats up out of the roof
    sounds/fx/spirit_shimmer.wav while the spirit blinks (the gut's digestion hum's place, 10 s): a calm
                                 singing-bowl ring swelling and fading, little sparkles quickening
                                 with the blinks
    sounds/fx/spirit_ting.wav    the new form (the coin's place): a bright small bell, a long ring
    sounds/fx/rain_loop.wav      the shrine's rain (when it rains where you are): a soft hiss and
                                 drops pattering on the roof, 6 s that loop seamlessly

    <venv>/bin/python tools/audio/offering_sounds.py [names]   (no names: all of them)
"""
import os
import sys
import wave
import numpy as np

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
SR = 44100
rng = np.random.default_rng(11)


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


def band(x, lo, hi):
    f = np.fft.rfft(x)
    hz = np.fft.rfftfreq(len(x), 1.0 / SR)
    f *= ((hz >= lo) & (hz <= hi)) * 1.0
    return np.fft.irfft(f, len(x))


def sweep_noise(n, f0, f1, width):
    """Noise through a band whose middle slides from f0 to f1 (done in short overlapping frames)"""
    out = np.zeros(n)
    hop = 512
    win = np.hanning(hop * 2)
    src = rng.standard_normal(n + hop * 2)
    for i in range(0, n, hop):
        u = i / n
        c = f0 * (f1 / f0) ** u
        seg = band(src[i:i + hop * 2], c / width, c * width) * win
        out[i:i + hop * 2] += seg[:max(0, min(hop * 2, n - i))] if i + hop * 2 > n else seg
    return out[:n]


def whoosh():
    """0.55 s: air rushing past, its pitch sinking as it falls (2.4 kHz to 700 Hz), in and out"""
    n = int(SR * 0.55)
    t = np.arange(n) / n
    env = np.sin(np.pi * t) ** 1.6
    return sweep_noise(n, 2400.0, 700.0, 1.5) * env


def tok():
    """0.2 s: a small hollow block of wood knocked: two quick-dying wooden tones and a click"""
    n = int(SR * 0.2)
    t = np.arange(n) / SR
    body = (np.sin(2 * np.pi * 620.0 * t) * np.exp(-t * 38) + 0.6 * np.sin(2 * np.pi * 1180.0 * t) * np.exp(-t * 55)
            + 0.25 * np.sin(2 * np.pi * 2350.0 * t) * np.exp(-t * 90))
    click = band(rng.standard_normal(n), 1500.0, 6000.0) * np.exp(-t * 400) * 0.5
    return body + click


def munch():
    """0.16 s: a tiny cartoon "nom": a bright little voice (1 kHz, the user: a touch higher; a rounded tone and its overtones through
    an "o"-ish formant) gliding down, closed off quickly, a soft tick of a bite at the start"""
    n = int(SR * 0.16)
    t = np.arange(n) / SR
    f = 1040.0 * (1.0 - 0.28 * np.clip(t / 0.12, 0, 1))
    ph = 2 * np.pi * np.cumsum(f) / SR
    voice = np.sin(ph) + 0.35 * np.sin(2 * ph) + 0.12 * np.sin(3 * ph)
    env = np.clip(t / 0.008, 0, 1) * np.clip((0.14 - t) / 0.05, 0, 1)
    tick = band(rng.standard_normal(n), 2500.0, 7000.0) * np.exp(-t * 300) * 0.35
    return voice * env * (1.0 + 0.08 * np.sin(2 * np.pi * 28 * t)) + tick


def clap():
    """0.6 s: two soft hand claps a breath apart, each a burst of air (mid band noise, a sharp start)
    with a little room after it"""
    n = int(SR * 0.6)
    x = np.zeros(n)
    for at, a in ((0.0, 1.0), (0.3, 0.9)):
        k = int(at * SR)
        m = n - k
        tt = np.arange(m) / SR
        burst = band(rng.standard_normal(m), 700.0, 3200.0)
        x[k:] += a * burst * (np.exp(-tt * 60) + 0.08 * np.exp(-tt * 12))
    return x


def shimmer():
    """10 s (the blinking): a singing bowl's ring (its uneven partials, beating slowly) swelling in
    and fading at the end, and small high sparkles, more and more of them as the blinks quicken"""
    dur = 10.0
    n = int(SR * dur)
    t = np.arange(n) / SR
    f = 392.0
    bowl = np.zeros(n)
    for k, (mul, a) in enumerate(((1.0, 1.0), (2.71, 0.45), (5.15, 0.18))):
        beat = 1.0 + 0.3 * np.sin(2 * np.pi * (0.5 + 0.3 * k) * t)
        bowl += a * np.sin(2 * np.pi * f * mul * t + k) * beat
    env = np.clip(t / 2.0, 0, 1) * np.clip((dur - t) / 1.5, 0, 1)
    x = bowl * env * 0.5
    # sparkles: their times quicken like the blinks (each gap 0.97 of the last)
    at, gap = 1.2, 0.7
    while at < dur - 0.4:
        k = int(at * SR)
        m = min(n - k, int(SR * 0.5))
        tt = np.arange(m) / SR
        p = rng.choice([1568.0, 1760.0, 2093.0, 2349.0, 2637.0])
        x[k:k + m] += 0.12 * np.sin(2 * np.pi * p * tt) * np.exp(-tt * 9) * env[k:k + m]
        at += gap
        gap = max(0.12, gap * 0.94)
    return x


def ting():
    """1.4 s: a small bright bell struck once (uneven partials, the high ones dying first)"""
    n = int(SR * 1.4)
    t = np.arange(n) / SR
    f = 1318.5
    x = np.zeros(n)
    for mul, a, d in ((1.0, 1.0, 3.0), (2.76, 0.5, 6.0), (5.40, 0.25, 11.0), (8.93, 0.1, 18.0)):
        x += a * np.sin(2 * np.pi * f * mul * t) * np.exp(-t * d)
    x[:int(SR * 0.002)] *= np.linspace(0, 1, int(SR * 0.002))
    return x


def pour():
    """1.6 s: a trickle (bubbly band noise, its pitch rising as the cup fills) with a couple of
    small glugs, in and out softly"""
    dur = 1.6
    n = int(SR * dur)
    t = np.arange(n) / SR
    x = sweep_noise(n, 1300.0, 2600.0, 1.35)
    bub = 1.0 + 0.6 * np.abs(np.sin(2 * np.pi * (9 + 5 * t) * t)) * rng.uniform(0.6, 1.0, n)
    x = x * bub
    for at in (0.25, 0.7, 1.1):
        k = int(at * SR)
        m = int(SR * 0.09)
        tt = np.arange(m) / SR
        x[k:k + m] += 0.6 * np.sin(2 * np.pi * (300 + 900 * tt / 0.09) * tt) * np.exp(-tt * 40)
    env = np.clip(t / 0.08, 0, 1) * np.clip((dur - t) / 0.25, 0, 1)
    return x * env


def inhale():
    """1.7 s: an airy breath drawn in (band noise swelling, its band rising) and a few soft bright
    sparkles climbing with it"""
    dur = 1.7
    n = int(SR * dur)
    t = np.arange(n) / SR
    air = sweep_noise(n, 500.0, 1800.0, 1.6)
    env = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 1.3
    x = air * env
    for i, at in enumerate((0.3, 0.55, 0.8, 1.0, 1.2)):
        k = int(at * SR)
        m = min(n - k, int(SR * 0.4))
        tt = np.arange(m) / SR
        x[k:k + m] += 0.18 * np.sin(2 * np.pi * (1568.0 * 2 ** (i / 6)) * tt) * np.exp(-tt * 10)
    return x


def rise():
    """1.5 s: air rising (band noise, its band climbing) and five soft chime notes going up a
    pentatonic scale, each ringing on"""
    dur = 1.5
    n = int(SR * dur)
    t = np.arange(n) / SR
    x = sweep_noise(n, 400.0, 2200.0, 1.5) * np.sin(np.pi * t / dur) ** 1.5 * 0.6
    for i, f in enumerate((784.0, 880.0, 1047.0, 1175.0, 1568.0)):
        k = int((0.12 + i * 0.17) * SR)
        m = n - k
        tt = np.arange(m) / SR
        x[k:] += 0.35 * (np.sin(2 * np.pi * f * tt) + 0.3 * np.sin(2 * np.pi * f * 2.76 * tt) * np.exp(-tt * 9)) * np.exp(-tt * 3.5)
    return x


def rain():
    """A soft rain: a hiss (noise in a band, periodic over the whole loop, so it loops seamlessly)
    and drops pattering on wood (short filtered taps, wrapped round the loop's end)"""
    n = SR * 6
    x = band(rng.standard_normal(n), 300, 5000) * 0.35
    x += band(rng.standard_normal(n), 80, 400) * 0.25
    tap_n = int(SR * 0.03)
    tt = np.arange(tap_n) / SR
    for _ in range(6 * 45):
        k = rng.integers(0, n)
        f = rng.uniform(1800, 4200)
        tap = np.sin(2 * np.pi * f * tt) * np.exp(-tt * rng.uniform(140, 260)) * rng.uniform(0.2, 0.9)
        idx = (k + np.arange(tap_n)) % n
        x[idx] += tap
    return x


SOUNDS = {
    'rain_loop.wav': (rain, 0.4),
    'offer_whoosh.wav': (whoosh, 0.5),
    'offer_tok.wav': (tok, 0.8),
    'offer_munch.wav': (munch, 0.7),
    'offer_clap.wav': (clap, 0.6),
    'offer_pour.wav': (pour, 0.5),
    'spirit_inhale.wav': (inhale, 0.5),
    'spirit_rise.wav': (rise, 0.6),
    'spirit_shimmer.wav': (shimmer, 0.6),
    'spirit_ting.wav': (ting, 0.7),
}

if __name__ == '__main__':
    want = sys.argv[1:] or list(SOUNDS)
    for name in SOUNDS:
        if any(w in name for w in want):
            fn, peak = SOUNDS[name]
            save(name, fn(), peak, fade=name != 'rain_loop.wav')
