"""RC Racer's sounds (scripts/rc_racer.gd), synthesized:

    sounds/fx/rc_motor.wav   the toy car's electric motor: a buzzy whine, a seamless 1 s loop
                             (the game raises its pitch with the speed and the turns)
    sounds/fx/rc_fall.wav    driving off the track: a cartoon whistle sliding down
    sounds/fx/rc_land.wav    ...and the toy landing on the floor: a plastic clatter and a bump
    sounds/fx/rc_beep.wav    the start lights: a short beep for each red light (3, 2, 1)
    sounds/fx/rc_go.wav      ...and a higher, longer one when they all turn green: GO

    <venv>/bin/python tools/audio/rc_sounds.py
"""
import os
import wave
import numpy as np
from scipy.signal import butter, sosfilt

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
SR = 44100
rng = np.random.default_rng(11)


def band(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], btype='band', fs=SR, output='sos'), x)


def low(x, hz):
    return sosfilt(butter(2, hz, btype='low', fs=SR, output='sos'), x)


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


def motor():
    """1 s, every partial a whole number of cycles in it, so the loop has no click"""
    n = SR
    t = np.arange(n) / SR
    base = 110.0                                    # the motor's hum (whole Hz: loops)
    x = np.zeros(n)
    for k, a in [(1, 1.0), (2, 0.55), (3, 0.4), (4, 0.25), (6, 0.18), (8, 0.12)]:
        x += a * np.sign(np.sin(2 * np.pi * base * k * t)) * 0.5 + a * np.sin(2 * np.pi * base * k * t) * 0.5
    whine = np.sin(2 * np.pi * 880.0 * t + 0.6 * np.sin(2 * np.pi * 6.0 * t)) * 0.22   # the gears
    x = low(x, 2600) + whine
    x *= 1.0 + 0.12 * np.sin(2 * np.pi * 9.0 * t)   # a little rattle, 9 Hz (whole: loops)
    return x


def fall():
    n = int(SR * 0.55)
    t = np.arange(n) / SR
    f = 1400.0 * np.exp(-t * 3.2) + 260.0           # sliding down
    phase = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(phase) + 0.25 * np.sin(phase * 2)
    env = np.minimum(1, t / 0.02) * np.clip(1.2 - t * 1.6, 0, 1)
    return x * env


def land():
    n = int(SR * 0.32)
    t = np.arange(n) / SR
    bump = np.sin(2 * np.pi * 90 * t) * np.exp(-t / 0.05)
    x = bump * 0.9
    # plastic clatter: a few short, bright knocks, quieter and closer each bounce
    for i, (at, amp) in enumerate([(0.0, 1.0), (0.07, 0.6), (0.12, 0.4), (0.155, 0.25), (0.18, 0.15)]):
        s = int(at * SR)
        m = int(SR * 0.03)
        k = band(rng.standard_normal(m), 1800, 5200) * np.exp(-np.arange(m) / SR / 0.006) * amp
        x[s:s + m] += k[:max(0, min(m, n - s))]
    return x


def beep(hz, dur):
    """The classic start-light tone: a clean square-ish beep, a soft attack, a short tail"""
    n = int(SR * dur)
    t = np.arange(n) / SR
    x = np.sign(np.sin(2 * np.pi * hz * t)) * 0.35 + np.sin(2 * np.pi * hz * t) * 0.65
    x = low(x, 4000)
    env = np.minimum(1, t / 0.004) * np.minimum(1, (dur - t) / 0.04)
    return x * env


if __name__ == '__main__':
    save('rc_beep.wav', beep(660.0, 0.22))
    save('rc_go.wav', beep(1320.0, 0.6))
    save('rc_motor.wav', motor(), peak=0.6, fade=False)
    save('rc_fall.wav', fall())
    save('rc_land.wav', land())
    print('ok')
