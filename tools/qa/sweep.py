#!/usr/bin/env python3
"""The difficulty curve AS BUILT, measured: every level of a game played by its autopilot, as a table.

    python3 tools/qa/sweep.py prix                 Pal Prix, the clean drive (one run)
    python3 tools/qa/sweep.py prix human=1 runs=5  ...a pretend regular player (lapses), five different runs
    python3 tools/qa/sweep.py prix2 | sumo skill=1 | sumo skill=2 | spin runs=3 | maze
    python3 tools/qa/sweep.py all                  every sweep of docs/difficulty_measured.md, and writes that file
    ... keep=DIR                                   the raw output of each run kept in DIR (and read back from it
                                                   when it is there: a table can be remade without playing again)

It runs tools/qa/shoot.sh headless at a fixed 60 fps step (FAST=1), as fast as the computer goes: a game's 54
levels take 1 to 4 minutes. Each game prints one "QA ..." line per level when its autopilot is on (qa_autopilot);
this file only reads those lines.

WHAT THE NUMBERS ARE, AND ARE NOT (the core review, docs/core_review.md, 14 November 2026):
  prix, prix2    the clean drive: an autopilot that steers perfectly. It tells a course's length, the margin between
                 a clean run and the par, and where even a clean run fails (an obstacle on the line).
  prix human=K   the same driver with a person's lapses (scripts/rc_racer.gd qa_human): which levels forgive a
                 mistake and which don't. Uncalibrated: read it as a shape, harder or easier than its neighbours.
  sumo skill=N   two simple fighters (1 drums and leans; 2 also shakes and pulls down). Neither is a good player.
  spin, maze     NOT players: Top Spin's never steers, Tilt Maze's rolls straight into holes. Their tables only
                 show that the levels run. Splash Hoops has no autopilot. These three need one (the plan, step 0).
"""
import os
import re
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
GAMES = {'prix': (0, 'Pal Prix'), 'prix2': (11, 'Pal Prix 2177'), 'sumo': (9, 'Paper Sumo'), 'spin': (8, 'Top Spin'), 'maze': (1, 'Tilt Maze')}
LEVELS = 54
PATTERNS = [
    # (regex, how to read it) -> {level, stars, time, par, slips}
    (re.compile(r'QA race (\d+) \((\w+)\) stars (\d) time ([\d.]+) par (\d+) crashes (\d+) place (\d)'),
     lambda m: dict(level=int(m[1]), stars=int(m[3]), time=float(m[4]), par=float(m[5]), slips=int(m[6]), place=int(m[7]))),
    (re.compile(r"QA race (\d+) \(([\w' ]+)\) stars (\d) time ([\d.]+) par (\d+) turbo (\d+) bumps (\d+) place (\d)"),
     lambda m: dict(level=int(m[1]), stars=int(m[3]), time=float(m[4]), par=float(m[5]), gold=float(m[6]), slips=int(m[7]), place=int(m[8]))),
    (re.compile(r"QA race (\d+) \(([\w' ]+)\) OUT OF LIVES at ([\d.]+)"), lambda m: dict(level=int(m[1]), stars=0, time=float(m[3]), slips=3)),
    (re.compile(r'QA sumo (\d)-(\d) (WON|LOST) (\d)-(\d) fight ([\d.]+)s par ([\d.]+)s stars (\d)'),
     lambda m: dict(level=(int(m[1]) - 1) * 9 + int(m[2]), stars=int(m[8]), time=float(m[6]), par=float(m[7]), slips=int(m[5]))),
    (re.compile(r"QA maze (\d+) \(([\w' ]+)\) stars (\d) time ([\d.]+) par (\d+) falls (\d+)"),
     lambda m: dict(level=int(m[1]), stars=int(m[3]), time=float(m[4]), par=float(m[5]), slips=int(m[6]))),
    (re.compile(r"QA maze (\d+) \(([\w' ]+)\) OUT OF LIVES at ([\d.]+) par (\d+)"), lambda m: dict(level=int(m[1]), stars=0, time=float(m[3]), par=float(m[4]), slips=3)),
    (re.compile(r"QA spin (\d+) \(([\w' ]+)\) stars (\d) spin (\d+) time ([\d.]+)"), lambda m: dict(level=int(m[1]), stars=int(m[3]), time=float(m[5]))),
    (re.compile(r"QA spin (\d+) \(([\w' ]+)\) LOST at ([\d.]+)"), lambda m: dict(level=int(m[1]), stars=0, time=float(m[3]))),
]


def parse(text):
    """level -> its result, from a run's output (a level with no line: the autopilot never finished it)"""
    out = {}
    for line in text.splitlines():
        for rx, read in PATTERNS:
            m = rx.search(line)
            if m:
                r = read(m)
                out[r['level']] = r
                break
    return out


def play(game, extra, keep, tag):
    """one run of all 54 levels: its output (from keep/<tag>.txt when it is there)"""
    path = os.path.join(keep, tag + '.txt') if keep else ''
    if path and os.path.exists(path):
        return open(path).read()
    env = dict(os.environ, FAST='1', HEADLESS='1', LINES_OUT='6000')
    cmd = [os.path.join(ROOT, 'tools', 'qa', 'shoot.sh'), f'game={GAMES[game][0]}', 'levels=' + ','.join(str(i) for i in range(1, LEVELS + 1)),
           'wait=400', 'until=done', 'timeout=30000'] + extra
    text = subprocess.run(cmd, env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL).stdout
    if path:
        os.makedirs(keep, exist_ok=True)
        open(path, 'w').write(text)
    return text


def sweep(game, opts, keep=''):
    """every run asked for: a list of {level: result}"""
    runs = int(opts.get('runs', 1))
    out = []
    for r in range(runs):
        extra = [f'{k}={v}' for k, v in opts.items() if k not in ('runs',)]
        if 'human' in opts:
            extra.append(f'seed={r}')
        tag = '_'.join([game] + [f'{k}{v}' for k, v in sorted(opts.items()) if k != 'runs'] + [str(r)])
        out.append(parse(play(game, extra, keep, tag)))
    return out


def table(game, runs, note=''):
    """a world a row: each level's stars (the mean of the runs; x = never cleared, ? = never finished), the world's
    stars of 27, the tries that failed, the time of a cleared run, how far under the par it was"""
    lines = [f'**{GAMES[game][1]}{": " + note if note else ""}** ({len(runs)} run{"s" if len(runs) > 1 else ""})', '',
             '| World | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | Stars of 27 | Tries failed | Seconds (cleared) | Under the par |',
             '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|']
    for w in range(6):
        cells, total, fails, tries, times, margins = [], 0.0, 0, 0, [], []
        for k in range(9):
            got = [r[w * 9 + k + 1] for r in runs if w * 9 + k + 1 in r]
            if not got:
                cells.append('?')
                continue
            tries += len(got)
            fails += sum(1 for g in got if g['stars'] == 0)
            mean = sum(g['stars'] for g in got) / len(got)
            total += mean
            cells.append('x' if mean == 0 else (f'{mean:.0f}' if len(runs) == 1 else f'{mean:.1f}'))
            for g in got:
                if g['stars'] > 0:
                    times.append(g['time'])
                    if 'par' in g and g['par'] > 0:
                        margins.append(1.0 - g['time'] / g['par'])
        secs = f'{min(times):.0f}-{max(times):.0f}' if times else '-'
        under = f'{100 * min(margins):.0f}% to {100 * max(margins):.0f}%' if margins else '-'
        lines.append(f'| {w + 1} | ' + ' | '.join(cells) + f' | {total:.1f} | {fails} of {tries} | {secs} | {under} |')
    return '\n'.join(lines)


ALL = [('prix', {}, 'the clean drive'), ('prix', {'human': '1', 'runs': '5'}, 'a pretend regular player (lapses)'),
       ('prix2', {}, 'the clean drive'), ('sumo', {'skill': '1'}, 'a fighter that drums and leans'),
       ('sumo', {'skill': '2'}, 'a fighter that also shakes and pulls down'), ('spin', {'runs': '3'}, 'NOT a player: it never steers'),
       ('maze', {}, 'NOT a player: it rolls into the holes')]


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return
    opts = dict(a.split('=', 1) for a in args[1:] if '=' in a)
    keep = opts.pop('keep', '')
    if args[0] == 'all':
        parts = ['# The difficulty curve as built, measured', '',
                 'Made by `python3 tools/qa/sweep.py all` (about half an hour; never edit this file). What each table is and',
                 'is not: the top of `tools/qa/sweep.py`. What they mean and what follows from them: `docs/core_review.md`.',
                 'A cell is the stars the autopilot got on that level (the mean of the runs; x = never cleared, ? = it',
                 'never finished the level).', '']
        for game, o, note in ALL:
            parts += [table(game, sweep(game, dict(o), keep), note), '']
        with open(os.path.join(ROOT, 'docs', 'difficulty_measured.md'), 'w') as f:
            f.write('\n'.join(parts))
        print('\n'.join(parts))
        return
    print(table(args[0], sweep(args[0], opts, keep)))


if __name__ == '__main__':
    main()
