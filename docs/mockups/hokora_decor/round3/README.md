# Hokora ornaments, round 3

Review assets for the tech team. The ten homes each have a `set_preview_8x.png` assembled from the **delivered game-size PNGs**. `source_*_imagegen.png` files are the original ImageGen paintings; the small PNGs are their hard-pixel exports. No ornaments have been installed into live `textures/` folders.

## Home sets

| Home | Lantern | Shelf object | Hanging piece |
| --- | --- | --- | --- |
| [Tree Hollow](tree_hollow/set_preview_8x.png) | Firefly jar | Sleeping squirrel | Acorn vine |
| [Neon Cyber](neon_cyber/set_preview_8x.png) | Holographic cube | Robot lucky cat | LED cable |
| [Moon](moon/set_preview_8x.png) | Crescent | Mochi rabbit | Stars and crescents |
| [Golden Temple](golden/set_preview_8x.png) | Phoenix | Phoenix statue | Gold tassels |
| [Ruined Night](ruined_night/set_preview_8x.png) | Broken stone and blue flame | Glowing mushrooms | Cobweb rope and spider |
| [Food Stall](ramen_stall/set_preview_8x.png) | Akachochin | Steaming pot | Menu plaques |
| [Capsule Pod](capsule_apartment/set_preview_8x.png) | Pod LED | Desk fan | Photos and fairy lights |
| [Arcade Cabinet](arcade_cabinet/set_preview_8x.png) | Pixel heart | Claw toy | Tokens and keychains |
| [Bathhouse](bathhouse/set_preview_8x.png) | Frosted lamp | Duck in bucket | Towels |
| [Fire Shrine](fire/set_preview_8x.png) | Iron cage | Salamander | Chilies and bells |

Each folder contains the animation frames and `icons/` at 96×96. The waving robot lucky cat also has left-facing frames. Use the `manifest.tsv` file for all frame names.

## Other pieces

- [Round 1 updates](round1/): all eleven lanterns now have light-animation frames; goldfish, maneki cats, candles, stone lantern, pinwheels, and LED string have frames. Ten original shelf-pair paintings are separated into right and left single objects. Waving cats have individually painted left-facing frames.
- [Extras](extras/): eight shelf objects and five hanging pieces, with frames where requested.
- [Tree Hollow gap preview](tree_hollow/tree_gap_preview_8x.png): the revised interior with open dark spaces between hanging roots. The original interior is saved as `tree_hollow/inside_before_round3.png`; the revised layer is `docs/mockups/hokora_homes/v5/tree_hollow/inside.png`.
- [Menu slides, step 1](../../menu_frames/v1/): paper and thin-wood versions of the slide frame, logo plate, and stats plate, each with an 8× preview. These are samples for choosing a material before step 2.

## Format and handoff

Lanterns are 26×42, shelf objects 30×36, hanging pieces 90×37, icons 96×96. The home set previews are 1760×1760 (220 art pixels enlarged 8×). The six menu sample PNGs have the sizes in `docs/kami_menu_frames_brief.md`.

The paintings were made with ImageGen. `tools/art/hokora_round3_export.swift`, `tools/art/hokora_tree_gap_export.swift`, and `tools/art/hokora_menu_step1_export.swift` only crop, place, and export them on the final grid. An inventory check read 281 requested PNGs and found **0 missing, wrong-size, or partial-alpha files**. In-game placement and animation timing still need review by the tech team.

## Animation cleanup

All 50 animated pieces now use their approved frame 0 as the fixed base. The 100 alternate frames change pixels only inside the moving regions recorded in [animation_regions.tsv](animation_regions.tsv). The [6× animation review sheets](animation_review/) show the delivered frames side by side. The right-facing Neon Cyber robot cat is a pixel mirror of the cleaner left-facing drawing, including its menu icon. The kokeshi moves its head by one pixel and returns; the bamboo fountain keeps its stand fixed.

Run `swift tools/art/check_hokora_round3_animation.swift` to compare every alternate with frame 0. Current result: **50 pieces, 100 alternate frames, 0 problems**. If art is re-exported from the original ImageGen source sheets, run `swift tools/art/hokora_round3_lock_animation.swift` afterward to restore this frame locking. The set previews can be rebuilt without changing sprites using `swift tools/art/hokora_round3_export.swift <home> --preview-only`.
