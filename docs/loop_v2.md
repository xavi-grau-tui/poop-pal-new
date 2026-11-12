# The loop, v2: one consistent system (DECIDED 2026-11-12; nothing built yet)

The user (2026-11-11): "what concerns me the most is the gameplay progression: the eating timings,
the dopamine cycle, the penalisation of not eating/playing... we need something consistent." This
page is the answer: the October skeleton (`docs/progression.md`) and the 31 October direction
(`docs/economy_pillar.md`) resolved into one system, checked in the model (`tools/design/pacing.py`,
now v4: run it plain for these rules, `old` for the October ones). Nothing here is built.

**Status: the user decided A-H on 12 November 2026** (the table and the review are in section 11;
the short version and what comes next are at the top of `docs/ideas_roadmap.md`). Sections 0-10
are the proposal as written, with each decision marked where it was taken.

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
runs only while you're inside a level of that game, and lasts 5 minutes (the better drink: 10; two
tiers, below). One power at a time: drinking again replaces it. So a drink is never wasted on a visit to feed,
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
  built into the course. The gate stays by tier (worlds 1-3 open with the plain drink, 4-6 want the
  better one), so the better drink buys something besides minutes.
- **A drink does nothing in another game.** One word per drink, everywhere. The old table (Splash a
  second chance in every game, Fizz in four games...) goes; the hearts stay as the lives.
- **Why 15 min / 5 min:** in a 15-minute session you get one power: 3-5 levels, one or two 3rd stars.
  The model: a regular player plays 43% of their minutes powered, a casual 66% (they play little, so
  most of it is powered), a keen player 18% (the ration bites them, as intended). Days to 90% of the
  stars: 59 with the powers, 58 without. **The ration works without stalling anyone.**
- The first drink (minute 15) is Watery: the TIDE reaches the golden hoop in Splash Hoops 1-3, so
  the first secret is in the free game with the first drink (it used to need Tilt Maze's Fizzy).

**DECIDED A (2026-11-12: Spicy for the races).** The 6th drink: Spicy for the races (HEAT: the roadmap's "spicy = fast"), Caffeinated
for Tummy Tunes (timing). The alternative: Caffeinated stays the races' (slow-motion before a crash,
as built) and the new drink is Tummy Tunes'. Spicy is the recommendation: heat on a race track reads
instantly, and FOCUS on a rhythm game is the natural word.

**DECIDED B (2026-11-12: two tiers, below).** Drink tiers make the power LONGER, not stronger. Stronger would mean retuning every
3rd star per tier. Longer keeps one tuning and still sells (plus the routes).

**Two tiers, keeping the icons** (the user, 2026-11-11: "I like the 2 tier approach, the right one not
to overwhelm the user"; agreed). First answer that day was three (three named drinks each, the three
world tiers, the 180-coin sink); two does the same job with less to read: 12 entries in the drink
menu instead of 18, and "the plain one / the better one" instead of a level number. Tier 1 = 5 min of
power, tier 2 = 10 min + the routes of worlds 4-6 (worlds 1-3 want tier 1); tier 2 costs 30 per type
(6 x 30 = 180: the sink unchanged). The icons we have are enough (16 drawn for 12 slots): Shrine Water
-> Coconut Water, Cola -> Ramune, Green Tea -> Coffee, Milk -> Bubble Tea, Mikan Juice -> Smoothie,
and the new type Ginger Ale -> Energy Drink (one new icon; Energy Drink leaves the caffeinated line).
The spares (Barley Tea, Cream Soda, Peach Juice, Milkshake, Lemonade) wait for seasonal or event
drinks. The model with two tiers: nothing moves for the regular and keen players (90% of the stars
day 59 / 24, the first tier-2 bought day 6 / 4) except the casual player's 5th game, day 48 instead of
31, because the model buys a 30-coin drink before Top Spin: the guide cards nudge "the next game
first", and the first tier-2 purchase can wait for world 4. `pacing.py` runs with two tiers now.

**The decisions page** (2026-11-11): https://claude.ai/artifact/4iUmvQ1teqnUBSmCE4kgdF explains the
whole loop and holds the user's choices and notes for decisions A-G in its own store (read them with
the ArtifactData tool, collection `decisions`, and `notes/general`). G (the spirit asks with an icon)
is already recorded there.

## 3. Care: what not feeding costs (the penalties)

**The principle: care gates the powers, never the collection.** Nothing a player owns is ever lost: no
sickness, no going back a stage, no spirit lost. What missing care costs is the thing that makes you
great at the games, and today's chance.

| Since the last meal | The spirit | What it costs |
|---|---|---|
| 0-2 h | fed (its happy face) | nothing |
| 2-8 h | hungry (its 2nd face); it asks for food at 2 h (below) | nothing yet |
| 8 h+ | very hungry (its 3rd face): **it won't drink until it has eaten**, so no power; the daily request waits for the meal | the games are harder until you feed it (one tap) |
| 24 h+ | the hokora goes dark: the lanterns out, the spirit asleep on the slab; the first offering wakes it and the lanterns light one by one | the streak resets (below) |

- **The spirit asks, with an icon, never a sentence** (the user, 2026-11-11: "no need to say 'hungry
  spirit', an icon said by the spirit could be enough"). On the pet screen a small speech bubble
  over the spirit with an offering on a tray, from 2 h; from 8 h the bubble also shows the drink cup
  crossed out, so the won't-drink rule explains itself; at 24 h the dark hokora says it without a
  bubble. Calm (pillar 5): the bubble shows when the screen opens and when the spirit is poked, then
  fades; the LCD's blinking meal digits stay the second cue. The push notification (text only on the
  phone) is the spirit's name and one glyph ("Picklet 🍙"), no sentence. With the touch screen (the
  roadmap's idea) a tap on the bubble opens the food menu on that offering.
- **The streak (new).** Every day you feed the spirit counts. 3, 7, 14 and 30 days in a row give a
  **Lucky Pinch token** (a free go at the claw: its exclusives, then coin capsules). A missed day
  resets it to 0. That's the only thing that can be "lost", and it's a chance, not a possession.
- **A snack (the user's idea, 2026-10-10).** Food of the spirit's OWN size feeds it without changing
  it. So a visit never forces an evolution, a player can keep a spirit they like for days, and
  "feed it" is always a thing you can do. The next size up is marked "grows".
- **Not playing** costs nothing beyond its own result: no stars, no coins, the powers unused. The
  power waits for the first level, so a drink taken on a feeding visit is still there tonight.

**DECIDED C (2026-11-12: this ladder; sad and asleep faces with it, angry only as a reaction).** This ladder (won't drink at 8 h, the dark hokora and the streak at 24 h; never sickness
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

**DECIDED D (2026-11-12, by the user's note: most homes earned, the first easily and then harder, maybe one
sold; the ladder is drafted in section 11). The proposal was: nothing prestige is ever sold.** The homes are all earned (the Moon at 60 spirits, the
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

**DECIDED E (the user, 2026-11-12).** The send-off ceremony and the generation mark in v1; blessed
spirits as the first update ("it doesn't affect too much and adds a bit of variety"). Today the
send-off already exists as a 2 s hold on the pet view (`main_button.gd`, `shrine.sendoff_ring()`):
what's new is that it counts (the mark) and, later, that it can bring a blessed spirit.

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
| Hunger | 2 h hungry, 8 h very hungry, 24 h the dark hokora | the nudge back; the won't-drink rule; the streak reset | here, 3 | the faces BUILT; the consequences, the speech bubble and the notification (none exists yet) PROPOSED |
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

## 11. The decisions (12 November 2026) and the review

### What the user decided (the page's store, read 2026-11-12)

| | Decision | The user's note |
|---|---|---|
| A | Spicy is the races' drink (HEAT); Caffeinated goes to Tummy Tunes (FOCUS) | |
| B | Two drink tiers, keeping today's icons; the better drink costs 30 | |
| C | The soft ladder (won't drink at 8 h, dark hokora and streak reset at 24 h, never sickness or regression) | "we could combine with sad / angry face, or use them for something to give dynamism to the app" |
| D | The tick is "the coolest pieces in the Shop", the note is the brief: **most homes earned, the first ones easily and then harder, maybe one special home sold; 12 homes in total** | (the note wins over the tick) |
| E | The ceremony and the generation mark in v1, blessed spirits as the first update | decided in chat after the explanation |
| F | The snack is in (the spirit's own size feeds without evolving) | |
| G | The spirit asks with an icon in a bubble, never a sentence | decided in chat, 2026-11-11 |
| H | The fourth stage: each exotic food its own mutant, 4 per realm, 130 spirits | "maybe we can have 2 per type for visual variety": two tech and two cosmic per realm, which is this option |

"Keep the rest as specified in the form and eventually change something at the final refinement."

### Does it close? Mostly yes

On paper every clock has a reward and every reward has somewhere to go. The model's eleven checks
pass with the decisions in (regular player): 26 new things in the first hour and never more than
6 minutes without one; a new spirit in 91% of the first month's sessions; every game by day 19, the
collection on day 28, 90% of the stars on day 59, every star on day 79; never more than 100 coins
idle; the catalogue (1325) against the coins earned (1285). Not feeding costs the powers, never the
collection, and one offering repairs it.

What is still open, in the order it matters (`tools/design/whatif.py` gives the numbers):

**1. The fourth stage is the thin one (DECIDED H, the user, 2026-11-12: four per realm, two per type).** All 15 grown
spirits of a realm turn into the same two mutants, so the path stops mattering exactly where the
foods get strange; and of the four exotic foods two are duplicates (the Battery does what the
Microchip does, the Moon Rock what the Alien Goo does). 15 of 120 spirits come from special foods.
The proposal: **each exotic food its own mutant, 4 per realm, 20 in all, 130 spirits** (a realm =
1 Sho, 5 Chu, 15 Dai, 4 mutants, 1 legend = 26). Then finding a new food in a game opens five
silhouettes in the Tomopedia at once, one per realm: the games feed the collection directly. The
legends stay one per realm (their rarity is the point).

| `whatif.py stage4` (regular) | spirits | collection complete | special foods bought | sessions with a new spirit, days 2-30 |
|---|---|---|---|---|
| today | 120 | day 28 | 120 coins | 91% |
| 4 mutants per realm, same finds | 130 | day 33 | 265 coins | 91% |
| ...and 6 more exotic foods as secret prizes | 130 | day 30 | 165 coins | 100% |

So it needs two things besides the tree: **10 more designs** (2 per realm; Fire has three spares in
the pool: C41, A43, A32) and **about 6 more exotic foods placed in the games** as secret prizes, so
the new mutants are found rather than bought (the budget is full). The casual player's collection
moves from day 62 to day 71. The time to decide is now: the realms' sheets are being laid out at 24
slots (Fire v3 is; the other four aren't started). The Tomopedia's 7th page per
realm (the specials') would hold five spirits instead of three: to lay out. Alternatives: keep 10; or 4 per realm as an update (the Battery and the Moon
Rock stay duplicates at launch).

**2. The better drinks compete with the last games.** With the better drink at 30 and bought as
soon as a gate wants it, the regular player gets the 6th game on day 19 and the casual one the 5th
on day 48 and the 6th on day 78.

| `whatif.py drinks` | Top Spin (casual) | Tummy Tunes (casual) | Tummy Tunes (regular) |
|---|---|---|---|
| as in the model | day 48 | day 78 | day 19 |
| one better drink at most while a game is still to buy | day 31 | day 47 | day 10 |
| the better drinks only once every game is owned | day 26 | day 43 | day 8 |
| the better drink at 20 | day 42 | day 58 | day 17 |

The price isn't the lever, the order is. The rule to build: **the first better drink is met at the
first world-4 gate (the Shop shows that one), the others come to the Shop once every game is
owned.** To put in the model with the games pass.

**3. The homes' ladder (D's note).** Twelve homes are in the catalogue (the Forest Hokora is the
start), eleven to get. Six had a source, five had none (River Shrine, Fire Shrine, Capsule Pod,
Arcade Cabinet, Bathhouse). A DRAFT for the final refinement, easy first, each from a different
loop so every loop has a home at its end:

| Home | Source (draft) | Regular player |
|---|---|---|
| River Shrine | 20 spirits | first week |
| Capsule Pod | the eight Lucky Pinch exclusives | week 1-2 |
| Moon Shrine | 60 spirits | day 13 |
| Bathhouse | the 14-day streak | day 14 at the earliest |
| Arcade Cabinet | half of all the stars | day 17 |
| Tree Hollow | 90 spirits | day 21 |
| Fire Shrine | Top Spin's Dragon Festival finale | month 1-2 |
| Golden Temple | every spirit | day 28-30 |
| Ruined Shrine | Paper Sumo's four seasons | month 2 |
| Neon Shrine | RC Prix 2177's finale | month 2 |
| Ramen Stall | the one sold (the user's "maybe one special"): needs ~150 more coins in (the 7th worlds give 162) or the 30-day streak instead | late |

**4. The keen player's ration.** They play with a power on 17% of the time (the regular 41%, the
casual 62%): a drink every 15 minutes covers a short visit, not a three-hour day. That is the
ration working, and it is also where a "timer wall" would be felt. Nothing to change on paper; on
the phone, the levers are the drink every 10 minutes and the better drink's 10 minutes.

**5. The faces (C's note).** Sad from 8 h and asleep in the dark hokora at 24 h belong to the
ladder. Angry doesn't fit "never punish" as a state, but it works as a reaction (a food it can't
use, a poke, a lost bout), which is the dynamism asked for. For the animations' revision.

**6. Nothing of loop v2 is built, and the model's players are assumed** (minutes per session,
skill). The balance above is a model's; section 10 lists what the phone has to confirm.

### After the decisions (the same day): the special foods' icons, the cases and stickers, what's next

**The special foods' icons.** All nine exist as 32 px icons (Microchip, Battery, Alien Goo, Moon
Rock; Golden Seed, Stardust Sugar, Dragon Oil, Phoenix Pepper, Kraken Brine) and none is missing
for H: two tech foods and two cosmic foods are exactly the four mutants per realm. They date from
3 October, before the food set was redrawn: a hard dark outline and flat fills beside the recent
foods' soft outlines and texture. So the work is a REDRAW of the nine in the current food style
(a designer round, to brief), and with H each exotic food now has to announce a look, since it
opens one kind of mutant in every realm:

| Food | Its five mutants | Status |
|---|---|---|
| Battery | the wind-up kind (brass, a key, gears): today's tech mutants | drawn in the old style; redone with the realms |
| Microchip | the circuit kind (LED eyes, traces, a pixel glow) | NEW, 5 designs |
| Moon Rock | the star-and-moon kind: today's cosmic mutants | drawn in the old style; redone with the realms |
| Alien Goo | the alien kind (goo, antennae, a UFO glow) | NEW, 5 designs |

An option for the redraw: the Battery becomes a Wind-up Key, which says "clockwork" better in a
shrine. What IS missing elsewhere: the Ginger Ale icon (the 6th drink) and the 10 new mutants.

**Cases and stickers: yes, they are in the loop, as rewards and as the last sink, never as
power.** Stickers: 18 themed ones are prizes (the small secret on a world's 3rd level, each
game's gold sticker at 150 stars, some first clears) and 30 are spirit stickers sold for a few
coins, only of spirits already met. Cases: 11 today, the themed ones won on finales (each game's
world 6), four plain ones sold at 40; planned ones at 250 and 500 stars and at every star. In the
model they are 320 of the catalogue's 1325 coins and are bought last, after every game and food
pack, so they never slow the progression. With loop v2 a world's small secret becomes a route
for its game's power, so the themed stickers now come from powered play. Their Shop sections open
when the first one is won.

**What's next, written down:**
- `docs/games_pass.md`: the stars, the powers and the difficulty as one contract for the six
  games, how each level's marks are set, and the order (the shared work, then Splash Hoops as the
  pilot).
- `docs/tomo_tunes.md`: the music game's plan (you play the world's instrument and the band plays
  on; six worlds, 24 songs; a Suno song split into the lead and the rest; the build order), and
  `docs/tomo_tunes_prompts.md`: the 24 Suno prompts, from `tools/audio/suno_prompts.py`. The pilot
  song (1A) comes first.

### Tomo Tunes after the pilot (12 November 2026, evening)

The approach is decided (the user, after playing 1A on the phone: "the approach works very well"):
the player plays the lead of a Suno song split in two, lanes by pitch, a miss silences the lead
while the band plays on. Suno Pro; world 3 is the Toy Ocarina, not the trumpet. Everything decided,
the band fix for phone speakers and the per-song workflow are in `docs/tomo_tunes.md` (sections
2b, 6b-6d).

