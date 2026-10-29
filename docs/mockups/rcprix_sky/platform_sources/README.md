# RC Prix Sky · cloud-supported start runway

High-resolution transparent ImageGen source paintings for the selected start platform. The game places the runway deck on the **existing drifting cloud art**; this delivery contains no painted cloud.

| File | Contents | Target after game conversion |
| --- | --- | --- |
| `runway_deck_source.png` | Blue-and-cream striped carpet runway, checker near right end, back-edge bunting, lights, thin front face | Top about 104 × 94 game px, plus a 6–10 px front face |
| `windsock_0_source.png` | Orange-and-white sock, fully inflated rightward | One common animation canvas; about 18 × 18 game px |
| `windsock_1_source.png` | Tail flicked upward | Same canvas and pole anchor |
| `windsock_2_source.png` | Briefly slack, tail lower | Same canvas and pole anchor |
| `windsock_3_source.png` | Filling again, tail rising | Same canvas and pole anchor |

The deck is viewed from above with a narrow front side below it, as in the Garden track. The plane travels **left to right**; the checker crosses the carpet front to back about 24 game px from the right end. Mirror the finished game sprite for leftward races. Place the windsock on a back corner as a separate animated layer. When converting its frames, keep one shared canvas and align by the fixed pole and base rather than independently cropping each cloth silhouette.

## Prompt set and method

Made only with the built-in ImageGen tool. The deck prompt used concept C for its striped fabric, checker, bunting, lamps and palette, and the existing pad guide for footprint and overhead view. It explicitly requested a separate toy-like deck with **no cloud, metal, rotors or plane**, transparent background, no glow and top-left light. Windsock frame 0 was generated separately as a small orange-and-white sock on a fixed pole; frames 1–3 were ImageGen edits of frame 0, changing the fabric motion while retaining its pole, palette and transparency. These are source paintings for the established game-grid conversion, not pixel-locked final sprites.
