# The core, reviewed (14 November 2026): what stays, what to fix, the plan

The user (2026-11-14): "review all the core logics for gameplay and progression and difficulty curve
through the games, to leave track of the best plan for it. We have a good base no? We can leave most
of the parts as they are no?"

**The answer: yes.** The base is good and almost all of it stays as built. On top of it goes the loop
decided on 12 November (`docs/loop_v2.md`), which is a layer, not a rebuild. This review read the
code, ran the model and played every level it could with the games' autopilots. It found **seven
things** to fix or decide; two matter a lot (the first two below), and none of them changes the
design. Nothing here is built except the measuring tools (section 1).

Where this file and an older note differ, this file wins for what it covers; `docs/loop_v2.md` is
still the loop, `docs/games_pass.md` still the stars' contract.

## 1. How it was checked (and how to repeat it)

| What | How | Repeat with |
|---|---|---|
| The rules as built | read in `scripts/pet_state.gd`, `game_data.gd`, `shop.gd`, `DrinkLibrary.gd`, `lcd_screen.gd`, `main_button.gd`, `collection.gd`, `base_minigame.gd` and each game's level tables | - |
| The calendar and the coins | the model, with three new what-ifs that leave its defaults alone | `python3 tools/design/pacing.py`, `python3 tools/design/whatif.py sendoff`, `... seven` |
| The difficulty as built | every level of a game played by its autopilot, headless, as fast as the Mac goes (54 levels in 1-4 minutes) | `python3 tools/qa/sweep.py prix` (or `prix2`, `sumo skill=1`...), `python3 tools/qa/sweep.py all` writes `docs/difficulty_measured.md` |

New in the code for this, all development-only and off unless `tools/qa` turns it on: a result line
per level in Tilt Maze and Top Spin (`print("QA ...")`, as the other games had), and a **pretend
player** for Pal Prix (`qa_human` in `scripts/rc_racer.gd`): the clean autopilot with a person's
lapses (now and then the thumbs freeze for a moment). It is not calibrated: it says which levels are
harder than which, not how often a real player fails.

**Not checked:** anything on the phone; Splash Hoops by play (it has no autopilot); Tilt Maze and
Top Spin by play (their autopilots are screenshot helpers, not players: one rolls into the holes, the
other never steers); Tomo Tunes (its own plan, `docs/tomo_tunes.md`).

## 2. The core as built: what stays

| Part | The rule, as the code has it | Verdict |
|---|---|---|
| The four things | stars = skill, coins = choice, spirits = the long goal, drinks = the bridge; the home shows it | stays |
| Worlds and levels | 6 worlds of 9 in every game; a level opens when the one before is cleared (`GameData.level_open`); retry is instant; 3 hearts in Tilt Maze and the races | stays |
| The world's shape | the new thing alone (1-2), pushed (3-5), the secret (6), the world before's joins in (7-8), the finale (9); each world starts easier than the last ended | stays; measured in section 4 |
| Stars and coins | 1 coin per new star (`record_level`), +2 on the day's first new star | stays |
| The games' prices | 5 / 30 / 50 / 70 / 100; Pal Prix 2177 is won with Pal Prix 6-9 | stays (finding 4) |
| The meal clock | a NEW spirit settles in: Sho 3 min, Chu 10, Dai / mutant / legend 30; a known step straight away (`PetState.WAIT_NEW`) | stays, **with finding 1** |
| The tree | 120 spirits, 5 realms; a baby grows only on kid food, a kid on adult food; tech / cosmic on a Dai, the legendary food on its ULTRA Dai | stays; +10 mutants are decided |
| Food and specials | packs 10 / 15 / 20; a special is found first in a game, then on the daily shelf (15 / 40), or from 350 / 450 stars; a spare turns into coins | stays |
| The drink clock | one drink every 15 min, running while the app is closed | stays |
| What a drink does | 5 types x 3 levels, each a one-shot boost read differently by each game; a type per game owned | **replaced by the decided loop** (one drink per game = its timed power, two tiers) |
| Secrets | the 3-6-9 rhythm, 61 secrets, 58 behind a drink | stay where they are; their gates move to the game's own drink (decided) |
| Gifts | each game's track at 5 / 15 / 30 / 60 / 100 / 150 stars; the Tomopedia every 10 spirits; a realm's colour at 10; Lucky Pinch after every 4th new spirit | stays |
| The Shop | sections that open when they matter; drink levels at 10 / 20 | stays; the drink prices become one better drink at 30 (decided) |
| Care | nothing: the code has no hunger at all (the sad and angry faces are drawn, nothing uses them) | the decided ladder is to build |
| Saving | the testing switches are on (`FRESH_START_ON_LAUNCH`, `RESET_ON_LAUNCH`...) | known, before release |

## 3. What the review found

### 1. A send-off skips the meal clock (the biggest one; a one-line cause)
The whole pace of the collection rests on "a new spirit needs time to settle in". But
`PetState.flush()` sets the meal clock back to zero, the send-off is allowed at any moment
(`main_button.gd`), and a known step costs no wait. So after ANY new spirit the wait can be skipped:
send it off, hatch again, walk the known steps, feed the next new one. Players will find this at
once, because sending off is how a new branch is started.

`python3 tools/design/whatif.py sendoff` (the model serves every wait; the game doesn't):

| Regular player | 30th spirit | 60th spirit | All 120 | Sessions with a new spirit, days 2-30 |
|---|---|---|---|---|
| The model (every wait served) | day 6 | day 13 | day 28 | 91% |
| The game today, sending off each grown spirit at once | day 3 | day 5 | day 21 | 23% |
| The game today, sending off after every new spirit | day 1 | day 2 | day 22 | 13% |

The end date hardly moves (the food packs and the specials still cost coins), but the rhythm breaks:
a binge in the first two days, then most visits bring nothing. That is the opposite of the cycle
loop v2 describes.

**The fix, two ways (the user's choice, decision 1):**
- **A (recommended): a spirit that has just arrived can't be sent off yet.** While its meal countdown
  runs, the hold does nothing (the spirit shakes its head). It reads as "it is settling in", the new
  spirit stays on screen for its 3 / 10 / 30 minutes, and it fits the send-off as a ceremony.
- **B: the wait stays with the shrine.** The send-off is always allowed, but the countdown keeps
  running over the empty hokora. One line of code, but up to 30 minutes of an empty shrine.

### 2. The clocks belong to the spirit; they should belong to the shrine
The same `flush()` also clears the drink's effect and restarts the drink clock (15 min after the
next first meal). Today that is minor. With the decided loop it is not: a power lasts 5 minutes of
play, and the collection asks for a send-off after every grown spirit, so **collecting and playing
would fight each other** (a player holding a power won't send off). The rule to build with the
powers: a send-off touches neither the power nor the drink clock.

### 3. The model leaves out a whole game
The model has six games (972 stars). The code has seven with levels: the five that are bought, Pal
Prix 2177 (54 levels built, won, not bought) and Tomo Tunes (to come). Pal Prix 2177 is not in the
model at all: its 162 stars, its play time, and the 140 coins its secrets and finales pay.
`python3 tools/design/whatif.py seven`:

| Regular player | Stars | Coins earned in 120 days | 90% of the stars | Every star |
|---|---|---|---|---|
| The model as it is | 972 | 1285 | day 59 | day 79 |
| With Pal Prix 2177 (as built) | 1134 | 1587 | day 68 | day 91 |
| The launch without Tomo Tunes | 972 | 1425 | day 55 | day 74 |

So **"the budget is full" (loop v2, section 4) is not true**: there are about 300 coins more than the
catalogue's 1325. That is exactly the room loop v2 was missing for the one home that is sold (the
Ramen Stall, about 150) and for buying some of the new exotic foods, with no 7th world needed. The
price: the last star moves from day 79 to day 91. To do: put the 7th game into the model's defaults
and decide whether Tomo Tunes is in the launch (decision 5).

### 4. Pal Prix 2177's key is the masters' finale
It opens with Pal Prix 6-9. The skeleton's own rule is that nothing the collection needs waits on a
world 6. Nothing needed is only there (its Moon Rock and Stardust Sugar are also sold), but a seventh
of the stars, 140 coins, five hokora pieces and (in the homes' draft) the Neon Shrine are. In the
model a regular player opens it on day 17, a casual one on day 72; with the key on 5-9 (the Phoenix
Cup) it is day 12 and day 39. And finding 6 says the model is optimistic about Pal Prix's late
worlds. **Recommended: keep it on 6-9** (it is the reward for the Grand Prix, the user's decision of
19 October), count it as the encore, let its coins pay the sold home, and look again with the
phone's numbers; 5-9 is the fallback (decision 2).

### 5. Two games score two different things, so the power can't own the 3rd star
The contract (`docs/games_pass.md`): the 2nd and 3rd star are two marks on one scale, and the power
pushes that scale. As built:

| Game | 2nd star | 3rd star | One scale? |
|---|---|---|---|
| Splash Hoops | 20% of the time left | 45% left | yes |
| Tilt Maze | within the par time | no fall | no, but HOP (it hops pits) helps the 3rd; fine |
| Pal Prix | within the par (1st with rivals) | no crash | **no: HEAT makes the toy faster, so it would work against the 3rd star** |
| Pal Prix 2177 | within the par | within the turbo time | yes: the pattern for Pal Prix |
| Paper Sumo | 2-0 | 2-0 within the par time | yes |
| Top Spin | 40 of spin left | 70 left | yes |

Pal Prix's 3rd star has to become a time (the gold par), as `games_pass.md` already asked
(decision 3). The marks are also not equally hard from game to game today: Tilt Maze's par looks
about three times too loose (two levels cleared at half tilt in 11-12 s against pars of 29 and 35),
Paper Sumo's is generous in world 1 (a fighter that only drums wins every level 2-0 in 5-12 s against
pars of 16-20), Pal Prix's car par is within 8-12% of a perfect drive. The contract's tuning loop
fixes that, once every game has a pretend player (the plan, step 0).

### 6. The difficulty curve, measured where it can be (section 4)
In short: Pal Prix's two **boat worlds are far harder than the worlds around them**, Paper Sumo's
world 2 is harder than its world 3, and two Pal Prix levels fail even for a perfect driver.

### 7. One open point in the decided loop: the first fifteen minutes
The first drink comes 15 minutes after the first meal, and the contract makes every level's 3rd star
"about 1 try in 8" without the power. So for the first quarter of an hour, in world 1 of the first
games, a new player who plays well would still see two stars. The model doesn't have this (its first
clears pay 2.5 stars on 1-1, power or not). **Recommended: the contract starts at world 2.** World 1
teaches the stars by skill alone; the golden hoop on Splash Hoops 1-3 teaches the drink (decision 4).

### Smaller things (notes that disagree with the code)
- `loop_v2.md` section 9 says the hunger faces are built: they are drawn, no rule uses them.
- The roadmap says "six games": there are seven with levels.
- The code sells drink levels at 10 / 20 for three tiers; the model already has one better drink at 30.
- Paper Sumo's first world is much quicker than the model thinks (fights of 5-12 s; the model counts
  over a minute a try), so it pays its first 27 stars in a few minutes. Harmless, to correct with the
  phone's numbers.

## 4. The difficulty curve

### The target (the skeleton and the contract, as marks that can be measured)
- A world's first pass pays fewer stars as the game goes on: about 21 of 27 in a world 1, about 15
  of 27 in a world 6 (the model's regular player). Inside a world the first levels are easy and the
  9th is a step up; the next world starts below it.
- A try fails about 1 time in 12 on 1-1, about 1 in 2 on a world-6 finale.
- The 3rd star: 2-3 tries with the power, about 1 in 8 without (from world 2, if decision 4 is taken).

### What was measured (`docs/difficulty_measured.md` has every level)
Stars a world paid, of 27:

| | W1 | W2 | W3 | W4 | W5 | W6 | Reads as |
|---|---|---|---|---|---|---|---|
| The model's regular player (assumed) | 20.7 | 19.5 | 18.3 | 17.2 | 16.0 | 14.8 | the target |
| Pal Prix, the clean drive | 27 | 27 | 26 | 27 | 22 | 23 | the courses work; two levels don't (below) |
| Pal Prix, the pretend player (5 runs) | 23.2 | **9.4** | 23.6 | 22.8 | **7.2** | 16.2 | the boats (W2, W5) are walls |
| Pal Prix 2177, the clean drive | 24 | 22 | 23 | 20 | 22 | 21 | flat, as meant ("faster, not harder") |
| Paper Sumo, a fighter that drums and leans | 27 | 22 | 25 | 22 | 18 | 16 | a good slope; W2 above W3 |
| Paper Sumo, one that also shakes and pulls | 27 | 19 | 24 | 18 | 11 | 17 | the same |

### Game by game

**Pal Prix (measured).** Races last 27 to 75 s, each world restarts on short courses: the saw-tooth
is there. The car and plane worlds sit close to the target. The boat does not: in the Lagoon
(world 2, the second world a player meets) the pretend player failed 19 tries of 45 and never
cleared 2-9; in the Reef (world 5, where the Phoenix Pepper is) 28 of 45, never clearing 5-8 or 5-9.
In the same five runs the car worlds failed 3 and 2 tries and the Sky none. Of its 294 crashes, 171
were a boat running onto the bank. The reason is in the rules: the car has guard rails on its
corners, the plane a wide corridor, the boat drifts and the bank past the buoys is a crash
(`SHORE_AT` 36 px). **To do in its pass: make the bank forgive** (wider water or the bank further
out in world 2, a bump back off the first touch like the car's rails), then sweep again until the
Lagoon sits between the Garden and the Sky. Also: on 5-6 a rock and on 6-3 a storm sit where a
perfect driver hits them every lap (the level can't be cleared by the autopilot); 3-9 and 5-9 cost it
a crash. Four levels to look at by hand. The par is 8-12% over a perfect drive for the car, 5-22%
for the boat and the plane.

**Pal Prix 2177 (measured, clean drive only).** Every level clears; 29-68 s; the par is 8-22% over
the clean drive; the turbo time needs the boosts (the autopilot gets it on 24 levels of 54). Its
stars are already two times on one scale. It needs the pretend player before its marks are judged.

**Paper Sumo (measured, two simple fighters).** World 1 is a walk (every level 2-0), then a steady
slope down to the masters' world, with each world's last levels the hard ones: the shape wanted. Two
things: world 2 (the turtles) is harder than world 3 (the otters), and its champion 2-9 beat both
fighters; and worlds 5-6 end on levels neither could win (5-8, 5-9, 6-9), which is where STURDY, the
game's own power, is meant to be needed. Fights last 5 to 74 s.

**Tilt Maze (read, not played).** Every world has the same nine steps (2-5 marbles, 0-8 holes, 0-3
blockers, a route of 8 + 2 per level + 1 per world cells), so each world restarts at no holes at
all and what grows from world to world is the floor (slippery, bouncy, currents, magnets, low
gravity) and the enemy. That is a deep saw-tooth on a nearly flat line: fine for a second game, to
confirm by play. Its par is the loose one (finding 5).

**Splash Hoops (read, not played).** Hand-made levels: the layout, the baskets' motion and speed
(0.7 to 1.9), the seconds (30 to 70), the pufferfish. The two star marks are the same share of the
time on every level (20% and 45% left), so the seconds given are the whole tuning, and nobody has
measured them. It is the pilot of the games pass and the first game anyone plays: it needs its
pretend player first.

**Top Spin (not measured).** Its autopilot never steers, so it flies out of the rim: it lost a third
of world 1 and nearly everything after. That says nothing about a player, except that an unsteered
match can be lost in 3-5 seconds. The model takes Top Spin as the hardest game; it is the one to
measure first after Splash Hoops.

### What the tuning needs
A pretend player in every game (the clean autopilot plus a person's mistakes), because 378 levels
can't be tuned by feel. Pal Prix has one; Pal Prix 2177 can take the same; Paper Sumo's two fighters
need a third, better one; Splash Hoops, Tilt Maze and Top Spin need a real one. Then the contract's
loop (`games_pass.md`, section 3) is a command, and the phone confirms it.

## 5. The plan, bit by bit

The decided order stays (`docs/ideas_roadmap.md`, "Next, in order"). The review adds a step before
it and a few notes inside it.

**Step 0. Close the leaks and build the measuring kit** (small; nothing of the new loop yet)
1. The send-off and the meal clock (finding 1), once decision 1 is taken. Done when: a new spirit's
   wait can't be skipped, checked by a QA script.
2. The model gets its 7th game and the what-ifs' numbers go into `loop_v2.md` (finding 3). Done when:
   `pacing.py` prints 1134 stars (or 972 without Tomo Tunes) and its checks pass.
3. The pretend player in every game, in the order of the pass: Splash Hoops, Tilt Maze, Pal Prix
   2177, Paper Sumo, Top Spin. Done when: `tools/qa/sweep.py all` fills a table for every game and
   the table looks like what the user feels on the phone for the levels they know.
4. Logging for the phone (tries and stars per level, power on or off): the same numbers from real
   players. It can wait for TestFlight but costs little now.

**Step 1. The shared work of the loop** (as decided), with from this review: the power and the drink
clock survive a send-off (finding 2); the contract starts at world 2 (decision 4).

**Step 2. Splash Hoops, the pilot** (as decided): its look, TIDE, its marks set by the loop.

**Step 3. The other games' pass** (as decided), with from this review: Pal Prix's boat forgiveness
and its four levels to check, its 3rd star as a gold time; Tilt Maze's par; Paper Sumo's world 2
against world 3; Top Spin measured before anything is changed.

**Steps 4 on** (care, the tree to 130, the homes' ladder, the send-off's ceremony): as decided. The
sold home can be paid by Pal Prix 2177's coins (finding 3).

Tomo Tunes goes on beside this on its own plan.

## 6. Decisions for the user

| # | Decision | Recommended |
|---|---|---|
| 1 | The send-off and the meal clock: A, a new spirit can't be sent off while it settles in; or B, the wait stays over the empty shrine | A |
| 2 | Pal Prix 2177's key: Pal Prix 6-9 as built, or 5-9 | keep 6-9, look again with the phone's numbers |
| 3 | Pal Prix's 3rd star becomes a gold time (no crash stops being a star) | yes |
| 4 | The "3rd star is made for the power" rule starts at world 2, not at 1-1 | yes |
| 5 | Is Tomo Tunes in the launch (1134 stars) or the first update (972)? | the user's call; the model handles both |
