# The spirits' style bible (2026-11-06)

**The look is the October sheets.** The user, on 2026-11-06: "these are cool ... just go this way". The sheets:
- `docs/mockups/pal_brainstorm/current_spirit_style_reference.png` (15 spirits)
- `docs/mockups/pal_brainstorm/spirit_30_alternatives/alternative_{a,b,c}.png` (3 × 30)

Every spirit, all 120, must look like it was drawn on the same sheet as those.

## Why they look like one family (and rounds 4–8 didn't)

They share one **construction**. Only the thing the spirit is changes. Rounds 4–8 varied everything at once:
- body plans (a hawk, a cow on a spring, a bowl with hands)
- faces (big shiny eyes, angry brows, open mouths)
- limbs and poses (sneezing, flipped, flying)
- the rendering: smooth paintings shrunk, instead of pixel art

Even with the same outline and shading, a set built that way never looks like one set.

## The construction (fixed for every spirit)

1. **Native pixel art** at one pixel size, the same as the sheets (we cut it to the old pals' grid, 56 × 56). It is never a smooth painting shrunk down.
2. **One low, round mass sitting on the floor**, usually wider than tall: a mochi, a pod, a jar, a lantern, a cloud. No arms. At most tiny stub feet. No poses or actions.
3. **The house face.** It is small and calm (deadpan, *yurui*) and sits low on the body, with the eyes set wide apart:
   - **eyes:** dot eyes or short sleepy lines
   - **mouth:** tiny, 1–2 px
   - **blush:** sometimes a little
   - **placement:** often on a cream "mochi" patch inside the object (the chestnut, the leaf, the mushroom, the daruma)
   - **not allowed:** big shiny eyes, eyebrows (except the daruma's and the oni's), open mouths
   - **Signature faces (the user, 2026-11-06):** some spirits get a face of their own, and those are among the best. Examples:
     - `comet_chili`'s big round eyes
     - `karakasa`'s and `popper`'s single eye
     - `burrito`'s pig snout
     - `hou_ou`'s beak

     The house face stays the default, but more spirits should get a face that comes from their thing: an animal's own muzzle or beak, the object's own opening, one eye, or big eyes. The body construction stays the same, so the set still holds together. The five spirits replaced in the 2026-11-06 round all get one; then the user decides which others to change.
4. **One Japanese thing each**: a yokai, a shrine object, a festival thing, a seasonal plant or food. The face lives in it.
5. **One or two extra features at most**: horns, a leaf, a flame, a rope, wisps. No props held, no scenes.
6. **The same rendering**:
   - a dark brown 1 px outline
   - soft shading with 3–4 tones and a small highlight, lit from the top left
   - warm, slightly muted colours
7. **Size grows with the stage**, at the same pixel size:
   - baby about 26 px tall
   - kid about 34
   - adult about 40
   - legend about 46

The **personality** (names, one-liners, little twists) lives in the writing and in the code animations, not in extra drawing.

## Why this also suits the game

- **Animation:** every spirit has the same face in the same zone and the same soft mass. One rig, written once, works for all 120: squash-and-stretch breathing, a blink and a mouth for eating, sway on the loose part (leaf, flame, horns).
- **Balls and small versions:** the colour, the face and the top feature. `tools/art/pal_balls.py` already works this way.
- **Merch and the Japanese market:** this is the language of the big Japanese character lines (simple soft bodies, deadpan faces, one idea each, series that look collected), not Western cartoon mascots.

## The pool: about 105 designs already drawn

`tools/art/october_cut.py` cuts all four sheets into 56 px sprites in `docs/mockups/spirits/october/`, named by sheet code:
- `A04` = sheet A, row 0, column 4
- `R13` = the reference sheet's 13th sprite

They are grouped by realm in `pool_<realm>.png`. Sheet A's columns are the realms; in sheets B and C, each row is a realm.

## The process from here

1. **For each realm, fill the 24 slots from its pool first.** Fire: 16 of 24, see `docs/spirits_roster_fire.md`.
2. **The designer makes only the gaps, into a template sheet.** The realm's chosen sprites sit on the October cream at their original size, in the tree layout, with the gap cells left blank. ImageGen fills the blank cells while the neighbours hold the style, scale and face (an edit, not a fresh generation).
3. **We cut the filled sheet** (`october_cut.py`), check it in the shrine and judge the realm as a whole.
4. **Names and one-liners** come last, from the look.
