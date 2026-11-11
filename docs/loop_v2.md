# The loop, v2: one consistent system (proposal, 2026-11-11)

The user (2026-11-11): "what concerns me the most is the gameplay progression: the eating timings,
the dopamine cycle, the penalisation of not eating/playing... we need something consistent." This
page is the answer: the October skeleton (`docs/progression.md`) and the 31 October direction
(`docs/economy_pillar.md`) resolved into one system, checked in the model (`tools/design/pacing.py`,
now v4: run it plain for these rules, `old` for the October ones). Nothing here is built. The
decisions the user has to take are marked **DECIDE**; everything else is the recommendation.

## 0. The promise, in one sentence

A spirit grows in your shrine from what you offer it; its drinks are the powers that make you great
at the festival's toy games; and the games pay for everything the shrine can become.

Four things, one job each (unchanged): stars = skill, coins = choice, spirits = the long goal,
powers = the bridge from caring to playing. The home shows all of it.

## 1. The clocks (the rhythm of coming back)

| Clock | What | Sets |
|---|---|---|
| The meal | a NEW spirit settles in: Sho 3 min, Chu 10, Dai / mutant / legend 30; a known step straight away | how fast the collection grows inside a session (built) |
| The drink | one every 15 min | how much powered play a session has (built: the countdown; the power is new) |
| Hunger | fed 0-2 h, hungry 2-8 h, very hungry 8 h+ | the nudge to come back today (built: the faces; the consequence is new) |
| The day | the daily request (+2 coins at the first new star), the special shelf restocks, the streak | the reason to come back tomorrow |
| The month | the Tomopedia (120 spirits: day ~28 regular, ~60 casual), the homes at 60 / 90 / 120 spirits | the first long goal |
| The season | the stars (90%: day ~59), the masters' worlds, the generations (section 6) | the second long goal |

Every session has all three short clocks running, so there is always a "next thing in N minutes" on
the LCD, and every day has one thing you can only get today.

## 2. Drinks are the games' powers (the heart of the change)

**The rule.** Each game has ONE power and ONE drink gives it. The drink arrives with its game. Drinking
starts nothing by itself: the power starts at the first level you play in its game after drinking,
runs only while you're inside a level of that game, and lasts 5 minutes (level 2 drinks: 8, level 3:
12). One power at a time: drinking again replaces it. So a drink is never wasted on a visit to feed,
and a drink is a decision: "which game do I want to be great at now?"

| Game | Drink | Its power | The 3rd star it makes reachable | The secret route it reaches |
|---|---|---|---|---|
| Splash Hoops | Watery | TIDE: the jets throw harder, the ball floats longer | 45% of the time left | the high golden hoop, the chest on the sand |
| Tilt Maze | Fizzy | HOP: the ball hops low fences and small pits | no fall | the vaults (built) |
| Pal Prix (and 2177) | **Spicy (NEW: a ginger ale / chilli ramune)** | HEAT: boost pads burn longer, a nitro on the straights | the gold par (1st, well within par) | the ramp into the tunnel, the route through the clouds |
| Paper Sumo | Milky | STURDY: weight | 2-0 within par | the mystery challenger |
| Top Spin | Fruity | ZEST: the top spins longer, dashes harder | 70% of the spin left | the bell, the golden top |
| Tummy Tunes | Caffeinated | FOCUS: wider timing windows | 95% of the notes | the golden note, the encore |

- **The 3rd star needs the power.** The tuning rule, per level, measured with the autopilot (FAST=1):
  with the power a regular player gets the 3rd star in 2-3 tries; without it about 1 try in 8. Never
  impossible: the best players can. The 1st and 2nd stars never need a drink.
- **The secret is a route, not a box.** The level's hidden prize sits where only the power reaches,
  built into the course. The gate level stays by tier (worlds 1-2 need the drink at level 1, 3-4 level
  2, 5-6 level 3), so drink levels still buy something besides minutes.
- **A drink does nothing in another game.** One word per drink, everywhere. The old table (Splash a
  second chance in every game, Fizz in four games...) goes; the hearts stay as the lives.
- **Why 15 min / 5 min:** in a 15-minute session you get one power: 3-5 levels, one or two 3rd stars.
  The model: a regular player plays 43% of their minutes powered, a casual 66% (they play little, so
  most of it is powered), a keen player 18% (the ration bites them, as intended). Days to 90% of the
  stars: 59 with the powers, 58 without. **The ration works without stalling anyone.**
- The first drink (minute 15) is Watery: the TIDE reaches the golden hoop in Splash Hoops 1-3, so
  the first secret is in the free game with the first drink (it used to need Tilt Maze's Fizzy).

**DECIDE A.** The 6th drink: Spicy for the races (HEAT: the roadmap's "spicy = fast"), Caffeinated
for Tummy Tunes (timing). The alternative: Caffeinated stays the races' (slow-motion before a crash,
as built) and the new drink is Tummy Tunes'. Spicy is the recommendation: heat on a race track reads
instantly, and FOCUS on a rhythm game is the natural word.

**DECIDE B.** Drink levels make the power LONGER (5 / 8 / 12 min), not stronger. Stronger would mean
retuning every 3rd star three times. Longer keeps one tuning and still sells (plus the gates).

**Keep three tiers? Yes** (the user asked, 2026-11-11). The three levels are three NAMED drinks, each
with its own icon (Shrine Water, Barley Tea, Coconut Water; Cola, Ramune, Cream Soda...), so the
drink menu's line-up is content a player collects, not a number. The three tiers match the three
tiers of worlds (1-2 / 3-4 / 5-6), so a tier-2 route's sign ("needs Ramune") says which drink to
buy. And the levels are 180 of the catalogue's coins, bought on days 4-10 in the model: the weeks
when the Shop most needs something worth saving for. What changes is only their meaning: a higher
drink = a longer power (its minutes shown on the LCD, so the upgrade is visible) + the tier's routes.
The fallback, if the drink menu feels cluttered on the phone with 6 x 3: two tiers at 10 / 30 (the
sink kept), the level-3 names dropped.

## 3. Care: what not feeding costs (the penalties)

**The principle: care gates the powers, never the collection.** Nothing a player owns is ever lost: no
sickness, no going back a stage, no spirit lost. What missing care costs is the thing that makes you
great at the games, and today's chance.

| Since the last meal | The spirit | What it costs |
|---|---|---|
| 0-2 h | fed (its happy face) | nothing |
| 2-8 h | hungry (its 2nd face); the notification "your spirit is hungry" at 2 h | nothing yet |
| 8 h+ | very hungry (its 3rd face): **it won't drink until it has eaten**, so no power; the daily request waits for the meal | the games are harder until you feed it (one tap) |
| 24 h+ | the hokora goes dark: the lanterns out, the spirit asleep on the slab; the first offering wakes it and the lanterns light one by one | the streak resets (below) |

- **The streak (new).** Every day you feed the spirit counts. 3, 7, 14 and 30 days in a row give a
  **Lucky Pinch token** (a free go at the claw: its exclusives, then coin capsules). A missed day
  resets it to 0. That's the only thing that can be "lost", and it's a chance, not a possession.
- **A snack (the user's idea, 2026-10-10).** Food of the spirit's OWN size feeds it without changing
  it. So a visit never forces an evolution, a player can keep a spirit they like for days, and
  "feed it" is always a thing you can do. The next size up is marked "grows".
- **Not playing** costs nothing beyond its own result: no stars, no coins, the powers unused. The
  power waits for the first level, so a drink taken on a feeding visit is still there tonight.

**DECIDE C.** This ladder (won't drink at 8 h, the dark hokora and the streak at 24 h; never sickness
or regression) against the older harsher one in the roadmap (grumpy 12 h, sick 24 h, back a stage
48 h). The recommendation is this one: the audience is casual, and the games already carry the
stakes. If TestFlight shows people don't come back, the next lever is the drink countdown
(a hungry spirit's drink takes longer), still never the collection.

## 4. Coins: all the stars pay for the whole catalogue

The rule (the user, 2026-10-31): the total price of everything sold ≈ the coins from every star (972)
plus the small sources (the daily request, small secrets, Lucky Pinch capsules, spare specials), with
a small margin left.

The model today (v4, a regular player over 120 days): **earns 1285; the catalogue is 1325** (games
255, food packs 145, drink levels 180 with the 6th drink, the HOME stall 305, stickers and plain
cases 320, plus ~120 of special foods bought from the daily shelf; most specials are found in the
games). Without the bought specials it's 1205: 80 spare. **So the budget is full.** Every new priced
thing (a sold home, a sold set, more stall pieces) needs more coins in: a 7th world per game (+162
stars) or a new small source.

**DECIDE D. Nothing prestige is ever sold.** The homes are all earned (the Moon at 60 spirits, the
Tree at 90, the Golden Temple at 120, the Cyber Shrine from RC Prix 2177's finale, the Ruined Night
from Paper Sumo's seasons); the Food Stall, which was going to be the Shop's one expensive item,
becomes a reward too (the 30-day streak, or the first full gift track: to pick). The Shop sells
CHOICE: food packs, drink levels, the plain stall pieces, pal stickers, plain cases. The reason: in a
collection game the best things must say "I played", and the budget has no room for a 200-coin home
anyway. The alternative (the coolest pieces in the Shop as a reason to save) needs the 7th worlds
first.

## 5. The spirits' pace (unchanged) and what the player sees

The meal clock stays as built: 120 spirits by day ~28 (regular), ~60 (casual), 91% of sessions in
the first month end on a new spirit. That pace is right for a casual-friendly game: a month to meet
everyone, with the stars, the homes and the generations as the second month.

The dopamine cycle, visit by visit (what should be on the screen, in this order):
1. Open: the spirit's face says how it is (and after a day away, the dark hokora waking up).
2. Feed: the sparkles show which offering leads somewhere new; the meal show; a new spirit's reveal
   and its Tomopedia card; every 10th spirit a grand piece appears in the hokora; every 4th new
   spirit the bell rings for Lucky Pinch.
3. Drink: the drink menu shows what each power opens right now ("3 gates", "5 third stars within
   reach") so choosing is a plan, not a guess.
4. Play: the power's icon drains on the HUD; the 3rd star lights up because of it; the route it
   opened; the stars tick into the LCD's coins back on the pet screen.
5. Buy: something affordable is always a few stars away in the first month (the model: never more
   than ~100 coins idle).
6. Leave with a hook: the next meal in N min, the next drink in N min, the special shelf tomorrow,
   the streak's next token, the gate that wants a level-3 drink.

## 6. Starting over: generations (the second month and after)

A grown spirit (Dai, mutant or legend) is SENT OFF by the player, never flushed by the game: a
ceremony (the bell, the spirit rising as a wisp, the lanterns flaring), and its Tomopedia card gets a
generation mark (x2, x3...). The collection, the coins and the homes all stay.

Then, as an UPDATE after launch (no new art: a palette swap by script, like the balls), **blessed
spirits**: from generation 2, each new spirit has a 1-in-4 chance to come blessed (a shifted palette,
a glint), with its own page in the Tomopedia. That doubles the collection for the players who want
it, when they want it, and gives send-offs a reason. The user's other ideas (an heirloom trait,
second-run branches) wait: traits can't change winning (the skeleton's rule), and new branches need
new spirits.

**DECIDE E.** The send-off ceremony and the generation mark in v1; blessed spirits as the first
update. (Or both in v1.)

## 7. What the games pass has to do, game by game

The games' aesthetics pass (next) touches every level anyway, so each game's pass covers, together:
its look · its power's effect · the 3rd star's gold target with and without the power (autopilot
runs both) · the secret routes remapped to its own drink (58 gated secrets today) · the drink's
assist removed from the other games.

## 8. What changes in the code (after the decisions; nothing yet)

- `pet_state.gd`: `boost` becomes a POWER (game, minutes left, level); the won't-drink rule at 8 h;
  the streak and its tokens; the snack (a food of the spirit's own size).
- `DrinkLibrary.gd` / `shop.gd`: six drinks, one per game (the 6th needs its 3 icons from the
  designer); a drink arrives with its game; levels 2-3 = longer.
- `base_minigame.gd`: the power's timer inside levels, its HUD icon draining; `gate_open()` by the
  game's own power.
- Each game: the power, the gold target, the routes (section 7).
- `lcd_screen.gd` / the drink menu: the power's minutes; what each drink opens now.
- `shrine.gd`: the dark hokora and its waking; the send-off ceremony.
- `tools/design/pacing.py`: DONE (v4: `POWERS`, `DRINK_OF`, `POWER_MIN`, `THIRD_WITHOUT`, the
  catalogue check). Still to add once decided: the streak tokens, the snack, the sold/earned homes.

## 9. Every cycle, in one place (the checklist, to check against later)

The user (2026-11-11): "are you sure we are covering all the cycles?" Every loop the game has, with
its clock, what it gives, where its rules are written and whether it's built. Anything not in this
table is not a cycle of the game.

| Cycle | Clock / trigger | Gives | Rules | Status |
|---|---|---|---|---|
| The meal | after a NEW spirit: Sho 3 min, Chu 10, Dai / mutant / legend 30; a known step 0 | the next offering; the collection's pace | progression.md 3 | BUILT (`pet_state.gd` WAIT_NEW) |
| Hunger | 2 h hungry, 8 h very hungry, 24 h the dark hokora | the nudge back; the won't-drink rule; the streak reset | here, 3 | the faces BUILT; the consequences and the 2 h notification (none exists yet) PROPOSED |
| The snack | any time | feeding without evolving (keep a spirit) | here, 3 | PROPOSED |
| Food packs | coins (Sho 10, Chu 15, Dai 20; shown when a size is about to be needed) | the tree's other branches | progression.md 3 | BUILT |
| Special foods | found first in a game (a vault = now a route for the game's power; a finale), then the daily shelf (one of each kind a day, 15 / 40), or from 350 / 450 stars; a spare one turns into coins; the shrine blessing (a home's full set: its special) | the mutants and the legends | progression.md 3 | BUILT, the blessing PROPOSED; the routes remap with the powers |
| The drink | one every 15 min; the first meal starts it | a power | here, 2; `lcd_screen.gd` | the countdown BUILT; the power PROPOSED (today: a one-shot boost) |
| Drink types | one per game, arriving with it; the 6th (Spicy) new | the powers | here, 2 | PROPOSED (today: the Nth game gives the Nth type) |
| Drink levels | bought, 10 / 20 per type | a longer power; the tier-2 / 3 routes | here, 2 | BUILT in the Shop; the meaning PROPOSED |
| Secrets (3-6-9) | each world's 3rd level a small pickup, its 6th the secret, its 9th the finale | coins and stickers; hokora pieces, specials, dress-ups; cases, legends | progression.md 4b | BUILT with drink-type gates; to remap to the game's own power |
| Stars and coins | 1 coin per new star; the daily request +2 | the catalogue | progression.md 5; here, 4 | BUILT |
| Gift tracks | 5 / 15 / 30 / 60 / 100 / 150 stars per game | a drift, a hanging piece, a dress-up, a shelf pair, a sky, the gold sticker | progression.md 5b | BUILT |
| The Tomopedia | every 10 spirits; 10 of a realm | a grand piece; the realm's colour | progression.md 5b | BUILT |
| Lucky Pinch | every 4th new spirit; the streak's tokens | 8 exclusives, then +3 coins | progression.md 3; here, 3 | BUILT; the tokens PROPOSED |
| The streak | days in a row with a meal: 3 / 7 / 14 / 30 | Lucky Pinch tokens | here, 3 | PROPOSED |
| The Shop | games, packs, drink levels, the daily specials, the HOME stall, stickers, plain cases; sections open as they become relevant | choice, never prestige | progression.md 5, 5b; here, 4 | BUILT; "nothing prestige sold" PROPOSED |
| The homes | 60 / 90 / 120 spirits, a finale, the four seasons, the streak | the hokoras | kami_future_hokoras.md; here, 4 | PROPOSED |
| The send-off | the player's choice on a grown spirit | the generation mark; blessed spirits (an update) | here, 6 | PROPOSED |
| Away | nothing happens while away, on purpose (no loss); the only away event is the dark hokora at 24 h | the return moment | here, 3 | PROPOSED |

Two things this audit found and fixed (2026-11-11): the model drank at minute 0 while the game's
first drink is at minute 15 (now the first meal starts the model's countdown too: the first secret
is at 16 min again); and the special foods' obtention wasn't restated with the powers (above: a
vault is a route for the game's own power, at the tier's drink level).

## 10. To measure on the phone (TestFlight), replacing the model's assumptions

The minutes per try and the fail rates per difficulty · the 3rd-star rate with and without the power
· whether 15 min between drinks feels right (10 is the fallback) · how many players come back after
the 8 h and 24 h marks (the care ladder's real test) · the first hour's gaps (never more than 5-6
minutes without something new).
