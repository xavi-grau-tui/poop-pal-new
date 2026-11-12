# The games pass: stars, powers and difficulty, one contract for six games (12 November 2026)

PROPOSED. What "the 3rd star needs the power" means in numbers, game by game, and how each
level's marks are set. It follows `docs/loop_v2.md` with decisions A-H made (two drink tiers, one
drink per game). Tomo Tunes has its own plan: `docs/tomo_tunes.md`.

## 1. The contract: every level of every game

| Star | Means | Needs a drink | Tuned so that a regular player... |
|---|---|---|---|
| 1 | cleared | never | clears a world-1 level nearly every try, a world-6 finale about 1 try in 2 |
| 2 | cleared well: a margin on the game's own measure | never | gets it on the first clear in the early worlds, in a replay or two later on |
| 3 | gold: further on the same measure | made for the power | with the power on: 2-3 tries. Without: about 1 try in 8. Never impossible |

1. **One measure per game.** The 2nd and the 3rd star are two marks on the same scale (time left,
   par, spin left, notes hit), and the power pushes that same scale. Nothing else to learn.
2. **A power has one strength.** The better drink lasts longer (10 minutes of play against 5) and
   reaches the routes of worlds 4-6. It is never stronger, so each level is tuned once.
3. **The 1st and 2nd stars are tuned with no power on.** The 3rd is set from runs with it.
4. **The level makes the difficulty**, the power never replaces skill: it widens a margin. The
   climb is the skeleton's saw-tooth (`docs/progression.md`, section 4): each world starts easier
   than the last one ended while its new thing is learnt, then goes past it; the 9th is a step up.
5. **The clock is fair.** A power counts its minutes only inside levels of its own game, and a
   level started with the power on finishes with it, even if the minutes run out halfway.
6. **A drink does nothing in another game.** Today's cross-game assists go (a second chance from
   Splash everywhere, Focus and Sturdy in three games each).

## 2. Game by game

The power's numbers are first values to tune with the loop in section 3.

| Game | The measure: 2nd / 3rd star | Drink, power | What the power changes | Its routes (level 3 · level 6) | In the code today |
|---|---|---|---|---|---|
| Splash Hoops | time left: 20% / 45% | Watery, TIDE | the jets throw 20% harder, the balls sink 25% slower | the high golden hoop · the chest on the sand | the two marks built; no drink does anything here |
| Tilt Maze | within par / no fall | Fizzy, HOP | the ball hops low fences and one-cell pits | the vaults | the fizzy vaults built; the watery, milky and caffeinated vaults to turn into HOP routes |
| Pal Prix and 2177 | within par / the gold par (today: no crash) | Spicy, HEAT | boost pads burn twice as long, a nitro on every straight | the ramp into the tunnel · the route through the clouds | Focus's slow motion, Sturdy, Splash's forgiven fall and three drinks' gates, all to replace |
| Paper Sumo | win 2-0 / 2-0 within par time | Milky, STURDY | a quarter heavier: harder to push, pushes further | the mystery challenger | Sturdy built; Focus and Splash to remove |
| Top Spin | spin left: 40% / 70% | Fruity, ZEST | the spin wears a fifth slower, the dash hits a fifth harder | the bell · the golden top | Fizz, Focus and Sturdy read today, to replace by ZEST |
| Tomo Tunes | notes hit: 85% / 95% | Caffeinated, FOCUS | the timing windows a third wider, a stray press is free | the golden note · the encore | nothing yet (a prototype with one song) |

**One change to decide inside this table: Pal Prix's 3rd star.** Today it is "no crash". With HEAT
as a speed power the gold mark has to be a time (the gold par), or the power would not help it.
"No crash" can stay as the 2nd star's twin (within par OR clean) if you'd miss it.

## 3. How a level's marks are set

The same loop for every level, run by the game's own autopilot with human error added (Tilt
Maze, Pal Prix, 2177, Paper Sumo and Top Spin have one for QA; Splash Hoops needs one; Tomo
Tunes uses a timing-error model on the chart):

1. 20 runs with no power. The 2nd star's mark = what 12 of the 20 reach.
2. 20 runs with the power. The 3rd star's mark = what 8 of the 20 reach (2-3 tries).
3. Count the no-power runs that reach the 3rd mark. Wanted: 3 or fewer (about 1 in 8).
   - More than 3: the power is too weak in this game. Raise its one number and redo the game.
   - None, in the early worlds: it is too strong, the star is locked behind the drink. Lower it.
4. The marks go into the level table; `pacing.py` gets the measured rates in place of its guesses.

Then the phone decides: TestFlight logs tries and stars per level, with and without a power.

## 4. What the player sees, without a word

- **The 3rd star wears the drink.** On the level menu and on the HUD, a 3rd star not yet won
  carries its game's small drink icon. That is the whole explanation of "drink this to get it".
- **The power is on the HUD**: the drink's icon in the race band, draining; it flashes when the
  last level on it begins.
- **The drink menu says where each drink works**: the game's icon beside the drink, and how many
  3rd stars and routes are within reach right now.
- **A route is seen before it can be taken**: the golden hoop out of reach, the fence across the
  vault's door. The prize is shown behind it.

## 5. The order

0. **The shared work** (once, before any game): the power in `pet_state.gd` (its game, minutes
   left, tier), the drink menu, the HUD icon, the star's drink icon, `gate_open()` by the game's
   own drink, two tiers in the Shop with the rule from the review (the first better drink is met
   at the first world-4 gate, the others once every game is owned), the model kept in step.
1. **Splash Hoops first.** It is the free game and the first drink (minute 15) is its own, so the
   first power and the first route (the golden hoop on 1-3) happen in the first session. It is the
   pilot: your verdict on the phone before the rule goes to the others.
2. Tilt Maze, Pal Prix with 2177, Paper Sumo, Top Spin: each its look, its power, its marks, its
   routes, and the other drinks' assists removed (58 gated secrets move to the game's own drink).
3. Tomo Tunes last, on its own plan; its pilot song can start now, since songs are the long pole.
