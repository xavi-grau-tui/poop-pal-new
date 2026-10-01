"""TUMMY TUNES chart maker: turns a song into note charts (no MIDI needed).

1. Spectral flux in three bands (low / mid / high) finds where sounds start.
2. The tempo and beat phase are fitted to those onsets, and onsets are snapped to the grid.
3. Bands become lanes: low -> left (mute button), mid -> middle (main), high -> right (forward).
4. Three charts: easy (quarter notes, one lane), normal (eighths), hard (sixteenths, chords).

    python3 tools/design/rhythm_chart.py "sounds/music/Retro Game Console.mp3" data/charts/retro_game_console.json

Needs numpy (decoding uses macOS afconvert). Output JSON:
  { "bpm": float, "offset": first beat (s), "length": s,
    "charts": { "easy": [[time, lane], ...], "normal": [...], "hard": [...] } }
"""
import json, os, subprocess, sys, tempfile, wave
import numpy as np

SR, HOP, NFFT = 22050, 256, 2048
BANDS = [(35, 180), (180, 1400), (1400, 8000)]       # lanes 0 / 1 / 2


def load(path):
    tmp = tempfile.mktemp(suffix=".wav")
    subprocess.run(["afconvert", "-f", "WAVE", "-d", f"LEI16@{SR}", "-c", "1", path, tmp], check=True)
    w = wave.open(tmp)
    x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768
    os.remove(tmp)
    return x


def band_flux(x):
    frames = np.lib.stride_tricks.sliding_window_view(x, NFFT)[::HOP] * np.hanning(NFFT)
    spec = np.log1p(np.abs(np.fft.rfft(frames, axis=1)) * 10)
    freqs = np.fft.rfftfreq(NFFT, 1 / SR)
    out = []
    for lo, hi in BANDS:
        sel = (freqs >= lo) & (freqs < hi)
        f = np.maximum(0, np.diff(spec[:, sel], axis=0)).sum(1)
        f = np.concatenate([[0], f])
        out.append(f / (np.percentile(f, 99) + 1e-9))
    return np.array(out)                                  # (3, frames)


def peaks(f, k=1.2, win=43):
    """Local maxima above an adaptive threshold (moving mean + k * moving std)."""
    pad = np.pad(f, win, mode="edge")
    view = np.lib.stride_tricks.sliding_window_view(pad, 2 * win + 1)[: len(f)]
    thr = view.mean(1) + k * view.std(1)
    loc = np.lib.stride_tricks.sliding_window_view(np.pad(f, 3, mode="edge"), 7).max(1) == f
    idx = np.nonzero(loc & (f > thr) & (f > 0.08))[0]
    return idx, f[idx]


def fit_grid(onset_times, strengths, bpm_guess):
    """Best tempo (+-4 BPM) and phase so onsets fall on 8th notes."""
    best = (-1, bpm_guess, 0.0)
    for bpm in np.arange(bpm_guess - 4, bpm_guess + 4, 0.02):
        step = 60 / bpm / 2
        phases = np.linspace(0, step, 40, endpoint=False)
        for ph in phases:
            d = (onset_times - ph) / step
            err = np.abs(d - np.round(d))
            score = (strengths * np.exp(-(err / 0.12) ** 2)).sum()
            if score > best[0]:
                best = (score, bpm, ph)
    return best[1], best[2]


def estimate_bpm(flux):
    total = flux.sum(0)
    total = total - total.mean()
    ac = np.correlate(total, total, "full")[len(total) - 1:]
    fps = SR / HOP
    best = max(((ac[int(round(60 / b * fps))] + 0.5 * ac[int(round(120 / b * fps))], b) for b in np.arange(70, 181, 0.5)))
    return best[1]


def make_charts(path):
    x = load(path)
    flux = band_flux(x)
    fps = SR / HOP
    bpm0 = estimate_bpm(flux)
    # all onsets (any band) to fit the grid
    allt, alls = [], []
    for b in range(3):
        idx, st = peaks(flux[b])
        allt += list(idx / fps)
        alls += list(st)
    allt, alls = np.array(allt), np.array(alls)
    bpm, phase = fit_grid(allt, alls, bpm0)
    beat = 60 / bpm
    length = len(x) / SR
    # strength of each band at each 16th-note slot
    n16 = int(length / (beat / 4)) + 1
    slots = np.zeros((3, n16))
    for b in range(3):
        idx, st = peaks(flux[b], k=0.9)
        for i, s in zip(idx, st):
            t = i / fps
            q = (t - phase) / (beat / 4)
            k = int(round(q))
            if 0 <= k < n16 and abs(q - k) < 0.35:
                slots[b, k] = max(slots[b, k], s)
    t_of = lambda k: round(phase + k * beat / 4, 3)

    def chart(every, max_lanes, thresh, min_gap16):
        notes, last = [], [-99, -99, -99]
        for k in range(0, n16, every):
            s = slots[:, k] if every == 1 else slots[:, k:k + every].max(1)
            order = [b for b in np.argsort(-s) if s[b] >= thresh]
            used = 0
            for b in order:
                if used >= max_lanes or k - last[b] < min_gap16:
                    continue
                notes.append([t_of(k), int(b)])
                last[b] = k
                used += 1
        return notes

    lead = 2.0                                       # nothing in the first 2 s (count-in)
    charts = {
        "easy": chart(4, 1, 0.45, 4),       # ~2 notes/s, quarter notes, never two at once
        "normal": chart(2, 1, 0.75, 2),     # ~3 notes/s, eighths
        "hard": chart(2, 2, 0.6, 2),        # ~5 notes/s, eighths with chords
    }
    for k in charts:
        charts[k] = [n for n in charts[k] if n[0] >= lead]
    return {"bpm": round(bpm, 3), "offset": round(phase, 3), "length": round(length, 2), "charts": charts}


if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    data = make_charts(src)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with open(dst, "w") as f:
        json.dump(data, f)
    for k, v in data["charts"].items():
        lanes = np.bincount([n[1] for n in v], minlength=3)
        print(f"{k:6s} {len(v):4d} notes  {len(v) / data['length']:.1f}/s  lanes L/M/R = {lanes.tolist()}")
    print("bpm", data["bpm"], "offset", data["offset"])
