# Shrine Prototype

This document tracks the shrine and KamiTomo prototype across conversations.

Last updated: 2026-10-22.

## Isolation and test app

- Work is in the `/private/tmp/pooppal-shrine-prototype` worktree on branch `shrine-prototype`.
- The worktree was based on the same starting commit as `yokai-migration` and includes a snapshot of its existing uncommitted work. New edits here remain isolated from the original `/Users/xaviergrau/Documents/PoopPal Godot/poop-pal-main-kiro` checkout.
- Do not merge or commit this work into `yokai-migration` without an explicit request. No commits have been made for this prototype.
- iPhone test bundle ID: `com.xavigrau.pooppal.shrinetest`. It is a separate app install, so it does not replace the regular app.
- The Xcode project is generated at `build/ios-shrine-test/PoopPalShrine.xcodeproj`; the build uses the existing Apple Development signing profile.
- Dev Launch includes a `NEW SHRINE` option. Use this option to view the selected frame in the app.

## Design direction agreed so far

- The hokora / spirit house replaces the gut in the pet view and must preserve the existing room's usable space and screen placement.
- Keep the curved roof silhouette the user selected. The roof triangle should not have the plant centerpiece; small flowers can be left out for now, while a few leaves are acceptable.
- Keep the stone shelf / base and the offering table. The spirit should read clearly inside the opening and sit near the center of the phone screen.
- The frame should be pale and warm, with a stronger outline around the front face, similar in weight to the spirit's outline.
- The overall drawing should match the pet and aura: deliberate chunky shapes, a consistent pixel unit, a restrained palette, and less tiny surface detail. Improve the design and pixel rhythm instead of simply making the whole image blurrier or more pixelated.
- The rope ornament on the left and paper lantern on the right are app items. Preserve their current rope swing / lantern pendulum behavior, including gravity and phone tilt, while adapting their artwork to the shrine's pixel style.
- The shrine should feel three-dimensional when the phone tilts. The visible side, roof thickness, underside, and stone thickness need to be designed as coherent faces. Leaves and other front decoration should stay on the front surface rather than continuing through the model's depth.
- Updated model direction: make the roof and the plain temple wall/shell the actual 3D geometry, with the wall depth continuing around the spirit-room opening as in the Yokai Migration model. Give the roof's top and side/depth faces their own low-resolution pixel-art textures, designed from the same tile shapes, palette, outline, and light direction as the front sprite. Map those textures onto the 3D faces so they read as the same roof when the phone tilts, with the pattern wrapping coherently across the eave and roof thickness.
- Treat roots and leaves as a small number (about three) of separate 2D parallax layers behind the shell; selected root tips may sit on 2D foreground layers across the opening, but keep most of the room clear for the spirit. The opening is a viewing aperture, not a crop mask for the architecture: roof supports and side beams can continue into the aperture and should have visible depth faces that reach into the room. Design their ends and inside faces deliberately so the current square opening does not cut roots or produce abrupt 90-degree beam ends.
- Center the shrine frame in the pet-view window while keeping the spirit independently near the screen center. Adjust the shelf/table only as needed to keep the spirit comfortably supported and preserve the room.
- Try the name `KamiTomo` on the prototype console using the existing HaraTomo wordmark's lettering, outline, shading, and spacing. The Japanese subtitle should read `神友`: `神` (kami) followed by the existing `友` (tomo) artwork.

## Current prototype state — restored forest frame

- User rejected the structural redesign and requested the previous shrine appearance back before making further changes one at a time.
- `NEW SHRINE` restores the selected curved roof and winding root front frame, the original dark interior, and full-silhouette depth layers. The stone shelf, offering table, room opening, and ornament gravity behavior are retained.
- Zoom is `0.95` around grid row `2.5`, without the experimental 44-unit downward shift. The room remains `Rect2(31, 33, 49, 44)`.
- `tools/art/build_hokora_frame.py` regenerates the forest frame from the chosen source at a 120-cell pixel grid, with the pale palette and original shrine interior. Experimental plain posts, diagonal braces, projected roof faces, separate root planes, and pale wall are no longer used.
- The rejected experiment was backed up to `/private/tmp/shrine-rejected-shell-pass/` before restoration. Its phone capture is `/private/tmp/shrine-final-installed.png`; this is historical, not the current intended design.
- KamiTomo logo fixes remain: the lowercase i has a 17-pixel stem and shared baseline; 神 uses the bold W6 face with the original 友 styling. Original HaraTomo assets remain unchanged.
- Shrine boost badges remain hidden, including the drink animation; aura and boost behavior remain enabled.
- The isolated app is named `Shrine Test`, bundle ID `com.xavigrau.pooppal.shrinetest`. Its main scene is the dev launch menu with `NEW SHRINE` available.
- Packaging fault discovered during the rejected pass: Xcode reads the ROOT `build/ios-shrine-test/PoopPalShrine.pck`, not the nested pack previously exported. Always compare the exported pack with the embedded app pack before installation.
- Restored build exported, built successfully, byte-compared against the embedded app pack, and installed on the paired iPhone on 2026-10-22.
- No commits or changes to `yokai-migration`.

## Verified packaging path

Export with `Godot --headless --path . --export-pack "iOS Shrine Test" build/ios-shrine-test/PoopPalShrine.pck`.
Build `build/ios-shrine-test/PoopPalShrine.xcodeproj` with scheme `PoopPalShrine`, Debug configuration, and derived data path `build/shrine-prototype-derived`.
Before installing, compare the export pack to `build/shrine-prototype-derived/Build/Products/Debug-iphoneos/PoopPalShrine.app/PoopPalShrine.pck` using `cmp` or SHA-256. Install that app with bundle ID `com.xavigrau.pooppal.shrinetest`.

## Next work

1. Review the restored forest shrine on the phone.
2. Choose one visual adjustment with the user, apply it, and review before making the next change. Earlier structural ideas above remain future direction, not authorization to repeat the rejected redesign wholesale.
3. Preserve the separate branch/app and ornament physics throughout.

## Incremental adjustment after rollback

- Move NEW SHRINE down seven grid cells to balance the roof and base margins.
- Increase front artwork sampling from 120 to 160 cells, retaining the selected roof/roots and pale 28-color palette with nearest-neighbor pixels.
- Raise the stone slab and offering table four grid cells together, including all depth copies, offerings and cup positions. Ornament physics are unchanged.
- These changes apply only to NEW SHRINE; no commits or migration edits.
- Export and Xcode build completed; embedded pack byte-matched the export, and the updated separate app was installed on the paired iPhone. Visual review of this incremental pass is pending.

## Stray background pixel cleanup

- Found low-alpha residue in the source frame (including alpha 1–5 pixels). The depth outline promoted these faint specks into opaque dark marks outside the shrine.
- Generator now thresholds source alpha at 128 for crisp pixel coverage and explicitly preserves the cleaned silhouette alpha on the rear outline. Regenerates front and both side textures together.

## Roof depth outline refinement

- NEW SHRINE roof depth uses a single muted wood color instead of repeating blurred tile bands. Its depth silhouette closes one-cell nicks, keeping crisp pixel steps.
- Increased NEW SHRINE depth slices from 20 to 80 (about one source pixel per depth step), removed per-slice shade changes, and narrowed the rear outline. Front artwork, layout and ornament physics remain unchanged. Original SHRINE retains its 20-slice shading.
- Roof refinement built and installed in the separate iPhone app; embedded pack matched the export. User tilt review pending. No commits.

## Incremental flat outer wall pass

- User approved keeping the roof and requested plain outer walls behind the unchanged front roots/leaves, working incrementally.
- Changed only the generated depth silhouette below the roof: straight plain wood walls, a connecting upper beam, and a full-depth structural plinth/feet. Roots and foliage now exist only on the current front sprite, rather than repeating all the way to the back.
- Approved roof depth pixels and front artwork are retained. Existing inner room, shelf/table depth, placement, logo and ornament physics remain intact. Additional shallow decoration layers are deferred until review of this first step.
- Previous generator and depth textures backed up to `/private/tmp/shrine-before-flat-walls/`. No commits; migration untouched.
- Export/build succeeded; packaged content byte-matched the export. Installed in the separate Shrine Test iPhone app for user tilt review.

## Front-only natural opening contours

- User approved the image-generation sketch of complete column caps and root curves overlapping the room edge, explicitly for the first/front layer only.
- Removed the rectangular aperture erase from the front artwork generator. The original source already has complete caps, supports and winding root contours around a transparent opening; these are now retained instead of being chopped by ROOM_OPEN.
- Plain depth walls/base, approved roof depth, room dimensions, ornaments and placement remain unchanged. No new decoration is extruded into the rear layers.
- Previous front and generator saved in `/private/tmp/shrine-before-front-overlap/`. No commits or migration changes.
- Front artwork preview inspected; export and build completed, embedded pack matched export, and app installed on paired iPhone. Phone composition review pending.

## Two root-and-leaf depth planes

- Added two distinct transparent sprite pairs using built-in image generation: `textures/pet/shrine_new/roots_middle.png` and `roots_rear.png`. Both are copied into the prototype workspace.
- Middle plane at depth -18, rear plane at -55 (front +20, back -56). Each is one flat sprite sorted among the plain wall slices, with nearest pixel sampling. Middle is shaded to 82%; rear artwork has a darker walnut/olive palette, shaded to 90%.
- Front frame, roof, plain walls, shelf and ornament gravity remain intact. The room renders ahead of these external decoration planes, keeping the spirit clear.
- Generation prompt specification: square transparent canvas; only left/right winding roots and sparse moss leaves, no architecture; top 34% and central 34–68% empty; roots approximately y=36–88%; match reference front's chunky 160-grid pixel style. Middle: slightly darker tan, fuller forked roots, alternate leaf heights. Rear: different narrow fork/S curves, sparse leaves, darkest walnut/olive. Built-in imagegen used, not CLI.
- No commits or migration edits.
- Export and Xcode build succeeded; embedded pack byte-matched the export. Installed on the paired iPhone as Shrine Test. User tilt review of spacing/visibility remains pending.

## Root plane perspective and wall overlap correction

- Middle decoration now 90% size, rear 80%, each scaled toward its base so the feet stay planted and the shapes tuck behind the front silhouette at neutral tilt.
- Increased darkening: middle brightness 62%, rear 65% of its already darker source palette.
- Added a shader mask using each plane's transformed shrine coordinates to prevent decoration from drawing across the solid side-wall columns. Also discards faint alpha residue.
- Phone capture before this pass returned a black screen, so it provided no usable visual diagnosis. User review of the installed perspective/occlusion is still needed.
- Export/build completed and embedded pack matched. Installed in separate Shrine Test app for tilt review. No commits; migration untouched.

## Wall-attached root outlines

- Replaced wall-column masking (which visibly cut through the roots) with independent left/right AtlasTexture sprites. Original generated textures are unchanged.
- Each sprite's inner extent is anchored to its wall's outer edge (grid x=24 or 87), with depth displacement identical to the corresponding wall slice. Root widths are reduced to fit beside the structure; height remains 90%/80% and previous darkening is retained.
- Roots keep full contours and base anchors. Shader now only removes faint alpha, never cuts against a wall rectangle. No front/roof changes.
- Export and Xcode build succeeded, embedded pack matched, and installed on the paired iPhone. Tilt/outline review pending. No commits or migration changes.

## Root sprites tucked against wall

- User reported detached hedge-like roots. Cause: aligning the extreme transparent sprite bounds to the wall's outside edge positioned the actual contours too far outward; sorting them in front of the wall also made overlap unnatural.
- Repositioned left/right sprite extents to overlap the wall by about four grid cells from its inner side. Sort them behind wall slices at matching depth so the wall occludes the overlap and the roots meet the opening edge. Their per-layer tilt depth, scale, and darkness are unchanged.
- Updated app pack byte-matched export, Xcode build succeeded, and the revised app is installed and launched on the paired phone. User visual/tilt review remains necessary.

## Root planes turned onto the shrine sides

- User clarified the root cards must meet the wall at 90 degrees. Replaced screen-facing sprites with textured `Polygon2D` planes whose vertical axis follows the jamb and whose width axis follows the shrine's front-to-back depth.
- Middle and rear roots occupy separate shallow depth spans (38 and 28 parallax units) at their corresponding wall depths. Polygon corners are projected from tilt every frame, so the planes sit flush and open into view as the phone tilts; neutral view is edge-on.
- The original left/right root textures remain separately anchored beside the jambs, darker at depth and nearest-filtered.
- Godot export and Xcode build succeeded, embedded pack matched, and 90-degree side-plane version installed and launched on paired iPhone. User tilt review remains pending.

## Gentle root overlap and spirit placement

- Added a shallow two-to-three cell pixel curve at the front root edges where they meet the room opening. It tapers at both ends and is only on the front artwork; roof and depth layers are unchanged.
- Lowered the spirit by 1.5 grid cells in NEW SHRINE only.

- Corrected the initial root extension after preview showed it had followed the straight post edge. The generated front now extends the actual inward root contours by at most two logical cells with a tapered curve. Spirit lowered by 1.5 grid cells.
- Rebuilt and installed on the paired iPhone after byte-comparing the embedded PCK. No commits; `yokai-migration` untouched.

## Revert of incorrect front-root edit

- User clarified the crop: soften the cut at the inner square edge by continuing the front root slightly into the opening, and show a temple column behind it.
- Reverted the prior extension (it followed the straight post edge) and reverted the 1.5-cell spirit shift. Regenerated baseline front art; no new design installed pending sketch review.
- Reverted baseline exported, built, package-compared, installed and launched on the phone. The new concept remains uninstalled.
- Imagegen preview: `/Users/xaviergrau/.codex/generated_images/01a1634f-3e57-7e80-b372-9dd38c5925cd/exec-4d7656f4-9c6d-428f-ab97-cec076d0961a.png`. Prompt direction: continue the existing root edge 2–3 chunky cells into the dark opening with a gentle rounded curl; show a straight outlined temple column continuing behind it; root remains foreground; preserve the close crop, palette and pixel style. Built-in imagegen edit mode used.

## Paired root curls, backing columns, and simpler beam detail

- Applied the approved sketch on both sides: the front root tips continue up to two logical cells into the opening with a taper that follows the existing contour.
- Extended the flat wall columns a few cells inward behind the roots so they read as temple posts behind the front roots.
- Removed the small circular emblem from the center plaque and chamfered the upper roof-cap corners by one pixel cell.
- Spirit remains at its previous position; the recent experimental spirit shift stays reverted.
- Front artwork preview showed the center mark removed before packaging. Export/build succeeded, embedded pack byte-matched, and build installed/launched on paired iPhone. On-device capture: `/private/tmp/shrine-ornament-update.png`.

## Rollback requested after paired-root and plaque pass

- User rejected the installed paired-root/column/plaque edits. Reverted generated front art to the chosen source, restored original plain wall widths, and removed all last-pass pixel edits to the central plaque and roof cap.
- Alignment finding: at runtime `PetView` is animated to x=0. The shrine inherits `Intestine-front` x=523.187, while console/window center is approximately x=539.902; baseline offset is -16.715 scene units. `front.position = tilt * FRONT` adds up to 20 scene units of lateral shift. Centering should be handled explicitly for NEW SHRINE after visual review.
- New root/beam concept to be shown as an image before any implementation or installation.
- Revised imagegen preview for review: `/Users/xaviergrau/.codex/generated_images/01a1634f-3e57-7e80-b372-9dd38c5925cd/exec-175bb881-d4ad-48ab-9e8c-ab420ff24613.png`. This places small inward bends at the mid-height root cut on both inner posts, with tan column visible behind, and shows a plain center plaque plus subtly softened top block. It is a concept sketch, not an exact sprite patch; imagegen changed some unrelated pixels. No part of this preview has been implemented or installed.
- Controlled full-front sketch: `/private/tmp/shrine-full-controlled-sketch.png`. Built from the existing front sprite with only mirrored root/column transition marks added; intended as a local shape preview. Not installed.

## Precise asset preview rendered in Godot

- Preview captured from the real app scene using the existing QA capture tool and a temporary runtime texture override. No generated whole-scene artwork is used.
- Scratch files: `/private/tmp/shrine-precise-preview/art.py`, `layout.gd`, `front-edited.png`, `front-preview.png`; screenshots `before.png` and `after.png` in that directory.
- Root/column boundary edits use the original 160-cell art grid. Beam-end motif removed and cap narrowed by one cell per side. Source texture remains untouched; changes are masked onto a temporary copy.
- Exterior frame width increased about 4% using an outward mapping with fixed inner opening coordinates. Interior node scale remains `(0.95, 0.95)`.
- At neutral tilt, roof-tip midpoint and screen center both measure x=539.902 in PetView coordinates. Pet moved down 22 scene units.
- QA uses a tiny nonzero tilt override because exactly `(0,0)` re-enables mouse input; this avoids mistaking the cursor's tilt for alignment error.
- Final screenshot: `/private/tmp/shrine-precise-preview/after.png`. Preview only; no production asset replacement, phone installation, or commit.

## Splash Hoops underwater backgrounds in NEW SHRINE test branch

- Full handoff for another reviewer, including art-source IDs, exact crop mapping, W-floor geometry/draw order, QA commands and device install details: `docs/splash_hoops_underwater_implementation.md`.
- Added six generated pixel-art scene backgrounds for Splash Hoops: lagoon, sunset, reef, moonlit pond, storm and deep sea. The water scenes remain open in the center for gameplay; sky details stay toward the top where appropriate.
- Kept moving scene elements on separate runtime layers: fish and seagrass, turtle/reef life, sun and reflection shimmer, moon glow/jellyfish, storm rain/lightning, and deep-sea tentacles. Cleaned static rain streaks from the storm background so the game rain animation owns that motion.
- `SplashArt.tank_layers` now loads per-world backgrounds and maps the entire scene below the tank's top plastic band. Sunset underwater ambience begins below its surface line.
- The first six-world QA captures used `new_shrine=1` and incorrectly showed the shrine over gameplay; discard those as a presentation check. Re-captured without shrine flags at `/private/tmp/splash-review-no-shrine/`.
- Confirmed Splash Hoops uses its original W-shaped sand/funnel floor, generated by `floor_at()` and drawn in the tank front layer. Its coordinates and shape are unchanged; the per-world art stays behind it. No shrine is rendered in these gameplay captures.
- Generated a six-material atlas with ImageGen and cropped it to six project textures under `textures/minigames/splash/new_shrine/floor/`. The W silhouette now uses a distinct lagoon, sunset, reef, night, storm or deep-sea pixel texture while preserving the original outline and collision geometry.
- Added `SplashArt.FloorLife`: small themed bubbles rise near the W valleys, with moving sand glints/ripples drawn above the floor and behind baskets, balls and pal.
- Previewed the six worlds without the shrine overlay at `/private/tmp/splash-floor-final-preview/`; no script errors during play capture. Godot reports existing renderer/resource leak warnings only when the QA runner exits.
- Refined the puffer's calm and startled pixel poses in `scripts/splash_art.gd`. The calm fish has a more distinct tail/fin silhouette and better shading; the startled fish is rounder with denser spines, a cream belly and a clearer mouth. `PUFFER_R`, `PUFFER_S`, movement, facing, eating limit, collision, spit-out and flee timing in `scripts/splash_hoops.gd` are unchanged.
- Refreshed the dedicated iOS Shrine Test export, built and installed `com.xavigrau.pooppal.shrinetest` on iPhone 15 Pro Max, then launched it. The normal shrine app and option remain separate.
- For the Splash Hoops game card, generated `textures/menus/splashhoops_new.png`, an edit of the earlier title concept that removed the hoop ring/net around the two O letters and added matching water drops. It was previewed in the game slide and installed once as a horizontal version; the original `splashhoops.png` remains untouched.
- On the follow-up pass, generated `textures/menus/splashhoops_stacked.png` with uppercase `SPLASH` over `HOOPS`, kept the same colors and droplets, and removed the ring/net. Sized it to 210×143 px for the existing 274×153 px inner title area (32 px horizontal and 5 px vertical margins). `scripts/game_menu_switcher.gd` now points to this stacked version. Preview: `/private/tmp/splash-stacked-title-preview-final/menu_games.png`. Re-exported the Shrine Test PCK, confirmed byte equality with the app’s embedded pack and a valid app signature, then installed/launched `com.xavigrau.pooppal.shrinetest` on the iPhone. Device capture: `/private/tmp/splashhoops-stacked-title-on-device.png`.
- Refined Splash Hoops again to 260×141 px, chunkier pixel clusters, and muted aqua/blue and apricot/terracotta tones. This is the active `textures/menus/splashhoops_stacked.png` and is mapped in `scripts/game_menu_switcher.gd`. Preview in card: `/private/tmp/splashhoops-muted-logo-preview/menu_games.png`; installed on the iPhone 15 Pro Max as `com.xavigrau.pooppal.shrinetest`.
- Generated matching 260×141 game-card logos for Tilt Maze (`textures/menus/tiltmaze_pixel.png`), RC Prix (`textures/menus/rcprix_pixel.png`), Top Spin (`textures/menus/topspin_pixel.png`), and RC Prix 2177 (`textures/menus/rcprix2177_pixel.png`). Updated their `CARD_ART` mappings in `scripts/game_menu_switcher.gd`; left the existing Paper Sumo asset and mapping unchanged. Preview captures: `/private/tmp/game-logo-previews/{tiltmaze,rcprix,topspin,rcprix2177}/menu_games_*.png`.
- Exported the updated `iOS Shrine Test` pack, confirmed it byte-matches the PCK embedded in the signed Xcode build, then installed and launched `com.xavigrau.pooppal.shrinetest` on iPhone 15 Pro Max. The normal shrine app remains separate.
- Paper Sumo logo edit sketch replaces both wrestlers with a folded-paper dohyo while retaining the lettering: `/Users/xaviergrau/.codex/generated_images/01a1634f-3e57-7e80-b372-9dd38c5925cd/exec-a17037e9-2a81-4bad-b5e0-f23a2805b55e.png`. Preview only; not installed pending review.
- Follow-up Paper Sumo logo uses only the folded-paper `PAPER / SUMO` lettering (no fighters or ring), sized to 260×141 px as `textures/menus/papersumo_pixel.png` and mapped at CARD_ART key 9. Slide preview: `/private/tmp/papersumo-letters-only-preview/menu_games_3.png`. Exported and verified the New Shrine test pack against the signed Xcode app, then installed/launched `com.xavigrau.pooppal.shrinetest` on the iPhone 15 Pro Max. The regular shrine app was not changed.
- Replaced the Tummy Tunes game-card logo with the TOMO TUNES shamisen version at `textures/menus/tummytunes_pixel.png`, normalized to 260×141 px and mapped at `CARD_ART` key 6 in `scripts/game_menu_switcher.gd`. Exported the `iOS Shrine Test` pack, verified it matches the signed app’s embedded pack, then installed and launched `com.xavigrau.pooppal.shrinetest`. The normal shrine app was not changed.
- Coarsened Paper Sumo's game-card pixel clusters by a 2× nearest-neighbor pixel pass, preserving its transparent 260×141 canvas, letter design, and palette. Original saved at `/private/tmp/papersumo-before-coarsening.png`. Re-exported and verified the embedded PCK/signature, then installed and launched `com.xavigrau.pooppal.shrinetest` on the iPhone; normal shrine app unchanged.
- Refined KamiTomo logo while retaining its current letter design, palette, and pixel treatment: revised only the lower arm of the K, added 2 px between m and i (moving following glyphs together), and widened the Kami kanji mask from 29 to 34 grid units. Updated the asset generator and `textures/console/logo_kamitomo.png` (518×124). Re-exported the Shrine Test pack, verified the signed app embeds the same pack, then installed/launched `com.xavigrau.pooppal.shrinetest`; standard shrine app unchanged.
- Correction to the first KamiTomo refinement: replaced the font-generated Kami character with the approved sketch’s 神 silhouette, recolored using the existing Tomo kanji texture, and rebuilt only K’s lower arm from that sketch while keeping its original upper arm. The extra spacing after “i” and all other letter shapes/colors remain. Added local reference masks under `tools/design/` and updated the generator. Re-exported, verified, installed, and launched the corrected `com.xavigrau.pooppal.shrinetest` build.
- Follow-up K correction: the approved concept’s full K silhouette now supplies both upper and lower arms with equal chunky stroke weight (instead of retaining the thin original upper arm). Rebuilt, verified pack/signature, and installed/launched `com.xavigrau.pooppal.shrinetest`.
- Latest KamiTomo logo pass: recolored every Kami kanji pixel uniformly dark so none of Tomo’s cream highlights carry over. Rebuilt the K from mirrored, equal-weight diagonal arms, kept the K–A interval at the same 3 px as the other standard letter gaps, preserved the extra breathing room before “i,” and held the 518 px logo canvas/right edge fixed so the final O remains in place. Exported the iOS Shrine Test pack and confirmed it byte-matches the pack embedded in the build. Installed and launched `com.xavigrau.pooppal.shrinetest` on the paired iPhone; standard shrine app untouched. `codesign --verify --deep --strict` reports the local development certificate as untrusted, though device installation and launch succeeded.
- Refined the KamiTomo K using the approved tapered lower-arm silhouette, extending its tip to the stem's bottom level, then mirrored that full-height arm upside down for the upper stroke. The two arms share the same silhouette and outline and reach the K's top/bottom levels. Letter spacing, dark Kami kanji, logo dimensions, and final O position are unchanged. Re-exported the iOS Shrine Test pack, verified it byte-matches the embedded pack, then installed and launched `com.xavigrau.pooppal.shrinetest`; standard shrine app untouched.

## New Shrine settings title logos

- Added six pixel-art title assets for the collection hub: `COIN / SHOP`, `TOMO / PEDIA`, `DRESS / UP`, `HOME / DECOR`, `BACKGROUNDS`, and `CASES`. They use the approved first draft's dimensional pixel lettering and separate color palettes, with line breaks as requested.
- Source proof sheet: `/Users/xaviergrau/.codex/generated_images/01a1634f-3e57-7e80-b372-9dd38c5925cd/exec-82f825a7-47d1-4278-9bcc-874312ddae52.png`. Extraction script: `tools/design/extract_new_shrine_titles.py`; installed source assets: `textures/menus/new_shrine_titles/`.
- `scripts/collection_menu.gd` selects these six logos only when `DevLaunch.new_shrine` is true. The standard Shrine selection continues using the existing logos. No game title art or in-menu text was changed.
- Preview of the extracted logos: `/private/tmp/new_shrine_titles_preview.png`.
- Correction from the user's attached reference: replaced the stacked draft cutouts with horizontal `COIN SHOP`, `TOMO PEDIA`, `DRESS UP`, `HOME DECOR`, `BACKGROUNDS`, and `CASES` wordmarks in the chunky style shown there. The corrected sheet is `docs/mockups/new_shrine_titles_side_by_side.png`, extraction script updated, and preview at `/private/tmp/new_shrine_titles_corrected_preview.png`. The New Shrine only routing remains the same.
- Final title layout correction per user: `COIN / SHOP`, `TOMO / PEDIA`, `DRESS / UP`, and `HOME / DECOR` are stacked on two lines; `BACKGROUNDS` and `CASES` remain single-line. The follow-up size correction uses each original logo's native canvas (`165×106`, `200×106`, `205×106`, `205×106`, `228×86`, `205×56` respectively), with stacked word lines scaled to use the full height and single-line titles fitted to their individual envelopes. Preview: `/private/tmp/new_shrine_titles_adjusted_preview.png`.
- Widened the four stacked wordmarks to 88% of their native logo-frame width while preserving their line height, and shifted the centered `BACKGROUNDS` art down 8 px within its canvas. Preview: `/private/tmp/new_shrine_titles_wide_preview.png`.
- Widened `COIN / SHOP` to the same 205 px logo-frame width as `DRESS / UP` and `HOME / DECOR`, so its visible wordmark now matches the other stacked titles. Preview: `/private/tmp/new_shrine_titles_coin_width_preview.png`.

## Hokora food and drink menu icons

- Added 54 alternate food sprites (45 standard foods plus 9 special offerings) and 15 drink sprites under `textures/food/new_shrine/` and `textures/drinks/new_shrine/`.
- `scripts/foodmenudebug.gd` swaps only the menu card icon when `DevLaunch.new_shrine` is active. The regular Shrine and all gameplay data/effects continue using the existing source textures.
- Assets are 32×32 RGBA PNGs, generated as category sheets and cropped to the menu icon size. Food order follows `FoodLibrary` and drink order follows `DrinkLibrary`.
- Exported the latest pack to `build/ios-shrine-test/PoopPalShrine.pck`. The Xcode app rebuild stopped at code signing (`errSecInternalComponent`), and the paired iPhone reported unavailable, so the updated signed app is not installed yet.
