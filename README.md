# KamiTomo 神友

**KamiTomo** is a pixel-art virtual pet for the iPhone, played on a little handheld console drawn
on screen. You raise a pal: what you feed it decides who it grows into, and its drinks give it the
boosts that open the secrets of the games you play together.

Made by Kobaya Tech.

## The game

- **Pals.** Over 120 pals to discover in the Pal Pedia. Each meal moves the pal along its own
  evolution path, so what you choose to feed it decides who it becomes.
- **Two clocks.** The console's screen shows the meal clock, which paces the pals, and the drink clock,
  which paces the boosts.
- **Drinks and boosts.** Watery, fizzy, caffeinated, milky and fruity drinks give the pal a boost
  (Splash, Fizz, Focus, Sturdy, Lucky). A boost helps in a game and opens the game's secrets.
- **Games.** Each game has 6 worlds of 9 levels, and you earn 1 to 3 stars on each level:
  - **Splash Hoops**: the two buttons.
  - **Tilt Maze**: tilt the phone to roll the pal through a maze.
  - **Pal Prix**: race a car, a boat and a plane.
  - **Paper Sumo**: buttons, tilt and rhythm.
  - **Top Spin**: everything at once.
  - **Tummy Tunes**: timing on three buttons (coming next).
- **Stars and coins.** Each new star is a coin. Coins buy games, food packs, special foods, drink
  levels, stickers and cases in the Shop.
- **Special foods.** These are hidden in the games' secrets. The rarest pals need them.
- **Collection.** Stickers, dress-ups, gut decor, skies and cases. You get them as gifts from
  the games, the Pal Pedia milestones and the Lucky Pinch claw.
- **The console.** Double-tap the logo to turn the device over and see its back and its case. On
  the first launch the console comes out of its retail box.

No points, no sickness, no game over for the pet: care is rewarded, never punished.

## Building

- Godot **4.4**. Open `project.godot` in the editor and run it.
- Debug builds start on a dev launcher (`scenes/dev_launch.tscn`) with these options:
  - **FULL BOOT**: the unboxing and the boot, as a new player sees them.
  - **ALL UNLOCKED**: every game, level, item, sticker and case, with a random pal.
  - **BOOT + PROGRESSION**: play from zero on a save that persists (**START OVER** wipes it).
- iOS: export with the "iOS" preset. The scene-lifecycle plugin in `ios/plugins/scene_lifecycle/`
  is needed for iOS 27.
- Before a release, turn off the testing switches (`PetState.FRESH_START_ON_LAUNCH`,
  `GameData.DEBUG_UNLOCKED`, the `RESET_*_ON_LAUNCH` flags, `Unboxing.SHOW_EVERY_LAUNCH`, ...).

## Project map

| Path | What's there |
|---|---|
| `scripts/` | the game's code (`scripts/base_minigame.gd`: what every game shares, levels, stars, lives) |
| `scenes/` | the scenes, the minigames in `scenes/minigames/` |
| `tools/art/`, `tools/audio/` | Python scripts that draw art and synthesise sounds |
| `tools/qa/shoot.sh` | screenshots and autopilot runs of any game and level |
| `tools/design/pacing.py` | the pacing model behind every price and unlock |
| `docs/progression.md` | how the whole game fits together: games, pals, coins, boosts |
| `docs/ideas_roadmap.md` | ideas and what comes next |
