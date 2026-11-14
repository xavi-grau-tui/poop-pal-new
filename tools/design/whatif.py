#!/usr/bin/env python3
"""What-ifs on the pacing model (tools/design/pacing.py), for the questions of 12 November 2026.
Nothing here changes the model's defaults: each what-if patches it in memory and prints the three
players side by side. The numbers quoted in docs/loop_v2.md section 11 come from here.

  python3 tools/design/whatif.py stage4    the fourth stage: each exotic food its own mutant
                                           (4 per realm, 130 spirits) against today (2 per realm)
  python3 tools/design/whatif.py drinks    two drink tiers and the casual player's late games:
                                           the better drinks after the games, or one at most, or at 20
  python3 tools/design/whatif.py sendoff   (the core review, 14 November 2026) the meal clock when a send-off
                                           resets it, as scripts/pet_state.gd flush() does today
  python3 tools/design/whatif.py seven     ...the game as built has a 7th game the model leaves out: Pal Prix
                                           2177 (54 levels, 162 stars, 140 coins of prizes), won with Pal Prix 6-9
                                           or, a what-if, with 5-9; and the launch without Tomo Tunes
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


def sendoff():
    """The model serves every wait (a new Sho 3 min, Chu 10, Dai / mutant / legend 30). The game doesn't: a
    send-off (PetState.flush) sets the meal clock back to zero, and a known step costs nothing, so the wait
    after ANY new spirit can be skipped by sending it off and walking the known steps again."""
    def show(label):
        ps = {n: P.Player(n).run() for n in P.PLAYERS}
        print(f'--- {label}')
        for name, p in ps.items():
            month = [new for d, new in p.sessions if 2 <= d <= 30]
            print(f'{name:8} 30th spirit {P.fmt(p.when("pal 30)")):>18} | 60th {P.fmt(p.when("pal 60)")):>18} | all {P.fmt(p.when("pal 120)")):>18}'
                  f' | sessions with a new spirit, days 2-30: {sum(month) / len(month):.0%}')

    show('the model: every wait is served')
    P.WAIT_NEW = {1: 3, 2: 10, 3: 0, 4: 0, 5: 0}
    show('the game today, a player who sends a grown spirit off as soon as it is found')
    P.WAIT_NEW = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
    show('the game today, a player who sends off after every new spirit')


def seven(gate_level=54, tunes=True):
    """Pal Prix 2177 in the model: free, opened by clearing a Pal Prix level (54 as built: 6-9), its drink the
    races' (spicy), its prizes as in scripts/pal_prix_2.gd (SECRETS, FINALES: Moon Rock on 5-6, Stardust Sugar
    on 6-6, 140 coins). tunes=False: the launch without Tomo Tunes (never bought)."""
    P.GAMES = list(BASE_GAMES) + [('Pal Prix 2177', 0, 6, 1.0, 0.3)]
    if not tunes:
        P.GAMES[5] = ('Tummy Tunes', 0, 0, 1.3, 1.0)               # (no levels: "owned" from the start, never played)
    P.DRINK_OF = dict(BASE_DRINK_OF)
    P.DRINK_OF[6] = 'spicy'
    P.GATE_TYPES = dict(BASE_GATES)
    P.GATE_TYPES[6] = ['spicy'] * 5
    if not tunes:
        del P.GATE_TYPES[5]
    P.SMALL_GATES = dict(BASE_SMALL)
    P.SMALL_GATES[6] = ['spicy'] * 6
    P.FINDS = [f for f in BASE_FINDS if tunes or f[0] != 5] + [(6, 42, 'Moon Rock', 'vault'), (6, 51, 'Stardust Sugar', 'vault')]
    extra = {21: 10, 24: 15, 39: 10, 48: 10, 45: 30, 54: 60}       # its coin prizes past the model's 5 on 1-3

    orig_shop, orig_play, orig_init = P.Player.shop, P.Player.play_once, P.Player.__init__

    def init(self, name):
        orig_init(self, name)
        if not tunes:
            self.owned.append(5)

    def shop(self):
        if 6 not in self.owned and self.cleared[2][gate_level - 1]:
            P.GAMES[6] = ('Pal Prix 2177', 0, 6, 1.0, 0.3)
            self.buy_game(6)                                         # (won, not bought: whatever else is still to buy)
        P.GAMES[6] = ('Pal Prix 2177', 10 ** 9, 6, 1.0, 0.3)
        return orig_shop(self)

    def play_once(self):
        ok = orig_play(self)
        paid = self.__dict__.setdefault('paid2177', set())
        for lvl, coins in extra.items():
            if lvl not in paid and self.cleared[6][lvl - 1]:
                paid.add(lvl)
                self.earn(coins)
        return ok

    P.Player.shop, P.Player.play_once, P.Player.__init__ = shop, play_once, init
    ps = {n: P.Player(n).run() for n in P.PLAYERS}
    P.Player.shop, P.Player.play_once, P.Player.__init__ = orig_shop, orig_play, orig_init
    mx = sum(P.GAMES[g][2] * P.LEVELS * 3 for g in range(len(P.GAMES)))
    for name, p in ps.items():
        d90 = p.day_when(lambda s: s[1] >= 0.9 * mx)
        dall = p.day_when(lambda s: s[1] >= 0.999 * mx)
        print(f'{name:8} 2177 opens {P.fmt(p.when("buys Pal Prix 2177")):>18} | all spirits {P.fmt(p.when("pal 120)")):>18}'
              f' | 90% of the {mx} stars: day {d90 or "-"} | every star: day {dall or "-"} | coins earned {p.earned:.0f}, left {p.coins:.0f}')
    return ps


def seven_all():
    print('--- the model as it is (six games, no Pal Prix 2177): 972 stars')
    ps = {n: P.Player(n).run() for n in P.PLAYERS}
    for name, p in ps.items():
        print(f'{name:8} coins earned {p.earned:.0f}, left {p.coins:.0f}')
    print('--- with Pal Prix 2177, as built (won with Pal Prix 6-9, the masters\' finale)')
    seven(54)
    print('--- with Pal Prix 2177 won with Pal Prix 5-9 (the Phoenix Cup, the end of the main game)')
    seven(45)
    print('--- the launch without Tomo Tunes: five bought games and Pal Prix 2177 (as built)')
    seven(54, tunes=False)


BASE_GAMES, BASE_DRINK_OF, BASE_GATES, BASE_SMALL, BASE_FINDS = list(P.GAMES), dict(P.DRINK_OF), dict(P.GATE_TYPES), dict(P.SMALL_GATES), list(P.FINDS)

if __name__ == '__main__':
    what = sys.argv[1] if len(sys.argv) > 1 else ''
    if what == 'stage4':
        stage4()
    elif what == 'drinks':
        drinks()
    elif what == 'sendoff':
        sendoff()
    elif what == 'seven':
        seven_all()
    else:
        print(__doc__)
