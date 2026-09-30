"""Flush finale: a pixel sparkle that pops out of the end of the colon + a soft "cling".

  -> textures/pet/fx/flush_sparkle.png   5 frames of 17x17 art pixels in one strip
                                          (drawn 1 texel per art pixel, scaled up in game)
  -> sounds/fx/flush_cling.wav           synthesized: two soft bell notes, fast decay
  -> sounds/fx/unlock_ding.wav           tiny, soft rising "ding-ding" for "ITEM UNLOCKED!"
"""
import math, os, wave
import numpy as np
from PIL import Image

from hires import PROJ, SCR

N = 17
C = N // 2
WHITE, YELLOW, PINK = (255, 252, 236, 255), (255, 228, 140, 255), (255, 160, 196, 255)


def star(arm, diag, ring=0, dots=(), core=1):
    im = np.zeros((N, N, 4), np.uint8)
    put = lambda x, y, c: 0 <= x < N and 0 <= y < N and im.__setitem__((y, x), c)
    for i in range(1, arm + 1):                      # + arms, fading out along their length
        col = WHITE if i <= arm // 2 else (YELLOW if i < arm else PINK)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            put(C + dx * i, C + dy * i, col)
    for i in range(1, diag + 1):                     # x arms, shorter
        col = YELLOW if i < diag else PINK
        for dx, dy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
            put(C + dx * i, C + dy * i, col)
    for y in range(-core, core + 1):                 # bright diamond core
        for x in range(-core, core + 1):
            if abs(x) + abs(y) <= core:
                put(C + x, C + y, WHITE)
    if ring:
        for a in range(0, 360, 30):
            put(C + round(ring * math.cos(math.radians(a))), C + round(ring * math.sin(math.radians(a))), PINK)
    for x, y, c in dots:
        put(C + x, C + y, c)
    return im


FRAMES = [
    star(1, 0, core=1),
    star(4, 2, core=1),
    star(7, 3, ring=0, core=2),
    star(5, 2, ring=7, core=1, dots=[(-6, -3, YELLOW), (5, -6, YELLOW), (6, 4, WHITE), (-4, 6, WHITE)]),
    star(2, 0, core=0, dots=[(-7, -4, PINK), (6, -7, PINK), (7, 5, YELLOW), (-5, 7, YELLOW), (0, -8, PINK)]),
]


def cling(path, sr=44100):
    """Two quick bell notes (E6 then B6) built from inharmonic partials, soft and short."""
    def bell(f, dur, amp):
        t = np.arange(int(sr * dur)) / sr
        env = np.exp(-t * 7.0) * (1 - np.exp(-t * 900))           # 1 ms attack, fast ring-out
        tone = sum(a * np.sin(2 * math.pi * f * m * t) for m, a in ((1, 1.0), (2.76, .35), (5.4, .12), (8.93, .05)))
        return amp * env * tone
    out = np.zeros(int(sr * 0.9))
    a = bell(1318.5, 0.9, 0.55)
    b = bell(1975.5, 0.9 - 0.075, 0.45)
    out[:len(a)] += a
    out[int(sr * 0.075):int(sr * 0.075) + len(b)] += b
    out *= np.linspace(1, 0, len(out)) ** 0.5                     # clean tail
    out = out / np.abs(out).max() * 0.6
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
        w.writeframes((out * 32767).astype(np.int16).tobytes())


def unlock_ding(path, sr=44100):
    """Two short, soft triangle-ish notes (G6 -> C7): noticeable but not distracting."""
    def note(f, dur):
        t = np.arange(int(sr * dur)) / sr
        tri = 2 / math.pi * np.arcsin(np.sin(2 * math.pi * f * t))       # soft 8-bit-ish tone
        tone = tri * 0.8 + 0.2 * np.sin(2 * math.pi * f * 2 * t)
        env = (1 - np.exp(-t * 600)) * np.exp(-t * 14)
        return tone * env
    a, b = note(1568.0, 0.12), note(2093.0, 0.2)
    out = np.zeros(int(sr * 0.3))
    out[:len(a)] += a
    start = int(sr * 0.085)
    out[start:start + len(b)] += b[:len(out) - start]
    out = out / np.abs(out).max() * 0.5
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
        w.writeframes((out * 32767).astype(np.int16).tobytes())


if __name__ == '__main__':
    dest = os.path.join(PROJ, 'pet', 'fx')
    os.makedirs(dest, exist_ok=True)
    strip = np.concatenate(FRAMES, axis=1)
    Image.fromarray(strip, 'RGBA').save(os.path.join(dest, 'flush_sparkle.png'))
    prev = Image.new('RGBA', (strip.shape[1], N), (236, 170, 170, 255))
    prev.alpha_composite(Image.fromarray(strip, 'RGBA'))
    prev.resize((prev.width * 12, prev.height * 12), Image.NEAREST).save(os.path.join(SCR, 'sparkle_preview.png'))
    cling(os.path.join(PROJ, '..', 'sounds', 'fx', 'flush_cling.wav'))
    unlock_ding(os.path.join(PROJ, '..', 'sounds', 'fx', 'unlock_ding.wav'))
    print('ok')
