# KamiTomo: the skeleton (progression foundation)

DECIDED with the user 2026-10-16 (the open points are in section 8). The one place that says how the whole game fits together: the
games and their difficulty, the pals and the meal clock, drinks and boosts, special foods, coins,
and when a player gets what. Everything else is built on it, bit by bit. Once confirmed it replaces
"Progression v2", "round 2" and "Progression framework" in ideas_roadmap.md where they differ
(those keep their reasoning).

**2026-10-30, the hokora (yokai migration).** The spirit now lives in a hokora, not a gut. Sections
1, 4, 5, 5b, 6, 7 and 8 are rewritten for it: the home's four decor slots and the sky's two, where
every piece comes from (each game a festival stall with its own prizes), the 3-6-9 rhythm that gives
every drink somewhere to go, the Shop's HOME stall, and what's built now. BUILT on
`yokai-migration` (code and data, the art still to come: docs/kami_collection_art.md is the list for
the designer). The gut's own catalogue is kept untouched as the classic (the dev launcher's HOME:
GUT). What changed from earlier decisions is flagged in section 8 (TO REVIEW).

Every number here comes from the pacing model, `tools/design/pacing.py` (v3): a fixed player
model, no dice, the real evolution tree. Its player numbers (minutes per try, fail rates, stars on
a first clear) are ASSUMED until measured on the phone. Rerun it after any change:
`python3 tools/design/pacing.py` (+ `regular`, `levels`, `days`).

## 1. The game in one picture

Four things, one job each, and the home that shows them. Nothing else to learn.

| Thing  | Job                          | Comes from                          | Goes to                                     |
|--------|------------------------------|-------------------------------------|---------------------------------------------|
| Stars  | skill (1-3 per level)        | playing a level well                | coins (each new star = 1) · gift tracks     |
| Coins  | choice                       | new stars (+2 a day), small secrets | games · food packs · special foods · drink levels · the HOME stall · stickers and cases |
| Spirits| the long goal (time + choice)| offerings: what you feed decides who| the Tomopedia (120 today, more to come)     |
| Boosts | the bridge pet -> games      | drinks (one every 15 min)           | an assist in a game · the key to its secrets|
| Home   | the reward you SEE every visit | gift tracks, secrets, Tomopedia milestones, Lucky Pinch, the stall | the hokora (lanterns, hanging, shelf, colours) and its sky (colours, drift) |

Two clocks on the LCD: the MEAL clock paces the spirits, the DRINK clock paces the boosts. Skill
pays for what the spirit needs; time and choice decide who it becomes; its drinks open the games'
secrets, which hold the special foods the rarest spirits need and the hokora's best pieces. The
home is where all of it shows: a player opens the app and sees how far they've come (the lanterns
from Splash Hoops, the shimenawa from Paper Sumo, the moss roof from the Mountain spirits). Its
pieces are mostly gifts (gift tracks, Tomopedia milestones, Lucky Pinch, secrets); the Shop's HOME
stall sells only a few plain ones.

What is NOT in the game, and why:
- Points / score: they mean nothing across games and nobody plans around them. Each game shows its
  own measure (time, accuracy, bouts) and the stars. The LCD's number becomes the coins.
- Lives, except where falling is the game's danger: Tilt Maze and Pal Prix have 3 hearts (the user,
  2026-10-17), see "Failing". Elsewhere levels are short and retry is instant; the one "extra life"
  is the Splash drink, which comes from caring for the pal.
- Pal stats that change winning: the pal you have is decided by the collection (and the meal
  clock), not by the game you want to play. If a pal were better at a game, players would keep it
  instead of collecting. The pal is in every game as itself (ball, driver, wrestler, rider).
- Sickness, death, going back a stage: they punish the casual player, who is most of the audience.
  Care is rewarded (daily request, the pal's happy face), never punished.

## 2. The six games: order, controls, difficulty

| # | Game          | Price (now -> proposed) | Teaches                    | Drink type that arrives | Its special foods                  |
|---|---------------|-------------------------|----------------------------|-------------------------|------------------------------------|
| 1 | Splash Hoops  | free                    | the two buttons (hold)     | Watery (Splash)         | Kraken Brine (5-9)                 |
| 2 | Tilt Maze     | 5 -> 5                  | tilt                       | Fizzy (Fizz)            | Microchip, Battery, Moon Rock, Alien Goo (vaults) |
| 3 | Pal Prix      | 40 -> 30                | the buttons with precision | Caffeinated (Focus)     | Battery (2-6), Moon Rock (3-6), Phoenix Pepper (5-9) |
| 4 | Paper Sumo    | 60 -> 50                | buttons + tilt + rhythm    | Milky (Sturdy)          | Microchip (4-9), Golden Seed (5-9) |
| 5 | Top Spin      | 90 -> 70                | everything at once         | Fruity (Lucky)          | Dragon Oil (5-9)                   |
| 6 | Tummy Tunes   | 135 -> 100              | timing (3 buttons)         | -                       | Stardust Sugar (5-9)               |
| 7 | Pal Prix 2177    | won: Pal Prix 6-9       | switching (land, sea, air) | -                       | Moon Rock (5-6), Stardust Sugar (6-6) |

- Order (DONE in code, 2026-10-16): Pal Prix 3rd, Paper Sumo 4th (GameMenuSwitcher.ORDER,
  GameData.LAUNCH_GAMES, GAME_PRICE by position). Pal Prix uses only the buttons, so it's an easier
  step after Tilt Maze than Paper Sumo (buttons + tilt + the hop rhythm).
- Every game is buyable from the start (as now); the order is the suggested path and the price.
  The drink type arrives with the Nth game you own, whichever it is (as now), and each new type
  always has a use already: Tilt Maze has a vault kind for every boost.
- Prices 5 / 30 / 50 / 70 / 100 (255; were 330): with special foods and drink levels in the Shop,
  330 pushed the 5th game to day 15 and the 6th to day 37 for a regular player. Now: 5th day 2,
  6th day ~16 (a player who saves gets it in about a week).
- Tummy Tunes waits: the first five games are completed first; its design is kept here (worlds of
  toy instruments, 4 songs per world) for when its songs are made.

### Worlds and the 9-level shape (every game the same)
6 worlds x 9 levels in every game (DECIDED 2026-10-16) = 324 levels, 972 stars, 162 per game.
Three tiers of two worlds: 1-2 learn it, 3-4 master it, 5-6 the hard part; the drink gates follow
the tiers (level 1, 2, 3). World 6 is the MASTERS' world: the hardest levels in the game, with
prestige prizes (the game's themed case, a gold sticker) rather than anything the Pal Pedia
needs, so the collection never waits on it. Updates add world 7 to every game (+162 stars).
Each world has its own look and ONE new thing, and every world has the same shape, so a player
learns it once:

| Levels | What happens                                                                   |
|--------|--------------------------------------------------------------------------------|
| 1-2    | the world's new thing alone, gently (a breather after the last world's end)    |
| 3-5    | the new thing pushed, with the basics                                          |
| 6      | the world's SECRET (a gate for a drink, see 4)                                 |
| 7-8    | the world before's thing joins in (the mix rule Tilt Maze already uses)        |
| 9      | the FINALE: a showpiece or a boss; the world's last step up; world 5's finale holds the game's legendary food, world 6's the game's trophy |

Difficulty is a saw-tooth: each world starts below where the last one ended, then climbs above
it. In the model each level gets a number from 0 (a walk) to 10 (the hardest thing in the game):
world w starts at 1 + (w - 1), climbs 2.5 over its 9 levels, +0.7 on the finale; later games
are a little harder overall (Pal Prix +0.3 ... Tummy Tunes +1.0). What that means for a regular
player (`pacing.py levels`):

| Difficulty | A try fails | Stars on a first clear | Example                          |
|------------|-------------|------------------------|----------------------------------|
| 1 (1-1)    | 8%          | 2.5                    | Splash Hoops 1-1: two 100s       |
| 4 (1-9)    | 21%         | 2.1                    | the end of a world 1             |
| 6 (3-9)    | 30%         | 1.8                    | the middle of the game           |
| 9 (6-9)    | 43%         | 1.4                    | a world 6 finale                 |
| 10         | 48%         | 1.3                    | Top Spin 6-9 / Tummy Tunes 6-9: the hardest in the game |

First pass of a world: 9-25 min (world 1 of Splash Hoops to world 6 of Top Spin). Every level of
every game cleared: ~9 h of play; every star: ~25 h. No star gates: clearing a level opens the
next; stars pay in coins and gifts instead. Tune on the phone so the measured fail rates sit near
this table (TestFlight: log tries and stars per level).

### Each game's worlds (one new thing each)
(All five BUILT on `complete-games`, 2026-10-16: every world, its new thing, its look, its secret
and its finale; the details are in each game's script header.)
- Splash Hoops (BUILT): 1 Morning Lagoon (the pumps one by one) · 2 Sunset Drift (drifting
  baskets) · 3 Pufferfish Reef (the pufferfish) · 4 Night Lights (baskets going round) · 5 Storm
  (gusts; finale 5-9: Kraken Brine) · 6 Deep Sea (dark water: you see what the anglerfish's lure
  lights).
- Tilt Maze (BUILT): 1 Wooden Toy · 2 Bath Tiles (slippery) · 3 The Gut (bouncy walls, drifting
  holes) · 4 Sewer (currents) · 5 Factory (magnets) · 6 Space (low gravity, goo). From each world's
  4th level a blocker, telegraphed: pegs that pop up and gut valves are doors (wait for them); the
  rubber duck, the sewer rat, fire jets and meteors are ENEMIES (the user, 2026-10-18): a touch
  knocks the ball back in a hop, it blinks a moment (nothing hurts it, so it gets past) and a heart
  breaks; the duck rests against a wall between crossings, the rat hides in its grate between runs
  (always a way past). A vault gate for every drink (fence, cracked wall, channel, shutter, chest);
  its sticker prizes are stickers of your own pals (never one you haven't met: "sticker:pal").
- Pal Prix (BUILT, reworked 2026-10-17/18 after the user: two worlds per toy, in the order car,
  boat, plane, then each toy's second world): 1 Garden (the car: the basics, tyre barriers on the
  corners that bounce it back; boost pads; jumps over gaps) · 2 Lagoon (the boat: it drifts down a
  channel marked by floating buoys; past them the shallows slow it and the sandbank is a crash;
  currents; ramps over sandbars) · 3 Sky (the plane through rings, a sparkle trail to the next
  ones, the ground far below scrolling slower; gusts; hot-air balloons) · 4 Night Race (figure-8s
  with a bridge; rain, puddles and oil; rival cars) · 5 Reef (a coral bank, rocks and logs,
  whirlpools, rival boats) · 6 Grand Prix (a sunset over a sea of clouds: storm clouds, rival
  planes, all of the sky). Each toy's first world starts on easy shapes again (an oval, an L, a U).
  Bigger courses with room round them; puddles, oil, rocks, balloons and storms always to one side
  of the course, on straights. The crowd is pals of every kind, your own among them, never still;
  they scream and scatter at a crash near them. The lives are little toys of the world's kind.
  Battery on 2-6 (the Lagoon), Moon Rock on 3-6 (the Sky), Phoenix Pepper on 5-9 (the Reef: every
  game's legendary food is its 5-9 finale), the Grand Prix case on 6-9.
- Paper Sumo (BUILT; the rivals are critters of the pals' world, not pals, drawn by the pal
  renderer: tools/art/sumo_rivals.py, after the user's note that the first paper dolls, cereal
  mascots and origami didn't fit): 1 Wooden Box (frogs: hop, lean, push out) · 2 Pond Garden, a
  rock in a spring koi pond (turtles, heavy: lean in) · 3 Autumn Stream, a log raft under maples
  (otters, the tricksters: they pull you down) · 4 Moon Base, a landing pad (wind-up tin robots:
  they march on their own beat, drum your side and run down; the big robot -> Microchip) · 5 Tree
  Stump, a summer forest (beetles, mushi-zumo: the horn lifts you; the beetle king -> Golden Seed)
  · 6 Shrine Festival, night (the sumo ranks up to the yokozuna; the harvest yokozuna -> the
  Dohyo case). A level = one match, best of 3 bouts; a mystery challenger after each world's 6th
  level for a sturdy or focused pal. An autopilot (tools/qa, FAST=1) tuned every level: worlds 1-4
  are won by a decent player, the late masters' champions want a sturdy pal.
- Top Spin (BUILT; rivals are tops with styles): 1 Wooden Bowl (wind, drop, dash) · 2 Bumper Bowl
  (bumpers; the guard and the perfect guard) · 3 Lacquer Tray (rim gaps: ring-outs) · 4 Toilet
  Bowl (it flushes halfway: a whirlpool pulls every top to the middle) · 5 Clockwork Bowl (a floor
  of turning gears; finale -> Dragon Oil) · 6 Dragon Festival (three tops at once; finale: the
  dragon top). A level = one match.
- Pal Prix 2177, the Turbo League (BUILT 2026-10-19 on `pal-prix-2`, the final game: a reward, not
  bought; Pal Prix 6-9 opens it): one craft that turns from a hover car to a jet ski to a rocket at
  gates on the course. 1 Neon City (land + sea) · 2 Rapids (sea + air) · 3 Canyon (land + air) ·
  4 Ice Fjord (all three) · 5 Asteroid Belt (with rivals) · 6 Saturn's Rings (Earth to space and
  back). Faster, not harder: magnetic walls on land, hearts on the water and in the air (the user), boosts (chains, drift, slipstream);
  stars = the laps, the par (1st with rivals), the turbo time.
- Tummy Tunes (LATER; one toy instrument per world, loved by the user): 1 Toy Xylophone (single
  notes on the beat) · 2 Toy Piano (chords: two buttons at once) · 3 Toy Drums (holds and rolls) ·
  4 Music Box (off-beats, tempo changes) · 5 Star Stage (all of it, faster; finale: the star song
  -> Stardust Sugar) · 6 to choose: Toy Trumpet (holding a note = breath) or The Tummy (the pal's
  own gurgles and toots, the game's namesake). 4 songs per world, 24 in all, each played on easy /
  normal / hard charts (tools/design/rhythm_chart.py already makes all three): levels 1-3 = songs
  A-C easy, 4-6 normal, 7-8 two of them hard, 9 = the world's showpiece song. A level = 60-75 s.
  Later, the tryhard EX: La Campanella.

### Stars (1 = clear it, 2 = well, 3 = great; the HUD dims each one the moment it's lost)
| Game         | 1 star          | 2 stars                     | 3 stars                         |
|--------------|-----------------|-----------------------------|---------------------------------|
| Splash Hoops | every basket    | 20% of the time left (built)| 45% left (built)                |
| Tilt Maze    | out the flush   | within par (built)          | no fall (built)                 |
| Pal Prix     | 3 laps          | within par / 1st (built)    | no crash (built)                |
| Paper Sumo   | win the match   | 2-0                         | 2-0 within par time             |
| Top Spin     | win             | 40% spin left               | 70% spin left                   |
| Tummy Tunes  | finish the song | 85% of the notes            | 95% of the notes                |

### Failing (the answer to "lives?")
- A level is one self-contained try of 30-90 s; finales up to ~2 min.
- Lives in the traversal games (Tilt Maze, Pal Prix; the user, 2026-10-17): 3 hearts on the HUD
  (BaseMinigame). A fall, an enemy's touch, a crash (a car off the track, a boat on a rock, a plane
  missing a ring or into a balloon) breaks one, costs time and the "clean" star, and you're back on
  the last checkpoint (an enemy: knocked back; a missed ring: the plane flies on); the third ends
  the level: "Out of lives!", retry starts it again from the beginning. A splashy pal (Splash) has a
  4th, a water heart: its first fall is undone on the spot.
- Hard failure only where the game is a contest: time's up (Splash Hoops), a match lost (Paper
  Sumo, Top Spin; best of 3 bouts already forgives one), the groove empty (Tummy Tunes).
- Retry is instant: one press on the result card (RETRY first after a fail), no loading. Short
  levels + instant retry are kinder than lives (a restart costs seconds, never a world).
- The Splash drink is the one extra life, in every game (+10 s, a fall forgiven, a ring-out
  survived, the groove refilled once). So "lives" exist, but they come from caring for the pal.
- Top Spin's and Paper Sumo's 3 lives go when they move onto levels.

## 3. Pals: the meal clock and the layers of the collection

### The meal clock (PROPOSED: the biggest change)
Today every meal starts a 30-minute countdown. After the first week, two meals out of every three
meet a pal you already know (your Sho, then your Chu) and only the third finds someone new: most
visits bring nothing. Proposed:

| What the meal did                     | Next meal in                 |
|---------------------------------------|------------------------------|
| a NEW Sho                             | 3 min                        |
| a NEW Chu                             | 10 min                       |
| a NEW Dai, mutant or legend           | 30 min                       |
| a pal you've met before (or nothing)  | straight away                |

"A new pal needs time to settle in; the bigger, the longer." Known steps are a quick montage where
the player still picks the path, and every visit can end on someone new. The first pal ever is all
new, so the first session shows the whole idea: hatch at 0, Chu at 4 min, Dai at 15 min.

| Model (regular player)            | 30 min after every meal (now) | Proposed  |
|-----------------------------------|-------------------------------|-----------|
| first Dai                         | 61 min                        | 15 min    |
| sessions with a new pal, days 2-30| 63%                           | 91%       |
| the 60th pal                      | day 21                        | day 13    |
| all 120 pals                      | day 63                        | day 28    |
| all 120 pals, casual / keen       | day 83 / 61                   | day 65 / 24 |

### The layers (what the collection looks like over time, regular player)
1. Day 1: the tree's first branches with the starting foods (Sho x3, Chu x2, Dai x1 types: 15
   pals reachable). ~6 pals.
2. Days 2-7: food packs open the other branches (first pack day 3); the first TECH mutant on day 2
   from a Battery found in Pal Prix's Kitchen. 30 pals by day 5-6.
3. Week 2: cosmic mutants (Moon Rock from Pal Prix's Sky), the first legends (day ~12, from the
   world-5 finales), drink level 3s and the late worlds' secrets. 60 pals by day 13.
4. Weeks 3-4: the last Dai (the dearest packs) and the last specials. 120 pals by day ~28.

More than 120 pals (planned): the model reads data/evolution_tree.json, so it follows the tree as
it grows. Late in the game a regular player finds ~4 pals a day (about one per visit), so every
30 more pals add roughly a week: ~150 pals = day ~36, ~200 = day ~50. That moves the Pal Pedia
back to being the longest goal, after the stars (keep the targets in pacing.py in step). New pals
should come with their own gate so they don't all land at once: a new food type or size, a new
special food found in a new world, or new legends (e.g. from the BLOOM adults).
Casual: 30 pals day 10, all day 65. Keen: 30 pals day 4, all day 24.

### Food packs (as built)
Start: Sho foods of 3 types (green, sweet, greasy), Chu of 2 (green, sweet), Dai of 1 (green). The
other 9 packs are in the Shop: Sho 10, Chu 15, Dai 20 (145). The Shop shows a size once a pal is
about to need it. Guidance layer 1 (the sparkle on foods that lead to someone new) is what makes
the "known steps are quick" rule readable: follow the sparkles.

### Special foods (the key items)
The full Pedia needs 15 special meals: a tech and a cosmic on a Dai of each family (10 mutants),
and each family's legendary food on its ULTRA Dai (5 legends).
- Found first where they belong (taken once): see the table below.
- Then the Shop restocks it: a special is on sale once you've found it in a game (its place tells
  its story first), or from 350 stars (tech, cosmic) / 450 (legendary) without, so no game is ever
  required. The special shelf holds one of each kind and restocks once a day (a reason to come
  back tomorrow, and the mutants spread over days instead of an afternoon). Prices as now: tech /
  cosmic 15, legendary 40. The pal rule as now (a Dai; its own ULTRA), so nothing is wasted.

| Special food   | Kind      | Found first                                                   |
|----------------|-----------|---------------------------------------------------------------|
| Battery        | tech      | Pal Prix 2-6 (Lagoon: behind crates) · Tilt Maze 5-3 (Factory) |
| Microchip      | tech      | Tilt Maze 4-3 (Sewer) · Paper Sumo 4-9 (beat the tin robot)   |
| Moon Rock      | cosmic    | Pal Prix 3-6 (Sky: in a storm cloud) · Tilt Maze 6-3 (Space)  |
| Alien Goo      | cosmic    | Tilt Maze 6-8 (Space)                                         |
| Kraken Brine   | legendary | Splash Hoops 5-9 (the Storm)                                  |
| Phoenix Pepper | legendary | Pal Prix 5-9 (the Reef's last race)                           |
| Golden Seed    | legendary | Paper Sumo 5-9 (the beetle king)                              |
| Dragon Oil     | legendary | Top Spin 5-9 (the dragon top)                                 |
| Stardust Sugar | legendary | Tummy Tunes 5-9 (the star song)                               |

7 tech / cosmic copies are hidden in the games. A regular meets the first two early (Pal Prix
2-6 and 3-6), buys ~8 from the daily shelf (120 coins) before reaching the late vaults, and wins
every legendary in the finales. A special that can't make a new pal any more (in the pantry or in
a vault) turns into its price in coins, so no prize is ever a dead one.

### Pal states (the answer to "states for the pals?")
- Two visible states, nothing else: HUNGER (the pal's 3 faces: fed / hungry / very hungry, from
  the time since its last meal: 0-2 h, 2-8 h, 8 h+) and BOOSTED (the aura and badge of its drink).
- No health, happiness or discipline bars, no sickness, no death, no going back a stage. A hungry
  face is the whole nudge, plus the notification "your pal is hungry".
- If TestFlight shows players don't come back, the first soft lever: a very hungry pal won't
  drink (no boost until it has eaten). Never anything that takes away a pal or progress.
- No stats that change winning (see 1). Traits (family = a feel, stage = size) may show as looks
  (a big Dai is a big ball) but never move a star.

### Lucky Pinch
After every 4th meal that brought a new pal (1 in 4, never twice in a row; the one surprise left
to luck on purpose). Its 8 exclusives, then coin capsules (+3). A regular gets one a day or so.

## 4. Drinks and boosts (the answer to "why are boosts needed?")
Without drinks the pet and the games are two apps that share a coin counter. Drinks have three jobs:
1. The bridge: every 15 minutes the pal gives you something for the games, so caring for it
   matters for playing (pillar 3).
2. Keys: every game has secrets behind drink gates, and the prizes inside (special foods,
   stickers, cases) are what the rare pals need. You see a gate and its prize long before you can
   open it: a goal you choose.
3. A built-in assist: the Splash second chance and the Focus wider windows let a weaker player
   reach the hard 3-stars without a difficulty menu. Every star stays reachable without any boost.

Rules: one boost at a time (the last drink counts); it stays until it FIRES (never wasted in a game
that has no use for it); the drink clock is 15 min; a type arrives with each game you own (as
now); levels 2 and 3 of a type are bought in the Shop (PROPOSED 10 / 20, now planned 15 / 30) and
make the same effect stronger AND open higher gates.

One meaning per boost, everywhere:
| Boost (type)          | Means                  | Splash Hoops      | Tilt Maze (vaults)  | Pal Prix               | Paper Sumo         | Top Spin            | Tummy Tunes      |
|-----------------------|------------------------|-------------------|---------------------|------------------------|--------------------|---------------------|------------------|
| Splash (watery)       | a second chance        | +10 s once        | a fall forgiven; water channels | a fall forgiven | spring back once   | survive a ring-out  | groove refilled once |
| Fizz (fizzy)          | lift, power            | stronger jets: the golden hoop | hop low fences (built) | a ramp off the road | -          | stronger dash: ring the bell | -       |
| Focus (caffeinated)   | more time to react     | -                 | time the shutters   | a slow-motion beat before a fall | wider beat window | wider perfect guard | wider timing  |
| Sturdy (milky)        | weight                 | -                 | ram cracked walls   | no slip on oil         | heavier: the mystery challenger | heavier top | -        |
| Lucky (fruity)        | finding                | a chest on the sand | open chests       | a gift box off the road| -                  | -                   | the golden note: an encore |
Lucky Pinch: Lucky = a firmer grab.

Secrets: one per world from world 2, on its 6th level (Tilt Maze: its 2 gated vaults per world).
The gate shows the drink type and level it needs: worlds 1-2 = level 1, 3-4 = level 2, 5-6 =
level 3. Prizes: special foods (table above), stickers, accessories, backgrounds, gut decor,
cases (see 5b). 25 secrets + Tilt Maze's 12 = 37.

### 4b. Why drink? The 3-6-9 rhythm (2026-10-30, BUILT; TO REVIEW on the phone)
The problem (the user): one secret per world is too rare for a drink every 15 minutes to matter;
most drinks wait unused. The answer: every world has the same three beats, so there is always a
gate near you that wants the drink you have, and the home shows what the drinks bought.

| Level | What it holds                                             | Needs       | Its prize                       |
|-------|-----------------------------------------------------------|-------------|---------------------------------|
| 3     | a SMALL secret: a pickup on the course (a golden hoop, a gift off the road) | a drink (the world's gate level) | coins (5-10) or a sticker for the case |
| 6     | the world's SECRET (as before)                            | a drink     | a piece for the hokora, a special food, a dress-up |
| 9     | the FINALE (as before)                                    | skill       | a case, a legendary food, a sticker |

- Small secrets are in the games whose secret is a pickup you can ignore: Splash Hoops, RC Prix
  and RC Prix 2177 (6 each, worlds 1-6). Tilt Maze already has 3 vaults a world. Paper Sumo's and
  Top Spin's secrets are part of the match (a mystery challenger, the golden top), so they keep one
  a world: adding them to level 3 would change those matches (to design, if wanted).
- Secrets now: Splash Hoops 11, RC Prix 11, RC Prix 2177 11, Tilt Maze 18 (15 gated), Paper Sumo 5,
  Top Spin 5 = 61 (43 before), 58 of them behind a drink.
- The world-1 small secrets want FIZZY, the 2nd game's drink: in the first minutes a player sees a
  golden hoop in Splash Hoops 1-3 they can't reach yet ("only fizzy jets reach it!"), a reason to buy
  Tilt Maze and to come back with a fizzy drink.
- A taken secret's spot stays empty (as now); the level menu already marks a level's gate.

What a boost means stays one word everywhere (Splash a second chance, Fizz power, Focus time, Sturdy
weight, Lucky finding) and it still stays until it fires. To make choosing a drink a decision you
can SEE (NEXT, not built): the drink menu's cards show how many open gates each drink has ("3
gates"); the Games menu's card shows a little gate badge when your boost opens something in that
game; the level menu lights the levels your boost opens. Each is a few lines on top of
`BaseMinigame.secrets()` and `gate_open()`.

Still to do from section 4's table (each game decides): the boosts with no use yet in a game
(Splash Hoops' Focus and Sturdy, Paper Sumo's Fizz and Lucky, Top Spin's Lucky) get an assist, so a
drink is never useless in any game.

## 5. Coins: in and out
In: each new star = 1 coin (972) · the pal's daily request +2 (a day you play) · Lucky Pinch coin
capsules once its items are won · a spare special food (one that can't make a new pal any more)
turns into its price · the small secrets (5-10 coins, 2026-10-30). A regular earns ~1285 in four
months, most of it in the first month.

| Out            | What                                                     | Coins       |
|----------------|----------------------------------------------------------|-------------|
| Games          | 5 · 30 · 50 · 70 · 100                                   | 255         |
| Food packs     | 2 Sho x 10 · 3 Chu x 15 · 4 Dai x 20 (as built)          | 145         |
| Drink levels   | per type: level 2 = 10, level 3 = 20                     | 100-150     |
| Special foods  | tech / cosmic 15 (several come free) · legendary 40 (if not won) | ~60-260 |
| HOME stall     | (the hokora) 12 plain pieces: lanterns 20, a noren / fairy lights 25, candles 15, stone lanterns / bonsai 30, skies 20, wood colours 40 | 305 |
| Device         | pal stickers (~5 each) and plain cases (~40); themed ones are only won | open |

Prices are unchanged (games, packs, drink levels, specials): the model (`pacing.py`, 2026-10-30)
still passes every check, and the dates of the games, the packs and the Tomopedia don't move. The
HOME stall is a late sink, cheap enough to buy a lantern on a whim: a regular now ends four months
with ~155 coins spare instead of ~330 (casual ~40, keen ~225); the most coins saved in the first
month stays ~100.

What a regular buys, in order (model): Tilt Maze 3 min · Pal Prix 17 min · Paper Sumo 44 min ·
Top Spin day 2 · the first Battery day 3 · the first food pack day 3 · drink levels days 4-10 ·
Tummy Tunes day ~16 · the last packs day ~19 · then stickers and cases. Coins never pile up in the
first month (at most ~100, saving for the last game).

## 5b. The collection in the hokora (2026-10-30, BUILT in code and data; the art to come)
The data lives in `scripts/hokora_catalog.gd` (every piece, its source, its art's file) and
`scripts/collection.gd` (what you own and use); the art list for the designer is
docs/kami_collection_art.md. Before 2026-10-30 this section described the gut's catalogue: that one
is kept as it was (collection.gd's DECOR / BACKGROUNDS / REWARDS) and comes back with HOME: GUT.

### The rule
- What your SPIRIT wears (dress-ups) is only ever won: each one a memory of where it came from.
- Its HOME's themed pieces are won too (a game's festival prizes, a secret's, a Tomopedia
  milestone's, a realm's colour, Lucky Pinch). CHANGED (was: never sold): the Shop's HOME stall
  sells 12 plain pieces (white or indigo lanterns, a noren, fairy lights, candles, stone lanterns, a
  bonsai, three skies, two wood colours), so coins have a use after the last game and a player who
  plays less can still make the hokora theirs. A real shrine has its stall too (the juyosho).
- The DEVICE's extras (stickers, cases) can be won or bought, as before.
- Each game is a festival stall at the shrine (the yokai plan's framing), so its gifts are
  that stall's prizes: goldfish from the water game, glass beads from the marble maze, racing
  pennants and ema for the races, origami and the yokozuna's rope from the paper ring, pinwheels
  and koma from the tops.

### The slots: Home Decor (four) and Backgrounds (two)
| Slot      | Where                                   | Default          | Off = | Art (each new piece)              |
|-----------|-----------------------------------------|------------------|-------|-----------------------------------|
| Lanterns  | the pair under the eaves, swinging with the tilt, a candle glow (stronger at night) | Red Lanterns | the red ones | one lantern (108 x 176), the left one is the same |
| Hanging   | across the front beam, over the front   | nothing          | nothing | a 925 x 925 overlay on the front, 2 frames of a sway |
| Shelf     | a pair on the stone slab, either side of the offering stand, at the ornaments' depth | nothing | nothing | a 925 x 924 overlay on the slab, both pieces in place |
| Colours   | the wood and the roof (the stone base and the moss kept) | Weathered Cedar | cedar | none: a shader recolours by material |
| Sky       | the sky's colour at dawn / day / dusk / night (the real clock moves it, as before) | Shrine Pink | pink | none: 3 colours |
| Clouds    | what drifts across the sky: the cloud layers, or particles over them | Clouds | clouds | layers (as the gut's) or tiny sprites |

In the menu the hokora's Home Decor and Backgrounds lists come in sections, like the Tomopedia's
families: FORWARD = the next slot, tap = the next piece (on through the slot's pages), hold = put it
on; picking the one in use takes it off. A piece with no art yet says "Art soon" and shows nothing
in the hokora (a lantern shows the red one recoloured; colours, skies and particle drifts need no
art). The time of day is never an item: every sky has its own night.

### Every piece and where it comes from (83, plus "Nothing" in Hanging and Shelf; * = needs its art)
Lanterns (12): Red (default) · Goldfish* (Splash Hoops 5 stars) · White*, Indigo* (stall 20) ·
Festival* (Top Spin 3-6) · Jellyfish* (Splash Hoops 6-6) · Moon Rabbit* (Paper Sumo 4-6, the Moon
Base) · Hozuki* (30 spirits) · Fox-fire* (70 spirits) · Daruma* (Lucky Pinch) · Neon* (RC Prix 2177
5 stars) · Gold* (100 spirits). Until drawn: the red lantern recoloured, each with its own glow.

Hanging (15): Wind Chimes (Splash Hoops 15) · Glass Beads (Tilt Maze 15) · Racing Pennants (RC
Prix 15) · Shimenawa (Paper Sumo 15: the yokozuna's rope) · Pinwheels (Top Spin 15) · Shell Chimes
(Splash Hoops 2-6) · Teru-teru Bozu (Splash Hoops 5-6, the Storm) · Glow Spores (Tilt Maze 3-8, the
moss garden) · Cog Garland (Tilt Maze 5-6, the Factory) · Carp Streamers (RC Prix 5-6, the Reef) ·
Thousand Cranes (40 spirits) · LED Strip (RC Prix 2177 15) · Festival Flags (Lucky Pinch) · Noren
Curtain, Fairy Lights (stall 25). All need art.

Shelf (15): Goldfish Bowls (Splash Hoops 60) · Puzzle Boxes (Tilt Maze 60) · Ema Plaques (RC Prix
60: wishes for the race) · Origami Cranes (Paper Sumo 60) · Koma Tops (Top Spin 60) · Kappa Statues
(Tilt Maze 4-6, the kappa's canal) · Sakaki Vases (20 spirits) · Fox Statues (50 spirits) · Komainu
(80 spirits) · Moon-viewing Set (110 spirits) · Maneki-neko (Lucky Pinch) · Neon Lucky Cats (RC Prix
2177 60) · Candles 15, Stone Lanterns 30, Bonsai 30 (stall). All need art.

Colours (10): Weathered Cedar (default) · a realm's colour when 10 of its spirits are found: Moss
(Mountain) · Vermilion (Fox) · Black Lacquer (Fire) · Copper Roof (River) · Moon White (Moon) ·
Sakura Wood (Lucky Pinch) · White-washed, Indigo (stall 40) · Gold Leaf (all 120 spirits: the
endgame hokora). No art: `shaders/hokora_colour.gdshader` moves each material's hue, saturation
and value (the presets in hokora_catalog.gd; the designer may suggest better ones).

Sky (14): Shrine Pink (default) · Lagoon (Splash Hoops 100) · Mint (Tilt Maze 100) · Peach (RC Prix
100) · Teal (Paper Sumo 100) · Summer Blue (Top Spin 100) · Golden Hour (RC Prix 6-6, the Grand
Prix's sunset) · Aurora (RC Prix 2177 4-6, the Ice Fjord) · Neon Dusk (RC Prix 2177 100) · Red Moon
(90 spirits) · Lilac (Lucky Pinch) · Amber, Silver, Sakura (stall 20). No art: day / dusk / night
colours.

Clouds (17): Clouds (default) · Marbles (Tilt Maze 5) · Balloons (RC Prix 5) · Paper Cranes (Paper
Sumo 5) · Spinning Tops (Top Spin 5) · Bubbles (Lucky Pinch) · Starfield (Tilt Maze 6-6): the gut's
layers, shared · the four SEASONS, all from Paper Sumo's places: Cherry Petals (2-6, the spring koi
pond), Maple Leaves (3-6, the autumn stream), Fireflies (5-6, the summer forest, glowing at night),
Snow (6-6, the winter shrine festival); owning all four brings Seasons, which follows the real
calendar (the southern half of the world the other way round) · Sky Goldfish (Splash Hoops 3-6) ·
Sky Lanterns (Splash Hoops 4-6, the Night Lights) · Fireworks (RC Prix 4-6, the Night Race: night
only) · Spirit Wisps (60 spirits) · Cloud Dragon* (Top Spin 6-6, the Dragon Festival). The particles
are drawn by `scripts/sky_drift.gd` until the designer's sprites replace them; the dragon needs its
drawing.

### Where the gifts come from, by source
| Source | What |
|--------|------|
| Each game's gift track (its stars: 5 · 15 · 30 · 60 · 100 · 150) | a drift or the first lanterns · a hanging piece · a dress-up · a shelf pair · a sky · the gold sticker. RC Prix 2177's: neon lanterns, LED strip, neon cats, Neon Dusk (its dress-up and sticker wait for art) |
| A world's secret (6th level) | the hokora's best themed pieces, the four seasons, special foods, dress-ups (section 4b) |
| A world's small secret (3rd level) | coins, a sticker for the case |
| Finales (9th, first clear) | cases, legendary foods; Paper Sumo also gives the wind-up key (1-9), the koi (2-9), the topknot (3-9) and the kabuto (5-8), Top Spin the dragon sticker (6-8) |
| The Tomopedia | every 10 spirits a grand piece (20 Sakaki Vases ... 120 Gold Leaf); 10 spirits of a realm: its colour |
| Lucky Pinch | 8 exclusives: Scarf, Headphones, Bubbles, Lilac, Daruma Lanterns, Festival Flags, Maneki-neko, Sakura Wood |
| The Shop | the HOME stall (12 plain pieces), pal stickers, plain cases |

A piece that replaced a gut piece as a prize brings the gut's twin with it (hokora_catalog.gd
GUT_TWIN), and both reward lists are given whichever home you play in, so the gut stays complete.

### Dress-ups, cases, stickers (unchanged in code; planned additions wait for their art)
- Dress-ups (14 now, all kept: the games' hats are their stalls' prizes). Planned for the spirits,
  once the spirit designs are final (every dress-up is fitted to every spirit by script): a
  kitsune mask worn on the side, a paper charm (ofuda) on the forehead, a straw hat (sugegasa), a
  flower hairpin (kanzashi), a bell collar (suzu), oni horns, a cyber visor (RC Prix 2177 30
  stars), a taiko headband (Tomo Tunes). Sources in docs/kami_collection_art.md.
- Cases (11 now). Planned: Torii (vermilion lacquer, 250 stars in all), Matsuri (indigo with
  lanterns, 500 stars), Gold Leaf (every star), Turbo (RC Prix 2177 6-9, replacing its 60 coins),
  Washi and Seigaiha prints (the Shop, 40), Taiko (Tomo Tunes 6-9), and the realistic Classic skin
  (the user's idea: the smooth console back + front buttons).
- Stickers (18 themed + 30 pal stickers). Planned: a SHRINE page in the sticker book (a 7th tab):
  omamori, ema, daruma, maneki-neko, torii, kitsune mask, furin, ramune, konpeito, taiyaki,
  koinobori, hanabi, for the small secrets once they exist (they give coins and pal stickers until
  then), plus RC Prix 2177's gold rocket.

### Shop sections and when they open
FOOD & DRINKS from the start · HOME once the first home piece is yours (Splash Hoops' 5 stars: the
goldfish lanterns, ~minute 3) · STICKERS once the first sticker is won · CASES once the first case
arrives (the gift). In the gut the HOME section doesn't exist.

## 5c. Rankings (later, if the game takes off)
Points are gone, but rankings are still possible and fairer without them: per-level BEST TIMES
(Tilt Maze, Pal Prix, Splash Hoops by time left: the same board for everyone; ghosts fit here),
accuracy per song (Tummy Tunes), the fastest win per match (Paper Sumo, Top Spin), total stars, the
Pal Pedia count, a weekly challenge level. So from now on every level saves its best result
(time / accuracy / win time) next to its stars. A score-attack "arcade run" per game can come
later too.

The LCD (DECIDED 2026-10-16): its number is the COINS (a coin glyph + 4 digits, where the score
was). Back from a game the new coins tick up one by one with a soft blip; buying ticks it down.

## 6. The calendar (what a player gets when; 6 worlds per game)
Players (ASSUMED): casual = 20 min on day 1, then two short sessions a day (8-11 min); regular = 60
min on day 1, then 30 min a day in week 1 and 20 after; keen = 180, then 60 and 40. Plus a couple
of quick visits a day just to feed. Hours pass between sessions.

| Milestone               | casual        | regular       | keen          |
|-------------------------|---------------|---------------|---------------|
| Tilt Maze               | 3 min         | 3 min         | 3 min         |
| first Chu / first Dai   | 4 / 15 min    | 4 / 15 min    | 4 / 15 min    |
| first secret            | 16 min        | 16 min        | 16 min        |
| Pal Prix (3rd)          | 17 min        | 17 min        | 17 min        |
| Paper Sumo (4th)        | day 3         | day 1         | day 1         |
| Top Spin (5th)          | day 29        | day 2         | day 1         |
| Tummy Tunes (6th)       | day 66        | day 16        | day 2         |
| first mutant            | day 3         | day 2         | day 1         |
| first legend            | day 47        | day 12        | day 5         |
| 30 / 60 / 90 pals       | day 10 / 23 / 34 | day 6 / 13 / 21 | day 4 / 9 / 16 |
| all 120 pals            | day 58        | day 28        | day 24        |
| half the stars          | day 67        | day 16        | day 5         |
| 90% of the stars        | -             | day 58        | day 24        |

Order of the long goals (a check in the model): every game bought, then the Pal Pedia complete,
then the last stars. With more than 120 pals the Pal Pedia gets longer (about a week per 30 pals
for a regular player), so it moves next to the stars as the longest goal.

Known weak spot: a casual player stays on 4 games for about a month (Top Spin day 29, Tummy Tunes
day 66). They're never short of levels, but if testers are mostly casual, lower the last two
prices or add a "welcome back" coin gift.

### The first hour (regular player, from the model)
0 hatch the first Sho · 3 first gift (Splash Hoops, 5 stars), buy Tilt Maze (+ Fizzy drinks) ·
4 the first Chu · 6, 10 Tilt Maze's first gifts · 15 the first Dai; the first drink · 16 the first
secret (a fizzy fence) · 17 buy Pal Prix (+ Caffeinated) · 20-36 Pal Prix's gifts, its world 2 ·
42 Tilt Maze world 2 · 44 buy Paper Sumo (+ Milky) · 46 flush, the second Sho; Lucky Pinch ·
50 its Chu · 60 its Dai. 24 new things in the first hour, never more than 5 min apart.

### The hokora over time (regular player, from the model's dates; 2026-10-30)
- Minute 0-1: an empty hokora with a wisp wandering in its room (the waiting sign); the first
  offering, the first spirit. A golden hoop in Splash Hoops 1-3 that only a fizzy pal reaches.
- Minute ~3: the first piece, big and on the main screen: Goldfish Lanterns (Splash Hoops' 5
  stars). The HOME stall opens. Tilt Maze's 5 stars: Marbles drift in the sky.
- Minutes 6-20: Wind Chimes, Glass Beads (the 15-star gifts), RC Prix's Balloons; the first drink
  (~15 min) opens the first small secret (coins) or Tilt Maze's fence.
- Hour 1-2: the 30-star dress-ups; Paper Sumo's Paper Cranes and its Shimenawa.
- Days 2-3: the 60-star shelf pairs (Goldfish Bowls, Puzzle Boxes, Ema), the Sakaki Vases (20
  spirits), the first realm colour (Moss: 10 Mountain spirits, the starting foods' realm), the
  world-2 secrets (Shell Chimes, Cherry Petals).
- Week 1: the 100-star skies, Hozuki Lanterns (30 spirits), the other realm colours as the food
  packs open the realms, the first seasons.
- Weeks 2-4: the late secrets (Jellyfish Lanterns, Fireworks, Teru-teru Bozu, Snow, the Cloud
  Dragon), Fox Statues, Spirit Wisps, Fox-fire Lanterns, Komainu, Red Moon; the 150-star gold
  stickers; at 120 spirits the Gold Leaf hokora. Coins left over go to the stall.

### A session (a 10-15 min visit, after the first week)
Open: the pal is hungry (the face, the notification) -> feed: pick the path through the known
pals to a sparkle -> a NEW pal (30 min to the next meal) -> drink: the type of a gate you've seen
-> play 4-8 levels (stars -> coins) -> open that secret -> buy what's now affordable (a pack, the
day's special, a drink level) -> leave with a hook: the next meal's countdown, a gate that needs a
level 3, the next game's price.

## 7. Building it (the `complete-games` branch, 2026-10-16: ALL BUILT, for the user to review)
The user asked for the first five games as complete as possible, then to decide what stays:
1. The systems: the meal clock by what the meal did · the LCD's coins (points off the HUDs) ·
   prices · special foods found first + the daily shelf + spares to coins · drink levels and the
   other boosts (Focus, Sturdy, Lucky) · the Shop's sections (food & drinks, stickers, cases) ·
   every level's best result saved.
2. The games, each to 6 worlds x 9 levels with its new things, looks, secrets, star rules and
   finale prizes: Tilt Maze (things that block the route, the other vault kinds), Splash Hoops
   (world 6, prettier scenes in the spirit of Pal Prix's Garden), Pal Prix (worlds 3-6, weather:
   rain spray off the wheels), Paper Sumo (levels and worlds, paper-toy rivals), Top Spin (levels
   and worlds, a background).
3. The catalogue: every gift-track item, the secrets' prizes, pal stickers, cases (new designs
   after the Melon Soda rules). BUILT: 18 themed stickers (the secrets' and the gift tracks' gold
   ones; a games page in the sticker book), 9 new dress-ups fitted to every pal (tools/art/hats.py),
   9 gut add-ons + 4 gut colours, 6 sky scenes + 4 sky colours, 9 new cases (5 games' + 4 sold in
   the Shop for 40: tools/art/cases_games.py) and a CASES page in the gear menu; every game's gift
   track (5 / 15 / 30 / 60 / 100 / 150 stars; Tummy Tunes' later). Still to make: the Pal Pedia's
   milestones past 10 pals, Lucky Pinch's own exclusives.
   After the user's review (2026-10-17/18): Pal Prix in two worlds per toy (car, boat, plane);
   lives in Tilt Maze and Pal Prix; Tilt Maze's enemies hurt instead of blocking; the cases from
   simple to fancy (Taro first, early; a print each: tools/art/case_prints.py) with the menu
   buttons' frames in the case's colours; the food menu's specials page only once a special food
   has been yours; the crowd of every kind of pal.
4. The dev launcher: BOOT + PROGRESSION starts from zero with everything in it; STRAIGHT TO GAMES
   becomes ALL UNLOCKED (a random pal, every game, level, item, sticker and case, the whole Shop).
Then measure on the phone and replace the model's ASSUMED numbers.

### 7b. The hokora's progression (branch `yokai-migration`, 2026-10-30: BUILT, the art to come)
1. The dev launcher's HOME switch (HOKORA / FIRST HOKORA / GUT) for FULL BOOT, ALL UNLOCKED and
   BOOT + PROGRESSION; the hokora is the default and the only home in release builds. ALL UNLOCKED
   in a shrine: Picklet on the pet screen (the old SHRINE start, now gone); in the gut: a random pal
   and the Games menu, as before. QA: `tools/qa/shoot.sh ... home=gut|first|hokora` (default hokora).
2. The catalogue (`scripts/hokora_catalog.gd`): the 83 pieces, their sources, the gut twins; the
   Collection home-aware (each home its decor and backgrounds, both reward lists given, realm
   milestones, Seasons).
3. The hokora wears them (`scripts/shrine.gd` _apply_decor): lanterns (art or a recolour, their
   glow), the beam's hanging overlay, the shelf overlay at the ornaments' depth, the wood and roof
   colour (`shaders/hokora_colour.gdshader`, the stone base kept), the sky sets on the real clock
   (darker night skies darken their clouds), the drifting particles (`scripts/sky_drift.gd`, two
   layers in the 3D tilt like the rain).
4. The menus: Home Decor and Backgrounds in sections (slots) with two rows of dots, "Art soon"
   cards, previews for pieces not drawn yet; the Shop's HOME stall.
5. The games' prizes: the 3-6-9 rhythm (section 4b), every secret's hokora prize (5b).
6. Fixes found on the way: the collection cards' pictures sat half a square up and left of their
   frames (the food icons are now placed by their corner), the two-line button legend was too
   tight; the boot's black screen now covers the hokora's lanterns, bell and rain, which light up
   with it; the waiting sign before the first offering is the wandering wisp in every shrine start
   (the EAT sign only in the gut).
NEXT: the designer's art (docs/kami_collection_art.md, P1 first); the drink-gate hints (4b);
the missing boost assists; measure on the phone; the planned dress-ups, cases and stickers.

## 8. Decisions
DECIDED (user, 2026-10-16): the order (Pal Prix 3rd, Paper Sumo 4th) · 6 worlds per game, world 6
the masters' world · the toy instrument per world for Tummy Tunes · Paper Sumo's rivals are paper
toys, not pals · no points, the LCD shows coins · rankings later from per-level bests.
Taken as the direction (the user: "bearing all this in mind"), to check on the phone: the meal
clock (new pal 3 / 10 / 30 min, known pal straight away) · no lives (the Splash drink is the one
extra life) · no pal stats or punishments (hunger and boost the only states) · prices 5 / 30 /
50 / 70 / 100 and drink levels 10 / 20 · special foods found first, then the daily shelf (or
350 / 450 stars) · the 9-level world shape · the collectables rule (5b).
DECIDED (user, 2026-10-17/18): Pal Prix 2 car + 2 boat + 2 plane worlds (the car's progression in
its two; 2026-10-18: ordered car, boat, plane, then the second of each) · lives in Tilt Maze and Pal Prix (3, +1 for a splashy pal; out = the level again) · guard
rails to try · the crowd: pals of every kind, screaming at a crash · the first case early and
simple, then fancier ones · the specials page once a special food is yours.
OPEN: Pal Prix 2177's worlds (built with the two lists combined: each step of the build-up in one
of the places; the user to confirm) · Tummy Tunes' 6th world (Toy Trumpet or The Tummy) · Pal Prix's places (see the roadmap: more
places per toy, boats and planes in every world, a toy that changes mid-race).
TO REVIEW (built 2026-10-30 for the hokora, the user to confirm or change on the phone):
- The four Home Decor slots (Lanterns, Hanging, Shelf, Colours) and the two sky slots (Sky,
  Clouds); the bell rope stays the hokora's own (it rings for Lucky Pinch).
- Each game a festival stall: its gift track = drift, hanging, dress-up, shelf, sky, gold sticker.
- The Tomopedia pays the grand pieces (every 10 spirits) and a realm's colour at 10 of its spirits;
  Gold Leaf at 120.
- CHANGED: the Shop's HOME stall sells 12 plain pieces (it was "what the pal lives in is never
  sold"); dress-ups stay never sold.
- The 3-6-9 rhythm: small secrets on every world's 3rd level in Splash Hoops, RC Prix and RC Prix
  2177 (coins, stickers); Paper Sumo's four secrets are the four seasons; Paper Sumo's and Top
  Spin's stickers moved to first-clear prizes.
- The hokora colour presets and the sky sets' colours (tune by eye on the phone).
- Prices unchanged; the model still passes (section 5).
