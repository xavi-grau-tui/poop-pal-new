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

Progression v2 (branch `rearrange`, 2026-10-10): BUILT the level menu + stars + result card
(Splash Hoops' 45 levels), coins per new star, games bought in the Games menu (shutter cards,
doubling prices), the Shop (adult foods, Spicy / Sour, special foods in a pantry), foods that
grow up with the pal (30 foods), Splash Hoops' gift track, the pufferfish leaving and coming back.
What follows from it:
- (M each) The other launch games onto levels: Tilt Maze first (its worlds, then the fence
  vaults), then Paper Sumo, Pipe Dream, Top Spin, Tummy Tunes: a LEVELS table, a star rule and
  uses_levels() each (BaseMinigame + LevelMenu do the rest).
- (S) The coin / Shop onboarding cards (listed in Progression v2).
- (S) Tune Splash Hoops' star marks (STAR_2 / STAR_3) and level times on the phone, then put the
  measured numbers into tools/design/pacing.py.
- (M) Drinks v2 ("Progression v2, round 2" below, to confirm): drink levels in the Shop, the 15 drinks' art, the
  level and size icons on the tags, the first secrets (Tilt Maze fences).
- (M) Stickers (the Shop's cosmetic, the device's back) and the food reroll.

Medium (M)
6. Tilt Maze: its level menu (the shared LevelMenu) + worlds, then the first fence vaults.
7. Pal traits from data (family = trait, stage = size), used by Tilt Maze, Top Spin, Paper Sumo.
8. The other drink boosts (Fizz, Focus, Sturdy, Lucky) in the games, per the boost table.
8b. (S-M, decided 2026-10-10) Water in Splash Hoops (+10 s once per run, wave + "+10" from the
    badge) + only watery drinks at the start + the first-drink onboarding (steps a-c). Then Fizzy
    with Tilt Maze: low-fence vaults and their prizes (see Tilt Maze).
9. Evolution guidance, layer 2: craving bubbles from the pal.
10. Top Spin restyle: painted wooden koma in a turned wooden bowl.
11. Boost tiers: 3 drinks per type, tier icons (1-3 droplets etc.), 5 new drink icons.

Big (L)
12. Real saving + turning the testing switches off. Needs: nothing; it's the foundation for
    progress, care, tracking and unlocks.
13. Care consequences (grumpy → sick → back one stage) + daily streaks + notifications.
    Needs: 12.
14. One progression shape for every game: worlds, 3 stars per level, saved progress. STARTED on
    `rearrange` (Splash Hoops; see Progression v2). Needs: 12 for real saving.
15. Foods that grow up with the pal: BUILT on `rearrange`. Left: the reroll item + the luck
    safety net.
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
- MOODS = hunger (user idea, 2026-10-10; docs/mockups/pal_brainstorm/v3/moods.png): Ember's face
  options become a ladder as time passes without food: Just fed (current: glossy eyes, smile,
  blush) -> Fine (B: smaller eyes) -> Peckish (D: Picklet dots) -> Hungry (A: glossy, no smile) ->
  Grumpy (C: half-lidded). First guess at the times: 0-30 min, 30 min-2 h, 2-6 h, 6-12 h, 12 h+.
  Every pal keeps its own face style; the mood modifies it. Sick / back-one-stage can follow
  Grumpy later (care consequences).
  UPDATE (user, 2026-10-10): 3 hunger faces per pal (fed / hungry / very hungry), and NOT the same
  pattern for everyone: each pal's arc fits its personality. A serious pal starts serious and
  gets a bit upset; a happy one can go happy -> scared -> offended; others their own way. Not
  linear, not one ladder for all: the 3 faces are part of each pal's design (a field per pal in
  the data). Idle animations come later, via script.
- FOOD WITHOUT EVOLUTION (user idea, 2026-10-10, to decide): a snack of the pal's OWN size keeps it
  happy (back to Just fed, the countdown restarts) without changing it; food of the NEXT size
  makes it grow. Fits Progression v2 (foods by size): the food menu would offer both sizes, the
  next size marked as "grows" (its icons one higher). Lets a player keep a pal they like for days.
- PAL DRAFTS v3 (2026-10-10, the direction the user loved: "the t3 variations... that's the way"):
  docs/mockups/pal_brainstorm/v3/sheet1.png, sheet2.png, sheet3.png = three full, MIXED 120s in the
  current pals' render quality. Every kid line (a baby + its 2nd food, with its 3 adults) has three
  alternatives: a SNACK (a dish that came alive: onigiri, taiyaki, dango, purin, burger, fried egg,
  takoyaki...), a YOKAI / lucky charm (kappa, tengu, oni, daruma, maneki-neko, karakasa, teru teru,
  kokeshi, kitsune, tanuki, umibozu...) or a CRITTER (frogs, moths, bees, hedgehogs, crabs, owls,
  foxes...). The sheets rotate them line by line, so each sheet mixes all three and every
  alternative appears once: pick per line (or per pal) across the sheets. Bud, Ember (calmer face)
  and Picklet are in every sheet. Each adult shows the 3rd food that leads to it (the food icons).
  Rules kept: Power Rangers colours per family, faces mostly cool (dots, half-lids, side-eyes,
  sleepy) with a few smiles, one idea per pal, no body shape more than twice per family band
  (check3.py). Files: palgen3.py (renderer: ~45 body plans, ~70 parts, ~22 eyes x 18 mouths),
  sets3.py (all 351 designs + names and one-liners), build3.py (the sheets), moods3.py (moods.png).
- DRAFTS (2026-10-10, brainstorm only, to pick from later): docs/mockups/pal_brainstorm/
  (1 = the current 120; 2 = new set A "clean shapes"; 3 = new set B "odd creatures", the user's
  favourite; 4 = Ember face options; v1_rough/ and v2/ = earlier tries). Names and one-liners in
  sets.py; generator palgen2.py (the current art style: forms_gen's renderer, outline drawn twice).
  Direction from the user: keep Picklet exactly as it is (Bud is the other strong baby); Ember
  recovered with a calmer face (no grin); faces not all smiling (Picklet's dot eyes, half-lids,
  glances); simple but cool, more variety and originality than today's "same body + topping".
  Family colours: sour yellow-green (Picklet's), spicy red, green green, greasy yellow-orange,
  sweet the Top Spin blue (chocolate as its first food). Combos may give new colours (chilli +
  chocolate = purple).

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
- GUIDE CARDS for Progression v2 (PROPOSED 2026-10-10, the user: "after playing a game and exiting,
  the main screen should tell you: looks like you earned some coins, now you can X, or X..."). Same
  look as the welcome card; each shown ONCE, on the main pet screen, with the button(s) it names
  doing the bip-bip. The text lists only what the player can afford / use right now.
  G1 First game left with coins: "You earned [coin] 6 coins! Spend them on a new game [games] or
     food for your pal [gear]." (Games button blinks if a game is affordable, else the gear.)
  G2 First time enough coins for the next game (any later exit): "A new game is ready to open!
     Hold its card in [games] to buy it." (Tilt Maze the first time.)
  G3 First time the pal can't grow (a kid, only locked adult foods): "Your pal is ready to grow,
     but needs bigger food. Find it in the Shop [gear]."
  G4 First Shop opening: "Coins buy food packs and special foods. Games are bought in [games]."
  G5 Second game bought: "New game, new drink! Drinks give your pal a perk in the games." (+ the
     first-drink steps a-c below)
  G6 First locked food card held: no card, the gear blinks (already built).
  G7 First world finished: "World 1 done! Every star you add later still gives a coin."
  G8 First gift track item: the LCD's ITEM UNLOCKED! + "Your first gift! Find it in [gear]."
  G9 First mood change to Hungry: "Your pal is hungry. Tap [food] when the timer runs out."
  Rules: max one card per return to the main screen (the rest queue); never during a minigame or
  a menu; a card that is no longer true when its turn comes is dropped (e.g. G2 after the game was
  already bought). Saved "seen" flags (with real saving).
  Cards never interrupt: if the moment comes during a minigame or with a menu open, the card WAITS
  (queued) and shows the next time the player is back on the main pet screen.
  - First drink (DECIDED 2026-10-10, replaces the 2026-10-09 note): two marked steps.
    a) When drinks first become available (the first drink countdown runs out, back on the pet
       screen): "Drinks are here! Tap [drink button] and drink something." The drink button and
       the DRINK sign blink with the buzz; only the drink button works (like the first meal).
    b) Once the pal has drunk and shows its boost (aura + badge): "Drinks give your pal a perk
       [boost icon] in the games it fits. Water: more time in Splash Hoops." Then the games
       button blinks: "Try it out!"
    c) In the game, the first time the boost fires (the clock hits 0 and the wave comes): the
       game pauses a moment on a small card "Your Water saved you! +10 s", pointing at the
       droplet badge. After that it just plays its effect (see Splash Hoops: the water boost).
  6. Each new thing explained only when it opens: the first drink ("Drinks give your pal a boost in
     the next game"), the shop at its unlock ("The shop is open! Trade your [token] for treats and
     stickers", with tokens already earned), each new game, each new food type.

## Progression v2: stars, coins, pals (2026-10-10, built on branch `rearrange`)
OFFICIAL (user, 2026-10-10): this progression (with round 2 below: food packs per size, Sho / Chu /
Dai, game prices 5/40/60/90/135, the progressive Shop that grows with the pals' sizes, special
foods once a Dai exists, legendary once its ULTRA) is THE way to go. Next: the user picks the pals
(from the v3 sheets) and their moods; then the guide cards.
GAMES ARE ALL BUYABLE FROM THE START (user, 2026-10-10; no "opens after Tilt Maze": the player
doesn't know Tilt Maze yet). Each has its own price, in the menu's easy -> hard order: Tilt Maze 5,
Paper Sumo 40, Pipe Dream / RC car 60, Top Spin 90, Tummy Tunes 135 (GameData.GAME_PRICE). Cards
still to make say "Coming soon".
NEXT STEPS (set 2026-10-10): 1) the user picks the pals and their 3 moods each (from the v3 sheets),
then tests the progression path with them; 2) guide cards G1-G9; 3) Drinks v2; 4) levels for the
other games (Tilt Maze first); 5) the RC car (Pipe Dream's rework), the Flipper Belly rework (the
tummy pinball that changes with what the pal ate) and the marble run (place pieces, watch the ball
roll; the 7th game, later); 6) real saving; 7) the art pass.
Replaces the 2026-10-09 framework below where they differ (that one is kept for its reasoning).

The loop in one line: games give STARS, every new star gives a COIN, coins open new GAMES and the
FOODS the pal needs to grow, and the PALS (found by feeding, at the pace of real meals) are the
long goal. Cosmetics come as gifts for playing, never for sale.

Three things, three jobs (nothing else to learn):
| What               | Earned by                                  | Used for                                         |
|--------------------|--------------------------------------------|--------------------------------------------------|
| Stars (1-3/level)  | playing a level well                       | coins (the first time) · each game's gift track |
| Coins              | each NEW star = 1 coin (+ small daily ones) | games (Games menu) · foods, key items (Shop)     |
| Pals               | feeding (a meal every 30 min)              | the Pal Pedia: the goal that lasts months        |
The LCD score stays as bragging only.

Pacing, why it holds together: a pal needs 3 meals to be an adult (= 1 h of real time at least), so
the 75 adults alone take ~110 h of meals: the pals are the slow spine (weeks to months). Games are
what you do between meals (minutes). Coins are the bridge: what you earn in a session decides what
your pal can grow into at the next meal.

Levels (every game, same shape: learn it once)
- Worlds of 9 levels = one page of the game's level menu (3 x 3, like the Pal Pedia: press = next
  level, hold = play, forward = next world). Launch: 5 worlds = 45 levels per game (6 games = 270
  levels, 810 stars, ~12-18 h to 3-star everything); updates add one world (9 levels) at a time.
  Not 100 at launch: every level has to be tuned and feel different; a grid that never ends feels
  impossible (the same reason the pals stay at ~120).
- Clear a level (1 star) = the next one opens; the 9th opens the next world. No star gates (a
  level you can't 3-star never blocks you; stars pay in coins and gifts instead).
- First time in a game: straight into level 1 (with its how-to card). After that the game opens
  on its level menu, on the first level still missing stars.
- After a level: the stars fill in one by one, new stars fly into the coin counter: NEXT / RETRY /
  LEVELS. Time's up: RETRY / LEVELS.
- 1 star = clear it, 2 = clear it well, 3 = clear it great; each game measures its own way (time
  left, no fall, perfect timing). The HUD shows the three stars and each one dims the moment it's
  lost, so you always see what you're playing for.

Coins: about 1000 over a whole playthrough
- +1 coin for each NEW star: 810 at launch. Replaying a level gives no coins once its stars are
  taken: no grind, ever.
- Small renewable ones (later): the pal's daily request (+3), Lucky Pinch coin capsules (once its
  items run out), a bonus for the first time a world is finished. Over months: ~1000.

Prices: about 1000 to buy everything
- GAMES, bought in the Games menu (hold the locked card): each one costs double the last:
  5, 10, 20, 40, 80 (155 in all). The 2nd is always Tilt Maze (it teaches tilt); after it any
  locked card can be bought, at the current price (the menu order is only a suggestion).
- SHOP, the gear menu's new card:
  - Food types: Spicy 30, Sour 30 (their baby and kid foods).
  - Adult foods, per type (both adult foods of that type): 20 for the first you buy, then 30, 40,
    50, 60 (200 in all).
  - Special foods (key items, each one = one meal, kept in a pantry): Microchip / Battery (tech)
    15, Alien Goo / Moon Rock (cosmic) 15, each legendary food 40. A full Pal Pedia needs 15 of
    them (~350); some come free from Tilt Maze vaults and daily requests.
  - Later: stickers for the device's back (10-30 each; some only from levels, milestones and
    Lucky Pinch), food rerolls (3), cases.
  - In all: 155 + 60 + 200 + ~300 + ~300 = ~1000, so a completionist ends with everything.

When things arrive (a typical player; tune on the phone)
- 0-10 min: Splash Hoops 1-1 to 1-4 (~6 coins) → Tilt Maze (5).
- 30 min: the pal is a kid → it needs adult foods to grow up → the first adult foods (20) at ~1 h.
- 1-2 h: the 3rd game (10), the 4th (20), Spicy (30).
- 2-5 h: Sour, more adult foods, the 5th game (40), the first Microchip.
- 5-10 h: the 6th game (80), the rest of the adult foods, special foods for mutants and legends.
- After: special foods, stickers, the last stars, the Pal Pedia (weeks).

Foods and the pal's growth (the 30 foods: docs/mockups/food_drafts/)
- A pal grows only by eating food of its next size: baby foods hatch a pal, kid foods grow a baby
  into a kid, adult foods grow a kid into an adult. The food menu shows the size the pal needs.
- At the start: Green, Sweet and Greasy, with their baby and kid foods. Spicy and Sour, and every
  type's adult foods, come from the Shop.
- A kid looking at a type whose adult foods you don't have yet: that card is locked ("?" + Shop);
  holding it blinks the gear button (where the Shop is). The pal waits, nothing is lost.
- Special foods page: the ones in your pantry (with how many), the rest "?". Only an adult can
  eat them (tech / cosmic = its family's mutant; legendary = only its own ULTRA adult); anyone
  else is refused softly, so a key item is never wasted.

Cosmetics: gifts for playing (DECIDED with the user's question, 2026-10-10)
- Backgrounds, dress-up pieces and gut decor are never sold. They come from: each game's GIFT
  TRACK (its own themed set at star milestones, e.g. 5, 15, 30, 60, 100 stars), Lucky Pinch
  (its exclusives), and Pal Pedia milestones (every 10 pals found). Why: a surprise gift feels
  generous (the ITEM UNLOCKED! moment); coins stay for decisions that change what you can DO; a
  shop full of price tags feels commercial; and every game gets a visible reason to go for 3 stars.
- First version: Splash Hoops' track carries the existing items (Pipe Dream's old score rewards
  move there); each game gets its own themed set in the art pass.

Unlockables: the full catalogue and how each one is earned (PROPOSED 2026-10-10, user question)
- Not by score: scores are not comparable between games (Splash Hoops points vs Tilt Maze points)
  and favour whoever grinds one game. Stars are the same in every game (45 levels x 3 = 135), so
  every game gives the same gifts for the same effort. The score stays as bragging (the LCD's
  lifetime total, best scores); if a cross-game number is wanted, it is total stars (x/810).
- Three sources, each with a visible goal (the locked card says how: "Tilt Maze: 30 stars"):
  1. Each game's GIFT TRACK (5 items, at 5 / 15 / 30 / 60 / 100 of its stars), themed after the toy,
     always in the same category order: 5 = a sky colour, 15 = a gut add-on, 30 = a dress piece,
     60 = a gut colour, 100 = a background scene (the showpiece). 6 games = 30 items.
  2. LUCKY PINCH exclusives (8, one capsule each, a party theme), then coin capsules.
  3. PAL PEDIA milestones (every 10 pals found = 12 items): the long goal, rewarded too.
  (+ secrets behind drink gates: stickers, see Drinks v2; + later: a care streak gift.)
- Kinds: DRESS (worn by the pal), GUT = colour (a hue shift) + add-on (hung on the gut), BACKGROUND =
  sky colour + scene (scrolling layers). Colours are cheap to make (a hue), so they fill the early
  milestones; scenes and dress pieces are the big ones.

  | Source        | 5 / 10           | 15 / 20            | 30 / 30            | 60 / 40           | 100 / 50          |
  |---------------|------------------|--------------------|--------------------|-------------------|-------------------|
  | Splash Hoops  | Aqua sky         | Seaweed (gut)      | Swim goggles       | Aquamarine gut    | Underwater scene  |
  | Tilt Maze     | Maple sky        | Marble run (gut)   | Explorer hat       | Wooden gut        | Labyrinth scene   |
  | Paper Sumo    | Washi sky        | Paper cranes (gut) | Sumo topknot       | Origami red gut   | Dohyo scene       |
  | Pipe Dream/RC | Asphalt sky      | Checkered flags    | Racing helmet      | Neon gut          | Race track scene  |
  | Top Spin      | Indigo sky       | Koma garland (gut) | Hachimaki          | Vermilion gut     | Festival scene    |
  | Tummy Tunes   | Lavender sky     | Music notes (gut)  | Headphones         | Disco gut         | Stage lights scene|
  Lucky Pinch: Party hat, Scarf, Confetti scene, Toilet Rolls scene, Lilac sky, Bunting, Golden gut,
  Mint gut. Pal Pedia (every 10 pals): 10 Round glasses, 20 Fairy lights, 30 Starry sky, 40 Bow tie,
  50 Garden scene, 60 Rainbow gut, 70 Flower crown, 80 Night scene, 90 Monocle, 100 Golden frame
  (gut), 110 Sunglasses, 120 Hall of Fame scene. Defaults: Clouds, Pink sky, the natural gut.
  In all ~50 items: 11 dress, 10 gut colours, 11 gut add-ons, 9 sky colours, 9 scenes.
- When (pacing model, regular player): the first gift ~3 min in, then ~one every 10-15 min in the
  first hours (5 / 15 / 30 stars come fast in each new game), the 100-star scenes are the long
  goals (~3-4 h of play each), Pal Pedia gifts every few days.
- Dress pieces must fit every pal: with v3's varied bodies, each pal's renderer exports anchors
  (head top, eye line, width) so accessories are placed per pal instead of drawn by hand 120 times.

Locked game cards (Games menu)
- The card's picture is behind the food menu's roll-down shutter, with a small "?" label on it
  (the "?" logo on the "?" looping pattern). The info panel shows the price: a coin and the number.
  Hold it with enough coins: the coins count down, the shutter rolls up, GAME UNLOCKED! Not enough:
  a soft buzz and the price blinks. Cards that can't be bought yet (before Tilt Maze) show a lock
  instead of a price.
- Bought games show "Stars 12/135 · Levels 4/45" instead of best score / progress.
- The coin balance shows in the Games menu and in the Shop (and in every game's HUD).

Onboarding to add with it: first coin ("Stars give coins!"), first time enough coins for a game
(the Games button blinks: "A new game is ready to open"), the first kid ("Your pal needs adult
food to grow up: get it in the Shop", the gear button blinks), the Shop's first opening.

Testing (rearrange branch): GameData.DEBUG_UNLOCKED now only holds the 4 games on hold, so the 6
launch games are bought with coins; the dev launcher has a STRAIGHT TO GAMES + 999 COINS button.

## Progression v2, round 2 (2026-10-10, branch `rearrange`): balance, drinks, food sizes
Rule (user): nothing left to chance. Every price comes from a timing target, checked with the pacing
model `tools/design/pacing.py` (a fixed player model, no dice, the real evolution tree; replace its
ASSUMED numbers with phone measurements). Three players: casual (20 min day 1, then 12/day), regular
(60, then 30), keen (180, then 60).

Foods (BUILT, the user's rule): from the start you have baby foods of 3 types (green, sweet, greasy),
kid foods of 2 (green, sweet) and adult foods of 1 (green), so the first pal grows all the way up.
The other 9 packs (2 baby, 3 kid, 4 adult) are in the Shop, priced by size like their icons: baby
10, kid 15, adult 20 (145 in all). Any pack is useful at once (no pack needs another).
Menus with nothing random (BUILT): the food menu lists every type you have for the size the pal
needs, always in the same order, then the rest as locked cards (silhouette + padlock + "Kid food";
holding one blinks the gear = the Shop). The two foods of a size take turns meal after meal
(a first-ever sweet meal = the chocolate). More than 3 cards: the list scrolls (press past the 3rd),
pips on the panel's right edge show where you are. An adult gets every type it has, no locks.
The drink menu: one drink type per game owned (Watery, Fizzy with Tilt Maze, Energy, Milky,
Fruity), the rest locked (holding one blinks the Games button: it comes with a new game).
The Shop opens with the packs your pal needs next first.

Game prices (BUILT): 5, 40, 60, 90, 135 (330). Doubling from 5 gave a regular player all six games
within ~1 h of play (each new game's easy world 1 pays for the next), then nothing to look forward to.
Now, regular player: Tilt Maze 3 min, 3rd game 17 min, 4th 45 min (day 1), 5th day 3, 6th day 9.
The model also says: the starting foods last about a week before a pack is needed; the 10th pal
~day 4, the 30th ~day 14, the 60th ~day 31; ~260 coins are left over for special foods.

Drinks v2 (PROPOSED, to confirm):
- Types come with games (built, see above); each type arrives at level 1.
- Levels 2 and 3 are bought in the Shop per type, permanent (that type's drink in the menu becomes
  the stronger one; you always get it, every 15 min): level 2 = 15, level 3 = 30 (needs level 2).
- What a level does: the same effect, stronger (Splash Hoops water: +10 / +15 / +20 s) AND it opens
  SECRETS: from world 2 on, one level per world holds a gate marked with a drink type's icons x1-3
  (Tilt Maze: a fence with 3 bubbles = Fizzy level 3). Only a boost of that type at that level
  opens it; the boost is spent there. The level menu shows the gate's icons on that level's cell
  and the prize's silhouette (bright once taken). World 2 = level 1, worlds 3-4 = level 2, 5 = level 3.
- Prizes: the 15 special foods the Pal Pedia needs (10 tech / cosmic for the mutants, 5 legendary
  for the legends, the legendary ones behind level-3 gates) + stickers. The Shop still sells them
  (15 / 40): two ways for every main-path item.
- Why buy level 3 (the user's question): you SEE the gate and its prize long before you can open it;
  one level-3 drink (30) opens every gate of its type, and a legendary food behind one is worth 40;
  it also makes the hardest 3-stars easier. Stars stay reachable without any boost (no pay to win).
- Pacing (model): first secret ~17 min, first level 2 day 2, first level 3 day 6 (regular).

Food size icons (DRAFT, docs/mockups/food_drafts/foods_tier_sheet.png, tier_icons.py): the drinks'
level icons' sibling: the type's icon once = baby food, twice = kid, three times = adult, on the
tag's top-right corner (menu, Shop packs, locked cards). Green = a leaf, Sweet = a wrapped sweet
(blue), Greasy = a burger, Spicy = a flame, Sour = a lemon. Not in the game yet: goes in with the
drink icons. Open: the tags still use the old pastel colours (sweet = pink) while the icons use the
new type colours (sweet = blue): recolour the tags too?

Dev launcher BOOT + PROGRESSION (BUILT): the real game kept between launches, its own save
(user://progress/, scripts/save_slot.gd), every testing switch off, only the six launch games, the
unboxing only the first time, real Lucky Pinch chance. The meal / drink countdowns are now saved as
real times (they run while the app is closed). START OVER (two taps) wipes that save; the three
testing starts never touch it.

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
- CREATURE TYPES (user, 2026-10-10: keep this naming for the game): every pal line (a kid and its
  3 adults) is one of three types: SNACK (a dish that came alive: onigiri, taiyaki, dango, burger),
  YOKAI (a Japanese spirit or lucky charm: kappa, oni, daruma, maneki-neko) or CRITTER (an odd
  animal: frog, moth, hedgehog, crab). The v3 sheets show three options per line (one per type);
  the final tree picks one per line, aiming for a good mix in every family. The type can show in
  the Pal Pedia (a small icon) and maybe matter later (traits, collections: "all the yokai").
- ADULT KINDS (the tree's rule, keep the names in the game): a kid's 3rd meal decides which of its
  3 adults it becomes.
  Mixed kid (2 different foods, e.g. sour then green): ROOT = the 1st food again (back to its
  origin), PEAK = the 2nd food again (all in on the new side), CHAOS = any other food (the wild one).
  Pure kid (the same food twice): ULTRA = that food a 3rd time (the purest; the only way to a
  LEGEND), BLOOM = a friend food (a neighbour on the circle green - sweet - greasy - spicy - sour),
  CLASH = a rival food (one of the other two).
  The sheets show which 3rd foods lead to each adult (the food icons on each adult).
  FRIENDS / RIVALS: the five foods sit on a circle, green - sweet - greasy - spicy - sour - (green).
  Neighbours are friends (classic pairs: green+sweet = matcha / fruit, sweet+greasy = donuts,
  greasy+spicy = hot wings, spicy+sour = kimchi, sour+green = pickles); the two not next to it are
  rivals. A design choice, can be changed (e.g. sweet+sour is a famous pair too).
- LEGENDS (user, 2026-10-10: "it should be more", to think about later): today only the 5 ULTRA
  adults can become legends. Idea: BLOOM adults too (10 more), or legends added in updates.
- STAGE NAMES DECIDED (user, 2026-10-10): SHO / CHU / DAI replace baby / kid / adult, for the pals
  AND the food sizes. Always shown with their level icons: Sho = level 1 (1 icon), Chu = level 2
  (2 icons), Dai = level 3 (3 icons): on the food tags, the Shop packs, the locked cards, the Pal
  Pedia and the evolution moment ("Picklet is now Chu!"). Same language as the drink levels.
  (Earlier note kept below for the options considered.)
- STAGE NAMES (the options, 2026-10-10: "baby / kid / adult" felt weird). They name both the
  pal's stage and the food size it eats (the 1-3 food icons). Options:
  a) SHO / CHU / DAI (small / medium / large, as on Japanese menus: food sizes and pal sizes at once;
     Asia first) - recommended
  b) BITE / MEAL / FEAST (food words: "Feast food", "a Meal pal")
  c) MINI / MIDI / MAXI (plain and universal)
  Mutants and legends keep their names (they are not sizes).
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

## Teaching the rules: every mechanic and WHERE the player learns it (2026-10-10)
Rule: nothing the player needs is hidden in a manual only. Each rule has a moment in the game
(a guide card, see Onboarding), a picture that keeps repeating it, and a page in the booklet for
those who want the whole map. One card at a time, shown when the rule first matters.

| Rule | Learned in the game (when) | Repeated by (always visible) | Booklet |
|---|---|---|---|
| Food decides the pal | welcome card + "Say hi" (built) | type tags on foods, pal colour = family | ch. Feeding |
| Sho / Chu / Dai, food sizes | first evolution: "Picklet is now Chu! It eats Chu food now [2 icons]" | 1-3 icons on foods, Shop, Pal Pedia | ch. Growing up |
| Locked sizes / types in the Shop | G3 (first pal that can't grow) | padlock cards + gear blink (built) | ch. Shop |
| Stars -> coins -> games / food | G1, G2, G4 | coin counter, prices on cards | ch. Coins |
| Adult kinds (ROOT/PEAK/CHAOS, ULTRA/BLOOM/CLASH) | first Dai: "Its 3rd meal decided which Dai it became." | Pal Pedia: each Dai shows its kind + the food path that leads there | ch. Evolution |
| Friends & rivals (the food circle) | first pure Chu (2 same meals): "Same food twice! A 3rd one makes it ULTRA. A friend food [circle] makes it BLOOM, a rival makes it CLASH." | the food circle drawn in the Pal Pedia header; craving bubbles point at friends | ch. Evolution (the circle) |
| Legends | first ULTRA: "An ULTRA pal! Feed it its legendary food and something amazing happens." | ULTRA's Pedia page shows the legend's silhouette + the legendary food icon | ch. Legends |
| Mutants (tech / cosmic) | first special food bought or found | special page "?" cards, Shop | ch. Special foods |
| Drinks, levels, secrets | first-drink steps a-c; first gate seen: "Needs [3 bubbles]: a level 3 Fizzy drink" | level icons on drinks, gates in levels, level menu cells | ch. Drinks |
| Moods / hunger | G9 (first time Hungry) | the pal's face + the LCD timers | ch. Care |
| Gifts (cosmetics) | G8 (first gift) | "?" cards say how: "Tilt Maze: 30 stars" | ch. Collection |

The Pal Pedia is the map: for a discovered pal it shows its food path (icons), its kind
(ROOT...), and for undiscovered NEXT pals a silhouette + the hint (layer 3 tracking below).
Status: the table is the plan; only the welcome / hatch / bonus cards and the locked-food blink
exist. To build with the guide cards (G1-G9) and the Pal Pedia pass.

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
- TO IMPLEMENT (decided 2026-10-10): the vault gate the FIZZY drink opens is a LOW FENCE (lower than
  a wall, striped top so it reads as different): a fizzy pal turns bouncy and hops it. One hop opens
  one vault (the boost is spent then, never on a level without a fence); a high fence needs the top
  fizzy drink (Ramune). Fizzy arrives with Tilt Maze (first-hour plan), with a fence vault right away.
  Walking THROUGH walls is Milky / Sturdy (cracked walls to ram): kept for the third drink.
  Prizes, better per world: first vaults = a sticker for the device's back, a pal accessory;
  middle worlds = a food reroll, a stronger drink (e.g. Ramune), a Pal Pedia hint (shows one missing
  pal's silhouette + the food leading to it); later worlds = the special foods, placed where they
  make sense (microchip in a factory / sewer world, alien goo in space), rare. A prize already taken
  shows as an open vault on the world map; replaying doesn't give it again.
  NO ball skins as prizes: the ball is the pal itself.
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

## Splash Hoops (reworked 2026-10-10: scripts/splash_hoops.gd, art in scripts/splash_art.gd)
- Look: a plastic water toy painted in code (teal water with light rays, rippled sand floor,
  coral cups and pumps), like the other toy games. Tilt nudges the balls a little.
- The pal dives along: its own sprite, small, with a diving mask and a snorkel. It drifts with
  the water and the tilt, is too wide for the baskets (it rests on top, tilt or pump it off),
  never scores, and scares the pufferfish.
- Five basket layouts: classic · upside-down triangle (6 baskets) · drifting (each basket its
  own way) · round and round (one in the centre, two circling it, two on the sides going up and
  down) · the wheel (5 on a turning wheel). All checked reachable with a random-press bot, no tilt
  (tests deleted; easy to redo). Random-bot clear time: classic ~35 s, triangle ~51 s. Right above
  a pump balls hardly ever come down from high up, so high baskets go out over the side walls
  instead (the triangle's top corners).
- LEVELS (rearrange branch, 2026-10-10; Progression v2): 45 levels in 5 worlds of 9, a table in
  splash_hoops.gd (LEVELS: layout, which baskets, still / sway, speed, seconds, pufferfish):
  1 Still Water (two 100s only, then the 200s, then the 300 with both pumps, the triangle, a
  gentle sway at the end) · 2 Drift · 3 Pufferfish · 4 Round and Round · 5 Storm (everything
  faster). Stars by the time left at the last basket: 2 stars with 20% left, 3 with 45% (STAR_2 /
  STAR_3, to tune on the phone); three stars right of the clock, each dims the moment it's lost.
  First time: straight into 1-1; after that the game opens on its level menu (LevelMenu: 3 x 3,
  press = next, hold = play, forward = next world; locked levels show a padlock). After a level:
  the result card (stars fill in, "+N coins") with NEXT / RETRY / LEVELS (forward = change, main
  = OK); time's up: RETRY / LEVELS.
- Pufferfish (worlds 3-5): swims across, OUT of the far side, and after a short pause (1.2-2.6 s)
  comes back the other way at a new depth (it used to turn round on the spot at the wall);
  swallows balls near its mouth (3 at most); bump it with the pal and it puffs up, spits them back
  out and darts off for 8 s (then comes back from the side it fled to).
- Coins: each new star is a coin (GameData.record_level); games are bought in the Games menu
  (see Progression v2). Its gift track: Splash Hoops' star milestones (Collection.REWARDS).
- Water boost (DECIDED 2026-10-10, to implement): water = "Splash", a second chance. The first
  time the clock hits 0 in a run, a wave washes over the tank and gives +10 s to finish the stage
  (once per run). Water is the ONLY drink type on offer at the start (Water → Barley tea →
  Coconut water as tiers later). Making it obvious: the droplet badge sits on the HUD from the
  start of the run; at 0 the timer turns blue, the wave rolls over from the badge, "+10" pops out
  of it and the clock refills with a splash sound; the first time ever, a short card says so
  (onboarding, first drink step c). Rejected alternative: pumps never run dry (bends water's
  "second chance" meaning). Fizzy here = stronger jets (boost table), so the 2nd drink helps both.
- Ideas: more layouts (a basket riding the pufferfish? a current that pushes sideways).

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
- DRAFT v2 (2026-10-10): 2 foods per type per stage = 30 (docs/mockups/food_drafts/foods_sheet.png;
  v1 in v1/). Kept as they are: the 8 originals + the glazed donut (*). New ones drawn in the
  originals' look (32x32, filling the box, warm muted colours, chunky texture, centred). Not in
  the game yet. Green: Broccoli, Avocado / Rice and Vegs*, Salad Bowl* / Cucumber Sushi*, Veggie
  Dumplings. Sweet: Chocolate (4 squares), Cookie / Glazed Donut*, Rainbow Jelly* / Choco Cake,
  Purin (Japanese caramel pudding; replaces Lemon Meringue so sweet stays fully sweet). Greasy: Fried Egg,
  Fries / Spaghetti*, Hot Dog* / Club Sandwich*, Cheeseburger*. Spicy: Chili Pepper, Jalapeño /
  Fire Skewer, Hot Drumstick / Fire Ramen, Curry Bowl. Sour: Lemon, Pickle / Kimchi, Umeboshi /
  Tom Yum, Pickle Jar. Rejected: Pea Pod, Spring Rolls, Lemon Tart, Lemon Meringue, Choco Parfait (too like the cake, not
  square), Hot Wings (unclear), Curry Rice on a flat plate (too wide).
  In the menu the icon sits ~3 px below the eat ring's centre and is drawn squashed
  (scale 3.62 x 3.42): centre it and use one scale when these go in.
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
  | Splash Hoops | +10 s once (DECIDED)    | stronger jets          |                      |                          | more points        |
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
  UPDATE (user, 2026-10-10): drink levels are NOT tied to the pal's age. PROPOSED instead: level 1
  of a type comes with that type's unlock; level 2 / 3 unlock with progress (star totals), then
  show up in the menu by rarity (level 1 common, 2 sometimes, 3 rare); level 3 also as vault
  prizes and in the shop. To confirm.
  Show the tier with icons, not numbers: the type's symbol 1, 2 or 3 times (Watery = 1, 2 or 3
  droplets), on the drink, the pal's boost badge and the game HUD. Light and playful, never heavy.
  Draft line-up (one new drink per type; Japanese favourites):
    Watery:      Water → Barley tea (mugicha) → Coconut water
    Fizzy:       Cola → Lemonade → Soda float
    Caffeinated: Tea → Coffee → Energy drink
    Milky:       Milk → Bubble tea → Milkshake
    Fruity:      Orange juice → Peach juice → Smoothie
  DRAFT v2 (2026-10-10, docs/mockups/drink_drafts/drinks_sheet.png; v1 in v1/): all 15 in the look of
  the 4 original drinks (Water, Cola, Energy Drink, Orange Juice: kept as they are): simple bottle /
  can / glass shapes, cylinder shading, muted colours, the originals' heavier outline, nearly full
  height. Line-up: Watery = Water* → Barley tea (the Water bottle itself, filled with amber tea:
  in Japan mugicha is the everyday "water") → Coconut water · Fizzy = Cola* → Lemonade (the Orange
  Juice glass and slice, in lemon) → Soda float (melon soda + ice cream; replaces Ramune, not known
  outside Japan) · Caffeinated = Tea (cup + saucer + tea bag; replaces Green tea) → Coffee (round
  mug) → Energy drink* · Milky = Milk (carton seen from the front) → Bubble tea (replaces the
  Yogurt drink) → Milkshake (straight glass) · Fruity = Orange juice* → Peach juice → Smoothie.
  The level (DECIDED 2026-10-10): the menu's type tag keeps its word (Watery, Fizzy, Energy, Milky,
  Fruity) and the level icons sit on the tag's top-right corner, 1-3 of them. The icons are pixel
  art (hand-placed, outlined): Watery = a blue drop, Fizzy = a bubble, Energy = a lightning bolt,
  Milky = a white drop, Fruity = a star (docs/mockups/drink_drafts/level_icons/, grids in
  level_icons.py). The same icons on the pal's boost badge and in the game HUD. Not in the game yet.

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
