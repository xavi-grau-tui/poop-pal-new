#!/usr/bin/env python3
"""Tomo Tunes: a Suno song split in two (the lead instrument, everything else) -> a level.

    .venv/bin/python tools/audio/tune_chart.py 1A "Wooden Steps"

Reads sounds/tunes/incoming/<id>/ (three MP3s as Suno names them: "<title>.mp3", "<title> (<Instrument>).mp3",
"<title> (Without <Instrument>).mp3"), and writes
  sounds/tunes/<id>/lead.ogg, backing.ogg      the pair the game plays in sync
  data/charts/tunes_<id>.json                  bpm, the beats, and the charts: easy / normal / hard = [time, lane, length]
  sounds/tunes/incoming/<id>/check_<chart>.wav the song with a click on every charted note (low / mid / high = the lane)
and prints the numbers a take is judged by (docs/tomo_tunes.md, section 2).

How: every note of the LEAD stem is found (its start, pitch, length). A beat grid is followed through the song from
the lead's own notes (Suno's timing wanders by tens of ms between phrases, so one fixed grid doesn't fit: the grid is
re-anchored note by note). A note's time in the chart is its real time in the audio; the grid only says whether it sits
on a beat, between two beats, or finer. Lanes are pitch: the notes split in three groups, low / middle / high.
Needs macOS afconvert, numpy, soundfile.
"""
import collections
import glob
import json
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np
import soundfile as sf

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
SR, HOP, NF = 22050, 128, 1024
FPS = SR / HOP
BACKING_UNDER = 6.0        # dB under the lead, as a phone speaker hears it: the target
MAX_HARMONICS = 80.0       # the most of the bass's 2nd / 3rd harmonics that may be added to reach it
NAMES = 'C C# D D# E F F# G G# A A# B'.split()


def decode(path, sr=SR, ch=1):
    tmp = tempfile.mktemp(suffix='.wav')
    subprocess.run(['afconvert', '-f', 'WAVE', '-d', f'LEI16@{sr}', '-c', str(ch), path, tmp], check=True)
    with wave.open(tmp) as w:
        x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768
    os.remove(tmp)
    return x if ch == 1 else x.reshape(-1, ch)


def find(folder):
    """the three files, by Suno's names: '(Without X)' = the backing, '(X)' = the lead, the other = the mix"""
    mp3 = sorted(glob.glob(os.path.join(folder, '*.mp3')))
    back = [f for f in mp3 if '(without' in f.lower()]
    lead = [f for f in mp3 if '(' in os.path.basename(f) and f not in back]
    mix = [f for f in mp3 if f not in back and f not in lead]
    if len(back) != 1 or len(lead) != 1 or len(mix) != 1:
        sys.exit(f'{folder}: wanted one "(Without ...)", one "(...)" and the full song, found {[os.path.basename(f) for f in mp3]}')
    return lead[0], back[0], mix[0]


def flux(x, lo, hi):
    fr = np.lib.stride_tricks.sliding_window_view(x, NF)[::HOP] * np.hanning(NF)
    sp = np.log1p(np.abs(np.fft.rfft(fr, axis=1)) * 20)
    f = np.fft.rfftfreq(NF, 1 / SR)
    return np.concatenate([[0], np.maximum(0, np.diff(sp[:, (f >= lo) & (f < hi)], axis=0)).sum(1)])


def notes_of(lead, lo=250.0, hi=9000.0):
    """every note of the lead: (start s, MIDI pitch, length s, strength)"""
    fl = flux(lead, lo, hi)
    fl /= np.percentile(fl, 99) + 1e-9
    win = int(FPS * 0.25)
    v = np.lib.stride_tricks.sliding_window_view(np.pad(fl, win, mode='edge'), 2 * win + 1)[:len(fl)]
    peak = np.lib.stride_tricks.sliding_window_view(np.pad(fl, 4, mode='edge'), 9).max(1) == fl
    idx = np.nonzero(peak & (fl > v.mean(1) + 0.8 * v.std(1)) & (fl > 0.12))[0]
    keep = []                                              # a flam or a double trigger within 90 ms is one note
    for i in idx:
        if keep and (i - keep[-1]) / FPS < 0.09:
            if fl[i] > fl[keep[-1]]:
                keep[-1] = i
        else:
            keep.append(i)
    env = np.sqrt(np.convolve(lead ** 2, np.ones(441) / 441, 'same'))
    n_fft = 4096
    f = np.fft.rfftfreq(n_fft * 2, 1 / SR)
    sel = (f > lo) & (f < 4500)
    out = []
    for k, i in enumerate(keep):
        t = i / FPS
        a = int((t + 0.01) * SR)
        seg = lead[a:a + n_fft]
        if len(seg) < n_fft:
            seg = np.pad(seg, (0, n_fft - len(seg)))
        sp = np.abs(np.fft.rfft(seg * np.hanning(n_fft), n_fft * 2))
        hz = f[sel][np.argmax(sp[sel])]
        end = keep[k + 1] / FPS if k + 1 < len(keep) else len(lead) / SR
        e = env[a:int(end * SR)]
        pk = e[:int(0.05 * SR)].max() if len(e) else 0.0
        below = np.nonzero(e < 0.25 * pk)[0]
        length = (below[0] / SR if len(below) else end - t)
        out.append((round(t, 3), int(round(69 + 12 * np.log2(hz / 440))), round(float(length), 3), float(fl[i])))
    return out


def follow_grid(times):
    """an eighth-note grid followed through the song: for each note its place on it (a float: whole = on the grid)
    and the grid's own times. Suno's tempo is steady inside a phrase and slips between phrases."""
    gaps = np.diff(times)
    p = float(np.median(gaps[(gaps > 0.2) & (gaps < 0.6)]))                 # one eighth
    if p > 0.45:
        p /= 2
    g, k0 = times[0], 0                                                    # the anchor: a grid time and its index
    place, anchors = [], [(0, times[0])]
    for t in times:
        q = (t - g) / p
        k = round(q)
        err = (q - k) * p
        if abs(err) < p * 0.22:                                            # on the grid: re-anchor on this note
            g, k0 = g + k * p + 0.5 * err, k0 + k
            if k:
                p += 0.05 * err / k
            anchors.append((k0, g))
            place.append(float(k0))
        else:
            place.append(k0 + q)
    ak = np.array([a[0] for a in anchors])
    at = np.array([a[1] for a in anchors])
    last = int(np.ceil(place[-1])) + 2
    grid = np.interp(np.arange(0, last), ak, at, right=np.nan)
    for i in range(len(grid)):                                             # past the last anchor: carry on at p
        if np.isnan(grid[i]):
            grid[i] = grid[i - 1] + p
    return np.array(place), grid, p


def beat_parity(grid, back):
    """which eighths are the beats: where the backing's kick is"""
    kick = flux(back, 30, 200)
    at = lambda ts: np.mean([kick[max(0, int(t * FPS) - 3):int(t * FPS) + 4].max() for t in ts if int(t * FPS) + 4 < len(kick)])
    even, odd = at(grid[0::2]), at(grid[1::2])
    return (0 if even >= odd else 1), max(even, odd) / (min(even, odd) + 1e-9)


def lanes_of(midi):
    """pitch -> lane: the notes in three groups of about the same size, one pitch always in one lane"""
    count = collections.Counter(midi)
    total, run, lane = len(midi), 0, {}
    for m in sorted(count):
        mid = run + count[m] / 2
        lane[m] = 0 if mid < total / 3 else (1 if mid < 2 * total / 3 else 2)
        run += count[m]
    return lane


def phone_loud(x, sr=44100):
    """loudness as a phone speaker plays it: almost nothing under ~250 Hz"""
    from scipy import signal
    y = signal.sosfilt(signal.butter(4, 300, 'hp', fs=sr, output='sos'), x.mean(1) if x.ndim > 1 else x)
    return float(np.sqrt((y ** 2).mean()) + 1e-9)


def balance(lead, back, mix, beats, sr=44100):
    """The band must carry the song alone when the lead is silent, on a phone. Suno's backing stem can be all bass
    and kick (1A: 99% under 250 Hz), which a phone speaker hardly plays.
    v1 (2026-11-12) rebuilt it hard: a driven bass, the full song's top band gated to the beats and raised 11 times,
    a soft limiter. On the phone it hissed and sounded clipped (the user). v2 is gentle and adds nothing but the
    bass's own 2nd and 3rd harmonics (250-900 Hz), clean, so the bass line is heard on a phone: no noise source, no
    limiter, no gating; both files then come down together until their sum has headroom. A thin band is fixed at the
    source: the prompt now asks for present drums (suno_prompts.py)."""
    from scipy import signal
    sos = lambda *a, **k: signal.butter(*a, fs=sr, output='sos', **k)
    dry, harm = np.zeros_like(back), np.zeros_like(back)
    for c in range(back.shape[1]):
        x = signal.sosfilt(sos(2, 35, 'hp'), back[:, c])
        low = signal.sosfilt(sos(4, 250, 'lp'), x)
        pk = float(np.abs(low).max()) + 1e-9
        n = low / pk
        dry[:, c] = (x - 0.9 * signal.sosfilt(sos(2, 130, 'lp'), x)) * 0.7     # the sub-bass nearly out (the user twice: too much sub-bass, hard to hear): the harmonics carry the bass
        harm[:, c] = signal.sosfilt(sos(4, [250, 900], 'bp'), (2 * n * n - 1) + 0.5 * (4 * n ** 3 - 3 * n)) * pk
    # the kick's harmonics are short peaks that eat the headroom (the pair came out quiet): levelled with a slow
    # gain (30 ms), which bends no waveform, so loud hits come down and the bass line between them comes up
    k = int(sr * 0.03)
    env = np.sqrt(signal.sosfiltfilt(sos(2, 30, 'lp'), (harm ** 2).mean(1)).clip(1e-12))
    ref = float(np.percentile(env, 60))
    harm = harm * np.clip((ref / (env + 1e-6)) ** 0.7, 0.15, 3.0)[:, None]
    want = phone_loud(lead) * 10 ** (-BACKING_UNDER / 20)
    g = 0.0                                                                # the harmonics' share: as much as the target needs
    for h in np.arange(0.0, MAX_HARMONICS + 0.01, 1.0):
        g = h
        if phone_loud(dry + h * harm) >= want:
            break
    out = dry + g * harm
    top = float(np.abs(out + lead).max()) / 0.89                           # the two play together: headroom for the sum
    if top > 1.0:
        out, lead = out / top, lead / top
    rep = (f'the bass harmonics added x{g:.2f}: {20 * np.log10(phone_loud(lead) / phone_loud(out)):.1f} dB under the lead '
           f'on a phone speaker (the stem as Suno gave it: {20 * np.log10(phone_loud(lead) / phone_loud(back)):.0f}); peak of the two together {float(np.abs(out + lead).max()):.2f}')
    return lead, out, rep


def write_ogg(path, x, sr):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with sf.SoundFile(path, 'w', samplerate=sr, channels=x.shape[1], format='OGG', subtype='VORBIS', compression_level=0.1) as f:
        for a in range(0, len(x), 4096):                                   # (one big write crashed libsndfile: loop_track.py)
            f.write(x[a:a + 4096])


def click_file(path, mix, chart):
    y = mix.copy()
    n = int(0.03 * SR)
    for t, lane, _ in chart:
        a = int(t * SR)
        if a + n < len(y):
            y[a:a + n] += 0.5 * np.sin(2 * np.pi * (900, 1500, 2400)[lane] * np.arange(n) / SR) * np.linspace(1, 0, n)
    with wave.open(path, 'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((np.clip(y, -1, 1) * 32767).astype(np.int16).tobytes())


def main():
    sid, title = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else sys.argv[1])
    folder = os.path.join(ROOT, 'sounds', 'tunes', 'incoming', sid)
    f_lead, f_back, f_mix = find(folder)
    lead, back, mix = decode(f_lead), decode(f_back), decode(f_mix)
    length = min(len(lead), len(back)) / SR
    notes = notes_of(lead)
    times = np.array([n[0] for n in notes])
    place, grid, p = follow_grid(times)
    parity, kick_ratio = beat_parity(grid, back)
    bpm = 30.0 / float(np.median(np.diff(grid)))
    lane = lanes_of([n[1] for n in notes])
    beat_len = 2 * p
    rows = []                                                              # (t, lane, hold length, kind) kind: 0 beat, 1 eighth, 2 finer
    for (t, m, ln, _), q in zip(notes, place):
        off = abs(q - round(q))
        kind = 2 if off > 0.22 else (0 if (int(round(q)) - parity) % 2 == 0 else 1)
        rows.append((t, lane[m], round(ln, 3) if ln >= beat_len else 0.0, kind))
    charts = {'easy': [list(r[:3]) for r in rows if r[3] == 0],
              'normal': [list(r[:3]) for r in rows if r[3] <= 1],
              'hard': [list(r[:3]) for r in rows]}
    beats = [round(float(t), 3) for t in grid[parity::2] if t < length]
    out = {'id': sid, 'title': title, 'bpm': round(bpm, 2), 'offset': beats[0], 'length': round(length, 2), 'beats': beats, 'charts': charts}
    with open(os.path.join(ROOT, 'data', 'charts', f'tunes_{sid}.json'), 'w') as f:
        json.dump(out, f)
    st = {name: decode(src, 44100, 2)[:int(length * 44100)] for name, src in (('lead', f_lead), ('backing', f_back), ('mix', f_mix))}
    n = min(len(v) for v in st.values())
    st = {k: v[:n] for k, v in st.items()}
    lead2, band, report = balance(st['lead'], st['backing'], st['mix'], beats)
    write_ogg(os.path.join(ROOT, 'sounds', 'tunes', sid, 'lead.ogg'), lead2, 44100)
    write_ogg(os.path.join(ROOT, 'sounds', 'tunes', sid, 'backing.ogg'), band, 44100)
    for name in charts:
        click_file(os.path.join(folder, f'check_{name}.wav'), mix, charts[name])

    kinds = collections.Counter(r[3] for r in rows)
    gaps = np.diff(times)
    drift = np.diff(grid)
    print(f'{sid} "{title}": {length:.1f} s, {bpm:.2f} BPM (an eighth {1000 * drift.min():.0f}-{1000 * drift.max():.0f} ms through the song)')
    print(f'  lead: {len(notes)} notes; on a beat {kinds[0]}, between beats {kinds[1]}, finer {kinds[2]} ({100 * (kinds[0] + kinds[1]) / len(notes):.0f}% on the eighth grid)')
    print(f'  the beats are where the kick is: {kick_ratio:.1f}x stronger there' + ('' if kick_ratio > 1.3 else '  (WEAK: check the easy chart by ear)'))
    print('  pitches: ' + ' '.join(f'{NAMES[m % 12]}{m // 12 - 1}x{c}>{"LMR"[lane[m]]}' for m, c in sorted(collections.Counter(n[1] for n in notes).items())))
    print(f'  longest silence {gaps.max():.1f} s ({gaps.max() / (4 * beat_len):.1f} bars); holds: {sum(1 for r in rows if r[2] > 0)}')
    print('  the band: ' + report)
    for name, c in charts.items():
        ls = collections.Counter(n[1] for n in c)
        print(f'  {name:6} {len(c):3d} notes, {len(c) / length:.1f} a second, lanes L/M/R {ls[0]}/{ls[1]}/{ls[2]}')


if __name__ == '__main__':
    main()
