"""KamiTomo pacing model v3 (the skeleton: docs/progression.md): WHEN does a player get WHAT?

Nothing is left to chance: a fixed player model (no dice: averages, so stars and coins come in
fractions), the real prices, the real evolution tree and the skeleton's rules (game order, the
difficulty of every level, the meal countdown, drinks and secrets, the special foods and where
they are found). Change a price or a rule and the whole timeline moves with it. The player's
numbers are ASSUMED until measured on the phone (minutes per try, how often a try fails, stars on
a first clear): replace them then.

  python3 tools/design/pacing.py              the three players side by side + the checks
  python3 tools/design/pacing.py regular      one player's timeline (casual / regular / keen)
  python3 tools/design/pacing.py levels       the difficulty curve: every game's worlds, measured
  python3 tools/design/pacing.py days         day by day, the three players

Keep in step with the game: GAMES (scripts/game_data.gd GAME_PRICE, GameMenuSwitcher.ORDER), the
food packs and special foods (scripts/shop.gd), the countdowns (scripts/lcd_screen.gd), Tilt
Maze's vaults (scripts/tilt_maze.gd VAULTS). Everything else here is PROPOSED in
docs/progression.md (the meal countdown by what the meal did, the secrets of the other games,
drink levels, where the special foods are found).
"""
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

# --- the games, in the Games menu's order (2026-10-16: Pal Prix 3rd, Paper Sumo 4th)
#   name, price (scripts/game_data.gd GAME_PRICE), worlds, minutes per try
#   at difficulty 0 (the level menu and result card included), how much harder the game is
#   overall (added to every level's difficulty)
GAMES = [
    ('Splash Hoops', 0, 6, 0.9, 0.0),
    ('Tilt Maze', 5, 6, 0.9, 0.0),
    ('Pal Prix', 30, 6, 1.0, 0.3),
    ('Paper Sumo', 50, 6, 1.2, 0.5),
    ('Top Spin', 70, 6, 1.4, 0.8),
    ('Tummy Tunes', 100, 6, 1.3, 1.0),
]
LEVELS = 9                                        # per world (one page of the level menu)

# --- difficulty: every level gets a number, 0 (a walk) .. 10 (the hardest thing in the game).
# A world starts easier than the last one ended (a breather while its new thing is learnt),
# climbs, and its 9th level, the finale, is a step up: the saw-tooth.
W_START, W_STEP, W_SPAN, FINALE = 1.0, 1.0, 2.5, 0.7


def difficulty(g, i):
    w, l = divmod(i, LEVELS)
    d = W_START + W_STEP * w + W_SPAN * l / (LEVELS - 1) + GAMES[g][4]
    return d + (FINALE if l == LEVELS - 1 else 0.0)


# how a regular player does at a difficulty (ASSUMED until measured)
def fail(d):            # a try that ends with no star
    return min(0.6, 0.03 + 0.045 * d)


def first_stars(d):     # stars when a level is first cleared
    return max(1.0, 2.6 - 0.13 * d)


def replay_stars(d):    # stars per try when going back for the missing ones
    return max(0.2, 0.65 - 0.035 * d)


def try_min(g, d):      # minutes per try
    return GAMES[g][3] * (0.85 + 0.04 * d)


# --- the pal: the meal countdown (minutes) after a meal, by what the meal did
WAIT_NEW = {1: 3, 2: 10, 3: 30, 4: 30, 5: 30}     # a NEW pal settles in: Sho, Chu, Dai, mutant, legend
WAIT_KNOWN = 0                                    # a pal met before (or no change): straight on
MEAL_MIN = 0.3                                    # a meal and its show, in minutes of the session
DRINK_EVERY = 15                                  # minutes between drinks (LcdScreen)
CLAW_EVERY = 4                                    # Lucky Pinch: after every 4th meal that brought a new pal
CLAW_ITEMS, CLAW_COINS = 8, 3                     # its exclusive prizes, then coin capsules

# --- prices (the game's; the drink levels are PROPOSED)
PACK_PRICE = {'baby': 10, 'kid': 15, 'adult': 20}  # a food pack, by its size (9 packs: 145)
START_FOODS = {'baby': ['green', 'sweet', 'greasy'], 'kid': ['green', 'sweet'], 'adult': ['green']}
SPECIAL_PRICE = {'tech': 15, 'cosmic': 15, 'legend': 40}
# a special food is on sale once you've found it in a game (its place tells its story first), or
# without that from a star total (so no game is ever required); + the pal rule (a Dai; its ULTRA)
SPECIAL_ON_SALE = {'tech': 350, 'cosmic': 350, 'legend': 450}
SPECIAL_STOCK = {'tech': 1, 'cosmic': 1, 'legend': 1}         # the Shop's special shelf: restocked every day
COSMETICS = [8] * 20 + [40] * 4                   # the Shop's stickers and plain cases (after every game is bought)
DRINK_PRICE = {2: 10, 3: 20}                      # a drink type's level 2 / level 3 (scripts/shop.gd)
DRINK_TYPES = ['watery', 'fizzy', 'caffeinated', 'milky', 'fruity']   # one more with each game owned
DAILY = 2                                         # the pal's daily request (from day 2, on a day you play)
GIFTS_AT = [5, 15, 30, 60, 100]                   # each game's gift track (its star total)
PEDIA_GIFT_EVERY = 10                             # a gift every 10 pals found

FAMS = ['green', 'sweet', 'greasy', 'spicy', 'sour']
TIERS = ['baby', 'kid', 'adult']
SPECIAL_KIND = {'Microchip': 'tech', 'Battery': 'tech', 'Alien Goo': 'cosmic', 'Moon Rock': 'cosmic',
                'Golden Seed': 'legend', 'Stardust Sugar': 'legend', 'Dragon Oil': 'legend',
                'Phoenix Pepper': 'legend', 'Kraken Brine': 'legend'}
LEGEND_OF = {'Golden Seed': 'green', 'Stardust Sugar': 'sweet', 'Dragon Oil': 'greasy',
             'Phoenix Pepper': 'spicy', 'Kraken Brine': 'sour'}

# --- secrets: a gate in a level, opened by a drink type of at least a level; the prize behind
# it. Tilt Maze: its vaults (2 gated per world; today all fizz, the plan gives each boost its
# own kind). The other games: one per world from world 2, on its 6th level. Gate level: worlds
# 1-2 = 1, 3-4 = 2, 5-6 = 3 (6 worlds = three tiers of two).
GATE_LEVEL = [1, 1, 2, 2, 3, 3]
GATE_TYPES = {
    0: ['fizzy', 'fruity', 'fizzy', 'fruity', 'fizzy'],                       # Splash Hoops: a high golden hoop / a chest on the sand
    2: ['fizzy', 'milky', 'fruity', 'milky', 'fizzy'],                        # Pal Prix: a ramp off the road / no slip / a gift box
    3: ['milky', 'caffeinated', 'milky', 'caffeinated', 'milky'],             # Paper Sumo: a mystery challenger who wants a heavy or a sharp pal
    4: ['fizzy', 'caffeinated', 'milky', 'fizzy', 'caffeinated'],             # Top Spin: a bell to ring / a perfect guard / a heavy top
    5: ['caffeinated', 'fruity', 'caffeinated', 'fruity', 'caffeinated'],     # Tummy Tunes: an encore song / a golden note
}
TILT_GATES = [('fizzy', 'fizzy'), ('fizzy', 'watery'), ('fizzy', 'milky'), ('caffeinated', 'milky'),
              ('fruity', 'caffeinated'), ('fruity', 'fizzy')]
TILT_VAULT_LEVELS = [(3, 8), (12, 17), (21, 26), (30, 35), (39, 44), (48, 53)]   # (scripts/tilt_maze.gd VAULTS)
# special foods found in the games (taken once): game, level, food, how (vault = behind its gate,
# clear = the level's first clear: a boss, a rival, a finale)
FINDS = [
    (1, 30, 'Microchip', 'vault'), (1, 39, 'Battery', 'vault'), (1, 48, 'Moon Rock', 'vault'),
    (1, 53, 'Alien Goo', 'vault'),                             # Tilt Maze (built)
    (2, 15, 'Battery', 'vault'),                               # Pal Prix 2 Kitchen: off a ramp, a kitchen timer's battery
    (2, 24, 'Moon Rock', 'vault'),                             # Pal Prix 3 Sky: a ramp to a floating island
    (3, 36, 'Microchip', 'clear'),                             # Paper Sumo 4 Tin Toys: beat the wind-up robot
    # the legendary foods: the world-5 finales (world 6 is the masters' world: prestige prizes)
    (0, 45, 'Kraken Brine', 'clear'),                          # Splash Hoops 5 Storm: the finale
    (2, 45, 'Phoenix Pepper', 'clear'),                        # Pal Prix 5 Grand Prix: the Phoenix Cup
    (3, 45, 'Golden Seed', 'clear'),                           # Paper Sumo 5 Shrine: the harvest yokozuna
    (4, 45, 'Dragon Oil', 'clear'),                            # Top Spin 5 Dragon Festival: the dragon top
    (5, 45, 'Stardust Sugar', 'clear'),                        # Tummy Tunes 5: the star song
]

# --- the players (ASSUMED): sessions per day (minutes each; the short ones are visits to feed),
# day 1, days 2-7, day 8 on. Between sessions hours pass: every session starts with the meal
# and the drink ready.
PLAYERS = {
    'casual': ([20, 2], [6, 5, 2], [5, 3, 2]),
    'regular': ([60, 2], [15, 15, 2, 2], [10, 10, 2, 2]),
    'keen': ([180, 3, 3], [30, 30, 5, 3, 3], [20, 20, 5, 3]),
}
DAYS = 120
TARGETS = {                      # the checks, on the regular player (minutes of play unless it says day)
    'Tilt Maze bought (min)': 5,
    'the first Dai (min)': 20,
    'new things in the first hour (at least)': 12,
    'longest wait for something new, 1st hour (min)': 6,
    'longest wait for something new, hours 1-5 (min)': 15,
    'the 3rd game (min)': 30,
    'every game (day)': 28,
    'sessions with a new pal, days 2-30 (share)': 0.8,
    'most coins saved up, days 1-30': 110,
    'Pal Pedia complete (day)': 45,
    'every game, then the Pal Pedia, then 90% of the stars': 1,
}


def tree():
    with open(os.path.join(ROOT, 'data', 'evolution_tree.json')) as f:
        return json.load(f)


def secrets_list():
    """every secret: (game, level, drink type, drink level, prize)"""
    out = []
    finds = {(g, lvl): food for g, lvl, food, how in FINDS if how == 'vault'}
    for w, (a, b) in enumerate(TILT_VAULT_LEVELS):
        for lvl, typ in zip((a, b), TILT_GATES[w]):
            out.append((1, lvl, typ, GATE_LEVEL[w], finds.get((1, lvl), 'sticker')))
    for g, types in GATE_TYPES.items():
        for k, typ in enumerate(types):
            w = k + 1                                   # worlds 2..6
            lvl = w * LEVELS + 6                        # the world's 6th level
            out.append((g, lvl, typ, GATE_LEVEL[w], finds.get((g, lvl), 'sticker')))
    return out


class Player:
    def __init__(self, name):
        self.name = name
        self.plan = PLAYERS[name]
        self.T = tree()
        self.t = 0.0                    # minutes of play (sessions only)
        self.clock = 0.0                # real minutes since the first launch
        self.day = 1
        self.coins = 0.0
        self.earned = 0.0
        self.spent = {}
        self.owned = [0]                # games owned (indices into GAMES)
        self.nlev = [GAMES[g][2] * LEVELS for g in range(len(GAMES))]
        self.stars = [[0.0] * n for n in self.nlev]
        self.cleared = [[False] * n for n in self.nlev]
        self.foods = {k: list(v) for k, v in START_FOODS.items()}
        self.drink_lvl = {'watery': 1}
        self.boost = None               # (type, level)
        self.next_drink = 0.0           # (real clock)
        self.next_meal = 0.0
        self.secrets = secrets_list()
        self.opened = set()
        self.pantry = {}
        self.met_specials = set()       # special foods found in a game at least once
        self.gifts = [0] * len(GAMES)
        self.form = ''
        self.found = set()
        self.new_meals = 0
        self.claws = 0
        self.log = []                   # (play minute, day, what)
        self.gaps = []                  # (play minute, minutes since the last new thing)
        self.last_new = 0.0
        self.max_unspent = 0.0
        self.sessions = []              # (day, found a new pal?)
        self.days = {}                  # day -> snapshot
        self.stock = dict(SPECIAL_STOCK)
        self.cosmetics = list(COSMETICS)

    # --- events
    def new(self, what):
        self.gaps.append((self.t, self.t - self.last_new))
        self.last_new = self.t
        self.log.append((self.t, self.day, what))

    def earn(self, n):
        self.coins += n
        self.earned += n

    def pay(self, n, what, kind):
        self.coins -= n
        self.spent[kind] = self.spent.get(kind, 0) + n
        self.new(f'{what} ({n})')

    def total_stars(self):
        return sum(sum(s) for s in self.stars)

    # --- the pals
    def stage(self, form=None):
        form = self.form if form is None else form
        return 0 if not form else int(self.T['forms'][form]['stage'])

    def fam(self, form):
        return self.T['forms'][form]['family']

    def result(self, food, form=None):
        """the pal a basic food family turns `form` into ('' = no change)"""
        form = self.form if form is None else form
        if not form:
            return self.T['starters'][food]
        if self.stage(form) >= 3:
            return ''
        return self.T['next'].get(form, {}).get(food, '')

    def special_result(self, food, form=None):
        form = self.form if form is None else form
        if not form or self.stage(form) != 3:
            return ''
        kind = SPECIAL_KIND[food]
        if kind == 'legend':
            lg = self.T['legend'].get(form)
            return lg['to'] if lg and lg['family'] == LEGEND_OF[food] else ''
        return self.T['next'].get(form, {}).get(kind, '')

    def special_on_sale(self, food, form):
        kind = SPECIAL_KIND[food]
        if food not in self.met_specials and self.total_stars() < SPECIAL_ON_SALE[kind]:
            return False
        return bool(self.special_result(food, form))

    def special_for(self, form, buy_ok):
        """a special food that turns this Dai into a pal not found yet: in the pantry, or on sale"""
        for food in SPECIAL_KIND:
            to = self.special_result(food, form)
            if not to or to in self.found:
                continue
            if self.pantry.get(food, 0) > 0:
                return food, False
            kind = SPECIAL_KIND[food]
            if buy_ok and self.stock[kind] > 0 and self.special_on_sale(food, form) and self.coins >= SPECIAL_PRICE[kind]:
                return food, True
        return None

    def unfound_below(self, form, foods=None):
        """pals not found yet at `form` or after it, with the foods you have (special foods
        count where you have one or it's on sale)"""
        foods = foods or self.foods
        n = 0 if form in self.found else 1
        st = self.stage(form)
        if st < 3:
            for f in foods[TIERS[st]]:
                to = self.result(f, form)
                if to:
                    n += self.unfound_below(to, foods)
        elif st == 3:
            for food in SPECIAL_KIND:
                to = self.special_result(food, form)
                if to and to not in self.found and (self.pantry.get(food, 0) or (self.stock[SPECIAL_KIND[food]] > 0 and
                        self.special_on_sale(food, form) and self.coins >= SPECIAL_PRICE[SPECIAL_KIND[food]])):
                    n += 1
        return n

    def anything_new(self, foods=None):
        foods = foods or self.foods
        return sum(self.unfound_below(self.T['starters'][f], foods) for f in foods['baby'])

    def meal(self):
        """one meal (or a special food, or a flush and a new pal): True if anything was eaten"""
        st = self.stage()
        if st >= 3:
            sp = self.special_for(self.form, buy_ok=True) if st == 3 else None
            if sp:
                food, buy = sp
                if buy:
                    self.stock[SPECIAL_KIND[food]] -= 1
                    self.pay(SPECIAL_PRICE[SPECIAL_KIND[food]], f'buys {food}', 'special foods')
                else:
                    self.pantry[food] -= 1
                return self.evolve(self.special_result(food))
            if not self.anything_new():
                return False                     # nothing new to find: the pal stays as it is
            self.form = ''                       # the flush: a new pal hatches at the next meal
            st = 0
        elif self.form and self.unfound_below(self.form) == 0:
            if not self.anything_new():
                return False                     # nothing new anywhere: the pal waits for a pack
            self.form = ''                       # a dead end: flushed early for a new start
            st = 0
        elif not self.form and not self.anything_new():
            return False
        tier = TIERS[st]
        opts = [f for f in self.foods[tier] if self.result(f)]
        if not opts:
            return False
        best = max(opts, key=lambda f: (self.unfound_below(self.result(f)), -FAMS.index(f)))
        return self.evolve(self.result(best))

    def evolve(self, to):
        self.form = to
        self.t += MEAL_MIN
        self.clock += MEAL_MIN
        if to in self.found:
            self.next_meal = self.clock + WAIT_KNOWN
            return True
        self.found.add(to)
        self.session_new = True
        st = self.stage(to)
        self.next_meal = self.clock + WAIT_NEW[st]
        self.new(f'meets {self.T["forms"][to]["name"]} ({["", "Sho", "Chu", "Dai", "mutant", "legend"][st]}, pal {len(self.found)})')
        if len(self.found) % PEDIA_GIFT_EVERY == 0:
            self.new(f'Pal Pedia gift ({len(self.found)} pals)')
        self.new_meals += 1
        if self.new_meals % CLAW_EVERY == 0:
            self.claws += 1
            if self.claws <= CLAW_ITEMS:
                self.new(f'Lucky Pinch: prize {self.claws}')
            else:
                self.earn(CLAW_COINS)
        return True

    # --- the Shop and the Games menu (a typical player, nudged by the guide cards)
    def wanted_pack(self):
        """the pack that opens the most new pals per coin, if the pal has nothing new to find"""
        if self.anything_new() and (not self.form or self.stage() >= 3 or self.unfound_below(self.form) > (0 if self.form in self.found else 1)):
            return None
        best = None
        for tier in TIERS:
            for f in FAMS:
                if f in self.foods[tier]:
                    continue
                trial = {k: list(v) for k, v in self.foods.items()}
                trial[tier].append(f)
                gain = self.anything_new(trial) - self.anything_new()
                if gain > 0 and (best is None or gain / PACK_PRICE[tier] > best[0]):
                    best = (gain / PACK_PRICE[tier], f, tier)
        return best and best[1:]

    def reached(self, g, lvl):
        """the level is open (the one before it cleared)"""
        return lvl == 1 or self.cleared[g][lvl - 2]

    def open_secrets(self):
        return [s for s in self.secrets if s not in self.opened and s[0] in self.owned and self.reached(s[0], s[1])]

    def wanted_drink(self):
        for g, lvl, typ, need, _ in self.open_secrets():
            have = self.drink_lvl.get(typ, 0)
            if have and have < need:
                return typ, have + 1
        return None

    def shop(self):
        while True:
            if 1 not in self.owned and self.coins >= GAMES[1][1]:
                self.buy_game(1)
                continue
            p = self.wanted_pack()
            if p and self.coins >= PACK_PRICE[p[1]]:
                self.foods[p[1]].append(p[0])
                self.pay(PACK_PRICE[p[1]], f'buys {p[0]} {p[1]} food', 'food packs')
                continue
            nxt = next((g for g in range(len(GAMES)) if g not in self.owned), None)
            if nxt is not None and 1 in self.owned and self.coins >= GAMES[nxt][1]:
                self.buy_game(nxt)
                continue
            d = self.wanted_drink()
            if d and self.coins >= DRINK_PRICE[d[1]]:
                self.drink_lvl[d[0]] = d[1]
                self.pay(DRINK_PRICE[d[1]], f'buys {d[0]} drinks level {d[1]}', 'drink levels')
                continue
            rest = [(t, f) for t in TIERS for f in FAMS if f not in self.foods[t]]
            if rest and nxt is None and self.coins >= PACK_PRICE[rest[0][0]]:
                t, f = rest[0]
                self.foods[t].append(f)
                self.pay(PACK_PRICE[t], f'buys {f} {t} food', 'food packs')
                continue
            if nxt is None and self.cosmetics and self.coins >= self.cosmetics[0] + 40:
                self.pay(self.cosmetics.pop(0), 'buys a sticker or a case', 'cosmetics')
                continue
            break
        if self.day <= 30:
            self.max_unspent = max(self.max_unspent, self.coins)

    def buy_game(self, g):
        self.owned.append(g)
        extra = ''
        if len(self.owned) <= len(DRINK_TYPES):
            typ = DRINK_TYPES[len(self.owned) - 1]
            self.drink_lvl[typ] = 1
            extra = f' (+ {typ} drinks)'
        self.pay(GAMES[g][1], f'buys {GAMES[g][0]}{extra}', 'games')

    # --- drinks and secrets
    def drink(self):
        """at a drink: the type (and level) the next secret within reach needs"""
        for g, lvl, typ, need, _ in self.open_secrets():
            if self.drink_lvl.get(typ, 0) >= need:
                self.boost = (typ, self.drink_lvl[typ])
                return
        if not self.boost:
            self.boost = ('watery', self.drink_lvl['watery'])

    def secret_to_open(self):
        if not self.boost:
            return None
        for s in self.open_secrets():
            if s[2] == self.boost[0] and self.boost[1] >= s[3]:
                return s
        return None

    def open_secret(self, s):
        g, lvl, typ, need, prize = s
        self.t += try_min(g, difficulty(g, lvl - 1))
        self.clock += try_min(g, difficulty(g, lvl - 1))
        self.opened.add(s)
        self.boost = None
        if prize != 'sticker':
            self.pantry[prize] = self.pantry.get(prize, 0) + 1
            self.met_specials.add(prize)
        self.new(f'opens a secret in {GAMES[g][0]} {lvl // LEVELS + 1}-{(lvl - 1) % LEVELS + 1} ({typ} {need}): {prize}')

    # --- playing
    def next_level(self):
        """the first level not cleared in the lowest world, newest game first; when every
        level is cleared, the replay that pays the most stars per minute"""
        best = None
        for g in reversed(self.owned):
            for i in range(self.nlev[g]):
                if not self.cleared[g][i]:
                    if best is None or i // LEVELS < best[1] // LEVELS:
                        best = (g, i, 'first')
                    break
        if best:
            return best
        cand = [(replay_stars(difficulty(g, i)) / try_min(g, difficulty(g, i)), g, i)
                for g in self.owned for i in range(self.nlev[g]) if self.stars[g][i] < 2.95]
        if not cand:
            return None
        _, g, i = max(cand)
        return (g, i, 'replay')

    def play_once(self):
        s = self.secret_to_open()
        if s:
            self.open_secret(s)
            return True
        nl = self.next_level()
        if not nl:
            return False
        g, i, kind = nl
        d = difficulty(g, i)
        if kind == 'first':
            m = try_min(g, d) / (1 - fail(d))
            got = first_stars(d)
            self.cleared[g][i] = True
            if i % LEVELS == 0 and i:
                self.new(f'{GAMES[g][0]}: world {i // LEVELS + 1}')
            for fg, lvl, food, how in FINDS:
                if how == 'clear' and (fg, lvl) == (g, i + 1):
                    self.pantry[food] = self.pantry.get(food, 0) + 1
                    self.met_specials.add(food)
                    self.new(f'wins {food} in {GAMES[g][0]} {i // LEVELS + 1}-{i % LEVELS + 1}')
        else:
            m = try_min(g, d)
            got = min(replay_stars(d), 3 - self.stars[g][i])
        self.t += m
        self.clock += m
        self.stars[g][i] += got
        self.earn(got)
        tot = sum(self.stars[g])
        while self.gifts[g] < len(GIFTS_AT) and tot >= GIFTS_AT[self.gifts[g]]:
            self.gifts[g] += 1
            self.new(f'gift {self.gifts[g]} of {GAMES[g][0]}')
        return True

    def session(self, minutes):
        end = self.t + minutes
        self.session_new = False
        self.next_meal = min(self.next_meal, self.clock)       # hours away: the pal is hungry
        self.next_drink = min(self.next_drink, self.clock)
        idle = 0
        while self.t < end:
            if self.clock >= self.next_meal and self.meal():
                self.shop()
                continue
            if self.clock >= self.next_drink:
                self.drink()
                self.next_drink = self.clock + DRINK_EVERY
            if minutes <= 3:                                   # a visit to feed: no games
                if self.clock >= self.next_meal:
                    break                                      # (nothing to feed: off again)
                self.t += 0.5
                self.clock += 0.5
                idle += 1
                if idle > 6:
                    break
                continue
            if not self.play_once():
                self.t = end
                break
            self.shop()
        self.sessions.append((self.day, self.session_new))

    def run(self, days=DAYS):
        for d in range(1, days + 1):
            self.day = d
            plan = self.plan[0] if d == 1 else self.plan[1] if d <= 7 else self.plan[2]
            if d > 1:
                self.earn(DAILY)
            self.stock = dict(SPECIAL_STOCK)
            for k, mins in enumerate(plan):
                self.clock = (d - 1) * 1440 + 480 + k * (840 / max(1, len(plan) - 1))
                self.session(mins)
            self.days[d] = (len(self.found), self.total_stars(), self.coins, len(self.owned), len(self.opened), self.t)
        return self

    def when(self, text):
        for t, d, what in self.log:
            if text in what:
                return t, d
        return None

    def day_when(self, test):
        for d in sorted(self.days):
            if test(self.days[d]):
                return d
        return None


def fmt(w):
    return '-' if not w else f'{w[0]:5.0f} min (day {w[1]})'


def levels():
    print('The difficulty curve (a regular player; ASSUMED until measured):')
    print(f'{"":13}{"world":>6}{"difficulty":>12}{"fails":>10}{"first pass":>12}{"to 3 stars":>12}{"stars, 1st pass":>17}')
    for g, (name, _, worlds, _, _) in enumerate(GAMES):
        for w in range(worlds):
            idx = range(w * LEVELS, (w + 1) * LEVELS)
            ds = [difficulty(g, i) for i in idx]
            fp = sum(try_min(g, d) / (1 - fail(d)) for d in ds)
            st = sum(first_stars(d) for d in ds)
            to3 = fp + sum((3 - first_stars(d)) / replay_stars(d) * try_min(g, d) for d in ds)
            fails = f'{fail(ds[0]) * 100:.0f}-{fail(ds[-1]) * 100:.0f}%'
            print(f'{name if w == 0 else "":13}{w + 1:>6}{ds[0]:>7.1f}-{ds[-1]:<4.1f}{fails:>10}{fp:>9.0f} min{to3:>9.0f} min{st:>13.1f}/27')
        print()
    allfp = sum(try_min(g, difficulty(g, i)) / (1 - fail(difficulty(g, i))) for g in range(len(GAMES)) for i in range(GAMES[g][2] * LEVELS))
    all3 = allfp + sum((3 - first_stars(difficulty(g, i))) / replay_stars(difficulty(g, i)) * try_min(g, difficulty(g, i))
                       for g in range(len(GAMES)) for i in range(GAMES[g][2] * LEVELS))
    n = sum(GAMES[g][2] * LEVELS for g in range(len(GAMES)))
    print(f'{n} levels, {n * 3} stars: every level cleared in ~{allfp / 60:.0f} h of play, every star in ~{all3 / 60:.0f} h')


def days_table():
    ps = {n: Player(n).run() for n in PLAYERS}
    show = [1, 2, 3, 5, 7, 10, 14, 21, 30, 45, 60, 90, 120]
    print(f'{"day":>5}' + ''.join(f'{n:>34}' for n in ps))
    print(f'{"":5}' + ''.join(f'{"pals  stars  coins games secrets":>34}' for _ in ps))
    for d in show:
        row = f'{d:>5}'
        for p in ps.values():
            pals, stars, coins, games, secrets, _ = p.days[d]
            row += f'{pals:>13}{stars:>7.0f}{coins:>7.0f}{games:>6}{secrets:>8}'
        print(row)


def main():
    if len(sys.argv) > 1 and sys.argv[1] == 'levels':
        return levels()
    if len(sys.argv) > 1 and sys.argv[1] == 'days':
        return days_table()
    if len(sys.argv) > 1:
        p = Player(sys.argv[1]).run(int(sys.argv[2]) if len(sys.argv) > 2 else 30)
        for t, d, what in p.log:
            print(f'{t:7.0f} min  day {d:3}  {what}')
        print(f'\ncoins earned {p.earned:.0f}, spent', {k: round(v) for k, v in p.spent.items()}, f'left {p.coins:.0f}')
        return
    ps = {n: Player(n).run() for n in PLAYERS}
    n_pals = len(ps['regular'].T['forms'])
    max_stars = sum(GAMES[g][2] * LEVELS * 3 for g in range(len(GAMES)))
    rows = [('Tilt Maze', 'buys Tilt Maze'), ('Pal Prix (3rd)', 'buys Pal Prix'), ('Paper Sumo (4th)', 'buys Paper Sumo'),
            ('Top Spin (5th)', 'buys Top Spin'), ('Tummy Tunes (6th)', 'buys Tummy Tunes'),
            ('first Chu', 'Chu, pal'), ('first Dai', 'Dai, pal'), ('first food pack', ' food ('),
            ('first secret', 'opens a secret'), ('first drink level 2', 'level 2'), ('first drink level 3', 'level 3'),
            ('first special found', '): Battery'), ('first mutant', 'mutant, pal'), ('first legend', 'legend, pal'),
            ('10th pal', 'pal 10)'), ('30th pal', 'pal 30)'), ('60th pal', 'pal 60)'), ('90th pal', 'pal 90)'),
            (f'all {n_pals} pals', f'pal {n_pals})')]
    print(f'{"":20}' + ''.join(f'{n:>22}' for n in ps))
    for label, key in rows:
        print(f'{label:20}' + ''.join(f'{fmt(p.when(key)):>22}' for p in ps.values()))
    for label, frac in [('50% of the stars', 0.5), ('90% of the stars', 0.9)]:
        print(f'{label:20}' + ''.join(f'{"day " + str(p.day_when(lambda s: s[1] >= frac * max_stars)) if p.day_when(lambda s: s[1] >= frac * max_stars) else "-":>22}' for p in ps.values()))
    print(f'{"coins: earned/left":20}' + ''.join(f'{p.earned:>15.0f} / {p.coins:<4.0f}' for p in ps.values()))
    print(f'{"most coins unspent":20}' + ''.join(f'{p.max_unspent:>22.0f}' for p in ps.values()))
    print()
    r = ps['regular']

    def gap(lo, hi):
        g = [x for t, x in r.gaps if lo <= t <= hi]
        return max(g) if g else 0

    s_new = [n for d, n in r.sessions if 2 <= d <= 30]
    pedia = r.day_when(lambda s: s[0] >= n_pals)
    stars90 = r.day_when(lambda s: s[1] >= 0.9 * max_stars)
    first_dai = r.when('Dai, pal')
    games_day = (r.when('buys Tummy Tunes') or (0, 999))[1]
    checks = [
        ('Tilt Maze bought (min)', r.when('buys Tilt Maze')[0], lambda v, t: v <= t),
        ('the first Dai (min)', first_dai[0] if first_dai else 999, lambda v, t: v <= t),
        ('new things in the first hour (at least)', len([1 for t, d, w in r.log if t <= 60]), lambda v, t: v >= t),
        ('longest wait for something new, 1st hour (min)', gap(0, 60), lambda v, t: v <= t),
        ('longest wait for something new, hours 1-5 (min)', gap(60, 300), lambda v, t: v <= t),
        ('the 3rd game (min)', (r.when('buys Pal Prix') or (999,))[0], lambda v, t: v <= t),
        ('every game (day)', games_day, lambda v, t: v <= t),
        ('sessions with a new pal, days 2-30 (share)', sum(s_new) / max(1, len(s_new)), lambda v, t: v >= t),
        ('most coins saved up, days 1-30', r.max_unspent, lambda v, t: v <= t),
        ('Pal Pedia complete (day)', pedia or 999, lambda v, t: v <= t),
        ('every game, then the Pal Pedia, then 90% of the stars', int(games_day <= (pedia or 999) <= (stars90 or 999)), lambda v, t: v >= t),
    ]
    print('checks (regular player):')
    for label, val, ok in checks:
        shown = f'{val:.2f}' if isinstance(val, float) and val < 1 else f'{val:.0f}'
        print(f'  {"ok  " if ok(val, TARGETS[label]) else "FAIL"} {label}: {shown} (target {TARGETS[label]})')


if __name__ == '__main__':
    main()
