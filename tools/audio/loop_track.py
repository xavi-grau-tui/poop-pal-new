"""Loops a Suno track for the game: measures its real tempo (Suno misses the BPM it's asked for),
finds the first beat and the last bar line before the quiet tail Suno leaves at the end, cuts
there and saves an OGG Vorbis that Godot loops from the first beat.

    <venv>/bin/python tools/audio/loop_track.py "sounds/music/Pixel Chase.mp3" [bpm_lo bpm_hi]

-> sounds/music/<name>.ogg, its .import (loop=true, loop_offset = the first beat, bpm), and the MP3
moved to sounds/music/originals/ (that folder has a .gdignore: kept, not imported).
Needs: macOS afconvert (MP3 -> WAV), numpy, soundfile. Writes in 4096-frame chunks with the
compression level given to SoundFile(): one big write crashed libsndfile before (2026-10-08).
"""
import os
import shutil
import subprocess
import sys
import tempfile
import wave
import numpy as np
import soundfile as sf

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))


def decode(mp3: str) -> tuple:
    tmp = os.path.join(tempfile.mkdtemp(), 'track.wav')
    subprocess.run(['afconvert', '-f', 'WAVE', '-d', 'LEI16@44100', mp3, tmp], check=True)
    with wave.open(tmp) as w:
        sr = w.getframerate()
        ch = w.getnchannels()
        x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768.0
    return x.reshape(-1, ch), sr


def onsets(mono: np.ndarray, sr: int, hop_s=0.0025) -> tuple:
    """A spectral-flux-like onset strength every hop_s seconds (positive energy rises)"""
    hop = int(sr * hop_s)
    n = len(mono) // hop
    e = np.sqrt(np.mean(mono[:n * hop].reshape(n, hop) ** 2, axis=1))
    flux = np.maximum(0.0, np.diff(e, prepend=e[0]))
    return flux, hop_s


def tempo(flux: np.ndarray, hop_s: float, lo: float, hi: float) -> tuple:
    """Fold the onsets onto the beat period, finely: the BPM whose folded peak is sharpest, and
    that peak's phase (s)"""
    t = np.arange(len(flux)) * hop_s
    best = (0.0, lo, 0.0)
    for bpm in np.arange(lo, hi, 0.01):
        period = 60.0 / bpm
        ph = (t % period) / period * 2 * np.pi
        z = np.sum(flux * np.exp(1j * ph))
        if abs(z) > best[0]:
            best = (abs(z), bpm, (np.angle(z) % (2 * np.pi)) / (2 * np.pi) * period)
    return best[1], best[2]


def phase_at(flux: np.ndarray, hop_s: float, bpm: float, lo: float, hi: float) -> float:
    """Where the beats fall (s, 0..one beat) on the bpm grid, from the onsets between lo and hi"""
    t = np.arange(len(flux)) * hop_s
    p = 60.0 / bpm
    m = (t >= lo) & (t < hi)
    z = np.sum(flux[m] * np.exp(1j * 2 * np.pi * (t[m] % p) / p))
    return (np.angle(z) % (2 * np.pi)) / (2 * np.pi) * p


def steady_tempo(flux: np.ndarray, hop_s: float, guess: float, start: float, end: float) -> tuple:
    """The BPM that keeps the track's start and its end on the same beat grid (no drift between
    the first and the last 25 s: a loop over the whole track stays on the beat), and that grid's
    phase. Finer than any single fold: 0.05 BPM off already drifts ~50 ms over 2.5 minutes.
    Tempos ~0.4 BPM apart also line up start and end (a whole beat apart, Pixel Chase 2026-10-15:
    106.70 and 107.20 both did), so of the drift-free ones it keeps the one whose beats line up
    best over the whole track."""
    t = np.arange(len(flux)) * hop_s
    found = []
    for bpm in np.arange(guess - 0.8, guess + 0.8, 0.005):
        p = 60.0 / bpm
        a = phase_at(flux, hop_s, bpm, start, start + 25.0)
        b = phase_at(flux, hop_s, bpm, end - 25.0, end)
        drift = abs((b - a + p / 2) % p - p / 2)
        if drift < 0.012:
            whole = abs(np.sum(flux * np.exp(1j * 2 * np.pi * (t % p) / p)))
            found.append((whole, bpm, a, drift))
    if not found:
        return guess, phase_at(flux, hop_s, guess, start, start + 25.0), -1.0
    whole, bpm, a, drift = max(found)
    return bpm, a, drift


def main():
    src = sys.argv[1]
    lo = float(sys.argv[2]) if len(sys.argv) > 2 else 80.0
    hi = float(sys.argv[3]) if len(sys.argv) > 3 else 125.0
    x, sr = decode(src)
    mono = x.mean(axis=1)
    flux, hop_s = onsets(mono, sr)
    # a coarse pass (kept in lo..hi: not half / double time), then the drift-free tempo
    bpm, _ = tempo(flux[::4], hop_s * 4, lo, hi)
    level0 = np.sqrt(np.convolve(mono ** 2, np.ones(2048) / 2048, mode='same'))
    loud0 = np.nonzero(level0 > np.median(level0[level0 > level0.max() * 0.08]) * 0.2)[0]
    bpm, phase, drift = steady_tempo(flux, hop_s, bpm, loud0[0] / sr + 0.5, loud0[-1] / sr - 0.5)
    print('tempo %.3f BPM, start-to-end drift %.1f ms' % (bpm, drift * 1000))
    beat = 60.0 / bpm
    # the first beat: the first beat-grid point where the music has started
    level = np.sqrt(np.convolve(mono ** 2, np.ones(2048) / 2048, mode='same'))
    started = np.argmax(level > level.max() * 0.08) / sr
    first = phase + np.ceil((started - phase - 0.02) / beat) * beat
    first = max(0.0, first)
    # the quiet tail: where the level falls for good below a fifth of the track's typical level
    typical = np.median(level[level > level.max() * 0.08])
    loud = np.nonzero(level > typical * 0.2)[0]
    tail = loud[-1] / sr
    bars = int((tail - first) / (beat * 4))
    end = first + bars * beat * 4
    name = os.path.splitext(os.path.basename(src))[0]
    out = os.path.join(os.path.dirname(src), name + '.ogg')
    a, b = int(round(0)), int(round(end * sr))       # (kept from the start: the loop jumps back to `first`)
    with sf.SoundFile(out, 'w', sr, x.shape[1], format='OGG', subtype='VORBIS', compression_level=0.6) as f:
        for i in range(a, b, 4096):
            f.write(x[i:min(b, i + 4096)])
    imp = out + '.import'
    with open(imp, 'w') as f:
        f.write('[remap]\n\nimporter="oggvorbisstr"\ntype="AudioStreamOggVorbis"\n\n[params]\n\n'
                'loop=true\nloop_offset=%.3f\nbpm=%s\nbeat_count=0\nbar_beats=4\n' % (first, round(bpm, 2)))
    orig = os.path.join(os.path.dirname(src), 'originals')
    os.makedirs(orig, exist_ok=True)
    shutil.move(src, os.path.join(orig, os.path.basename(src)))
    for extra in [src + '.import']:
        if os.path.exists(extra):
            os.remove(extra)
    print('%s: %.2f BPM, first beat %.3f s, loop end %.3f s (end of bar %d), music stops ~%.1f s'
          % (name, bpm, first, end, bars, tail))


if __name__ == '__main__':
    main()
