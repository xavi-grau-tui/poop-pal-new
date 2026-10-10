"""HaraTomo pacing model (Progression v2): WHEN does a player get WHAT?

Nothing is left to chance: a fixed player model (no dice), the real prices and the real evolution
tree, so changing a price shows its effect on the timeline straight away. The player numbers are
ASSUMED until measured on the phone (level times, stars on a first try): replace them then.

  python3 tools/design/pacing.py              the three players side by side + the checks
  python3 tools/design/pacing.py regular      one player's whole timeline

Keep PRICES in step with scripts/game_data.gd and scripts/shop.gd (the drink levels are PROPOSED,
docs/ideas_roadmap.md "Drinks v2").
"""
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

# --- prices (the game's)
GAME_PRICES = [5, 40, 60, 90, 135]                # the games' own prices, cheapest first (players buy in this order)
PACK_PRICE = {'baby': 10, 'kid': 15, 'adult': 20}  # a food pack, by its size (9 packs: 145)
START_FOODS = {'baby': ['green', 'sweet', 'greasy'], 'kid': ['green', 'sweet'], 'adult': ['green']}
DRINK_PRICE = {2: 15, 3: 30}                      # PROPOSED: a drink type's level 2 / level 3
DRINK_TYPES = ['watery', 'fizzy', 'caffeinated', 'milky', 'fruity']   # one more with each game
GIFTS_AT = [5, 15, 30, 60, 100]                   # each game's gift track (its star total)
FAMS = ['green', 'sweet', 'greasy', 'spicy', 'sour']
TIERS = ['baby', 'kid', 'adult']

# --- the levels (every game the same shape)
GAMES, WORLDS, LEVELS = 6, 5, 9
# PROPOSED secrets: one per world from world 2 on, behind a gate of a drink type and level
# (the type: one the player has by then; world 2 = level 1, 3 and 4 = level 2, 5 = level 3)
GATE_LEVEL = {2: 1, 3: 2, 4: 2, 5: 3}

# --- the player (ASSUMED until measured)
ATTEMPT_MIN = [0.85, 0.9, 0.95, 1.0, 1.0]         # one try of a level, menus included, per world
FAIL = [0.05, 0.12, 0.2, 0.27, 0.33]              # a try that ends with no star, per world
FIRST_STARS = [2.4, 2.1, 1.8, 1.6, 1.4]           # stars when a level is first cleared, per world
REPLAY_STARS = [0.6, 0.5, 0.4, 0.35, 0.3]         # stars per replay, going back for missing ones
DRINK_EVERY = 15                                  # minutes between drinks (LcdScreen)
MEAL_EVERY = 30                                   # minutes between meals
PLAYERS = {
    # name: (minutes of play per day: day 1, days 2-7, then; meals a day outside play)
    'casual': ([20, 12, 8], 2),
    'regular': ([60, 30, 20], 2),
    'keen': ([180, 60, 40], 3),
}
TARGETS = {                      # the checks (minutes of play unless it says days)
    'first coin buys something': 5,
    'longest wait for something new, first 2 h': 15,
    'the 3rd game, at most': 60,
    'every game, days (regular)': 10,
    'coins left for special foods, at least': 150,
}


def tree():
    with open(os.path.join(ROOT, 'data', 'evolution_tree.json')) as f:
        return json.load(f)


class Player:
    def __init__(self, name):
        self.name = name
        self.per_day, self.meals_out = PLAYERS[name]
        self.t = 0.0                    # minutes of play
        self.day = 1
        self.coins = 0
        self.games = 1
        self.stars = [[0.0] * (WORLDS * LEVELS) for _ in range(GAMES)]
        self.first_done = [[False] * (WORLDS * LEVELS) for _ in range(GAMES)]
        self.foods = {k: list(v) for k, v in START_FOODS.items()}
        self.drink_lvl = {'watery': 1}
        self.secrets = 0
        self.secret_done = set()
        self.next_drink = 0.0
        self.gifts = [0] * GAMES
        self.log = []                   # (minute, day, what)
        self.last_new = 0.0
        self.longest_gap = 0.0
        self.max_unspent = 0
        self.T = tree()
        self.form = ''                  # the pal
        self.found = set()
        self.next_meal = 0.0

    # --- events
    def new(self, what):
        if self.t <= 120:
            self.longest_gap = max(self.longest_gap, self.t - self.last_new)
        self.last_new = self.t
        self.log.append((self.t, self.day, what))

    def pay(self, n, what):
        self.coins -= n
        self.new(f'{what} ({n})')

    # --- buying (a typical player, nudged by the onboarding: the deterministic order of wishes)
    def packs_bought(self):
        return sum(len([f for f in self.foods[t] if f not in START_FOODS[t]]) for t in TIERS)

    def shop(self):
        while True:
            if self.games < 2 and self.coins >= GAME_PRICES[0]:
                self.games = 2
                self.drink_lvl['fizzy'] = 1
                self.pay(GAME_PRICES[0], 'buys Tilt Maze (+ Fizzy drinks)')
                continue
            need = self.wanted_pack()
            price = PACK_PRICE[need[1]] if need else 0
            if need and self.coins >= price:
                self.foods[need[1]].append(need[0])
                self.pay(price, f'buys {need[0]} {need[1]} food')
                continue
            dr = self.wanted_drink()
            if dr and self.coins >= DRINK_PRICE[dr[1]]:
                self.drink_lvl[dr[0]] = dr[1]
                self.pay(DRINK_PRICE[dr[1]], f'buys {dr[0]} drink level {dr[1]}')
                continue
            if 2 <= self.games < GAMES and self.coins >= GAME_PRICES[self.games - 1]:
                self.games += 1
                if self.games <= len(DRINK_TYPES):
                    self.drink_lvl[DRINK_TYPES[self.games - 1]] = 1
                self.pay(GAME_PRICES[self.games - 2], f'buys game {self.games}' +
                         (f' (+ {DRINK_TYPES[self.games - 1]} drinks)' if self.games <= len(DRINK_TYPES) else ''))
                continue
            rest = [(t, f) for t in TIERS for f in FAMS if f not in self.foods[t]]
            spare = self.coins - (0 if self.games == GAMES else GAME_PRICES[self.games - 1])
            if rest and spare >= PACK_PRICE[rest[0][0]]:
                t, f = rest[0]                  # the rest of the packs, when the next game is paid for anyway
                self.foods[t].append(f)
                self.pay(PACK_PRICE[t], f'buys {f} {t} food')
                continue
            break
        self.max_unspent = max(self.max_unspent, self.coins)

    def wanted_pack(self):
        """the pack the pal's next meal needs to find someone new (the size it eats next)"""
        st = self.stage()
        tier = TIERS[min(st, 2)] if st < 3 else 'baby'
        if self.new_options(tier, self.foods[tier]):
            return None                          # something new to find already: no need yet
        for f in FAMS:
            if f not in self.foods[tier] and self.new_options(tier, [f]):
                return (f, tier)
        return None

    def wanted_drink(self):
        """a level the next secret in a game you play needs"""
        for g in range(self.games):
            for w in range(2, WORLDS + 1):
                if (g, w) in self.secret_done or not self.reached(g, w):
                    continue
                typ = self.gate_type(w)
                lvl = GATE_LEVEL[w]
                have = self.drink_lvl.get(typ, 0)
                if have and have < lvl and have + 1 in DRINK_PRICE:
                    return (typ, have + 1)
        return None

    # --- pals
    def stage(self):
        return 0 if not self.form else int(self.T['forms'][self.form]['stage'])

    def result(self, fam):
        if not self.form:
            return self.T['starters'][fam]
        return self.T['next'].get(self.form, {}).get(fam, '')

    def new_options(self, tier, fams):
        if self.stage() >= 3:
            return [f for f in fams if self.T['starters'][f] not in self.found]
        return [f for f in fams if self.result(f) and self.result(f) not in self.found]

    def unfound_below(self, form, depth):
        """pals not found yet at `form` or after it, with the foods you have"""
        n = 0 if form in self.found else 1
        if depth < 2:
            tier = TIERS[depth + 1]
            for f in self.foods[tier]:
                to = self.T['next'].get(form, {}).get(f, '')
                if to:
                    n += self.unfound_below(to, depth + 1)
        return n

    def meal(self):
        st = self.stage()
        if st >= 3:
            self.form = ''                       # flush, and a new pal hatches
            st = 0
        tier = TIERS[st]
        # the food that leads to the most pals not found yet (the Pal Pedia's "?"s guide the player)
        opts = sorted(self.foods[tier], key=lambda f: -self.unfound_below(self.result(f), st) if self.result(f) else 1)
        to = self.result(opts[0])
        if to:
            self.form = to
            if to not in self.found:
                self.found.add(to)
                self.new(f'meets {self.T["forms"][to]["name"]} (pal {len(self.found)})')

    # --- playing
    def gate_type(self, w):
        return DRINK_TYPES[min(w - 2, len(DRINK_TYPES) - 1)] if w - 2 < 2 else DRINK_TYPES[(w - 2) % 3]

    def reached(self, g, w):
        return self.first_done[g][(w - 1) * LEVELS]

    def next_level(self):
        """the easiest stars on offer: the first unplayed level of the lowest world, newest game
        first; when every first pass is done, the best replay"""
        best = None
        for g in reversed(range(self.games)):
            for i in range(WORLDS * LEVELS):
                if not self.first_done[g][i]:
                    if best is None or i // LEVELS < best[1] // LEVELS:
                        best = (g, i, 'first')
                    break
        if best:
            return best
        cand = [(REPLAY_STARS[i // LEVELS], g, i) for g in range(self.games) for i in range(WORLDS * LEVELS) if self.stars[g][i] < 2.95]
        if not cand:
            return None
        _, g, i = max(cand)
        return (g, i, 'replay')

    def play(self, minutes):
        end = self.t + minutes
        while self.t < end:
            if self.t >= self.next_meal:
                self.meal()
                self.next_meal = self.t + MEAL_EVERY
            nl = self.next_level()
            if not nl:
                self.t = end
                break
            g, i, kind = nl
            w = i // LEVELS
            if kind == 'first':
                self.t += ATTEMPT_MIN[w] / (1 - FAIL[w])
                got = FIRST_STARS[w]
                self.first_done[g][i] = True
                if i % LEVELS == 0 and w > 0:
                    self.new(f'reaches world {w + 1} of game {g + 1}')
            else:
                self.t += ATTEMPT_MIN[w]
                got = min(REPLAY_STARS[w], 3 - self.stars[g][i])
            self.stars[g][i] += got
            self.coins += got
            total = sum(self.stars[g])
            while self.gifts[g] < len(GIFTS_AT) and total >= GIFTS_AT[self.gifts[g]]:
                self.gifts[g] += 1
                self.new(f'gift {self.gifts[g]} of game {g + 1}')
            # a secret: its world reached, a drink of the right type and level ready
            for w2 in range(2, WORLDS + 1):
                if (g, w2) not in self.secret_done and self.reached(g, w2) and self.t >= self.next_drink:
                    typ = self.gate_type(w2)
                    if self.drink_lvl.get(typ, 0) >= GATE_LEVEL[w2]:
                        self.secret_done.add((g, w2))
                        self.secrets += 1
                        self.next_drink = self.t + DRINK_EVERY
                        self.new(f'opens secret {self.secrets} (game {g + 1}, world {w2})')
            self.shop()

    def run(self, days):
        for d in range(1, days + 1):
            self.day = d
            mins = self.per_day[0] if d == 1 else self.per_day[1] if d <= 7 else self.per_day[2]
            self.play(mins)
            for _ in range(self.meals_out):      # meals outside play (quick visits later that day)
                self.meal()
            self.next_meal = self.t              # the next session starts with a meal
        return self

    def when(self, text):
        for t, d, what in self.log:
            if text in what:
                return t, d
        return None


def fmt(w):
    return '-' if not w else f'{w[0]:4.0f} min (day {w[1]})'


def main():
    if len(sys.argv) > 1:
        p = Player(sys.argv[1]).run(30)
        for t, d, what in p.log:
            print(f'{t:6.0f} min  day {d:2}  {what}')
        return
    ps = {n: Player(n).run(60) for n in PLAYERS}
    rows = [('Tilt Maze', 'buys Tilt Maze'), ('3rd game', 'buys game 3'), ('4th game', 'buys game 4'),
            ('5th game', 'buys game 5'), ('6th game', 'buys game 6'), ('first food pack', 'food ('),
            ('first drink level 2', 'level 2'), ('first drink level 3', 'level 3'), ('first secret', 'opens secret 1 '),
            ('10th pal', '(pal 10)'), ('30th pal', '(pal 30)'), ('60th pal', '(pal 60)')]
    print(f'{"":22}' + ''.join(f'{n:>22}' for n in ps))
    for label, key in rows:
        print(f'{label:22}' + ''.join(f'{fmt(p.when(key)):>22}' for p in ps.values()))
    print()
    r = ps['regular']
    print('checks (regular player):')
    first = r.when('buys Tilt Maze')[0]
    g3 = r.when('buys game 3')
    g6 = r.when('buys game 6')
    for label, ok, val in [
        ('first coin buys something', first <= TARGETS['first coin buys something'], f'{first:.0f} min'),
        ('longest wait for something new, first 2 h', r.longest_gap <= TARGETS['longest wait for something new, first 2 h'], f'{r.longest_gap:.0f} min'),
        ('the 3rd game, at most', g3 and g3[0] <= TARGETS['the 3rd game, at most'], fmt(g3)),
        ('every game, days (regular)', g6 and g6[1] <= TARGETS['every game, days (regular)'], fmt(g6)),
        ('coins left for special foods, at least', r.coins >= TARGETS['coins left for special foods, at least'], f'{r.coins:.0f}')]:
        print(f'  {"ok  " if ok else "FAIL"} {label}: {val}')


if __name__ == '__main__':
    main()
