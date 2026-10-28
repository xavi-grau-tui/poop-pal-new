# RC Prix · Garden: notes for round 7 (the round-6 sketches, at the tree's leaf size)

## What we want

The bushes you showed in your app in round 6 (`round6_sources/bush_*_tone_study.png`) are the look
we want: leafy rosettes with pointy tips, the outline bumping around the leaves. We put them in the
game exactly as drawn (`textures/minigames/rcprix/garden/trial/bush_*_big.png`). They look right but
**too small-leaved, as if farther away than the tree**.

The game draws the trees and bushes at exactly the same pixel scale. There is no distance between
them, so **one leaf must be the same number of pixels in a bush as in the tree**. Measured:

| | Light leaf patch (median) | Colour changes every |
|---|---|---|
| Tree | 47 px (about 7×7) | 3.65 px |
| Your round-6 sketches | 10–31 px | 1.9–2.2 px |

Their leaves are 1.5–2× too small. They're also a bit dark: 28% light green, against 38% in the tree.

## The rules

1. **Leaf size is fixed first.** Every leaf rosette is the tree's size: a light patch of about
   7×7 px with a few highlight pixels at its top left, in a rosette about 10–12 px across including
   its shadow. A bush is just **fewer rosettes**, never smaller ones.
   - A (90 px wide): about 8 rosettes across. B (108 px): about 9. C (86 px): about 7.
     D (94 px): about 8.
   - E, F, G (38–48 px): 3–4 rosettes across, 5–8 in total.
2. **Build from the tree's own rosettes** (the safest way). Cut 6–10 single rosettes out of
   `tree_top.png`, each with its own shading, and stamp them, overlapping, into the round-6 sketch
   shapes: back and bottom ones first, front and top ones last. Darken the lower rosettes one step
   so each sits in shadow under the next. Then draw the 1 px outline (`#251a24`) around the leaf
   tips. If you use a generator instead, generate at **16× the final size** (A at 1440×1216) with
   rosettes 160–190 px across, and turn each 16×16 block into one pixel.
3. **What you show us is what you deliver.** The PNG in the game must be the exact picture you
   approved, with no repaint or snapping script afterwards. (In rounds 4 and 6 the files that came
   in differed from the pictures shown.)
4. **Brightness like the tree:** the tree's six colours only, about 26% deep shadow, 27% mids,
   26% light, 12% highlight.

## Sizes (the round-5 boxes, already in the templates)

| File | Size | Shape |
|---|---|---|
| `bush_a.png` | 90×76 | round sketch A |
| `bush_b.png` | 108×46 | wide, low sketch B |
| `bush_c.png` | 86×64 | uneven sketch C |
| `bush_d.png` | 94×80 | tall sketch D |
| `bush_e.png` | 44×38 | small sketch E |
| `bush_f.png` | 38×32 | small sketch F |
| `bush_g.png` | 48×36 | small sketch G |

## Test before handing over

1. All seven next to the tree at 4×: the rosettes must look the same size and shape as the tree's.
2. `python3 tools/art/check_rcprix_art.py`: 81/81 files, 0 problems (it checks colours, leaf patch
   size and speckle against the tree).
3. Send the 4× picture made **from the delivered PNGs themselves**.
