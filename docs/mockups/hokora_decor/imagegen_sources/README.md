# Hokora decoration ImageGen sources

These are the **review paintings** for the forest hokora decoration set. Every illustrated design and animation frame in this folder was made with the built-in ImageGen tool, one asset per call. No script drew or repainted the art.

## Files

| Folder | Source files | Intended game output |
| --- | ---: | --- |
| `lanterns/` | 11 | One 108 × 176 transparent lantern each |
| `hanging/` | 30 | Fifteen ornaments, `-1` and `-2`, each on a 925 × 925 transparent canvas |
| `shelf/` | 15 | One pair per 925 × 924 transparent canvas, with the offering-table area clear |
| `sky/` | 21 | Tiny final-grid sprites; see the original art list for each size |
| `icons/` | 41 | One centred 96 × 96 transparent icon per lantern, hanging ornament, and shelf pair |

The names of the source paintings match the requested game names. Hanging animation frames use `<name>-1.png` and `<name>-2.png`.

## Conversion and review

Workflow used: **high-resolution ImageGen source paintings**, rather than 4× painting directly on the guides. The sources have alpha, but ImageGen chose its own canvas dimensions. They are **not yet final-grid sprites**. Before placing them in `textures/pet/shrine_new/decor/` or `textures/pet/shrine_new/sky/`, the tech/art pass should:

1. Judge each painting beside `textures/pet/shrine_new/front.png` at phone size. Simplify any details that disappear at the target size.
2. Place lantern hooks at the top centre. Use `guide_hanging.png` and `guide_shelf.png` to compose the full transparent canvases, keeping the central spirit opening clear.
3. Clean fringe and partial-alpha pixels, then convert to the shrine's hard pixel grid with nearest-neighbour scaling. In particular, the tiny sky sources are visual references for a deliberate 1–6-pixel redraw; simple shrinking will not produce legible final sprites.
4. Align each hanging pair to the same anchors and bounds so the second frame makes only a subtle sway.
5. Crop and centre the icons on 96 × 96 transparent canvases.

Some ImageGen sources have a soft plum halo around the outline, especially hanging art. Remove it during final-grid cleanup if it reads as a background patch.

The dress-ups, device cases and stickers in the **LATER** section of the brief remain deferred until the spirit designs are final.
