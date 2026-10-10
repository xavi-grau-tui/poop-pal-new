# HaraTomo (Poop Pal): roadmap and design notes

Living document (started 2026-10-01, last big update 2026-10-07). It holds the aim, the decisions
made, and what's still missing, so any new conversation can pick the work up from here.
When asked "what could we implement next?", answer from **What to implement next** below.

## The aim, in one paragraph
A virtual-pet handheld in a phone: you feed a cute poop pal and it evolves along food-driven paths
into 120+ different pals (collect them all in the Pal Pedia). Drinks give one-shot boosts for the
minigames. The minigames are digital versions of real physical toys living inside the handheld
(a wooden labyrinth, spinning tops, paper sumo, a water toy, a claw machine...), each deep enough to
come back to, and each feeding the rest (rewards, foods, drinks, secrets). Everything must feel
light, playful and visually intuitive: icons over text, learn by doing. Asia first (Japan above all).

## Where things stand (2026-10-07)
- Built and playable: the pet (feeding, drinks, evolution tree of 120 pals, Pal Pedia, flush),
  collection (backgrounds, accessories, gut decor), Lucky Pinch (bonus claw machine), the
  first-launch box unboxing, and the minigames: Pipe Dream, Tilt Maze, Splash Hoops, Pal Dash,
  Tile Break, Germ Zap, Tummy Tunes, Flipper Belly, plus the prototypes Top Spin (9th card) and
  Paper Sumo (10th card).
- Top Spin and Paper Sumo have first-time tutorials and control legends (shared helpers in
  scripts/base_minigame.gd: show_coach / hide_coach, make_button_hint, device_button_at for
  multi-touch). Prototypes were on branch `top-spin` (check git for whether it's merged).
- Testing switches are still ON (everything resets each launch, games unlocked): see the
  project-state memory / GameData, PetState, Collection, LuckyPinch, Unboxing constants.
- Only Splash is a working drink boost; the other 4 drink types have no effect yet.
- Dev launcher (debug builds only: the editor and the debug installs on the phone): picks FULL BOOT
  or STRAIGHT TO GAMES (Picklet as the pal, Games menu open). scripts/dev_launch.gd, started via
  `run/main_scene.debug` in project.godot; release builds start the real main scene and never see it.

## What to implement next (pick a few to offer)
Sizes: S = a session, M = a few sessions, L = a big block. "Needs" = do that first.

Quick wins (S)
1. Evolution guidance, layer 1: a sparkle / "?" badge on foods that lead to an undiscovered pal,
   the pal's tiny face on foods that lead to a known one (uses PetState.evolution_for).
2. Hide the 4 cut games' cards (Germ Zap, Pal Dash, Tile Break, Flipper Belly); keep their code.
3. Top Spin feel pass: screen shake + a short freeze on big hits, bigger sparks, a hum that drops
   in pitch as the top slows, wooden clacks, the ripcord sound.
4. Paper Sumo: the rival flashes while it's mid-hop (when FORWARD = SHAKE works best).
5. Tune both prototypes from phone feedback (tilt directions, damage, bout / match length).

Medium (M)
6. Tilt Maze: level select + saving the levels reached, then the first Splash vaults (2-3 levels).
7. Pal traits from data (family = trait, stage = size), used by Tilt Maze, Top Spin, Paper Sumo.
8. The other drink boosts (Fizz, Focus, Sturdy, Lucky) in the games, per the boost table.
9. Evolution guidance, layer 2: craving bubbles from the pal.
10. Top Spin restyle: painted wooden koma in a turned wooden bowl.
11. Boost tiers: 3 drinks per type, tier icons (1-3 droplets etc.), 5 new drink icons.

Big (L)
12. Real saving + turning the testing switches off. Needs: nothing; it's the foundation for
    progress, care, tracking and unlocks.
13. Care consequences (grumpy → sick → back one stage) + daily streaks + notifications.
    Needs: 12.
14. One progression shape for every game: worlds, 3 stars per level, saved progress, unlocks by
    total stars. Needs: 12.
15. Foods that grow up with the pal + the reroll item + the luck safety net.
16. Evolution guidance, layer 3: track a pal from the Pal Pedia. Needs: 1.
17. Tummy Tunes as a toy xylophone; Pipe Dream reworked as a circuit race.
18. Pal art pass (own silhouettes and personalities per stage and branch).
19. The instruction booklet (see its outline below), opened from the back sticker. Needs: the
    mechanics it explains to be final, so it comes late; the device and feeding chapters could
    start earlier.
20. More toy moments on the device: stains to rub clean (S-M), stickers earned and stuck on the
    back (M), swappable cases (M-L, needs case art). See "More toy moments".

## Bottom buttons layout (ON TRIAL 2026-10-10: scripts/console_layout.gd, NEW_BUTTONS)
- New: orange MAIN on the left (where the sound button was) · sound in the middle with one 7 x 3
  speaker grill under it · forward on the right as a square like the orange button (its cream and
  >> sign). Every button keeps its logic. Mock-ups: docs/mockups/.
- The first layout stays in the scene: NEW_BUTTONS = false brings it back; then re-run
  tools/design/box_art.py so the box's device picture matches (it reads the switch). The new art:
  tools/design/console_buttons_new.py. Tummy Tunes' lanes follow the buttons left to right.
- To weigh: classic handhelds put the main action button on the right.

## What makes HaraTomo unique (the pillars; check new ideas against them)
1. A physical toy in your phone (THE main hook): a handheld you unbox (seal, lid, films to peel,
   the battery strip), switch on, hold, flip over. Much of the dopamine comes purely from these
   tactile toy moments; keep adding them (button clicks, the back sticker, the booklet...).
2. A creature growing in your guts: what you eat shapes who it becomes (120 pals to collect).
3. Handcrafted toy minigames (real toys, done faithfully) with drink boosts that change how you play.
4. Collectables: pals, gut decor, backgrounds, accessories.
5. Calm, uncluttered pixel art: charming, never noisy.
Lead the trailer and the store screenshots with the device experience (pillar 1).

More toy moments (ideas, 2026-10-08; the user loves them, some were already on their mind)
- Stickers: earned in the game (a new collectable), stuck on the device's back (and maybe the
  front frame) by dragging them on. Placed where you like, peelable.
- Stains (not scratches): the device gets grubby with use (a smudge, a food splat, a sticky
  fingerprint) and you clean it by rubbing it with your finger, with a squeaky-clean feel.
  Could tie into care.
- Cases: shells that change the device's look, snapped on, taken off or swapped (a collectable
  and a cosmetic, like the backgrounds for the pal).
- Batteries running low after a while: open the small cover on the back and swap them.
- Settings as physical controls: a volume wheel / contrast dial on the side instead of menus.
- No screen protector (too much): the only film is the one peeled off when unboxing.

## Market
- Competitor check (quick search, 2026-10-08): every piece exists somewhere, the combination doesn't.
  - Pet inside a device on screen: Tamagotchi L.i.f.e. (Bandai's app; a classic mode shows the egg
    casing), Noa Noa!, Hatchi, My Mochi 97 (retro handheld style). None has an unboxing or treats
    the device as an object.
  - Food-driven evolution: Gourmet Creature Hungry Mogumon (what you feed decides how it evolves).
    Closest idea, but no gut, no device, no toy games: different enough.
  - Poop games in Japan: only small novelty games (うんちがいさがし, a poop chicken race).
  - Paper sumo apps exist (とんとんバトラーズ, 相撲巻 SumoRoll): different enough; ours is the pal
    folded as the wrestler, inside the device, tied to boosts and the collection.
  - First impressions will compare it with Tamagotchi (Bandai owns the genre's name): the device
    experience and the gut-evolution idea are what set it apart.
- Aim at Asia first (Japan above all, then Korea, China/Taiwan): poop-as-cute is mainstream there
  (the 💩 emoji, Unko Sensei, Dr. Slump's "unchi"). Plan for localization early: Japanese, Korean,
  Chinese. The 便友 already on the console fits.
- Know who it's for: kids, casual players, fans of quirky cute. Some people will bounce off the theme, and that's fine.

## The pals (the heart of it)
- The pals ARE the product: craft them with a lot of care.
- Collection size (2026-10-07): every food path gives a pal, but NOT every combination needs its
  own: 5 types x 5 x 5 x 3 specials would be 500+ pals (too many to draw well, and a collection
  that feels impossible stops people trying). Keep it around 120-150 (now: 5 babies, 25 kids,
  75 adults, 10 mutants, 5 legends = 120), with specials as branches. A collection people WANT to
  complete must look finishable: progress counter, silhouettes, hints.
- Pal traits for the minigames come from data, not by hand: family sets the trait (e.g. greasy =
  heavy, sweet = bouncy, spicy = fast, sour = light and twitchy, green = steady), stage sets size.
  "Which pal is best at which game?" ties evolution to gameplay.
- Today many generated pals read as "the previous one, but bigger or with a hat". Each stage and branch
  needs its own silhouette and personality (different body types, not just toppings).
- DECIDED (2026-10-08): the current 120 pals are placeholders; fewer than 5 (maybe none) survive.
  The foods' and drinks' art gets redone too. Art comes LAST: first the technical side (saving,
  gameplay, evolution logic, minigames, unlock progression), well tied together; then the design
  pass, "the fun part". Better 30-40 great pals at launch, the rest in updates, than 120 samey ones.
- More expressions and moods (._. sad, angry, evil… started), small animations per pal.

## Onboarding: teach each thing when it becomes relevant (2026-10-09)
- One short card at a time (one or two sentences), button PICTURES instead of words, shown once,
  explained at the moment it matters. "Do this next" signal everywhere: the button blinks
  bip-bip … bip-bip with a short, sharp buzz in sync.
- DONE (scripts/onboarding.gd, only while no pal has ever existed): after the boot, "Welcome to
  HaraTomo! Tap [food button] to eat something and meet your new pal." (the food button and the
  EAT sign blink with the buzz; only the food button works); after the hatch, "Say hi to <name>!
  What you eat decides how it grows."
- Boot (2026-10-09): no welcome text any more. After the Kobaya Tech logo the screen comes on
  slowly: the pet screen fades in from black, the gut lights up from dim, the calmest song
  ("Sweet Dreams, Pet", measured: slowest, fewest notes per second) fades in; then the LCD, then
  (after a breath) the welcome card. The boot can't be skipped.
- DONE (2026-10-09): the first bonus. The claw waits for the guide cards (and a breath); after
  its visit: "Lucky you! Sometimes a bonus turns up after a meal." then "Tap [games button] to
  play the bonus game!" with the games button doing the bip-bip (the bonus already locks the rest).
  Later bonuses come without cards. LCD unlock messages (ITEM / PAL UNLOCKED!) blink in step with
  the gear button (6 quick blinks), then stay lit.
  To decide: make the FIRST meal ever always bring the bonus (today only the testing switch
  LuckyPinch.TEST_FIRST_MEAL does; the real chance is 20%), so every player meets it while the
  guide is there; otherwise the first-bonus cards need a saved "seen" flag for whenever it comes.
- Next steps (to build with the progression framework):
  3. Right after the hatch card, the games button blinks: "Tap [games button] to play games and
     earn ★ stars. Stars unlock new things!"
  4. First time in a game: its how-to card / tutorial (exists).
  5. First star → the first sticker: "Your first sticker! Flip your HaraTomo over to stick it on."
     (also teaches the device flip).
  Cards never interrupt: if the moment comes during a minigame or with a menu open, the card WAITS
  (queued) and shows the next time the player is back on the main pet screen.
  - First drink (user, 2026-10-09): when the drink countdown first runs out, back on the pet
    screen: "Drink time! Your pal is thirsty" + a short line on boosts ("A drink gives your pal a
    boost [boost icon] for the next game it fits"); the drink button blinks with the buzz.
  6. Each new thing explained only when it opens: the first drink ("Drinks give your pal a boost in
     the next game"), the shop at its unlock ("The shop is open! Trade your [token] for treats and
     stickers", with tokens already earned), each new game, each new food type.

## Progression framework (PROPOSED 2026-10-09, to confirm)
- Goal: a player progresses whatever games they prefer and in whatever order; no game is required.
- Stars (3 per level, levels tuned to similar lengths in every game) are the ONE progress measure.
  Unlocks are automatic at star totals (one unlock table = the single source of truth; later a data
  file the game reads): games, food types, drink types, special foods, features.
- Pal stage (baby / kid / adult) decides the food and drink TIERS on offer.
- Drink TYPES unlock with the games (user, 2026-10-09): at first only the types whose boosts work
  in the games already unlocked are on offer (e.g. watery for Splash Hoops / Tilt Maze); a type
  arrives together with (or right after) the first game it helps, so every drink is useful.
- Tokens (separate from the score, earned per level cleared / new star at the same rate in every
  game) buy from a SHOP: key items (special foods for evolutions, rerolls, maybe higher drink tiers)
  so nobody is ever stuck, plus cosmetics (stickers, cases, backgrounds) and Lucky Pinch tries.
  Finding key items in games stays the better / free route (vaults, level drops); the shop is the
  sure but slower one. No real money in this shop.
- The score stays as records / bragging only (scores aren't comparable between games).
- Rules: every main-path item obtainable at least two ways (game-exclusive rewards are cosmetic);
  "equal value per minute" across games; after the first two games (Splash Hoops teaches the
  buttons, Tilt Maze tilt), the player CHOOSES which locked game to open next; small nudges towards
  variety (first star in a new game, daily pal requests), never forced.
- First hour (draft): start = Splash Hoops, 3 food types, watery drinks · 1st star = a sticker for
  the device · 3 stars = Tilt Maze · first evolution = kid-tier foods · 6 = fizzy drinks (+ a Tilt
  Maze low-fence vault right away) · 10 = the shop (tokens already earned) · 12 = choose the next
  game · ~20 = spicy + sour foods · then every 15-30 min, rarer and bigger later. Something new
  about every 5 min in the first hour; alternate kinds (a toy item, a game, a drink, a feature).
  Splash Hoops must give its first star within ~2 min and 3 stars within ~5-10.
- To decide: stars as the one measure? tokens + shop? the player choosing the next game? "two
  ways for every main-path item" as a firm rule?

## Pal design principles (for the art pass)
- Every pal is its own creature with its own idea, like Pokémon: different body shapes,
  personalities, faces and expressions. Not as wild as Pokémon's variety: all pals share one
  aesthetic (pixel scale, outline, palette rules, top-left light), but within that, real variety.
- A mix is a NEW IDEA, not a sum: sour + green must not be "the sour baby, bigger, with a green
  thing on its head". It should be something that makes sense for both ingredients together but
  isn't obvious (e.g. pulling from food culture: pickles, hot sauce, candied things, fermented
  things...). If the next evolution can be guessed exactly, it's boring.
- A light family cue can carry through (a colour accent, a trait), so the line still feels related.
- Silhouette test: each pal must be recognisable from its silhouette alone (the Pal Pedia shows
  silhouettes for missing pals, and the game's colour/silhouette hints depend on it).
- Several expressions per pal (happy, sad, angry, sick, sleepy...) and small idle animations.
- Size and complexity grow with the stage (baby simple and round, adults more elaborate).

## Evolution guidance: knowing what to go for without reading (2026-10-07)
Players must know intuitively what to feed to get new or specific pals, without studying the
Pal Pedia. The Pedia already has silhouettes + a text hint per missing pal, but that needs reading.
Guidance belongs at the moment of choosing food. Three layers:
1. The food tells you (zero reading): a food that would evolve the pal into an UNDISCOVERED pal
   gets a sparkle / "?" badge; one that leads to a known pal shows that pal's tiny face.
2. The pal tells you (zero reading, cute): now and then a craving bubble with a food-type icon;
   cravings point towards undiscovered evolutions. Ignoring them can feed the care mechanic.
3. Tracking (for collectors): tap a silhouette in the Pedia → "track"; the food leading towards it
   gets a marker in the food menu (like a quest marker). The reroll item helps when its type isn't
   on offer.
Optional: a small "next evolutions" view from the current pal (its 3-5 next pals as silhouettes,
each with the food icon that leads there), not the whole tree.
Colour language everywhere: one colour per food type (food tag, badge, craving bubble, pal tint).

## Minigames: 6 deep ones at launch, from easy to hard
- DECIDED (2026-10-07): 6 games at launch + Lucky Pinch as the bonus:
  Splash Hoops, Tilt Maze, Top Spin, Paper Sumo, Tummy Tunes (toy xylophone), Pipe Dream (circuit).
  Marble run = the 7th, in an update. Germ Zap, Pal Dash, Tile Break and Flipper Belly are out
  (too recognisable as Space Invaders / runner / Breakout / pinball): hide their cards, keep the
  code until the final cut (their ball physics, sounds and art can be reused).
- ORDER (DECIDED 2026-10-10, roughly easy → hard; the Games menu shows the cards in this order,
  GameMenuSwitcher.ORDER, Splash Hoops is the game unlocked from the start):
  1. Splash Hoops (two buttons: teaches the buttons)  2. Tilt Maze (teaches tilt)
  3. Paper Sumo (buttons + tilt, simple rules)  4. Pipe Dream → the RC car (two buttons, precision)
  5. Top Spin (the most complex controls)  6. Tummy Tunes, the music game (the hardest timing)
  then the four on hold at the end of the list (Pal Dash, Tile Break, Germ Zap, Flipper Belly).
  After the first two, the player chooses what to unlock next, so this is the suggested path.
  Locked games show as "?" cards with a hint.
- Rule: no generic clones. A game stays only if it has its own twist; otherwise it's replaced.
- "A toy box in a toy": the ones that work are digital versions of real physical toys, living inside
  the handheld and using its hardware (tilt, the two buttons, touch). But the toy is only the
  wrapper: the game must pass the depth test.
- Depth test for every game:
  1. Feels good in 10 seconds (weight, bounce, impact).
  2. A skill ceiling: an expert plays visibly differently from a beginner.
  3. Mechanics that combine, so each new one multiplies the levels.
  4. Decisions, not only reflexes.
  5. Cheap content: a generator or a level kit, so there can be 50+ levels.
- Art rule: every game looks like a real physical toy made of real materials (wood: Tilt Maze,
  Top Spin; paper and cardboard: Paper Sumo; plastic: Splash Hoops, Lucky Pinch). What ties them
  together is the shared style: chunky pixel art, outlines, top-left light, warm colours, the
  handheld frame.
- Menu legend wording (2026-10-10): device language, "press: next" / "hold: eat" (not "tap").
- Teaching: everything must be visually intuitive and light: icons over numbers, one short line of
  text at a time. The bigger games teach themselves with a first-time tutorial (done for Top Spin
  and Paper Sumo: one step at a time, each waits until you've done it, skippable with FORWARD) and
  an always-visible control legend (the device button's icon + what it does right now).
- Phones: games that need fast or two-thumb input read the touches directly (device_button_at);
  the emulated mouse only follows one finger and drops taps.
- Tilt works in ANY holding position (2026-10-07): it's measured from the pose the phone is in when
  a round starts (BaseMinigame.calibrate_tilt / device_tilt), not from lying flat. Used by Tilt
  Maze (each level; MAIN re-levels), Top Spin (at the drop), Paper Sumo (each bout).
- Verdicts:
  - Splash Hoops: the water toy, the first game.
  - Tilt Maze: keep (see "Tilt Maze" below).
  - Top Spin, Paper Sumo: prototypes in (see their sections).
  - Tummy Tunes: keep. The device's 3 buttons as lanes is its own thing, and it's the only rhythm
    game. Restyle as a toy xylophone (see below).
  - Pipe Dream: Flappy Bird now. PLANNED REWORK (user, 2026-10-10): an RC CAR (a real toy) on a
    circuit, seen from above, in the spirit of Micro Machines. The car drives forward by itself;
    ORANGE turns it towards the top of the screen, FORWARD towards the bottom, up to 90° each way
    (180° in all), so every course moves rightwards overall but can climb, drop, wind and zig-zag
    (and can be generated: a path that always progresses). The pal drives.
    Depth: racing lines (speed drops in tight turns), surfaces per world (carpet = grippy, bathroom
    tiles = slippery, garden = bumpy, puddles), shortcuts and risky routes, ramps, boost pads
    (Fizz = a speed burst), stars by time, a ghost of your best run. Maybe both buttons together =
    brake / drift (an expert trick, no third button).
    Open: keep the name (the course could run through toy plumbing pipes) or rename it; whether
    the car's speed is fixed or both buttons do throttle tricks.
  - Out (twist ideas kept in case): Tile Break (the toilet-paper paddle unrolls; the tiles are a
    mosaic revealing a pal card), Germ Zap (a gut garden: protect the good bacteria), Pal Dash (a
    ride through the gut timed to its squeezing waves).
  - Flipper Belly: MAYBE BACK (user, 2026-10-10: tabletop pinball is a real toy), but only with
    a twist that makes it more than pinball. Ideas: the table is your pal's tummy and CHANGES WITH
    WHAT IT ATE (spicy = hot zones, sweet = sticky candy bumpers, greasy = slippery lanes: the
    strongest, it ties to the gut-evolution pillar); digestion missions (guide the food through
    the stomach and intestine lanes) instead of plain points; the cheap plastic toy pinball look
    with a spring plunger, tilting the phone to nudge (TILT if overdone); one table per organ as
    worlds. A 7th candidate, judged by the depth test like the rest.
- Lucky Pinch stays a bonus, not one of the 6.
- Ideas looked at and why: daruma otoshi and kendama are one trick each (at most a mode inside
  another game); pachinko has no player control, and Lucky Pinch already covers luck.
- Late-game idea: MARBLE RUN, the thinking game. An almost finished run with gaps, a few pieces to
  place or rotate in fixed slots (ramp, funnel, trampoline, fan); press play and watch it go. The
  poop through the plumbing to the toilet. Pal traits matter (a heavy pal needs a different track).
  Puzzles are hand-made (needs a level format, maybe an editor for us), so it costs more than the
  other games.
- A hardcore late game for tryhards (La Campanella in Tummy Tunes, legendary foods).
- Every game should feed the rest: it unlocks specific foods, drinks and items, and each drink boost
  does something different in it (discovered by playing; the boost symbol goes on the card once found).

## Progression & unlocks (design first, then wire it all at once)
- Locked at the start:
  - 2 of the 5 food types (likely Spicy + Sour)
  - every drink type except Watery
  - all special foods (Tech, Cosmic, Legendary): the Special page shows "?" until the first one is unlocked
- Lucky Pinch: exclusive prizes, its pile refills when empty; tune how often the claw comes
  (now: every first meal, for testing).
- Turn off the testing switches (fresh start, debug unlocks…) once real saving is in.
- Every game has the same shape: worlds of levels, stars per level, secrets behind boost gates.
  Learn it in one game, you know it in all of them.
- Saved progress in EVERY game (DECIDED 2026-10-07): the highest level / world reached is kept,
  and you start from any level you've reached (no replaying level 1 each time). Records become
  per level (stars, best time, best score) instead of one long run score. An optional "arcade run"
  from level 1 can stay for high scores and leaderboards.
- Stars (3 per level): clear it / do it well (time, no fall…) / a perfect run. Total stars across
  all games unlock the next game and the next world in each game.
- Reasons to replay early levels (farming):
  - Missing stars, now easier with a better pal and boosts.
  - Each level drops ONE specific thing (an ingredient, a drink type, a Lucky Pinch token).
    Strongest pull if the pal's foods come from games: "I need the corn from Maze 1-4 for that
    evolution". Open question: does food become a pantry earned in games, or stay a random menu?
  - Points as a currency to spend (Lucky Pinch tries, a shop, rerolls), so farming has a use.
  - A daily level with a twist (a modifier) for a bonus.
  - (ideas, 2026-10-08) Daily requests from the pal ("today I'd love to win Paper Sumo 2 with a
    spicy pal"): small daily goals pointing at old levels, a small reward; ties into care.
  - Time trials against your own ghost on early levels (Tilt Maze, the Pipe Dream circuit):
    short, addictive, good for social clips.
  - A hidden extra in each level (e.g. a sticker for the device), easy to miss the first time.
  - Remixed early levels later on ("night" / "flooded" world 1): familiar layout, new rules.
  - Strongest pulls, together: vaults + level-specific items + daily pal requests (they tie
    replaying to evolution, boosts and care).
- Keep replaying light, not a chore: early levels short (under a minute); the level select shows
  what's still missing (stars, a locked vault icon, an uncollected item); no pure grind (an item is
  certain to drop, or guaranteed after a few tries, never a long chain of random drops).
- Games feed each other: game A drops the drink whose boost opens game B's secrets.

## Tilt Maze (the model for the others)
- Lots of levels: the seeded generator makes endless boards, but variety comes from WORLDS
  (~10 levels each), each with its own look and a new mechanic:
  wooden toy → bathroom tiles (slippery) → the gut (soft walls, moving holes) → the sewer (currents,
  flush streams) → space (low gravity, the alien goo foods). Later: switches, keys, one-way doors,
  magnets, a bigger grid. ~6 worlds = ~60 levels at launch, more in updates.
- Level select: start from any level reached. The world map shows stars and vaults (shut / open / ?).
- Vaults: a dead end off the route is sealed by a gate, with its prize visible from the first visit.
  Only the right boost gets through: Splash = a water channel to skim across, Fizz = a low fence to
  hop, Sturdy = a cracked wall to ram, Focus = a shutter to time, Lucky = a chest that needs a key.
  The boost is spent when it opens a gate (not wasted on a level without one). Vaults can ask for a
  boost tier (a low fence = Fizz 1, a high fence = Fizz 3).
- Vault prizes: special foods (microchip, alien goo…) above all, since they open new evolutions;
  then cosmetics.
- First version: level select + saving levels reached, Splash vaults on 2-3 levels.

## Top Spin (prototype: scripts/top_spin.gd)
- Your pal rides a spinning top in a bowl stadium. Three parts per match:
  1. WIND (6 s): a needle sweeps round; tap when it's on the gold zone. Hits in a row wind faster.
     Past 100% the top is over-wound and lands wobbly. Skill, not mashing. FORWARD = done.
  2. DROP: tilt to aim, tap to drop. Landing on a rival = an opening hit; the centre is safe.
  3. BATTLE: tilting the bowl steers you (it moves the rivals too, less: heavy ones barely).
     MAIN = dash (costs spin; where you lean, or at the nearest rival; leaves a trail). Hold FORWARD
     = guard (blue shield ring; heavy, drains spin). Guard just as you're hit = PERFECT (white ring
     moment): the hitter bounces off and you steal some spin. Rivals flash red with a "!" before
     they dash, so guarding is readable.
- Spin is health and energy: every dash and guard costs it. Out = stops spinning or flies out
  through a gap in the rim. Last top spinning wins.
- In the prototype: 5 rival styles (rookie, charger, wall, heavy, boss), bumpers, slime puddles
  (drain spin), 2-4 rim gaps, 8 levels then the last four repeat tougher, 3 lives. First-time
  tutorial (wind → drop → roll → dash → guard → fight) and a control legend. The tutorial is a
  practice match (TUTORIAL, then LV 1; dash twice, block two attacks: you hold still while
  learning to guard so every attack lands) in a smaller, lower bowl with no rim gaps, so the coach's
  card never covers it and nobody can fall out. Winding: a tap off the gold SLIPS the cord (spin
  lost + a short jam), so mashing never pays. Rivals' warning flash shrinks with the level
  (0.5 s at LV 1 → 0.2 s from LV 12).
- Still to come: whipping (tap in rhythm while free to win spin back), obstacles that hit everyone
  (a sweeper arm, rails, the toilet-bowl arena that flushes halfway), rivals fighting each other,
  goals other than KO (ring-out only, survive, bells, king of the hill), bosses per world,
  team matches with an ally top, stars, boosts (Sturdy = heavier, Fizz = stronger dash or easier
  winding, Focus = wider perfect window), pal traits.
- Watch: readability on a small screen. Max 3 rivals plus obstacles, big tops, a clear wobble.
- Look: painted wooden koma (Edo-koma: bright concentric rings, lathe-turned) in a turned wooden
  bowl with grain and lathe rings. The rings blur into bands when fast and become stripes as the
  top slows, so spin reads at a glance.
  Colour (2026-10-08): wooden but NOT brown: blue-grey tones (indigo-stained / aizome wood,
  weathered grey wood, or whitewashed ash with the grain showing). Wood reads through grain and
  lathe rings, not colour. The bowl stays calm blue-grey; the tops are painted Edo-koma with
  bright rings that pop against it (each rival its own ring colours). Fits the slate card and the
  chiptune music ("Pixel Battle"); if the track then feels too futuristic, regenerate it with a
  few traditional touches (koto-like square lead, soft taiko), the same recipe as Pixel Sumo.
- Feel to add: screen shake and a short freeze on big hits, a bigger spark burst; a whirring hum
  that drops in pitch as the top slows, wooden clacks, the ripcord sound while winding.
- Check on the phone: tilt directions (INVERT_TILT), winding speed, damage, match length.

## Paper Sumo (prototype: scripts/paper_sumo.gd)
- Tontonzumo: your pal printed on paper and folded, in a ring drawn on a cardboard box (side view).
  MAIN (HOP) drums your side: your wrestler hops the way it leans; tapping right as it lands keeps
  the rhythm and makes strong, steady hops (a tap a moment early counts); tapping high in the air
  only wobbles it. FORWARD (SHAKE) drums the far side: shakes the rival (risky). Tilt leans forward
  (pushes harder, falls easier) or back (the pull-down: a rival leaning on you falls when you back off).
- Out = falls over or steps out of the ring. Best of 3 bouts per rival, 3 lives. Rivals are other
  pals: PEBBLE (light), BRICK (heavy), SLICK (pull-downs), RUMBLER (drums your side), YOKOZUNA.
  First-time tutorial (hop → lean → push out; the rhythm step was dropped 2026-10-09: too hard
  and unclear) and a control legend. Good timing is shown instead: a hop timed right as the
  wrestler lands (a bit stronger) pops a little burst of sparks at its feet. A spotlight from above
  lights the ring, the rest is darker (an audience of pals was tried and removed).
- Open question: does it have the depth (see the depth test)? Rhythm + balance + pull-downs +
  pal traits (weight, height = top-heavy) are the candidates.
- The FORWARD button may be hard to read: add a cue (the rival flashes while it's mid-hop and
  vulnerable). If it still feels useless, make FORWARD a BRACE instead (hold to plant your feet:
  heavier, no hops), like Top Spin's guard.
- Check on the phone: lean direction (INVERT_TILT), bout length, whether falls happen.

## Tummy Tunes (the music game)
- Each WORLD a different toy instrument (2026-10-10): a toy xylophone, then a toy piano, then a toy
  drum kit (percussion)..., each with its own feel and songs, three notes under the device's three
  buttons. Different paths / levels per instrument. Songs played on the pal's tummy (gurgles,
  toots) as a twist.

## Care & daily rhythm (a reason to come back tomorrow)
- ON TRIAL (2026-10-10, FoodMenu BARRIER_ENABLED): while the food / drink countdown runs, a pixel
  roll-down shutter (the panel's orange) slides over that menu page with the LCD's countdown
  ("NEXT MEAL IN 29:59"), and eating / drinking is refused; once it has run out, the next time
  the menu opens it rolls back up. It slides in behind the frame's inner border (an overlay of
  that border: textures/menus/diapositive1_ring.png, made by tools/art/frame_ring.py).
  KEPT ON (user, 2026-10-10): it stays until that menu needs something else there; then switch
  it off (BARRIER_ENABLED) or replace it. Ties into the future hunger / thirst design.
- (2026-10-07) The player must feel the NEED to care for the pal. Soft, recoverable consequences
  (harsh ones, like Tamagotchi death, make people quit), e.g.: ~12 h without care = grumpy (boosts
  don't work, fewer points), ~24 h = sick (needs cleaning / medicine), ~48 h = goes back one
  evolution stage. The Pal Pedia is never lost. Plus rewards for caring: daily streaks.
  Notifications bring players back ("your pal is hungry").
- Real-time needs: the food/drink countdowns on the LCD become hunger/thirst with consequences.
- Healthy/unhealthy as a mechanic: a hidden gut health from what it eats and drinks.
  Junk streaks lead to "bad" pals (runny, bloated, sickly, diarrhea-like); eating well brings it back.
- Possibly kcal sets how long a meal keeps the pal full (heavy food lasts longer but steers
  towards the greasy lines).
- Something happening while you're away; small daily surprises.

## Foods that grow up (idea, 2026-10-07)
- The foods grow up with the pal: each type has a simple food at the baby stage, a more elaborate
  one at the kid stage, and even more at the adult stage.
  E.g. sour: lemon → (kid: lemon tart?) → (adult: something fancier); spicy: pepper → … → …
  Keep the type readable on fancy foods (the type colour / tag on every food).
- The menu offers 3 of the 5 types each time, so luck matters for reaching the missing evolutions.
- An earned item to REFRESH the 3 types on offer (a reroll). It's won in the minigames, so it
  ties farming in the games to completing the Pal Pedia.
- Luck compounds (the right type 3 meals in a row is ~22%): add a safety net, e.g. the type you
  need is guaranteed after a few meals without it. Balance rerolls: too many and luck stops
  mattering, too few and players feel stuck.

## Drinks
- Types (scripts/DrinkLibrary.gd): Watery (Splash, done), Fizzy (Fizz), Caffeinated (Focus),
  Milky (Sturdy), Fruity (Lucky). Drinks stay out of evolution (food drives it).
- Boosts (DECIDED 2026-10-07): each boost keeps ONE meaning everywhere (Splash = a second chance,
  Fizz = more power / lift, Focus = more forgiving timing, Sturdy = heavier / an extra life,
  Lucky = more rewards), and each game supports only the 2-3 that fit it (~15 effects, not 30).
  They should change how you play, not just add 10%. Draft:

  | Game         | Splash                  | Fizz                   | Focus                | Sturdy                   | Lucky              |
  |--------------|-------------------------|------------------------|----------------------|--------------------------|--------------------|
  | Splash Hoops |                         | stronger jets          |                      |                          | more points        |
  | Tilt Maze    | bounce out of a hole    | hop low fences (vault) |                      | ram cracked walls (vault)| open chests (vault)|
  | Top Spin     | survive one ring-out    | stronger dash / wind   | wider perfect guard  | heavier top              |                    |
  | Paper Sumo   | spring back from a fall |                        | wider beat window    | heavier, harder to push  |                    |
  | Tummy Tunes  | one miss forgiven       |                        | wider timing         |                          | more points        |
  | Pipe Dream   | one crash forgiven      | extra lift             | slower course        |                          |                    |
  | Lucky Pinch  |                         |                        |                      |                          | a firmer grab      |

  Tilt Maze's boosts are mostly KEYS to its vaults, so each drink has a second purpose there.
- Boost TIERS (idea, 2026-10-07): 3 drinks per type, from basic to strong, like the foods that
  grow up. Tier 1 / 2 / 3 = a stronger version of the same effect (Splash: 1 save / 2 saves /
  a save + a bonus; Focus: timing windows +10% / +20% / +30%; ...). Higher tiers appear as the pal
  grows (baby: tier 1, kid: tier 2, adult: tier 3), and rare top drinks can be prizes (vaults).
  Show the tier with icons, not numbers: the type's symbol 1, 2 or 3 times (Watery = 1, 2 or 3
  droplets), on the drink, the pal's boost badge and the game HUD. Light and playful, never heavy.
  Draft line-up (one new drink per type; Japanese favourites):
    Watery:      Water → Barley tea (mugicha) → Coconut water
    Fizzy:       Cola → Lemonade → Ramune
    Caffeinated: Green tea → Coffee → Energy drink
    Milky:       Milk → Calpis → Milkshake
    Fruity:      Orange juice → Peach juice → Smoothie

## Instruction booklet (planned; keep this outline updated as mechanics ship)
The booklet explains the whole game straight away, so nobody needs to study menus or the Pal Pedia.
Already decided (box work, 2026-10-05): a classic stapled instruction manual; in the unboxing only
its cover shows under the device; later it's opened as an easter egg by tapping the sticker on the
device's back ("SEE INSTRUCTION MANUAL"), not from a settings menu.

Style rules
- Old handheld manual feel (90s Japanese game manuals): one idea per page, pictures first, the real
  device button icons inline, at most ~3 short paragraphs a page, cute pal mascots giving tips.
- Same art as the box: pals pixelated to the 3 px print grid, the box's colours.
- Written to be localised (Japanese first): short sentences, no wordplay that can't translate.
- It explains what's IN the game at release only; nothing "coming soon".

Chapters (one page each unless noted)
0. Cover + "Thank you for adopting a HaraTomo pal!" (a welcome and a playful safety joke).
1. The general idea: raise a pal, feed it to make it evolve, play toy games, collect them all.
2. Your HaraTomo device: a labelled drawing of the screen, the LCD score, the menu buttons (food,
   games, collection, settings), MAIN (orange), FORWARD, the speaker / mute button, the back sticker.
   How to hold it for tilt games (lay it flat).
3. Your pal: hatching with the first meal, poking it, flushing (hold MAIN), moods.
4. Feeding and evolution (2 pages): the 5 food types with their colours and icons; stages
   (baby → kid → adult, plus rare mutants and legends); each meal steers the next evolution (a
   small path diagram); special foods (Tech, Cosmic, Legendary); how to read the guidance (sparkle
   = a new pal, the pal's cravings, tracking from the Pal Pedia); the reroll item.
5. Drinks and boosts: the 5 drink types and their boost icons; tiers shown as 1-3 symbols; one boost
   at a time, used up in the next game that has a use for it. (Which boost does what in each game
   is left for players to discover.)
6. Care and daily life: hunger / thirst, what happens if you forget your pal (grumpy → sick → back
   one stage), daily streaks. Gentle tone.
7. The games (1 page per game): Splash Hoops, Tilt Maze, Top Spin, Paper Sumo, Tummy Tunes,
   Pipe Dream. Each page: the toy it's based on, the goal, the controls (button icons + tilt),
   2-3 tips, worlds / stars / secrets in one line.
8. Lucky Pinch: the bonus claw machine, when it shows up, its exclusive prizes.
9. Collectables: the Pal Pedia (silhouettes, hints, tracking), backgrounds, accessories, gut decor,
   and how each is earned.
10. Progress and unlocks: stars, worlds, unlocking new games, saved progress per game.
11. Settings and sound: mute, skipping songs (FORWARD on the pet screen); tilt calibration (MAIN in
    Tilt Maze); maybe hint at the device-flip easter egg (double-tap the logo).
12. Back cover: a teaser of the evolution chart in silhouettes ("can you find them all?").

Where the facts live (to write each chapter from the code, not from memory)
- Pals and evolution: data/evolution_tree.json, scripts/pet_state.gd (feed, evolution_for, BOOSTS).
- Foods and drinks: scripts/FoodLibrary.gd, scripts/DrinkLibrary.gd.
- Collectables and rewards: scripts/collection.gd (REWARDS, BACKGROUNDS, ACCESSORIES, DECOR),
  scripts/lucky_pinch_state.gd.
- Games: the header comment of each scripts/<game>.gd (controls and rules), the tutorials' coach
  lines in Top Spin and Paper Sumo.
- Unlocks and progress: scripts/game_data.gd.
- Device controls: scripts/main_button.gd, scripts/forward_button.gd, scripts/device_flip.gd.

## Release timeline (draft, 2026-10-08; assumes steady work like recent weeks)
1. Foundation (~1 month): real saving + testing switches off, saved progress per game, stars and
   levels, evolution guidance layer 1 (the food sparkle), the 4 missing drink boosts.
   → A TestFlight build friends can play (needs the paid Apple account).
2. Games and systems (~2 months): Tilt Maze worlds + vaults, Top Spin and Paper Sumo finished
   (feel, levels), Tummy Tunes as a xylophone, Pipe Dream as a circuit, care consequences, foods
   that grow up + reroll, unlock progression tied together, first toy moments (stains, stickers).
3. Art pass (~1-2 months, the fun part, last on purpose): new pals (30-40 great ones for launch),
   new food and drink art, game art (wooden koma etc.), cases.
4. Release prep (~1 month): Japanese localisation, the booklet, pricing / the one purchase,
   store screenshots and a trailer led by the device experience.
≈ 5-6 months to a first release. Scope levers if needed: fewer pals at launch, fewer Tilt Maze
worlds, fewer drink tiers; the rest arrives in updates.

## Android port (later; not hard)
- Godot exports to Android about as easily as iOS; nothing in the game is iPhone-only (the iOS
  scene-lifecycle plugin just isn't needed there). ~1-2 days to run on a phone, ~a week to polish.
  Do it after the iPhone version plays well, or alongside TestFlight.
- Setup: Android SDK + JDK + Godot's Android export templates + a debug key (USB installs like
  the iPhone); to publish, a Google Play account (one-time fee) and a release key.
- To handle: many screen shapes (test tall phones and tablets; the device sits on black already),
  the system Back gesture (probably = leave the menu), the vibration permission, maybe Godot's
  simpler renderer for old phones, and the purchase code (Google's billing, separate from Apple's).
- Tilt: our games read gravity, not rotation, so every phone works (the accelerometer is
  everywhere). Budget phones without a gyroscope (e.g. some Galaxy A32 variants) lack the clean
  fused "gravity" sensor, so the game falls back to the raw accelerometer (already coded in
  BaseMinigame._gravity), which also picks up shakes: add a small smoothing (low-pass) filter on
  that path and test on a cheap phone.

## Release plan (draft)
- Launch with the 6 games polished, don't wait for 7 and 8. Then updates: new worlds, new pals,
  then a new game (the marble run). Polish over count.
- Pricing to decide: a "launch price, rising later" works if it's announced as such (early buyers
  feel rewarded). For Japan, consider a free download with the first games playable + one purchase
  that unlocks everything (no ads, no pay-to-win): the unlock structure already fits it.

## Before release
- Legal (2026-10-08; not legal advice, check with a trademark attorney before filing):
  1. Now, free: search the official databases for HaraTomo / ハラトモ / 腹友 / 便友 in classes 9
     (apps), 41 (entertainment, online games) and maybe 28 (toys): J-PlatPat (Japan), WIPO Global
     Brand Database, TMview (EU + many national offices), USPTO. A quick web search (2026-10-08)
     found no app, game, brand or trademark called HaraTomo.
  2. Just before the game goes public (trailer, open TestFlight, store page): file ONE cheap home
     trademark (e.g. Spain's OEPM, ~low hundreds of euros for one class).
  3. Within 6 months of that filing, if the reaction is good: extend through the Madrid system
     (WIPO) to Japan (+ US / Korea / EU as wanted), keeping the home filing date. Japan is
     first-to-file, so don't wait long once the game is visible. Check the EU SME Fund (it has
     refunded much of the trademark fees for small businesses).
  Box text: the lid's bottom band says "120+ PALS TO DISCOVER!" (tools/design/box_art.py):
  match it to the real number of pals at launch.
  Also before release: a licence check of every sound, song, font and image (e.g. the Epidemic
  Sound effect, the 8-bit classical recordings, pixChicago); a privacy policy; the age rating; the
  kids' app rules if aimed at young children.
- TestFlight with friends early: watch where they get bored.
- Rebalance scores and difficulty.
- Store presence: screenshots and a short video of the handheld + a pal evolving.
