#!/usr/bin/env python3
"""What-ifs on the pacing model (tools/design/pacing.py), for the questions of 12 November 2026.
Nothing here changes the model's defaults: each what-if patches it in memory and prints the three
players side by side. The numbers quoted in docs/loop_v2.md section 11 come from here.

  python3 tools/design/whatif.py stage4    the fourth stage: each exotic food its own mutant
                                           (4 per realm, 130 spirits) against today (2 per realm)
  python3 tools/design/whatif.py drinks    two drink tiers and the casual player's late games:
                                           the better drinks after the games, or one at most, or at 20
"""
import copy
import sys

import pacing as P

EXOTIC = ['Microchip', 'Battery', 'Alien Goo', 'Moon Rock']
BASE = P.tree()


def tree4():
    """today's tree with a second tech and a second cosmic mutant per realm: the Battery's and the
    Moon Rock's own (the Microchip and the Alien Goo keep today's)"""
    t = copy.deepcopy(BASE)
    for a, f in list(t['forms'].items()):
        if f['stage'] != 3:
            continue
        nx = t['next'][a]
        for food in EXOTIC:
            kind = P.SPECIAL_KIND[food]
            mid = nx[kind] if food in ('Microchip', 'Alien Goo') else nx[kind] + '_' + food.lower().replace(' ', '')
            if mid not in t['forms']:
                m = dict(t['forms'][nx[kind]])
                m['name'] += ' II'
                t['forms'][mid] = m
            nx[food] = mid
    return t


def special_result4(self, food, form=None):
    form = self.form if form is None else form
    if not form or self.stage(form) != 3:
        return ''
    if P.SPECIAL_KIND[food] == 'legend':
        lg = self.T['legend'].get(form)
        return lg['to'] if lg and lg['family'] == P.LEGEND_OF[food] else ''
    return self.T['next'].get(form, {}).get(food, '')


def stage4():
    def show(label):
        ps = {n: P.Player(n).run() for n in P.PLAYERS}
        n = len(ps['regular'].T['forms'])
        print(f'--- {label}: {n} spirits')
        for name, p in ps.items():
            muts = [d for t, d, w in p.log if 'mutant, pal' in w]
            month = [new for d, new in p.sessions if 2 <= d <= 30]
            print(f'{name:8} all spirits {P.fmt(p.when(f"pal {n})")):>18} | mutants {len(muts):>2} (days {muts[0]}-{muts[-1]})'
                  f' | special foods bought {p.spent.get("special foods", 0):>4.0f} coins | earned {p.earned:.0f}, left {p.coins:.0f}'
                  f' | sessions with a new spirit, days 2-30: {sum(month) / len(month):.2f}')

    show('today (tech / cosmic: 2 mutants per realm)')
    P.tree = tree4
    P.Player.special_result = special_result4
    show('each exotic food its own mutant (4 per realm), same finds, same shelf')
    # the missing foods placed in the games: one more of each as a world's secret prize (worlds 3-4)
    P.FINDS = list(P.FINDS) + [(0, 24, 'Microchip', 'vault'), (4, 24, 'Battery', 'vault'), (5, 24, 'Alien Goo', 'vault'),
                               (3, 24, 'Moon Rock', 'vault'), (0, 33, 'Alien Goo', 'vault'), (4, 33, 'Microchip', 'vault')]
    show('...plus 6 more exotic foods as secret prizes')


def drinks():
    def show(label):
        ps = {n: P.Player(n).run() for n in P.PLAYERS}
        mx = sum(P.GAMES[g][2] * P.LEVELS * 3 for g in range(len(P.GAMES)))
        print(f'--- {label}')
        for name, p in ps.items():
            d90 = p.day_when(lambda s: s[1] >= 0.9 * mx)
            print(f'{name:8} Top Spin {P.fmt(p.when("buys Top Spin")):>18} | Tummy Tunes {P.fmt(p.when("buys Tummy Tunes")):>18}'
                  f' | first better drink {P.fmt(p.when("level 2")):>18} | all spirits {P.fmt(p.when("pal 120)")):>18}'
                  f' | 90% of the stars: day {d90 or "-"} | powered {p.powered / p.t * 100:.0f}%')

    orig = P.Player.wanted_drink
    show('two tiers as in the model (the better drink 30, bought as soon as a gate wants it)')

    def games_first(self):
        return None if any(g not in self.owned for g in range(len(P.GAMES))) else orig(self)
    P.Player.wanted_drink = games_first
    show('the better drinks wait until every game is owned')

    def one_ahead(self):
        d = orig(self)
        if d and any(g not in self.owned for g in range(len(P.GAMES))) and any(v >= 2 for v in self.drink_lvl.values()):
            return None
        return d
    P.Player.wanted_drink = one_ahead
    show('one better drink at most while a game is still to buy')

    P.Player.wanted_drink = orig
    P.DRINK_PRICE = {2: 20}
    show('the better drink at 20')


if __name__ == '__main__':
    what = sys.argv[1] if len(sys.argv) > 1 else ''
    if what == 'stage4':
        stage4()
    elif what == 'drinks':
        drinks()
    else:
        print(__doc__)
