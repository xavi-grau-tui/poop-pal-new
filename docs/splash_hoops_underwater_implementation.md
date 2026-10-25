# Splash Hoops underwater backgrounds and W-floor

**Review date:** 2026-10-23  
**Project:** NEW SHRINE development build (`/private/tmp/pooppal-shrine-prototype`)  
**Purpose:** record the underwater backgrounds, the themed W-shaped floor, its moving accents, QA and the phone installation so another developer can inspect or reproduce the work.

## Scope and invariants

- This work applies to Splash Hoops in the NEW SHRINE test build. It does not add the shrine to Splash Hoops gameplay; the six game captures are made without `shrine=1` or `new_shrine=1`.
- The lower foreground is the game's existing two-pump funnel floor. Its W-shaped contour is produced by `SplashHoops.floor_at()` in `scripts/splash_hoops.gd`. It is a gameplay surface, so keep its coordinates, outline, collision behavior and relationship to the two nozzles fixed.
- The six generated floor materials are sampled only inside that existing contour. They do not define a new shape or alter physics.
- The normal shrine app remains a separate bundle. The installed test bundle is `com.xavigrau.pooppal.shrinetest`.

## Art assets

### Six underwater backgrounds

Installed project files:

- `textures/minigames/splash/new_shrine/lagoon.png`
- `textures/minigames/splash/new_shrine/sunset.png`
- `textures/minigames/splash/new_shrine/reef.png`
- `textures/minigames/splash/new_shrine/night.png`
- `textures/minigames/splash/new_shrine/storm.png`
- `textures/minigames/splash/new_shrine/deep.png`

Each is a 317×316 pixel-art background. They contain no shrine. Most scenes are underwater; sunset and night retain upper-surface/sky details. Storm rain streaks were removed from the static art so runtime rain owns that motion.

Original ImageGen outputs, retained in the Codex generated-images folder:

`/Users/xaviergrau/.codex/generated_images/01a1634f-3e57-7e80-b372-9dd38c5925cd/`

| World | Output file |
| --- | --- |
| Lagoon | `exec-4b742622-31a2-4243-beaf-7e8ca35574e2.png` |
| Sunset | `exec-5cee29a7-d424-4a34-8c5b-38477cdc019c.png` |
| Reef | `exec-295a7dd6-fd2c-4d9d-a745-f4bab503e5b8.png` |
| Night | `exec-966c2ce9-cf7d-4495-8019-996072a560c5.png` |
| Storm, rain-free static art | `exec-ac69845f-fa00-4f6b-be9b-56da00366ab9.png` |
| Deep sea | `exec-424df075-cf3e-491d-80b5-447f8a500a27.png` |

### Themed W-floor materials

ImageGen atlas source:

`/Users/xaviergrau/.codex/generated_images/01a1634f-3e57-7e80-b372-9dd38c5925cd/exec-b9f5ca8c-494c-4c0c-b670-ea7ec8973efc.png` (1254×1254).

The source is a 3-column × 2-row atlas, ordered lagoon, sunset, reef / night, storm, deep sea. The six 394×394 project crops are in `textures/minigames/splash/new_shrine/floor/` with matching world filenames. Crop offsets in source coordinates were:

| Material | x | y | width × height |
| --- | ---: | ---: | --- |
| Lagoon | 18 | 120 | 394 × 394 |
| Sunset | 430 | 120 | 394 × 394 |
| Reef | 842 | 120 | 394 × 394 |
| Night | 18 | 740 | 394 × 394 |
| Storm | 430 | 740 | 394 × 394 |
| Deep sea | 842 | 740 | 394 × 394 |

At runtime `SplashArt.tank_layers()` resizes each material to 317×128 using nearest-neighbor sampling. That avoids soft interpolation and makes the artwork fit the existing 317-pixel foreground sprite. It reads texture x from the full sprite width and y from depth below the floor lip, so the texture does not repeat in vertical seams.

## Runtime implementation

### Theme selection and front floor

- `scripts/splash_art.gd`: each `THEMES` entry now names its `background`, `floor_texture`, and `floor_fx` color.
- `SplashArt.tank_layers()` paints the generated background into the existing back panel, behind the game front and moving scene layer. The top plastic band and foreground continue to occlude it normally.
- The tank front loop still uses `floor_at(wx)` for every pixel. It retains the original two-pixel dark outline and one-pixel highlight lip; below that, it samples the current world's generated material. If a theme has no material, the original procedural `_sand()` remains the fallback.
- `scripts/splash_hoops.gd`: `floor_at()` remains unchanged:

  ```gdscript
  func floor_at(x: float) -> float:
      var d := minf(absf(x - NOZZLES[0]), absf(x - NOZZLES[1]))
      return FLOOR_Y - FLOOR_SLOPE * d
  ```

  Current geometry constants: `NOZZLES = [237.0, 713.0]`, `FLOOR_Y = 866.0`, `FLOOR_SLOPE = 0.42`. Do not adjust these as part of visual floor work without separately checking physics/colliders.

### Animated scenery and draw order

- Existing `SplashArt.SceneLife` remains the moving back-scene layer: lagoon fish and seagrass; sunset clouds, sun reflection and gulls; reef turtle, fish and seaweed; night stars and jellyfish; storm clouds, waves and lightning reflection; deep-sea tentacles.
- New `SplashArt.FloorLife` adds five gentle bubble lanes around the lower W and seven moving theme-colored glints/ripples within the floor fill. It gets its floor coordinate function from `floor_at()` and its tint from `floor_fx`.
- Node order in `SplashHoops._create_static_nodes()`: back panel → `SceneLife` and other back effects → tank front → `FloorLife` → nozzles → baskets/balls/pal. This keeps new floor motion behind the interactive toy pieces.
- Sunset ambient particles begin below y=275 so the upper sunset remains readable; other worlds begin ambient particles at `BAND_Y`.

## Review captures

All six-world captures were rendered on desktop without shrine flags:

`/private/tmp/splash-floor-final-preview/`

- `g2_l01.png` — lagoon
- `g2_l10.png` — sunset
- `g2_l19.png` — reef
- `g2_l28.png` — night
- `g2_l37.png` — storm
- `g2_l46.png` — deep sea

The earlier `/private/tmp/new-shrine-splash-six-final/` capture set used `new_shrine=1` and showed the shrine in front of gameplay. Do not use it as the Splash Hoops composition reference.

QA command used:

```sh
/Applications/Godot.app/Contents/MacOS/Godot \
  --windowed --resolution 1100x900 --audio-driver Dummy --path . \
  res://tools/qa/capture.tscn -- \
  game=2 levels=1,10,19,28,37,46 wait=5 out=/private/tmp/splash-floor-final-preview
```

All six levels rendered and produced screenshots without script errors. The QA runner prints renderer/ObjectDB resource-leak warnings during process shutdown; these did not stop captures. A visual check also showed the W floor style changes by world while its contour remains in the same position.

## Build and device install

Target: `iOS Shrine Test` in `export_presets.cfg`; Xcode scheme/target `PoopPalShrine`; bundle ID `com.xavigrau.pooppal.shrinetest`.

Phone: `iPhone de Xavi`, iPhone 15 Pro Max, UDID `00008130-000115C03661001C` (paired/available when installed).

Reproduction commands from the repository root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless --path . --export-debug 'iOS Shrine Test' \
  build/ios-shrine-test/PoopPalShrine.xcodeproj

xcodebuild -quiet \
  -project build/ios-shrine-test/PoopPalShrine.xcodeproj \
  -scheme PoopPalShrine -configuration Debug \
  -destination 'id=00008130-000115C03661001C' \
  -derivedDataPath build/shrine-prototype-derived \
  CODE_SIGN_STYLE=Automatic build

xcrun devicectl device install app \
  --device 00008130-000115C03661001C \
  build/shrine-prototype-derived/Build/Products/Debug-iphoneos/PoopPalShrine.app

xcrun devicectl device process launch \
  --device 00008130-000115C03661001C \
  com.xavigrau.pooppal.shrinetest
```

Build succeeded, the test bundle installed, and `devicectl` launched it. The app's `DevLaunch` screen defaults to/highlights NEW SHRINE when no saved choice exists; it persists the last dev choice in `user://dev_launch.json`. The normal app uses bundle ID `com.xavigrau.pooppal` and was not overwritten. Xcode emits existing warnings for empty photo-library/camera/microphone usage descriptions.

## Files to inspect first

- `scripts/splash_art.gd` — theme asset map, generated floor texture sampling, scene animation, `FloorLife`.
- `scripts/splash_hoops.gd` — unchanged W geometry, theme wiring, draw order and ambient setup.
- `textures/minigames/splash/new_shrine/` — six background PNGs and six floor materials.
- `tools/qa/capture.gd` — screenshot harness; omit `new_shrine=1` and `shrine=1` for game captures.
- `shrine-prototype.md` — broader chronological prototype notes.

The working tree contains many other pre-existing NEW SHRINE and app changes. This handoff does not imply those are part of the Splash Hoops feature, and they were not cleaned or reverted during this work.
