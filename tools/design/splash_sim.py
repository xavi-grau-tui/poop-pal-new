"""Splash Hoops reach map: where does a ball land for a given pump pattern?

Mirror of the ball physics in scripts/splash_hoops.gd (one ball, no noise, NO basket or
ball-ball collisions, so treat results as "can reach", then confirm in game).
Keep the constants in sync with the script when tuning.

    python3 tools/design/splash_sim.py          # table: rest spot x pump pattern -> basket
Ball starts at the LEFT pump (rest spots 205 / 236 / 268 = outer / on nozzle / inner).
Pattern: left held hold_l, right held hold_r (started delay_r later)."""
import math
FLOOR_Y, SLOPE, NOZ = 866.0, 0.42, (237.0, 713.0)
G, DRAG, R = 380.0, 1.4, 16.0
CUPS = {"L100": (130, 545), "L200": (325, 470), "T300": (475, 330), "R200": (625, 470)}
RIM, TOP, F, PUMP = -16.0, 474.0, 2600.0, 0.9
MEET_PULL, MEET_DAMP, MEET_MIN_H, MEET_LIFT, MEET_WIDTH = 14.0, 4.5, 250.0, 1500.0, 110.0

def power_at(t, hold, st):
    held = t < hold
    if held:
        st['h'] += 1 / 240
        want = max(0.0, min(1.0, 1 - (st['h'] - PUMP) / 0.4))
    else:
        want = 0.0
    p = st['p']; rate = 14.0 if want > p else 5.0
    st['p'] = min(want, p + rate / 240) if want > p else max(want, p - rate / 240)
    return st['p']

def sim(x0, hold_l, hold_r=0.0, delay_r=0.0, conv=0.0, conv_band=(0, 700)):
    x = x0; y = FLOOR_Y - SLOPE * abs(x0 - NOZ[0]) - R
    vx = vy = 0.0; t = 0.0; dt = 1 / 240; apex = y; hits = []
    sl, sr = {'h': 0, 'p': 0}, {'h': 0, 'p': 0}
    while t < 6.0:
        pl = power_at(t, hold_l, sl)
        pr = power_at(t - delay_r, hold_r, sr) if t >= delay_r else 0.0
        fx = fy = 0.0
        h = FLOOR_Y - y
        both = min(pl, pr)
        for nx, p in ((NOZ[0], pl), (NOZ[1], pr)):
            if y >= TOP and p > 0.01:
                dx = x - nx; w = 40 + h * 0.42
                fade = min(1, (y - TOP) / 60)
                k = p * math.exp(-(dx / w) ** 2) * fade
                fan = max(0, min(1, (h - 120) / 250))
                fx += (math.copysign(1, dx) if dx else 0) * 0.3 * fan * F * k * (1 - both)   # meeting currents cancel the fan
                fy -= F * k
        if conv and both > 0.01 and conv_band[0] < h < conv_band[1]:
            fx += both * (MEET_PULL * (475 - x) - MEET_DAMP * vx)
            fy -= both * MEET_LIFT * math.exp(-((x - 475) / MEET_WIDTH) ** 2)
        vy += G * dt; vx += fx * dt; vy += fy * dt
        d = max(0, 1 - DRAG * dt); vx *= d; vy *= d
        py = y; x += vx * dt; y += vy * dt; apex = min(apex, y)
        for n, (cx, cy) in CUPS.items():
            if vy > 0 and py - cy <= RIM < y - cy and abs(x - cx) < 32:
                hits.append(n)
        fl = FLOOR_Y - SLOPE * min(abs(x - NOZ[0]), abs(x - NOZ[1]))
        if y > fl - R:
            if t > max(hold_l, hold_r + delay_r) + 0.1:
                break
            y = fl - R; vy = min(vy, 0)
        t += dt
    return round(apex), round(x), hits

import sys
conv, band = 1.0, (MEET_MIN_H, 9999)
for x0 in (205, 236, 268):
    row = []
    for hl, hr, dl in ((0.5, 0, 0), (0.7, 0, 0), (0.7, 0.7, 0), (0.9, 0.9, 0), (0.9, 0.9, 0.15), (1.2, 1.2, 0)):
        a, xl, hits = sim(x0, hl, hr, dl, conv, band)
        row.append(f"L{hl}/R{hr}@{dl}: {hits or '-'} x={xl}")
    print(x0, " | ".join(row))
