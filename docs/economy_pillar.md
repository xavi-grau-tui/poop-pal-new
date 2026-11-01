# PILLAR: the economy and the progression loop

**The user, 2026-10-31: this is a pillar of the game. It balances a whole part of it, so it has to
be thought through very carefully before anything is built.** Nothing here is built yet. Decide it
as ONE system, with the user, check it in the model (`tools/design/pacing.py`), and only then change
the code. The current numbers and rules are in `docs/progression.md` (sections 3-6 and 8), the
notes this page gathers are in its "OPEN QUESTIONS".

## The loop in one picture

```
 play a game ──► stars ──► coins ──► buy (the catalogue: foods, drink levels, games, stickers,
     ▲             │                      cases, the HOME stall, homes / sets if sold)
     │             │
     │             └──► the 3rd star needs the game's DRINK (its power)
     │                         │
 drinks (rationed by time) ◄───┘ the same power opens the level's secrets / special items
     │
 meals (the meal clock) ──► new pals ──► the Tomopedia ──► its prizes (homes, grand pieces)
     │
 a grown spirit's send-off ──► a reason to start over (keeps the collection)
```

Every part feeds another, and every part has a clock. If one is off, the rest feels off: too many
coins makes the Shop meaningless, a drink that's always there makes the third stars trivial,
pals too slow make the player quit before the late game.

## The decisions so far (the user's direction, 2026-10-31)

1. **Each game has a power, and the drinks are those powers.** One drink type per game; the two
   RC Prix share one (or RC Prix 2177 gets its own, not speed). 7 games = 6 powers = 5 drinks
   today + **one new drink type** (two if 2177 gets its own).
2. **The power makes the third star reachable.** Without the game's drink the 3rd star is VERY
   hard (still possible for the best); with it, reachable. Every level's star targets are tuned
   both with and without the power.
3. **The same power opens the secrets and special items, built into the level.** Not a locked
   box: a route only the power reaches (in the races, a ramp into a tunnel, a path through the
   clouds, a more complex circuit). Each game finds its own natural version.
4. **All the stars pay for the whole catalogue.** The total price of everything sold ≈ the coins
   from all the stars (1 a star, 972 now) plus the small sources (requests, secrets, Lucky Pinch),
   with a small margin. Every new priced item must fit that budget or come with more stars.
5. **Boosts last a while, not one shot** (about 5 minutes, to set), rationed by the drink
   countdown (15 min today). Nobody clears every game's third stars in one sitting: a little
   waiting, a reason to come back.

## Still to think through

- **Where the items come from:** the coolest pieces in the Shop (a reason to save) and the
  standard ones won in the games (a reason to play), or the best ones only earned, never bought?
  Today the games and the Tomopedia give most of it; the Shop's HOME stall sells 12 plain pieces.
- **The homes and their sets** (`docs/kami_future_hokoras.md`, `docs/kami_ornaments_brief.md`):
  the biggest prizes; their sources decided together with the above.
- **The shrine blessing (PROPOSED, the user, 2026-11-01):** a home worn with its whole set brings
  its special food: a gift once (only if it can still make a new pal: no coins) and, while worn,
  that food always on the daily special shelf. A second road for the specials, never the first: a
  catch-up for casual players (legends on days 48-64 in the model). The details, the home-to-food
  table and the model's check: `docs/progression.md`, "The shrine blessing".
- **The pals' pace:** the wait after a new pal (3 / 10 / 30 min by size) against how many meals a
  branch needs, so the last pals don't drag (all 120: day ~28 regular, ~60 casual today).
- **A reason to start over** once a spirit is grown: not a wipe (the collection, coins and homes
  stay). Ideas: the send-off leaves an heirloom (a trait, a colour, a family's bonus) for the next
  baby; branches that only open on a second run; a generation count in the Tomopedia.
- **The drink levels:** what levels 2-3 add when boosts are timed (longer or stronger).
- **The new drink type:** its power, its art (3 levels), its place in the drink menu.
- **The difficulty curve:** later worlds harder and better paid; the third star's gap with and
  without the power the same feel in every game.

## How it gets checked (before building)

The model (`tools/design/pacing.py`) simulates a casual, a regular and a keen player day by day
with the real prices and rules. Add to it, before changing the game:
- all stars => every sold item affordable, spare under N coins
- spending per stage (first hour, first week, first month) against the stars earned by then
- timed boosts and the drink countdown: days to 100% of the stars mustn't jump
- third stars with and without the power (from FAST autopilot runs of each game)
- the pals' pace with the tuned waits
Then the user plays it on the phone. A rule that only works on paper isn't done.
