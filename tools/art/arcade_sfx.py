"""Little synthesized sounds for FLIPPER BELLY (pinball) and LUCKY PINCH (claw machine).

    python3 tools/art/arcade_sfx.py      -> sounds/fx/pin_*.wav, claw_*.wav

Soft, short, chiptune-ish: they sit under the music and never get shrill.
"""
import os, wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'sounds', 'fx')
rng = np.random.default_rng(3)


def t(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, attack=0.004, decay=8.0):
    x = np.arange(n) / SR
    a = np.clip(x / attack, 0, 1)
    return a * np.exp(-x * decay)


def sweep(f0, f1, dur, shape='sine'):
    x = t(dur)
    f = f0 * (f1 / f0) ** (x / dur)
    ph = 2 * np.pi * np.cumsum(f) / SR
    if shape == 'square':
        return np.sign(np.sin(ph)) * 0.6
    if shape == 'tri':
        return 2 / np.pi * np.arcsin(np.sin(ph))
    return np.sin(ph)


def lowpass(x, a=0.2):
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += a * (v - acc)
        y[i] = acc
    return y


def save(name, x, gain=0.8):
    x = x / (np.abs(x).max() + 1e-9) * gain
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(name, f'{len(x) / SR:.2f}s')


# flipper: a short wooden "thock" (low thump + a click of noise)
n = int(SR * 0.09)
thump = sweep(190, 90, 0.09) * env(n, 0.002, 38)
click = lowpass(rng.uniform(-1, 1, n), 0.35) * env(n, 0.001, 140)
save('pin_flipper.wav', thump + 0.6 * click, 0.7)

# bumper: a round rubbery pop
n = int(SR * 0.14)
save('pin_bumper.wav', (sweep(720, 380, 0.14, 'tri') + 0.3 * sweep(1440, 760, 0.14)) * env(n, 0.002, 24), 0.75)

# slingshot: a tighter, higher pop
n = int(SR * 0.08)
save('pin_sling.wav', sweep(980, 620, 0.08, 'tri') * env(n, 0.001, 40), 0.65)

# target: a small bell
n = int(SR * 0.35)
x = t(0.35)
bell = np.sin(2 * np.pi * 1320 * x) + 0.45 * np.sin(2 * np.pi * 2640 * x) + 0.2 * np.sin(2 * np.pi * 3960 * x)
save('pin_target.wav', bell * env(n, 0.002, 11), 0.6)

# all three targets: a quick rising arpeggio
notes = [784, 988, 1175, 1568]
parts = []
for i, f in enumerate(notes):
    d = 0.09 if i < 3 else 0.28
    m = int(SR * d)
    parts.append((np.sign(np.sin(2 * np.pi * f * t(d))) * 0.35 + np.sin(2 * np.pi * f * t(d))) * env(m, 0.002, 6 if i == 3 else 16))
save('pin_jackpot.wav', np.concatenate(parts), 0.6)

# belly button: a gulp (two quick downward sweeps)
g = []
for f0 in (420, 330):
    m = int(SR * 0.08)
    g.append(sweep(f0, 120, 0.08) * env(m, 0.004, 22))
    g.append(np.zeros(int(SR * 0.03)))
save('pin_gulp.wav', np.concatenate(g), 0.75)

# drain: three falling square notes
parts = []
for f in (523, 415, 311):
    m = int(SR * 0.13)
    parts.append(np.sign(np.sin(2 * np.pi * f * t(0.13))) * 0.5 * env(m, 0.003, 9))
save('pin_drain.wav', lowpass(np.concatenate(parts), 0.25), 0.55)

# tilt: a low buzzer
n = int(SR * 0.45)
save('pin_tilt.wav', lowpass(np.sign(np.sin(2 * np.pi * 98 * t(0.45))) * env(n, 0.005, 3), 0.15), 0.6)

# claw grab: a metallic clunk
n = int(SR * 0.16)
x = t(0.16)
metal = np.sin(2 * np.pi * 330 * x) + 0.6 * np.sin(2 * np.pi * 517 * x) + 0.4 * np.sin(2 * np.pi * 851 * x)
save('claw_grab.wav', metal * env(n, 0.001, 30) + 0.5 * lowpass(rng.uniform(-1, 1, n), 0.4) * env(n, 0.001, 90), 0.65)

# claw drop: a soft whoosh down
n = int(SR * 0.3)
save('claw_drop.wav', lowpass(rng.uniform(-1, 1, n), 0.08) * env(n, 0.05, 7) + 0.4 * sweep(500, 260, 0.3) * env(n, 0.02, 9), 0.45)

# prize: a happy little fanfare
notes = [(523, 0.1), (659, 0.1), (784, 0.1), (1047, 0.32)]
parts = []
for f, d in notes:
    m = int(SR * d)
    parts.append((np.sign(np.sin(2 * np.pi * f * t(d))) * 0.3 + np.sin(2 * np.pi * f * t(d))) * env(m, 0.003, 5 if d > 0.2 else 12))
save('claw_prize.wav', np.concatenate(parts), 0.6)

# nothing caught: a short "aww" (bending down)
n = int(SR * 0.4)
save('claw_miss.wav', lowpass(sweep(392, 262, 0.4, 'square'), 0.2) * env(n, 0.01, 4), 0.5)
