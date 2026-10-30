# RC Prix · Sky: plan and state

Levels 19–27, the plane through rings over the countryside at noon. Behind the dev launcher's **RC ART**
switch (FX for the light effects), like the Garden and the Lagoon; the old look stays switchable until the
final clean-up (`docs/rcprix_art_process.md`, "Still open").

**State (2026-10-30): done and approved by the user**, apart from the polish below. Code: `scripts/rc_sky.gd`
(`RcSky`: textures, rings, stand clouds, the ground, the drifting clouds, balloons) and its hooks in
`scripts/rc_racer.gd` (`Ring`, `SkyDock`, `Crowd`, `SkyClouds`, `MillSails`, `_sky_ground`, `_sky_front_start`,
`_sky_clouds_start`). Art: `textures/minigames/rcprix/sky/`, all made by
`tools/art/rcprix_sky_from_sources.py` from the designer's paintings (see "How the art is made").

## Kept from the original (the user loves it)

- The ground's **diagonal field grid**, pale and hazy, far below (PARALLAX 0.55), with the original's noise
  cloud shading on it.
- The **wind streaks** (`AirFx`) turning with the plane.

## Done

| Piece | What it is now | Where |
|---|---|---|
| Rings | Glossy red and cream, gold, grey, at every size the levels use (86–124 world px, by 2), each scaled from the painting. Tall rings are the wide ones transposed; turned 180° for courses going right or down, so the thick near side is always over the plane as it flies in. Drawn NEAREST (no hairline at the cut) | `RcSky.ring_half`, `Ring` |
| Rings, gold | **GOLD PASS** (default): all red, gold on the chime's own frame as the plane flies through, a longer pop once it's out. The dev launcher's RINGS switch keeps the old GOLD NEXT | `Ring` state 5, `DevLaunch.rc_gold_pass` |
| Stands | The Garden's stand with a light-blue canopy, on a cloud built from the drifting clouds' paintings (big ones along the bank, past the stand on every edge, a row of puffs over the south edge for depth; whole per length, never cut). Front views preferred; the start moved to a horizontal straight with room for a front stand | `RcSky.stand_cloud`, `Crowd._draw_sky_cloud`, `_sky_front_start`, `SKY_STAND_GAP`, `SKY_START_NEAR` |
| Start | The designer's **cloud runway** (front view, left to right; mirrored for races starting to the left), 114 × 110 game px, on drifting clouds (big under it, puffs over its front edge), checkered line on the start line; an orange **windsock** (4 frames, fast, opposite way) on the runway near its back corner behind the plane | `SkyDock._draw_art`, `platform_e/_w`, `windsock_0..3`, `RcSky.SOCK_FOOT` |
| Ground | The designer's 8 field paintings turned to the grid's angle while big, then put on the grid; hedges and tree lines cut to each field edge; the river strip along the original's winding path; side-view stone bridges where it crosses a hedge; decor (farms, copses, haystacks, ponds, villages, church, windmills with turning sails). Softened and hazed by `GROUND_SHADER` (paler, like the original) | `RcSky.ground`, `_sky_ground`, `MillSails` |
| Drifting clouds | The designer's 6 cumulus in two layers between the plane and the ground (parallax 0.72 / 0.86, the nearer row 10% bigger), each its own drift. **Solid, as real clouds** (2026-10-30, the user): distance shows as paleness, not transparency (lower row eased 60% towards the haze, upper 40%). Cut to the playing area, never over the dark frame. Pale shadows drift on the ground | `SkyClouds`, `CLOUD_DEPTH / PALE / SIZE / ALPHA` in `rc_racer.gd` |
| Plane shadow | Half size on the ground (it's far below); bigger on the drifting clouds (nearer), only on them | `_follow`, `SkyClouds.shadow` |
| Balloons | Levels 25–27, the designer's paintings in blue and pink only (the user) | `RcSky.balloon` |

Unused now, kept for reference: the drone pad pieces (`pad_*`, `rotor_*`, `light_*`, round 1) and the concept C
runway trial. The old code drawing (steel deck, rotors, round stand cloud) is the fallback when RC ART is off.

## Still to do (polish, not started)

- [ ] Wind streaks, contrail, ring sparkles and the guide sparkles redrawn on the 2 px art grid (same behaviour).
- [ ] Optional: the designer repaints the runway deck at its stretched 114 × 110 shape (today the painting is stretched to fit).
- [ ] Optional, asked about early: bird flocks lower down (own parallax and shadows).
- [ ] At the end of all worlds: make the new art the default and remove the RC ART switch (with the Garden and the Lagoon).

## How the art is made (what worked)

The designer is good at high-resolution **ImageGen paintings** (transparent background, no glow, light from the
top left) and weak at hand-made pixel art; their first rounds were scripted shapes and the user rejected them
("pretty awful"). So:

1. The designer paints big into a `*_sources/` folder here, with a README.
2. `tools/art/rcprix_sky_from_sources.py` puts them on the game grid with `tools/art/rcprix_pixelate.py`
   (scaled by area, premultiplied, alpha cut at 50%, small palette, lone pixels dropped). Flags: none = rings,
   stand clouds, ground; `--fields` ground only; `--things` drifting clouds and balloons; `--stand-drift` the
   stands' clouds from the drifting clouds; `--runway` the start runway and windsock; `--platform` the concept C trial.
3. New PNGs: delete their `.godot/imported/` entries, run `Godot --headless --import`, then QA shots
   (`tools/qa/shoot.sh game=0 levels=19..27 rc_new_art=1 rc_fx=1`) and the autopilot check
   (`FAST=1 HEADLESS=1 ... until=done wait=120`: level 25 must still give 3 stars in 44.6 s).

Exact pieces (sizes, positions, perspective) still come from our guides: `guides/`, `ground_guides/`
(`tools/art/rcprix_sky_round1_guides.py`, `rcprix_sky_ground_guides.py`).

## Folder

- `BRIEF_ROUND_1.md`, `BRIEF_GROUND.md`: what the designer was asked.
- `*_sources/`: the designer's paintings (round 2, ground, clouds, balloons, platform); `platform_concepts/`,
  `style_samples/`, `reference/`, `round1_paint/` (superseded).
- `current/`: the original look; review pictures (`review_round1_vs_garden.png`, `stand_clouds_old_vs_drift.png`,
  `drifting_clouds_now_vs_paler.png`).

## The user's decisions, in order

Pastel countryside, the diagonal grid kept · stands from the front, two at the start · rings and clouds as
paintings, not scripted shapes · gold on pass, on the chime · ground paler like the original · plane shadow
smaller · drifting clouds paler and 85%, then solid (paleness only) · the stands' clouds from the drifting
clouds, past the edges · no military pad: a cloud runway seen from the side, the former pad's size +10%, the
windsock on it behind the plane · windmill and bridge in perspective, no pointless bridges · blue and pink
balloons · rings turned for right / down courses · the plane's shadow on the clouds.
